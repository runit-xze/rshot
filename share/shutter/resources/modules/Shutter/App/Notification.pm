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

package Shutter::App::Notification;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try'; no warnings 'experimental::try';

use Net::DBus;
use Log::Any;

#Glib
use Glib qw/TRUE FALSE/;

#--------------------------------------

my $log = Log::Any->get_logger;

sub new ($class) {

	my $self = {};

	#Use notifications object
	try {
		$self->{_notifications_service} = Net::DBus->session->get_service('org.freedesktop.Notifications');
		$self->{_notifications_object}  = $self->{_notifications_service}->get_object('/org/freedesktop/Notifications', 'org.freedesktop.Notifications');
	}
	catch ($e) {
		$log->warn("Warning: $e");
	}

	#last nid
	$self->{_nid} = 0;

	bless $self, $class;
	return $self;
}

sub show ($self, $summary, $body, $nid = undef) {
	$nid //= $self->{_nid};

	#notification
	try {
		if (defined $self->{_notifications_object}) {
			$self->{_nid} = $self->{_notifications_object}->Notify('Shutter', $nid, "gtk-dialog-info", $summary, $body, [], {}, -1);
		}
	}
	catch ($e) {
		$log->warn("NotifyWarning: $e");
	}

	return $self->{_nid};
}

sub close ($self, $nid = undef) {
	$nid //= $self->{_nid};

	#close notification
	if ($nid) {
		try {
			if (defined $self->{_notifications_object}) {
				$self->{_notifications_object}->CloseNotification($nid);
			}
		}
		catch ($e) {
			$log->warn("CloseNotificationWarning: $e");
		}
		return TRUE;
	}

	return FALSE;
}

1;
