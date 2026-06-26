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

package Shutter::App::Handlers::UI_Tabs;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_get_file_by_index ($self, $index) {
	my $cli             = $self->cli;
	my $notebook        = $cli->{_notebook};
	my $session_screens = $cli->{_session_screens};

	return unless $index && $notebook;

	#get current page
	my $curr_page = $notebook->get_nth_page($index);

	my $key = undef;

	#and loop through hash to find the corresponding key
	if ($curr_page) {
		foreach my $ckey (keys %$session_screens) {
			next unless exists $session_screens->{$ckey}->{'tab_child'};
			if ($session_screens->{$ckey}->{'tab_child'} == $curr_page) {
				$key = $ckey;
				last;
			}
		}
	}

	return $key;
}

sub fct_get_key_by_filename ($self, $filename) {
	my $session_screens = $self->cli->{_session_screens};

	return unless $filename;

	my $key = undef;

	#and loop through hash to find the corresponding key
	foreach my $ckey (keys %$session_screens) {
		next unless exists $session_screens->{$ckey}->{'long'};

		if ($session_screens->{$ckey}->{'long'} eq $filename) {
			$key = $ckey;
			last;
		}
	}

	return $key;
}

sub fct_get_key_by_pubfile ($self, $filename) {
	my $session_screens = $self->cli->{_session_screens};

	return unless $filename;

	my $key = undef;

	#and loop through hash to find the corresponding key
	foreach my $ckey (keys %$session_screens) {
		next unless exists $session_screens->{$ckey}->{'links'};
		next
			unless exists $session_screens->{$ckey}->{'links'}->{'ubuntu-one'};
		next
			unless exists $session_screens->{$ckey}->{'links'}->{'ubuntu-one'}->{'pubfile'};

		if ($session_screens->{$ckey}->{'links'}->{'ubuntu-one'}->{'pubfile'} eq $filename) {
			$key = $ckey;
			last;
		}
	}

	return $key;
}

sub fct_get_total_size_of_session ($self) {
	my $session_screens = $self->cli->{_session_screens};

	my $total_size = 0;
	foreach my $ckey (keys %$session_screens) {
		next unless $session_screens->{$ckey}->{'size'};
		$total_size += $session_screens->{$ckey}->{'size'};
	}
	return $total_size;
}

sub fct_update_profile_selectors ($self, $combobox_settings_profiles, $current_profiles_ref, $recur_widget) {
	my $cli       = $self->cli;
	my $tray_menu = $cli->{_tray_menu};
	my $sm        = $cli->{_sm};
	my $status    = $cli->{_status};
	my $d         = $cli->sc->gettext_object;

	#populate quick selector as well
	if (scalar @{$current_profiles_ref} > 0) {

		#tray menu
		if ($tray_menu) {
			foreach my $child ($tray_menu->get_children) {
				if ($child->get_name eq 'quicks') {
					$child->set_submenu(fct_ret_profile_menu($combobox_settings_profiles, $current_profiles_ref)) if defined &fct_ret_profile_menu;
					$child->set_sensitive(TRUE);
					last;
				}
			}
		}

		#main menu
		if ($sm->{_menuitem_quicks}) {
			$sm->{_menuitem_quicks}->set_submenu(fct_ret_profile_menu($combobox_settings_profiles, $current_profiles_ref, $sm->{_menuitem_quicks}->get_submenu)) if defined &fct_ret_profile_menu;
			$sm->{_menuitem_quicks}->set_sensitive(TRUE);
		}

		#and statusbar
		unless ($recur_widget
			&& $recur_widget eq $cli->{_combobox_status_profiles})
		{
			if (   defined $cli->{_combobox_status_profiles}
				&& defined $cli->{_combobox_status_profiles_label})
			{
				$cli->{_combobox_status_profiles_label}->destroy;
				$cli->{_combobox_status_profiles}->destroy;
			}

			$cli->{_combobox_status_profiles_label} = Gtk3::Label->new($d->get("Profile") . ":");
			$cli->{_combobox_status_profiles}       = Gtk3::ComboBoxText->new;
			$status->pack_start($cli->{_combobox_status_profiles_label}, FALSE, FALSE, 0) if $status;
			$status->pack_start($cli->{_combobox_status_profiles},       FALSE, FALSE, 0) if $status;

			foreach my $profile (@{$current_profiles_ref}) {
				$cli->{_combobox_status_profiles}->append_text($profile);
			}

			$cli->{_combobox_status_profiles}->set_active($combobox_settings_profiles->get_active);

			$cli->{_combobox_status_profiles}->signal_connect(
				'changed' => sub {
					my $widget = shift;

					$combobox_settings_profiles->set_active($widget->get_active);
					evt_apply_profile($widget, $combobox_settings_profiles, $current_profiles_ref) if defined &evt_apply_profile;

				});

			$status->show_all if $status;
		}

	} else {

		#tray menu
		if ($tray_menu) {
			foreach my $child ($tray_menu->get_children) {
				if ($child->get_name eq 'quicks') {
					$child->set_submenu(undef);
					$child->set_sensitive(FALSE);
					last;
				}
			}
		}

		#main menu
		if ($sm->{_menuitem_quicks}) {
			$sm->{_menuitem_quicks}->set_submenu(undef);
			$sm->{_menuitem_quicks}->set_sensitive(FALSE);
		}

		#and statusbar
		if (   defined $cli->{_combobox_status_profiles}
			&& defined $cli->{_combobox_status_profiles_label})
		{
			$cli->{_combobox_status_profiles_label}->destroy;
			$cli->{_combobox_status_profiles}->destroy;
			$cli->{_combobox_status_profiles_label} = undef;
			$cli->{_combobox_status_profiles}       = undef;
		}
	}
	return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::UI_Tabs - UI tabs handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
