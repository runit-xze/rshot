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

package Shutter::App::Events::Screenshot;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub evt_take_screenshot ($self, $source, $mode, $window_name, $extra) {
	$self->$self->cli->handlers->get('Core')->evt_take_screenshot(undef, $mode, undef, $extra);
	return;
}

sub shortcut_select ($self) {
	$self->evt_take_screenshot('global_keybinding', 'select', undef, undef);
	return;
}

sub shortcut_full ($self) {
	$self->evt_take_screenshot('global_keybinding', 'full', undef, undef);
	return;
}

sub shortcut_window ($self, $pattern) {
	$self->evt_take_screenshot('global_keybinding', 'window', undef, $pattern);
	return;
}

sub shortcut_awindow ($self) {
	$self->evt_take_screenshot('global_keybinding', 'awindow', undef, undef);
	return;
}

sub shortcut_menu ($self) {
	$self->evt_take_screenshot('global_keybinding', 'menu', undef, undef);
	return;
}

sub shortcut_tooltip ($self) {
	$self->evt_take_screenshot('global_keybinding', 'tooltip', undef, undef);
	return;
}

sub shortcut_web ($self, $url) {
	$self->evt_take_screenshot('global_keybinding', 'web', undef, $url);
	return;
}

sub shortcut_redoshot ($self) {
	$self->evt_take_screenshot('global_keybinding', 'redoshot', undef, undef);
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Events::Screenshot – Screenshot event handlers

=head1 SYNOPSIS

    my $screenshot_events = Shutter::App::Events::Screenshot->new(cli => $cli);
    $screenshot_events->evt_take_screenshot('global_keybinding', 'select');

=head1 DESCRIPTION

Handles all screenshot capture modes: selection, full screen, window,
active window, menu, tooltip, web page, and redo last shot.

=cut
