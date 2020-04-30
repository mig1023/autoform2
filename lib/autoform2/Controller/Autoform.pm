package autoform2::Controller::Autoform;

use utf8;
use Mojo::Base 'Mojolicious::Controller';
use Data::Dumper;



sub new_token
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $new_token = $self->app->token->generation();
	
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
	
	my $tmp_page_num = ( $tmp_data->{ direction } eq 'next' ? 2 : 1);
  
	$self->render( json => $self->app->model->pages->get_page( $tmp_page_num ) );
}

1;
