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

package Shutter::Screenshot::SelectorAuto;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try'; no warnings 'experimental::try';

use Shutter::Screenshot::Main;
use Shutter::Screenshot::History;

use Data::Dumper;
use Moo;
extends 'Shutter::Screenshot::Main';

#Glib
use Glib qw/TRUE FALSE/;

#--------------------------------------

sub new ($class, $shutter_common, $include_cursor, $delay, $notify_timeout) {

	#call constructor of super class (shutter_common, include_cursor, delay, notify_timeout)
	my $self = $class->SUPER::new($shutter_common, $include_cursor, $delay, $notify_timeout);

	return $self;
}

sub select_auto ($self, $x, $y, $width, $height) {

	my $d = $self->{_sc}->get_gettext;

	my $output;
	if ($x>=0 && $y>=0 && $width && $height) {
		($output) = $self->get_pixbuf_from_drawable($self->{_root}, $x, $y, $width, $height);

		#section not valid
	} else {
		$output = 0;
	}

	#we don't have a useful string for wildcards (e.g. $name)
	if ($output =~ /Gtk3/) {
		$self->{_action_name} = $d->get("Selection");
	}

	#set history object
	if ($output) {
		$self->{_history} = Shutter::Screenshot::History->new($self->{_sc}, $self->{_root}, $x, $y, $width, $height);
	}

	return $output;
}

sub redo_capture ($self) {
	my $output = 3;
	if (defined $self->{_history}) {
		($output) = $self->get_pixbuf_from_drawable($self->{_history}->get_last_capture);
	}
	return $output;
}

sub get_history ($self) {
	return $self->{_history};
}

sub get_error_text ($self) {
	return $self->{_error_text};
}

sub get_action_name ($self) {
	return $self->{_action_name};
}

1;
