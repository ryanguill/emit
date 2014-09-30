component extends="basicTest" {

	function setup (currentMethod) {
		var emit = new lib.emit();

		testService = new com.testServiceNoInheritance();

		emit.makeEmitter(testService);
	}

	function testExtendsEmit() {

	}

}