package autoform2::Other::Services;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( age lang get_file_content this_is_inner_ip );

sub age
# //////////////////////////////////////////////////
{
	my ( $self, $birth_date, $current_date ) = @_; 
	
	return 99 if ( 
		$birth_date !~ /^\d{4}\-\d{2}\-\d{2}$/
		or 
		$current_date !~ /^\d{4}\-\d{2}\-\d{2}$/
	);
	
	my $age_free_days = $self->{ vars }->getConfig( 'general' )->{ age_free_days } + 0;

	my ( $birth_year, $birth_month, $birth_day ) = split( /\-/, $birth_date ); 
	
	my ( $year, $month, $day ) = Add_Delta_Days( split( /\-/, $current_date ), $age_free_days );
	
	my $age = $year - $birth_year;
	
	$age -= 1 unless sprintf( "%02d%02d", $month, $day ) >= sprintf( "%02d%02d", $birth_month, $birth_day );
		
	$age = 0 if $age < 0;

	return $age;
}

sub lang
# //////////////////////////////////////////////////
{
	my ( $self, $text, $lang_param ) = @_;

	return if !$text;

	my $vocabulary = $self->{ vars }->{ 'VCS::Resources' }->{ 'list' };

	my $lang = ( $lang_param ? $lang_param : $self->{ 'lang' } );

	if ( ref( $text ) ne 'HASH' ) {
	
		return $vocabulary->{ $text }->{ $lang } || $text;
	}
	
	for ( keys %$text ) {

		next if !$text->{ $_ };
	
		$text->{ $_ } = $vocabulary->{ $text->{ $_ } }->{ $lang } || $text->{ $_ };
	}
	
	return $text;
}

sub get_file_content
# //////////////////////////////////////////////////
{
	my $self = shift;

	undef $/;
	
	open( my $file, '<', shift ) or return;
	
	my $content = <$file>;
	
	close $file;
	
	return $content;
}

sub this_is_inner_ip
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my %inner_ip_list_h = map { $_ => 1 } @{ VCS::Site::autodata::get_inner_ip() };

	return 1 if $inner_ip_list_h{ $ENV{ HTTP_X_REAL_IP } }; 
	
	return 0;
}	

1;