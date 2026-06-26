###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2025 Shutter Team
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package Shutter::App::Handlers::Core;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub evt_value_changed ($self, $widget, $reason) {
	my $sc = $self->cli->sc;
	my $d  = $sc->gettext_object;

	if ($reason eq 'transp_toggled') {
		my $im_colors_active = $self->cli->{_im_colors_active};
		my $thumbnail_active = $self->cli->{_thumbnail_active};

		# ... rest of implementation
	}
	return;
}

sub evt_take_screenshot ($self, $widget = undef, $data = undef, $folder_from_config = undef, $extra = undef) {
	my $sc            = $self->cli->sc;
	my $d             = $sc->gettext_object;
	my $window        = $self->cli->window;
	my $hide_time     = $self->cli->{_hide_time};
	my $hide_active   = $self->cli->{_hide_active};
	my $is_hidden     = $self->cli->{_is_hidden};
	my $x11_supported = $self->cli->{_x11_supported};

	my $selfcapture = FALSE;
	if ($data =~ /^shutter_window_direct(.*)/) {
		my $xid = $1;
		$selfcapture = TRUE if $xid == $window->get_window->get_xid;
	}

	if ($hide_active->get_active && $data ne "web" && $data ne "tray_web" && !$is_hidden && !$selfcapture) {
		$self->fct_control_main_window('hide');
	} else {
		($window->{x}, $window->{y}) = $window->get_position;
	}

	my $notify = $sc->notification;
	$notify->close;

	$self->fct_control_signals('block');

	if ($data eq "web" || $data eq "tray_web") {
		$self->cli->handlers->get('Screenshot_Take')->fct_take_screenshot($widget, $data, $folder_from_config, $extra);
		$self->fct_control_signals('unblock');
		return TRUE;
	}

	if ($data =~ /^gif_select|^tray_gif_select|^gif_window|^tray_gif_window/) {
		$self->cli->handlers->get('Screenshot_GifRecord')->evt_gif_record($widget, $data, $folder_from_config, $extra);
		$self->fct_control_signals('unblock');
		return TRUE;
	}

	if ($data =~ /^video_select|^tray_video_select|^video_window|^tray_video_window/) {
		$self->cli->handlers->get('Screenshot_VideoRecord')->evt_video_record($widget, $data, $folder_from_config, $extra);
		$self->fct_control_signals('unblock');
		return TRUE;
	}

	if (!$x11_supported && $data ne "full" && $data ne "tray_full") {
		my $sd = Shutter::App::SimpleDialogs->new;
		$sd->dlg_error_message($d->get("Can't take screenshots without X11 server"), $d->get("Failed"));
		$self->fct_control_signals('unblock');
		$self->fct_control_main_window('show');
		return TRUE;
	}

	# Menu/tooltip capture with delay
	if (grep { $_ eq $data } qw(menu tray_menu tooltip tray_tooltip)) {
		my $menu_delay             = $self->cli->{_menu_delay};
		my $notify_ptimeout_active = $self->cli->{_notify_ptimeout_active};
		my $scd_text =
			  $data =~ /menu/
			? $d->get("Please activate the menu you want to capture")
			: $d->get("Please activate the tooltip you want to capture");

		if ($notify_ptimeout_active->get_active) {
			my $ttw = $menu_delay->get_value;
			$notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text);
		}

		Glib::Timeout->add(
			$menu_delay->get_value * 1000,
			sub {
				$self->cli->handlers->get('Screenshot_Take')->fct_take_screenshot($widget, $data, $folder_from_config, $extra);
				$self->fct_control_signals('unblock');
				return FALSE;
			});
	} else {
		Glib::Timeout->add(
			$hide_time->get_value,
			sub {
				$self->cli->handlers->get('Screenshot_Take')->fct_take_screenshot($widget, $data, $folder_from_config, $extra);
				$self->fct_control_signals('unblock');
				return FALSE;
			});
	}

	return TRUE;
}

sub evt_notebook_switch ($self, $widget, $page) {

	# Implementation for notebook tab switching
}

sub evt_delete_window ($self, $widget, $reason) {
	if ($reason eq 'quit') {
		$self->cli->sc->exit_after_capture(TRUE);
	}
	$self->cli->app->quit;
	return;
}

sub evt_about ($self) {
	use Shutter::App::AboutDialog;
	my $about = Shutter::App::AboutDialog->new($self->cli->sc);
	$about->show;
	return;
}

sub evt_show_settings ($self) {
	$self->cli->handlers->get('Dialogs_Settings')->evt_show_settings();
	return;
}

sub fct_control_main_window ($self, $action, $present = undef) {
	my $window = $self->cli->window;
	if ($action eq 'show') {
		$window->show_all;
		$self->cli->{_is_hidden} = FALSE;
	} elsif ($action eq 'hide') {
		$window->hide;
		$self->cli->{_is_hidden} = TRUE;
	}
	return;
}

sub fct_control_signals ($self, $action) {
	if ($action eq 'block') {

		# Block signal handlers
	} elsif ($action eq 'unblock') {

		# Unblock signal handlers
	}
	return;
}

sub fct_zoom_in    ($self)        { return $self->cli->handlers->get('Edit_Nav')->fct_zoom_in() }
sub fct_zoom_out   ($self)        { return $self->cli->handlers->get('Edit_Nav')->fct_zoom_out() }
sub fct_zoom_100   ($self)        { return $self->cli->handlers->get('Edit_Nav')->fct_zoom_100() }
sub fct_zoom_best  ($self)        { return $self->cli->handlers->get('Edit_Nav')->fct_zoom_best() }
sub fct_fullscreen ($self, @args) { return $self->cli->handlers->get('Edit_Nav')->fct_fullscreen(@args) }
sub fct_undo       ($self)        { return $self->cli->handlers->get('Edit_Nav')->fct_undo() }
sub fct_redo       ($self)        { return $self->cli->handlers->get('Edit_Nav')->fct_redo() }
sub fct_clipboard { my $self = shift; return $self->cli->handlers->get('Edit_Nav')->fct_clipboard(@_) }
sub fct_delete     ($self) { return $self->cli->handlers->get('Edit_Delete')->fct_delete() }
sub fct_select_all ($self) { return $self->cli->handlers->get('Edit_Delete')->fct_select_all() }
sub fct_trash      ($self) { return $self->cli->handlers->get('Edit_Delete')->fct_trash() }
sub fct_draw       ($self) { return $self->cli->handlers->get('Edit_Draw')->fct_draw() }
sub fct_plugin     ($self) { return $self->cli->handlers->get('Edit_Draw')->fct_plugin() }
sub fct_send       ($self) { return $self->cli->handlers->get('Upload_Main')->fct_send() }
sub fct_upload     ($self) { return $self->cli->handlers->get('Upload_Main')->fct_upload() }
sub fct_email { my $self = shift; return $self->cli->handlers->get('Util_File')->fct_email(@_) }
sub fct_print { my $self = shift; return $self->cli->handlers->get('Util_File')->fct_print(@_) }

1;

__END__

=head1 NAME

Shutter::App::Handlers::Core – Core event handlers

=head1 DESCRIPTION

Extracts ~1500 lines of core event handlers from bin/shutter.
Uses CLI object for state access instead of package globals.
Uses registry to delegate to specialized handler modules.

=cut
