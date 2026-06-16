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
###################################################

package Shutter::App::Handlers::Events_Control;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_control_main_window {
		my $mode = shift;

		#default value for present is TRUE
		my $present = TRUE;
		$present = shift if @_;

		#this is an unusual method for raising the window
		#to the top within the stacking order (z-axis)
		#but it works best here
		if ($mode eq 'show' && $present) {

			#move window to saved position
			$window->move($window->{x}, $window->{y})
				if (defined $window->{x} && defined $window->{y});

			#if it's shown already, but behind other windows, without hiding it doesn't show
			$window->hide;

			$window->show_all;
			#$window->window->focus(Gtk3->get_current_event_time)
			#	if defined $window->window;
			$window->present;

			#set flag
			$is_hidden = FALSE;

			#toolbar->set_show_arrow is FALSE at startup
			#to automatically adjust the main window width
			#we change the setting to TRUE if it is still false,
			#so the window/toolbar is resizable again
			if ($st->{_toolbar}) {
				unless ($st->{_toolbar}->get_show_arrow) {
					$st->{_toolbar}->set_show_arrow(TRUE);

					#add a small margin
					my ($rw, $rh) = $window->get_size;
					$window->resize($rw + 50, $rh);
				}
			}

		} elsif ($mode eq 'hide') {

			#save current position of main window
			($window->{x}, $window->{y}) = $window->get_position;

			$window->hide;

			$is_hidden = TRUE;

		}

		return TRUE;
	}

	sub fct_control_signals {
		my $action = shift;

		my $sensitive = undef;
		if ($action eq 'block') {

			$sensitive = FALSE;

			#block signals
			foreach my $connection (@signal_connections) {
				if ($app->signal_handler_is_connected($connection)) {
					$app->signal_handler_block($connection);
				}
			}

			#and block status icon handler
			if ($tray && $tray->isa('Gtk3::StatusIcon')) {
				if ($tray->signal_handler_is_connected($tray->{'hid'})) {
					$tray->signal_handler_block($tray->{'hid'});
				}
				if ($tray->signal_handler_is_connected($tray->{'hid2'})) {
					$tray->signal_handler_block($tray->{'hid2'});
				}
			} elsif ($tray && $tray->isa('AppIndicator::Indicator')) {
				$tray->set_status('passive');
			}
		} elsif ($action eq 'unblock') {

			$sensitive = TRUE;

			#attach signal-handler again
			foreach my $connection (@signal_connections) {
				if ($app->signal_handler_is_connected($connection)) {
					$app->signal_handler_unblock($connection);
				}
			}

			#and unblock status icon handler
			if ($tray && $tray->isa('Gtk3::StatusIcon')) {
				if ($tray->signal_handler_is_connected($tray->{'hid'})) {
					$tray->signal_handler_unblock($tray->{'hid'});
				}
				if ($tray->signal_handler_is_connected($tray->{'hid2'})) {
					$tray->signal_handler_unblock($tray->{'hid2'});
				}
			} elsif ($tray && $tray->isa('AppIndicator::Indicator')) {
				$tray->set_status('active');
			}
		}

		#enable/disable controls
		if ($st->{_select} && $sm->{_menuitem_selection}) {
			# if $x11_supported is false, we are on Wayland, and all these buttons are already disabled and should stay disabled

			#menu
			if ($x11_supported) {
				$sm->{_menuitem_selection}->set_sensitive($sensitive);
				$sm->{_menuitem_window}->set_sensitive($sensitive);
				#$sm->{_menuitem_section}->set_sensitive($sensitive);
				$sm->{_menuitem_menu}->set_sensitive($sensitive);
				$sm->{_menuitem_tooltip}->set_sensitive($sensitive);
			}
			$sm->{_menuitem_web}->set_sensitive($sensitive)
				if ($gnome_web_photo);
			$sm->{_menuitem_iclipboard}->set_sensitive($sensitive);

			#toolbar
			if ($x11_supported) {
				$st->{_select}->set_sensitive($sensitive);
				$st->{_window}->set_sensitive($sensitive);
				#$st->{_section}->set_sensitive($sensitive);
				$st->{_menu}->set_sensitive($sensitive);
				$st->{_tooltip}->set_sensitive($sensitive);
			}
			$st->{_web}->set_sensitive($sensitive) if ($gnome_web_photo);

			#special case: redoshot (toolbar and menu)
			if (fct_get_last_capture()) {
				$st->{_redoshot}->set_sensitive($sensitive);
				$sm->{_menuitem_redoshot}->set_sensitive($sensitive);
			}

		}

		return TRUE;
	}


1;
