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

package Shutter::App::UI::Menus;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);
has sm => (is => 'rw');
has st => (is => 'rw');

sub BUILD ($self, $args) {
    my $sc = $self->cli->sc;
    my $vbox = $self->cli->vbox;

    $self->sm($self->cli->{sm} // Shutter::App::Menu->new($sc));
    $self->st($self->cli->{st} // Shutter::App::Toolbar->new($sc));

    $vbox->pack_start($self->sm->create_menu, FALSE, TRUE, 0);
    $vbox->pack_start($self->st->create_toolbar, FALSE, TRUE, 0);
    $vbox->pack_start($self->cli->notebook, TRUE, TRUE, 0);

    $self->_connect_menu_items;
    $self->_connect_toolbar_items;
}

sub _connect_menu_items ($self) {
    my $sm = $self->sm;
    my $h  = $self->cli->handlers;

    $sm->{_menuitem_open}->signal_connect('activate' => sub {
        my @files = grep { $self->cli->shf->file_exists($_) } @ARGV;
        $h->get('Init_Handlers')->fct_open_files(@files);
        $h->get('Core')->fct_control_main_window('show');
    });

    $sm->{_menuitem_quit}->signal_connect('activate' => sub { $h->get('Core')->evt_delete_window(undef, 'quit') });
    $sm->{_menuitem_undo}->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_undo() });
    $sm->{_menuitem_redo}->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_redo() });
    $sm->{_menuitem_zoom_in}->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_zoom_in() });
    $sm->{_menuitem_zoom_out}->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_zoom_out() });
    $sm->{_menuitem_fullscreen}->signal_connect('toggled' => sub ($widget) { $h->get('Edit_Nav')->fct_fullscreen($widget) });
    $sm->{_menuitem_about}->signal_connect('activate' => sub { $h->get('Core')->evt_about() });
    $sm->{_menuitem_settings}->signal_connect('activate' => sub { $h->get('Core')->evt_show_settings() });
    $sm->{_menuitem_selection}->signal_connect('activate' => sub { $h->get('Core')->evt_take_screenshot(undef, 'select', undef, undef) });
    $sm->{_menuitem_draw}->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_draw() });
    $sm->{_menuitem_large_draw}->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_draw() });
    }

sub _connect_toolbar_items ($self) {
    my $st = $self->st;
    my $h  = $self->cli->handlers;

    $st->{_redoshot}->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'redoshot', undef, undef) });
    $st->{_select}->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'select', undef, undef) });
    $st->{_full}->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'full', undef, undef) });
    $st->{_window}->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'window', undef, undef) });
    $st->{_menu}->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'menu', undef, undef) });
    $st->{_tooltip}->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'tooltip', undef, undef) });
}

1;

__END__

=head1 NAME

Shutter::App::UI::Menus – Menu and toolbar signal wiring

=head1 SYNOPSIS

    my $menus = Shutter::App::UI::Menus->new(cli => $cli);

=head1 DESCRIPTION

Creates menu and toolbar, then connects all UI signals to handler methods.
Uses handler objects for actual logic implementation.

=cut