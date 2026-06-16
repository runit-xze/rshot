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

	sub fct_try_init_tray {
		$tray_legacy = Gtk3::StatusIcon->new();
		$tray_legacy->set_from_icon_name("shutter-panel");
		$tray_legacy->set_visible(1);

		fct_update_gui();

		if ($tray_legacy->is_embedded) {
			if ($tray_libappindicator) {
				$tray_libappindicator->set_status('passive');
				$tray_libappindicator = undef;
			}
			$tray = $tray_legacy;
			$tray->{'hid'} = $tray->signal_connect(
				'popup-menu' => sub { evt_show_systray_statusicon(@_); },
				$tray
			);
			$tray->{'hid2'} = $tray->signal_connect(
				'activate' => sub {
					evt_activate_systray_statusicon(@_);
					$tray;
				},
				$tray
			);
		} else {
			$tray_legacy->set_visible(0);
			$tray_legacy = undef;

			if ($appindicator && !$tray_libappindicator) {
				# Fallback to AppIndicator. This one doesn't allow left-click signal, but it seems to be the only option for Gnome on Ubuntu 21.04...
				$tray_libappindicator = AppIndicator::Indicator->new("Shutter", "shutter-panel", 'application-status');
				$tray_libappindicator->set_menu($tray_menu);
				$tray_libappindicator->set_status('active');
			}

			if ($tray_libappindicator) {
				$tray = $tray_libappindicator;
			} else {
				$tray = undef;
			}
		}
	}


1;
