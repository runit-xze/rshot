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

package Shutter::Screenshot::History;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

#Glib
use Glib qw/TRUE FALSE/;

use Moo;

has '_sc'       => (is => 'rw');
has '_drawable' => (is => 'rw');
has '_x'        => (is => 'rw', default => sub { 0 });
has '_y'        => (is => 'rw', default => sub { 0 });
has '_w'        => (is => 'rw', default => sub { 0 });
has '_h'        => (is => 'rw', default => sub { 0 });
has '_region'   => (is => 'rw');
has '_wxid'     => (is => 'rw');
has '_gxid'     => (is => 'rw');

around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;
	if (@args >= 1 && @args <= 9 && (ref($args[0]) || !defined($args[0]) || $args[0] !~ /^_/)) {
		my ($sc, $drawable, $x, $y, $w, $h, $region, $wxid, $gxid) = @args;
		return $class->$orig(
			_sc       => $sc,
			_drawable => $drawable,
			_x        => defined $x ? $x : 0,
			_y        => defined $y ? $y : 0,
			_w        => defined $w ? $w : 0,
			_h        => defined $h ? $h : 0,
			_region   => $region,
			_wxid     => $wxid,
			_gxid     => $gxid,
		);
	}
	return $class->$orig(@args);
};

#--------------------------------------

sub get_last_capture ($self) {
	return ($self->{_drawable}, $self->{_x}, $self->{_y}, $self->{_w}, $self->{_h}, $self->{_region}, $self->{_wxid}, $self->{_gxid});
}

sub set_last_capture ($self, $drawable = undef, $x = undef, $y = undef, $w = undef, $h = undef, $region = undef, $wxid = undef, $gxid = undef) {
	if (defined $drawable && defined $x && defined $y && defined $w && defined $h) {
		$self->{_drawable} = $drawable;
		$self->{_x}        = $x;
		$self->{_y}        = $y;
		$self->{_w}        = $w;
		$self->{_h}        = $h;
		$self->{_region}   = $region;
		$self->{_wxid}     = $wxid;
		$self->{_gxid}     = $gxid;
	} else {
		warn "WARNING: Wrong number of arguments in Shutter::Screenshot::History::set_last_capture\n";
	}
	return ($self->{_drawable}, $self->{_x}, $self->{_y}, $self->{_w}, $self->{_h}, $self->{_region}, $self->{_wxid}, $self->{_gxid});
}

1;
