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

package Shutter::App::Handlers::Workflow_Post;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_post_settings {
		my $settings_dialog = shift;

		#unset profile combobox when profile was not applied
		if ($current_profile_indx != $combobox_settings_profiles->get_active) {
			$combobox_settings_profiles->set_active($current_profile_indx);
		}

		if (defined $settings_dialog && $settings_dialog) {
			$settings_dialog->hide();
		}

		#save directly
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

		#we need to update the first tab here
		#because the profile might have changed
		fct_update_info_and_tray();

		return TRUE;
	}


1;
