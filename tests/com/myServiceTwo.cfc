component accessors="true" {

	property emit;

	function configure () {

	}

	numeric function doEvent() {
		var data = {counter: 0};
		emit.emit("myServiceTwo.testEvent", {data: data});

		return data.counter;
	}

}