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
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package Shutter::App::UI::Windows;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has common => (is => 'ro', required => 1);
has app => (is => 'ro', required => 1);
has cli => (is => 'ro', required => 1);
has _window => (is => 'rw');
has _vbox => (is => 'rw');

sub BUILD ($self, $args) {
    my $sc = $self->common;
    my $app = $self->app;

    my $window = Gtk3::ApplicationWindow->new($app);
    $self->_window($window);
    $sc->set_mainwindow($window);

    $window->signal_connect('delete-event' => sub { $self->cli->handlers->get('Core')->evt_delete_window('', 'quit') });
    $window->set_border_width(0);
    $window->set_resizable(TRUE);
    $window->set_focus_on_map(TRUE);
    $window->set_default_size(-1, 500);

    Gtk3::Window::set_default_icon_name("rshot");

    my $vbox = Gtk3::VBox->new(FALSE, 0);
    $self->_vbox($vbox);
    $window->add($vbox);
    return;
}

sub get_window { return $_[0]->_window }
sub get_vbox { return $_[0]->_vbox }

1;

__END__

=head1 NAME

Shutter::App::UI::Windows – Main window creation

=head1 SYNOPSIS

    my $windows = Shutter::App::UI::Windows->new(common => $sc, app => $app);

=head1 DESCRIPTION

Creates the main application window and its top-level container vbox.
Other UI components pack into this vbox.

=cut