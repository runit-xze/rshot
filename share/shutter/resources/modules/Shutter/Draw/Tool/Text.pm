package Shutter::Draw::Tool::Text;

use Moo;
use utf8;
use v5.40;
use GooCanvas2;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has event        => (is => 'rw', lazy    => 1);
has copy_item    => (is => 'rw', lazy    => 1);
has X            => (is => 'rw', default => sub { 0 });
has Y            => (is => 'rw', default => sub { 0 });
has width        => (is => 'rw', default => sub { 0 });
has height       => (is => 'rw', default => sub { 0 });
has stroke_color => (is => 'rw', lazy    => 1, default => sub { shift->drawing_tool->stroke_color });
has line_width   => (is => 'rw', lazy    => 1, default => sub { shift->drawing_tool->line_width });
has text_str     => (is => 'rw', lazy    => 1, default => sub { shift->drawing_tool->gettext->get('New text...') });

sub draw ($self, $cr) {

	# Handled by GooCanvas2
}

sub on_click ($self, $event) {
	return $self->drawing_tool->create_text($event, undef);
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

	$dt->{_items}{$item}{text} = GooCanvas2::CanvasText->new(
		parent                => $dt->canvas->get_root_item,
		text                  => "<span font_desc='" . $dt->font . "' >" . $self->text_str . "</span>",
		x                     => $item->get('x'),
		y                     => $item->get('y'),
		width                 => -1,
		anchor                => 'nw',
		'use-markup'          => TRUE,
		'fill-color-gdk-rgba' => $self->stroke_color,
		'line-width'          => $self->line_width,
	);

	my $tb = $dt->{_items}{$item}{text}->get_bounds;
	my $w  = abs($tb->x1 - $tb->x2);
	my $h  = abs($tb->y1 - $tb->y2);

	if ($self->copy_item) {
		$dt->{_items}{$item}->set(
			x          => $dt->{_items}{$item}->get('x') + 20,
			y          => $dt->{_items}{$item}->get('y') + 20,
			width      => $w,
			height     => $h,
			visibility => 'hidden',
		);
	} else {
		$dt->{_items}{$item}->set(
			x          => $self->event->x - $w,
			y          => $self->event->y - $h,
			width      => $w,
			height     => $h,
			visibility => 'hidden',
		);
	}

	$dt->handle_embedded('hide', $item);

	$dt->{_items}{$item}{type} = 'text';
	$dt->{_items}{$item}{uid}  = $dt->uid;
	$dt->increase_uid;
	$dt->{_items}{$item}{stroke_color} = $dt->stroke_color;

	$dt->handle_rects('create', $item);
	if ($self->copy_item) {
		$dt->handle_embedded('update', $item);
		$dt->handle_rects('hide', $item);
	}

	$dt->setup_item_signals($dt->{_items}{$item}{text});
	$dt->setup_item_signals_extra($dt->{_items}{$item}{text});
	$dt->setup_item_signals($item);
	$dt->setup_item_signals_extra($item);

	return $item;
}

sub _check_event_and_copy_item ($self) {
	my $dt = $self->drawing_tool;

	if ($self->event) {
		$self->X($self->event->x);
		$self->Y($self->event->y);
	} elsif ($self->copy_item) {
		$self->X($self->copy_item->get('x') + 20);
		$self->Y($self->copy_item->get('y') + 20);
		$self->width($self->copy_item->get('width'));
		$self->height($self->copy_item->get('height'));
		$self->stroke_color($dt->{_items}{$self->copy_item}{stroke_color});
		$self->text_str($dt->{_items}{$self->copy_item}{text}->get('text'));
		$self->line_width($dt->{_items}{$self->copy_item}{text}->get('line-width'));
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

sub is_text_tool {
	return 1;
}

1;
