package Shutter::Draw::Tool::Ellipse;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

sub draw ($self, $cr) {
    # Ellipse drawing logic
}

sub on_click ($self, $event) {
    # Ellipse click logic
}

sub on_drag ($self, $event) {
    # Ellipse drag logic
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Ellipse - Ellipse drawing tool

=head1 DESCRIPTION

Implements ellipse drawing.
