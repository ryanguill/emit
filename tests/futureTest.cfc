component extends="testbox.system.BaseSpec" {

	function beforeTests() {
		//create a folder for the test files to be written to
		var tempDir = getTempDirectory();
		if (!findNoCase(right(tempDir, 1), "/\")) {
			tempDir &= "/";
		}

		variables.dir = tempDir & "emitFutureTest" & dateFormat(now(),"yyyymmdd") & timeformat(now(),"HHmmssl");

		directoryCreate(dir);

		writeoutput(dir & "<hr>");

	}

	function afterTests() {
		//attempt to clean up
		try {
			if (directoryExists(dir)) {
				directoryDelete(dir);
			}
		} catch (any e) {}
	}

	function setup (currentMethod) {

	}

	function teardown (currentMethod) {

	}

	function testFutureSimple () {
		var emit = new lib.emit();

		var f = emit.future(function() {
			//represents slow running process
			//this function will run in its own thread,
			//code in here will not block the execution of code outside
			return 1;
		});

		assert(isStruct(f));
		assert(!isNull(f.get) && isClosure(f.get));

		var result = f.get(); //this blocks until the value is ready
		assert(result == 1);

		result = f.get();
		assert(result == 1);
	}

	function testFutureError () {
		var emit = new lib.emit();

		var f = emit.future(function() {
			throw(message="TestFutureError");
		});

		try {
			var result = f.get();
		} catch (any e) {
			//throw the error from the inside
			var error = e;
		}

		assert(isStruct(duplicate(error))); //use duplicate because ACF is dumb and doesnt think an exception is a struct
		assert(!isNull(error.message) && findNoCase("TestFutureError", error.message));
	}

	function testAsyncFuture () {
		var emit = new lib.emit();
		var filename = dir & "/testAsyncFuture.txt";

		var f = emit.future(function () {
			sleep(50);
			filewrite(filename, "");
			return true;
		});

		assert(!fileExists(filename));

		sleep(75);

		assert(fileExists(filename));

		var result = f.get();
		assert(result);
	}

	function testAsyncLongRunningCalculation () {

		var emit = new lib.emit();
		var rand1 = randRange(1,1000);
		var rand2 = randRange(1,1000);

		var f = emit.future(function() {
			sleep(100);
			return rand1 + rand2;
		});

		var startTick = getTickCount();
		var result = f.get();
		var blockedTime = getTickCount() - startTick;

		assert(blockedTime > 90);

		assert(result == rand1 + rand2);
		result = f.get();
		assert(result == rand1 + rand2);

	}

	function testFutureNeverGet () {
		var startTick = getTickCount();
		var emit = new lib.emit();
		var rand1 = randRange(1,1000);
		var rand2 = randRange(1,1000);

		var f = emit.future(function() {
			sleep(100);
			return rand1 + rand2;
		});
		var time = getTickCount() - startTick;
		assert(time < 10);//shouldn't have taken longer than 10 ms
	}

	function testSeanExample () {

		var emit = new lib.emit();

		var rand1 = randRange(1,1000);
		var rand2 = randRange(1,1000);

		var a = emit.future(function() {
			sleep(50);
			return rand1;
		});

		var b = emit.future(function() {
			sleep(50);
			return rand2;
		});

		assert(a.get() + b.get() == rand1 + rand2);
	}

	function testFutureIsComplete () {
		var emit = new lib.emit();

		var f = emit.future(function() {
			sleep(50);
			return true;
		});

		assert(f.isComplete() == false);

		sleep(55);

		assert(f.isComplete() == true); //isComplete can check the status of the result without blocking for it

		assert(f.get() == true);

		assert(f.isComplete() == true);
	}

	function testFutureHasError () {
		var emit = new lib.emit();

		var f = emit.future(function() {
			sleep(50);
			return true;
		});

		assert(f.hasError() == false); //not complete so no error yet

		assert(f.get() == true);

		assert(f.hasError() == false); //no error so hasError = false

		f = emit.future(function() {
			sleep(50);
			throw(message="Intentional Error");
		});

		assert(f.hasError() == false); //not complete so no error yet

		try {
			f.get();
		} catch (any e) {
			assert(findNoCase("Intentional Error", e.message));
		}

		assert(f.hasError() == true);
	}

	function testFutureRaceSimple () {
		var emit = new lib.emit();

		var ps = [];

		for (var i = 1; i <= 10; i++) {
			var makeFuture = function(index) {
				return emit.future(function() {
					sleep(index * 100);
					return index;
				});
			};
			arrayAppend(ps, makeFuture(i));
		}

		var racep = emit.race(ps);

		racep.then(function(value) {
			assert(value == 1);
		});
	}

	function testFutureRaceNonFuture () {
		var emit = new lib.emit();

		var ps = [];

		for (var i = 1; i <= 10; i++) {
			var makeFuture = function(index) {

				if (index == 5) {
					return 5;
				}
				return emit.future(function() {
					sleep(index * 100);
					return index;
				});
			};
			arrayAppend(ps, makeFuture(i));
		}

		var racep = emit.race(ps);

		racep.then(function(value) {
			assert(value == 5);
		});
	}

	function testFutureRaceFailure () {
		var emit = new lib.emit();

		var ps = [];

		for (var i = 5; i <= 5; i++) {
			var makeFuture = function(index) {

				return emit.future(function() {
					if (index == 5) {
						throw(message="Intentional Error " & index);
					}
					sleep(index * 100);
					return index;
				});
			};
			arrayAppend(ps, makeFuture(i));
		}

		var racep = emit.race(ps);

		racep.then(function(value) {
			//writedump(value);abort;
			throw(message="should not be called");
		}).fail(function(error) {
			assert(findNoCase("Intentional Error 5", error.message) != 0);
		});
	}


}