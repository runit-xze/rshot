package Shutter::Draw::Tool::Rectangle;

use Moo;
use utf8;
use v5.40;
use GooCanvas2;
use Glib qw/TRUE FALSE/;

use constant POSITION_INDENT => 20;

with 'Shutter::Draw::Tool::Base';

has event     => ( is => 'rw', lazy => 1 );
has copy_item => ( is => 'rw', lazy => 1 );
has X         => ( is => 'rw', default => sub {0} );
has Y         => ( is => 'rw', default => sub {0} );
has width     => ( is => 'rw', default => sub {0} );
has height    => ( is => 'rw', default => sub {0} );
has stroke_color => ( is => 'rw', lazy => 1, default => sub { shift->drawing_tool->stroke_color } );
has fill_color   => ( is => 'rw', lazy => 1, default => sub { shift->drawing_tool->fill_color } );
has line_width   => ( is => 'rw', lazy => 1, default => sub { shift->drawing_tool->line_width } );

sub draw ($self, $cr) {
    # Handled by GooCanvas2
}

sub on_click ($self, $event) {
    return $self->drawing_tool->create_rectangle($event, undef);
}

sub on_drag ($self, $event) {
    # Handled by DrawingTool for now
}

sub on_drag_creation_shape ($self, $item, $target, $ev) {
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

	$dt->{_items}{$item}{type} = 'rectangle';
	$dt->{_items}{$item}{uid}  = $dt->uid;
	$dt->increase_uid;

	$dt->{_items}{$item}{fill_color}   = $self->fill_color;
	$dt->{_items}{$item}{stroke_color} = $self->stroke_color;

	$dt->handle_rects('create', $item);
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
		$self->X($self->copy_item->get('x') + POSITION_INDENT);
		$self->Y($self->copy_item->get('y') + POSITION_INDENT);
		$self->width($self->copy_item->get('width'));
		$self->height($self->copy_item->get('height'));
		$self->stroke_color($dt->{_items}{$self->copy_item}{stroke_color});
		$self->fill_color($dt->{_items}{$self->copy_item}{fill_color});
		$self->line_width($self->copy_item->get('line-width'));
	}
	return;
}

sub _create_item ($self) {
	my $dt = $self->drawing_tool;

	return GooCanvas2::CanvasRect->new(
		parent                => $dt->canvas->get_root_item,
		x                     => $self->X,
		y                     => $self->Y,
		width                 => $self->width,
		height                => $self->height,
		'fill-color-gdk-rgba' => $self->fill_color,
		'stroke-color-gdk-rgba' => $self->stroke_color,
		'line-width'          => $self->line_width,
	);
}

1;
