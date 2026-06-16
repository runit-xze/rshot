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

package Shutter::App::Handlers::Upload_SendMail;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_send {

		my $key = fct_get_current_file();

		my @files_to_send;
		unless ($key) {
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push(@files_to_send, $session_screens{$key}->{'long'});
					}

				});
		} else {
			push(@files_to_send, $session_screens{$key}->{'long'});
		}

		my $sendto_string = undef;
		foreach my $sendto_filename (@files_to_send) {
			$sendto_string .= "'$sendto_filename' ";
		}

		$shf->nautilus_sendto($sendto_string);

		return TRUE;
	}


1;
