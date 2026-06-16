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

package Shutter::App::Handlers::Init_Handlers;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_check_valid_mime_type {
		my $mime_type = shift;

		foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
			foreach my $mtype (@{$format->get_mime_types}) {
				return TRUE if $mtype eq $mime_type;
				last;
			}
		}

		return FALSE;
	}

	sub fct_drop_handler {
		my ($widget, $context, $x, $y, $selection, $info, $time) = @_;
		my $type = $selection->get_target->name;
		return unless $type eq 'text/uri-list';
		my $data = $selection->get_data;
		$data = join('', map { chr } @$data);

		my @files = grep defined($_), split /[\r\n]+/, $data;

		my @valid_files;
		my @sxcu_files;
		foreach my $file (@files) {
			my $giofile = Glib::IO::File::new_for_uri($file);
			my $path = $giofile->get_path;
			if ($path && $path =~ /\.sxcu$/i) {
				push @sxcu_files, $path;
			} else {
				my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $path);
				$mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;    #FIXME
				if ($mime_type && fct_check_valid_mime_type($mime_type)) {
					push @valid_files, $file;
				}
			}
		}

		if (@sxcu_files) {
			my $uploaders_dir = $ENV{'HOME'} . '/.shutter/uploaders';
			mkdir $uploaders_dir unless -d $uploaders_dir;
			use File::Copy;
			my $imported = 0;
			foreach my $sxcu (@sxcu_files) {
				use File::Basename;
				my $name = basename($sxcu);
				if (copy($sxcu, "$uploaders_dir/$name")) {
					$imported++;
				}
			}
			fct_show_status_message(3, sprintf($d->nget("Imported %d ShareX custom uploader", "Imported %d ShareX custom uploaders", $imported), $imported));
			
			# Re-init upload plugins to load the new ones!
			fct_init_upload_plugins();
		}

		#open all valid files
		if (@valid_files) {
			fct_open_files(@valid_files);
			Gtk3::drag_finish($context, 1, 0, $time);
			return TRUE;
		} else {
			Gtk3::drag_finish($context, 0, 0, $time);
			return FALSE;
		}
	}

	sub fct_is_uri_in_session {
		my $giofile = shift;
		my $jump    = shift;

		return FALSE unless $giofile;

		foreach my $key (keys %session_screens) {
			if (exists $session_screens{$key}->{'giofile'}) {
				if ($giofile->equal($session_screens{$key}->{'giofile'})) {
					if (exists $session_screens{$key}->{'tab_child'}) {
						if ($jump) {
							$notebook->set_current_page($notebook->page_num($session_screens{$key}->{'tab_child'}));
						}
						return TRUE;
					}
				}
			}
		}

		return FALSE;
	}

	sub fct_load_session {

		#session file
		my $sessionfile = "$ENV{ HOME }/.shutter/session.xml";

		eval {
			my $session_xml = XMLin(IO::File->new($sessionfile))
				if $shf->file_exists($sessionfile);

			return FALSE if scalar(keys %{$session_xml}) < 1;

			#activate throbber
			my ($throbber, $sep) = fct_toggle_status_throbber($status);

			#how many files have to be loaded
			#store this value in the session hash
			$session_start_screen{'first_page'}->{'num_session_files'} = scalar(keys %{$session_xml});

			#local counter
			#is passed to several subroutines to indicate the correct index
			my $count = 0;
			foreach my $key (sort keys %{$session_xml}) {

				#increment counter
				$count++;

				#refresh gui
				fct_update_gui();

				#do the real work
				my $new_giofile = Glib::IO::File::new_for_path(${$session_xml}{$key}{'filename'});
				if (fct_integrate_screenshot_in_notebook($new_giofile, undef, undef, $count)) {
					fct_show_status_message(1, $shf->utf8_decode($new_giofile->get_path) . " " . $d->get("opened"));
				} else {
					fct_show_status_message(1, sprintf($d->get("Error while opening image %s."), "'" . $new_giofile->get_basename . "'"));
				}

			}

			#clear the value after loading the files
			$session_start_screen{'first_page'}->{'num_session_files'} = undef;

			#de-activate the throbber
			fct_toggle_status_throbber($status, $throbber, $sep);

		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Session could not be restored!"));
			unlink $sessionfile;
		}

		return TRUE;
	}

	sub fct_open_files {
		my (@new_files) = @_;

		return FALSE if scalar(@new_files) < 1;

		my ($throbber, $sep) = fct_toggle_status_throbber($status);

		foreach my $file (@new_files) {

			my $new_giofile = Glib::IO::File::new_for_uri($shf->utf8_decode(unescape_string($file)));
			next if fct_is_uri_in_session($new_giofile, TRUE);

			#refresh gui
			fct_update_gui();

			#do the real work
			if (fct_integrate_screenshot_in_notebook($new_giofile)) {
				fct_show_status_message(1, $shf->utf8_decode($new_giofile->get_path) . " " . $d->get("opened"));
			} else {
				fct_show_status_message(1, sprintf($d->get("Error while opening image %s."), "'" . $shf->utf8_decode($new_giofile->get_basename) . "'"));
			}
		}

		fct_toggle_status_throbber($status, $throbber, $sep);

		return TRUE;
	}

	sub fct_toggle_status_throbber {
		my $status   = shift;
		my $throbber = shift;
		my $sep      = shift;
		return FALSE unless $status;

		if (defined $throbber && defined $sep) {
			$throbber->destroy;
			$throbber = undef;
			$sep->destroy;
			$sep = undef;
		} else {

			#don't show more than one
			foreach my $child ($status->get_children) {
				if ($child->get_name eq 'throbber') {
					return FALSE;
				}
			}
			$throbber = Gtk3::Image->new_from_file("$shutter_root/share/shutter/resources/icons/throbber_16x16.gif");
			$throbber->set_name('throbber');
			$sep = Gtk3::HSeparator->new;
			$status->pack_start($sep, FALSE, FALSE, 3);
			$status->pack_end($throbber, FALSE, FALSE, 0);
		}

		$status->show_all;

		return ($throbber, $sep);
	}


1;
