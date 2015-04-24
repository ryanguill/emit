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
			return 1;
		});

		assert(isStruct(f));
		assert(!isNull(f.get) && isClosure(f.get));

		var result = f.get();
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


}