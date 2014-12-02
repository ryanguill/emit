component extends="testbox.system.BaseSpec" {

	function beforeTests() {
		//initialize ioc
		//initMethod configuration requires di1 1.0
		beanFactory = new testLib.ioc("/lib, /tests/com", {initMethod: "configure"});

	}

	function afterTests() {

	}

	function setup (currentMethod) {

	}

	function teardown (currentMethod) {

	}

	function testEmitAsSingleton () {

		var myServiceOne = beanFactory.getBean("myServiceOne");
		//myServiceOne.configure();

		var myServiceTwo = beanFactory.getBean("myServiceTwo");

		var result = myServiceTwo.doEvent();

		expect(result).toBe(1);

	}



}