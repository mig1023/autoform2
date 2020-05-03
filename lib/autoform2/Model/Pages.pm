package autoform2::Model::Pages;

use utf8;
use Exporter;
use Data::Dumper;
use autoform2::Data::AutodataTypeC;

sub get_page
# //////////////////////////////////////////////////
{
	my ( $self, $pid ) = @_;

	return dummy_data()->{ $pid };
}



1;