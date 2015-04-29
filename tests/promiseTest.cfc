component extends="testbox.system.BaseSpec" {

	function beforeTests() {

		beanFactory = new testLib.ioc("/lib, /tests/com", {initMethod: "configure"});

		//create a folder for the test files to be written to
		var tempDir = getTempDirectory();
		if (!findNoCase(right(tempDir, 1), "/\")) {
			tempDir &= "/";
		}

		variables.dir = tempDir & "emitPromiseTest" & dateFormat(now(),"yyyymmdd") & timeformat(now(),"HHmmssl");

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

	function setup (currentMethod) {}

	function teardown (currentMethod) {}

	function testSimplePromise () {
		var emit = new lib.emit();

		var x = randRange(1, 100);

		emit.Promise(function(resolve, reject) {
			resolve(x);
		}).then(
			function(value) {
				assert(value == x);
			}
		);

	}

	function testSimplePromise2 () {
		var emit = new lib.emit();

		var x = randRAnge(1, 100);

		var p = emit.Promise(function(resolve, reject) {
			resolve(x);
		});

		p.then(
			function(value) {
				assert(value == x);
			}
		);
	}

	function testSimplePromiseRejection () {
		var emit = new lib.emit();

		var x = randRange(1, 100);

		var p = emit.Promise(function(resolve, reject) {
			reject(x);
		});

		p.then(
			function(value) {
				throw(message="Should not be called");
			}
		);

		p.fail(
			function(value) {
				assert(value == x);
			}
		);

	}

	function testPromiseRejectionChain () {
		var emit = new lib.emit();

		var x = randRange(1, 100);

		emit.Promise(function(resolve, reject) {
			reject(x);
		}).then(
			function(value) {
				throw(message="Should not be called");
			}
		).fail(
			function(value) {
				assert(value == x);
			}
		);

	}

	function testPromiseChain () {
		var emit = new lib.emit();

		var p = emit.Promise(function(resolve, reject) {
			resolve(1);
		});

		p.then(function (value) {
			assert(value == 1);
			return value + 1;
		}).then(function (value) {
			assert(value == 2);
		});

	}

	function testServiceReturningPromises () {

		var x = randRange(1, 100);

		var service = beanFactory.getBean("promiseService");

		service.times10(x)
			.then(service, "dividedBy10")
			.then(function(value) { assert(value == x);});

	}

	function testPromiseStatus () {
		var emit = new lib.emit();

		var x = randRange(1, 100);

		var p = emit.Promise(function(resolve, reject) {
			resolve(x);
		});

		assert(p.getStatus() == "PENDING");

		p.then(
			function(value) {
				assert(value == x);
			}
		);

		assert(p.getStatus() == "FULFILLED");

		assert(p.then().getStatus() == "FULFILLED");

		p = emit.Promise(function(resolve, reject) {
			reject(x);
		});

		assert(p.getStatus() == "PENDING");

		assert(p.then(
			function(value) {
				throw(message="Should not be called");
			}
		).getStatus() == "REJECTED");


		p.fail(
			function(value) {
				assert(value == x);
			}
		);

		assert(p.getStatus() == "REJECTED");

	}

	function testPromiseIsComplete () {
		var emit = new lib.emit();

		var x = randRange(1, 100);

		var p = emit.Promise(function(resolve, reject) {
			resolve(x);
		});

		assert(p.isComplete() == false);

		p.then(
			function(value) {
				assert(value == x);
			}
		);

		assert(p.isComplete() == true);

		assert(p.isComplete() == true);

		p = emit.Promise(function(resolve, reject) {
			reject(x);
		});

		assert(p.isComplete() == false);

		assert(p.then(
			function(value) {
				throw(message="Should not be called");
			}
		).isComplete() == true);


		p.fail(
			function(value) {
				assert(value == x);
			}
		);

		assert(p.isComplete() == true);

	}

	function testServiceReturningPromisesFailure () {

		var x = randRange(1, 100);

		var service = beanFactory.getBean("promiseService");

		service.times10(x)
			.then(service, "slowErrorProcess")
			.then(function(value) { throw(message="Should Not Be Called");})
			.fail(function(value) { assert(value == x * 10);});

	}

	function testPromiseRace () {
		var emit = new lib.emit();

		var ps = [];

		for (var i = 1; i <= 10; i++) {
			arrayAppend(ps, emit.Promise(function(resolve, reject) {
				sleep(i * 10);
				resolve(i);
			}));
		}

		var racep = emit.race(ps);

		racep.then(function(value) {
			writedump(value);abort;
			assert(value == 1);
		});


	}




}