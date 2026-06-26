package Shutter::Draw::Polyline;

use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Moo;

use GooCanvas2;
use Glib qw/ TRUE FALSE /;

has app         => (is => "ro", required => 1);
has event       => (is => "rw", lazy     => 1);
has copy_item   => (is => "rw", lazy     => 1);
has highlighter => (is => "rw", default  => sub { FALSE });

has points       => (is => "rw", default => sub { [] });
has transform    => (is => "rw");
has stroke_color => (is => "rw", lazy => 1, default => sub { shift->app->stroke_color });
has line_width   => (is => "rw", lazy => 1, default => sub { shift->app->line_width });

sub setup {
	my ($self, $event, $copy_item, $highlighter) = @_;
	$self->event($event);
	$self->copy_item($copy_item);
	$self->highlighter($highlighter // FALSE);

	$self->_check_event_and_copy_item;

	my $item = $self->_create_item;

	$self->app->current_new_item($item) unless $self->copy_item;
	$self->app->items->{$item} = $item;

	# need at least 2 points
	push @{$self->app->items->{$item}{'points'}}, @{$self->points};
	$item->set(points    => Shutter::Draw::Utils::points_to_canvas_points(@{$self->app->items->{$item}{'points'}}));
	$item->set(transform => $self->transform) if $self->transform;

	if ($self->highlighter) {

		# set type flag
		$self->app->items->{$item}{type} = 'highlighter';
		$self->app->items->{$item}{uid}  = $self->app->uid;
		$self->app->uid($self->app->uid + 1);
		my $hl_color = Gtk3::Gdk::RGBA::parse('#FFFF00');
		$hl_color->alpha(0.5);
		$self->app->items->{$item}{stroke_color} = $hl_color;
	} else {

		# set type flag
		$self->app->items->{$item}{type} = 'freehand';
		$self->app->items->{$item}{uid}  = $self->app->uid;
		$self->app->uid($self->app->uid + 1);
		$self->app->items->{$item}{stroke_color} = $self->stroke_color;
	}

	$self->app->setup_item_signals($item);
	$self->app->setup_item_signals_extra($item);

	return $item;
}

sub _check_event_and_copy_item {
	my $self = shift;
	if ($self->event) {
		$self->points([$self->event->x, $self->event->y, $self->event->x, $self->event->y]);
	} elsif ($self->copy_item) {
		my @pts;
		foreach (@{$self->app->items->{$self->copy_item}{points}}) {
			push @pts, $_ + 20;
		}
		$self->points(\@pts);

		$self->stroke_color($self->app->items->{$self->copy_item}{stroke_color});
		$self->transform($self->copy_item->get('transform'));
		$self->line_width($self->copy_item->get('line-width'));
	}
	return;
}

sub _create_item {
	my $self = shift;
	if ($self->highlighter) {
		return $self->app->_item_factory->create_highlighter_polyline;
	}
	return $self->app->_item_factory->create_pen_polyline($self->stroke_color, $self->line_width);
}

1;
