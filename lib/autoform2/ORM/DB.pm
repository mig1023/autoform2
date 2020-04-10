package autoform2::ORM::DB;

use utf8;
use DBI;
use Data::Dumper;

sub connection
# //////////////////////////////////////////////////
{
	my $self = shift;

	my $db = DBI->connect("dbi:mysql:dbname=vcs", "remoteuser", "userremote") or die;

	$self->helper(db => sub { return $db });
	
	$self->helper(query => sub {
			
			my $self = shift;
			my $type = shift;
	
			if ( $type eq "selall" ) {
				
				return $db->selectall_arrayref( shift, {Slice => {}}, @_ );
			}
			elsif ( $type eq "sel1" ) {
				
				my @result = $db->selectrow_arrayref( shift, {}, @_ );
				
				return $result[0][0];
			}
			else {
				return $db->do( shift, {}, @_ );
			}
		}
	);
}

1;