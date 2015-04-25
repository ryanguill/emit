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
		})

		p.then(
			function(value) {
				throw(message="Should not be called");
			}
		);

		p.catch(
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
		).catch(
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
			.then(service.dividedBy10)
			.then(function(value) { assert(value == x);});

	}

	function testServiceReturningPromisesFailure () {

		var x = randRange(1, 100);

		var service = beanFactory.getBean("promiseService");

		service.times10(x)
			.then(service.slowErrorProcess)
			.then(function(value) { throw(message="Should Not Be Called");})
			.catch(function(value) { assert(value == x * 10);});

	}





}