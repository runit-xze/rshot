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

package Shutter::App::Handlers::Other;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_take_screenshot {
		my ($widget, $data, $folder_from_config, $extra) = @_;

		print "\n$data was emitted by widget $widget\n"
			if $sc->get_debug;

		#quality
		my $quality_value = $scale->get_value();

		#delay
		my $delay_value = undef;

		#include_cursor
		my $include_cursor = undef;

		#filename
		my $filename_value = $filename->get_text();

		#filetype
		my $filetype_value = undef;

		#folder to save
		my $folder = Glib::filename_to_unicode($saveDir_button->get_filename) || $folder_from_config;
		if ($save_no_active->get_active) {
			$folder = Shutter::App::Directories::get_cache_dir();
		}

		#screenshot(pixbuf) and screenshot name
		my $screenshot       = undef;
		my $screenshooter    = undef;
		my $screenshot_name  = undef;
		my $thumbnail_ending = "thumb";

		#determine current file type (name - description)
		$combobox_type->get_active_text =~ /(.*) -/;
		$filetype_value = $1;
		unless ($filetype_value) {
			$sd->dlg_error_message($d->get("No valid filetype specified"), $d->get("Failed"));
			fct_control_main_window('show');
			return FALSE;
		}

		#delay
		#when capturing a menu or tooltip => disable delay (there is a dedicated delay property for this)
		unless ($data eq "menu"
			|| $data eq "tray_menu"
			|| $data eq "tooltip"
			|| $data eq "tray_tooltip")
		{
			if (defined $sc->get_delay) {
				$delay_value = int $sc->get_delay;
			} else {
				if ($delay->get_value) {
					$delay_value = int $delay->get_value;
				} else {
					$delay_value = 0;
				}
			}
		} else {
			$delay_value = 0;
		}

		#cursor
		if ($sc->get_include_cursor) {
			$include_cursor = $sc->get_include_cursor;
		} elsif ($sc->get_remove_cursor) {
			$include_cursor = FALSE;
		} else {
			if ($cursor_active->get_active) {
				$include_cursor = $cursor_active->get_active;
			} else {
				$include_cursor = FALSE;
			}
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
				$screenshot = $screenshooter->workspace();
			} else {
				# TODO: support kwin directly, because it has more features than the xdg portal
				$screenshot = Shutter::Screenshot::Wayland::xdg_portal($screenshooter);
			}

		#window
		} elsif ($data eq "window"
			|| $data eq "tray_window"
			|| $data eq "awindow"
			|| $data eq "tray_awindow"
			|| $data eq "section"
			|| $data eq "tray_section"
			|| $data eq "menu"
			|| $data eq "tray_menu"
			|| $data eq "tooltip"
			|| $data eq "tray_tooltip")
		{

			#control some wm related settings
			my $curr_value = fct_control_wm_settings('start');

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

				$screenshot = $screenshooter->window();

			}

			#control some wm related settings
			if (defined $curr_value && $curr_value != -1) {
				fct_control_wm_settings('stop', $curr_value);
			}

			#selection
		} elsif ($data eq "select" || $data eq "tray_select") {

			if (defined $extra && $extra) {

				my @coords = split(',', $extra);

				$screenshooter = Shutter::Screenshot::SelectorAuto->new($sc, $include_cursor, $delay_value, $notify_timeout_active->get_active,);

				$screenshot = $screenshooter->select_auto($coords[0], $coords[1], $coords[2], $coords[3]);

			} else {

				$screenshooter = Shutter::Screenshot::SelectorAdvanced->new(
					$sc,                      $include_cursor,        $delay_value,                $notify_timeout_active->get_active,
					$zoom_active->get_active, $hide_time->get_value,  $as_help_active->get_active, $asel_size3->get_value,
					$asel_size4->get_value,   $asel_size1->get_value, $asel_size2->get_value,			 $as_confirmation_necessary->get_active,
				);

				$screenshot = $screenshooter->select_advanced();

			}

			#web
		} elsif ($data eq "web" || $data eq "tray_web") {

			my $website_width = 1024;
			if ($combobox_web_width->get_active_text =~ /(\d+)/) {
				$website_width = $1;
			}

			print "\nvirtual website width: $website_width\n"
				if $sc->get_debug;

			#determine timeout
			my $web_menu = $st->{_web}->get_menu;
			my @timeouts = $web_menu->get_children;
			my $timeout  = undef;
			foreach my $to (@timeouts) {
				if ($to->get_active) {
					$timeout = $to->get_name;
					$timeout =~ /([0-9]+)/;
					$timeout = $1;
					print $timeout. "\n" if $sc->get_debug;
				}
			}

			$screenshooter = Shutter::Screenshot::Web->new($sc, $timeout, $website_width);
			$screenshot    = $screenshooter->dlg_website($extra);

			#window by xid
		} elsif ($data =~ /^shutter_window_direct(.*)/) {

			my $xid = $1;
			print "Selected xid: $xid\n" if $sc->get_debug;

			#control some wm related settings
			my $curr_value = fct_control_wm_settings('start');

			#change mode (imitating selecting a window by mouse)
			$data = "window";

			$screenshooter = Shutter::Screenshot::WindowXid->new(
				$sc,                        $include_cursor,               $delay_value,            $notify_timeout_active->get_active,
				$border_active->get_active, $winresize_active->get_active, $winresize_w->get_value, $winresize_h->get_value,
				$hide_time->get_value,      $data,                         $autoshape_active->get_active
			);

			$screenshot = $screenshooter->window_by_xid($xid);

			#control some wm related settings
			if (defined $curr_value && $curr_value != -1) {
				fct_control_wm_settings('stop', $curr_value);
			}

		} elsif ($data =~ /^shutter_wrksp_direct/) {

			#we need to handle different wm, e.g. metacity, compiz here
			my $selected_workspace = undef;
			my $vpx                = undef;
			my $vpy                = undef;

			#compiz
			if ($data =~ /compiz(\d*)x(\d*)/) {
				$vpx = $1;
				$vpy = $2;
				print "Sel. Viewport: $vpx, $vpy\n" if $sc->get_debug;

				#metacity etc.
			} elsif ($data =~ /shutter_wrksp_direct(.*)/) {
				$selected_workspace = $1;
				print "Sel. Workspace: $selected_workspace\n"
					if $sc->get_debug;

				#all workspaces
			} elsif ($data =~ /shutter_wrksp_all/) {
				print "Capturing all workspaces\n"
					if $sc->get_debug;
				$selected_workspace = 'all';
			}

			$screenshooter =
				Shutter::Screenshot::Workspace->new($sc, $include_cursor, $delay_value, $notify_timeout_active->get_active, $selected_workspace, $vpx, $vpy, $current_monitor_active->get_active);

			if ($selected_workspace eq 'all') {
				$screenshot = $screenshooter->workspaces();
			} else {
				$screenshot = $screenshooter->workspace();
			}

		} elsif ($data eq "redoshot") {

			#~ my $key = fct_get_last_capture();
			#~ if(defined $key && exists $session_screens{$key}->{'history'} && defined $session_screens{$key}->{'history'}){
			#~ $screenshooter = $session_screens{$key}->{'history'};
			#~ $screenshot = $screenshooter->redo_capture;
			#~ }else{
			#~ $screenshot = 3;
			#~ }

			if ($screenshooter = fct_get_last_capture()) {

				#we need to handle menu and tooltip in a special way
				if ($screenshooter->can('get_mode')) {
					if (my $mode = $screenshooter->get_mode) {

						#control some wm related settings
						my $curr_value = undef;
						if (($mode eq "window" || $mode eq "tray_window" || $mode eq "awindow" || $mode eq "tray_awindow" || $mode eq "section" || $mode eq "tray_section")) {
							$curr_value = fct_control_wm_settings('start');
						}

						if ($mode eq "menu" || $mode eq "tray_menu") {
							$st->{_menu}->signal_emit('clicked');
							return FALSE;
						} elsif ($mode eq "tooltip" || $mode eq "tray_tooltip") {
							$st->{_tooltip}->signal_emit('clicked');
							return FALSE;
						} else {
							$screenshot = $screenshooter->redo_capture;
						}

						#control some wm related settings
						if (($mode eq "window" || $mode eq "tray_window" || $mode eq "awindow" || $mode eq "tray_awindow" || $mode eq "section" || $mode eq "tray_section")) {
							if (defined $curr_value && $curr_value != -1) {
								fct_control_wm_settings('stop', $curr_value);
							}
						}

						#window by xid
					} else {

						#control some wm related settings
						my $curr_value = fct_control_wm_settings('start');
						$screenshot = $screenshooter->redo_capture;

						#control some wm related settings
						if (defined $curr_value && $curr_value != -1) {
							fct_control_wm_settings('stop', $curr_value);
						}
					}
				} else {
					$screenshot = $screenshooter->redo_capture;
				}
			} else {
				$screenshot = 3;
			}

		} elsif ($data eq "redoshot_this") {

			#get current screenshot (current notebook page)
			my $key = fct_get_current_file();

			#or get the selected screenshot in the view
			unless (defined $key) {
				$session_start_screen{'first_page'}->{'view'}->selected_foreach(
					sub {
						my ($view, $path) = @_;
						my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
						if (defined $iter) {
							$key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						}
					},
					undef
				);
			}

			if (   defined $key
				&& exists $session_screens{$key}->{'history'}
				&& defined $session_screens{$key}->{'history'})
			{
				$screenshooter = $session_screens{$key}->{'history'};

				#we need to handle menu and tooltip in a special way
				if ($screenshooter->can('get_mode')) {
					if (my $mode = $screenshooter->get_mode) {

						#control some wm related settings
						my $curr_value = undef;
						if (($mode eq "window" || $mode eq "tray_window" || $mode eq "awindow" || $mode eq "tray_awindow" || $mode eq "section" || $mode eq "tray_section")) {
							$curr_value = fct_control_wm_settings('start');
						}

						if ($mode eq "menu" || $mode eq "tray_menu") {
							$st->{_menu}->signal_emit('clicked');
							return FALSE;
						} elsif ($mode eq "tooltip" || $mode eq "tray_tooltip") {
							$st->{_tooltip}->signal_emit('clicked');
							return FALSE;
						} else {
							$screenshot = $screenshooter->redo_capture;
						}

						#control some wm related settings
						if (($mode eq "window" || $mode eq "tray_window" || $mode eq "awindow" || $mode eq "tray_awindow" || $mode eq "section" || $mode eq "tray_section")) {
							if (defined $curr_value && $curr_value != -1) {
								fct_control_wm_settings('stop', $curr_value);
							}
						}

						#window by xid
					} else {

						#control some wm related settings
						my $curr_value = fct_control_wm_settings('start');
						$screenshot = $screenshooter->redo_capture;

						#control some wm related settings
						if (defined $curr_value && $curr_value != -1) {
							fct_control_wm_settings('stop', $curr_value);
						}
					}
				} else {
					$screenshot = $screenshooter->redo_capture;
				}
			} else {
				$screenshot = 3;
			}

		} else {

			#show error dialog
			my $response = $sd->dlg_error_message($d->get("Triggered invalid screenshot action."), $d->get("Error while taking the screenshot."));

			fct_show_status_message(1, $d->get("Error while taking the screenshot."));
			fct_control_main_window('show');
			return FALSE;
		}

		#screenshot was taken at this stage...
		#start postprocessing here

		#...successfully???
		
		# $screenshot is undefined if the selection width or height is zero
		# Actually this should be handled by Shutter::Screenshot::Error but fails for an area with zero width or height for some reason
		unless ($screenshot) {
			my $response = $sd->dlg_error_message($d->get("Error: selection width or height is zero, please retry!"), $d->get("Failed"));
			fct_control_main_window('show');
			return FALSE;
		}

		my $giofile = undef;
		my $error = Shutter::Screenshot::Error->new($sc, $screenshot, $data, $extra);
		if ($error->is_error) {
			my $detailed_error_text = '';
			if (defined $screenshooter && $screenshooter) {
				$detailed_error_text = $screenshooter->get_error_text;
			}
			my ($response, $status_text) = $error->show_dialog($detailed_error_text);
			fct_show_status_message(1, $status_text);
			if ($error->is_aborted_by_user) {
				fct_control_main_window('show', $present_after_active->get_active);
			} else {
				fct_control_main_window('show');
			}
			return FALSE;

		} else {
			#get next filename (auto increment using a wild card or manually)
			if ($sc->get_export_filename) {
				my ($short, $folder, $ext) = fileparse($shf->switch_home_in_file($shf->utf8_decode($sc->get_export_filename)), qr/\.[^.]*/);

				#set filetype
				$filetype_value = $ext;
				$filetype_value =~ s/\.//;

				#prepare filename, parse wild-cards
				$short = strftime $short, localtime;

				#..remove / and #
				$short =~ s/(\/|\#)/-/g;

				#relative to abs
				my $tmp_filename = $folder . $short . $ext;
				unless (File::Spec->file_name_is_absolute($tmp_filename)) {
					$tmp_filename = File::Spec->rel2abs($tmp_filename);
				}

				#..replace wildcards by values
				$tmp_filename = &fct_parse_filename_wildcards($tmp_filename, $screenshooter, $screenshot);

				#...and create an uri
				$giofile = Glib::IO::File::new_for_path($tmp_filename);
			} else {

				#prepare filename, parse wild-cards
				$filename_value = $shf->utf8_decode(strftime $filename_value , localtime);

				#..remove / and #
				$filename_value =~ s/(\/|\#)/-/g;

				#..replace wildcards by values
				$filename_value = &fct_parse_filename_wildcards($filename_value, $screenshooter, $screenshot);

				#...and get next filename
				$giofile = fct_get_next_filename($filename_value, $folder, $filetype_value);
			}

			#no valid filename was determined, exit here
			unless ($giofile) {
				my $response = $sd->dlg_error_message($d->get("There was an error determining the filename."), $d->get("Failed"));
				fct_control_main_window('show');
				return FALSE;
			}


			#we have to use the path (e.g. /home/username/file1.png)
			#so we can save the screenshot_properly
			$screenshot_name = $shf->utf8_decode(unescape_string($giofile->get_path));

			#maybe / is set as uri (get_path returns undef)
			#in this case nothing is returned when using get_path
			#we use the directory name and the short name in this case
			#(anyway - most users won't have permissions to write to /)
			$screenshot_name = "/" . $giofile->get_basename
				unless $screenshot_name;

			#update uri after parsing as well, so we can check if file exists for example
			$giofile = Glib::IO::File::new_for_path($screenshot_name);

			#maybe the uri already exists, so we have to append some digits (e.g. testfile01(0002).png)
			#don't check if filename is set via cmd parameter
			unless ($sc->get_export_filename) {
				if ($giofile->query_exists) {
					my $count        = 1;
					my $new_filename = fileparse($shf->utf8_decode(unescape_string($giofile->get_path)), qr/\.[^.]*/);

					print "Checking if filename already exists: " . $new_filename . "\n"
						if $sc->get_debug;

					my $existing_filename = $new_filename;
					while ($giofile->query_exists) {
						$new_filename = $existing_filename . "(" . sprintf("%03d", $count++) . ")";
						$giofile      = Glib::IO::File::new_for_path($folder);
						$giofile      = $giofile->append_string("$new_filename.$filetype_value");
						print "Checking new uri after parsing: " . $giofile->get_path . "\n"
							if $sc->get_debug;
					}
				}
			}

			#we have to update the path again
			$screenshot_name = $shf->utf8_decode(unescape_string($giofile->get_path));

			#no valid filename was determined, exit here
			unless ($screenshot_name) {
				my $response = $sd->dlg_error_message($d->get("There was an error determining the filename."), $d->get("Failed"));
				fct_control_main_window('show');
				return FALSE;
			}

			print "New uri after exists check: " . $shf->utf8_decode($giofile->get_path) . "\n"
				if $sc->get_debug;

			#manipulate before saving
			#bordereffect
			if ($bordereffect_active->get_active) {

				print "Adding border effect to $screenshot_name\n"
					if $sc->get_debug;

				my $pbuf_border = Shutter::Pixbuf::Border->new($sc);
				$screenshot = $pbuf_border->create_border($screenshot, $bordereffect->get_value, $bordereffect_cbtn->get_color);
			}

			#ask for filename and folder
			if ($save_ask_active->get_active) {

				print "Asking for filename\n"
					if $sc->get_debug;

				if ($screenshot_name = dlg_save_as(undef, undef, $screenshot_name, $screenshot, $quality_value)) {
					if ($screenshot_name eq 'user_cancel') {
						fct_show_status_message(1, $d->get("Capture aborted by user"));
						fct_control_main_window('show', $present_after_active->get_active);
						return FALSE;
					} else {

						#update uri after saving, so we can check if file exists for example
						$giofile = Glib::IO::File::new_for_path($screenshot_name);
					}
				} else {
					fct_control_main_window('show');
					return FALSE;
				}

			} else {

				print "Trying to save file to $screenshot_name\n"
					if $sc->get_debug;

				#finally save pixbuf
				unless ($sp->save_pixbuf_to_file($screenshot, $screenshot_name, $filetype_value, $quality_value)) {
					fct_control_main_window('show');
					return FALSE;
				}

			}

		}    #end screenshot successfull

		if ($giofile->query_exists) {

			#quantize
			if ($im_colors_active->get_active) {
				my $colors;
				if ($combobox_im_colors->get_active == 0) {
					$colors = 16;
				} elsif ($combobox_im_colors->get_active == 1) {
					$colors = 64;
				} elsif ($combobox_im_colors->get_active == 2) {
					$colors = 256;
				}
				$screenshot = fct_imagemagick_perform('reduce_colors', $screenshot_name, $colors);
			}

			#generate the thumbnail
			my $screenshot_thumbnail      = undef;
			my $screenshot_thumbnail_name = undef;
			if ($thumbnail_active->get_active) {

				#calculate size
				my $twidth  = int($screenshot->get_width * ($thumbnail->get_value / 100));
				my $theight = int($screenshot->get_height * ($thumbnail->get_value / 100));

				#create thumbail
				$screenshot_thumbnail = $lp->load($screenshot_name, $twidth, $theight, TRUE);

				#save path of thumbnail
				my ($name, $folder, $ext) = fileparse($screenshot_name, qr/\.[^.]*/);
				$screenshot_thumbnail_name = $folder . "/$name-$thumbnail_ending.$filetype_value";

				#parse wild cards
				$screenshot_thumbnail_name =~ s/\$w/$twidth/g;
				$screenshot_thumbnail_name =~ s/\$h/$theight/g;

				print "Trying to save file to $screenshot_thumbnail_name\n"
					if $sc->get_debug;

				#finally save pixbuf
				unless ($sp->save_pixbuf_to_file($screenshot_thumbnail, $screenshot_thumbnail_name, $filetype_value, $quality_value)) {
					fct_control_main_window('show');
					return FALSE;
				}

			}

			#Dont add it to session if no_session-parameter is set
			unless ($sc->get_no_session) {

				#Dont add it to session if it already exists
				unless (fct_is_uri_in_session($giofile, TRUE)) {

					#integrate it into the notebook
					$new_key_screenshot = fct_integrate_screenshot_in_notebook($giofile, $screenshot, $screenshooter);

					#thumbnail as well if present
					$new_key_screenshot_thumbnail = fct_integrate_screenshot_in_notebook(Glib::IO::File::new_for_path($screenshot_thumbnail_name), $screenshot_thumbnail)
						if $thumbnail_active->get_active;

					$session_screens{$new_key_screenshot}->{'image'}->set_fitting(TRUE);
				}
			}

			#in some cases it is not possible to add it to the session
			#e.g. when saving to pdf
			if ($new_key_screenshot) {

				#copy to clipboard
				if (!$no_autocopy_active->get_active()) {

					#image_autocopy to clipboard if configured
					if ($image_autocopy_active->get_active()) {
						$clipboard->set_image($screenshot);
					}

					#filename autocopy to clipboard if configured
					if ($fname_autocopy_active->get_active()) {
						$clipboard->set_text($screenshot_name);
					}

				}

				#open screenshot with configured program
				if ($progname_active->get_active) {
					my $model         = $progname->get_model();
					my $progname_iter = $progname->get_active_iter();
					if ($progname_iter) {
						my $progname_value = $model->get_value($progname_iter, 2);
						my $appname_value  = $model->get_value($progname_iter, 1);
						fct_open_with_program($progname_value, $appname_value);
					}
				}
				print "screenshot successfully saved to $screenshot_name!\n"
					if $sc->get_debug;

				fct_show_status_message(1, sprintf($d->get("%s saved"), $session_screens{$new_key_screenshot}->{'short'}));

				#show pop-up notification
				if ($notify_after_active->get_active) {
					my $notify = $sc->get_notification_object;
					if (defined $session_screens{$new_key_screenshot}->{'is_unsaved'}
						&& $session_screens{$new_key_screenshot}->{'is_unsaved'})
					{
						$notify->show($d->get("Screenshot saved"), "*" . $session_screens{$new_key_screenshot}->{'name'});
					} else {
						$notify->show($d->get("Screenshot saved"), $session_screens{$new_key_screenshot}->{'long'});
					}
				}

			} else {    #endif - adding to session worked

				print "screenshot successfully saved to $screenshot_name, but unable to add the file to session!\n"
					if $sc->get_debug;

				fct_show_status_message(1, sprintf($d->get("%s saved"), $screenshot_name));

				#show pop-up notification
				if ($notify_after_active->get_active) {
					my $notify = $sc->get_notification_object;
					$notify->show($d->get("Screenshot saved"), $screenshot_name);
				}

			}

		} else {

			#show error dialog
			my $response = $sd->dlg_error_message(sprintf($d->get("The filename %s could not be verified. Maybe it contains unsupported characters."), "'" . $screenshot_name . "'"),
				$d->get("Error while taking the screenshot."));
			fct_show_status_message(1, $d->get("Error while taking the screenshot."));
			fct_control_main_window('show');
			return FALSE;

		}

		# --- After Capture Pipeline (TODO-ShareX.md #1 & #2) ---
		# Run any configured pipeline steps after the screenshot is fully saved.
		if ($acp && $acp->get_steps) {
			my $upload_link_container = \ '';
			$acp->execute({
				filename    => $screenshot_name,
				pixbuf      => $screenshot,
				clipboard   => $clipboard,
				upload_link => \$upload_link_container,
				editor_cb   => sub {
					my ($fn) = @_;
					if ($progname_active->get_active) {
						my $model         = $progname->get_model();
						my $progname_iter = $progname->get_active_iter();
						if ($progname_iter) {
							my $progname_value = $model->get_value($progname_iter, 2);
							my $appname_value  = $model->get_value($progname_iter, 1);
							fct_open_with_program($progname_value, $appname_value);
						}
					}
				},
				upload_cb   => sub {
					my ($fn, $sxcu_path) = @_;
					# Trigger the upload dialog for the given file
					dlg_upload($new_key_screenshot) if $new_key_screenshot;
				},
				pin_cb      => sub {
					my ($pbuf) = @_;
					$pins->pin($pbuf, $sc) if $pins;
				},
			});
		}

		fct_control_main_window('show', $present_after_active->get_active);

		#Exit Shutter after the first capture has been made.
		#This is useful when using Shutter in scripts.
		if ($sc->get_exit_after_capture) {
			evt_delete_window('', 'quit');
		}

		return TRUE;
	}


1;
