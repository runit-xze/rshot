package Shutter::Draw::Tool::Blur;

use Moo;
use utf8;
use v5.40;
use GooCanvas2;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has event     => (is => 'rw', lazy    => 1);
has copy_item => (is => 'rw', lazy    => 1);
has X         => (is => 'rw', default => sub { 0 });
has Y         => (is => 'rw', default => sub { 0 });
has width     => (is => 'rw', default => sub { 0 });
has height    => (is => 'rw', default => sub { 0 });

sub draw ($self, $cr) {

	# Handled by GooCanvas2
}

sub on_click ($self, $event) {
	return $self->drawing_tool->create_pixel_image($event, undef);
}

sub on_drag ($self, $event) {

	# Handled by DrawingTool for now
}

sub on_drag_creation_shape ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;
	$dt->deactivate_all($item);
	$dt->{_current_item}                                    = $item;
	$dt->{_items}{$item}{'bottom-right-corner'}->{res_x}    = $ev->x;
	$dt->{_items}{$item}{'bottom-right-corner'}->{res_y}    = $ev->y;
	$dt->{_items}{$item}{'bottom-right-corner'}->{resizing} = TRUE;
	eval { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], undef, $ev->time); };
	if ($@) { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], Gtk3::Gdk::Cursor->new('left-ptr'), $ev->time); }
	$dt->store_to_xdo_stack($item, 'create', 'undo');
	return TRUE;
}

sub on_click_creation ($self, $item, $target, $ev, $copy_item = undef) {
	return $self->setup($ev, $copy_item);
}

sub setup ($self, $event, $copy_item) {
	my $dt = $self->drawing_tool;

	$self->event($event);
	$self->copy_item($copy_item);
	$self->_check_event_and_copy_item;

	my $item = $self->_create_item;

	$dt->current_new_item($item) unless $self->copy_item;
	$dt->{_items}{$item} = $item;

	my $blank = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, 2, 2);
	$blank->fill(0x00000000);

	$dt->{_items}{$item}{pixelize} = GooCanvas2::CanvasImage->new(
		parent => $dt->canvas->get_root_item,
		pixbuf => $blank,
		x      => $item->get('x'),
		y      => $item->get('y'),
		width  => 2,
		height => 2,
	);

	$dt->{_items}{$item}{type} = 'pixelize';
	$dt->{_items}{$item}{uid}  = $dt->uid;
	$dt->increase_uid;

	$dt->handle_rects('create', $item);

	if ($self->copy_item) {
		$dt->{_items}{$item}{pixelize}->set(
			x      => int $item->get('x'),
			y      => int $item->get('y'),
			width  => $item->get('width'),
			height => $item->get('height'),
			pixbuf => $dt->get_pixelated_pixbuf_from_canvas($item),
		);
		$dt->handle_embedded('update', $item, undef, undef, TRUE);
	}

	$dt->setup_item_signals($dt->{_items}{$item}{pixelize});
	$dt->setup_item_signals_extra($dt->{_items}{$item}{pixelize});
	$dt->setup_item_signals($item);
	$dt->setup_item_signals_extra($item);

	return $item;
}

sub _check_event_and_copy_item ($self) {
	if ($self->event) {
		$self->X($self->event->x);
		$self->Y($self->event->y);
	} elsif ($self->copy_item) {
		$self->X($self->copy_item->get('x') + 20);
		$self->Y($self->copy_item->get('y') + 20);
		$self->width($self->copy_item->get('width'));
		$self->height($self->copy_item->get('height'));
	}
	return;
}

sub _create_item ($self) {
	my $dt = $self->drawing_tool;

	return GooCanvas2::CanvasRect->new(
		parent            => $dt->canvas->get_root_item,
		x                 => $self->X,
		y                 => $self->Y,
		width             => $self->width,
		height            => $self->height,
		'fill-color-rgba' => 0,
		'line-dash'       => GooCanvas2::CanvasLineDash->newv([5, 5]),
		'line-width'      => 1,
		'stroke-color'    => 'gray',
	);
}

1;
