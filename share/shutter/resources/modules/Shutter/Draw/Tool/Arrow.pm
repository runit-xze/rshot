package Shutter::Draw::Tool::Arrow;

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
    # default arrow behavior: create line with end_arrow TRUE
    $self->drawing_tool->create_line($event, undef, TRUE, FALSE);
}

sub on_drag ($self, $event) {
    # Handled by DrawingTool for now
}


sub on_drag_creation_shape {
	my ($self, $item, $target, $ev) = @_;
	my $dt = $self->drawing_tool;
	$dt->deactivate_all($item);
	$dt->{_current_item} = $item;
	$dt->{_items}{$item}{'bottom-right-corner'}->{res_x} = $ev->x;
	$dt->{_items}{$item}{'bottom-right-corner'}->{res_y} = $ev->y;
	$dt->{_items}{$item}{'bottom-right-corner'}->{resizing} = TRUE;
	eval { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], undef, $ev->time); };
	if ($@) { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], Gtk3::Gdk::Cursor->new('left-ptr'), $ev->time); }
	$dt->store_to_xdo_stack($item, 'create', 'undo');
	return TRUE;
}


sub on_click_creation {
	my ($self, $item, $target, $ev, $copy_item) = @_;
	require Shutter::Draw::Arrow;
	my $arrow = Shutter::Draw::Arrow->new( app => $self->drawing_tool );
	return $arrow->setup($ev, $copy_item, TRUE, FALSE);
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Arrow - Arrow drawing tool

=head1 DESCRIPTION

Implements arrow drawing.
