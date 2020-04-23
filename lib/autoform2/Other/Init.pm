package autoform2::Other::Init;

use utf8;
use Exporter;

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
}

1;