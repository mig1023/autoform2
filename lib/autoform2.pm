package autoform2;
use Mojo::Base 'Mojolicious';

sub startup {

  my $self = shift;

  my $config = $self->plugin('Config');

  $self->secrets($config->{secrets});

  my $r = $self->routes;

  $r->get('/')->to('autoform#new_token');
  
  $r->get('/token/:token')->to('autoform#token');
  
  $r->get('/data/:token')->to('autoform#data');
}

1;
