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

package Shutter::App::Handlers::Screenshot;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub evt_notebook_switch {
		my ($widget, $pointer, $int) = @_;

		my $key = fct_get_file_by_index($int);
		if ($key) {
			Glib::Idle->add(
				sub {

					#is key still current page?
					if (defined $key) {
						return FALSE unless exists $session_screens{$key};
						return FALSE
							unless $session_screens{$key}->{'tab_child'} == $notebook->get_nth_page($notebook->get_current_page);

						#~ print "update tab for $key\n";
					}
					foreach my $ckey (keys %session_screens) {

						#set pixbuf for current item
						if ($ckey eq $key) {
							if ($session_screens{$key}->{'long'}) {

								#update window title
								fct_update_info_and_tray($key);

								#do nothing if the view does already show a pixbuf
								if (exists $session_screens{$ckey}
									&& defined $session_screens{$ckey}->{'image'})
								{
									unless ($session_screens{$ckey}->{'image'}->get_pixbuf) {
										$session_screens{$ckey}->{'image'}->set_pixbuf($lp->load($session_screens{$key}->{'long'}, undef, undef, undef, TRUE), TRUE);
									}
								}
							}
							next;
						}

						#unset imageview for all other items
						if (exists $session_screens{$ckey}
							&& defined $session_screens{$ckey}->{'image'})
						{
							if ($session_screens{$ckey}->{'image'}->get_pixbuf) {
								$session_screens{$ckey}->{'image'}->set_pixbuf(undef);
							}
						}
					}
					return FALSE;
				});
		} else {
			Glib::Idle->add(
				sub {
					fct_update_info_and_tray("session");
					return FALSE;
				});
		}

		#unselect all items in session tab
		#when we move away
		if ($int == 0) {
			$session_start_screen{'first_page'}->{'view'}->unselect_all;
		}

		#enable/disable menu entry when we switch tabs
		fct_update_actions($int, $key);

		return TRUE;
	}

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

	sub evt_value_changed {
		my ($widget, $data) = @_;

		# a small workaround when the widget is undef
		$widget ||= "undef";

		print "\n$data was emitted by widget $widget\n"
			if $sc->get_debug;

		return FALSE unless $data;

		#checkbox for "open with" -> entry active/inactive
		if ($data eq "progname_toggled") {
			if ($progname_active->get_active) {
				$progname->set_sensitive(TRUE);
			} else {
				$progname->set_sensitive(FALSE);
			}
		}

		#checkbox for "color depth" -> entry active/inactive
		if ($data eq "im_colors_toggled") {
			if ($im_colors_active->get_active) {
				$combobox_im_colors->set_sensitive(TRUE);
			} else {
				$combobox_im_colors->set_sensitive(FALSE);
			}
		}

		#radiobuttons for "transparent parts"
		if ($data eq "transp_toggled") {

			#Sets how the view should draw transparent parts of images with an alpha channel
			if ($trans_check->get_active) {
				$css_provider_alpha->load_from_data("
					.imageview.transparent {
						background-image: url('$shutter_root/share/shutter/resources/gui/checkers.svg');
					}
				");
			} elsif ($trans_custom->get_active) {
				my $color_string = $trans_custom_btn->get_rgba->to_string;
				$css_provider_alpha->load_from_data("
					.imageview.transparent {
						background-color: $color_string;
					}
				");
			} elsif ($trans_backg->get_active) {
				$css_provider_alpha->load_from_data(" ");
			}
			$window->queue_draw;
		}

		#"cursor_status" toggled
		if ($data eq "cursor_status_toggled") {
			$cursor_active->set_active($cursor_status_active->get_active);
		}

		#"cursor" toggled
		if ($data eq "cursor_toggled") {
			$cursor_status_active->set_active($cursor_active->get_active);
		}

		#value for "delay" -> update text
		if ($data eq "delay_changed") {
			$delay_status->set_value($delay->get_value);
			$delay_vlabel->set_text($d->nget("second", "seconds", $delay->get_value));
		}

		#value for "delay" -> update text
		if ($data eq "delay_status_changed") {
			$delay->set_value($delay_status->get_value);
			$delay_status_vlabel->set_text($d->nget("second", "seconds", $delay_status->get_value));
		}

		#value for "menu_delay" -> update text
		if ($data eq "menu_delay_changed") {
			$menu_delay_vlabel->set_text($d->nget("second", "seconds", $menu_delay->get_value));
		}

		#value for "hide_time" -> update text
		if ($data eq "hide_time_changed") {
			$hide_time_vlabel->set_text($d->nget("millisecond", "milliseconds", $hide_time->get_value));
		}

		#checkbox for "thumbnail" -> HScale active/inactive
		if ($data eq "thumbnail_toggled") {
			if ($thumbnail_active->get_active) {
				$thumbnail->set_sensitive(TRUE);
			} else {
				$thumbnail->set_sensitive(FALSE);
			}
		}

		#quality value changed
		if ($data eq "qvalue_changed") {
			my $settings = undef;
			if (defined $sc->get_globalsettings_object) {
				$settings = $sc->get_globalsettings_object;
			} else {
				$settings = Shutter::App::GlobalSettings->new();
				$sc->set_globalsettings_object($settings);
			}
			if ($combobox_type->get_active_text =~ /jpeg/) {
				$settings->set_image_quality("jpg", $scale->get_value);
			} elsif ($combobox_type->get_active_text =~ /jpg/) {
				$settings->set_image_quality("jpg", $scale->get_value);
			} elsif ($combobox_type->get_active_text =~ /png/) {
				$settings->set_image_quality("png", $scale->get_value);
			} elsif ($combobox_type->get_active_text =~ /webp/) {
				$settings->set_image_quality("webp", $scale->get_value);
			} elsif ($combobox_type->get_active_text =~ /avif/) {
				$settings->set_image_quality("avif", $scale->get_value);
			} else {
				$settings->clear_quality_settings();
			}
		}

		#checkbox for "bordereffect" -> HScale active/inactive
		if ($data eq "bordereffect_toggled") {
			if ($bordereffect_active->get_active) {
				$bordereffect->set_sensitive(TRUE);
			} else {
				$bordereffect->set_sensitive(FALSE);
			}
		}

		#value for "bordereffect" -> update text
		if ($data eq "bordereffect_changed") {
			$bordereffect_vlabel->set_text($d->nget("pixel", "pixels", $bordereffect->get_value));
		}

		#filetype changed
		if ($data eq "type_changed") {
			$scale->set_sensitive(TRUE);
			$scale_label->set_sensitive(TRUE);
			$scale_label->set_text($d->get("Quality") . ":");
			if ($combobox_type->get_active_text =~ /jpeg/) {
				$scale->set_range(1, 100);
				$scale->set_value(90);
			} elsif ($combobox_type->get_active_text =~ /jpg/) {
				$scale->set_range(1, 100);
				$scale->set_value(90);
			} elsif ($combobox_type->get_active_text =~ /png/) {
				$scale->set_range(0, 9);
				$scale->set_value(9);
				$scale_label->set_text($d->get("Compression") . ":");
			} elsif ($combobox_type->get_active_text =~ /webp/) {
				$scale->set_range(0, 100);
				$scale->set_value(98);
			} elsif ($combobox_type->get_active_text =~ /avif/) {
				$scale->set_range(0, 100);
				$scale->set_value(68);
			} else {
				$scale->set_sensitive(FALSE);
				$scale_label->set_sensitive(FALSE);
			}
		}

		#notify agent changed
		if ($data eq "ns_changed") {
			if ($combobox_ns->get_active == 0) {
				$sc->set_notification_object(Shutter::App::Notification->new);
			} else {
				$sc->set_notification_object(Shutter::App::ShutterNotification->new($sc));
			}
		}

		return TRUE;
	}


1;
