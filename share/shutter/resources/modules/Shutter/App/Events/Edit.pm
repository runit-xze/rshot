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

package Shutter::App::Events::Edit;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_undo ($self) { fct_undo() }
sub fct_redo ($self) { fct_redo() }
sub fct_zoom_in ($self) { fct_zoom_in() }
sub fct_zoom_out ($self) { fct_zoom_out() }
sub fct_zoom_100 ($self) { fct_zoom_100() }
sub fct_zoom_best ($self) { fct_zoom_best() }
sub fct_fullscreen ($self) { fct_fullscreen() }
sub fct_draw ($self) { fct_draw() }
sub fct_clipboard ($self, $mode) { fct_clipboard($mode) }
sub fct_delete ($self) { fct_delete() }
sub fct_select_all ($self) { fct_select_all() }
sub fct_upload ($self) { fct_upload() }
sub fct_send ($self) { fct_send() }
sub fct_plugin ($self) { fct_plugin() }
sub fct_rename ($self) { fct_rename() }
sub fct_show_in_folder ($self) { fct_show_in_folder() }
sub fct_value_changed ($self, $widget, $reason) { evt_value_changed($widget, $reason) }

1;

__END__

=head1 NAME

Shutter::App::Events::Edit – Editing event handlers

=head1 SYNOPSIS

    my $edit_events = Shutter::App::Events::Edit->new(cli => $cli);
    $edit_events->fct_undo();

=head1 DESCRIPTION

Provides thin wrappers around the original event handler functions for
undo/redo, zoom, fullscreen, drawing, clipboard operations, and more.

=cut