package autoform2;
use Mojo::Base 'Mojolicious';
use Mojo::mysql;

use utf8;
use autoform2::Other::Init;

sub startup
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my $config = $self->plugin( 'Config' );

	$self->secrets( $config->{ secrets } );
	
	start_init( $self );

	my $r = $self->routes;

	$r->any( '/' )->to( 'autoform#new_token' );
  
	$r->any( '/t/:token' )->to( 'autoform#t' );
  
	$r->post( '/data/:token' )->to( 'autoform#data' );
}

1;
