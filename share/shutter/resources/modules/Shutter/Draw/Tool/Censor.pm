package Shutter::Draw::Tool::Censor;

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
    $self->drawing_tool->create_censor($event, undef);
}

sub on_drag ($self, $event) {
    # Handled by DrawingTool for now
}


sub on_drag_creation_points ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;
	$dt->{_items}{$item}->set('points' => Shutter::Draw::Utils::points_to_canvas_points(@{$dt->{_items}{$item}{'points'}}));
}


sub on_click_creation ($self, $item, $target, $ev, $copy_item) {
	require Shutter::Draw::Censor;
	my $censor = Shutter::Draw::Censor->new( app => $self->drawing_tool );
	return $censor->setup($ev, $copy_item);
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Censor - Censor drawing tool

=head1 DESCRIPTION

Implements censor drawing.
