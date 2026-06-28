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

package Shutter::App::Handlers::Workflow_Save;

use utf8;
use v5.40;
use Shutter::App::Core::FileSystemAPI;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Log::Any;

my $log = Log::Any->get_logger;

has cli => (is => 'ro', required => 1);

sub fct_load_settings ($self, $data, $profilename) {
	my $cli = $self->cli;
	my $d   = $cli->sc->gettext_object;

	my $settings_xml = $cli->settings_manager->load_settings($profilename);

	if (defined $profilename && $profilename ne "") {
		$self->cli->handlers->get('Init_Accounts')->fct_load_accounts($profilename);
	}

	if ($settings_xml && %{$settings_xml}) {
		$cli->handlers->get('UI_Status')->fct_show_status_message(1, $d->get("Settings loaded successfully"));
	}

	return $settings_xml;
}

sub fct_save_settings ($self, $profilename = undef) {
	my $cli = $self->cli;
	my $d   = $cli->sc->gettext_object;

	if (!defined $cli->settings_manager) {
		$log->error('SettingsManager is not initialized; cannot save settings');
		return FALSE;
	}

	my $saved = $cli->settings_manager->save_settings($profilename);
	if (!$saved) {
		$log->error('SettingsManager->save_settings returned FALSE');
		return FALSE;
	}

	$cli->handlers->get('UI_Status')->fct_show_status_message(1, $d->get("Settings saved successfully!"));
	return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Workflow_Save - Workflow save handlers

=head1 DESCRIPTION

Save and load application settings via Shutter::App::Core::SettingsManager.

The legacy bin/shutter version of these functions fanned out to ~60 widget
getters/setters; that approach is not portable to the Moo-based UI refactor.
Settings persistence now goes through the central SettingsManager, which
holds settings in a hashref updated via C<< $cli->settings_manager->set_setting >>
and serialized on save.

Custom uploaders (.sxcu) live on disk in the uploaders directory and are
loaded by SettingsManager::load_accounts on every startup, so they survive
without an explicit save path.
=cut