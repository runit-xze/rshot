###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
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

package Shutter::Pixbuf::Border;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;

#Glib
use Glib qw/TRUE FALSE/;

has '_common' => (is => 'ro', required => 1, init_arg => 'common');

sub create_border ($self, $pixbuf, $width, $color) {

	#create new pixbuf
	my $tmp_pbuf = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, $pixbuf->get_width + 2 * $width, $pixbuf->get_height + 2 * $width);

	#Create a pixel specification
	my $pixel = 0;
	$pixel += ($color->red / 257) << 24;
	$pixel += ($color->green / 257) << 16;
	$pixel += ($color->blue / 257) << 8;
	$pixel += 255;

	#fill tmp pixbuf
	$tmp_pbuf->fill($pixel);

	#copy source pixbuf to new pixbuf
	try { $pixbuf->copy_area(0, 0, $pixbuf->get_width, $pixbuf->get_height, $tmp_pbuf, $width, $width); }
	catch ($e) {
		print "create border failed: $e\n" if $self->_common->debug;
		return $pixbuf;
	}

	return $tmp_pbuf;
}

1;
