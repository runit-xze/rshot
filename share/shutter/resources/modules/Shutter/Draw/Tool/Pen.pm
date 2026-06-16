package Shutter::Draw::Tool::Pen;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has drawing_tool => (is => 'ro', required => 1);

sub draw ($self, $cr) {
    # Handled by GooCanvas2
}

sub on_click ($self, $event) {
    $self->drawing_tool->create_polyline($event, undef, FALSE);
}

sub on_drag ($self, $event) {
    # Logic currently handled inside DrawingTool.pm:2020
    # Will extract this next.
}

1;


1;
