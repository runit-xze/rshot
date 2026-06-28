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

package Gtk3::IconSize;    ## no critic (Modules::ProhibitMultiplePackages Modules::RequireFilenameMatchesPackage)

use utf8;
use v5.40;

use Shutter::App::HelperFunctions;

no warnings 'redefine';

sub lookup {
	my ($self, $size) = @_;
	return Shutter::App::HelperFunctions->icon_size($size);
}

1;

__END__

=head1 NAME

Gtk3::IconSize – Compat shim overriding Gtk3::IconSize::lookup via GI

=head1 SYNOPSIS

    use Gtk3::IconSize;  # loaded once at app startup; installs the override globally

=head1 DESCRIPTION

The native Gtk3::IconSize::lookup method does not return useful values
under Glib::Object::Introspection, so this file replaces it with a
call into L<Shutter::App::HelperFunctions/icon_size> which uses GI to
look up the size. Loading the module is sufficient to install the
override globally for the lifetime of the interpreter.

=cut
