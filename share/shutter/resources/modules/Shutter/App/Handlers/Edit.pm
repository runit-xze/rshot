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

package Shutter::App::Handlers::Edit;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_clipboard {
		my ($widget, $mode) = @_;

		my $key = fct_get_current_file();

		#create shutter region object
		my $sr = Shutter::Geometry::Region->new();

		my @clipboard_array;

		#single file
		if ($key) {

			return FALSE unless fct_screenshot_exists($key);
			push(@clipboard_array, $key);

		} else {

			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push(@clipboard_array, $key);
					}
				},
				undef
			);

		}

		my $clipboard_string = undef;
		my $clipboard_region = Cairo::Region->create;
		my @pixbuf_array;
		my @rects_array;
		foreach my $key (@clipboard_array) {

			if ($mode eq 'image') {
				my $pixbuf = $lp->load($session_screens{$key}->{'long'});
				my $rect   = {x=>$sr->get_clipbox($clipboard_region)->{width}, y=>0, width=>$pixbuf->get_width, height=>$pixbuf->get_height};
				$clipboard_region->union_rectangle($rect);
				push @pixbuf_array, $pixbuf;
				push @rects_array,  $rect;
			} else {
				$clipboard_string .= $session_screens{$key}->{'long'} . "\n";
			}

		}

		if ($clipboard_string) {
			chomp $clipboard_string;
			$clipboard->set_text($clipboard_string);
			fct_show_status_message(1, $d->get("Selected filenames copied to clipboard"));
		}

		if ($clipboard_region->num_rectangles) {
			my $clipboard_image = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, $sr->get_clipbox($clipboard_region)->{width}, $sr->get_clipbox($clipboard_region)->{height});
			$clipboard_image->fill(0x00000000);

			#copy images to the blank pixbuf
			my $rect_counter = 0;
			foreach my $pixbuf (@pixbuf_array) {
				$pixbuf->copy_area(0, 0, $pixbuf->get_width, $pixbuf->get_height, $clipboard_image, $rects_array[$rect_counter]->{x}, 0);
				$rect_counter++;
			}

			$clipboard->set_image($clipboard_image);
			fct_show_status_message(1, $d->get("Selected images copied to clipboard"));
		}

		return TRUE;
	}

	sub fct_clipboard_import {

		my $image = $clipboard->wait_for_image;
		if (defined $image) {

			#folder to save
			my $folder = Glib::filename_to_unicode($saveDir_button->get_filename) ;
			if ($save_no_active->get_active) {
				$folder = Shutter::App::Directories::get_cache_dir();
			}
			
			#determine current file type (name - description)
			$combobox_type->get_active_text =~ /(.*) -/;
			my $filetype_value = $1;
			unless ($filetype_value) {
				$sd->dlg_error_message($d->get("No valid filetype specified"), $d->get("Failed"));
				fct_control_main_window('show');
				return FALSE;
			}
			
			#generate random filename
			my $short = "clipboard-import-" . int(rand(10000000000));

			#relative to abs
			my $tmpfilename = $folder ."/" . $short ."." . $filetype_value;
			unless (File::Spec->file_name_is_absolute($tmpfilename)) {
				$tmpfilename = File::Spec->rel2abs($tmpfilename);
			}
			
			#save pixbuf to tempfile and integrate it
			if ($sp->save_pixbuf_to_file($image, $tmpfilename, $filetype_value)) {
				my $new_key = fct_integrate_screenshot_in_notebook(Glib::IO::File::new_for_path($tmpfilename), $image);
				$session_screens{$new_key}->{'image'}->set_fitting(TRUE);
			}

		} else {
			fct_show_status_message(1, $d->get("There is no image data in the clipboard to paste"));
		}

		return TRUE;
	}

	sub fct_delete {
		my $key    = shift;
		my $action = shift;

		#close current tab (unless $key is provided or close_all)
		unless (defined $action && $action eq 'menu_close_all') {
			$key = fct_get_current_file() unless $key;
		}

		#single file
		if ($key) {

			if ($ask_on_delete_active->get_active) {
				my $response = $sd->dlg_question_message(
					"", sprintf($d->get("Are you sure you want to move %s to the trash?"), "'" . $session_screens{$key}->{'long'} . "'"),
					'gtk-cancel', $d->get("Move to _Trash"),
				);
				return FALSE unless $response == 20;
			}

			if ($session_screens{$key}->{'giofile'}->query_exists) {
				fct_trash($key);
				eval {

					#remove from recentmanager
					Gtk3::RecentManager::get_default->remove_item($session_screens{$key}->{'giofile'}->get_path);
				};
			}

			$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));    #delete tab
			fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("deleted"))
				if defined($session_screens{$key}->{'long'});

			if (defined $session_screens{$key}->{'iter'}
				&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
			{
				$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
			}

			#unlink undo and redo files
			fct_unlink_tempfiles($key);

			delete $session_screens{$key};

			$window->show_all unless $is_hidden;

			#session tab
		} else {

			if ($ask_on_delete_active->get_active) {

				#any files selected?
				my $selected = FALSE;
				$session_start_screen{'first_page'}->{'view'}->selected_foreach(
					sub {
						my ($view, $path) = @_;
						my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
						if (defined $iter) {
							$selected = TRUE;
						}
					});

				if ($selected) {
					my $response = $sd->dlg_question_message("", $d->get("Are you sure you want to move the selected files to the trash?"), 'gtk-cancel', $d->get("Move to _Trash"),);
					return FALSE unless $response == 20;
				} else {
					fct_show_status_message(1, $d->get("No screenshots selected"));
					return FALSE;
				}
			}

			my @to_delete;
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));

						if ($session_screens{$key}->{'giofile'}->query_exists) {
							fct_trash($key);
							eval {

								#remove from recentmanager
								Gtk3::RecentManager::get_default->remove_item($session_screens{$key}->{'giofile'}->get_path);
							};
						}

						#copy to array
						#we delete the files from hash and model
						#when exiting the sub
						push @to_delete, $key;

					}
				},
				undef
			);

			if (scalar @to_delete == 0) {
				fct_show_status_message(1, $d->get("No screenshots selected"));
				return FALSE;
			}

			#delete from hash and model
			foreach my $key (@to_delete) {
				if (defined $session_screens{$key}->{'iter'}
					&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
				{
					$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
				}

				#unlink undo and redo files
				fct_unlink_tempfiles($key);

				delete $session_screens{$key};
			}

			fct_show_status_message(1, $d->get("Selected screenshots deleted"));

			$window->show_all unless $is_hidden;

		}

		fct_update_info_and_tray();

		return TRUE;
	}

	sub fct_draw {

		my $key = fct_get_current_file();

		my @draw_array;

		#single file
		if ($key) {

			return FALSE unless fct_screenshot_exists($key);
			push(@draw_array, $key);

		} else {
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push(@draw_array, $key);
					}
				},
				undef
			);
		}

		#open drawing tool

		my $drawing_tool_icons;

		if ($drawing_tool_light_icons_active->get_active()) {
				$drawing_tool_icons = "light";
		} elsif ($drawing_tool_dark_icons_active->get_active()) {
				$drawing_tool_icons = "dark";
		} elsif ($drawing_tool_auto_icons_active->get_active()) {
				$drawing_tool_icons = "auto";
		}


		foreach my $key (@draw_array) {
			my $drawing_tool = Shutter::Draw::DrawingTool->new($sc);
			$drawing_tool->show(
				$session_screens{$key}->{'long'}, $session_screens{$key}->{'filetype'},   $session_screens{$key}->{'mime_type'},
				$session_screens{$key}->{'name'}, $session_screens{$key}->{'is_unsaved'}, \%session_screens,
				$drawing_tool_icons
			);
		}

		#~ &fct_control_main_window ('show');

		return TRUE;
	}

	sub fct_fullscreen {
		my ($widget) = @_;

		if ($widget->get_active) {
			$window->fullscreen;
		} else {
			$window->unfullscreen;
		}
	}

	sub fct_plugin {

		my $key = fct_get_current_file();

		my @plugin_array;

		#single file
		if ($key) {

			return FALSE unless fct_screenshot_exists($key);

			unless (keys %plugins > 0) {
				$sd->dlg_error_message($d->get("No plugin installed"), $d->get("Failed"));
			} else {
				push(@plugin_array, $key);
				dlg_plugin(@plugin_array);
			}

			#session tab
		} else {

			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push(@plugin_array, $key);
					}

				},
				undef
			);
			dlg_plugin(@plugin_array);
		}
		return TRUE;
	}

	sub fct_plugin_get_info {
		my ($plugin, $info) = @_;

		my $plugin_info = `$plugin $info`;
		utf8::decode $plugin_info;

		return $plugin_info;
	}

	sub fct_redo {

		my $key = fct_get_current_file();

		#single file
		if ($key) {

			return FALSE unless fct_screenshot_exists($key);

			#and revert last version
			my $last_version = pop @{$session_screens{$key}->{'redo'}};

			#~ push @{$session_screens{$key}->{'undo'}}, $last_version;

			if ($last_version) {

				#cancel handle
				if (exists $session_screens{$key}->{'handle'}) {
					$session_screens{$key}->{'handle'}->cancel;
				}

				if (cp($last_version, $session_screens{$key}->{'long'})) {

					fct_update_tab($key, undef, $session_screens{$key}->{'giofile'}, TRUE, 'gui');

					fct_show_status_message(1, $d->get("Last action redone"));

					#delete last_version from filesystem
					unlink $last_version;

				} else {

					my $response = $sd->dlg_error_message(
						sprintf($d->get("Error while copying last version (%s)."),    "'" . $last_version . "'"),
						sprintf($d->get("There was an error performing redo on %s."), "'" . $session_screens{$key}->{'long'} . "'"),
						undef, undef, undef, undef, undef, undef, $@
					);

					fct_update_tab($key, undef, $session_screens{$key}->{'giofile'}, TRUE, 'clear');

				}

				#setup a new filemonitor, so we get noticed if the file changed
				fct_add_file_monitor($key);

			}

		}
		return TRUE;
	}

	sub fct_select_all {

		$session_start_screen{'first_page'}->{'view'}->select_all;

		return TRUE;
	}

	sub fct_trash {
		my $key = shift;

		#cancel handle
		if (exists $session_screens{$key}->{'handle'}) {
			$session_screens{$key}->{'handle'}->cancel;
		}

		$session_screens{$key}->{'giofile'}->trash;
	}

	sub fct_undo {

		my $key = fct_get_current_file();

		#single file
		if ($key) {

			return FALSE unless fct_screenshot_exists($key);

			#push current version to redo
			#(current version is always the last element in the array)
			my $current_version = pop @{$session_screens{$key}->{'undo'}};
			push @{$session_screens{$key}->{'redo'}}, $current_version;

			#and revert last version
			my $last_version = pop @{$session_screens{$key}->{'undo'}};
			if ($last_version) {

				#cancel handle
				if (exists $session_screens{$key}->{'handle'}) {
					$session_screens{$key}->{'handle'}->cancel;
				}

				if (cp($last_version, $session_screens{$key}->{'long'})) {

					fct_update_tab($key, undef, $session_screens{$key}->{'giofile'}, TRUE, 'gui');

					fct_show_status_message(1, $d->get("Last action undone"));

					#delete last_version from filesystem
					unlink $last_version;

				} else {

					my $response = $sd->dlg_error_message(
						sprintf($d->get("Error while copying last version (%s)."),    "'" . $last_version . "'"),
						sprintf($d->get("There was an error performing undo on %s."), "'" . $session_screens{$key}->{'long'} . "'"),
						undef, undef, undef, undef, undef, undef, $@
					);

					fct_update_tab($key, undef, $session_screens{$key}->{'giofile'}, TRUE, 'clear');

				}

				#setup a new filemonitor, so we get noticed if the file changed
				fct_add_file_monitor($key);

			}

		}
		return TRUE;
	}

	sub fct_zoom_100 {
		my $key = fct_get_current_file();
		if ($key) {
			$session_screens{$key}->{'image'}->set_zoom(1);
		}
	}

	sub fct_zoom_best {
		my $key = fct_get_current_file();
		if ($key) {
			$session_screens{$key}->{'image'}->set_fitting(TRUE);
		}
	}

	sub fct_zoom_in {
		my $key = fct_get_current_file();
		if ($key) {
			$session_screens{$key}->{'image'}->zoom_in;
		}
	}

	sub fct_zoom_out {
		my $key = fct_get_current_file();
		if ($key) {
			$session_screens{$key}->{'image'}->zoom_out;
		}
	}


1;
