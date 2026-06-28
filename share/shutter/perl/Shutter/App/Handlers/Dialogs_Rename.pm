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

package Shutter::App::Handlers::Dialogs_Rename;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib           qw/TRUE FALSE/;
use File::Basename qw(fileparse);
use Shutter::App::SimpleDialogs;

has cli => (is => 'ro', required => 1);

sub dlg_rename ($self, @file_to_rename_keys) {
	my $cli             = $self->cli;
	my $window          = $cli->window;
	my $d               = $cli->sc->gettext_object;
	my $session_screens = $cli->{_session_screens};
	my $shf             = $cli->shf;
	my $sd              = $cli->sc->{_sd};

	foreach my $key (@file_to_rename_keys) {
		return FALSE unless defined $session_screens->{$key};

		my $input_dialog = Gtk3::MessageDialog->new($window, [qw/modal destroy-with-parent/], 'other', 'none', undef);

		$input_dialog->set_title($d->get("Rename"));

		$input_dialog->set('image' => Gtk3::Image->new_from_stock('gtk-save-as', 'dialog'));

		$input_dialog->set('text' => sprintf($d->get("Rename image %s"), "'$session_screens->{$key}->{'short'}'"));

		$input_dialog->set('secondary-text' => $d->get("New filename") . ": ");

		#rename button
		my $rename_btn = Gtk3::Button->new_with_mnemonic($d->get("_Rename"));
		$rename_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));
		$rename_btn->set_can_default(TRUE);

		$input_dialog->add_button('gtk-cancel', 'reject');
		$input_dialog->add_action_widget($rename_btn, 'accept');

		$input_dialog->set_default_response('accept');

		my $new_filename_vbox = Gtk3::VBox->new();
		my $new_filename_hint = Gtk3::Label->new();
		my $new_filename      = Gtk3::Entry->new();
		$new_filename->set_activates_default(TRUE);

		fct_validate_filename($new_filename, $new_filename_hint) if defined &fct_validate_filename;

		#parse filename
		my ($short, $folder, $ext) = fileparse($session_screens->{$key}->{'long'}, qr/\.[^.]*/);

		#enable/disable rename button
		#e.g. if no text is in entry
		$new_filename->signal_connect(
			'changed' => sub {
				my $temp_filename = $new_filename->get_text;
				if (length($temp_filename)) {
					$rename_btn->set_sensitive(TRUE);

					#Bug #1087367
					if ($temp_filename =~ /.*$ext$/) {
						my ($short, $folder, $ext) = fileparse($temp_filename, qr/\.[^.]*/);
						$new_filename->set_text($short);
					}
				} else {
					$rename_btn->set_sensitive(FALSE);
				}
				return TRUE;
			});

		#show just the name of the image
		$new_filename->set_text($session_screens->{$key}->{'name'});
		if (length($new_filename->get_text)) {
			$rename_btn->set_sensitive(TRUE);
		} else {
			$rename_btn->set_sensitive(FALSE);
		}

		$new_filename_vbox->pack_start($new_filename,      TRUE, TRUE, 0);
		$new_filename_vbox->pack_start($new_filename_hint, TRUE, TRUE, 0);
		$input_dialog->get_child->add($new_filename_vbox);
		$input_dialog->show_all;

		#run dialog
		my $input_response = $input_dialog->run;

		#handle user responses here
		if ($input_response eq 'accept') {

			my $new_name = $new_filename->get_text;
			$new_name = $session_screens->{$key}->{'folder'} . "/" . $new_name . "." . $session_screens->{$key}->{'filetype'};

			#create uris for following action (e.g. update tab, move etc.)
			my $new_giofile = Glib::IO::File::new_for_path($new_name);
			my $old_giofile = $session_screens->{$key}->{'giofile'};

			if ($new_giofile) {

				#filenames eq? -> nothing to do here
				unless ($session_screens->{$key}->{'long'} eq $new_name) {

					#does the "renamed" file already exists?
					unless ($shf->file_exists($new_name)) {

						#ok => rename it

						#cancel handle
						if (exists $session_screens->{$key}->{'handle'}) {

							$session_screens->{$key}->{'handle'}->cancel;
						}

						eval { $old_giofile->move($new_giofile, []); };
						if ($@) {
							my $response = $sd->dlg_error_message(
								sprintf($d->get("Error while renaming the image %s."),           "'" . $old_giofile->get_basename . "'"),
								sprintf($d->get("There was an error renaming the image to %s."), "'" . $new_giofile->get_basename . "'"),
								undef, undef, undef, undef, undef, undef, $@
							);

						}
						fct_update_tab($key, undef, $new_giofile, FALSE, 'block') if defined &fct_update_tab;

						#setup a new filemonitor, so we get noticed if the file changed
						fct_add_file_monitor($key) if defined &fct_add_file_monitor;

						fct_show_status_message(1, $session_screens->{$key}->{'long'} . " " . $d->get("renamed")) if defined &fct_show_status_message;

						#change window title
						#~ $window->set_title($session_screens->{$key}->{'long'}." - ".SHUTTER_NAME);

					} else {

						#ask the user to replace the image
						#replace button
						my $replace_btn = Gtk3::Button->new_with_mnemonic($d->get("_Replace"));
						$replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

						my $sd_local = Shutter::App::SimpleDialogs->new($window);

						my $response = $sd_local->dlg_warning_message(
							sprintf($d->get("The image already exists in %s. Replacing it will overwrite its contents."), "'" . $new_giofile->extract_dirname . "'"),
							sprintf($d->get("An image named %s already exists. Do you want to replace it?"),              "'" . $new_giofile->get_basename . "'"),
							undef, undef, undef, $replace_btn, undef, undef
						);

						#rename == replace_btn was hit
						if ($response == 40) {

							#ok => rename it

							#cancel handle
							if (exists $session_screens->{$key}->{'handle'}) {

								$session_screens->{$key}->{'handle'}->cancel;
							}

							eval { $old_giofile->move($new_giofile, ['overwrite']); };
							if ($@) {
								my $response = $sd_local->dlg_error_message(
									sprintf($d->get("Error while renaming the image %s."),           "'" . $old_giofile->get_basename . "'"),
									sprintf($d->get("There was an error renaming the image to %s."), "'" . $new_giofile->get_basename . "'"),
									undef, undef, undef, undef, undef, undef, $@
								);
							}
							fct_update_tab($key, undef, $new_giofile, FALSE, 'block') if defined &fct_update_tab;

							#setup a new filemonitor, so we get noticed if the file changed
							fct_add_file_monitor($key) if defined &fct_add_file_monitor;

							fct_show_status_message(1, $session_screens->{$key}->{'long'} . " " . $d->get("renamed")) if defined &fct_show_status_message;

							#change window title
							#~ $window->set_title($session_screens->{$key}->{'long'}." - ".SHUTTER_NAME);

							#maybe file is in session as well, need to set the handler again ;-)
							foreach my $searchkey (keys %$session_screens) {
								next if $key eq $searchkey;
								if ($session_screens->{$searchkey}->{'long'} eq $new_name) {

									#cancel handle
									if (exists $session_screens->{$searchkey}->{'handle'}) {

										$session_screens->{$searchkey}->{'handle'}->cancel;
									}

									fct_update_tab($searchkey, undef, $new_giofile, FALSE, 'block') if defined &fct_update_tab;

									#setup a new filemonitor, so we get noticed if the file changed
									fct_add_file_monitor($searchkey) if defined &fct_add_file_monitor;

								}
							}
							$input_dialog->destroy();
							next;
						}
						$input_dialog->destroy();
						next;
					}

				}

			} else {

				#uri object could not be created
				#=> uri illegal
				my $response = $sd->dlg_error_message(
					sprintf($d->get("Error while renaming the image %s."),           "'" . $old_giofile->get_basename . "'"),
					sprintf($d->get("There was an error renaming the image to %s."), "'" . $new_name . "'"),
					undef, undef, undef, undef, undef, undef, $d->get("Invalid Filename"));

			}

		}

		$input_dialog->destroy();
		next;

	}
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Dialogs_Rename - Rename dialog handler

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
