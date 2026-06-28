###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 3 of the License, or
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

package Shutter::Screenshot::MockScreenshooter;

use utf8;
use v5.40;

sub new             { return bless {}, shift }
sub get_mode        { return "mock" }
sub get_action_name { return "mock_action" }
sub get_history     { return 1 }
sub get_error_text  { return "" }
sub can             { return 1 }

sub redo_capture {
	return Gtk3::Gdk::Pixbuf->new_from_file($ENV{SHUTTER_ROOT} . "/share/shutter/resources/icons/web_image.svg");
}

1;

__END__

=head1 NAME

Shutter::Screenshot::MockScreenshooter - Stub screenshooter used by --mock-capture

=head1 DESCRIPTION

When the user runs rshot with C<--mock-capture>, the real capture path is
skipped and a static SVG is loaded instead. The downstream code still
expects a screenshooter object with C<get_action_name>, C<get_mode>,
C<get_history>, C<get_error_text>, and C<can> methods, plus a
C<redo_capture> for the redo action. This package provides a
no-op stand-in so the post-capture pipeline can run end-to-end without
real capture hardware.

=cut
