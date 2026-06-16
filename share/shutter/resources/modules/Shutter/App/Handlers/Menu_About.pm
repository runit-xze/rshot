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

package Shutter::App::Handlers::Menu_About;

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

	sub evt_bug {
		$shf->xdg_open(undef, "https://github.com/shutter-project/shutter/issues/new?labels=bug&template=bug_report.md", undef);
	}

	sub evt_question {
		$shf->xdg_open(undef, "https://shutter-project.org/faq-help/", undef);
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
