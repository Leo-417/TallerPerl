package Breakout::Ball;

use strict;
use warnings;

use constant PI => 3.14159265358979;

use SDLx::Sprite;

use Breakout::Wall;

sub new {
  my ($class, $x, $y) = @_;

  return bless {
    x      => $x,
    y      => $y,
    dir    => 5 / 4 * PI + PI / 2 * rand,
    speed  => 0,
    radius => 8,
    sprite => SDLx::Sprite->new( image => 'ball.bmp' ),
  }, $class;
}

sub x      { return shift->{x} }
sub y      { return shift->{'y'} }
sub dir    { return shift->{dir} }
sub speed  { return shift->{speed} }
sub radius { return shift->{radius} }
sub sprite { return shift->{sprite} }

sub update {
  my ($self, $step, $app, @objects) = @_;

  push @objects, Breakout::Wall->new(0, 0, 16, $app->height);
  push @objects, Breakout::Wall->new($app->width - 16, 0, 16, $app->height);
  push @objects, Breakout::Wall->new(0, 0, $app->width, 16);

  while ($step > 0) {
    my $dx = cos($self->dir) * $step * $self->speed;
    my $dy = sin($self->dir) * $step * $self->speed;

    my $best;

    foreach my $object (@objects) {
      if (my $collision = $self->_collide($dx, $dy, $object)) {
        if (not defined $best or $best->{t} > $collision->{t}) {
          $best = $collision;
        }
      }
    }

    if ($best) {
      $self->{x} += $dx * $best->{t};
      $self->{y} += $dy * $best->{t};
      $best->{o}->handle_collision($self);

      if ($best->{o}->isa('Breakout::Paddle')) {
        my $offset = ($self->x - $best->{o}->x) * 2 / $best->{o}->width;
        $self->{dir} = (18 + 3 * $offset) * PI / 12;
      } else {
        $self->{dir} = ($best->{d} eq 'h' ? 3 : 2) * PI - $self->dir;
      }

      $step *= 1 - $best->{t};
    } else {
      $self->{x} += $dx;
      $self->{y} += $dy;
      $step = 0;
    }
  }
}

sub draw {
  my ($self, $app) = @_;
  $self->sprite->x($self->x - $self->radius);
  $self->sprite->y($self->y - $self->radius);
  $self->sprite->draw($app);
}

sub _collide {
  my ($self, $dx, $dy, $object) = @_;

  my $hseg = [ $object->rect->left, 0, $object->rect->right, 0 ];
  my $vseg = [ 0, $object->rect->top, 0, $object->rect->bottom, 0 ];

  if ($dy) {
    my $y = $dy < 0 ? $object->rect->bottom : $object->rect->top;
    my $t = ($y - $self->y) / $dy;

    if ($t > 0 and $t <= 1) {
      my $ix = $self->x + $t * $dx;
      if ($ix >= $object->rect->left and $ix <= $object->rect->right) {
        return {
          t => $t,
          d => 'v',
          o => $object,
        };
      }
    }
  }

  if ($dx) {
    my $x = $dx < 0 ? $object->rect->right : $object->rect->left;
    my $t = ($x - $self->x) / $dx;
    if ($t > 0 and $t <= 1) {
      my $iy = $self->y + $t * $dy;
      if ($iy >= $object->rect->top and $iy <= $object->rect->bottom) {
        return {
          t => $t,
          d => 'h',
          o => $object,
        };
      }
    }
  }

  return undef;
}

1;
