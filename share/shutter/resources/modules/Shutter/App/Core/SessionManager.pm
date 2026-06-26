###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2020-2021 Google LLC, contributed by Alexey Sokolov <sokolov@google.com>
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

package Shutter::App::Core::SessionManager;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib       qw/TRUE FALSE/;
use File::Copy qw/cp mv/;
use File::Spec;
use List::Util qw/max min/;

has '_common'               => (is => 'ro', required => 1);
has '_session_screens'      => (is => 'rw', default  => sub { {} });
has '_session_start_screen' => (is => 'rw', default  => sub { {} });

sub get_session_screens      { return $_[0]->{_session_screens} }
sub get_session_start_screen { return $_[0]->{_session_start_screen} }

sub integrate_screenshot ($self, $giofile, $pixbuf, $history, $count) {
	return $self->fct_integrate_screenshot_in_notebook($giofile, $pixbuf, $history, $count);
}

sub fct_integrate_screenshot_in_notebook ($self, $giofile, $pixbuf, $history, $count) {
	my $session_screens      = $self->_session_screens;
	my $session_start_screen = $self->_session_start_screen;
	my $sc                   = $self->_common;
	my $shf                  = $sc->get_helper_functions;
	my $sd                   = Shutter::App::SimpleDialogs->new($sc->main_window);
	my $d                    = $sc->gettext_object;

	return FALSE unless $giofile;
	unless ($giofile->query_exists) {
		fct_show_status_message(1, $giofile->get_path . " " . $d->get("not found"));
		return FALSE;
	}

	my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $giofile->get_path);
	$mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;
	if ($mime_type =~ m/(pdf|ps|svg)/ig) {
		return FALSE;
	}

	Gtk3::RecentManager::get_default->add_item($giofile->get_path);

	my %plugins   = %{$sc->get_plugins // {}};
	my $num_files = $session_start_screen->{'first_page'}->{'num_session_files'};

	my $fname = $shf->utf8_decode(unescape_string_for_display($giofile->get_basename));
	my $key   = 0;
	my $indx  = 0;

	if (defined $num_files && $num_files > 0) {
		if (defined $history && $history->get_history) {
			$indx = $num_files + 1;
			$session_start_screen->{'first_page'}->{'num_session_files'} = $indx;
		} elsif (defined $count) {
			$indx = $count;
		} else {
			$indx = $num_files + 1;
			while ($indx < $self->fct_get_latest_tab_key()) {
				$indx++;
			}
			$session_start_screen->{'first_page'}->{'num_session_files'} = $indx;
		}
	} else {
		$indx = $self->fct_get_latest_tab_key();
	}

	$key = "[" . $indx . "] - $fname";

	if (defined $history && $history->get_history) {
		$session_screens->{$key}->{'history'}              = $history;
		$session_start_screen->{'first_page'}->{'history'} = $history;
		$session_screens->{$key}->{'history_timestamp'}    = time;
	}

	return $key;
}

sub fct_get_latest_tab_key ($self) {
	my $session_screens = $self->_session_screens;
	my $latest_key      = 0;
	foreach my $key (keys %$session_screens) {
		if ($key =~ /^\[(\d+)\]/) {
			$latest_key = max($latest_key, $1);
		}
	}
	return $latest_key;
}

1;
