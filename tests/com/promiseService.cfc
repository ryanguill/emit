component accessors="true" {

	property emit;

	function times10 (required numeric input) {

		return emit.Promise(function(resolve, reject) {
			sleep(50);
			resolve(input * 10);
		});
	}

	function dividedBy10 (required numeric input) {

		return emit.Promise(function(resolve, reject) {
			sleep(50);
			resolve(input  / 10);
		});
	}

	function slowErrorProcess (required numeric input) {

		return emit.Promise(function (resolve, reject) {
			sleep(50);
			reject(input);
		});
	}



}