package Shutter::Screenshot::Selector::InputManager;

use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Glib qw(TRUE FALSE);
use Gtk3;

has app   => (is => 'ro', required => 1);
has model => (is => 'ro', required => 1);

sub handle_key_press ($self, $event, $x, $y) {
	my $app   = $self->app;
	my $model = $self->model;

	my $keyval = $event->keyval;
	my $state  = $event->state;

	if ($keyval == Gtk3::Gdk::keyval_from_name('space')) {
		$app->{_zoom_active} = !$app->{_zoom_active};
		$app->{_draw_area}->queue_draw;
		return TRUE;
	}

	if ($keyval == Gtk3::Gdk::keyval_from_name('Shift_L') || $keyval == Gtk3::Gdk::keyval_from_name('Shift_R')) {
		if ($app->{_prop_active}) {
			Gtk3::Gdk::keyboard_ungrab(Gtk3::get_current_event_time());
			$app->{_prop_window}->hide;
			$app->{_prop_active} = FALSE;
			Gtk3::Gdk::keyboard_grab($app->{_select_window}->get_window, 0, Gtk3::get_current_event_time());
		} else {
			Gtk3::Gdk::keyboard_ungrab(Gtk3::get_current_event_time());
			$app->{_prop_window}->move($x, $y);
			$app->{_prop_window}->show_all;
			$app->{_prop_active} = TRUE;
			Gtk3::Gdk::keyboard_grab($app->{_prop_window}->get_window, 0, Gtk3::get_current_event_time());
		}
		return TRUE;
	}

	if ($keyval == Gtk3::Gdk::keyval_from_name('Escape')) {
		$app->quit;
		return TRUE;
	}

	if ($keyval == Gtk3::Gdk::keyval_from_name('Return') || $keyval == Gtk3::Gdk::keyval_from_name('KP_Enter')) {
		$app->{_select_window}->hide;
		$app->{_prop_window}->hide;
		Glib::Timeout->add($app->{_hide_time}, sub { Gtk3->main_quit; return FALSE; });
		Gtk3->main();
		my $s = $model->get_hash;
		if ($s) {
			$app->{_final_output} = $app->take_screenshot($s);
		}
		$app->quit;
		return TRUE;
	}

	# Navigation actions
	my $action = _get_nav_action($keyval, $state);
	return FALSE unless $action;

	my $dx = 0;
	my $dy = 0;
	if    ($action->{dir} eq 'up')    { $dy = -1; }
	elsif ($action->{dir} eq 'down')  { $dy = 1; }
	elsif ($action->{dir} eq 'left')  { $dx = -1; }
	elsif ($action->{dir} eq 'right') { $dx = 1; }

	if ($action->{type} eq 'resize') {
		if ($model->is_active) {
			$model->resize_by($dx, $dy);
			$app->{_gdk_display}->warp_pointer($app->{_gdk_screen}, $model->x + $model->width, $model->y + $model->height);
		} else {

			# Start tiny selection
			$model->set_rect($x, $y, $dx > 0 ? 2 : 1, $dy > 0 ? 2 : 1);
			$app->{_gdk_display}->warp_pointer($app->{_gdk_screen}, $x + ($dx > 0 ? 2 : 1), $y + ($dy > 0 ? 2 : 1));
		}
	} elsif ($action->{type} eq 'move') {
		if ($model->is_active) {
			$model->move_by($dx, $dy);
			$app->{_gdk_display}->warp_pointer($app->{_gdk_screen}, $model->x, $model->y);
		}
	} elsif ($action->{type} eq 'cursor') {
		$app->{_gdk_display}->warp_pointer($app->{_gdk_screen}, $x + $dx, $y + $dy);
	}

	return TRUE;
}

sub _get_nav_action ($keyval, $state) {
	my $dir;
	if    ($keyval == Gtk3::Gdk::keyval_from_name('Up'))    { $dir = 'up'; }
	elsif ($keyval == Gtk3::Gdk::keyval_from_name('Down'))  { $dir = 'down'; }
	elsif ($keyval == Gtk3::Gdk::keyval_from_name('Left'))  { $dir = 'left'; }
	elsif ($keyval == Gtk3::Gdk::keyval_from_name('Right')) { $dir = 'right'; }
	return unless $dir;

	if ($state >= 'control-mask') {
		return {dir => $dir, type => 'resize'};
	} elsif ($state >= 'mod1-mask') {
		return {dir => $dir, type => 'move'};
	} else {
		return {dir => $dir, type => 'cursor'};
	}
}

1;
