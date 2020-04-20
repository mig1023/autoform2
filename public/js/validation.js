var validation = {
	ok( input, check ) {
		
		var val = input.value.replace(/^\s+|\s+$/g, '');
		
		if ( ( val == '' ) || ( check == '' ) ) {
			return true;
		}
		
		if ( input.type == 'text' ) {
			
			if ( /z/.test( check ) && ( val == '' ) ) {

				return false;
			}

			if ( /D/.test( check ) ) {

				var date_reg = new RegExp( check.replace( /(z|D)/g, '' ) );

				if ( !date_reg.test( val ) && ! (val == '') ) {
					
					return false;
				}
			}
			else {
				var regexp = '';

				if ( /W/.test( check ) ) {
					regexp += 'A-Za-z';
				}
				if ( /¨/.test( check ) ) {
					regexp += 'À-ß¨à-ÿ¸';
				}
				if ( /N/.test( check ) ) {
					regexp += '0-9';
				}

				var regexp_add = check.replace( /(z|W|¨|N)/g, '' );

				var input_reg = new RegExp( '[^' + regexp + regexp_add + ']' );

				var reverse_reg = new RegExp( '[' + regexp + regexp_add + ']', "g" );

				if ( input_reg.test( val ) && ( val != '' ) ) {

					return false;
				}
			}
		}

		return true;
	},
}

export default validation;