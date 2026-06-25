package Shutter::Draw::Tool::Censor;

use Moo;
use utf8;
use v5.40;
use GooCanvas2;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has event     => ( is => 'rw', lazy => 1 );
has copy_item => ( is => 'rw', lazy => 1 );
has points    => ( is => 'rw', default => sub { [] } );
has transform => ( is => 'rw' );

sub draw ($self, $cr) {
    # Handled by GooCanvas2
}

sub on_click ($self, $event) {
    $self->drawing_tool->create_censor($event, undef);
}

sub on_drag ($self, $event) {
    # Handled by DrawingTool for now
}

sub on_drag_creation_points ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;
	push @{$dt->{_items}{$item}{'points'}}, $ev->x, $ev->y;
	$dt->{_items}{$item}->set('points' => Shutter::Draw::Utils::points_to_canvas_points(@{$dt->{_items}{$item}{'points'}}));
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

	$dt->{_items}{$item}{type} = 'censor';
	$dt->{_items}{$item}{uid}  = $dt->uid;
	$dt->increase_uid;

	push @{$dt->{_items}{$item}{'points'}}, @{$self->points};
	$item->set(points => Shutter::Draw::Utils::points_to_canvas_points(@{$dt->{_items}{$item}{'points'}}));
	$item->set(transform => $self->transform) if $self->transform;

	$dt->setup_item_signals($item);
	$dt->setup_item_signals_extra($item);

	return $item;
}

sub _check_event_and_copy_item ($self) {
	my $dt = $self->drawing_tool;

	if ($self->event) {
		$self->points([$self->event->x, $self->event->y, $self->event->x, $self->event->y]);
	} elsif ($self->copy_item) {
		my @pts;
		foreach (@{$dt->{_items}{$self->copy_item}{points}}) {
			push @pts, $_ + 20;
		}
		$self->points(\@pts);
		$self->transform($self->copy_item->get('transform'));
	}
}

sub _create_item ($self) {
	my $dt = $self->drawing_tool;

	return GooCanvas2::CanvasPolyline->new(
		parent        => $dt->canvas->get_root_item,
		'close-path'  => FALSE,
		'stroke-pixbuf' => $dt->stipple_pixbuf,
		'line-width'  => 14,
		'line-cap'    => 'CAIRO_LINE_CAP_ROUND',
		'line-join'   => 'CAIRO_LINE_JOIN_ROUND',
	);
}

1;
