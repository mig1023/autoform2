var sending = {

	pack( form, direction ) {
		
		var data = {
			'direction': direction,
		};
		
		form.elements.forEach( function( item ) {
			data[ item.name ] = item.val;
		});
		
		return JSON.stringify( data );
	},
}

export default sending;