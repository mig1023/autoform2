var action = {
	change(object, token, direction) {
		fetch( '/' + direction + '/' + token)
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