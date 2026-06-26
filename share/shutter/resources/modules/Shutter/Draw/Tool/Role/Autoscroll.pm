package Shutter::Draw::Tool::Role::Autoscroll;

use Moo::Role;
use Glib qw/TRUE FALSE/;

requires qw(
	drawing_tool
);

sub _handle_autoscroll {
	my ($self, $item, $ev) = @_;
	my $dt = $self->drawing_tool;

	return if $dt->{_current_mode_descr} eq "censor" || !$dt->{_autoscroll};
	return unless $ev->state >= 'button1-mask'       || $ev->state >= 'button2-mask';

	my ($x, $y, $width, $height, $depth) = $dt->{_canvas}->get_window->get_geometry;
	my $s  = $dt->{_canvas}->get_scale;
	my $ha = $dt->{_scrolled_window}->get_hadjustment->get_value;
	my $va = $dt->{_scrolled_window}->get_vadjustment->get_value;

	if (   $ev->x > ($ha / $s + $width / $s - 100 / $s)
		&& $ev->y > ($va / $s + $height / $s - 100 / $s))
	{
		$dt->{_canvas}->scroll_to($ha / $s + 10 / $s, $va / $s + 10 / $s);
	} elsif ($ev->x > ($ha / $s + $width / $s - 100 / $s)) {
		$dt->{_canvas}->scroll_to($ha / $s + 10 / $s, $va / $s);
	} elsif ($ev->y > ($va / $s + $height / $s - 100 / $s)) {
		$dt->{_canvas}->scroll_to($ha / $s, $va / $s + 10 / $s);
	} elsif ($ev->x < ($ha / $s + 100 / $s) && $ev->y < ($va / $s + 100 / $s)) {
		$dt->{_canvas}->scroll_to($ha / $s - 10 / $s, $va / $s - 10 / $s);
	} elsif ($ev->x < ($ha / $s + 100 / $s)) {
		$dt->{_canvas}->scroll_to($ha / $s - 10 / $s, $va / $s);
	} elsif ($ev->y < ($va / $s + 100 / $s)) {
		$dt->{_canvas}->scroll_to($ha / $s, $va / $s - 10 / $s);
	}

	return;
}

1;
