###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
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
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package Shutter::Screenshot::WindowName;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Shutter::Screenshot::WindowXid;
use Data::Dumper;
use Moo;
extends 'Shutter::Screenshot::WindowXid';

#Glib and Gtk3
use Gtk3;
use Glib qw/TRUE FALSE/;

#--------------------------------------

#~ sub DESTROY {
#~ my $self = shift;
#~ print "$self dying at\n";
#~ }
#~

sub window_find_by_name ($self, $name_pattern) {

	my $active_workspace = $self->{_wnck_screen}->get_active_workspace;

	#cycle through all windows
	my $output = 7;
	foreach my $win (@{$self->{_wnck_screen}->get_windows_stacked}) {

		#ignore shutter window
		if ($self->{_sc}->get_mainwindow->get_window) {
			next if ($win->get_xid == $self->{_sc}->get_mainwindow->get_window->get_xid);
		}

		#check if window is on active workspace
		if ($active_workspace && $win->is_on_workspace($active_workspace)) {
			try {
				if ($win->get_name =~ m/$name_pattern/i) {
					$output = $self->window_by_xid($win->get_xid);
					last;
				}
			} catch ($e) {
				$output = 8;
				$self->{_error_text} = $e;
			}
		}
	}

	return $output;
}

1;
