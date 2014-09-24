component extends="lib.emit" skip="true" {

	function init () {
		return this;
	}

	struct function extensionPoint (required struct data ) {

		emit(eventName="extensionPointEvent", data=data);

		return data;
	}


	struct function extensionPointPositional (required struct data ) {

		emit("extensionPointEvent", data);

		return data;
	}

}