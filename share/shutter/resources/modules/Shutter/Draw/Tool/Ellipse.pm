package Shutter::Draw::Tool::Ellipse;

use Moo;
use utf8;
use v5.40;
use GooCanvas2;
use Glib qw/TRUE FALSE/;

use constant POSITION_INDENT => 20;

with 'Shutter::Draw::Tool::Base';

has event     => ( is => 'rw', lazy => 1 );
has copy_item => ( is => 'rw', lazy => 1 );
has numbered  => ( is => 'rw', lazy => 1 );
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
    return $self->drawing_tool->create_ellipse($event, undef);
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

sub on_click_creation ($self, $item, $target, $ev, $copy_item = undef, $numbered = undef) {
	return $self->setup($ev, $copy_item, $numbered);
}

sub setup ($self, $event, $copy_item, $numbered) {
	my $dt = $self->drawing_tool;

	$self->event($event);
	$self->copy_item($copy_item);
	$self->numbered($numbered);

	$self->_check_event_and_copy_item;

	my $item = $self->_create_item;

	$dt->current_new_item($item) unless $self->copy_item;
	$dt->{_items}{$item} = $item;

	$self->_setup_item_ellipse($item);

	if ($self->numbered) {
		$self->_setup_ellipse_numbered($item);
	} else {
		$item->{type} = 'ellipse';
		$item->{uid}  = $dt->uid;
		$dt->increase_uid;
	}

	$item->{fill_color}   = $dt->fill_color;
	$item->{stroke_color} = $dt->stroke_color;

	$dt->handle_rects('create', $item);
	if ($self->copy_item) {
		$dt->handle_embedded('update', $item);
		$dt->handle_rects('hide', $item);
	}

	if ($self->numbered) {
		$dt->setup_item_signals($item->{text});
		$dt->setup_item_signals_extra($item->{text});
	}

	$dt->setup_item_signals($item->{ellipse});
	$dt->setup_item_signals_extra($item->{ellipse});
	$dt->setup_item_signals($item);
	$dt->setup_item_signals_extra($item);

	return $item;
}

sub _setup_item_ellipse ($self, $item) {
	my $dt = $self->drawing_tool;

	$item->{ellipse} = GooCanvas2::CanvasEllipse->new(
		parent                => $dt->canvas->get_root_item,
		x                     => $self->X,
		y                     => $self->Y,
		width                 => $self->width,
		height                => $self->height,
		'fill-color-gdk-rgba' => $self->fill_color,
		'stroke-color-gdk-rgba' => $self->stroke_color,
		'line-width'          => $self->line_width,
	);
	return;
}

sub _setup_ellipse_numbered ($self, $item) {
	my $dt = $self->drawing_tool;
	my $number = $dt->get_highest_auto_digit + 1;

	my $txt = GooCanvas2::CanvasText->new(
		parent              => $dt->canvas->get_root_item,
		text                => "<span font_desc='" . $dt->font . "' >" . $number . "</span>",
		x                   => $item->{ellipse}->get('center-x'),
		y                   => $item->{ellipse}->get('center-y'),
		width               => -1,
		anchor              => 'center',
		'use-markup'        => TRUE,
		'fill-color-gdk-rgba' => $self->stroke_color,
		'line-width'        => $self->line_width,
	);

	$txt->{digit} = $number;
	$item->{text} = $txt;
	$item->{type} = 'number';
	$item->{uid}  = $dt->uid;
	$dt->increase_uid;

	my $tb = $txt->get_bounds;
	my $qs = abs($tb->x1 - $tb->x2);
	$qs = abs($tb->y1 - $tb->y2) if abs($tb->y1 - $tb->y2) > abs($tb->x1 - $tb->x2);
	$qs += $item->{ellipse}->get('line-width') + 5;

	$item->set(
		x          => $self->copy_item ? ($self->X + POSITION_INDENT) : ($self->X - $qs),
		y          => $self->copy_item ? ($self->Y + POSITION_INDENT) : ($self->Y - $qs),
		width      => $qs,
		height     => $qs,
		visibility => 'hidden',
	);

	$dt->handle_embedded('hide', $item);
	return;
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
		$self->line_width($dt->{_items}{$self->copy_item}{ellipse}->get('line-width'));
		$self->numbered(TRUE) if exists $dt->{_items}{$self->copy_item}{text};
	}
	return;
}

sub _create_item ($self) {
	my $dt = $self->drawing_tool;

	return GooCanvas2::CanvasRect->new(
		parent          => $dt->canvas->get_root_item,
		x               => $self->X,
		y               => $self->Y,
		width           => $self->width,
		height          => $self->height,
		'fill-color-rgba' => 0,
		'line-dash'     => GooCanvas2::CanvasLineDash->newv([5, 5]),
		'line-width'    => 1,
		'stroke-color'  => 'gray',
	);
}

1;
