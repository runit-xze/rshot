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

package Shutter::App::Handlers::Dialogs_Save;

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


1;
