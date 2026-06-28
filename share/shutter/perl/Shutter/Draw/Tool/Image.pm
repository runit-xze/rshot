package Shutter::Draw::Tool::Image;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;
with 'Shutter::Draw::Tool::Base';

sub on_drag_creation_shape ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;
	$dt->deactivate_all($item);
	$dt->_current_item($item);
	$dt->{_items}{$item}{'bottom-right-corner'}->{res_x}    = $ev->x;
	$dt->{_items}{$item}{'bottom-right-corner'}->{res_y}    = $ev->y;
	$dt->{_items}{$item}{'bottom-right-corner'}->{resizing} = TRUE;
	eval { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], undef, $ev->time); };
	if ($@) { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], Gtk3::Gdk::Cursor->new('left-ptr'), $ev->time); }
	$dt->store_to_xdo_stack($item, 'create', 'undo');
	return TRUE;
}

sub on_click_creation ($self, $item, $target, $ev) {
	return $self->drawing_tool->item_factory->create_image($ev, undef);
}

1;
