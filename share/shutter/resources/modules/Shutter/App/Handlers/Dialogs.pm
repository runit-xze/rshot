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

package Shutter::App::Handlers::Dialogs;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub dlg_open {
		my ($widget, $data) = @_;
		print "\n$data was emitted by widget $widget\n"
			if $sc->get_debug;

		#do we need to open a filechooserdialog?
		#maybe we open a recently opened file that is
		#selected via menu
		my @new_files;
		unless ($widget =~ /Gtk3::RecentChooserMenu/) {
			my $fs = Gtk3::FileChooserDialog->new(
				$d->get("Choose file to open"), $window,
				'open',
				'gtk-cancel' => 'reject',
				'gtk-open'   => 'accept'
			);
			$fs->set_select_multiple(TRUE);

			#preview widget
			my $iprev = Gtk3::Image->new;
			$fs->set_preview_widget($iprev);

			$fs->signal_connect(
				'selection-changed' => sub {
					if (my $pfilename = $fs->get_preview_filename) {

						#without error dialog
						my $pixbuf = $lp_ne->load($pfilename, 200, 200, TRUE, TRUE);
						unless (defined $pixbuf) {
							$fs->set_preview_widget_active(FALSE);
						} else {
							$fs->get_preview_widget->set_from_pixbuf($pixbuf);
							$fs->set_preview_widget_active(TRUE);
						}
					} else {
						$fs->set_preview_widget_active(FALSE);
					}
				});

			my $filter_all = Gtk3::FileFilter->new;
			$filter_all->set_name($d->get("All compatible image formats"));
			$fs->add_filter($filter_all);

			foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
				my $filter = Gtk3::FileFilter->new;

				#add all known formats to the dialog
				$filter->set_name($format->get_name . " - " . $format->get_description);

				foreach my $ext (@{$format->get_extensions}) {
					$filter->add_pattern("*." . uc $ext);
					$filter_all->add_pattern("*." . uc $ext);
					$filter->add_pattern("*." . $ext);
					$filter_all->add_pattern("*." . $ext);
				}
				$fs->add_filter($filter);
			}

			#set default filter
			$fs->set_filter($filter_all);

			#get current file
			my $key = fct_get_current_file();

			#go to recently used folder
			if (defined $sc->get_ruof && $shf->folder_exists($sc->get_ruof)) {
				$fs->set_current_folder_uri($sc->get_ruof);
			} else {
				if ($key) {
					$fs->set_filename($session_screens{$key}->{'long'});
				} elsif ($saveDir_button->get_filename) {
					$fs->set_current_folder($saveDir_button->get_filename);
				} else {
					$fs->set_current_folder($ENV{'HOME'});
				}
			}

			my $fs_resp = $fs->run;

			if ($fs_resp eq "accept") {
				@new_files = @{$fs->get_uris};

				#keep folder in mind
				if ($new_files[0]) {
					my ($oshort, $ofolder, $oext) = fileparse($new_files[0], qr/\.[^.]*/);
					$sc->set_ruof($ofolder) if defined $ofolder;
				}

				$fs->destroy();
			} else {
				$fs->destroy();
			}

		} else {
			print "Trying to open file via RecentChooserMenu ", $sm->{_menu_recent}->get_current_item->get_uri, "\n"
				if $sc->get_debug;
			push @new_files, $sm->{_menu_recent}->get_current_item->get_uri;
		}

		#call function to open files - with progress bar etc.
		fct_open_files(@new_files);

		return TRUE;
	}

	sub dlg_plugin {
		my (@file_to_plugin_keys) = @_;

		my $plugin_dialog = Gtk3::Dialog->new($d->get("Choose a plugin"), $window, [qw/modal destroy-with-parent/]);
		$plugin_dialog->set_size_request(350, -1);
		$plugin_dialog->set_resizable(FALSE);

		#rename button
		my $run_btn = Gtk3::Button->new_with_mnemonic($d->get("_Run"));
		$run_btn->set_image(Gtk3::Image->new_from_stock('gtk-execute', 'button'));
		$run_btn->set_can_default(TRUE);

		$plugin_dialog->add_button('gtk-cancel', 'reject');
		$plugin_dialog->add_action_widget($run_btn, 'accept');

		$plugin_dialog->set_default_response('accept');

		my $model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String');

		#temp variables to restore the
		#recent plugin
		my $recent_time        = 0;
		my $iter_lastex_plugin = undef;
		foreach my $pkey (sort keys %plugins) {

			#check if plugin allows current filetype
			#~ my $nfiles_ok += scalar grep($plugins{$pkey}->{'ext'} =~ /$session_screens{$_}->{'mime_type'}/, @file_to_plugin_keys);
			#~ next if scalar @file_to_plugin_keys > $nfiles_ok;

			if ($plugins{$pkey}->{'binary'} ne "") {

				my $new_iter = $model->append;
				$model->set(
					$new_iter,                 0, $plugins{$pkey}->{'pixbuf_object'}, 1, $plugins{$pkey}->{'name'}, 2, $plugins{$pkey}->{'binary'}, 3,
					$plugins{$pkey}->{'lang'}, 4, $plugins{$pkey}->{'tooltip'},       5, $pkey
				);

				#initialize $iter_lastex_plugin
				#with first new iter
				$iter_lastex_plugin = $new_iter
					unless defined $iter_lastex_plugin;

				#restore the recent plugin
				#($plugins{$plugin_key}->{'recent'} is a timestamp)
				#
				#we keep the new_iter in mind
				if (defined $plugins{$pkey}->{'recent'}
					&& $plugins{$pkey}->{'recent'} > $recent_time)
				{
					$iter_lastex_plugin = $new_iter;
					$recent_time        = $plugins{$pkey}->{'recent'};
				}

			} else {
				print "WARNING: Program $pkey is not configured properly, ignoring\n";
			}

		}

		my $plugin_label = Gtk3::Label->new($d->get("Plugin") . ":");
		my $plugin       = Gtk3::ComboBox->new_with_model($model);

		#plugin description
		my $plugin_descr      = Gtk3::TextBuffer->new;
		my $plugin_descr_view = Gtk3::TextView->new_with_buffer($plugin_descr);
		$plugin_descr_view->set_sensitive(FALSE);
		$plugin_descr_view->set_wrap_mode('word');
		my $textview_hbox = Gtk3::HBox->new(FALSE, 5);
		$textview_hbox->set_border_width(8);
		$textview_hbox->pack_start($plugin_descr_view, TRUE, TRUE, 0);

		my $plugin_descr_label = Gtk3::Label->new();
		$plugin_descr_label->set_markup("<b>" . $d->get("Description") . "</b>");
		my $plugin_descr_frame = Gtk3::Frame->new();
		$plugin_descr_frame->set_label_widget($plugin_descr_label);
		$plugin_descr_frame->set_shadow_type('none');
		$plugin_descr_frame->add($textview_hbox);

		#plugin image
		my $plugin_image = Gtk3::Image->new;

		#packing
		my $plugin_vbox1 = Gtk3::VBox->new(FALSE, 5);
		my $plugin_hbox1 = Gtk3::HBox->new(FALSE, 5);
		my $plugin_hbox2 = Gtk3::HBox->new(FALSE, 5);
		$plugin_hbox2->set_border_width(10);

		#what plugin is selected?
		my $plugin_pixbuf = undef;
		my $plugin_name   = undef;
		my $plugin_value  = undef;
		my $plugin_lang   = undef;
		my $plugin_tip    = undef;
		my $plugin_key    = undef;
		$plugin->signal_connect(
			'changed' => sub {
				my $model       = $plugin->get_model();
				my $plugin_iter = $plugin->get_active_iter();

				if ($plugin_iter) {
					$plugin_pixbuf = $model->get_value($plugin_iter, 0);
					$plugin_name   = $model->get_value($plugin_iter, 1);
					$plugin_value  = $model->get_value($plugin_iter, 2);
					$plugin_lang   = $model->get_value($plugin_iter, 3);
					$plugin_tip    = $model->get_value($plugin_iter, 4);
					$plugin_key    = $model->get_value($plugin_iter, 5);

					$plugin_descr->set_text($plugin_tip);
					if ($shf->file_exists($plugins{$plugin_key}->{'pixbuf'})) {
						$plugin_image->set_from_pixbuf($lp->load($plugins{$plugin_key}->{'pixbuf'}, 100, 100));
					}
				}
			});

		my $renderer_pix = Gtk3::CellRendererPixbuf->new;
		$plugin->pack_start($renderer_pix, FALSE);
		$plugin->add_attribute($renderer_pix, pixbuf => 0);
		my $renderer_text = Gtk3::CellRendererText->new;
		$plugin->pack_start($renderer_text, FALSE);
		$plugin->add_attribute($renderer_text, text => 1);

		#we try to activate the last executed plugin if that's possible
		$plugin->set_active_iter($iter_lastex_plugin);

		$plugin_hbox1->pack_start($plugin, TRUE, TRUE, 0);

		$plugin_hbox2->pack_start($plugin_image, TRUE, TRUE, 0);
		$plugin_hbox2->pack_start($plugin_descr_frame, TRUE, TRUE, 0);

		$plugin_vbox1->pack_start($plugin_hbox1, FALSE, TRUE, 1);
		$plugin_vbox1->pack_start($plugin_hbox2, TRUE,  TRUE, 1);

		$plugin_dialog->get_child->add($plugin_vbox1);

		my $plugin_progress = Gtk3::ProgressBar->new;
		$plugin_progress->set_no_show_all(TRUE);
		$plugin_progress->set_ellipsize('middle');
		$plugin_progress->set_orientation('horizontal');
		$plugin_dialog->get_child->add($plugin_progress);

		$plugin_dialog->show_all;

		my $plugin_response = $plugin_dialog->run;

		if ($plugin_response eq 'accept') {

			#anything wrong with the selected plugin?
			unless ($plugin_value =~ /[a-zA-Z0-9]+/) {
				$sd->dlg_error_message($d->get("No plugin specified"), $d->get("Failed"));
				return FALSE;
			}

			#we save the last execution time
			#and try to preselect it when the plugin dialog is executed again
			$plugins{$plugin_key}->{'recent'} = time;

			#disable buttons and combobox
			$plugin->set_sensitive(FALSE);
			foreach my $dialog_child ($plugin_dialog->get_child->get_children) {
				$dialog_child->set_sensitive(FALSE)
					if $dialog_child =~ /Button/;
			}

			#show the progress bar
			$plugin_progress->show;
			$plugin_progress->set_fraction(0);
			fct_update_gui();
			my $counter = 1;

			#call execute_plugin for each file to be processed
			foreach my $key (@file_to_plugin_keys) {

				#update the progress bar and update gui to show changes
				#~ $plugin_progress->set_text($session_screens{$key}->{'long'});
				#~ $plugin_progress->set_fraction($counter / scalar @file_to_plugin_keys);
				#~ fct_update_gui();

				#store data
				my $data = [$plugin_value, $plugin_name, $plugin_lang, $key, $plugin_dialog, $plugin_progress];
				fct_execute_plugin(undef, $data);

				#increase counter and update gui to show updated progress bar
				$counter++;
			}

			$plugin_dialog->destroy();
			return TRUE;
		} else {
			$plugin_dialog->destroy();
			return FALSE;
		}
	}

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

	sub dlg_rename {
		my (@file_to_rename_keys) = @_;

		foreach my $key (@file_to_rename_keys) {

			my $input_dialog = Gtk3::MessageDialog->new($window, [qw/modal destroy-with-parent/], 'other', 'none', undef);

			$input_dialog->set_title($d->get("Rename"));

			$input_dialog->set('image' => Gtk3::Image->new_from_stock('gtk-save-as', 'dialog'));

			$input_dialog->set('text' => sprintf($d->get("Rename image %s"), "'$session_screens{$key}->{'short'}'"));

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

			fct_validate_filename($new_filename, $new_filename_hint);

			#parse filename
			my ($short, $folder, $ext) = fileparse($session_screens{$key}->{'long'}, qr/\.[^.]*/);

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
			$new_filename->set_text($session_screens{$key}->{'name'});
			if (length($new_filename->get_text)) {
				$rename_btn->set_sensitive(TRUE);
			} else {
				$rename_btn->set_sensitive(FALSE);
			}

			$new_filename_vbox->pack_start($new_filename, TRUE, TRUE, 0);
			$new_filename_vbox->pack_start($new_filename_hint, TRUE, TRUE, 0);
			$input_dialog->get_child->add($new_filename_vbox);
			$input_dialog->show_all;

			#run dialog
			my $input_response = $input_dialog->run;

			#handle user responses here
			if ($input_response eq 'accept') {

				my $new_name = $new_filename->get_text;
				$new_name = $session_screens{$key}->{'folder'} . "/" . $new_name . "." . $session_screens{$key}->{'filetype'};

				#create uris for following action (e.g. update tab, move etc.)
				my $new_giofile = Glib::IO::File::new_for_path($new_name);
				my $old_giofile = $session_screens{$key}->{'giofile'};

				if ($new_giofile) {

					#filenames eq? -> nothing to do here
					unless ($session_screens{$key}->{'long'} eq $new_name) {

						#does the "renamed" file already exists?
						unless ($shf->file_exists($new_name)) {

							#ok => rename it

							#cancel handle
							if (exists $session_screens{$key}->{'handle'}) {

								$session_screens{$key}->{'handle'}->cancel;
							}

							eval { $old_giofile->move($new_giofile, []); };
							if ($@) {
								my $response = $sd->dlg_error_message(
									sprintf($d->get("Error while renaming the image %s."),           "'" . $old_giofile->get_basename . "'"),
									sprintf($d->get("There was an error renaming the image to %s."), "'" . $new_giofile->get_basename . "'"),
									undef, undef, undef, undef, undef, undef, $@
								);

							}
							fct_update_tab($key, undef, $new_giofile, FALSE, 'block');

							#setup a new filemonitor, so we get noticed if the file changed
							fct_add_file_monitor($key);

							fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("renamed"));

							#change window title
							#~ $window->set_title($session_screens{$key}->{'long'}." - ".SHUTTER_NAME);

						} else {

							#ask the user to replace the image
							#replace button
							my $replace_btn = Gtk3::Button->new_with_mnemonic($d->get("_Replace"));
							$replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

							my $sd = Shutter::App::SimpleDialogs->new;

							my $response = $sd->dlg_warning_message(
								sprintf($d->get("The image already exists in %s. Replacing it will overwrite its contents."), "'" . $new_giofile->extract_dirname . "'"),
								sprintf($d->get("An image named %s already exists. Do you want to replace it?"),              "'" . $new_giofile->get_basename . "'"),
								undef, undef, undef, $replace_btn, undef, undef
							);

							#rename == replace_btn was hit
							if ($response == 40) {

								#ok => rename it

								#cancel handle
								if (exists $session_screens{$key}->{'handle'}) {

									$session_screens{$key}->{'handle'}->cancel;
								}

								eval { $old_giofile->move($new_giofile, ['overwrite']); };
								if ($@) {
									my $response = $sd->dlg_error_message(
										sprintf($d->get("Error while renaming the image %s."),           "'" . $old_giofile->get_basename . "'"),
										sprintf($d->get("There was an error renaming the image to %s."), "'" . $new_giofile->get_basename . "'"),
										undef, undef, undef, undef, undef, undef, $@
									);
								}
								fct_update_tab($key, undef, $new_giofile, FALSE, 'block');

								#setup a new filemonitor, so we get noticed if the file changed
								fct_add_file_monitor($key);

								fct_show_status_message(1, $session_screens{$key}->{'long'} . " " . $d->get("renamed"));

								#change window title
								#~ $window->set_title($session_screens{$key}->{'long'}." - ".SHUTTER_NAME);

								#maybe file is in session as well, need to set the handler again ;-)
								foreach my $searchkey (keys %session_screens) {
									next if $key eq $searchkey;
									if ($session_screens{$searchkey}->{'long'} eq $new_name) {

										#cancel handle
										if (exists $session_screens{$searchkey}->{'handle'}) {

											$session_screens{$searchkey}->{'handle'}->cancel;
										}

										fct_update_tab($searchkey, undef, $new_giofile, FALSE, 'block');

										#setup a new filemonitor, so we get noticed if the file changed
										fct_add_file_monitor($searchkey);

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

	}

	sub dlg_save_as {

		#mandatory
		my $key = shift;

		#optional
		my $rfiletype = shift;
		my $rfilename = shift;
		my $rpixbuf   = shift;
		my $rquality  = shift;

		$rfilename = $session_screens{$key}->{'long'} if $key;

		my $fs = Gtk3::FileChooserDialog->new(
			$d->get("Choose a location to save to"),
			$window, 'save',
			'gtk-cancel' => 'reject',
			'gtk-save'   => 'accept'
		);

		#parse filename
		my ($short, $folder, $ext) = fileparse($rfilename, qr/\.[^.]*/);

		#go to recently used folder
		if (defined $sc->get_rusf && $shf->folder_exists($sc->get_rusf)) {
			$fs->set_current_folder($sc->get_rusf);
			$fs->set_current_name($short . $ext);
		} elsif (defined $key
			&& defined $session_screens{$key}->{'is_unsaved'}
			&& $session_screens{$key}->{'is_unsaved'})
		{
			$fs->set_current_folder($saveDir_button->get_current_folder);
			$fs->set_current_name($short . $ext);
		} else {
			$fs->set_current_folder($folder);
			$fs->set_current_name($short . $ext);
		}

		#preview widget
		my $iprev = Gtk3::Image->new;
		$fs->set_preview_widget($iprev);

		$fs->signal_connect(
			'selection-changed' => sub {
				if (my $pfilename = $fs->get_preview_filename) {

					#without error dialog
					my $pixbuf = $lp_ne->load($pfilename, 200, 200, TRUE, TRUE);
					unless (defined $pixbuf) {
						$fs->set_preview_widget_active(FALSE);
					} else {
						$fs->get_preview_widget->set_from_pixbuf($pixbuf);
						$fs->set_preview_widget_active(TRUE);
					}
				} else {
					$fs->set_preview_widget_active(FALSE);
				}
			});

		#change extension related to the requested filetype
		if (defined $rfiletype && defined $rfilename) {
			my ($short, $folder, $ext) = fileparse($rfilename, qr/\.[^.]*/);
			$fs->set_current_name($short . "." . $rfiletype);
		}

		my $extra_hbox = Gtk3::HBox->new;

		my $label_save_as_type = Gtk3::Label->new($d->get("Image format") . ":");

		my $combobox_save_as_type = Gtk3::ComboBoxText->new;

		#add supported formats to combobox
		my $counter     = 0;
		my $png_counter = undef;

		#add pdf support
		if (defined $rfiletype && $rfiletype eq 'pdf') {

			$combobox_save_as_type->insert_text($counter, "pdf - Portable Document Format");
			$combobox_save_as_type->set_active(0);

		} elsif (defined $rfiletype && $rfiletype eq 'ps') {

			$combobox_save_as_type->insert_text($counter, "ps - PostScript");
			$combobox_save_as_type->set_active(0);

			#images
		} else {

			foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {

				#we don't want svg here - this is a dedicated action in the DrawingTool
				next if !defined $rfiletype && $format->get_name =~ /svg/;

				#we have a requested filetype - nothing else will be offered
				next if defined $rfiletype && $format->get_name ne $rfiletype;

				#we want jpg not jpeg
				if ($format->get_name eq "jpeg" || $format->get_name eq "jpg") {
					$combobox_save_as_type->insert_text($counter, "jpg" . " - " . $format->get_description);
				} else {
					$combobox_save_as_type->insert_text($counter, $format->get_name . " - " . $format->get_description);
				}

				#set active when mime_type is matching
				#loop because multiple mime types are registered for fome file formats
				foreach my $mime (@{$format->get_mime_types}) {

					if (defined $key) {
						if ($mime eq $session_screens{$key}->{'mime_type'}
							|| defined $rfiletype)
						{
							$combobox_save_as_type->set_active($counter);
						}
					} else {

						#Fix Bug #966159
						if (defined $rfilename) {
							my ($short, $folder, $ext) = fileparse($rfilename, qr/\.[^.]*/);
							if ($mime eq "image/jpeg" && $ext eq ".jpg"
								|| $mime eq "image/png" && $ext eq ".png"
								|| $mime eq "image/bmp" && $ext eq ".bmp"
								|| $mime eq "image/webp" && $ext eq ".webp"
								|| $mime eq "image/avif" && $ext eq ".avif") {
								$combobox_save_as_type->set_active($counter);
							}
						}
					}

					#save png_counter as well as fallback
					$png_counter = $counter if $mime eq 'image/png';
				}

				$counter++;

			}

		}

		#something went wrong here
		#filetype was not detected automatically
		#set to png as default
		unless ($combobox_save_as_type->get_active_text) {
			if (defined $png_counter) {
				$combobox_save_as_type->set_active($png_counter);
			}
		}

		$combobox_save_as_type->signal_connect(
			'changed' => sub {
				my $filename = $shf->utf8_decode($fs->get_filename);

				my $choosen_format = $combobox_save_as_type->get_active_text;
				$choosen_format =~ s/ \-.*//;    #get png or jpeg (jpg) for example
												#~ print $choosen_format . "\n";

				#parse filename
				my ($short, $folder, $ext) = fileparse($filename, qr/\.[^.]*/);

				$fs->set_current_name($short . "." . $choosen_format);
			});

		#emit the signal once in order to invoke the sub above
		#~ $combobox_save_as_type->signal_emit('changed');

		$extra_hbox->pack_start($label_save_as_type,    FALSE, FALSE, 5);
		$extra_hbox->pack_start($combobox_save_as_type, FALSE, FALSE, 5);

		my $align_save_as_type = Gtk3::Alignment->new(1, 0, 0, 0);

		$align_save_as_type->add($extra_hbox);
		$align_save_as_type->show_all;

		$fs->set_extra_widget($align_save_as_type);

		my $fs_resp = $fs->run;

		if ($fs_resp eq "accept") {
			my $filename = $shf->utf8_decode($fs->get_filename);

			#parse filename
			my ($short, $folder, $ext) = fileparse($filename, qr/\.[^.]*/);

			#keep selected folder in mind
			$sc->set_rusf($folder);

			#handle file format
			my $choosen_format = $combobox_save_as_type->get_active_text;
			$choosen_format =~ s/ \-.*//;    #get png or jpeg (jpg) for example

			$filename = $folder . $short . "." . $choosen_format;

			unless ($shf->file_exists($filename)) {

				#get pixbuf from param
				my $pixbuf = $rpixbuf;
				unless ($pixbuf) {

					#or load pixbuf from existing file
					$pixbuf = $lp_ne->load($rfilename);
				}

				#save as (pixbuf, new_filename, filetype, quality - auto here, old_filename)
				if ($sp->save_pixbuf_to_file($pixbuf, $filename, $choosen_format, $rquality)) {

					if ($key) {

						#do not try to update when exporting to pdf or ps
						unless (defined $rfiletype
							&& ($rfiletype eq 'pdf' || $rfiletype eq 'ps'))
						{

							#cancel handle
							if (exists $session_screens{$key}->{'handle'}) {

								$session_screens{$key}->{'handle'}->cancel;
							}
							if (fct_update_tab($key, undef, Glib::IO::File::new_for_path($filename), FALSE, 'clear')) {

								#setup a new filemonitor, so we get noticed if the file changed
								fct_add_file_monitor($key);

								fct_show_status_message(1, "$session_screens{ $key }->{ 'long' } " . $d->get("saved"));
							}

						} else {
							if ($shf->file_exists($filename)) {
								fct_show_status_message(1, "$filename " . $d->get("saved"));
							}
						}

					}

					#successfully saved
					$fs->destroy();
					return $filename;

				} else {

					#error while saving
					$fs->destroy();
					return FALSE;

				}

			} else {

				#ask the user to replace the image
				#replace button
				my $replace_btn = Gtk3::Button->new_with_mnemonic($d->get("_Replace"));
				$replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

				my $response = $sd->dlg_warning_message(
					sprintf($d->get("The image already exists in %s. Replacing it will overwrite its contents."), "'" . $folder . "'"),
					sprintf($d->get("An image named %s already exists. Do you want to replace it?"),              "'" . $short . "." . $choosen_format . "'"),
					undef, undef, undef, $replace_btn, undef, undef
				);

				if ($response == 40) {

					#get pixbuf from param
					my $pixbuf = $rpixbuf;
					unless ($pixbuf) {

						#or load pixbuf from existing file
						$pixbuf = $lp_ne->load($rfilename);
					}

					if ($sp->save_pixbuf_to_file($pixbuf, $filename, $choosen_format, $rquality)) {

						if ($key) {

							#do not try to update when exporting to pdf
							unless (defined $rfiletype
								&& ($rfiletype eq 'pdf' || $rfiletype eq 'ps'))
							{

								#cancel handle
								if (exists $session_screens{$key}->{'handle'}) {

									$session_screens{$key}->{'handle'}->cancel;
								}

								if (fct_update_tab($key, undef, Glib::IO::File::new_for_path($filename), FALSE, 'clear')) {

									#setup a new filemonitor, so we get noticed if the file changed
									fct_add_file_monitor($key);

									#maybe file is in session as well, need to set the handler again ;-)
									foreach my $searchkey (keys %session_screens) {
										next if $key eq $searchkey;
										if ($session_screens{$searchkey}->{'long'} eq $filename) {
											$session_screens{$searchkey}->{'changed'} = TRUE;
											fct_update_tab($searchkey, undef, undef, FALSE, 'clear');
										}
									}

									fct_show_status_message(1, "$session_screens{ $key }->{ 'long' } " . $d->get("saved"));

								}

							} else {
								if ($shf->file_exists($filename)) {
									fct_show_status_message(1, "$filename " . $d->get("saved"));
								}
							}

						}    #end if $key

						#successfully saved
						$fs->destroy();
						return $filename;

					} else {

						#error while saving
						$fs->destroy();
						return FALSE;

					}

				} else {

					#user cancelled overwrite
					$fs->destroy();
					return 'user_cancel';

				}

			}

		} else {

			#user cancelled
			$fs->destroy();
			return 'user_cancel';
		}

		$fs->destroy();

	}

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
