package Shutter::Screenshot::Selector::SelectionModel;

use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;

has x => (is => 'rw', default => 0);
has y => (is => 'rw', default => 0);
has width => (is => 'rw', default => 0);
has height => (is => 'rw', default => 0);
has is_active => (is => 'rw', default => 0);

has max_w => (is => 'ro', required => 1);
has max_h => (is => 'ro', required => 1);

# Callbacks
has on_changed => (is => 'ro', default => sub { sub {} });

sub set_rect ($self, $x, $y, $w, $h) {
    if ($w < 0) { $x += $w; $w = abs($w); }
    if ($h < 0) { $y += $h; $h = abs($h); }

    $x = 0 if $x < 0;
    $y = 0 if $y < 0;
    $w = $self->max_w - $x if $x + $w > $self->max_w;
    $h = $self->max_h - $y if $y + $h > $self->max_h;
    
    return if $self->is_active && $self->x == $x && $self->y == $y && $self->width == $w && $self->height == $h;

    $self->is_active(1);
    $self->x($x);
    $self->y($y);
    $self->width($w);
    $self->height($h);
    
    $self->on_changed->($self);
    return;
}

sub clear ($self) {
    $self->is_active(0);
    $self->on_changed->($self);
    return;
}

sub move_by ($self, $dx, $dy) {
    return unless $self->is_active;
    my $nx = $self->x + $dx;
    my $ny = $self->y + $dy;
    
    $nx = 0 if $nx < 0;
    $ny = 0 if $ny < 0;
    $nx = $self->max_w - $self->width if $nx + $self->width > $self->max_w;
    $ny = $self->max_h - $self->height if $ny + $self->height > $self->max_h;

    $self->set_rect($nx, $ny, $self->width, $self->height);
    return;
}

sub resize_by ($self, $dw, $dh) {
    return unless $self->is_active;
    $self->set_rect($self->x, $self->y, $self->width + $dw, $self->height + $dh);
    return;
}

sub get_hash ($self) {
    return unless $self->is_active;
    return { x => $self->x, y => $self->y, width => $self->width, height => $self->height };
}

1;
