package autoform2::Model::Pages;

use utf8;
use Exporter;
use autoform2::Data::AutodataTypeC;

@ISA = qw( Exporter );
our @EXPORT = qw( get );

sub get_page
# //////////////////////////////////////////////////
{
	my ( $self, $pid ) = @_;

	return dummy_data()->{ $pid };
}

1;