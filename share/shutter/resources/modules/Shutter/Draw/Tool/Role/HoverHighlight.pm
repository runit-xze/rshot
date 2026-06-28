package Shutter::Draw::Tool::Role::HoverHighlight;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;

requires qw(
	drawing_tool
);

sub on_enter_notify {
	my ($self, $item, $target, $ev) = @_;
	my $dt = $self->drawing_tool;

	return TRUE if $dt->_busy;

	if ((
			   $item->isa('GooCanvas2::CanvasRect')
			|| $item->isa('GooCanvas2::CanvasEllipse')
			|| $item->isa('GooCanvas2::CanvasText')
			|| $item->isa('GooCanvas2::CanvasImage')
			|| $item->isa('GooCanvas2::CanvasPolyline'))
		&& !$self->can('on_drag_creation_points')

		)
	{

		#embedded item?
		my $parent = $dt->get_parent_item($item);
		$item = $parent if $parent;

		#real shape
		if (exists $dt->_items->{$item}) {

			#canvas resizing shape
		} elsif ($dt->_canvas_bg_rect->{'right-side'} == $item
			|| $dt->_canvas_bg_rect->{'bottom-side'} == $item
			|| $dt->_canvas_bg_rect->{'bottom-right-corner'} == $item)
		{

			$item->set('fill-color' => 'red');

		} else {

			$item->set('fill-color' => 'red');

		}
	}

	return TRUE;
}

sub on_leave_notify {
	my ($self, $item, $target, $ev) = @_;
	my $dt = $self->drawing_tool;

	return TRUE if $dt->_busy;

	if ((
			   $item->isa('GooCanvas2::CanvasRect')
			|| $item->isa('GooCanvas2::CanvasEllipse')
			|| $item->isa('GooCanvas2::CanvasText')
			|| $item->isa('GooCanvas2::CanvasImage')
			|| $item->isa('GooCanvas2::CanvasPolyline'))
		&& !$self->can('on_drag_creation_points')

		)
	{

		#embedded item?
		my $parent = $dt->get_parent_item($item);
		$item = $parent if $parent;

		#real shape
		if (exists $dt->_items->{$item}) {

			#canvas resizing shape
		} elsif ($dt->_canvas_bg_rect->{'right-side'} == $item
			|| $dt->_canvas_bg_rect->{'bottom-side'} == $item
			|| $dt->_canvas_bg_rect->{'bottom-right-corner'} == $item)
		{

			$item->set('fill-color-gdk-rgba' => $dt->_style_bg);

		} else {

			$item->set('fill-color-gdk-rgba' => $dt->_style_bg);

		}
	}

	return TRUE;
}

1;
