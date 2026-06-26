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

package Shutter::Screenshot::Window;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

#File operations
use IO::File();

use Shutter::Screenshot::Main;
use Shutter::Screenshot::History;
use Data::Dumper;
use Moo;
extends 'Shutter::Screenshot::Main';
with 'Shutter::Screenshot::Window::Geometry';
with 'Shutter::Screenshot::Window::Selector';
with 'Shutter::Screenshot::Window::Highlighter';
with 'Shutter::Screenshot::Window::CaptureManager';
with 'Shutter::Screenshot::Window::Interaction';

#Glib
use Gtk3;
use Future;
use Glib qw/TRUE FALSE/;

#--------------------------------------

has '_include_border' => (is => 'rw');
has '_windowresize'   => (is => 'rw');
has '_windowresize_w' => (is => 'rw');
has '_windowresize_h' => (is => 'rw');
has '_hide_time'      => (is => 'rw');
has '_mode'           => (is => 'rw');
has '_auto_shape'     => (is => 'rw');
has '_is_hidden'      => (is => 'rw');
has '_show_visible'   => (is => 'rw');
has '_ignore_type'    => (is => 'rw');

around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;
	if (@args >= 14 && @args <= 15) {
		my ($sc, $include_cursor, $delay, $notify_timeout, $include_border, $windowresize, $windowresize_w, $windowresize_h, $hide_time, $mode, $auto_shape, $is_hidden, $show_visible, $ignore_type) =
			@args;
		return $class->$orig(
			_sc             => $sc,
			_include_cursor => $include_cursor,
			_delay          => $delay,
			_notify_timeout => $notify_timeout,
			_include_border => $include_border,
			_windowresize   => $windowresize,
			_windowresize_w => $windowresize_w,
			_windowresize_h => $windowresize_h,
			_hide_time      => $hide_time,
			_mode           => $mode,
			_auto_shape     => $auto_shape,
			_is_hidden      => $is_hidden,
			_show_visible   => $show_visible,
			_ignore_type    => $ignore_type,
		);
	}
	return $class->$orig(@args);
};

sub BUILD ($self, $args) {

	#X11 protocol and XSHAPE ext
	require X11::Protocol;

	$self->{_x11} = X11::Protocol->new($ENV{'DISPLAY'});
	$self->{_x11}{ext_shape} = $self->{_x11}->init_extension('SHAPE');

	#main window
	$self->{_main_gtk_window} = $self->_sc->get_mainwindow;
	$self->{_dpi_scale}       = $self->{_main_gtk_window}->get('scale-factor');

	#only used when selecting a window
	if (defined $self->_mode && $self->_mode =~ m/(window|section)/ig) {
		$self->setup_highlighter;
	}
	return;
}

#~ sub DESTROY {
#~ my $self = shift;
#~ print "$self dying at\n";
#~ }
#~

sub window_async ($self) {

	my $f      = Future->new;
	my $output = 5;

	my $active_workspace = $self->{_wnck_screen}->get_active_workspace;
	unless ($active_workspace) {
		$output = 0;
		return $output;
	}

	unless ($self->{_mode} eq "menu"
		|| $self->{_mode} eq "tray_menu"
		|| $self->{_mode} eq "tooltip"
		|| $self->{_mode} eq "tray_tooltip"
		|| $self->{_mode} eq "awindow"
		|| $self->{_mode} eq "tray_awindow")
	{
		$self->{_highlighter}->realize;

		my $grab_counter = 0;
		while (!Gtk3::Gdk::pointer_is_grabbed() && $grab_counter < 100) {
			Gtk3::Gdk::pointer_grab($self->{_root}, FALSE, [qw/pointer-motion-mask button-press-mask button-release-mask/], undef, Gtk3::Gdk::Cursor->new('GDK_HAND2'), Gtk3::get_current_event_time());
			Gtk3::Gdk::keyboard_grab($self->{_highlighter}->get_window, 0, Gtk3::get_current_event_time());
			$grab_counter++;
		}
	}

	my $initevent = $self->_init_capture_state;

	if (
		Gtk3::Gdk::pointer_is_grabbed()
		&& !(
			   $self->{_mode} eq "menu"
			|| $self->{_mode} eq "tray_menu"
			|| $self->{_mode} eq "tooltip"
			|| $self->{_mode} eq "tray_tooltip"
			|| $self->{_mode} eq "awindow"
			|| $self->{_mode} eq "tray_awindow"
		))
	{
		$self->_capture_interactive($f, $active_workspace, $initevent);
	} else {
		$self->_capture_noninteractive($f, $initevent);
	}
	return $f;
}

sub get_mode ($self) {
	return $self->{_mode};
}

sub get_history ($self) {
	return $self->{_history};
}

sub get_error_text ($self) {
	return $self->{_error_text};
}

sub get_action_name ($self) {
	return $self->{_action_name};
}

1;
