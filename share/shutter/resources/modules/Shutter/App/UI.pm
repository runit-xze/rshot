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

package Shutter::App::UI;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub create_main_window {
    my ($self, $app) = @_;
    my $window = Gtk3::ApplicationWindow->new($app);
    $self->cli->set_mainwindow($window);
    $window->signal_connect('delete-event' => \&evt_delete_window);
    $window->set_border_width(0);
    $window->set_resizable(TRUE);
    $window->set_focus_on_map(TRUE);
    $window->set_default_size(-1, 500);
    return $window;
}

sub setup_app_objects {
    my ($self) = @_;
    my $sc = $self->cli;
    my $window = $sc->get_mainwindow;

    my $sas = Shutter::App::Autostart->new();
    my $sm = Shutter::App::Menu->new($sc);
    my $st = Shutter::App::Toolbar->new($sc);
    my $sd = Shutter::App::SimpleDialogs->new($window);

    my $sp = Shutter::Pixbuf::Save->new($sc);
    my $lp = Shutter::Pixbuf::Load->new($sc);
    my $lp_ne = Shutter::Pixbuf::Load->new($sc, undef, TRUE);

    my $acp = Shutter::App::AfterCapturePipeline->new($sc, $sc->get_gettext, $window);
    my $pins = Shutter::App::PinToScreen->new();

    my $vbox = Gtk3::VBox->new(FALSE, 0);
    $window->add($vbox);
    $vbox->pack_start($sm->create_menu, FALSE, TRUE, 0);
    $vbox->pack_start($st->create_toolbar, FALSE, TRUE, 0);

    my $status = Gtk3::Statusbar->new;
    $status->set_name('main-window-statusbar');
    $vbox->pack_start($status, FALSE, TRUE, 0);

    return ($sas, $sm, $st, $sd, $sp, $lp, $lp_ne, $acp, $pins, $vbox, $status);
}

1;