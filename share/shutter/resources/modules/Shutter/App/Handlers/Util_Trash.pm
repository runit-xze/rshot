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

package Shutter::App::Handlers::Util_Trash;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_unlink_tempfiles {
		my $key = shift;

		foreach my $tmpf (@{$session_screens{$key}->{'undo'}}) {
			unlink $tmpf;
		}

		foreach my $tmpf (@{$session_screens{$key}->{'redo'}}) {
			unlink $tmpf;
		}

		return TRUE;
	}

	sub fct_validate_filename{
		my $myfilename	= shift;
		my $myfilename_hint	= shift;
		my @invalid_codes = (47, 92);
		$myfilename->signal_connect(
			'key-press-event' => sub {
				shift;
				my $event = shift;

				my $input = Gtk3::Gdk::keyval_to_unicode($event->keyval);

				#invalid input
				#~ print $input."\n";
				if (grep($input == $_, @invalid_codes)) {
					my $char = chr($input);
					$char = 'amp();' if $char eq '&';
					$myfilename_hint->set_markup("<span size='small'>" . sprintf($d->get("Reserved character %s is not allowed to be in a filename."), "'" . $char . "'") . "</span>");
					return TRUE;
				} else {

					#clear possible message when valid char is entered
					$myfilename_hint->set_markup("<span size='small'></span>");
					return FALSE;
				}
			});
	}


1;
