package autoform2::ORM::ORM;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( get_names_db_for_save_or_get get_current_table_id check_data_from_db get_content_rules get_content_rules_hash_opt init_add_param );

sub get_names_db_for_save_or_get
# //////////////////////////////////////////////////
{
	my ( $self, $page_content, $save_or_get, $app_finished ) = @_;
	
	my $request_tables = {};
	
	my $alt_data_source = {};

	return if $page_content =~ /^\[/;
	
	if ( ref( $page_content ) eq 'HASH' ) {
	
		my $allpages_content = [];
	
		for my $page ( keys %$page_content ) {
		
			next if $page_content->{ $page } =~ /^\[/;
			
			push( @$allpages_content, $_ ) for @{ $page_content->{ $page } };
		}
		
		$page_content = $allpages_content;
	}

	for my $element (@$page_content) {

		next if ( $element->{ type } eq 'info' ) and ( $save_or_get eq 'save' );
		
		next if ref( $element->{ db } ) ne 'HASH';

		my $prefix = ( $element->{ db }->{ table } !~ /^Auto/i ? 'Auto' : '' );
		
		$prefix = '' if $app_finished eq 'finished';

		if ( $element->{ db }->{ name } eq 'complex' ) {
		
			for my $sub_element ( keys %{ $element->{ param } } ) {
			
				$request_tables->{ $prefix . $element->{ db }->{ table } }->{ $element->{ param }->{ $sub_element }->{ db } } = 
					$sub_element;
			}
		}
		else { 
			$request_tables->{ $prefix . $element->{ db }->{ table } }->{ $element->{ db }->{ name } } = $element->{ name };
			
			if ( $element->{ load_if_free_field } ) {
			
				$alt_data_source->{ $element->{ name } }->{ table } = $prefix . $element->{ load_if_free_field }->{ table };
				
				$alt_data_source->{ $element->{ name } }->{ field } = $element->{ load_if_free_field }->{ name };
			}
		}
	}
	
	$request_tables->{ alternative_data_source } = $alt_data_source;

	return $request_tables;
}

sub get_current_table_id
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $tables_id = {};

	my $tables_controled_by_AutoToken = VCS::Site::autodata::get_tables_controled_by_AutoToken();

	my @tables_list = ( 'AutoToken', keys %$tables_controled_by_AutoToken );
	
	my $request_tables = 'ID, ' . join( ', ', values %$tables_controled_by_AutoToken );
	
	my @ids = $self->db->query("
		SELECT $request_tables FROM AutoToken WHERE Token = ?", $self->{ token }
	);

	my $max_index = scalar( keys %$tables_controled_by_AutoToken );
	
	for my $id ( 0..$max_index ) {
	
		$tables_id->{ $tables_list[ $id ] } = $ids[ $id ];
	};
	
	return $tables_id;
}

sub check_data_from_db
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $table_id = $self->get_current_table_id();
	
	my $rules = $self->get_content_db_rules( 'check' );
	
	for my $table ( keys %$rules ) {
		
		my $auto_table = 'Auto' . $table;
		
		next if !$table_id->{ $auto_table };
		
		for ( keys %{ $rules->{ $table } } ) {
		
			delete $rules->{ $table }->{ $_ } unless $rules->{ $table }->{ $_ };
		}
		
		next if !( scalar keys %{ $rules->{ $table } } );

		my $request = join( ',', keys %{ $rules->{ $table } } );
		
		my $where_id = "ID = " . $table_id->{ $auto_table };
		
		$where_id = "AppID = " . $table_id->{ 'AutoAppointments' } if $auto_table eq 'AutoAppData';
		
		my $data = $self->db->query( "
			SELECT $request FROM $auto_table WHERE $where_id"
		);

		for my $app ( @$data ) {
		
			for my $field ( keys %{ $app } ) {
		
				return 25 if (
					( $rules->{ $table }->{ $field } eq 'not_empty')
					&&
					( !$app->{ $field } or $app->{ $field } eq '0000-00-00' )
				);
			}
		}
	}
	
	return 0;
}

sub get_content_rules
# //////////////////////////////////////////////////
{
	my ( $self, $current_page, $full, $need_to_init ) = @_;

	my ( $center ) = $self->get_app_visa_and_center();
		
	my $content = $self->get_content_rules_hash_opt();

	my $keys_in_current_page = {};
	my $new_content = {};
	
	my $page_order = 0;
	
	for my $page ( sort { $content->{ $a }->[ 0 ]->{ page_ord } <=> $content->{ $b }->[ 0 ]->{ page_ord } } keys %$content ) {
		
		my $page_ord = ++$page_order;
		
		$new_content->{ $page_ord } = $content->{ $page };
		
		if ( $current_page == $page_ord ) {

			for ( 'persons_in_page', 'collect_date', 'param', 'ussr_or_rf_first',
				'primetime_spb_price', 'primetime_price' ) {
			
				$keys_in_current_page->{ $_ } = ( $new_content->{ $page_ord }->[ 0 ]->{ $_ } ? 1 : 0 );
			}
		}
		
		if ( !$full && $content->{ $page }->[ 0 ]->{ replacer } ) {
		
			$new_content->{ $page_ord } = $content->{ $page }->[ 0 ]->{ replacer };
		}
		elsif ( !$full ) {
		
			delete $new_content->{ $page_ord }->[ 0 ];
			
			@{ $new_content->{ $page_ord } } = grep defined, @{ $new_content->{ $page_ord } };
		}
		else {
			$new_content->{ $page_ord }->[ 0 ]->{ page_name } = $page;
		}
	}

	$content = ( $need_to_init ? $self->init_add_param( $new_content, $keys_in_current_page ) : $new_content );
	
	return $content if !$current_page;
	
	return scalar( keys %$content ) if $current_page =~ /^length$/i;
	
	return $content->{ $current_page };
}

sub get_content_rules_hash_opt
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my ( $center, $visa_category ) = $self->get_app_visa_and_center();
		
	return VCS::Site::autodata_type_d::get_content_rules_hash() if $visa_category eq 'D';

	return VCS::Site::autodata_type_c_spb::get_content_rules_hash() if VCS::Site::autodata::this_is_spb_center( $center );

	return VCS::Site::autodata_type_c::get_content_rules_hash();
}

sub init_add_param
# //////////////////////////////////////////////////
{
	my ( $self, $content_rules, $keys ) = @_;
	
	my $info_from_db = undef;
	my $ussr_first = 0;
	my $primetime_price = 0;
	
	if ( $keys->{ param } ) {
	
		$info_from_db = $self->cached( 'autoform_addparam' );
		
		if ( !$info_from_db ) {
		
			my $info_from_sql = {
				'[centers_from_db]' => 'SELECT ID, BName FROM Branches WHERE Display = 1 AND isDeleted = 0',
				'[visas_from_db]' => 'SELECT ID, VName FROM VisaTypes WHERE OnSite = 1',
				'[brh_countries]' => 'SELECT ID, EnglishName, Ex, MemberOfEU, Schengen FROM Countries',
				'[schengen_provincies]' => 'SELECT ID, Name FROM SchengenProvinces',
			};
			
			for ( keys %$info_from_sql ) {
			
				$info_from_db->{ $_ } = $self->query( 'selall', __LINE__, $info_from_sql->{ $_ } );
			}

			for ( @{ $info_from_db->{ '[brh_countries]' } } ) {
			
				push( @{ $info_from_db->{ '[prevcitizenship_countries]' } }, $_ );
				
				push( @{ $info_from_db->{ '[citizenship_countries]' } }, $_ ) if $_->[ 2 ] == 0;
				
				push( @{ $info_from_db->{ '[eu_countries]' } }, $_ ) if $_->[ 3 ] == 1;
				
				push( @{ $info_from_db->{ '[schengen_countries]' } }, $_ ) if $_->[ 4 ] == 1;
			}

			$self->cached( 'autoform_addparam', $info_from_db );
		}
		
		$_->[ 1 ] = $self->get_lang_if_exist( $_->[ 1 ], 'mobname', $_->[ 0 ] )
			for @{ $info_from_db->{ '[centers_from_db]' } };
	
		$_->[ 1 ] = $self->get_lang_if_exist( $_->[ 1 ], 'visaname', $_->[ 0 ] )
			for @{ $info_from_db->{ '[visas_from_db]' } };
	}
	
	if ( $self->{ token } and $keys->{ persons_in_page } ) {

		my $app_person_in_app = $self->query( 'selallkeys', __LINE__, "
			SELECT AutoAppData.ID as ID, CONCAT(RFName, ' ', RLName, ', ', BirthDate) as person,
			birthdate, CURRENT_DATE() as currentdate
			FROM AutoToken 
			JOIN AutoAppData ON AutoToken.AutoAppID = AutoAppData.AppID
			WHERE AutoToken.Token = ?", $self->{ token }
		);

		for my $person ( @$app_person_in_app ) {
		
			$person->{ person } = $self->date_format( $person->{ person } );
			
			next if ( $self->age( $person->{ birthdate }, $person->{ currentdate } ) < 
					$self->{ autoform }->{ age }->{ age_for_agreements } );

			push ( @{ $info_from_db->{ '[persons_in_app]' } }, [ $person->{ ID }, $person->{ person } ] );
		};
			
		push( @{ $info_from_db->{ '[persons_in_app]' } }, [ -1, $self->lang('на доверенное лицо') ] );
	}
	
	if ( $self->{ token } and $keys->{ ussr_or_rf_first } ) {
	
		my $birthdate = $self->query( 'sel1', __LINE__, "
			SELECT DATEDIFF(AutoAppData.BirthDate, '1991-12-26')
			FROM AutoAppData
			JOIN AutoToken ON AutoAppData.ID = AutoToken.AutoAppDataID 
			WHERE AutoToken.Token = ?", $self->{ token }
		);
	
		$ussr_first = 1 if $birthdate < 0;
	}
	
	if ( $keys->{ primetime_price } ) {
	
		$primetime_price = $self->query( 'sel1', __LINE__, "
			SELECT Price FROM PriceRate
			JOIN ServicesPriceRates ON PriceRate.ID = PriceRateID
			WHERE BranchID = 41 AND RDate <= curdate() AND ServicesPriceRates.ServiceID = 2
			ORDER by PriceRate.ID DESC LIMIT 1"
		);
	}
	
	if ( $keys->{ primetime_spb_price } ) {
	
		$primetime_price = $self->query( 'sel1', __LINE__, "
			SELECT Price FROM PriceRate
			JOIN ServicesPriceRates ON PriceRate.ID = PriceRateID
			WHERE BranchID = 43 AND RDate <= curdate() AND ServicesPriceRates.ServiceID = 3
			ORDER by PriceRate.ID DESC LIMIT 1"
		);
	}
	
	if (
		$keys->{ param }
		or
		$keys->{ collect_date }
		or
		$keys->{ persons_in_page }
		or
		$keys->{ ussr_or_rf_first }
		or
		$keys->{ primetime_price }
		or
		$keys->{ primetime_spb_price }
	) {
	
		for my $page ( keys %$content_rules ) {
		
			next if $content_rules->{ $page } =~ /^\[/;
			
			for my $element ( @{ $content_rules->{ $page } } ) {

				if ( ref( $element->{ param } ) ne 'HASH' ) {
				
					my $param_array = $info_from_db->{ $element->{ param } };
					
					$element->{ param } = {};
					
					$element->{ param }->{ $_->[ 0 ] } = $_->[ 1 ] for ( @$param_array );
				}
				
				if ( exists $element->{ check_logic } and $self->{ token } and $keys->{ collect_date } ) {
				
					for ( @{ $element->{ check_logic } } ) {
					
						$_->{ offset } = $self->get_collect_date()	
							if $_->{ offset } =~ /\[collect_date_offset\]/;
					}
				}
				
				if ( $element->{ name } =~ /^(brhcountry|prev_сitizenship)$/ ) {
				
					$element->{ first_elements } = '272, 70' if $ussr_first;
				}
				
				if (
					( $keys->{ primetime_price } or $keys->{ primetime_spb_price } )
					and
					$element->{ label } =~ /\[primetime_price\]/
				) {
					$element->{ label } =~ s/\[primetime_price\]/$primetime_price/;
				}
			}
		}
	}

	return $content_rules;
}

1;