package autoform2::ORM::Services;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( get_step_by_id get_id_by_step get_all_visa_categories get_app_visa_and_center get_current_apps mod_last_error_date get_same_info_for_timeslots get_lang_if_exist get_collect_date create_clear_form citizenship_check_fail );

sub get_step_by_id
# //////////////////////////////////////////////////
{
	my ( $self, $page_id ) = @_;
	
	return $page_id if $page_id < 1000;
	
	my $page_content = $self->get_content_rules( undef, 'full' );
	
	for my $page ( keys %$page_content ) {
	
		return $page if $page_content->{ $page }->[ 0 ]->{ page_db_id } eq $page_id;
	}
	
	return 0;
}

sub get_id_by_step
# //////////////////////////////////////////////////
{
	my ( $self, $step ) = @_;
	
	my $page_content = $self->get_content_rules( undef, 'full' );

	my $id_page = $page_content->{ $step }->[ 0 ]->{ page_db_id };
	
	return $id_page;
}

sub get_all_visa_categories
# //////////////////////////////////////////////////
{
	my $self = shift;

	my $category = $self->cached( 'autoform_all_vtypes' );
		
	if ( !$category  ) {

		$category = {};

		my $all_visas = $self->db->query("
			SELECT ID, Category FROM VisaTypes"
		);

		$category->{ $_->{ ID } } = $_->{ Category } for @$all_visas;

		$self->cached( 'autoform_all_vtypes', $category );
	}

	return $category;
}

sub get_app_visa_and_center
# //////////////////////////////////////////////////
{
	my $self = shift;

	return ( 1, 'C' ) if !$self->{ token };

	my $app_data = {};
	
	$app_data->{ $_ } = $self->cached( 'autoform_' . $self->{ token } . '_' . $_ ) for ( 'vtype', 'center' );
		
	if ( !$app_data->{ vtype } or !$app_data->{ center } ) {
		
		( $app_data->{ center }, $app_data->{ vtype } ) = $self->db->query("
			SELECT CenterID, VType
			FROM AutoAppointments
			JOIN AutoToken ON AutoAppointments.ID = AutoToken.AutoAppID
			WHERE Token = ?", $self->{ token }
		);

		for ( 'vtype', 'center' ) {

			$app_data->{ $_ } = 'X' unless $app_data->{ $_ };

			$self->cached( 'autoform_' . $self->{ token } . '_' . $_, $app_data->{ $_ } );
		}
	}

	for ( 'vtype', 'center' ) {
		
		$app_data->{ $_ } = undef if $app_data->{ $_ } eq 'X';
	}
	
	return ( $app_data->{ center }, 'C' ) if !$app_data->{ vtype };
	
	my $visa_categories = $self->get_all_visa_categories();

	return ( $app_data->{ center }, $visa_categories->{ $app_data->{ vtype } } );
}

sub get_current_apps
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $all = $self->db->query("
		SELECT COUNT(AutoAppData.ID) FROM AutoToken
		JOIN AutoAppData ON AutoToken.AutoAppID = AutoAppData.AppID
		WHERE Token = ?", $self->{ token }
	);
	
	my $max = $self->db->query("
		SELECT NCount FROM AutoToken
		JOIN AutoAppointments ON AutoToken.AutoAppID = AutoAppointments.ID
		WHERE Token = ?", $self->{ token }
	);
	
	$all = 0 unless $all;
	$max = 0 unless $max;
	
	return ( $all, $max );
}

sub mod_last_error_date
# //////////////////////////////////////////////////
{
	my ( $self, $last_error ) = @_;
	
	$last_error =~ s/[^A-Za-zАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчшщъыьэюя0-9\s\-\.\,\:\"\(\)№_]/!/g;
	
	return $self->db->query("
		UPDATE AutoToken SET LastError = ? WHERE Token = ?", {},
		$last_error, $self->{ token }
	);
}

sub get_same_info_for_timeslots
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $app = {};

	( $app->{ persons }, $app->{ center }, $app->{ fdate }, $app->{ timeslot }, 
			$app->{ appdate }, $app->{ urgent } ) = $self->db->query("
		SELECT count(AutoAppData.ID), CenterID, SDate, TimeslotID, AppDate, Urgent
		FROM AutoToken 
		JOIN AutoAppData ON AutoToken.AutoAppID = AutoAppData.AppID
		JOIN AutoAppointments ON AutoToken.AutoAppID = AutoAppointments.ID
		WHERE Token = ?", $self->{ token }
	);
	
	$app->{ fdate_iso } = $app->{ fdate };
	
	$app->{ fdate } = $self->date_format( $app->{ fdate } );

	return $app;
}


sub get_lang_if_exist
# //////////////////////////////////////////////////
{
	my ( $self, $line, $static_key, $dynamic_key ) = @_;
	
	my $lang_version = $self->lang( $static_key . $dynamic_key ) || $line;

	$line = $lang_version unless $lang_version =~ /^$static_key/;
	
	return $line;
}

sub get_collect_date
# //////////////////////////////////////////////////
{
	my $self = shift;

	my $collect_dates = $self->cached( 'autoform_collectdates' );
		
	if ( !$collect_dates ) {
	
		my $collect_dates_array = $self->db->query("
			SELECT ID, CollectDate, cdSimpl, cdUrgent, cdCatD
			FROM Branches where isDeleted = 0 and Display = 1"
		);
		$collect_dates = {};
		
		for my $date ( @$collect_dates_array ) {

			$collect_dates->{ $date->{ ID } }->{ $_ } = $date->{ $_ }
				for ( 'CollectDate', 'cdSimpl', 'cdUrgent', 'cdCatD' );
		}

		$self->cached( 'autoform_collectdates', $collect_dates );
	}
	
	my ( $center_id, $category ) = $self->get_app_visa_and_center();

	$collect_dates = $collect_dates->{ $center_id };

	return 0 unless $collect_dates->{ CollectDate };
	
	return $collect_dates->{ cdCatD } if $category eq 'D';
	
	return ( $collect_dates->{ cdUrgent } ? $collect_dates->{ cdUrgent } : $collect_dates->{ cdSimpl } );
}

sub create_clear_form
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	$self->db->query("
		INSERT INTO AutoAppointments (RDate, Login, Draft) VALUES (now(), ?, 1)", {}, 
		$self->{ vars }->get_session->{'login'}
	);
		
	my $app_id = $self->db->query("
		SELECT last_insert_id()"
	) || 0;
	
	$self->db->query("
		UPDATE AutoToken SET AutoAppID = ?, StartDate = now(), LastIP = ? WHERE Token = ?", {}, 
		$app_id, $ENV{ HTTP_X_REAL_IP }, $self->{ token }
	);
}

sub citizenship_check_fail
# //////////////////////////////////////////////////
{
	my ( $self, $value ) = @_;
	
	my %citizenship = map { $_ => 1 } split( /,\s?/, $value );

	my $applicants = $self->query( 'selallkeys', __LINE__, "
		SELECT Citizenship FROM AutoAppData
		JOIN AutoToken ON AutoAppData.AppID = AutoToken.AutoAppID
		WHERE Token = ?", $self->{ token }
	);
	
	for ( @$applicants ) {
	
		return 1 if !exists $citizenship{ $_->{ Citizenship } };
	}
	
	return 0;
}

1;