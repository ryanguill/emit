component extends="lib.emit" skip="true" {

	function init () {
		return this;
	}

	struct function extensionPoint (required struct data ) {

		emit("extensionPointEvent", data);

		return data;
	}

}