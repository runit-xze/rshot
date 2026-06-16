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

package Shutter::App::Handlers::Dialogs_UploadMain;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub dlg_upload {
		my (@files_to_upload) = @_;

		return FALSE if @files_to_upload < 1;

		my $dlg_header     = $d->get("Upload / Export");
		my $hosting_dialog = Gtk3::Dialog->new($dlg_header, $window, [qw/modal destroy-with-parent/]);
		$hosting_dialog->set_default_size(400, 300);

		my $close_button  = $hosting_dialog->add_button('gtk-close',        'close');
		my $upload_button = $hosting_dialog->add_button($d->get("_Upload"), 'accept');
		$upload_button->set_image(Gtk3::Image->new_from_stock('gtk-go-up', 'button'));
		$hosting_dialog->set_default_response('accept');
		#we need to know what plugins are fully set up
		my $model = Gtk3::ListStore->new('Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String');

		foreach (keys %accounts) {

			#cut username so the dialog will not explode ;-)
			my $short_username = $accounts{$_}->{'username'};
			if (defined $accounts{$_}->{'username'}
				&& length $accounts{$_}->{'username'} > 10)
			{
				$short_username = substr($accounts{$_}->{'username'}, 0, 10) . "...";
			}

			#Create Username/Password entry (if supported and supplied)
			if ($accounts{$_}->{'supports_authorized_upload'}) {
				if (   $accounts{$_}->{'username'} ne ""
					&& $accounts{$_}->{'password'} ne "")
				{
					$model->set(
						$model->append,  0, $accounts{$_}->{'module'}, 1, $accounts{$_}->{'username'}, 2, $accounts{$_}->{'password'}, 3,
						$short_username, 4, $accounts{$_}->{'module'}, 5, $accounts{$_}->{'folder'}, 6, $accounts{$_}->{'path'});
				}
			}

			#Create Anonymous entry (if supported)
			if ($accounts{$_}->{'supports_anonymous_upload'}) {
				$model->set($model->append, 0, $accounts{$_}->{'module'}, 1, $d->get("Guest"), 2, "", 3, $d->get("Guest"), 4, $accounts{$_}->{'module'}, 5, $accounts{$_}->{'folder'}, 6, $accounts{$_}->{'path'});
			}

			#Create OAuth entry (if supported)
			if ($accounts{$_}->{'supports_oauth_upload'}) {
				$model->set($model->append, 0, $accounts{$_}->{'module'}, 1, $d->get("OAuth"), 2, "", 3, $d->get("OAuth"), 4, $accounts{$_}->{'module'}, 5, $accounts{$_}->{'folder'}, 6, $accounts{$_}->{'path'});
			}
		}

		#set up account combobox
		my $hosting       = Gtk3::ComboBox->new_with_model($model);
		my $renderer_host = Gtk3::CellRendererText->new;
		$hosting->pack_start($renderer_host, FALSE);
		$hosting->add_attribute($renderer_host, text => 0);

		my $renderer_username = Gtk3::CellRendererText->new;
		$hosting->pack_start($renderer_username, FALSE);
		$hosting->add_attribute($renderer_username, text => 3);
		$hosting->set_active(0);

		#public hosting settings
		my $pub_hbox1      = Gtk3::HBox->new(FALSE, 0);
		my $pub_hbox2      = Gtk3::HBox->new(FALSE, 0);
		my $pub_hbox_hint  = Gtk3::HBox->new(FALSE, 0);
		my $pub_hbox_hint2 = Gtk3::HBox->new(FALSE, 0);
		my $pub_vbox1      = Gtk3::VBox->new(FALSE, 0);

		my $pub_hint  = Gtk3::Label->new();
		my $pub_hint2 = Gtk3::Label->new();
		$pub_hint->set_line_wrap(TRUE);
		$pub_hint2->set_line_wrap(TRUE);
		$pub_hint->set_line_wrap_mode('word-char');
		$pub_hint2->set_line_wrap_mode('word-char');

		$pub_hint->set_markup(
			"<span size='small'>"
				. $d->get(
				"Please choose one of the accounts above and click <i>Upload</i>. The upload links will still be available in the screenshot's <i>right-click menu</i> after closing this dialog.")
				. "</span>"
		);
		$pub_hint2->set_markup("<span size='small'>"
				. $d->get("<b>Please note:</b> If a plugin allows only authorized uploading you need to enter your credentials in preferences first to make it appear in the list above.")
				. "</span>");

		$pub_hbox1->pack_start(Gtk3::Label->new($d->get("Choose account") . ":"), FALSE, FALSE, 6);
		$pub_hbox1->pack_start($hosting, TRUE, TRUE, 0);
		$pub_hbox_hint->pack_start($pub_hint, TRUE, TRUE, 6);
		$pub_hbox_hint2->pack_start($pub_hint2, TRUE, TRUE, 6);

		$pub_hint->set_alignment(0, 0.5);
		$pub_hint2->set_alignment(0, 0.5);

		$pub_vbox1->pack_start($pub_hbox1,      FALSE, FALSE, 3);
		$pub_vbox1->pack_start($pub_hbox_hint,  FALSE, FALSE, 3);
		$pub_vbox1->pack_start($pub_hbox_hint2, FALSE, FALSE, 3);

		#places settings
		my $pl_hbox1 = Gtk3::HBox->new(FALSE, 0);
		my $pl_vbox1 = Gtk3::VBox->new(FALSE, 0);
		my $places_fc = Gtk3::FileChooserButton->new("Shutter - " . $d->get("Choose folder"), 'select-folder');
		$places_fc->set('local-only' => FALSE);
		$pl_hbox1->pack_start(Gtk3::Label->new($d->get("Choose folder") . ":"), FALSE, FALSE, 6);
		$pl_hbox1->pack_start($places_fc, TRUE, TRUE, 0);
		$pl_vbox1->pack_start($pl_hbox1, FALSE, FALSE, 3);

		#ftp settings
		#we are using the same widgets as in the settings and populate
		#them with saved values when possible
		my $ftp_hbox1_dlg = Gtk3::HBox->new(FALSE, 0);
		my $ftp_hbox2_dlg = Gtk3::HBox->new(FALSE, 0);
		my $ftp_hbox3_dlg = Gtk3::HBox->new(FALSE, 0);
		my $ftp_hbox4_dlg = Gtk3::HBox->new(FALSE, 0);
		my $ftp_hbox5_dlg = Gtk3::HBox->new(FALSE, 0);

		#uri
		my $ftp_entry_label_dlg = Gtk3::Label->new($d->get("URI") . ":");
		$ftp_hbox1_dlg->pack_start($ftp_entry_label_dlg, FALSE, TRUE, 10);
		my $ftp_remote_entry_dlg = Gtk3::Entry->new;
		$ftp_remote_entry_dlg->set_text($ftp_remote_entry->get_text);

		$ftp_entry_label_dlg->set_tooltip_text($d->get("URI\nExample: ftp://host:port/path"));

		$ftp_remote_entry_dlg->set_tooltip_text($d->get("URI\nExample: ftp://host:port/path"));

		$ftp_hbox1_dlg->pack_start($ftp_remote_entry_dlg, TRUE, TRUE, 10);

		#connection mode
		my $ftp_mode_label_dlg = Gtk3::Label->new($d->get("Connection mode") . ":");
		$ftp_hbox2_dlg->pack_start($ftp_mode_label_dlg, FALSE, TRUE, 10);
		my $ftp_mode_combo_dlg = Gtk3::ComboBoxText->new;
		$ftp_mode_combo_dlg->insert_text(0, $d->get("Active mode"));
		$ftp_mode_combo_dlg->insert_text(1, $d->get("Passive mode"));
		$ftp_mode_combo_dlg->set_active($ftp_mode_combo->get_active);

		$ftp_mode_label_dlg->set_tooltip_text($d->get("Connection mode"));

		$ftp_mode_combo_dlg->set_tooltip_text($d->get("Connection mode"));

		$ftp_hbox2_dlg->pack_start($ftp_mode_combo_dlg, TRUE, TRUE, 10);

		#username
		my $ftp_username_label_dlg = Gtk3::Label->new($d->get("Username") . ":");
		$ftp_hbox3_dlg->pack_start($ftp_username_label_dlg, FALSE, TRUE, 10);
		my $ftp_username_entry_dlg = Gtk3::Entry->new;
		$ftp_username_entry_dlg->set_text($ftp_username_entry->get_text);

		$ftp_username_label_dlg->set_tooltip_text($d->get("Username"));

		$ftp_username_entry_dlg->set_tooltip_text($d->get("Username"));

		$ftp_hbox3_dlg->pack_start($ftp_username_entry_dlg, TRUE, TRUE, 10);

		#password
		my $ftp_password_label_dlg = Gtk3::Label->new($d->get("Password") . ":");
		$ftp_hbox4_dlg->pack_start($ftp_password_label_dlg, FALSE, TRUE, 10);
		my $ftp_password_entry_dlg = Gtk3::Entry->new;
		$ftp_password_entry_dlg->set_invisible_char("*");
		$ftp_password_entry_dlg->set_visibility(FALSE);
		$ftp_password_entry_dlg->set_text($ftp_password_entry->get_text);

		$ftp_password_label_dlg->set_tooltip_text($d->get("Password"));

		$ftp_password_entry_dlg->set_tooltip_text($d->get("Password"));

		$ftp_hbox4_dlg->pack_start($ftp_password_entry_dlg, TRUE, TRUE, 10);

		#website url
		my $ftp_wurl_label_dlg = Gtk3::Label->new($d->get("Website URL") . ":");
		$ftp_hbox5_dlg->pack_start($ftp_wurl_label_dlg, FALSE, TRUE, 10);
		my $ftp_wurl_entry_dlg = Gtk3::Entry->new;
		$ftp_wurl_entry_dlg->set_text($ftp_wurl_entry->get_text);

		$ftp_wurl_label_dlg->set_tooltip_text($d->get("Website URL"));

		$ftp_wurl_entry_dlg->set_tooltip_text($d->get("Website URL"));

		$ftp_hbox5_dlg->pack_start($ftp_wurl_entry_dlg, TRUE, TRUE, 10);

		my $ftp_vbox_dlg = Gtk3::VBox->new(FALSE, 0);
		$ftp_vbox_dlg->pack_start($ftp_hbox1_dlg, FALSE, TRUE, 3);
		$ftp_vbox_dlg->pack_start($ftp_hbox2_dlg, FALSE, TRUE, 3);
		$ftp_vbox_dlg->pack_start($ftp_hbox3_dlg, FALSE, TRUE, 3);
		$ftp_vbox_dlg->pack_start($ftp_hbox4_dlg, FALSE, TRUE, 3);
		$ftp_vbox_dlg->pack_start($ftp_hbox5_dlg, FALSE, TRUE, 3);

		#all labels = one size
		$ftp_entry_label_dlg->set_alignment(0, 0.5);
		$ftp_mode_label_dlg->set_alignment(0, 0.5);
		$ftp_username_label_dlg->set_alignment(0, 0.5);
		$ftp_password_label_dlg->set_alignment(0, 0.5);
		$ftp_wurl_label_dlg->set_alignment(0, 0.5);

		my $sg_ftp_dlg = Gtk3::SizeGroup->new('horizontal');
		$sg_ftp_dlg->add_widget($ftp_entry_label_dlg);
		$sg_ftp_dlg->add_widget($ftp_mode_label_dlg);
		$sg_ftp_dlg->add_widget($ftp_username_label_dlg);
		$sg_ftp_dlg->add_widget($ftp_password_label_dlg);
		$sg_ftp_dlg->add_widget($ftp_wurl_label_dlg);

		#setup notebook
		my $unotebook = Gtk3::Notebook->new;
		my $hosting_label = Gtk3::Label->new;
		$hosting_label->set_text($d->get("Public hosting"));
		$unotebook->append_page($pub_vbox1,    $hosting_label);
		my $ftp_label = Gtk3::Label->new;
		$ftp_label->set_text("FTP");
		$unotebook->append_page($ftp_vbox_dlg, $ftp_label);
		my $places_label = Gtk3::Label->new;
		$places_label->set_text($d->get("Places"));
		$unotebook->append_page($pl_vbox1,     $places_label);
		$hosting_dialog->get_child->add($unotebook);

		my $hosting_progress = Gtk3::ProgressBar->new;
		$hosting_progress->set_no_show_all(TRUE);
		$hosting_progress->set_ellipsize('middle');
		$hosting_progress->set_orientation('horizontal');
		$hosting_dialog->get_child->add($hosting_progress);

		$hosting_dialog->show_all;

		#restore recently used upload tab
		if (defined $sc->get_ruu_tab && $sc->get_ruu_tab) {
			$unotebook->set_current_page($sc->get_ruu_tab);
		}

		#and the relevant detail (folder, uploader etc.)
		if (defined $sc->get_ruu_hosting && $sc->get_ruu_hosting) {
			$hosting->set_active($sc->get_ruu_hosting);
		} else {
			$hosting->set_active(0);
		}
		if (defined $sc->get_ruu_places
			&& $shf->folder_exists($sc->get_ruu_places))
		{
			$places_fc->set_current_folder($sc->get_ruu_places);
		}

		#DIALOG RUN
		while (my $hosting_response = $hosting_dialog->run) {

			#start upload
			if ($hosting_response eq "accept") {

				#running state of dialog
				$upload_button->set_sensitive(FALSE);
				$close_button->set_sensitive(FALSE);
				$hosting_progress->show;

				#public hosting
				#All modules must provide the following methods:
				# 1: init
				# 2: upload
				# 3: show
				# 4: show_all

				if ($unotebook->get_current_page == 0) {

					my $model            = $hosting->get_model();
					my $hosting_iter     = $hosting->get_active_iter();
					my $hosting_host     = $model->get_value($hosting_iter, 0);
					my $hosting_username = $model->get_value($hosting_iter, 1);
					my $hosting_password = $model->get_value($hosting_iter, 2);
					my $hosting_module   = $model->get_value($hosting_iter, 4);
					my $hosting_folder   = $model->get_value($hosting_iter, 5);
					my $hosting_path     = $model->get_value($hosting_iter, 6);

					$hosting_progress->set_text(sprintf($d->get("Loading module %s"), $hosting_module));
					fct_update_gui();

					#import module
					eval {
						lib->import($hosting_folder);
						require "$hosting_module.pm";
					};
					if ($@) {

						#dialogs (main window != parent window)
						my $sd = Shutter::App::SimpleDialogs->new;

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
						$uploader = $hosting_module->new($hosting_path, $sc->get_debug, $shutter_root, $d, $window, SHUTTER_VERSION);
					} else {
						$uploader = $hosting_module->new($hosting_host, $sc->get_debug, $shutter_root, $d, $window, SHUTTER_VERSION);
					}

					#init module
					if ($uploader->init($hosting_username)) {

						my $counter = 1;
						$hosting_progress->set_fraction(0);
						foreach my $key (sort @files_to_upload) {

							my $file = $session_screens{$key}->{'long'};

							#set text for progressbar
							$hosting_progress->set_text("Uploading $file");
							fct_update_gui();

							#upload file
							my %upload_response = $uploader->upload($shf->switch_home_in_file($file), $hosting_username, $hosting_password);

							if (is_success($upload_response{'status'})) {

								#add to public-links menu
								foreach (keys %upload_response) {
									next if $_ eq 'status';
									$session_screens{$key}->{'links'}->{$hosting_module}->{$_} = $upload_response{$_};
									$session_screens{$key}->{'links'}->{$hosting_module}->{'menuentry'} = $hosting_module;
								}

								$uploader->show;
								fct_show_status_message(1, $file . " " . $d->get("uploaded"));
							} else {
								my $response = dlg_upload_error_message($upload_response{'status'}, $upload_response{'max_filesize'});

								#10 == skip all, 20 == skip, else == cancel
								last if $response == 10;
								next if $response == 20;
								redo if $response == 30;
								next;
							}
							$hosting_progress->set_fraction($counter / @files_to_upload);

							#update gui
							fct_update_gui();
							$counter++;
						}

						$uploader->show_all;

					}

					#ftp
				} elsif ($unotebook->get_current_page == 1) {

					#create upload object
					my $uploader = Shutter::Upload::FTP->new($sc->get_debug, $shutter_root, $d, $window, $ftp_mode_combo_dlg->get_active);

					my $counter = 1;
					my $login   = FALSE;
					$hosting_progress->set_fraction(0);

					#start upload
					foreach my $key (sort @files_to_upload) {

						my $file = $session_screens{$key}->{'long'};

						#need to login?
						my @upload_response;
						unless ($login) {

							eval { $uploader->quit; };

							@upload_response = $uploader->login($ftp_remote_entry_dlg->get_text, $ftp_username_entry_dlg->get_text, $ftp_password_entry_dlg->get_text);

							if ($upload_response[0]) {

								#dialogs (main window != parent window)
								my $sd = Shutter::App::SimpleDialogs->new;

								#we already get translated error messaged back
								my $response = $sd->dlg_error_message($upload_response[1], $upload_response[0], undef, undef, undef, undef, undef, undef, $upload_response[2]);
								next;
							} else {
								$login = TRUE;
							}

						}

						$hosting_progress->set_text($file);

						#update gui
						fct_update_gui();
						@upload_response = $uploader->upload($shf->switch_home_in_file($file));

						#upload returns FALSE if there is no error
						unless ($upload_response[0]) {

							#everything is fine here
							fct_show_status_message(1, $file . " " . $d->get("uploaded"));

							#show as notification
							my $notify = $sc->get_notification_object;
							$notify->show($d->get("Successfully uploaded"), sprintf($d->get("The file %s was successfully uploaded."), $file));

							#copy website url to clipboard
							my $uri = $ftp_wurl_entry_dlg->get_text;
							if ($uri) {
								my ($short, $folder, $ext) = fileparse($file, qr/\.[^.]*/);
								if ($uri !~ m|/$|) {
									$uri .= '/';
								}
								$uri .= $short . $ext;
								$clipboard->set_text($uri);
								print "copied URI ", $uri, " to clipboard\n"
									if $sc->get_debug;
							}

						} else {

							#dialogs (main window != parent window)
							my $sd = Shutter::App::SimpleDialogs->new;

							#we already get translated error messaged back
							my $response =
								$sd->dlg_error_message($upload_response[1], $upload_response[0], $d->get("Skip all"), $d->get("Skip"), $d->get("Retry"), undef, undef, undef, $upload_response[2]);

							#10 == skip all, 20 == skip, 30 == redo, else == cancel
							if ($response == 10) {
								last;
							} elsif ($response == 20) {
								$login = FALSE;
								next;
							} elsif ($response == 30) {
								$login = FALSE;
								redo;
							} else {
								next;
							}

						}
						$hosting_progress->set_fraction($counter / @files_to_upload);

						#update gui
						fct_update_gui();
						$counter++;
					}    #end foreach

					eval { $uploader->quit; };

					#xfer using Gnome-VFS
				} elsif ($unotebook->get_current_page == 2) {

					my $counter = 1;
					$hosting_progress->set_fraction(0);

					#start upload
					foreach my $key (sort @files_to_upload) {

						my $file = $session_screens{$key}->{'long'};

						$hosting_progress->set_text($file);

						#update gui
						fct_update_gui();

						my $source_giofile = Glib::IO::File::new_for_path($file);

						my $target_giofile = Glib::IO::File::new_for_uri($places_fc->get_uri);
						$target_giofile = $target_giofile->get_child($source_giofile->get_basename);

						#~ print sprintf("%s und %s \n", $target_giofile->to_string, $source_giofile->to_string);

						my $result;
						unless (unescape_string($target_giofile->get_path) eq unescape_string($source_giofile->get_path)) {
							unless ($target_giofile->query_exists) {
								eval {
									$source_giofile->copy($target_giofile, []);
									$result = 'ok';
								};
								if ($@) {
									$result = $@;
								}
							} else {
								$result = 'error-file-exists';
							}
						} else {
							$result = 'ok';
						}

						#everything is fine here
						if ($result eq 'ok') {
							fct_show_status_message(1, $file . " " . $d->get("exported"));

							#show as notification
							my $notify = $sc->get_notification_object;
						} elsif ($result eq 'error-file-exists') {

							#ask the user to replace the image
							#replace button
							my $replace_btn = Gtk3::Button->new_with_mnemonic($d->get("_Replace"));
							$replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

							my $target_path = $shf->utf8_decode(unescape_string($target_giofile->get_path // $target_giofile->get_uri));

							#dialogs (main window != parent window)
							my $sd = Shutter::App::SimpleDialogs->new;

							my $response = $sd->dlg_warning_message(
								sprintf($d->get("The image already exists in %s. Replacing it will overwrite its contents."), "'" . $target_path . "'"),
								sprintf($d->get("An image named %s already exists. Do you want to replace it?"),              "'" . $shf->utf8_decode($target_giofile->get_basename) . "'"),
								$d->get("Skip all"), $d->get("Skip"), undef, $replace_btn, undef, undef
							);

							#10 == skip all, 20 == skip, 40 == replace, else == cancel
							if ($response == 10) {
								last;
							} elsif ($response == 20) {
								next;
							} elsif ($response == 40) {
								eval {
									$source_giofile->copy($target_giofile, ['overwrite']);
									$result = 'ok';
								};
								if ($@) {
									$result = $@;
								}

								#check result again
								if ($result eq 'ok') {

									fct_show_status_message(1, $file . " " . $d->get("exported"));

									#show as notification
									my $notify = $sc->get_notification_object;
									$notify->show($d->get("Successfully exported"), sprintf($d->get("The file %s was successfully exported."), $file));

								} else {

									my $response = dlg_upload_error_message_gnome_vfs($target_giofile, $result);

									#10 == skip all, 20 == skip, 40 == retry, else == cancel
									if ($response == 10) {
										last;
									} elsif ($response == 20) {
										next;
									} elsif ($response == 40) {
										redo;
									} else {
										next;
									}

								}
							}

						} else {

							my $response = dlg_upload_error_message_gnome_vfs($target_giofile, $result);

							#10 == skip all, 20 == skip, 40 == retry, else == cancel
							if ($response == 10) {
								last;
							} elsif ($response == 20) {
								next;
							} elsif ($response == 40) {
								redo;
							} else {
								next;
							}

						}

						$hosting_progress->set_fraction($counter / @files_to_upload);

						#update gui
						fct_update_gui();
						$counter++;

					}

				}

				#save recently used upload tab
				$sc->set_ruu_tab($unotebook->get_current_page);

				#and the relevant detail (folder, uploader etc.)
				#hosting service
				$sc->set_ruu_hosting($hosting->get_active);
				$sc->set_ruu_places($places_fc->get_filename);

				#set initial state of dialog
				$upload_button->set_sensitive(TRUE);
				$close_button->set_sensitive(TRUE);
				$hosting_progress->hide;

				#response != accept
			} else {
				$hosting_dialog->destroy();
				return FALSE;
			}

		}    #dialog loop
	}


1;
