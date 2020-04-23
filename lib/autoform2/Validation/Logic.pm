package autoform2::Validation::Logic;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( check_logic );

sub check_logic
# //////////////////////////////////////////////////
{
	my ( $self, $element, $tables_id, $finished ) = @_;

	my $value = $self->param( $element->{ name } );
	my $error = 0;
	
	$value =~ s/^\s+|\s+$//g;
	
	my $prefix = ( $finished ? '' : 'Auto' );

	for my $rule ( @{ $element->{ check_logic } } ) {
	
		if ( $rule->{ condition } =~ /^equal$/ ) {
			
			my $related_value = $self->db->query( "
				SELECT $rule->{name} FROM $prefix$rule->{table} WHERE ID = ?",
				$tables_id->{ $prefix.$rule->{table} }
			);

			return $self->text_error( 26, $element, undef, $rule->{ error }, undef, $rule->{ full_error } )
				if lc( $related_value ) ne lc( $value );
		}
		
		if ( $rule->{ condition } =~ /^required_element$/ ) {
			
			my $required = $rule->{ value };
			my $value_line = $self->get_prepare_line( $value, $element );
			
			return $self->text_error( 0, $element, undef, $rule->{ error }, undef, $rule->{ full_error } )
				if $value_line !~ /(^|,)$required(,|$)/;
		}

		if ( $rule->{ condition } =~ /^(equal|now)_or_(later|earlier)$/ ) {
		
			$value = $self->date_format( $value, 'to_iso' );

			my $datediff = $self->get_datediff(
				$value, $rule, $tables_id, ( $rule->{ condition } =~ /^equal/ ? 1 : 0 ), $prefix
			);

			my $offset = ( $rule->{ offset } ? $rule->{ offset } : 0 );
			
			$error = 6 if (
				(
					( $datediff < $offset )
					or
					( ( $datediff == $offset ) and $rule->{ equality_is_also_fail } )
				)
				and
				( $rule->{ condition } =~ /later$/ )
			);

			$error = 8 if (
				(
					( $datediff > $offset )
					or
					( ( $datediff == $offset ) and $rule->{ equality_is_also_fail } )
				)
				and
				( $rule->{ condition } =~ /earlier$/ )
			);

			$error = 12 if ( $error and $rule->{ condition } =~ /^now/ );
			
			$error += 1  if ( $offset and ( $error == 6 or $error == 8 ) );
			$error = 23 if ( $offset < -1 and $error == 9 );
			
			$offset *= -1 if $offset < 0;

			return $self->text_error(
				$error, $element, undef, $rule->{ error }, $offset, $rule->{ full_error }
				
			) if $error;
		}
		
		if ( $rule->{ condition } =~ /^not_beyond_than$/ ) {
		
			$value = $self->date_format( $value, 'to_iso' );

			my $datediff = $self->get_datediff( $value, $rule, $tables_id, 'use_date', $prefix );

			return $self->text_error(
				23, $element, undef, $rule->{ error }, $rule->{ offset }, $rule->{ full_error }
			) if (
				( ( $datediff > 0 ) and ( $datediff >= $rule->{ offset } ) )
				or
				( ( $datediff < 0 ) and ( $datediff <= ( $rule->{ offset } * -1 ) ) )
			);
		}
		
		if ( $rule->{ condition } =~ /^not_closer_than(_in_spb)?(_from_now)?$/ ) {
		
			my ( $spb, $from_now ) = ( $1, $2 );

			$value = $self->date_format( $value, 'to_iso' );
			
			$value = sprintf( "%04d-%02d-%02d",
				( Date::Calc::Add_Delta_YMD( split( /-/, $value  ), 0, 3, 1 ) )
				
			) if $spb;
			
			
			my $datediff = $self->get_datediff( $value, $rule, $tables_id, ( $from_now ? 0 : 1 ), $prefix );

			return $self->text_error(
				23, $element, undef, $rule->{ error }, $rule->{ offset }, $rule->{ full_error }
			) if (
				( ( $datediff < $rule->{ offset } ) and ( $rule->{ offset } >= 0  ) and !$spb )
				or
				( ( $datediff > $rule->{ offset } ) and ( $rule->{ offset } < 0  ) and !$spb )
				or
				( ( $datediff >= 0 ) and $spb )
			);
		}
		
		if ( $rule->{ condition } =~ /^younger_than$/ ) {
			
			my $app = $self->db->query( "
				SELECT birthdate, CURRENT_DATE() as currentdate
				FROM " . $prefix . "AppData WHERE ID = ?", $tables_id->{ AutoAppData }
			)->[ 0 ];
			
			return $self->text_error( 21, $element, undef, $rule->{ offset } ) 
				if ( 
					( $self->age( $app->{ birthdate }, $app->{ currentdate } ) >= $rule->{ offset } )
					and
					!(
						( $element->{ type } eq 'checkbox' )
						and
						( $value eq '' )
					)
				);
		}
		
		if ( $rule->{ condition } =~ /^unique_in_pending$/ ) {
			
			my $isChild = $self->db->query( "
				SELECT isChild
				FROM AutoToken
				JOIN AutoAppData ON AutoToken.AutoAppDataID = AutoAppData.ID
				WHERE Token = ?", $self->{ token }
			);
			
			if ( !$isChild ) {
		
				my $id_in_db = $self->db->query( "
					SELECT COUNT(ID) FROM $rule->{table}
					WHERE Status = 1 AND isChild = 0 AND $rule->{name} = ?", $value
				);

				return $self->text_error( 10, $element ) if $id_in_db;
			}
		}
		
		if ( $rule->{ condition } =~ /^free_only_if(_not)?(_eq)?$/ ) {
			
			my ( $not, $eq ) = ( $1, $2 );
	
			my $field_in_db = $self->db->query( "
				SELECT $rule->{name} FROM $prefix$rule->{table} WHERE ID = ?", 
				$tables_id->{ $prefix.$rule->{table} }
			);
			
			my @err_param = ( $element, undef, $rule->{ error }, undef, $rule->{ full_error } );

			if ( $eq ) {
				
				my $eq_find = 0;
	
				for my $val ( split /;/, $rule->{ values } ) {
				
					s/(^\s+|\s+$)//g for ( $val, $field_in_db );
				
					$eq_find = 1 if lc( $val ) eq lc( $field_in_db );
				}

				return $self->text_error( 14, @err_param ) if !$value and $eq_find and $not;
			
				return $self->text_error( 13, @err_param ) if !$value and !$eq_find and !$not;
			}
			else {
				return $self->text_error( 14, @err_param ) if $field_in_db and !$value and $not;

				return $self->text_error( 13, @err_param ) if !$not and !( $field_in_db or $value );
			}
		}
		
		if ( $rule->{ condition } =~ /^existing_postcode$/ and $value ) {
			
			my ( $postcode_id, undef ) = $self->get_postcode_id( $value );
			
			return $self->text_error( 15, $element ) unless ( $postcode_id );
		}

		if ( $rule->{ condition } =~ /^length_strict$/ and $value ) {
			
			return $self->text_error( 1, $element, undef, undef, undef, $rule->{ full_error } )
				if length( $value ) != $rule->{ length };
		}
		
		if ( $rule->{ condition } =~ /^this_is_email$/ and $value ) {
			
			return $self->text_error( 16, $element )
				if $value !~ /^([a-z0-9_-]+\.)*[a-z0-9_-]+@[a-z0-9_-]+(\.[a-z0-9_-]+)*\.[a-z]{2,6}$/i;
		}
		
		if ( $rule->{ condition } =~ /^email_not_blocked$/ and $value ) {
		
			my ( $center ) = $self->get_app_visa_and_center();

			my $blocket_emails = VCS::Site::autodata::get_blocked_emails();
			
			for my $m ( @$blocket_emails ) {
				
				my %check = map { $_ => 1 } @{ $m->{ emails } };
				next unless exists $check{ $value };
				
				%check = map { $_ => 1 } @{ $m->{ for_centers } };
				next unless exists $check{ $center } or @{ $m->{ for_centers } } == 0;
				
				return $self->text_error( 16 + ( $m->{ show_truth } ? 1 : 0 ) , $element ); 
			};
		}
		
		if ( $rule->{ condition } =~ /^english_only_for_not_rf_citizen$/ and $value ) {
			
			my $citizenship = $self->db->query( "
				SELECT Citizenship FROM " . $prefix . "AppData WHERE ID = ?", 
				$tables_id->{ $prefix.'AppData' }
			);

			return $self->text_error( 1, $element, undef, undef, undef, $rule->{ full_error } )
				if ( $citizenship == 70 ) and $value =~ /[A-Za-z]/i;
		}

		if ( $rule->{ condition } =~ /^rf_pass_format$/ and $value ) {

			my $citizenship = $self->db->query( "
				SELECT Citizenship FROM " . $prefix . "AppData WHERE ID = ?", 
				$tables_id->{ $prefix.'AppData' }
			);

			return $self->text_error( undef, $element, undef, undef, undef, $rule->{ full_error } )
				if ( $citizenship == 70 ) and $value !~ /^[0-9]{9}$/i;
		}
		
		if ( $rule->{ condition } =~ /^(more|less)_than$/ ) {
			
			my $type = $1;
			
			my $error_type = ( $type eq 'more' ? 29 : 28 );
			
			return $self->text_error( $error_type, $element, undef, $rule->{ offset } ) 
				if (
					( ( $type eq 'more' ) and ( $value < $rule->{ offset } ) )
					or
				 	( ( $type eq 'less' ) and ( $value > $rule->{ offset } ) )
				);
		}
	}
}

1;