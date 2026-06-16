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

package Shutter::App::Handlers::Menu;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub evt_about {
		Shutter::App::AboutDialog->new($sc)->show;
	}

	sub evt_apply_profile {
		my ($widget, $combobox_settings_profiles, $current_profiles_ref) = @_;

		if ($combobox_settings_profiles->get_active_text) {
			$settings_xml         = fct_load_settings('profile_load', $combobox_settings_profiles->get_active_text);
			$current_profile_indx = $combobox_settings_profiles->get_active;
			my $current_profile_text = $combobox_settings_profiles->get_active_text;

			fct_update_profile_selectors($combobox_settings_profiles, $current_profiles_ref, $widget);

			fct_update_info_and_tray();

			fct_show_status_message(1, sprintf($d->get("Profile %s loaded successfully"), "'" . $current_profile_text . "'"));
		}

		return TRUE;
	}

	sub evt_bug {
		$shf->xdg_open(undef, "https://github.com/shutter-project/shutter/issues/new?labels=bug&template=bug_report.md", undef);
	}

	sub evt_delete_profile {
		my ($widget, $combobox_settings_profiles, $current_profiles_ref) = @_;
		if ($combobox_settings_profiles->get_active_text) {
			my $active_text  = $combobox_settings_profiles->get_active_text;
			my $active_index = $combobox_settings_profiles->get_active;
			unlink("$ENV{'HOME'}/.shutter/profiles/" . $active_text . ".xml");
			unlink("$ENV{'HOME'}/.shutter/profiles/" . $active_text . "_accounts.xml");

			unless ($shf->file_exists("$ENV{'HOME'}/.shutter/profiles/" . $active_text . ".xml")
				|| $shf->file_exists("$ENV{'HOME'}/.shutter/profiles/" . $active_text . "_accounts.xml"))
			{
				$combobox_settings_profiles->remove($active_index);
				$combobox_settings_profiles->set_active($combobox_settings_profiles->get_active + 1);
				$current_profile_indx = $combobox_settings_profiles->get_active;

				#remove from array as well
				splice(@{$current_profiles_ref}, $active_index, 1);

				fct_update_profile_selectors($combobox_settings_profiles, $current_profiles_ref);

				fct_show_status_message(1, $d->get("Profile deleted"));
			} else {
				$sd->dlg_error_message($d->get("Profile could not be deleted"), $d->get("Failed"));
				fct_show_status_message(1, $d->get("Profile could not be deleted"));
			}
		}
		return TRUE;
	}

	sub evt_delete_window {
		my ($widget, $data, $scounter) = @_;
		print "\n$data was emitted by widget $widget\n"
			if $sc->get_debug;

		if (   $data ne "quit"
			&& $close_at_close_active->get_active
			&& $tray)
		{
			$window->hide;
			$is_hidden = TRUE;
			return TRUE;
		}

		Glib::Idle->add(
			sub {

				#hide window and block sontrols
				$window->hide;
				fct_control_signals('block');

				#wait if there are still files that need to be loaded
				#they would not be saved in session
				unless (defined $scounter) {
					$scounter = 0;
				}
				while (defined $session_start_screen{'first_page'}->{'num_session_files'} && $scounter <= 15) {
					$scounter++;

					#try again in a second
					Glib::Timeout->add(
						1000,
						sub {
							evt_delete_window('', 'quit', $scounter);
							return FALSE;
						});
					return FALSE;
				}

				#save settings
				fct_save_settings(undef);
				fct_save_settings($combobox_settings_profiles->get_active_text)
					if $combobox_settings_profiles->get_active != -1;

				#autostart
				$sas->create_autostart_file(
					Shutter::App::Directories::get_autostart_dir(),
					$fs_active->get_active,
					$fs_min_active->get_active,
					$fs_nonot_active->get_active
				);

				$app->quit;

				return FALSE;
			});

		return TRUE;
	}

	sub evt_page_setup {
		my ($widget, $data) = @_;

		#restore settings if prossible
		my $ssettings = Gtk3::PrintSettings->new;
		if ($shf->file_exists("$ENV{ HOME }/.shutter/printing.xml")) {
			eval { $ssettings = Gtk3::PrintSettings->new_from_file("$ENV{ HOME }/.shutter/printing.xml"); };
		}

		($pagesetup) = Glib::Object::Introspection->invoke('Gtk', undef, 'print_run_page_setup_dialog', $window, $pagesetup, $ssettings);

		return TRUE;
	}

	sub evt_question {
		$shf->xdg_open(undef, "https://shutter-project.org/faq-help/", undef);
	}

	sub evt_save_as {
		my ($widget, $data) = @_;
		print "\n$data was emitted by widget $widget\n"
			if $sc->get_debug;

		my $key = fct_get_current_file();

		my @save_as_files;

		#single file
		if ($key) {

			push @save_as_files, $key;

			#session tab
		} else {

			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push @save_as_files, $key;
					}
				},
				undef
			);

		}

		#determine requested filetype
		my $rfiletype = undef;
		if ($data eq 'menu_export_svg') {
			$rfiletype = 'svg';
		} elsif ($data eq 'menu_export_ps') {
			$rfiletype = 'ps';
		} elsif ($data eq 'menu_export_pdf') {
			$rfiletype = 'pdf';
		}

		foreach my $file (@save_as_files) {
			dlg_save_as($file, $rfiletype);
		}

		return TRUE;

	}

	sub evt_save_profile {
		my ($widget, $combobox_settings_profiles, $current_profiles_ref) = @_;
		my $curr_profile_name = $combobox_settings_profiles->get_active_text
			|| "";
		my $new_profile_name = dlg_profile_name($curr_profile_name, $combobox_settings_profiles);

		if ($new_profile_name) {
			if ($curr_profile_name ne $new_profile_name) {
				$combobox_settings_profiles->prepend_text($new_profile_name);
				$combobox_settings_profiles->set_active(0);
				$current_profile_indx = 0;

				#unshift to array as well
				unshift(@{$current_profiles_ref}, $new_profile_name);

				fct_update_profile_selectors($combobox_settings_profiles, $current_profiles_ref);

			}

			#save settings
			fct_save_settings($new_profile_name);

			#autostart
			$sas->create_autostart_file(
				Shutter::App::Directories::get_autostart_dir(),
				$fs_active->get_active,
				$fs_min_active->get_active,
				$fs_nonot_active->get_active
			);
		}
		return TRUE;
	}

	sub evt_show_settings {
		fct_check_installed_programs();

		$settings_dialog->show_all;
		my $settings_dialog_response = $settings_dialog->run;

		fct_post_settings($settings_dialog);

		if ($settings_dialog_response eq "close") {
			return TRUE;
		} else {
			return FALSE;
		}
	}

	sub evt_translate {
		$shf->xdg_open(undef, "https://translations.launchpad.net/shutter", undef);
	}


1;
