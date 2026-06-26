package Shutter::Draw::CanvasManager;

use Moo;
use utf8;
use v5.40;

has registry     => (is => 'ro', required => 1);
has drawing_tool => (is => 'ro', required => 1);
has active_tool  => (is => 'rw');

sub set_tool {
	my ($self, $tool_name) = @_;
	my $tool_class = $self->registry->get_tool($tool_name);
	if ($tool_class) {
		eval "require $tool_class" or die "Could not load $tool_class: $@";
		$self->active_tool($tool_class->new(drawing_tool => $self->drawing_tool));
	} else {
		$self->active_tool(undef);
	}
	return;
}

sub on_draw {
	my ($self, $cr) = @_;
	$self->active_tool->draw($cr) if $self->active_tool;
	return;
}

sub on_click {
	my ($self, $event) = @_;
	$self->active_tool->on_click($event) if $self->active_tool;
	return;
}

sub on_drag {
	my ($self, $event) = @_;
	$self->active_tool->on_drag($event) if $self->active_tool;
	return;
}

sub acquire_focus {
	my ($self, $item, $ev, $cursor) = @_;
	my $dt = $self->drawing_tool;
	eval { $dt->{_canvas}->pointer_grab($item, ['pointer-motion-mask', 'button-release-mask'], $cursor, $ev->time); };
	if ($@) {

		# workaround for https://gitlab.gnome.org/GNOME/goocanvas/-/merge_requests/8
		$dt->{_canvas}->pointer_grab($item, ['pointer-motion-mask', 'button-release-mask'], Gtk3::Gdk::Cursor->new('left-ptr'), $ev->time);
	}
	$dt->{_canvas}->grab_focus($item);
	return;
}

sub release_focus {
	my ($self, $item, $ev) = @_;
	my $dt = $self->drawing_tool;
	$dt->{_canvas}->pointer_ungrab($item, $ev->time);
	$dt->{_canvas}->keyboard_ungrab($item, $ev->time);
	return;
}

1;

__END__

=head1 NAME

Shutter::Draw::CanvasManager - Manages the drawing canvas and tool delegation

=head1 DESCRIPTION

Delegates drawing events to the currently active tool.
