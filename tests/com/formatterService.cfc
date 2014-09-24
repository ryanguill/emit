component {

	function formatName (required struct data) {
		if (structKeyExists(data, "firstname") && structKeyExists(data, "lastname")) {
			data.fullname = data.lastname & ", " & data.firstname;
		}
	}

}