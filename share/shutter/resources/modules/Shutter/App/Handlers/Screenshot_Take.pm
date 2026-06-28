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

## no critic (Subroutines::ProtectPrivateSubs)

use warnings;
require Shutter::App::Core::FileSystemAPI;
use utf8;
use Future;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use File::Basename;
use POSIX       qw(strftime);
use URI::Escape qw(uri_unescape);
use Shutter::App::SimpleDialogs;
use Shutter::Screenshot::Workspace;
use Shutter::Screenshot::Window;
use Shutter::Screenshot::WindowName;
use Shutter::Screenshot::WindowXid;
use Shutter::Screenshot::SelectorAuto;
use Shutter::Screenshot::SelectorAdvanced;
use Shutter::Screenshot::Web;
use Shutter::Screenshot::Error;
use Shutter::Pixbuf::Border;

has cli => (is => 'ro', required => 1);

sub evt_take_screenshot ($self, $widget, $data, $folder_from_config, $extra) {
	my $cli                    = $self->cli;
	my $sc                     = $cli->sc;
	my $window                 = $cli->window;
	my $d                      = $cli->sc->gettext_object;
	my $hide_active            = $cli->{_hide_active};
	my $notify_ptimeout_active = $cli->{_notify_ptimeout_active};
	my $menu_delay             = $cli->{_menu_delay};
	my $hide_time              = $cli->{_hide_time};
	my $x11_supported          = $cli->{_x11_supported};

	#get xid if any window was selected from the submenu...
	my $selfcapture = FALSE;
	if ($data =~ /^shutter_window_direct(.*)/) {
		my $xid = $1;
		$selfcapture = TRUE if $xid == $window->get_window->get_xid;
	}

	#hide mainwindow
	if (   $hide_active
		&& $hide_active->get_active
		&& $data ne "web"
		&& $data ne "tray_web"
		&& !$cli->{_is_hidden}
		&& !$selfcapture)
	{

		$cli->handlers->get('Core')->fct_control_main_window('hide');

	} else {

		#save current position of main window
		($window->{x}, $window->{y}) = $window->get_position;

	}

	#close last message displayed
	my $notify = $sc->notification;
	$notify->close if $notify;

	#disable signal-handler
	$cli->handlers->get('Core')->fct_control_signals('block');

	if ($data eq "web" || $data eq "tray_web") {
		$self->fct_take_screenshot($widget, $data, $folder_from_config, $extra);

		#unblock signal handler
		$cli->handlers->get('Core')->fct_control_signals('unblock');
		return TRUE;
	} elsif (!$x11_supported && $data ne "full" && $data ne "tray_full") {
		my $sd = Shutter::App::SimpleDialogs->new;
		$sd->dlg_error_message($d->get("Can't take screenshots without X11 server"), $d->get("Failed"));
		$cli->handlers->get('Core')->fct_control_signals('unblock');
		$cli->handlers->get('Core')->fct_control_main_window('show');
		return TRUE;
	}

	if (   $data eq "menu"
		|| $data eq "tray_menu"
		|| $data eq "tooltip"
		|| $data eq "tray_tooltip")
	{

		my $scd_text;
		if ($data eq "menu" || $data eq "tray_menu") {
			$scd_text = $d->get("Please activate the menu you want to capture");
			if ($ENV{GDK_SCALE} && $ENV{GDK_SCALE} > 1) {
				my $sd = Shutter::App::SimpleDialogs->new;
				$sd->dlg_info_message(
"Capturing a cascading menu is known to be broken with HiDPI.\nPlease unset GDK_SCALE variable and restart Shutter.\nPlease follow https://github.com/shutter-project/shutter/issues/326 and send us the patch\nWill attempt capturing it anyway...",
					undef, 'gtk-ok'
				);
			}
		} elsif ($data eq "tooltip" || $data eq "tray_tooltip") {
			$scd_text = $d->get("Please activate the tooltip you want to capture");
		}

		#show notification messages displaying the countdown
		if ($notify_ptimeout_active && $notify_ptimeout_active->get_active) {
			my $notify = $sc->notification;
			my $ttw    = $menu_delay->get_value;

			#first notification immediately
			$notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text) if $notify;
			$ttw--;

			#delay is only 1 second
			#do not show any further messages
			if ($ttw >= 1) {

				#then controlled via timeout
				Glib::Timeout->add(
					1000,
					sub {
						$notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text) if $notify;
						$ttw--;
						if ($ttw == 0) {

							#close last message with a short delay (less than a second)
							Glib::Timeout->add(
								500,
								sub {
									$notify->close if $notify;
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
						$notify->close if $notify;
						return FALSE;
					});
			}
		}    #notify not activated

		#capture with delay
		Glib::Timeout->add(
			$menu_delay->get_value * 1000,
			sub {
				$self->fct_take_screenshot($widget, $data, $folder_from_config, $extra);

				#unblock signal handler
				$cli->handlers->get('Core')->fct_control_signals('unblock');
				return FALSE;
			});
	} else {
		if (($data eq "section" || $data eq "tray_section") && $ENV{GDK_SCALE} && $ENV{GDK_SCALE} > 1) {
			my $sd = Shutter::App::SimpleDialogs->new;
			$sd->dlg_info_message(
"Capturing a window section is known to be broken with HiDPI.\nPlease unset GDK_SCALE variable and restart Shutter.\nPlease follow https://github.com/shutter-project/shutter/issues/326 and send us the patch\nWill attempt capturing it anyway...",
				undef, 'gtk-ok'
			);
		}

		#A short timeout to give the server a chance to
		#redraw the area that was obscured by our dialog.
		Glib::Timeout->add(
			$hide_time->get_value,
			sub {
				$self->fct_take_screenshot($widget, $data, $folder_from_config, $extra);

				#unblock signal handler
				$cli->handlers->get('Core')->fct_control_signals('unblock');
				return FALSE;
			});
	}

	return TRUE;
}

sub fct_take_screenshot ($self, $widget, $data, $folder_from_config, $extra) {
	my $cli  = $self->cli;
	my $sc   = $cli->sc;
	my $shf  = $cli->shf;
	my $sd   = $cli->{_sd};
	my $sp   = $cli->{_sp};
	my $lp   = $cli->{_lp};
	my $acp  = $cli->{acp};
	my $pins = $cli->{pins};
	my $d    = $sc->gettext_object;
	my $sm   = $cli->{settings_manager};

	# Get settings from SettingsManager
	my $quality_value  = $sm->get_setting('general', 'quality')  // 9;
	my $filename_value = $sm->get_setting('general', 'filename') // '$name_%NNN';
	my $folder         = $sm->get_setting('general', 'folder')   // $folder_from_config // Glib::get_user_special_dir('pictures') // Glib::get_home_dir();

	my $save_no_active  = $sm->get_setting('general', 'save_no')  // FALSE;
	my $save_ask_active = $sm->get_setting('general', 'save_ask') // FALSE;

	my $filetype_index = $sm->get_setting('general', 'filetype');

	my $cursor_active = $sm->get_setting('general', 'cursor') // FALSE;

	# Other settings (stubs for now)
	my $notify_timeout_active     = $cli->{_notify_timeout_active}     // Shutter::App::Init::_mock_widget(FALSE);
	my $current_monitor_active    = $cli->{_current_monitor_active}    // Shutter::App::Init::_mock_widget(FALSE);
	my $border_active             = $cli->{_border_active}             // Shutter::App::Init::_mock_widget(FALSE);
	my $winresize_active          = $cli->{_winresize_active}          // Shutter::App::Init::_mock_widget(FALSE);
	my $winresize_w               = $cli->{_winresize_w}               // Shutter::App::Init::_mock_widget(800);
	my $winresize_h               = $cli->{_winresize_h}               // Shutter::App::Init::_mock_widget(600);
	my $hide_time                 = $cli->{_hide_time}                 // Shutter::App::Init::_mock_widget(250);
	my $autoshape_active          = $cli->{_autoshape_active}          // Shutter::App::Init::_mock_widget(FALSE);
	my $is_hidden                 = $cli->{_is_hidden}                 // FALSE;
	my $visible_windows_active    = $cli->{_visible_windows_active}    // Shutter::App::Init::_mock_widget(FALSE);
	my $menu_waround_active       = $cli->{_menu_waround_active}       // Shutter::App::Init::_mock_widget(FALSE);
	my $zoom_active               = $cli->{_zoom_active}               // Shutter::App::Init::_mock_widget(FALSE);
	my $as_help_active            = $cli->{_as_help_active}            // Shutter::App::Init::_mock_widget(FALSE);
	my $asel_size1                = $cli->{_asel_size1}                // Shutter::App::Init::_mock_widget(0);
	my $asel_size2                = $cli->{_asel_size2}                // Shutter::App::Init::_mock_widget(0);
	my $asel_size3                = $cli->{_asel_size3}                // Shutter::App::Init::_mock_widget(0);
	my $asel_size4                = $cli->{_asel_size4}                // Shutter::App::Init::_mock_widget(0);
	my $as_confirmation_necessary = $cli->{_as_confirmation_necessary} // Shutter::App::Init::_mock_widget(FALSE);
	my $combobox_web_width        = $cli->{_combobox_web_width}        // Shutter::App::Init::_mock_widget(1024);
	my $st                        = $cli->{st};
	my $bordereffect_active       = $cli->{_bordereffect_active}   // Shutter::App::Init::_mock_widget(FALSE);
	my $bordereffect              = $cli->{_bordereffect}          // Shutter::App::Init::_mock_widget(0);
	my $bordereffect_cbtn         = $cli->{_bordereffect_cbtn}     // Shutter::App::Init::_mock_widget(undef);
	my $im_colors_active          = $cli->{_im_colors_active}      // Shutter::App::Init::_mock_widget(FALSE);
	my $combobox_im_colors        = $cli->{_combobox_im_colors}    // Shutter::App::Init::_mock_widget(0);
	my $thumbnail_active          = $cli->{_thumbnail_active}      // Shutter::App::Init::_mock_widget(FALSE);
	my $thumbnail                 = $cli->{_thumbnail}             // Shutter::App::Init::_mock_widget(25);
	my $no_autocopy_active        = $cli->{_no_autocopy_active}    // Shutter::App::Init::_mock_widget(FALSE);
	my $image_autocopy_active     = $cli->{_image_autocopy_active} // Shutter::App::Init::_mock_widget(FALSE);
	my $fname_autocopy_active     = $cli->{_fname_autocopy_active} // Shutter::App::Init::_mock_widget(FALSE);
	my $progname_active           = $cli->{_progname_active}       // Shutter::App::Init::_mock_widget(FALSE);
	my $progname                  = $cli->{_progname}              // Shutter::App::Init::_mock_widget(undef);
	my $notify_after_active       = $cli->{_notify_after_active}   // Shutter::App::Init::_mock_widget(FALSE);
	my $present_after_active      = $cli->{_present_after_active}  // Shutter::App::Init::_mock_widget(FALSE);
	require Shutter::App::Core::ClipboardAPI;
	my $clipboard                 = Shutter::App::Core::ClipboardAPI->new;
	my $x11_supported             = $cli->{_x11_supported};
	my $wnck_screen               = undef;
	try { $wnck_screen = Wnck::Screen::get_default(); } catch ($e) {
	}

	print "\n$data was emitted by widget " . ($widget // 'none') . "\n" if $sc->debug;

	# screenshot(pixbuf) and screenshot name
	my $screenshot       = undef;
	my $screenshooter    = undef;
	my $screenshot_name  = undef;
	my $thumbnail_ending = "thumb";

	# Mock Capture Mode
	my $filetype_value;

	if ($sc->mock_capture) {
		print "Mock Capture Mode enabled - using static test image\n" if $sc->debug;
		$screenshot = Gtk3::Gdk::Pixbuf->new_from_file($sc->shutter_root . "/share/shutter/resources/icons/web_image.svg");

		$quality_value  = 90;
		$filetype_value = "png";
		$folder         = $folder_from_config || "/tmp";
		$filename_value = "mock_capture";

		$screenshooter = MockScreenshooter->new;
		goto POST_CAPTURE;
	}

	#delay
	my $delay_value = undef;

	#include_cursor
	my $include_cursor = undef;

	#folder to save
	if ($save_no_active) {

		# $folder = Shutter::App::Directories::get_cache_dir(); # FIXME: Directories.pm might not be loaded
		$folder = "/tmp/shutter_cache";
		Shutter::App::Core::FileSystemAPI->new->Shutter::App::Core::FileSystemAPI->new->make_dir($folder) unless Shutter::App::Core::FileSystemAPI->new->is_directory($folder);
	}

	#determine current file type
	my @supported_formats;
	my $png_index = 0;
	my $i         = 0;
	foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
		my $format_name = $format->get_name;
		if (grep { $_ eq $format_name } qw(jpeg png bmp webp avif)) {
			$format_name = "jpg" if $format_name eq "jpeg";
			push @supported_formats, $format_name;
			$png_index = $i if $format_name eq "png";
			$i++;
		}
	}
	$filetype_index //= $png_index;
	$filetype_value = $supported_formats[$filetype_index] // "png";

	#delay
	unless ($data eq "menu" || $data eq "tray_menu" || $data eq "tooltip" || $data eq "tray_tooltip") {
		if (defined $sc->delay) {
			$delay_value = int $sc->delay;
		} else {
			$delay_value = int($delay_value // 0);
		}
	} else {
		$delay_value = 0;
	}

	#cursor
	if ($sc->include_cursor) {
		$include_cursor = $sc->include_cursor;
	} elsif ($sc->remove_cursor) {
		$include_cursor = FALSE;
	} else {
		$include_cursor = $cursor_active;
	}

	#fullscreen screenshot
	if ($data eq "full" || $data eq "tray_full") {
		if ($x11_supported) {
			$screenshooter = Shutter::Screenshot::Workspace->new(
				$sc, $include_cursor, $delay_value,
				$notify_timeout_active->get_active,
				$wnck_screen ? $wnck_screen->get_active_workspace : undef,
				undef, undef, $current_monitor_active->get_active
			);
			$screenshot = $screenshooter->workspace_async();
		} else {
			$screenshot = Shutter::Screenshot::Wayland::xdg_portal($screenshooter);
		}
	} elsif ($data =~ /^(window|tray_window|awindow|tray_awindow|section|tray_section|menu|tray_menu|tooltip|tray_tooltip)$/) {
		if ($x11_supported) {

			# FIXME: fct_control_wm_settings not easily accessible
			if (defined $extra && $extra) {
				$screenshooter = Shutter::Screenshot::WindowName->new(
					$sc,                        $include_cursor,               $delay_value,            $notify_timeout_active->get_active,
					$border_active->get_active, $winresize_active->get_active, $winresize_w->get_value, $winresize_h->get_value,
					$hide_time->get_value,      $data,                         $autoshape_active->get_active
				);
				$screenshot = $screenshooter->window_find_by_name($extra);
			} else {
				$screenshooter = Shutter::Screenshot::Window->new(
					$sc,                                 $include_cursor,               $delay_value,                  $notify_timeout_active->get_active,
					$border_active->get_active,          $winresize_active->get_active, $winresize_w->get_value,       $winresize_h->get_value,
					$hide_time->get_value,               $data,                         $autoshape_active->get_active, $is_hidden,
					$visible_windows_active->get_active, $menu_waround_active->get_active
				);
				$screenshot = $screenshooter->window_async();
			}
		} else {
			$screenshooter = {};                                                            # dummy object
			$screenshot    = Shutter::Screenshot::Wayland::xdg_portal($screenshooter, 1);
		}
	} elsif ($data eq "select" || $data eq "tray_select") {
		if ($x11_supported) {
			if (defined $extra && $extra) {
				my @coords = split(',', $extra);
				$screenshooter = Shutter::Screenshot::SelectorAuto->new($sc, $include_cursor, $delay_value, $notify_timeout_active->get_active);
				$screenshot    = $screenshooter->select_auto($coords[0], $coords[1], $coords[2], $coords[3]);
			} else {
				$screenshooter = Shutter::Screenshot::SelectorAdvanced->new(
					$sc,                      $include_cursor,        $delay_value,                $notify_timeout_active->get_active,
					$zoom_active->get_active, $hide_time->get_value,  $as_help_active->get_active, $asel_size3->get_value,
					$asel_size4->get_value,   $asel_size1->get_value, $asel_size2->get_value,      $as_confirmation_necessary->get_active,
				);
				$screenshot = $screenshooter->select_advanced();
			}
		} else {
			$screenshooter = {};                                                            # dummy object
			$screenshot    = Shutter::Screenshot::Wayland::xdg_portal($screenshooter, 1);
		}
	} elsif ($data eq "web" || $data eq "tray_web") {
		my $website_width = 1024;
		if ($combobox_web_width->get_active_text =~ /(\d+)/) {
			$website_width = $1;
		}
		$screenshooter = Shutter::Screenshot::Web->new($sc, 10, $website_width);    # Fixed 10s timeout for now
		$screenshot    = $screenshooter->dlg_website($extra);
	}

	my $post_capture_cb = sub {
		my ($screenshot) = @_;

		unless ($screenshot) {
			$sd->dlg_error_message($d->get("Error while taking the screenshot."), $d->get("Failed"));
			$cli->handlers->get('Core')->fct_control_main_window('show');
			return FALSE;
		}

		my $giofile = undef;
		my $error   = Shutter::Screenshot::Error->new($sc, $screenshot, $data, $extra);
		if ($error->is_error) {
			my $detailed_error_text = $screenshooter ? $screenshooter->get_error_text : '';
			my ($response, $status_text) = $error->show_dialog($detailed_error_text);
			if ($error->is_aborted_by_user) {
				$cli->handlers->get('Core')->fct_control_main_window('show', $present_after_active->get_active);
			} else {
				$cli->handlers->get('Core')->fct_control_main_window('show');
			}
			return FALSE;
		} else {
			if ($sc->export_filename) {
				my ($short, $folder_path, $ext) = fileparse($shf->switch_home_in_file($shf->utf8_decode($sc->export_filename)), qr/\.[^.]*/);
				$filetype_value = $ext;
				$filetype_value =~ s/\.//;
				$short = strftime $short, localtime;
				$short =~ s/(\/|\#)/-/g;
				my $tmp_filename = $folder_path . $short . $ext;
				$tmp_filename = File::Spec->rel2abs($tmp_filename) unless File::Spec->file_name_is_absolute($tmp_filename);
				$tmp_filename = $cli->handlers->get('Util_File')->fct_parse_filename_wildcards($tmp_filename, $screenshooter, $screenshot);
				$giofile      = Glib::IO::File::new_for_path($tmp_filename);
			} else {
				$filename_value = $shf->utf8_decode(strftime $filename_value, localtime);
				$filename_value =~ s/(\/|\#)/-/g;
				$filename_value = $cli->handlers->get('Util_File')->fct_parse_filename_wildcards($filename_value, $screenshooter, $screenshot);
				$giofile        = $cli->handlers->get('Util_Get')->fct_get_next_filename($filename_value, $folder, $filetype_value);
			}

			unless ($giofile) {
				$sd->dlg_error_message($d->get("There was an error determining the filename."), $d->get("Failed"));
				$cli->handlers->get('Core')->fct_control_main_window('show');
				return FALSE;
			}

			$screenshot_name = $shf->utf8_decode(uri_unescape($giofile->get_path));
			$screenshot_name = "/" . $giofile->get_basename unless $screenshot_name;
			$giofile         = Glib::IO::File::new_for_path($screenshot_name);

			# Bordereffect
			if ($bordereffect_active->get_active) {
				my $pbuf_border = Shutter::Pixbuf::Border->new($sc);
				$screenshot = $pbuf_border->create_border($screenshot, $bordereffect->get_value, $bordereffect_cbtn->get_color);
			}

			# Save pixbuf
			unless ($sp->save_pixbuf_to_file($screenshot, $screenshot_name, $filetype_value, $quality_value)) {
				$cli->handlers->get('Core')->fct_control_main_window('show');
				return FALSE;
			}
		}

		if ($giofile->query_exists) {

			# Integrate into session
			unless ($sc->no_session) {
				$cli->handlers->get('Workflow_Integrate')->fct_integrate_screenshot_in_notebook($giofile, $screenshot, $screenshooter);
			}

			# After Capture Pipeline
			if ($acp && $acp->get_steps) {
				my $upload_link_container = \ '';
				$acp->execute({
						filename    => $screenshot_name,
						pixbuf      => $screenshot,
						clipboard   => $clipboard,
						upload_link => \$upload_link_container,
						editor_cb   => sub {
							$cli->handlers->get('Upload_Main')->fct_open_with_program(@_);
						},
						upload_cb => sub {
							$cli->handlers->get('Dialogs_Upload')->fct_upload();
						},
						pin_cb => sub {
							my ($pbuf) = @_;
							$pins->pin($pbuf, $sc) if $pins;
						},
					});
			}
		}

		$cli->handlers->get('Core')->fct_control_main_window('show', $present_after_active->get_active);

		if ($sc->exit_after_capture) {
			$cli->handlers->get('Core')->evt_delete_window('', 'quit');
		}

		return TRUE;
	};

	if ($sc->mock_capture) {
		return $post_capture_cb->($screenshot);
	}

	if (eval { $screenshot->isa('Future') }) {
		$screenshot->then(
			sub {
				$post_capture_cb->($_[0]);
				return Future->done();
			})->retain;
		return TRUE;
	} else {
		return $post_capture_cb->($screenshot);
	}
}

package MockScreenshooter {    ## no critic (Modules::ProhibitMultiplePackages)
	sub new             { return bless {}, shift }
	sub get_mode        { return "mock" }
	sub get_action_name { return "mock_action" }
	sub get_history     { return 1 }
	sub get_error_text  { return "" }
	sub can             { return 1 }

	sub redo_capture {
		return Gtk3::Gdk::Pixbuf->new_from_file($ENV{SHUTTER_ROOT} . "/share/shutter/resources/icons/web_image.svg");
	}
}

1;
