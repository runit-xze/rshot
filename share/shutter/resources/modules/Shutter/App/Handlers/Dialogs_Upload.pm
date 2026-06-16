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

package Shutter::App::Handlers::Dialogs_Upload;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub dlg_profile_name {
		my ($curr_profile_name, $combobox_settings_profiles) = @_;

		my $profile_dialog = Gtk3::MessageDialog->new($window, [qw/modal destroy-with-parent/], 'other', 'none', undef);

		$profile_dialog->set_title("Shutter");

		$profile_dialog->set('image' => Gtk3::Image->new_from_stock('gtk-dialog-question', 'dialog'));

		$profile_dialog->set('text' => $d->get("Save current preferences as new profile"));

		$profile_dialog->set('secondary-text' => $d->get("New profile name") . ": ");

		$profile_dialog->add_button('gtk-cancel', 'reject');
		$profile_dialog->add_button('gtk-save',   'accept');

		$profile_dialog->set_default_response('accept');

		my $new_profile_name_vbox = Gtk3::VBox->new();
		my $new_profile_name_hint = Gtk3::Label->new();
		my $new_profile_name      = Gtk3::Entry->new();
		$new_profile_name->set_activates_default(TRUE);

		fct_validate_filename($new_profile_name, $new_profile_name_hint);

		#show name of current profile
		$new_profile_name->set_text($curr_profile_name)
			if defined $curr_profile_name;

		$new_profile_name_vbox->pack_start($new_profile_name, TRUE, TRUE, 0);
		$new_profile_name_vbox->pack_start($new_profile_name_hint, TRUE, TRUE, 0);
		$profile_dialog->get_child->add($new_profile_name_vbox);
		$profile_dialog->show_all;

		#run dialog
		my $profile_response = $profile_dialog->run;

		#handle user responses here
		if ($profile_response eq 'accept') {
			my $entered_name = $new_profile_name->get_text;

			if ($shf->file_exists("$ENV{'HOME'}/.shutter/profiles/$entered_name.xml")) {

				#ask the user to replace the profile
				#replace button
				my $replace_btn = Gtk3::Button->new_with_mnemonic($d->get("_Replace"));
				$replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

				my $response = $sd->dlg_warning_message(
					$d->get("Replacing it will overwrite its contents."),
					sprintf($d->get("A profile named %s already exists. Do you want to replace it?"), "'" . $entered_name . "'"),
					undef, undef, undef, $replace_btn, undef, undef
				);

				#40 == replace_btn was hit
				if ($response != 40) {
					$profile_dialog->destroy();
					return FALSE;
				}
			}

			$profile_dialog->destroy();
			return $entered_name;
		} else {
			$profile_dialog->destroy();
			return FALSE;
		}
	}

	sub dlg_upload_error_message {
		my ($status, $max_filesize) = @_;

		#dialogs (main window != parent window)
		my $sd = Shutter::App::SimpleDialogs->new;

		my $response;
		if ($status == 999) {
			$response = $sd->dlg_error_message($d->get("Please check your credentials and try again."), $d->get("Error while login"));
		} elsif ($status == 998) {
			$response = $sd->dlg_error_message(
				$d->get("Maximum filesize reached"),
				$d->get("Error while uploading"),
				$d->get("Skip all"), $d->get("Skip"), undef, undef, undef, undef, sprintf($d->get("Maximum filesize: %s"), $max_filesize));
		} else {
			$response = $sd->dlg_error_message($status, $d->get("Error while connecting"), $d->get("Skip all"), $d->get("Skip"), $d->get("Retry"),);
		}
		return $response;
	}

	sub dlg_upload_error_message_gnome_vfs {
		my $target_giofile = shift;
		my $result         = shift;

		#dialogs (main window != parent window)
		my $sd = Shutter::App::SimpleDialogs->new;

		my $target_path = $shf->utf8_decode(unescape_string($target_giofile->get_path // $target_giofile->get_uri));

		#retry button
		my $retry_btn = Gtk3::Button->new_with_mnemonic($d->get("_Retry"));
		$retry_btn->set_image(Gtk3::Image->new_from_stock('gtk-redo', 'button'));

		my $response = $sd->dlg_error_message(
			sprintf($d->get("Error while copying the image %s."),             "'" . $target_giofile->get_basename . "'"),
			sprintf($d->get("There was an error copying the image into %s."), "'" . $target_path . "'"),
			$d->get("Skip all"), $d->get("Skip"), undef, $retry_btn, undef, undef, $result
		);

		return $response;
	}


1;
