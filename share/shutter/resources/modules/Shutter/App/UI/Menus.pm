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
has core_handlers => (is => 'rw');
has workflow_handlers => (is => 'rw');

sub BUILD ($self) {
    my $sc = $self->cli->sc;
    my $vbox = $self->cli->vbox;

    $self->sm(Shutter::App::Menu->new($sc));
    $self->st(Shutter::App::Toolbar->new($sc));

    $vbox->pack_start($self->sm->create_menu, FALSE, TRUE, 0);

    # Create handler objects
    $self->core_handlers(Shutter::App::Handlers::Core->new(cli => $self->cli));
    $self->workflow_handlers(Shutter::App::Handlers::Workflow->new(cli => $self->cli));

    $self->_connect_menu_items;
    $self->_connect_toolbar_items;
}

sub _connect_menu_items ($self) {
    my $sm = $self->sm;
    my $core = $self->core_handlers;

    $sm->{_menuitem_open}->signal_connect('activate' => sub {
        my @files = grep { $self->cli->shf->file_exists($_) } @ARGV;
        fct_open_files(@files);
        fct_control_main_window('show');
    });

    $sm->{_menuitem_quit}->signal_connect('activate' => sub { $core->evt_delete_window(undef, 'quit') });
    $sm->{_menuitem_undo}->signal_connect('activate' => sub { fct_undo() });
    $sm->{_menuitem_redo}->signal_connect('activate' => sub { fct_redo() });
    $sm->{_menuitem_zoom_in}->signal_connect('activate' => sub { fct_zoom_in() });
    $sm->{_menuitem_zoom_out}->signal_connect('activate' => sub { fct_zoom_out() });
    $sm->{_menuitem_fullscreen}->signal_connect('toggled' => sub { fct_fullscreen() });
}

sub _connect_toolbar_items ($self) {
    my $st = $self->st;
    my $core = $self->core_handlers;

    $st->{_redoshot}->signal_connect('clicked' => sub { $core->evt_take_screenshot(undef, 'redoshot', undef, undef) });
    $st->{_select}->signal_connect('clicked' => sub { $core->evt_take_screenshot(undef, 'select', undef, undef) });
    $st->{_full}->signal_connect('clicked' => sub { $core->evt_take_screenshot(undef, 'full', undef, undef) });
    $st->{_window}->signal_connect('clicked' => sub { $core->evt_take_screenshot(undef, 'window', undef, undef) });
    $st->{_menu}->signal_connect('clicked' => sub { $core->evt_take_screenshot(undef, 'menu', undef, undef) });
    $st->{_tooltip}->signal_connect('clicked' => sub { $core->evt_take_screenshot(undef, 'tooltip', undef, undef) });
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