package Shutter::Draw::Tool::Highlighter;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has drawing_tool => (is => 'ro', required => 1);

sub draw ($self, $cr) {
    # Handled by GooCanvas2
}

sub on_click ($self, $event) {
    $self->drawing_tool->create_polyline($event, undef, TRUE);
}

sub on_drag ($self, $event) {
    # Handled by DrawingTool for now
}


sub on_drag_creation_points {
	my ($self, $item, $target, $ev) = @_;
	my $dt = $self->drawing_tool;
	$dt->{_items}{$item}->set('points' => Shutter::Draw::Utils::points_to_canvas_points(@{$dt->{_items}{$item}{'points'}}));
}


sub on_click_creation {
	my ($self, $item, $target, $ev, $copy_item) = @_;
	require Shutter::Draw::Polyline;
	my $poly = Shutter::Draw::Polyline->new( app => $self->drawing_tool );
	return $poly->setup($ev, $copy_item, TRUE);
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Highlighter - Highlighter drawing tool

=head1 DESCRIPTION

Implements highlighter drawing.
