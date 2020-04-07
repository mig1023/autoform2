package autoform2;
use Mojo::Base 'Mojolicious';

sub startup {

  my $self = shift;

  my $config = $self->plugin('Config');

  $self->secrets($config->{secrets});

  my $r = $self->routes;

  $r->get('/')->to('autoform#index');
  
  $r->get('/dummy')->to('autoform#dummy');
}

1;
