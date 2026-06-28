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

package Shutter::App::Handlers::Edit_Nav;

use utf8;
use v5.40;
use Shutter::App::Core::ClipboardAPI;
use Shutter::App::Core::FileSystemAPI;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib       qw/TRUE FALSE/;
use File::Copy qw(cp);
use File::Spec;
use Shutter::Geometry::Region;
use Shutter::App::Directories;

has cli => (is => 'ro', required => 1);

sub fct_clipboard ($self, $widget = undef, $mode = 'image') {
	my $cli                  = $self->cli;
	my $h                    = $cli->handlers;
	my $d                    = $cli->sc->gettext_object;
	require Shutter::App::Core::ClipboardAPI;
	my $clipboard            = $cli->{_clipboard} || Shutter::App::Core::ClipboardAPI->new;
	my $session_start_screen = $cli->{_session_start_screen};
	my $session_screens      = $cli->{_session_screens};
	my $lp                   = $cli->{_lp};                                                                               # LoadPixbuf module

	my $key = $h->get('Menu_Ret_Get')->fct_get_current_file();

	#create shutter region object
	my $sr = Shutter::Geometry::Region->new();

	my @clipboard_array;

	#single file
	if ($key) {
		return FALSE unless $h->get('UI_Status')->fct_screenshot_exists($key);
		push(@clipboard_array, $key);
	} else {
		if ($session_start_screen && $session_start_screen->{'first_page'} && $session_start_screen->{'first_page'}->{'view'}) {
			$session_start_screen->{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
						push(@clipboard_array, $key);
					}
				},
				undef
			);
		}
	}

	my $clipboard_string = undef;
	my $clipboard_region = Cairo::Region->create;
	my @pixbuf_array;
	my @rects_array;

	foreach my $k (@clipboard_array) {
		if ($mode eq 'image') {
			if ($lp && $session_screens->{$k} && $session_screens->{$k}->{'long'}) {
				my $pixbuf = $lp->load($session_screens->{$k}->{'long'});
				if ($pixbuf) {
					my $rect = {x => $sr->get_clipbox($clipboard_region)->{width}, y => 0, width => $pixbuf->get_width, height => $pixbuf->get_height};
					$clipboard_region->union_rectangle($rect);
					push @pixbuf_array, $pixbuf;
					push @rects_array,  $rect;
				}
			}
		} else {
			if ($session_screens->{$k} && $session_screens->{$k}->{'long'}) {
				$clipboard_string .= $session_screens->{$k}->{'long'} . "\n";
			}
		}
	}

	if ($clipboard_string) {
		chomp $clipboard_string;
		$clipboard->set_text($clipboard_string);
		$h->get('UI_Status')->fct_show_status_message(1, $d->get("Selected filenames copied to clipboard"));
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
		$h->get('UI_Status')->fct_show_status_message(1, $d->get("Selected images copied to clipboard"));
	}

	return TRUE;
}

sub fct_clipboard_import ($self) {
	my $cli             = $self->cli;
	my $h               = $cli->handlers;
	my $d               = $cli->sc->gettext_object;
	require Shutter::App::Core::ClipboardAPI;
	my $clipboard       = $cli->{_clipboard} || Shutter::App::Core::ClipboardAPI->new;
	my $saveDir_button  = $cli->{_saveDir_button};
	my $save_no_active  = $cli->{_save_no_active};
	my $combobox_type   = $cli->{_combobox_type};
	my $sd              = $cli->sc->{_sd};
	my $sp              = $cli->{_sp};                                                                               # SavePixbuf module
	my $session_screens = $cli->{_session_screens};

	my $image = $clipboard->wait_for_image;
	if (defined $image) {

		#folder to save
		my $folder = $saveDir_button ? Glib::filename_to_unicode($saveDir_button->get_filename) : Shutter::App::Directories::get_cache_dir();
		if ($save_no_active && $save_no_active->get_active) {
			$folder = Shutter::App::Directories::get_cache_dir();
		}

		#determine current file type (name - description)
		my $filetype_value;
		if ($combobox_type && $combobox_type->get_active_text) {
			$combobox_type->get_active_text =~ /(.*) -/;
			$filetype_value = $1;
		} else {
			$filetype_value = 'png';    # Fallback
		}

		unless ($filetype_value) {
			$sd->dlg_error_message($d->get("No valid filetype specified"), $d->get("Failed"));
			$h->get('Core')->fct_control_main_window('show');
			return FALSE;
		}

		#generate random filename
		my $short = "clipboard-import-" . int(rand(10000000000));

		#relative to abs
		my $tmpfilename = $folder . "/" . $short . "." . $filetype_value;
		unless (File::Spec->file_name_is_absolute($tmpfilename)) {
			$tmpfilename = File::Spec->rel2abs($tmpfilename);
		}

		#save pixbuf to tempfile and integrate it
		if ($sp && $sp->save_pixbuf_to_file($image, $tmpfilename, $filetype_value)) {
			my $new_key = $h->get('Workflow_Integrate')->fct_integrate_screenshot_in_notebook(Glib::IO::File::new_for_path($tmpfilename), $image);
			if ($new_key && $session_screens->{$new_key} && $session_screens->{$new_key}->{'image'}) {
				$session_screens->{$new_key}->{'image'}->set_fitting(TRUE);
			}
		}

	} else {
		$h->get('UI_Status')->fct_show_status_message(1, $d->get("There is no image data in the clipboard to paste"));
	}

	return TRUE;
}

sub fct_fullscreen ($self, $widget = undef) {
	my $window = $self->cli->window;

	if ($window) {
		if ($widget && $widget->get_active) {
			$window->fullscreen;
		} else {
			$window->unfullscreen;
		}
	}
	return;
}

sub fct_redo ($self) {
	my $cli             = $self->cli;
	my $h               = $cli->handlers;
	my $d               = $cli->sc->gettext_object;
	my $sd              = $cli->sc->{_sd};
	my $session_screens = $cli->{_session_screens};

	my $key = $h->get('Menu_Ret_Get')->fct_get_current_file();

	#single file
	if ($key) {
		return FALSE unless $h->get('UI_Status')->fct_screenshot_exists($key);

		#and revert last version
		my $last_version = pop @{$session_screens->{$key}->{'redo'}};

		if ($last_version) {

			#cancel handle
			if (exists $session_screens->{$key}->{'handle'}) {
				$session_screens->{$key}->{'handle'}->cancel;
			}

			if (cp($last_version, $session_screens->{$key}->{'long'})) {
				$h->get('UI_Status')->fct_update_tab($key, undef, $session_screens->{$key}->{'giofile'}, TRUE, 'gui');
				$h->get('UI_Status')->fct_show_status_message(1, $d->get("Last action redone"));

				#delete last_version from filesystem
				Shutter::App::Core::FileSystemAPI->new->remove($last_version);
			} else {
				my $response = $sd->dlg_error_message(
					sprintf($d->get("Error while copying last version (%s)."),    "'" . $last_version . "'"),
					sprintf($d->get("There was an error performing redo on %s."), "'" . $session_screens->{$key}->{'long'} . "'"),
					undef, undef, undef, undef, undef, undef, $@
				);
				$h->get('UI_Status')->fct_update_tab($key, undef, $session_screens->{$key}->{'giofile'}, TRUE, 'clear');
			}

			#setup a new filemonitor, so we get noticed if the file changed
			$h->get('Events_Init')->fct_add_file_monitor($key);
		}
	}
	return TRUE;
}

sub fct_undo ($self) {
	my $cli             = $self->cli;
	my $h               = $cli->handlers;
	my $d               = $cli->sc->gettext_object;
	my $sd              = $cli->sc->{_sd};
	my $session_screens = $cli->{_session_screens};

	my $key = $h->get('Menu_Ret_Get')->fct_get_current_file();

	#single file
	if ($key) {
		return FALSE unless $h->get('UI_Status')->fct_screenshot_exists($key);

		#push current version to redo
		#(current version is always the last element in the array)
		my $current_version = pop @{$session_screens->{$key}->{'undo'}};
		push @{$session_screens->{$key}->{'redo'}}, $current_version;

		#and revert last version
		my $last_version = pop @{$session_screens->{$key}->{'undo'}};
		if ($last_version) {

			#cancel handle
			if (exists $session_screens->{$key}->{'handle'}) {
				$session_screens->{$key}->{'handle'}->cancel;
			}

			if (cp($last_version, $session_screens->{$key}->{'long'})) {
				$h->get('UI_Status')->fct_update_tab($key, undef, $session_screens->{$key}->{'giofile'}, TRUE, 'gui');
				$h->get('UI_Status')->fct_show_status_message(1, $d->get("Last action undone"));

				#delete last_version from filesystem
				Shutter::App::Core::FileSystemAPI->new->remove($last_version);
			} else {
				my $response = $sd->dlg_error_message(
					sprintf($d->get("Error while copying last version (%s)."),    "'" . $last_version . "'"),
					sprintf($d->get("There was an error performing undo on %s."), "'" . $session_screens->{$key}->{'long'} . "'"),
					undef, undef, undef, undef, undef, undef, $@
				);
				$h->get('UI_Status')->fct_update_tab($key, undef, $session_screens->{$key}->{'giofile'}, TRUE, 'clear');
			}

			#setup a new filemonitor, so we get noticed if the file changed
			$h->get('Events_Init')->fct_add_file_monitor($key);
		}
	}
	return TRUE;
}

sub fct_zoom_100 ($self) {
	my $key             = $self->$self->cli->handlers->get('Menu_Ret_Get')->fct_get_current_file();
	my $session_screens = $self->cli->{_session_screens};
	if ($key && $session_screens->{$key} && $session_screens->{$key}->{'image'}) {
		$session_screens->{$key}->{'image'}->set_zoom(1);
	}
	return;
}

sub fct_zoom_best ($self) {
	my $key             = $self->$self->cli->handlers->get('Menu_Ret_Get')->fct_get_current_file();
	my $session_screens = $self->cli->{_session_screens};
	if ($key && $session_screens->{$key} && $session_screens->{$key}->{'image'}) {
		$session_screens->{$key}->{'image'}->set_fitting(TRUE);
	}
	return;
}

sub fct_zoom_in ($self) {
	my $key             = $self->$self->cli->handlers->get('Menu_Ret_Get')->fct_get_current_file();
	my $session_screens = $self->cli->{_session_screens};
	if ($key && $session_screens->{$key} && $session_screens->{$key}->{'image'}) {
		$session_screens->{$key}->{'image'}->zoom_in;
	}
	return;
}

sub fct_zoom_out ($self) {
	my $key             = $self->$self->cli->handlers->get('Menu_Ret_Get')->fct_get_current_file();
	my $session_screens = $self->cli->{_session_screens};
	if ($key && $session_screens->{$key} && $session_screens->{$key}->{'image'}) {
		$session_screens->{$key}->{'image'}->zoom_out;
	}
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Edit_Nav – Edit navigation handlers (Zoom, Undo, Clipboard)

=head1 DESCRIPTION

This module handles navigation and editing actions such as zoom, undo/redo, and clipboard operations for screenshots in Shutter.
It has been migrated to use the CLI object for state access instead of package globals.

=head1 METHODS

=head2 fct_clipboard

Copies selected screenshots (or their images) to the clipboard.

=head2 fct_clipboard_import

Imports an image from the clipboard into the session.

=head2 fct_fullscreen

Toggles fullscreen mode for the main window.

=head2 fct_redo

Redoes the last undone action for the current screenshot.

=head2 fct_undo

Undoes the last action for the current screenshot.

=head2 fct_zoom_100

Zooms the current screenshot to 100%.

=head2 fct_zoom_best

Zooms the current screenshot to fit the view.

=head2 fct_zoom_in

Zooms in on the current screenshot.

=head2 fct_zoom_out

Zooms out on the current screenshot.

=cut
