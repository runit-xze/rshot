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

package Shutter::App;

use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;
use Gtk3 '-init';
use Glib::Object::Subclass qw/Gtk3::Application/;

1;

__END__

=head1 NAME

Shutter::App – Gtk3::Application subclass for Shutter

=head1 DESCRIPTION

This module defines the Shutter::App class, which is a subclass of Gtk3::Application.
It provides the main application object for the Gtk3 main loop.

=cut
