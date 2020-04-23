package autoform2::ORM::ORM;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( get_names_db_for_save_or_get get_current_table_id check_data_from_db get_content_rules get_content_rules_hash_opt );

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
	
	my @ids = $self->db->query( "
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

1;