package autoform2;
use Mojo::Base 'Mojolicious';
use Mojo::mysql;

use utf8;

sub startup
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	$self->helper(
		db => sub {
			return Mojo::mysql->strict_mode( 'mysql://remoteuser:userremote@127.0.0.1/vcs' )->db;
		}
	);
	
	my $config = $self->plugin( 'Config' );

	$self->secrets( $config->{ secrets } );

	my $r = $self->routes;

	$r->any( '/' )->to( 'autoform#new_token' );
  
	$r->any( '/t/:token' )->to( 'autoform#t' );
  
	$r->post( '/data/:token' )->to( 'autoform#data' );
}

1;
