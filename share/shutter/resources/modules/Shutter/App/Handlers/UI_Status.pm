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

package Shutter::App::Handlers::UI_Status;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_screenshot_exists {
		my ($key) = @_;

		#check if file still exists
		unless ($session_screens{$key}->{'giofile'}->query_exists) {
			fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("not found"));
			return FALSE;
		}
		return TRUE;
	}

	sub fct_update_gui {

		while (Gtk3::events_pending()) {
			Gtk3::main_iteration();
		}
		Gtk3::Gdk::flush();

		return TRUE;
	}

	sub fct_update_tab {

		#mandatory
		my $key = shift;
		return FALSE unless $key;

		#optional, e.g.used by fct_integrate...
		my $pixbuf        = shift;
		my $giofile       = shift;
		my $force_thumb   = shift;
		my $xdo           = shift;
		my $no_image_load = shift;

		$session_screens{$key}->{'giofile'} = $giofile if $giofile;
		$session_screens{$key}->{'mtime'}   = -1
			unless $session_screens{$key}->{'mtime'};

		#something wrong here
		unless (defined $session_screens{$key}->{'giofile'}) {
			return FALSE;
		}

		#sometimes there are some read errors
		#because the CHANGED signal gets emitted by the file monitor
		#but the file is still in use (e.g. plugin, external app)
		#we try to read the fileinfos and the file itsels several times
		#until throwing an error
		my $error_counter = 0;
		while ($error_counter <= MAX_ERROR) {

			my $filestat = stat($session_screens{$key}->{'giofile'}->get_path);

			#does the file exist?
			if ($session_screens{$key}->{'giofile'}->query_exists) {

				#maybe we need no update
				if ($filestat->mtime == $session_screens{$key}->{'mtime'}
					&& !$giofile)
				{
					print "Updating fileinfos REJECTED for key: $key (not modified)\n"
						if $sc->get_debug;
					return TRUE;
				}

				print "Updating fileinfos for key: $key\n" if $sc->get_debug;

				#FILEINFO
				#--------------------------------------
				$session_screens{$key}->{'mtime'} = $filestat->mtime;
				$session_screens{$key}->{'size'}  = $filestat->size;

				$session_screens{$key}->{'short'}    = $shf->utf8_decode(unescape_string($session_screens{$key}->{'giofile'}->get_basename));
				$session_screens{$key}->{'long'}     = $shf->utf8_decode(unescape_string($session_screens{$key}->{'giofile'}->get_path));
				$session_screens{$key}->{'folder'}   = $shf->utf8_decode(unescape_string($session_screens{$key}->{'giofile'}->get_parent->get_path));
				$session_screens{$key}->{'filetype'} = $session_screens{$key}->{'short'};
				$session_screens{$key}->{'filetype'} =~ s/.*\.//ig;

				#just the name
				$session_screens{$key}->{'name'} = $session_screens{$key}->{'short'};
				$session_screens{$key}->{'name'} =~ s/\.$session_screens{$key}->{'filetype'}//g;

				#mime type
				my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $session_screens{$key}->{'giofile'}->get_path);
				$mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;    #FIXME
				$session_screens{$key}->{'mime_type'} = $mime_type;

				#TAB PREVIEW IMAGE
				#--------------------------------------
				#maybe we have a pixbuf already (e.g. after taking a screenshot)

				unless ($pixbuf) {
					unless ($no_image_load) {
						$pixbuf = $lp_ne->load($session_screens{$key}->{'long'}, undef, undef, undef, TRUE);

						unless ($pixbuf) {

							#increment error counter
							#and go to next try
							$error_counter++;
							sleep 1;

							#we need to reset the modification time
							#because the change would not be
							#recognized otherwise
							$session_screens{$key}->{'mtime'} = -1;
							next;
						}
					}
				}

				my $im_format = undef;
				my $im_width = undef;
				my $im_height = undef;

				if (defined $pixbuf) {
					#setting pixbuf
					$session_screens{$key}->{'image'}->set_pixbuf($pixbuf);

					$im_width = $pixbuf->get_width;
					$im_height = $pixbuf->get_height;

				} else {
					#If image pixbuf was not loaded, get image info without loading it into the memory
					($im_format, $im_width, $im_height) = Gtk3::Gdk::Pixbuf::get_file_info($session_screens{$key}->{'long'});

					unless ($im_format) {
						#increment error counter
						#and go to next try
						$error_counter++;
						sleep 1;

						#we need to reset the modification time
						#because the change would not be
						#recognized otherwise
						$session_screens{$key}->{'mtime'} = -1;
						next;
					}
				}

				#UPDATE INFOS
				#--------------------------------------

				#get dimensions - using the pixbuf
				$session_screens{$key}->{'width'}  = $im_width;
				$session_screens{$key}->{'height'} = $im_height;


				#generate thumbnail if file is not too large
				#set flag
				if (   $session_screens{$key}->{'width'} <= 10000
					&& $session_screens{$key}->{'height'} <= 10000)
				{
					$session_screens{$key}->{'no_thumbnail'} = FALSE;
				} else {
					$session_screens{$key}->{'no_thumbnail'} = TRUE;
				}

				#update is_unsaved flag
				if ($session_screens{$key}->{'folder'} eq Shutter::App::Directories::get_cache_dir()) {
					$session_screens{$key}->{'is_unsaved'} = TRUE;
				} else {
					$session_screens{$key}->{'is_unsaved'} = FALSE;
				}

				#update tab label
				#and tooltip
				if (defined $session_screens{$key}->{'is_unsaved'}
					&& $session_screens{$key}->{'is_unsaved'})
				{
					$session_screens{$key}->{'hbox_tab_label'}->set_tooltip_text("*" . $session_screens{$key}->{'name'});
					$session_screens{$key}->{'tab_label'}->set_text("[" . $session_screens{$key}->{'tab_indx'} . "] - " . "*" . $session_screens{$key}->{'name'});
				} else {
					$session_screens{$key}->{'hbox_tab_label'}->set_tooltip_text($session_screens{$key}->{'long'});
					$session_screens{$key}->{'tab_label'}->set_text("[" . $session_screens{$key}->{'tab_indx'} . "] - " . $session_screens{$key}->{'short'});
				}

				#create tempfile
				#maybe we have to restore the file later
				my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);

				#UNDO / REDO
				#--------------------------------------

				#blocked (e.g. renaming)
				if (defined $xdo && $xdo eq 'block') {

					unlink $tmpfilename;

					#clear (e.g. save_as)
				} elsif (defined $xdo && $xdo eq 'clear') {

					while (defined $session_screens{$key}->{'undo'}
						&& scalar @{$session_screens{$key}->{'undo'}} > 0)
					{
						unlink shift @{$session_screens{$key}->{'undo'}};
					}
					while (defined $session_screens{$key}->{'redo'}
						&& scalar @{$session_screens{$key}->{'redo'}} > 0)
					{
						unlink shift @{$session_screens{$key}->{'redo'}};
					}

					push @{$session_screens{$key}->{'undo'}}, $tmpfilename;
					cp($session_screens{$key}->{'long'}, $tmpfilename);

					#push to undo
				} else {

					#clear redo unless triggered from gui (undo/redo buttons)
					if (!defined $xdo) {
						while (defined $session_screens{$key}->{'redo'}
							&& scalar @{$session_screens{$key}->{'redo'}} > 0)
						{
							unlink shift @{$session_screens{$key}->{'redo'}};
						}
					}

					push @{$session_screens{$key}->{'undo'}}, $tmpfilename;
					cp($session_screens{$key}->{'long'}, $tmpfilename);

				}

				#thumbnail in tab
				my $thumb;
				unless ($session_screens{$key}->{'no_thumbnail'}) {

					#update tab icon
					$thumb = $lp_ne->load($shf->utf8_decode($session_screens{$key}->{'giofile'}->get_path), $shf->icon_size('small-toolbar'));
					$session_screens{$key}->{'tab_icon'}->set_from_pixbuf($thumb);
				}

				#UPDATE FIRST TAB - VIEW
				#--------------------------------------

				my $thumb_view = undef;
				unless ($session_screens{$key}->{'no_thumbnail'}) {
					my $max_size = 100;

					#update first page tab list view thumb icon
					if ($im_width <= $max_size && $im_height <= $max_size) {
						if (defined $pixbuf) {
							$thumb_view = $pixbuf;
						} else {
							#If the full image is smaller than max_size in all
							#the dimensions, no need to resize it.
							$thumb_view = $lp_ne->load($shf->utf8_decode($session_screens{$key}->{'giofile'}->get_path));
						}
					} else {
						$thumb_view = $lp_ne->load($shf->utf8_decode($session_screens{$key}->{'giofile'}->get_path), $max_size, $max_size);
					}

					#update dnd pixbuf
					$session_screens{$key}->{'image'}->{thumb} = $thumb_view;
				} else {
					$thumb_view = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, 5, 5);
					$thumb_view->fill(0x00000000);
				}

				#create new iter if needed...
				unless (defined $session_screens{$key}->{'iter'}
					&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
				{
					$session_screens{$key}->{'iter'} = $session_start_screen{'first_page'}->{'model'}->append;
				}

				#...update it
				if (defined $session_screens{$key}->{'is_unsaved'}
					&& $session_screens{$key}->{'is_unsaved'})
				{
					$session_start_screen{'first_page'}->{'model'}->set($session_screens{$key}->{'iter'}, 0, $thumb_view, 1, "*" . $session_screens{$key}->{'name'}, 2, $key);
				} else {
					$session_start_screen{'first_page'}->{'model'}->set($session_screens{$key}->{'iter'}, 0, $thumb_view, 1, $session_screens{$key}->{'short'}, 2, $key);
				}

				#update first tab
				fct_update_info_and_tray();

				#update menu actions
				my $current_key = fct_get_current_file();
				if (defined $current_key && $current_key eq $key) {
					fct_update_actions(1, $key);
				}

				return TRUE;

				#file does not exist
			} else {

				#show dialog
				if ($ask_on_fs_delete_active->get_active) {

					#mark file as deleted
					$session_screens{$key}->{'deleted'} = TRUE;

					#we only handle one case here:
					#file was deleted in filesystem and we got informed about that...
					my $response = $sd->dlg_question_message(
						$d->get("Try to resave the file?"),
						sprintf($d->get("Image %s was not found on disk"), "'" . $session_screens{$key}->{'long'} . "'"),
						'gtk-discard', 'gtk-save'
					);

					#handle different responses
					if ($response == 10 || $response == -1) {

						$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));    #delete tab
						fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("removed from session"))
							if defined($session_screens{$key}->{'long'});

						if (defined $session_screens{$key}->{'iter'}
							&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
						{
							$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
						}

						delete($session_screens{$key});

					} elsif ($response == 20) {

						#try to resave the file
						#(current version is always the last element in the array)
						my $current_version = pop @{$session_screens{$key}->{'undo'}};

						my $pixbuf = $lp_ne->load($current_version);

						#restoring the last version failed => delete the screenshot
						unless ($pixbuf) {

							$sd->dlg_error_message(
								sprintf($d->get("Error while saving the image %s."),           "'" . $session_screens{$key}->{'short'} . "'"),
								sprintf($d->get("There was an error saving the image to %s."), "'" . $session_screens{$key}->{'folder'} . "'"),
								undef, undef, undef, undef, undef, undef, $@
							);

							$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));    #delete tab
							fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("removed from session"))
								if defined($session_screens{$key}->{'long'});

							if (defined $session_screens{$key}->{'iter'}
								&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
							{
								$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
							}

							delete($session_screens{$key});

							fct_update_info_and_tray();
							return FALSE;

						}

						if ($sp->save_pixbuf_to_file($pixbuf, $session_screens{$key}->{'long'}, $session_screens{$key}->{'filetype'})) {

							fct_update_tab($key);

							#setup a new filemonitor, so we get noticed if the file changed
							fct_add_file_monitor($key);

							fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("saved"));

							fct_update_info_and_tray();
							return TRUE;

							#resave failed => delete the screenshot
						} else {

							$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));    #delete tab
							fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("removed from session"))
								if defined($session_screens{$key}->{'long'});

							if (defined $session_screens{$key}->{'iter'}
								&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
							{
								$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
							}

							delete($session_screens{$key});

						}
					}

					#no dialog
				} else {

					#mark file as deleted
					$session_screens{$key}->{'deleted'} = TRUE;

					#try to resave the file
					#(current version is always the last element in the array)
					my $current_version = pop @{$session_screens{$key}->{'undo'}};

					my $pixbuf = $lp_ne->load($current_version);

					#restoring the last version failed => delete the screenshot
					unless ($pixbuf) {

						$sd->dlg_error_message(
							sprintf($d->get("Error while saving the image %s."),           "'" . $session_screens{$key}->{'short'} . "'"),
							sprintf($d->get("There was an error saving the image to %s."), "'" . Shutter::App::Directories::get_cache_dir() . "'"),
							undef, undef, undef, undef, undef, undef, $@
						);

						$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));    #delete tab
						fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("removed from session"))
							if defined($session_screens{$key}->{'long'});

						if (defined $session_screens{$key}->{'iter'}
							&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
						{
							$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
						}

						delete($session_screens{$key});

						fct_update_info_and_tray();
						return FALSE;

					}

					#prepare new filename
					my ($short, $folder, $ext) = fileparse($session_screens{$key}->{'long'}, qr/\.[^.]*/);
					my $new_giofile  = fct_get_next_filename($short, Shutter::App::Directories::get_cache_dir(), $ext);
					my $new_filename = $shf->utf8_decode(unescape_string($new_giofile->get_path));

					if ($sp->save_pixbuf_to_file($pixbuf, $new_filename, $session_screens{$key}->{'filetype'})) {

						if (fct_update_tab($key, undef, Glib::IO::File::new_for_path($new_filename), FALSE, 'clear')) {

							#setup a new filemonitor, so we get noticed if the file changed
							fct_add_file_monitor($key);
						}

						fct_show_status_message(1, sprintf($d->get("Image %s was deleted from filesystem"), $new_filename));

						fct_update_info_and_tray();
						return TRUE;

						#resave failed => delete the screenshot
					} else {

						$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));    #delete tab
						fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("removed from session"))
							if defined($session_screens{$key}->{'long'});

						if (defined $session_screens{$key}->{'iter'}
							&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
						{
							$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
						}

						delete($session_screens{$key});

					}

				}

				fct_update_info_and_tray();
				return FALSE;

			}    #end if exists

		}    #end while($error_counter <= MAX_ERROR){

		#could not load the file => show an error message
		my $response = $sd->dlg_error_message(
			sprintf($d->get("Error while opening image %s."), "'" . $session_screens{$key}->{'long'} . "'"),
			$d->get("There was an error opening the image."),
			undef, undef, undef, undef, undef, undef, $@
		);

		$notebook->remove_page($notebook->page_num($session_screens{$key}->{'tab_child'}));    #delete tab
		fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("removed from session"))
			if defined($session_screens{$key}->{'long'});

		if (defined $session_screens{$key}->{'iter'}
			&& $session_start_screen{'first_page'}->{'model'}->iter_is_valid($session_screens{$key}->{'iter'}))
		{
			$session_start_screen{'first_page'}->{'model'}->remove($session_screens{$key}->{'iter'});
		}

		delete($session_screens{$key});

		fct_update_info_and_tray();
		return FALSE;

	}



1;
