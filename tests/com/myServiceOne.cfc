component accessors="true" {

	property emit;

	function configure () {
		emit.on("myServiceTwo.testEvent", function(data) {
			data.counter += 1;
		});
	}

}