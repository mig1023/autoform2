package autoform2::Controller::Autoform;

use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;

use autoform2::Data::AutodataTypeC;
use autoform2::Other::TokenGeneration;


sub new_token
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $new_token = autoform2::Other::TokenGeneration::token_generation( $self );
	
	$self->redirect_to( "/token/$new_token" );
}

sub token
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $token = $self->param( "token" );

	$self->render( token => $token );
}

sub data
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $token = $self->param( "token" );
  
	my $dummy_data = autoform2::Data::AutodataTypeC::dummy_data( $token );

	$self->render( json => $dummy_data );
}

1;
