package autoform2::Controller::Autoform;
use Mojo::Base 'Mojolicious::Controller';

sub index {

  my $self = shift;

  $self->render();
}

sub dummy {

  my $self = shift;
  
  my $dummy_data = [
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
	{
		name => "field4",
		label => "dummy field 3 - simple text",
		type => "text",
	},
  ];

  $self->render(json => $dummy_data);
}

1;
