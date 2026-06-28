package Shutter::Draw::Tool::Arrow;

use Moo;
use utf8;
use v5.40;
use GooCanvas2;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has event            => (is => 'rw', lazy => 1);
has copy_item        => (is => 'rw', lazy => 1);
has end_arrow        => (is => 'rw');
has start_arrow      => (is => 'rw');
has X                => (is => 'rw', default => sub { 0 });
has Y                => (is => 'rw', default => sub { 0 });
has width            => (is => 'rw', default => sub { 0 });
has height           => (is => 'rw', default => sub { 0 });
has mirrored_w       => (is => 'rw', default => sub { 0 });
has mirrored_h       => (is => 'rw', default => sub { 0 });
has arrow_width      => (is => 'rw', default => sub { 4 });
has arrow_length     => (is => 'rw', default => sub { 5 });
has arrow_tip_length => (is => 'rw', default => sub { 4 });
has stroke_color     => (is => 'rw', lazy    => 1, default => sub { shift->drawing_tool->stroke_color });
has line_width       => (is => 'rw', lazy    => 1, default => sub { shift->drawing_tool->line_width });

sub draw ($self, $cr) {

	# Handled by GooCanvas2
}

sub on_click ($self, $event) {
	return $self->drawing_tool->item_factory->create_line($event, undef, TRUE, FALSE);
}

sub on_drag ($self, $event) {

	# Handled by DrawingTool for now
}

sub on_drag_creation_shape ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;
	$dt->deactivate_all($item);
	$dt->_current_item($item);
	$dt->_items->{$item}{'bottom-right-corner'}->{res_x}    = $ev->x;
	$dt->_items->{$item}{'bottom-right-corner'}->{res_y}    = $ev->y;
	$dt->_items->{$item}{'bottom-right-corner'}->{resizing} = TRUE;
	eval { $dt->_canvas->pointer_grab($dt->_items->{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], undef, $ev->time); };
	if ($@) { $dt->_canvas->pointer_grab($dt->_items->{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], Gtk3::Gdk::Cursor->new('left-ptr'), $ev->time); }
	$dt->store_to_xdo_stack($item, 'create', 'undo');
	return TRUE;
}

sub on_click_creation ($self, $item, $target, $ev, $copy_item = undef) {
	return $self->setup($ev, $copy_item, TRUE, FALSE);
}

sub setup ($self, $event, $copy_item, $end_arrow, $start_arrow) {
	my $dt = $self->drawing_tool;

	$self->event($event);
	$self->copy_item($copy_item);
	$self->end_arrow($end_arrow);
	$self->start_arrow($start_arrow);

	$self->_check_event_and_copy_item;

	my $item = $self->_create_item;

	$dt->current_new_item($item) unless $self->copy_item;
	$dt->_items->{$item} = $item;

	$dt->_items->{$item}{line} = $dt->_item_factory->create_line_polyline(
		$item->get('x'), $item->get('y'),
		$item->get('width'), $item->get('height'),
		$self->stroke_color, $self->line_width,
		$self->end_arrow, $self->start_arrow,
		$self->arrow_length, $self->arrow_width, $self->arrow_tip_length,
	);

	if (defined $self->end_arrow || defined $self->start_arrow) {
		$dt->_items->{$item}{end_arrow}        = $dt->_items->{$item}{line}->get('end-arrow');
		$dt->_items->{$item}{start_arrow}      = $dt->_items->{$item}{line}->get('start-arrow');
		$dt->_items->{$item}{arrow_width}      = $dt->_items->{$item}{line}->get('arrow-width');
		$dt->_items->{$item}{arrow_length}     = $dt->_items->{$item}{line}->get('arrow-length');
		$dt->_items->{$item}{arrow_tip_length} = $dt->_items->{$item}{line}->get('arrow-tip-length');
	}

	$dt->_items->{$item}{type} = 'line';
	$dt->_items->{$item}{uid}  = $dt->uid;
	$dt->increase_uid;

	$dt->_items->{$item}{mirrored_w}   = $self->mirrored_w;
	$dt->_items->{$item}{mirrored_h}   = $self->mirrored_h;
	$dt->_items->{$item}{stroke_color} = $dt->stroke_color;

	$dt->handle_rects('create', $item);
	if ($self->copy_item) {
		$dt->handle_embedded('update', $item);
		$dt->handle_rects('hide', $item);
	}

	$dt->setup_item_signals($dt->_items->{$item}{line});
	$dt->setup_item_signals_extra($dt->_items->{$item}{line});
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
		$self->stroke_color($dt->_items->{$self->copy_item}{stroke_color});
		$self->line_width($dt->_items->{$self->copy_item}{line}->get('line-width'));
		$self->mirrored_w($dt->_items->{$self->copy_item}{mirrored_w});
		$self->mirrored_h($dt->_items->{$self->copy_item}{mirrored_h});
		$self->end_arrow($dt->_items->{$self->copy_item}{end_arrow});
		$self->start_arrow($dt->_items->{$self->copy_item}{start_arrow});
		$self->arrow_width($dt->_items->{$self->copy_item}{arrow_width});
		$self->arrow_length($dt->_items->{$self->copy_item}{arrow_length});
		$self->arrow_tip_length($dt->_items->{$self->copy_item}{arrow_tip_length});
	}
	return;
}

sub _create_item ($self) {
	my $dt = $self->drawing_tool;
	return $dt->_item_factory->create_bounding_rect($self->X, $self->Y, $self->width, $self->height);
}

1;
