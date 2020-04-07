package autoform2::Controller::Autoform;
use Mojo::Base 'Mojolicious::Controller';

sub new_token {

	my $self = shift;
	
	my $new_token = int( rand( 10000 ) );
	
	$self->redirect_to( "/token/$new_token" );
}

sub token {

	my $self = shift;
	
	my $token = $self->param( "token" );

	$self->render( token => $token );
}

sub data {

	my $self = shift;
	
	my $token = $self->param( "token" );
  
	my $dummy_data = [
		{
			name => "token_field",
			label => "token: $token",
			type => "text",
		},
		{
			name => "field1",
			label => "dummy field 1",
			type => "input",
			val => "",
		},
		{
			name => "field2",
			label => "dummy checkbox 1",
			type => "checkbox",
			val => "",
		},
		{
			name => "field3",
			label => "dummy field 2",
			type => "input",
			val => "",
		},
	];

	$self->render( json => $dummy_data );
}

1;
