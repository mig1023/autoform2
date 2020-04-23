package autoform2::ORM::Services;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( get_step_by_id get_id_by_step get_all_visa_categories get_app_visa_and_center get_current_apps mod_last_error_date get_same_info_for_timeslots );

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

		my $all_visas = $self->query( 'selallkeys', __LINE__, "
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
		
		( $app_data->{ center }, $app_data->{ vtype } ) = $self->query( 'sel1', __LINE__, "
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
	
	my $all = $self->query( 'sel1', __LINE__, "
		SELECT COUNT(AutoAppData.ID) FROM AutoToken
		JOIN AutoAppData ON AutoToken.AutoAppID = AutoAppData.AppID
		WHERE Token = ?", $self->{ token }
	);
	
	my $max = $self->query( 'sel1', __LINE__, "
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
	
	return $self->query( 'query', __LINE__, "
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
			$app->{ appdate }, $app->{ urgent } ) = $self->query( 'sel1', __LINE__, "
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

1;