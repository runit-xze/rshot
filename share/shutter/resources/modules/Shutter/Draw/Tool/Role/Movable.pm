package Shutter::Draw::Tool::Role::Movable;

use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;

sub handle_moving {
	my ($self, $item, $target, $ev) = @_;
	my $dt = $self->drawing_tool;

	if ($item->isa('GooCanvas2::CanvasRect')) {
		my $new_x = $dt->{_items}{$item}->get('x') + $ev->x - $item->{drag_x};
		my $new_y = $dt->{_items}{$item}->get('y') + $ev->y - $item->{drag_y};

		$dt->{_items}{$item}->set(
			'x' => $new_x,
			'y' => $new_y,
		);

		$item->{drag_x} = $ev->x;
		$item->{drag_y} = $ev->y;

		$dt->handle_rects('update', $item);
		$dt->handle_embedded('update', $item);
	} else {
		$item->translate($ev->x - $item->{drag_x}, $ev->y - $item->{drag_y});
	}

	#add to undo stack
	if ($item->{dragging_start}) {
		$dt->store_to_xdo_stack($item, 'modify', 'undo');
		$item->{dragging_start} = FALSE;
	}

	return TRUE;
}

sub start_moving {
	my ($self, $item, $ev) = @_;
	$item->{drag_x}         = $ev->x;
	$item->{drag_y}         = $ev->y;
	$item->{dragging}       = TRUE;
	$item->{dragging_start} = TRUE;
	return Gtk3::Gdk::Cursor->new('fleur');
}

sub stop_moving {
	my ($self, $item) = @_;
	$item->{dragging}       = FALSE if exists $item->{dragging};
	$item->{dragging_start} = FALSE if exists $item->{dragging_start};
}

1;
