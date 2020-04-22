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
	
	my $new_token = token_generation( $self );
	
	$self->redirect_to( "/t/$new_token" );
}

sub token
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $token = $self->param( "t" );

	$self->render( token => $token );
}

sub data
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	# my $token = $self->param( "t" );
	
	my $tmp_data = $self->req->json;
	
	my $tmp = undef;
	if ( $tmp_data->{ direction } eq 'next' ) {
		$tmp = dummy_data()->{ 2 };
	}
	else {
		$tmp = dummy_data()->{ 1 };
	}
  
	$self->render( json => $tmp );
}

1;
