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

package Shutter::App::Handlers::Screenshot_Take;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub evt_take_screenshot {
		my ($widget, $data, $folder_from_config, $extra) = @_;

		#get xid if any window was selected from the submenu...
		my $selfcapture = FALSE;
		if ($data =~ /^shutter_window_direct(.*)/) {
			my $xid = $1;
			$selfcapture = TRUE if $xid == $window->get_window->get_xid;
		}

		#hide mainwindow
		if (   $hide_active->get_active
			&& $data ne "web"
			&& $data ne "tray_web"
			&& !$is_hidden
			&& !$selfcapture)
		{

			fct_control_main_window('hide');

		} else {

			#save current position of main window
			($window->{x}, $window->{y}) = $window->get_position;

		}

		#close last message displayed
		my $notify = $sc->get_notification_object;
		$notify->close;

		#disable signal-handler
		fct_control_signals('block');

		if ($data eq "web" || $data eq "tray_web") {
			fct_take_screenshot($widget, $data, $folder_from_config, $extra);

			#unblock signal handler
			fct_control_signals('unblock');
			return TRUE;
		} elsif (!$x11_supported && $data ne "full" && $data ne "tray_full") {
			my $sd = Shutter::App::SimpleDialogs->new;
			$sd->dlg_error_message($d->get("Can't take screenshots without X11 server"), $d->get("Failed"));
			fct_control_signals('unblock');
			fct_control_main_window('show');
			return TRUE;
		}

		if ($data eq "menu"
			|| $data eq "tray_menu"
			|| $data eq "tooltip"
			|| $data eq "tray_tooltip")
		{

			my $scd_text;
			if ($data eq "menu" || $data eq "tray_menu") {
				$scd_text = $d->get("Please activate the menu you want to capture");
				if ($ENV{GDK_SCALE} > 1) {
					my $sd = Shutter::App::SimpleDialogs->new;
					$sd->dlg_info_message("Capturing a cascading menu is known to be broken with HiDPI.\nPlease unset GDK_SCALE variable and restart Shutter.\nPlease follow https://github.com/shutter-project/shutter/issues/326 and send us the patch\nWill attempt capturing it anyway...", undef, 'gtk-ok');
				}
			} elsif ($data eq "tooltip" || $data eq "tray_tooltip") {
				$scd_text = $d->get("Please activate the tooltip you want to capture");
			}

			#show notification messages displaying the countdown
			if ($notify_ptimeout_active->get_active) {
				my $notify = $sc->get_notification_object;
				my $ttw    = $menu_delay->get_value;

				#first notification immediately
				$notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text);
				$ttw--;

				#delay is only 1 second
				#do not show any further messages
				if ($ttw >= 1) {

					#then controlled via timeout
					Glib::Timeout->add(
						1000,
						sub {
							$notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text);
							$ttw--;
							if ($ttw == 0) {

								#close last message with a short delay (less than a second)
								Glib::Timeout->add(
									500,
									sub {
										$notify->close;
										return FALSE;
									});

								return FALSE;

							} else {

								return TRUE;

							}
						});
				} else {

					#close last message with a short delay (less than a second)
					Glib::Timeout->add(
						500,
						sub {
							$notify->close;
							return FALSE;
						});
				}
			}    #notify not activated

			#capture with delay
			Glib::Timeout->add(
				$menu_delay->get_value * 1000,
				sub {
					fct_take_screenshot($widget, $data, $folder_from_config, $extra);

					#unblock signal handler
					fct_control_signals('unblock');
					return FALSE;
				});
		} else {
			if (($data eq "section" || $data eq "tray_section") && $ENV{GDK_SCALE} > 1) {
				my $sd = Shutter::App::SimpleDialogs->new;
				$sd->dlg_info_message("Capturing a window section is known to be broken with HiDPI.\nPlease unset GDK_SCALE variable and restart Shutter.\nPlease follow https://github.com/shutter-project/shutter/issues/326 and send us the patch\nWill attempt capturing it anyway...", undef, 'gtk-ok');
			}

			#A short timeout to give the server a chance to
			#redraw the area that was obscured by our dialog.
			Glib::Timeout->add(
				$hide_time->get_value,
				sub {
					fct_take_screenshot($widget, $data, $folder_from_config, $extra);

					#unblock signal handler
					fct_control_signals('unblock');
					return FALSE;
				});
		}

		return TRUE;
	}


1;
