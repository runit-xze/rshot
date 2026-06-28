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
use Shutter::App::Core::ClipboardAPI;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Shutter::App::Directories;
use Shutter::App::SimpleDialogs;
use URI::Escape qw(uri_unescape);

has cli => (is => 'ro', required => 1);

sub dlg_profile_name ($self, $curr_profile_name, $combobox_settings_profiles) {
	my $cli    = $self->cli;
	my $window = $cli->window;
	my $d      = $cli->sc->gettext_object;
	my $shf    = $cli->shf;
	my $sd     = $cli->sc->{_sd};

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

	# Assuming fct_validate_filename is available globally or we call it appropriately
	$cli->handlers->get('Util_File')->fct_validate_filename($new_profile_name, $new_profile_name_hint);

	#show name of current profile
	$new_profile_name->set_text($curr_profile_name)
		if defined $curr_profile_name;

	$new_profile_name_vbox->pack_start($new_profile_name,      TRUE, TRUE, 0);
	$new_profile_name_vbox->pack_start($new_profile_name_hint, TRUE, TRUE, 0);
	$profile_dialog->get_child->add($new_profile_name_vbox);
	$profile_dialog->show_all;

	#run dialog
	my $profile_response = $profile_dialog->run;

	#handle user responses here
	if ($profile_response eq 'accept') {
		my $entered_name = $new_profile_name->get_text;

		if ($shf->file_exists(Shutter::App::Directories::get_profile_settings_file($entered_name))) {

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

sub dlg_upload_error_message ($self, $status, $max_filesize) {
	my $cli = $self->cli;
	my $d   = $cli->sc->gettext_object;

	#dialogs (main window != parent window)
	my $sd = Shutter::App::SimpleDialogs->new($cli->window);

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

sub dlg_upload ($self, @files_to_upload) {
	return FALSE if @files_to_upload < 1;

	my $cli       = $self->cli;
	my $sc        = $cli->sc;
	my $shf       = $cli->shf;
	my $d         = $sc->gettext_object;
	my $window    = $cli->window;
	require Shutter::App::Core::ClipboardAPI;
	my $clipboard = Shutter::App::Core::ClipboardAPI->new;

	my $dlg_header     = $d->get("Upload / Export");
	my $hosting_dialog = Gtk3::Dialog->new($dlg_header, $window, [qw/modal destroy-with-parent/]);
	$hosting_dialog->set_default_size(400, 300);

	my $close_button  = $hosting_dialog->add_button('gtk-close',        'close');
	my $upload_button = $hosting_dialog->add_button($d->get("_Upload"), 'accept');
	$upload_button->set_image(Gtk3::Image->new_from_stock('gtk-go-up', 'button'));
	$hosting_dialog->set_default_response('accept');

	#we need to know what plugins are fully set up
	my $model = Gtk3::ListStore->new('Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String');

	my $accounts_ref = $cli->{_accounts} // {};
	my %accounts     = %$accounts_ref;

	foreach (keys %accounts) {
		my $short_username = $accounts{$_}->{'username'};
		if (defined $accounts{$_}->{'username'} && length $accounts{$_}->{'username'} > 10) {
			$short_username = substr($accounts{$_}->{'username'}, 0, 10) . "...";
		}

		if ($accounts{$_}->{'supports_authorized_upload'}) {
			if ($accounts{$_}->{'username'} ne "" && $accounts{$_}->{'password'} ne "") {
				$model->set(
					$model->append,  0, $_, 1, $accounts{$_}->{'username'}, 2, $accounts{$_}->{'password'}, 3,
					$short_username, 4, $accounts{$_}->{'module'}, 5, $accounts{$_}->{'folder'}, 6, $accounts{$_}->{'path'});
			}
		}

		if ($accounts{$_}->{'supports_anonymous_upload'}) {
			$model->set($model->append, 0, $_, 1, $d->get("Guest"), 2, "", 3, $d->get("Guest"), 4, $accounts{$_}->{'module'}, 5, $accounts{$_}->{'folder'}, 6, $accounts{$_}->{'path'});
		}

		if ($accounts{$_}->{'supports_oauth_upload'}) {
			$model->set($model->append, 0, $_, 1, $d->get("OAuth"), 2, "", 3, $d->get("OAuth"), 4, $accounts{$_}->{'module'}, 5, $accounts{$_}->{'folder'}, 6, $accounts{$_}->{'path'});
		}
	}

	my $hosting       = Gtk3::ComboBox->new_with_model($model);
	my $renderer_host = Gtk3::CellRendererText->new;
	$hosting->pack_start($renderer_host, FALSE);
	$hosting->add_attribute($renderer_host, text => 0);

	my $renderer_username = Gtk3::CellRendererText->new;
	$hosting->pack_start($renderer_username, FALSE);
	$hosting->add_attribute($renderer_username, text => 3);
	$hosting->set_active(0);

	my $pub_hbox1      = Gtk3::HBox->new(FALSE, 0);
	my $pub_hbox_hint  = Gtk3::HBox->new(FALSE, 0);
	my $pub_hbox_hint2 = Gtk3::HBox->new(FALSE, 0);
	my $pub_vbox1      = Gtk3::VBox->new(FALSE, 0);

	my $pub_hint  = Gtk3::Label->new();
	my $pub_hint2 = Gtk3::Label->new();
	$pub_hint->set_line_wrap(TRUE);
	$pub_hint2->set_line_wrap(TRUE);
	$pub_hint->set_line_wrap_mode('word-char');
	$pub_hint2->set_line_wrap_mode('word-char');

	$pub_hint->set_markup("<span size='small'>"
			. $d->get(
			"Please choose one of the accounts above and click <i>Upload</i>. The upload links will still be available in the screenshot's <i>right-click menu</i> after closing this dialog.")
			. "</span>");
	$pub_hint2->set_markup("<span size='small'>"
			. $d->get("<b>Please note:</b> If a plugin allows only authorized uploading you need to enter your credentials in preferences first to make it appear in the list above.")
			. "</span>");

	$pub_hbox1->pack_start(Gtk3::Label->new($d->get("Choose account") . ":"), FALSE, FALSE, 6);
	$pub_hbox1->pack_start($hosting,                                          TRUE,  TRUE,  0);
	$pub_hbox_hint->pack_start($pub_hint, TRUE, TRUE, 6);
	$pub_hbox_hint2->pack_start($pub_hint2, TRUE, TRUE, 6);

	$pub_hint->set_alignment(0, 0.5);
	$pub_hint2->set_alignment(0, 0.5);

	$pub_vbox1->pack_start($pub_hbox1,      FALSE, FALSE, 3);
	$pub_vbox1->pack_start($pub_hbox_hint,  FALSE, FALSE, 3);
	$pub_vbox1->pack_start($pub_hbox_hint2, FALSE, FALSE, 3);

	my $pl_hbox1  = Gtk3::HBox->new(FALSE, 0);
	my $pl_vbox1  = Gtk3::VBox->new(FALSE, 0);
	my $places_fc = Gtk3::FileChooserButton->new("Shutter - " . $d->get("Choose folder"), 'select-folder');
	$places_fc->set('local-only' => FALSE);
	$pl_hbox1->pack_start(Gtk3::Label->new($d->get("Choose folder") . ":"), FALSE, FALSE, 6);
	$pl_hbox1->pack_start($places_fc,                                       TRUE,  TRUE,  0);
	$pl_vbox1->pack_start($pl_hbox1,                                        FALSE, FALSE, 3);

	my $unotebook     = Gtk3::Notebook->new;
	my $hosting_label = Gtk3::Label->new;
	$hosting_label->set_text($d->get("Public hosting"));
	$unotebook->append_page($pub_vbox1, $hosting_label);

	my $places_label = Gtk3::Label->new;
	$places_label->set_text($d->get("Places"));
	$unotebook->append_page($pl_vbox1, $places_label);
	$hosting_dialog->get_content_area->add($unotebook);

	my $hosting_progress = Gtk3::ProgressBar->new;
	$hosting_progress->set_no_show_all(TRUE);
	$hosting_progress->set_ellipsize('middle');
	$hosting_progress->set_orientation('horizontal');
	$hosting_dialog->get_content_area->add($hosting_progress);

	$hosting_dialog->show_all;

	if (defined $sc->ruu_tab) {
		$unotebook->set_current_page($sc->ruu_tab);
	}

	if (defined $sc->ruu_hosting) {
		$hosting->set_active($sc->ruu_hosting);
	} else {
		$hosting->set_active(0);
	}

	if (defined $sc->ruu_places && $shf->folder_exists($sc->ruu_places)) {
		$places_fc->set_current_folder($sc->ruu_places);
	}

	while (my $hosting_response = $hosting_dialog->run) {
		if ($hosting_response eq "accept") {
			$upload_button->set_sensitive(FALSE);
			$close_button->set_sensitive(FALSE);
			$hosting_progress->show;

			if ($unotebook->get_current_page == 0) {
				my $model            = $hosting->get_model();
				my $hosting_iter     = $hosting->get_active_iter();
				my $hosting_host     = $model->get_value($hosting_iter, 0);
				my $hosting_display  = $model->get_value($hosting_iter, 0);
				my $hosting_username = $model->get_value($hosting_iter, 1);
				my $hosting_password = $model->get_value($hosting_iter, 2);
				my $hosting_module   = $model->get_value($hosting_iter, 4);
				my $hosting_folder   = $model->get_value($hosting_iter, 5);
				my $hosting_path     = $model->get_value($hosting_iter, 6);

				$hosting_progress->set_text(sprintf($d->get("Loading module %s"), $hosting_module));
				$cli->handlers->get('UI_Status')->fct_update_gui();

				eval {
					lib->import($hosting_folder);
					require "$hosting_module.pm";
				};
				if ($@) {
					my $sd = Shutter::App::SimpleDialogs->new($window);
					$sd->dlg_error_message(
						sprintf($d->get("Error while executing upload plugin %s."), "'" . $hosting_module . "'"),
						$d->get("There was an error executing the upload plugin."),
						undef, undef, undef, undef, undef, undef, $@
					);
					$hosting_dialog->destroy();
					return FALSE;
				}

				my $uploader;
				if ($hosting_module eq 'ShareX') {
					$uploader = "Shutter::Upload::ShareX"->new($hosting_path, $sc->debug, $sc->shutter_root, $d, $window, $sc->version);
				} else {
					$uploader = $hosting_module->new($hosting_host, $sc->debug, $sc->shutter_root, $d, $window, $sc->version);
				}

				if ($uploader->init($hosting_username)) {
					my $counter = 1;
					$hosting_progress->set_fraction(0);
					foreach my $key (sort @files_to_upload) {
						my $file = $cli->{_session_screens}->{$key}->{'long'};
						$hosting_progress->set_text("Uploading $file");
						$cli->handlers->get('UI_Status')->fct_update_gui();

						my %upload_response = $uploader->upload($shf->switch_home_in_file($file), $hosting_username, $hosting_password);

						if ($upload_response{'status'} >= 200 && $upload_response{'status'} < 300) {    # is_success replacement
							foreach (keys %upload_response) {
								next if $_ eq 'status';
								$cli->{_session_screens}->{$key}->{'links'}->{$hosting_display}->{$_} = $upload_response{$_};
								$cli->{_session_screens}->{$key}->{'links'}->{$hosting_display}->{'menuentry'} = $hosting_display;
							}
							$uploader->show;
							$cli->handlers->get('UI_Status')->fct_show_status_message(1, $file . " " . $d->get("uploaded"));
						} else {
							my $response = $self->dlg_upload_error_message($upload_response{'status'}, $upload_response{'max_filesize'});
							last if $response == 10;
							next if $response == 20;
							redo if $response == 30;
							next;
						}
						$hosting_progress->set_fraction($counter / @files_to_upload);
						$cli->handlers->get('UI_Status')->fct_update_gui();
						$counter++;
					}
					$uploader->show_all;
				}
			} elsif ($unotebook->get_current_page == 1) {

				# Places export logic
			}

			$sc->ruu_tab($unotebook->get_current_page);
			$sc->ruu_hosting($hosting->get_active);
			$sc->ruu_places($places_fc->get_filename);

			$upload_button->set_sensitive(TRUE);
			$close_button->set_sensitive(TRUE);
			$hosting_progress->hide;
		} else {
			$hosting_dialog->destroy();
			return FALSE;
		}
	}
	return;
}

sub dlg_upload_error_message_gnome_vfs ($self, $target_giofile, $result) {
	my $cli = $self->cli;
	my $d   = $cli->sc->gettext_object;
	my $shf = $cli->shf;

	#dialogs (main window != parent window)
	my $sd = Shutter::App::SimpleDialogs->new($cli->window);

	my $target_path = $shf->utf8_decode(uri_unescape($target_giofile->get_path // $target_giofile->get_uri));

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

__END__

=head1 NAME

Shutter::App::Handlers::Dialogs_Upload – Upload dialog handlers

=head1 DESCRIPTION

This module handles dialogs related to profile management and upload errors in Shutter.
It has been migrated to use the CLI object for state access instead of package globals.

=head1 METHODS

=head2 dlg_profile_name

Opens a dialog to prompt the user for a new profile name, with validation and replacement confirmation.

=head2 dlg_upload_error_message

Displays an error message dialog for upload-related issues.

=head2 dlg_upload_error_message_gnome_vfs

Displays an error message dialog for GNOME VFS upload-related issues.

=cut
