component skip="true" {

	function init () {
		return this;
	}

	struct function extensionPoint (required struct data ) {

		emit("extensionPointEvent", {data=data});

		return data;
	}

}