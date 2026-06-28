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
use Shutter::App::Core::FileSystemAPI;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Shutter::App::Directories;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub evt_about ($self) {
	Shutter::App::AboutDialog->new($self->cli->sc)->show;
	return;
}

sub evt_apply_profile ($self, $widget, $combobox_settings_profiles, $current_profiles_ref) {
	my $d = $self->cli->sc->gettext_object;

	if ($combobox_settings_profiles->get_active_text) {
		$self->cli->{_settings_xml}         = fct_load_settings('profile_load', $combobox_settings_profiles->get_active_text);
		$self->cli->{_current_profile_indx} = $combobox_settings_profiles->get_active;
		my $current_profile_text = $combobox_settings_profiles->get_active_text;

		fct_update_profile_selectors($combobox_settings_profiles, $current_profiles_ref, $widget);

		fct_update_info_and_tray();

		fct_show_status_message(1, sprintf($d->get("Profile %s loaded successfully"), "'" . $current_profile_text . "'"));
	}

	return TRUE;
}

sub evt_bug ($self) {
	$self->cli->shf->xdg_open(undef, "https://github.com/shutter-project/shutter/issues/new?labels=bug&template=bug_report.md", undef);
	return;
}

sub evt_delete_profile ($self, $widget, $combobox_settings_profiles, $current_profiles_ref) {
	my $shf = $self->cli->shf;
	my $d   = $self->cli->sc->gettext_object;
	my $sd  = $self->cli->sc->{_sd};

	if ($combobox_settings_profiles->get_active_text) {
		my $active_text  = $combobox_settings_profiles->get_active_text;
		my $active_index = $combobox_settings_profiles->get_active;
		Shutter::App::Core::FileSystemAPI->new->remove(Shutter::App::Directories::get_profile_settings_file($active_text));
		Shutter::App::Core::FileSystemAPI->new->remove(Shutter::App::Directories::get_profile_accounts_file($active_text));

		unless ($shf->file_exists(Shutter::App::Directories::get_profile_settings_file($active_text))
			|| $shf->file_exists(Shutter::App::Directories::get_profile_accounts_file($active_text)))
		{
			$combobox_settings_profiles->remove($active_index);
			$combobox_settings_profiles->set_active($combobox_settings_profiles->get_active + 1);
			$self->cli->{_current_profile_indx} = $combobox_settings_profiles->get_active;

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

sub evt_delete_window ($self, $widget, $data, $scounter) {
	my $sc                    = $self->cli->sc;
	my $close_at_close_active = $self->cli->{_close_at_close_active};
	my $tray                  = $self->cli->{_tray};
	my $window                = $self->cli->window;

	print "\n$data was emitted by widget $widget\n"
		if $sc->debug;

	if (   $data ne "quit"
		&& $close_at_close_active
		&& $close_at_close_active->get_active
		&& $tray)
	{
		$window->hide;
		$self->cli->{_is_hidden} = TRUE;
		return TRUE;
	}

	# Use a weak reference to self in the idle callback
	my $weak_self = $self;

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

			my $session_start_screen = $weak_self->cli->{_session_start_screen};

			while (defined $session_start_screen->{'first_page'}->{'num_session_files'} && $scounter <= 15) {
				$scounter++;

				#try again in a second
				Glib::Timeout->add(
					1000,
					sub {
						$weak_self->evt_delete_window('', 'quit', $scounter);
						return FALSE;
					});
				return FALSE;
			}

			#save settings
			fct_save_settings(undef);

			my $combobox_settings_profiles = $weak_self->cli->{_combobox_settings_profiles};
			if ($combobox_settings_profiles && $combobox_settings_profiles->get_active != -1) {
				fct_save_settings($combobox_settings_profiles->get_active_text);
			}

			#autostart
			my $sas             = $weak_self->cli->sc->{_sas};
			my $fs_active       = $weak_self->cli->{_fs_active};
			my $fs_min_active   = $weak_self->cli->{_fs_min_active};
			my $fs_nonot_active = $weak_self->cli->{_fs_nonot_active};

			if ($sas && $fs_active && $fs_min_active && $fs_nonot_active) {
				$sas->create_autostart_file(Shutter::App::Directories::get_autostart_dir(), $fs_active->get_active, $fs_min_active->get_active, $fs_nonot_active->get_active);
			}

			$weak_self->cli->app->quit;

			return FALSE;
		});

	return TRUE;
}

sub evt_page_setup ($self, $widget, $data) {
	my $shf       = $self->cli->shf;
	my $window    = $self->cli->window;
	my $pagesetup = $self->cli->{_pagesetup};

	#restore settings if prossible
	my $ssettings = Gtk3::PrintSettings->new;
	if ($shf->file_exists(Shutter::App::Directories::get_printing_file())) {
		eval { $ssettings = Gtk3::PrintSettings->new_from_file(Shutter::App::Directories::get_printing_file()); };
	}

	($pagesetup) = Glib::Object::Introspection->invoke('Gtk', undef, 'print_run_page_setup_dialog', $window, $pagesetup, $ssettings);
	$self->cli->{_pagesetup} = $pagesetup;

	return TRUE;
}

sub evt_question ($self) {
	$self->cli->shf->xdg_open(undef, "https://shutter-project.org/faq-help/", undef);
	return;
}

sub evt_save_as ($self, $widget, $data) {
	my $sc                   = $self->cli->sc;
	my $session_start_screen = $self->cli->{_session_start_screen};

	print "\n$data was emitted by widget $widget\n"
		if $sc->debug;

	my $key = fct_get_current_file();

	my @save_as_files;

	#single file
	if ($key) {
		push @save_as_files, $key;

		#session tab
	} elsif ($session_start_screen && $session_start_screen->{'first_page'} && $session_start_screen->{'first_page'}->{'view'}) {
		$session_start_screen->{'first_page'}->{'view'}->selected_foreach(
			sub {
				my ($view, $path) = @_;
				my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
				if (defined $iter) {
					my $key = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
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

sub evt_save_profile ($self, $widget, $combobox_settings_profiles, $current_profiles_ref) {
	my $curr_profile_name = $combobox_settings_profiles->get_active_text || "";
	my $new_profile_name  = dlg_profile_name($curr_profile_name, $combobox_settings_profiles);

	if ($new_profile_name) {
		if ($curr_profile_name ne $new_profile_name) {
			$combobox_settings_profiles->prepend_text($new_profile_name);
			$combobox_settings_profiles->set_active(0);
			$self->cli->{_current_profile_indx} = 0;

			#unshift to array as well
			unshift(@{$current_profiles_ref}, $new_profile_name);

			fct_update_profile_selectors($combobox_settings_profiles, $current_profiles_ref);
		}

		#save settings
		fct_save_settings($new_profile_name);

		#autostart
		my $sas             = $self->cli->sc->{_sas};
		my $fs_active       = $self->cli->{_fs_active};
		my $fs_min_active   = $self->cli->{_fs_min_active};
		my $fs_nonot_active = $self->cli->{_fs_nonot_active};

		if ($sas && $fs_active && $fs_min_active && $fs_nonot_active) {
			$sas->create_autostart_file(Shutter::App::Directories::get_autostart_dir(), $fs_active->get_active, $fs_min_active->get_active, $fs_nonot_active->get_active);
		}
	}
	return TRUE;
}

sub evt_show_settings ($self) {
	fct_check_installed_programs();

	my $settings_dialog = $self->cli->{_settings_dialog};
	if ($settings_dialog) {
		$settings_dialog->show_all;
		my $settings_dialog_response = $settings_dialog->run;

		fct_post_settings($settings_dialog);

		if ($settings_dialog_response eq "close") {
			return TRUE;
		} else {
			return FALSE;
		}
	}
	return FALSE;
}

sub evt_translate ($self) {
	$self->cli->shf->xdg_open(undef, "https://translations.launchpad.net/shutter", undef);
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Menu – Menu action handlers

=head1 DESCRIPTION

This module handles menu actions in Shutter.
It has been migrated to use the CLI object for state access instead of package globals.

=head1 METHODS

=head2 evt_about

Opens the About dialog.

=head2 evt_apply_profile

Applies the selected profile settings.

=head2 evt_bug

Opens the bug report page in the browser.

=head2 evt_delete_profile

Deletes the selected profile.

=head2 evt_delete_window

Handles the deletion/closing of the main window.

=head2 evt_page_setup

Opens the page setup dialog for printing.

=head2 evt_question

Opens the FAQ/Help page in the browser.

=head2 evt_save_as

Opens the save dialog for exporting files.

=head2 evt_save_profile

Saves the current settings as a new profile.

=head2 evt_show_settings

Shows the settings dialog.

=head2 evt_translate

Opens the translation page in the browser.

=cut
