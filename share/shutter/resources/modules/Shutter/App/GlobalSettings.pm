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

package Shutter::App::GlobalSettings;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;

#Glib
use Glib qw/TRUE FALSE/;

#--------------------------------------

has '_image_quality' => (
	is      => 'rw',
	default => sub {
		{"png" => undef, "jpg" => undef, "webp" => undef, "avif" => undef}
	},
);

has '_default_image_quality' => (
	is      => 'ro',
	default => sub {
		{"png" => 9, "jpg" => 90, "webp" => 98, "avif" => 68}
	},
);

has '_gif_settings' => (
	is      => 'rw',
	default => sub {
		{fps => 10, max_duration => 30, countdown => 3, cursor => 1}
	},
);

#getter / setter

sub get_image_quality ($self, $format) {
	if (defined $self->_image_quality->{$format}) {
		return $self->_image_quality->{$format};
	} else {
		return $self->_default_image_quality->{$format};
	}
}

sub set_image_quality ($self, $format, $value = undef) {
	$self->_image_quality->{$format} = $value if defined $value;
	return $self->_image_quality->{$format};
}

sub clear_quality_settings ($self) {
	$self->_image_quality({"png" => undef, "jpg" => undef, "webp" => undef, "avif" => undef});
	return;
}

sub get_gif_setting ($self, $key) {
	return $self->_gif_settings->{$key};
}

sub set_gif_setting ($self, $key, $val) {
	$self->_gif_settings->{$key} = $val;
	return;
}

1;
