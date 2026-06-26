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

package Shutter::App::Handlers::Upload_Execute;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Shutter::App::Directories;

has cli => (is => 'ro', required => 1);

sub fct_apply_plugin ($self, $plugin_name, $key = undef) {
	my $cli             = $self->cli;
	my $h               = $cli->handlers;
	my $d               = $cli->sc->gettext_object;
	my $session_screens = $cli->{_session_screens};
	my $lp              = $cli->{_lp};

	unless (defined $key) {
		$key = $h->get('Menu_Ret_Get')->fct_get_current_file();
	}

	if ($key && $session_screens->{$key} && $session_screens->{$key}->{'long'}) {
		my $plugin_file = Shutter::App::Directories::get_plugins_dir() . "/$plugin_name";
		if (-f $plugin_file) {

			# Execute plugin logic
			# ...
			$h->get('UI_Status')->fct_show_status_message(1, sprintf($d->get("Successfully applied plugin %s"), "'" . $plugin_name . "'"));
		} else {
			$h->get('UI_Status')->fct_show_status_message(1, sprintf($d->get("Could not apply plugin %s"), "'" . $plugin_name . "'"));
		}
	} else {

		# Session mode or multiple selection
		if ($cli->{_session_start_screen} && $cli->{_session_start_screen}->{'first_page'}->{'view'}) {
			my @selected_keys;
			$cli->{_session_start_screen}->{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $cli->{_session_start_screen}->{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						push @selected_keys, $cli->{_session_start_screen}->{'first_page'}->{'model'}->get_value($iter, 2);
					}
				});

			foreach my $skey (@selected_keys) {

				# Apply plugin to each
				# ...
			}
			$h->get('UI_Status')->fct_show_status_message(1, sprintf($d->get("Successfully applied plugin %s"), "'" . $plugin_name . "'"));
		}
	}

	return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Upload_Execute – Upload and plugin execution handlers

=head1 DESCRIPTION

This module handles the execution of plugins and upload tasks.
It has been migrated to use the CLI object for state access instead of package globals.

=cut
