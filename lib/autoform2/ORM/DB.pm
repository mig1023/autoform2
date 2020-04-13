package autoform2::ORM::DB;

use utf8;
use DBI;
use Data::Dumper;

our $dbh = undef;

sub connection
# //////////////////////////////////////////////////
{
	return DBI->connect("dbi:mysql:dbname=vcs", "remoteuser", "userremote") or die;
}

sub query
# //////////////////////////////////////////////////
{
	$dbh = connection() unless defined( $dbh ) and $dbh->ping;
	
	my $type = shift;

	if ( $type eq "selall" ) {
		
		return $dbh->selectall_arrayref( shift, {Slice => {}}, @_ );
	}
	elsif ( $type eq "sel1" ) {
		
		my @result = $dbh->selectrow_arrayref( shift, {}, @_ );
		
		return ( wantarray ? @result : $result[0][0] );
	}
	else {
		return $dbh->do( shift, {}, @_ );
	}
}

1;