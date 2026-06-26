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

package Shutter::Screenshot::Web;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use File::Temp qw/ tempfile tempdir /;

#timing issues
use Time::HiRes qw/ time usleep /;

use Shutter::Screenshot::History;

#Glib and Gtk3
use Gtk3;
use Glib qw/TRUE FALSE/;

use Moo;

has '_sc'      => (is => 'rw');
has '_timeout' => (is => 'rw');
has '_width'   => (is => 'rw');
has '_shf'     => (is => 'lazy', builder => 1);

sub _build__shf {
	my $self = shift;
	return Shutter::App::HelperFunctions->new($self->_sc);
}

around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;
	if (@args == 3) {
		my ($sc, $timeout, $width) = @args;
		return $class->$orig(
			_sc      => $sc,
			_timeout => $timeout,
			_width   => $width,
		);
	}
	return $class->$orig(@args);
};

#--------------------------------------

sub web ($self) {
	return FALSE;
}

sub dlg_website ($self, $url) {

	#gettext
	my $d = $self->{_sc}->gettext_object;

	my $website_dialog =
		Gtk3::MessageDialog->new($self->{_sc}->main_window, [qw/modal destroy-with-parent/], 'error', 'close', $d->get("Web capture is no longer supported because gnome-web-photo is obsolete."));
	$website_dialog->set_title("Shutter");
	$website_dialog->run;
	$website_dialog->destroy();

	return 6;
}

sub update_gui ($self) {

	while (Gtk3::events_pending()) {
		Gtk3::main_iteration();
	}
	Gtk3::Gdk::flush();

	return TRUE;
}

sub redo_capture ($self) {
	my $output = 3;
	if (defined $self->{_history}) {
		$output = $self->dlg_website($self->{_url});
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
