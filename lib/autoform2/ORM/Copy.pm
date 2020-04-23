package autoform2::ORM::Copy;

use utf8;
use Exporter;

@ISA = qw( Exporter );
our @EXPORT = qw( copy_information );

sub copy_information
# //////////////////////////////////////////////////
{
	my ( $self, $tables_id ) = @_;

	return unless $tables_id;

	my $all_elements = $self->get_content_rules();
	
	my $copy_tables = {};

	for my $page ( keys %$all_elements ) {
	
		my $elements = $all_elements->{ $page };
		
		next if $elements =~ /\[/;
		
		for my $element ( @$elements ) {
	
			next unless $element->{ special } =~ /copy_from_other_applicants/;
			
			my $table = $element->{ db }->{ table };
			
			$copy_tables->{ $table } = {} unless ref( $copy_tables->{ $table } ) eq 'HASH';
			
			$copy_tables->{ $table }->{ $element->{ db }->{ name } } = 1;
		}
	}

	for my $table ( keys %$copy_tables ) {

		next if !$tables_id->{ $table }->{ target } or !$tables_id->{ $table }->{ source };

		my $request = '';
		
		my $send = '';
	
		for my $row ( keys %{ $copy_tables->{ $table } } ) {
		
			$request .= "$row, ";
			
			$send .=  "$row = ?, ";
		}
		$_ =~ s/,\s$// for ( $request, $send );

		my @values = $self->query( 'sel1', __LINE__, "
			SELECT $request FROM Auto$table WHERE ID = ?", $tables_id->{ $table }->{ source }
		);

		$self->query( 'query', __LINE__, "
			UPDATE Auto$table SET $send WHERE ID = ?", {}, @values, $tables_id->{ $table }->{ target }
		);
	}
	
	$self->query( 'query', __LINE__, "
		UPDATE AutoAppData SET Copypasta = 1 WHERE ID = ?", {}, $tables_id->{ AppData }->{ target }
	);
}


1;