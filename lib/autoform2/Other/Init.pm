package autoform2::Other::Init;

use utf8;
use Exporter;
use autoform2::Other::Token;
use autoform2::Model::Pages;

@ISA = qw( Exporter );
our @EXPORT = qw( start_init );

sub start_init
# //////////////////////////////////////////////////
{
	my $self = shift;

	$self->helper(
		db => sub {
			return Mojo::mysql->strict_mode( 'mysql://remoteuser:userremote@127.0.0.1/vcs' )->db;
		}
	);

	$self->helper( 'token.generation' => \&{ autoform2::Other::Token::generation } );
	$self->helper( 'token.get' => \&{ autoform2::Other::Token::get } );
	$self->helper( 'token.check' => \&{ autoform2::Other::Token::check } );
	$self->helper( 'model.pages.get_page' => \&{ autoform2::Model::Pages::get_page } );
}

1;