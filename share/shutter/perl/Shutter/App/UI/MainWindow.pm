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

package Shutter::App::UI::MainWindow;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has '_common'   => (is => 'ro', required => 1);
has '_window'   => (is => 'rw');
has '_notebook' => (is => 'rw');
has '_status'   => (is => 'rw');

sub create_main_window ($self, $app) {
	my $window = Gtk3::ApplicationWindow->new($app);
	$self->_window($window);
	return $window;
}

sub get_window   { return $_[0]->_window }
sub get_notebook { return $_[0]->_notebook }
sub get_status   { return $_[0]->_status }

1;
