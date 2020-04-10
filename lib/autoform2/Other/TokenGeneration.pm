package autoform2::Other::TokenGeneration;

use utf8;

sub token_generation
# //////////////////////////////////////////////////
{
	my $self = shift;
	
	my ( $token_existing, $token_existed_before, $token ) = ( 1, 0, 't' );
	
	$self->{ app }->query( 'do', "LOCK TABLES AutoToken WRITE, AutoToken_expired READ" );
	
	$self->{ app }->query( 'do', "
		INSERT INTO AutoToken (
		AutoAppID, AutoAppDataID, AutoSchengenAppDataID, Step, LastError, Finished, Draft, StartDate, LastIP) 
		VALUES (0, 0, 0, ?, '', 0, 0, now(), ?)", 1, 1
	);
	
	my $appid = $self->{ app }->query( 'sel1', "SELECT last_insert_id()" ) || 0;
	
	my $appidcode = "-$appid-";

	my @alph = split( //, '0123456789abcdefghigklmnopqrstuvwxyz' );

	do {
		$token = 't';
		
		$token .= $alph[ int( rand( 36 ) ) ] for ( 1..63 );
	
		substr( $token, 10, length( $appidcode ) ) = $appidcode;
			
		$token_existing = $self->{ app }->query( 'sel1', "
			SELECT ID FROM AutoToken WHERE Token = ?", $token
		) || 0;
		
		$token_existed_before = $self->{ app }->query( 'sel1', "
			SELECT ID FROM AutoToken_expired WHERE Token = ?", $token
		) || 0;
				
	} while ( $token_existing || $token_existed_before );
	
	$self->{ app }->query( 'query', "
		UPDATE AutoToken SET Token = ? WHERE ID = ?", $token, $appid
	);

	$self->{ app }->query( 'query', "UNLOCK TABLES");	
	
	return $token;
}

1;