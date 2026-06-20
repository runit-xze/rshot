package Shutter::Draw::Tool::Blur;

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
    $self->drawing_tool->create_pixel_image($event, undef);
}

sub on_drag ($self, $event) {
    # Handled by DrawingTool for now
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Blur - Blur/pixelize drawing tool

=head1 DESCRIPTION

Implements blur/pixelize tool.
