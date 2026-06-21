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

package Shutter::Screenshot::Error;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try'; no warnings 'experimental::try';

#Glib
use Glib qw/TRUE FALSE/;

use Moo;

has '_sc' => (is => 'rw');
has '_code' => (is => 'rw');
has '_data' => (is => 'rw');
has '_extra' => (is => 'rw');

around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;
	if (@args == 4) {
		my ($sc, $code, $data, $extra) = @args;
		return $class->$orig(
			_sc => $sc,
			_code => $code,
			_data => $data,
			_extra => $extra,
		);
	}
	return $class->$orig(@args);
};

#--------------------------------------

sub get_error ($self) {
	return ($self->{_code}, $self->{_data}, $self->{_extra});
}

sub is_aborted_by_user ($self) {
	if (defined $self->{_code} && $self->{_code} == 5) {
		return TRUE;
	} else {
		return FALSE;
	}
}

sub is_error ($self) {
	if (defined $self->{_code} && $self->{_code} =~ /^\d+$/) {
		return TRUE;
	} else {
		return FALSE;
	}
}

sub set_error ($self, $code = undef, $data = undef, $extra = undef) {
	if (defined $code) {
		$self->{_code}  = $code;
		$self->{_data}  = $data;
		$self->{_extra} = $extra;
	}
	return ($self->{_code}, $self->{_data}, $self->{_extra});
}

sub show_dialog ($self, $detailed_error_text = '') {

	#load modules at custom path
	#--------------------------------------
	require lib;
	lib->import($self->{_sc}->get_root . "/share/shutter/resources/modules");
	require Shutter::App::SimpleDialogs;

	my $sd = Shutter::App::SimpleDialogs->new($self->{_sc}->get_mainwindow);

	#gettext
	my $d = $self->{_sc}->get_gettext;

	my $response;
	my $status_text = $d->get("Error while taking the screenshot.");

	#handle error codes
	if ($self->{_code} == 0) {

		#show error dialog
		my $response = $sd->dlg_error_message($d->get("Maybe mouse pointer could not be grabbed or the selected area is invalid."), $d->get("Error while taking the screenshot."));

		#keyboard could not be grabbed
	} elsif ($self->{_code} == 1) {

		$response = $sd->dlg_error_message($d->get("Keyboard could not be grabbed."), $d->get("Error while taking the screenshot."));

		#no window with type xy detected
	} elsif ($self->{_code} == 2) {

		my $type = undef;
		if ($self->{_data} eq "menu" || $self->{_data} eq "tray_menu") {
			$type = $d->get("menu");
		} elsif ($self->{_data} eq "tooltip" || $self->{_data} eq "tray_tooltip") {
			$type = $d->get("tooltip");
		}

		$response = $sd->dlg_error_message(sprintf($d->get("No window with type %s detected."), "'" . $type . "'"), $d->get("Error while taking the screenshot."));

		#no history object stored
	} elsif ($self->{_code} == 3) {

		$response = $sd->dlg_error_message($d->get("There is no last capture that can be redone."), $d->get("Error while taking the screenshot."));

		#window no longer available
	} elsif ($self->{_code} == 4) {

		$response = $sd->dlg_error_message($d->get("The window is no longer available."), $d->get("Error while taking the screenshot."));

		#user aborted screenshot
	} elsif ($self->{_code} == 5) {

		$status_text = $d->get("Capture aborted by user");

		#gnome-web-photo failed
	} elsif ($self->{_code} == 6) {

		$response = $sd->dlg_error_message($d->get("Unable to capture website"), $d->get("Error while taking the screenshot."), undef, undef, undef, undef, undef, undef, $detailed_error_text);

		$status_text = $d->get("Unable to capture website");

		#no window with name $pattern detected
	} elsif ($self->{_code} == 7) {

		my $name_pattern = $self->{_extra};

		$response = $sd->dlg_error_message(sprintf($d->get("No window with name pattern %s detected."), "'" . $name_pattern . "'"), $d->get("Error while taking the screenshot."));

		#invalid pattern
	} elsif ($self->{_code} == 8) {

		my $name_pattern = $self->{_extra};

		$response = $sd->dlg_error_message(
			sprintf($d->get("Invalid pattern %s detected."), "'" . $name_pattern . "'"),
			$d->get("Error while taking the screenshot."),
			undef, undef, undef, undef, undef, undef, $detailed_error_text
		);

	} elsif ($self->{_code} == 9) {
		$response = $sd->dlg_error_message($d->get("Unable to capture"), $d->get("Error while taking the screenshot."), undef, undef, undef, undef, undef, undef, $detailed_error_text);
	}

	return ($response, $status_text);
}

1;
