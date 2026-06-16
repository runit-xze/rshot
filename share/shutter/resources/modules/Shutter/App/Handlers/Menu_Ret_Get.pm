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

package Shutter::App::Handlers::Menu_Ret_Get;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_get_current_file {

		#get current page
		my $curr_page = $notebook->get_nth_page($notebook->get_current_page);

		my $key = undef;

		#and loop through hash to find the corresponding key
		if ($curr_page) {
			foreach my $ckey (keys %session_screens) {
				next unless (exists $session_screens{$ckey}->{'tab_child'});
				if ($session_screens{$ckey}->{'tab_child'} == $curr_page) {
					$key = $ckey;
					last;
				}
			}
		}

		return $key;
	}

	sub fct_get_latest_tab_key {
		my $max_key = 0;
		foreach my $key (keys %session_screens) {
			$key =~ /\[(\d+)\]/;
			$max_key = $1 if ($1 > $max_key);
		}
		return $max_key + 1;
	}


1;
