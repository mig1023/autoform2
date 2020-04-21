var sending = {

	pack( form ) {
		
		var data = {};
		
		form.elements.forEach( function( item ) {
			data[ item.name ] = item.val;
		});
		
		return JSON.stringify( data );
	},
}

export default sending;