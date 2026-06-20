package Shutter::Draw::Tool::Rectangle;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has drawing_tool => (is => 'ro', required => 1);

sub draw ($self, $cr) {
    # Rectangle drawing logic
}

sub on_click ($self, $event) {
    $self->drawing_tool->create_rectangle($event, undef);
}

sub on_drag ($self, $event) {
    # Rectangle drag logic
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Rectangle - Rectangle drawing tool

=head1 DESCRIPTION

Implements rectangle drawing.
