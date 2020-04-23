package autoform2::Validation::Data;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( check_data_from_form check_diff_types check_checklist check_chkbox check_param check_captcha check_passnum_already_in_pending );

sub check_data_from_form
# //////////////////////////////////////////////////
{
	my ( $self, $step, $content, $tables_ids_edt ) = @_;
	
	my $page_content = ( $content ? $content : $self->get_content_rules( $step, undef, 'init' ) );
	
	my $tables_id = ( $tables_ids_edt ? $tables_ids_edt : $self->get_current_table_id() );

	return if $page_content =~ /^\[/;
	
	my $first_error = '';
	
	for my $element ( @$page_content ) {

		last if $first_error;
		
		$first_error = $self->check_diff_types( $element ) if $element->{ check };

		$first_error = $self->check_captcha() if $element->{ type } =~ /captcha/;

		last if $first_error;

		$first_error = $self->check_logic( $element, $tables_id, ( $tables_ids_edt ? 1 : 0 ) )
			if $element->{ check_logic };
	}
	
	return $first_error;
}

sub check_diff_types
# //////////////////////////////////////////////////
{
	my ( $self, $element ) = @_;
	
	return $self->check_chkbox( $element ) if $element->{type} =~ /checkbox|disclaimer/;

	return $self->check_checklist( $element ) if $element->{type} =~ /checklist/;

	return $self->check_param( $element );
}

sub check_checklist
# //////////////////////////////////////////////////
{
	my ( $self, $element ) = @_;
	
	my $at_least_one = 0;
	
	for my $field ( keys %{ $element->{ param } } ) {
	
		$at_least_one += ( $self->param( $field ) ? 1 : 0 );
	}
	
	return $self->text_error( 11, $element )
		if ( ( $element->{ check } =~ /at_least_one/ ) and ( $at_least_one == 0 ) );
}

sub check_chkbox
# //////////////////////////////////////////////////
{
	my ( $self, $element ) = @_;
	
	my $value = $self->param( $element->{ name } );
	
	return $self->text_error( 3, $element ) if ( ( $element->{ check } =~ /true/ ) and ( $value eq '' ) );
}

sub check_param
# //////////////////////////////////////////////////
{
	my ( $self, $element ) = @_;

	my $value = $self->param( $element->{ name } );
	my $rules = $element->{ check };

	$value = $self->get_prepare_line( $value, $element );
	
	return $self->text_error( 30, $element )
		if ( $element->{ example_not_for_copy } and $element->{ example } ne '' ) and ( $value eq $element->{ example } ); 

	return $self->text_error( 0, $element )
		if ( $rules =~ /z/ ) and ( ( $value eq '' ) or ( $value eq '0' ) );
			
	return if $rules eq 'z';

	if ( $rules =~ /D/ ) {
	
		$rules =~ s/(z|D)//g;
		
		return $self->text_error( 1, $element ) if ( !( $value =~ /$rules/ ) and ( $value ne '' ) );
		
		$value =~ /(\d\d)\.(\d\d)\.(\d\d\d\d)/;
	
		return $self->text_error( 1, $element )
			if ( Date::Calc::check_date( $3, $2, $1 ) == 0  and ( $value ne '' ) );
	}
	else {
		my $regexp = '';
		
		$regexp .= 'A-Za-z' if $rules =~ /W/; 
		$regexp .= 'АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя' if $rules =~ /Ё/;
		$regexp .= '0-9' if $rules =~ /N/;
	
		$rules =~ s/(z|W|Ё|N)//g;
		
		my $revers_regexp = '[' . $regexp . $rules . ']';
		$regexp = '[^' . $regexp . $rules . ']';

		if ( ( $value =~ /$regexp/ ) and ( $value ne '' ) ) {
		
			$value =~ s/$revers_regexp//gi;

			return $self->text_error( 2, $element, $value );
		}
	}
}

sub check_captcha
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	return undef if $self->this_is_inner_ip();
	
	my $response = $self->param( 'g-recaptcha-response' ) || '';
	
	my $request = HTTP::Tiny->new();

	my $result = $request->post_form(
		$self->{ autoform }->{ captcha }->{ verify_api },
		{ 
			secret => $self->{ autoform }->{ captcha }->{ private_key }, 
			response  => $response
		}
	);

	if ( $result->{ success } ) {
	
		return if decode_json( $result->{ content } )->{ success };
	}
	return 'captha_div' . $self->text_error( 18 );
}

sub check_passnum_already_in_pending
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $pass_list = [];
	
	my $pass_double = undef;
	
	my $pass_doubles = {};

	my $app_data = $self->db->query( "
		SELECT AutoAppData.PassNum, isChild
		FROM AutoToken
		JOIN AutoAppointments ON AutoToken.AutoAppID = AutoAppointments.ID
		JOIN AutoAppData ON AutoAppointments.ID = AutoAppData.AppID
		WHERE Token = ?", $self->{ token }
	);

	for ( @$app_data ) {
	
		unless ( $_->{ isChild } ) {
		
			push( @$pass_list, $_->{ PassNum } );
			
			$pass_doubles->{ $_->{ PassNum } } += 1;
		}
	}
	
	for ( keys %$pass_doubles ) {
			
		$pass_double = $_ if $pass_doubles->{ $_ } > 1;
	}
	
	my $pass_line = join( "','", @$pass_list );

	my $pass_already = $self->db->query( "
		SELECT COUNT(ID) FROM AppData
		WHERE PassNum IN ('$pass_line') AND Status = 1 AND isChild = 0"
	);

	$pass_already = undef unless $pass_already;

	return ( $pass_already, $pass_list, $pass_double );
}

1;