package autoform2::Other::TokenGeneration;

use utf8;

sub token_generation
# //////////////////////////////////////////////////
{
	my $self = shift;

	my @alph = split( //, '0123456789abcdefghigklmnopqrstuvwxyz' );

	$token = 't';
	
	$token .= $alph[ int( rand( 36 ) ) ] for ( 1..63 );
	
	return $token;
}

1;