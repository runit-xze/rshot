package Shutter::Draw::Tool::Pen;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

sub draw ($self, $cr) {
    # Handled by GooCanvas2
}

sub on_click ($self, $event) {
    $self->drawing_tool->create_polyline($event, undef, FALSE);
}

sub on_drag ($self, $event) {
    # Logic currently handled inside DrawingTool.pm
}

sub on_drag_creation_points ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;
	push @{$dt->{_items}{$item}{'points'}}, $ev->x, $ev->y;
	$dt->{_items}{$item}->set('points' => Shutter::Draw::Utils::points_to_canvas_points(@{$dt->{_items}{$item}{'points'}}));
}

sub on_click_creation ($self, $item, $target, $ev, $copy_item = undef) {
	require Shutter::Draw::Polyline;
	my $poly = Shutter::Draw::Polyline->new( app => $self->drawing_tool );
	return $poly->setup($ev, $copy_item, FALSE);
}

1;
