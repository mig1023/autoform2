package autoform2::Controller::Autoform;
use Mojo::Base 'Mojolicious::Controller';

sub index {

  my $self = shift;

  $self->render(msg => 'Autoform2 hello world');
}

1;
