var action = {
	change(object, token, data) {
		
		fetch( '/data/' + token, {
			method: 'POST',
			body: data,
		})
		.then((response) => {
			if (response.ok) {
				return response.json();
			}
		})
		.then((json) => {
			object.elements = json;
		})
	},
}

export default action;