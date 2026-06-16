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

package Shutter::App::UI::SettingsDialog;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has '_common' => (is => 'ro', required => 1);
has '_dialog' => (is => 'rw');
has '_profiles_box' => (is => 'rw');

sub create_settings_dialog {
    my ($self, $window) = @_;
    my $sc = $self->_common;
    my $d = $sc->get_gettext;

    my $dialog = Gtk3::Dialog->new(SHUTTER_NAME . " - " . $d->get("Preferences"), $window, [qw/modal destroy-with-parent/], 'gtk-close' => 'close');
    $self->_dialog($dialog);
    return $dialog;
}

sub show {
    my ($self) = @_;
    $self->_dialog->show_all if $self->_dialog;
    return $self->_dialog->run if $self->_dialog;
}

sub hide {
    my ($self) = @_;
    $self->_dialog->hide() if $self->_dialog;
}

1;