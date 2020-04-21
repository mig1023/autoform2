var validation = {

	all_ok( form ) {
		
		var all_error = '';
		
		form.elements.forEach( function( item ) {
			
			var next_error = error( item.val, item.check );
			
			if ( !isEmpty( next_error ) )
				all_error += item.name + ': ' + next_error + '\n';
		});
		
		if ( isEmpty( all_error ) )
			return true;
		else {
			alert( all_error );
			return false;
		}
	},
	
	ok( input, check ) {
		return ( isEmpty( error( input.value, check ) ) ? true : false );
	},
	

}

function error( value, check ) {
	
	if ( ( value == '' ) && ( check == '' ) )
		return '';
		
	if ( value == undefined )
		value = '';
	
	var val = value.replace(/^\s+|\s+$/g, '');
 	
	if ( /z/.test( check ) && ( val == '' ) ) {

		return 'Cant be empty';
	}

	if ( /D/.test( check ) ) {

		var date_reg = new RegExp( check.replace( /(z|D)/g, '' ) );

		if ( !date_reg.test( val ) && ! (val == '') ) {
			
			return 'Wrong date format';
		}
	}
	else {
		var regexp = '';

		if ( /W/.test( check ) ) {
			regexp += 'A-Za-z';
		}
		if ( /Ё/.test( check ) ) {
			regexp += 'А-ЯЁа-яё';
		}
		if ( /N/.test( check ) ) {
			regexp += '0-9';
		}

		var regexp_add = check.replace( /(z|W|Ё|N)/g, '' );

		var input_reg = new RegExp( '[^' + regexp + regexp_add + ']' );

		var reverse_reg = new RegExp( '[' + regexp + regexp_add + ']', "g" );

		if ( input_reg.test( val ) && ( val != '' ) ) {

			return 'Wrong symbols: ' + reverse_reg;
		}
	}
		
	return '';
};

function isEmpty( str ) {
	return ( str.trim() == '' ? true : false );
}

export default validation;