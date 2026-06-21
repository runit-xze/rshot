package Shutter::Draw::Tool::Rectangle;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

with 'Shutter::Draw::Tool::Base';

has drawing_tool => (is => 'ro', required => 1);

sub draw ($self, $cr) {
    # Rectangle drawing logic
}

sub on_click ($self, $event) {
    $self->drawing_tool->create_rectangle($event, undef);
}

sub on_drag ($self, $event) {
    # Rectangle drag logic
}


sub on_drag_creation_shape {
	my ($self, $item, $target, $ev) = @_;
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


sub on_click_creation {
	my ($self, $item, $target, $ev, $copy_item) = @_;
	require Shutter::Draw::Rectangle;
	my $rect = Shutter::Draw::Rectangle->new( app => $self->drawing_tool );
	return $rect->setup($ev, $copy_item);
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Rectangle - Rectangle drawing tool

=head1 DESCRIPTION

Implements rectangle drawing.
