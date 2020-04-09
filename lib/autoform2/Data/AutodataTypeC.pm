package autoform2::Data::AutodataTypeC;

sub dummy_data {

	my $token = shift;
	
	return [
		{
			name => "token_field",
			label => "token: $token",
			type => "text",
		},
		{
			name => "field1",
			label => "dummy field 1",
			type => "input",
			val => "",
		},
		{
			name => "field2",
			label => "dummy checkbox 1",
			type => "checkbox",
			val => "",
		},
		{
			name => "field3",
			label => "dummy field 2",
			type => "input",
			val => "",
		},
	];
};

1;