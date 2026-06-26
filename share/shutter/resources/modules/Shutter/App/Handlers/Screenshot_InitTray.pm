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

package Shutter::App::Handlers::Screenshot_InitTray;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_try_init_tray ($self) {
	my $cli = $self->cli;

	$cli->{_tray_legacy} = Gtk3::StatusIcon->new();
	$cli->{_tray_legacy}->set_from_icon_name("shutter-panel");
	$cli->{_tray_legacy}->set_visible(1);

	fct_update_gui() if defined &fct_update_gui;

	if ($cli->{_tray_legacy}->is_embedded) {
		if ($cli->{_tray_libappindicator}) {
			$cli->{_tray_libappindicator}->set_status('passive');
			$cli->{_tray_libappindicator} = undef;
		}
		$cli->{_tray} = $cli->{_tray_legacy};
		if (defined &evt_show_systray_statusicon) {
			$cli->{_tray}->{'hid'} = $cli->{_tray}->signal_connect('popup-menu' => sub { evt_show_systray_statusicon(@_, $cli->{_tray}) });
		}
		if (defined &evt_activate_systray_statusicon) {
			$cli->{_tray}->{'hid2'} = $cli->{_tray}->signal_connect(
				'activate' => sub {
					evt_activate_systray_statusicon(@_, $cli->{_tray});
					$cli->{_tray};
				});
		}
	} else {
		$cli->{_tray_legacy}->set_visible(0);
		$cli->{_tray_legacy} = undef;

		if ($cli->{_appindicator} && !$cli->{_tray_libappindicator}) {

			# Fallback to AppIndicator.
			$cli->{_tray_libappindicator} = AppIndicator::Indicator->new("Shutter", "shutter-panel", 'application-status') if defined &AppIndicator::Indicator::new;
			$cli->{_tray_libappindicator}->set_menu($cli->{_tray_menu})                                                    if $cli->{_tray_libappindicator};
			$cli->{_tray_libappindicator}->set_status('active')                                                            if $cli->{_tray_libappindicator};
		}

		if ($cli->{_tray_libappindicator}) {
			$cli->{_tray} = $cli->{_tray_libappindicator};
		} else {
			$cli->{_tray} = undef;
		}
	}
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Screenshot_InitTray - Screenshot tray initialization handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
