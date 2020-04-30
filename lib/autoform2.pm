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
	
	$self->helper(
		db => sub {
			return Mojo::mysql->strict_mode( 'mysql://remoteuser:userremote@127.0.0.1/vcs' )->db;
		}
	);
	
	$self->helper( 'token.generation' => \&{ autoform2::Other::Token::generation } );
	$self->helper( 'token.check' => \&{ autoform2::Other::Token::check } );

	my $r = $self->routes;

	$r->any( '/' )->to( 'autoform#new_token' );
  
	$r->any( '/t/:token' )->to( 'autoform#t' );
  
	$r->post( '/data/:token' )->to( 'autoform#data' );
}

1;
