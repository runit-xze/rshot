package Shutter::Draw::CanvasManager;

use Moo;
use utf8;
use v5.40;

has registry => (is => 'ro', required => 1);
has active_tool => (is => 'rw');

sub set_tool ($self, $tool_name) {
    my $tool_class = $self->registry->get_tool($tool_name);
    $self->active_tool($tool_class->new);
}

sub on_draw ($self, $cr) {
    $self->active_tool->draw($cr) if $self->active_tool;
}

sub on_click ($self, $event) {
    $self->active_tool->on_click($event) if $self->active_tool;
}

sub on_drag ($self, $event) {
    $self->active_tool->on_drag($event) if $self->active_tool;
}

1;

__END__

=head1 NAME

Shutter::Draw::CanvasManager - Manages the drawing canvas and tool delegation

=head1 DESCRIPTION

Delegates drawing events to the currently active tool.
