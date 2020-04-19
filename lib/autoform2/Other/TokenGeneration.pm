package autoform2::Other::TokenGeneration;

use utf8;
use Exporter;
use Math::Random::Secure qw( irand );

@ISA = qw( Exporter );
our @EXPORT = qw( token_generation );

sub token_generation
# //////////////////////////////////////////////////
{
	my $self = shift;

	my $transaction = $self->db->begin;
	
	my $appid = $self->db->query( "
		INSERT INTO AutoToken (
		AutoAppID, AutoAppDataID, AutoSchengenAppDataID, Step, LastError, Finished, Draft, StartDate, LastIP) 
		VALUES (0, 0, 0, ?, '', 0, 0, now(), ?)",
		1, $self->tx->remote_address
	)->last_insert_id;

	my $appidcode = "-$appid-";

	my @alph = split( //, '0123456789abcdefghigklmnopqrstuvwxyz' );
	
	my $token = undef;
	
	$token .= $alph[ int( irand( 36 ) ) ] for ( 1..64 );

	substr( $token, 10, length( $appidcode ) ) = $appidcode;

	$self->db->query( "
		UPDATE AutoToken SET Token = ? WHERE ID = ?", $token, $appid
	);
	
	$transaction->commit;

	return $token;
}

1;