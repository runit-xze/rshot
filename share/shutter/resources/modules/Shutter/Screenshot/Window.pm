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
		my ($sc, $include_cursor, $delay, $notify_timeout, $include_border, $windowresize, $windowresize_w, $windowresize_h, $hide_time, $mode, $auto_shape, $is_hidden, $show_visible, $ignore_type) = @args;
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
	$self->{_dpi_scale} = $self->{_main_gtk_window}->get('scale-factor');

	#only used when selecting a window
	if (defined $self->_mode && $self->_mode =~ m/(window|section)/ig) {
		$self->setup_highlighter;
	}
}

#~ sub DESTROY {
#~ my $self = shift;
#~ print "$self dying at\n";
#~ }
#~





sub window_async ($self) {

	my $f = Future->new;

	#return value

	my $output = 5;

	#current workspace
	my $active_workspace = $self->{_wnck_screen}->get_active_workspace;

	#something went wrong here, no active workspace detected
	unless ($active_workspace) {
		$output = 0;
		return $output;
	}

	#grab pointer and keyboard
	#when mode is section or window
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

	#init
	$self->{_c}                     = ();
	$self->{_c}{'ws'}               = undef;
	$self->{_c}{'ws_init'}          = FALSE;
	$self->{_c}{'lw'}{'gdk_window'} = 0;

	#root window size is minimum at startup
	$self->{_min_size}              = $self->{_root}->{w} * $self->{_root}->{h} * $self->{_dpi_scale} * $self->{_dpi_scale};
	$self->{_c}{'cw'}{'gdk_window'} = $self->{_root};
	$self->{_c}{'cw'}{'x'}          = $self->{_root}->{x};
	$self->{_c}{'cw'}{'y'}          = $self->{_root}->{y};
	$self->{_c}{'cw'}{'width'}      = $self->{_root}->{w};
	$self->{_c}{'cw'}{'height'}     = $self->{_root}->{h};

	#get initial window under cursor
	my ($window_at_pointer, $initx, $inity, $mask) = $self->{_root}->get_pointer;

	#create event for current coordinates
	my $initevent = Gtk3::Gdk::Event->new('motion-notify');
	$initevent->time(Gtk3::get_current_event_time());
	$initevent->window($self->{_root});
	$initevent->x($initx);
	$initevent->y($inity);

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

		#simulate mouse movement
		$self->select_window($initevent, $active_workspace);

		Gtk3::Gdk::Event::handler_set(
			sub {
				my ($event, $data) = @_;
				return FALSE unless defined $event;

				#KEY-PRESS
				if ($event->type eq 'key-press') {
					next unless defined $event->keyval;

					if ($event->keyval == Gtk3::Gdk::keyval_from_name('Escape')) {

						#destroy highlighter window
						$self->{_highlighter}->destroy;

						$self->quit;

						$output = 5;
						$f->done($output);
					}

					#BUTTON-PRESS
				} elsif ($event->type eq 'button-press') {
					print "Type: " . $event->type . "\n"
						if (defined $event && $self->{_sc}->get_debug);

					#user selects window or section
					$self->select_window($event, $active_workspace);

					#BUTTON-RELEASE
				} elsif ($event->type eq 'button-release') {
					print "Type: " . $event->type . "\n" if (defined $event && $self->{_sc}->get_debug);

					my ($xp, $yp, $wp, $hp, $xc, $yc, $wc, $hc) = (0, 0, 0, 0, 0, 0, 0, 0);

					if (defined $self->{_c}{'lw'} && $self->{_c}{'lw'}{'gdk_window'}) {

						#size (we need to do this again because of autoresizing)
						if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {
							($xc, $yc, $wc, $hc) = $self->get_window_size($self->{_c}{'lw'}{'window'}, $self->{_c}{'lw'}{'gdk_window'}, $self->{_include_border}, TRUE);
							($xp, $yp, $wp, $hp) = $self->get_window_size($self->{_c}{'lw'}{'window'}, $self->{_c}{'lw'}{'gdk_window'}, $self->{_include_border});

							$self->{_c}{'cw'}{'x'}      = $xp;
							$self->{_c}{'cw'}{'y'}      = $yp;
							$self->{_c}{'cw'}{'width'}  = $wp;
							$self->{_c}{'cw'}{'height'} = $hp;
						}

						#focus selected window (maybe it is hidden)
						$self->{_c}{'lw'}{'gdk_window'}->focus($event->time);
						Gtk3::Gdk::flush();

						#something went wrong here, no window on screen detected
					} else {

						$output = 0;
						$self->quit;
						$f->done($output);
						return FALSE;

					}

					#looking for a section of a window?
					#keep current window in mind and search for children
					if (($self->{_mode} eq "section" || $self->{_mode} eq "tray_section")
						&& !$self->{_c}{'ws'})
					{

						#mark as selected parent window
						$self->{_c}{'ws'}      = $self->{_c}{'cw'}{'gdk_window'};
						$self->{_c}{'ws_init'} = TRUE;

						#and select current subwindow
						$self->select_window($event);

						#we don't take the screenshot yet
						return TRUE;
					}

					#stop event handler
					$self->quit_eventh_only;

					#destroy highlighter window
					$self->{_highlighter}->destroy;

					#A short timeout to give the server a chance to
					#redraw the area
					Glib::Timeout->add($self->{_hide_time}, sub {
						$self->get_pixbuf_from_drawable_async($self->{_root}, $self->{_c}{'cw'}{'x'} / $self->{_dpi_scale}, $self->{_c}{'cw'}{'y'} / $self->{_dpi_scale}, $self->{_c}{'cw'}{'width'} / $self->{_dpi_scale}, $self->{_c}{'cw'}{'height'} / $self->{_dpi_scale}, undef)->then(sub {
							my ($output_new, $l_cropped, $r_cropped, $t_cropped, $b_cropped) = @_;

					#save return value to current $output variable
					#-> ugly but fastest and safest solution now
					$output = $output_new;

					#respect rounded corners of wm decorations (metacity for example - does not work with compiz currently)
					if ($self->{_include_border}) {
						my $xid = $self->{_c}{'cw'}{'gdk_window'}->get_xid;

						#do not try this for child windows
						foreach my $win (@{$self->{_wnck_screen}->get_windows}) {
							if ($win->get_xid == $xid) {
								$output = $self->get_shape($xid, $output, $l_cropped, $r_cropped, $t_cropped, $b_cropped);
								last;
							}
						}
					}

					#restore window size when autoresizing was used
					if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
						if (defined $self->{_windowresize} && $self->{_windowresize}) {
							if ($wc != $wp || $hc != $hp) {
								if ($self->{_include_border}) {
									$self->{_c}{'lw'}{'window'}->set_geometry('current', [qw/width height/], $xc, $yc, $wc, $hc);
								} else {
									$self->{_c}{'lw'}{'gdk_window'}->resize($wc, $hc);
								}
							}
						}
					}

					#set name of the captured window
					#e.g. for use in wildcards
					if ($output =~ /Gtk3/ && defined $self->{_c}{'cw'}{'window'}) {
						$self->{_action_name} = $self->{_c}{'cw'}{'window'}->get_name;
					}

					#set history object
					$self->{_history} = Shutter::Screenshot::History->new(
						$self->{_sc},           $self->{_root},                       $self->{_c}{'cw'}{'x'},
						$self->{_c}{'cw'}{'y'}, $self->{_c}{'cw'}{'width'},           $self->{_c}{'cw'}{'height'},
						undef,                  $self->{_c}{'cw'}{'window'}->get_xid, $self->{_c}{'cw'}{'gdk_window'}->get_xid
					);

					$self->quit;
							$f->done($output);
							return Future->done();
						})->retain;
						return FALSE;
					});

					#MOTION-NOTIFY
				} elsif ($event->type eq 'motion-notify') {
					print "Type: " . $event->type . "\n"
						if (defined $event && $self->{_sc}->get_debug);

					#user selects window or section
					$self->select_window($event, $active_workspace);

				} else {
					Gtk3::main_do_event($event);
				}
			});

		#pointer not grabbed
	} else {

		$output = 0;

		my ($xp, $yp, $wp, $hp, $xc, $yc, $wc, $hc) = (0, 0, 0, 0, 0, 0, 0, 0);

		if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {

			#and select current parent window
			my ($wnck_window, $gdk_window) = $self->find_active_window;

			if (defined $wnck_window && $wnck_window && defined $gdk_window && $gdk_window) {

				#get_size of it
				($xc, $yc, $wc, $hc) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border}, TRUE);
				($xp, $yp, $wp, $hp) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border});

				$self->{_c}{'cw'}{'window'}     = $wnck_window;
				$self->{_c}{'cw'}{'gdk_window'} = $gdk_window;
				$self->{_c}{'cw'}{'x'}          = $xp;
				$self->{_c}{'cw'}{'y'}          = $yp;
				$self->{_c}{'cw'}{'width'}      = $wp;
				$self->{_c}{'cw'}{'height'}     = $hp;
				$self->{_c}{'cw'}{'is_parent'}  = TRUE;

			}

		} elsif (($self->{_mode} eq "menu" || $self->{_mode} eq "tray_menu")) {

			#and select current menu
			$self->find_region_for_window_type($self->{_root}->get_xid, 'menu');

			#no window with type_hint eq 'menu' detected
			unless (defined $self->{_c}{'cw'}{'window_region'}) {
				if ($self->{_ignore_type}) {
					warn "WARNING: No window with type hint 'menu' detected -> window type hint will be ignored, because workaround is enabled\n";
					$self->find_region_for_window_type($self->{_root}->get_xid);
				} else {
					return 2;
				}
			}

		} elsif (($self->{_mode} eq "tooltip" || $self->{_mode} eq "tray_tooltip")) {

			#and select current tooltip
			$self->find_region_for_window_type($self->{_root}->get_xid, 'tooltip');

			#no window with type_hint eq 'tooltip' detected
			unless (defined $self->{_c}{'cw'}{'window_region'}) {
				if ($self->{_ignore_type}) {
					warn "WARNING: No window with type hint 'tooltip' detected -> window type hint will be ignored, because workaround is enabled\n";
					$self->find_region_for_window_type($self->{_root}->get_xid);
				} else {
					return 2;
				}
			}

			#looking for a section of a window?
			#keep current window in mind and search for children
		} elsif (($self->{_mode} eq "section" || $self->{_mode} eq "tray_section")) {

			#mark as selected parent window
			$self->{_c}{'ws'} = $self->{_root};

			#and select current subwindow
			$self->select_window($initevent);

		}

		$self->get_pixbuf_from_drawable_async($self->{_root}, $self->{_c}{'cw'}{'x'}, $self->{_c}{'cw'}{'y'}, $self->{_c}{'cw'}{'width'}, $self->{_c}{'cw'}{'height'},
			$self->{_c}{'cw'}{'window_region'})->then(sub {
			my ($output_new, $l_cropped, $r_cropped, $t_cropped, $b_cropped) = @_;

		#save return value to current $output variable
		#-> ugly but fastest and safest solution now
		$output = $output_new;

		#respect rounded corners of wm decorations
		#(metacity for example - does not work with compiz currently)
		#only if toplevel window was selected
		if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {
			if ($self->{_include_border}) {
				my $xid = $self->{_c}{'cw'}{'gdk_window'}->get_xid;

				#do not try this for child windows
				foreach my $win (@{$self->{_wnck_screen}->get_windows}) {
					if ($win->get_xid == $xid) {
						$output = $self->get_shape($xid, $output, $l_cropped, $r_cropped, $t_cropped, $b_cropped);
						last;
					}
				}
			}
		}

		#restore window size when autoresizing was used
		if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
			if (defined $self->{_windowresize} && $self->{_windowresize}) {
				if ($wc != $wp || $hc != $hp) {
					if ($self->{_include_border}) {
						$self->{_c}{'cw'}{'window'}->set_geometry('current', [qw/width height/], $xc, $yc, $wc, $hc);
					} else {
						$self->{_c}{'cw'}{'gdk_window'}->resize($wc, $hc);
					}
				}
			}
		}

		#set name of the captured window
		#e.g. for use in wildcards
		my $d = $self->{_sc}->get_gettext;

		if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {

			if ($output =~ /Gtk3/ && defined $self->{_c}{'cw'}{'window'}) {
				$self->{_action_name} = $self->{_c}{'cw'}{'window'}->get_name;
			}

		} elsif (($self->{_mode} eq "section" || $self->{_mode} eq "tray_section")) {

			if ($output =~ /Gtk3/ && defined $self->{_c}{'cw'}{'window'}) {
				$self->{_action_name} = $self->{_action_name} = $self->{_c}{'cw'}{'window'}->get_name;
			}

		} elsif (($self->{_mode} eq "menu" || $self->{_mode} eq "tray_menu")) {

			if ($output =~ /Gtk3/) {
				$self->{_action_name} = $d->get("Menu");
			}

		} elsif (($self->{_mode} eq "tooltip" || $self->{_mode} eq "tray_tooltip")) {

			if ($output =~ /Gtk3/) {
				$self->{_action_name} = $d->get("Tooltip");
			}

		}

		if (defined $self->{_c}{'cw'}{'window'} && $self->{_c}{'cw'}{'gdk_window'}) {

			#set history object
			$self->{_history} = Shutter::Screenshot::History->new(
				$self->{_sc},                       $self->{_root},                       $self->{_c}{'cw'}{'x'},
				$self->{_c}{'cw'}{'y'},             $self->{_c}{'cw'}{'width'},           $self->{_c}{'cw'}{'height'},
				$self->{_c}{'cw'}{'window_region'}, $self->{_c}{'cw'}{'window'}->get_xid, $self->{_c}{'cw'}{'gdk_window'}->get_xid
			);

		} else {

			#set history object
			$self->{_history} = Shutter::Screenshot::History->new(
				$self->{_sc}, $self->{_root},
				$self->{_c}{'cw'}{'x'},
				$self->{_c}{'cw'}{'y'},
				$self->{_c}{'cw'}{'width'},
				$self->{_c}{'cw'}{'height'},
				$self->{_c}{'cw'}{'window_region'},
			);

		}
		$f->done($output);
		return Future->done();
	})->retain;

	}
	return $f;
}

sub get_mode ($self) {
	return $self->{_mode};
}

sub redo_capture_async ($self) {
	my $f = Future->new;
	my $output = 3;

	if (defined $self->{_history}) {
		my ($last_drawable, $lxp, $lyp, $lwp, $lhp, $lregion, $wxid, $gxid) = $self->{_history}->get_last_capture;

		if (defined $gxid && defined $wxid) {

			#create windows
			my $gdk_window = Gtk3::GdkX11::X11Window->foreign_new_for_display(Gtk3::Gdk::Display::get_default(), $gxid);
			my $wnck_window = Wnck::Window::get($wxid);

			if (defined $gdk_window && defined $wnck_window) {

				#store size
				my ($xp, $yp, $wp, $hp, $xc, $yc, $wc, $hc) = (0, 0, 0, 0, 0, 0, 0, 0);

				if ($self->{_mode} eq "section" || $self->{_mode} eq "tray_section") {

					($xp, $yp, $wp, $hp) = $gdk_window->get_geometry;
					($xp, $yp) = $gdk_window->get_origin;

					#find parent window
					my $pxid   = $self->find_wm_window($gxid);
					my $parent = Gtk3::GdkX11::X11Window->foreign_new_for_display(Gtk3::Gdk::Display::get_default(), $pxid);
					if (defined $parent && $parent) {

						#and focus parent window (maybe it is hidden)
						$parent->focus(Gtk3::get_current_event_time());
						Gtk3::Gdk::flush();
					}

				} elsif ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {

					#get_size of it
					($xc, $yc, $wc, $hc) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border}, TRUE);
					($xp, $yp, $wp, $hp) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border});

				}

				#focus selected window (maybe it is hidden)
				$gdk_window->focus(Gtk3::get_current_event_time());
				Gtk3::Gdk::flush();

				#A short timeout to give the server a chance to
				#redraw the area
				Glib::Timeout->add($self->{_hide_time}, sub {
					$self->get_pixbuf_from_drawable_async($self->{_root}, $xp, $yp, $wp, $hp)->then(sub {
						my ($output_new, $l_cropped, $r_cropped, $t_cropped, $b_cropped) = @_;

				#save return value to current $output variable
				#-> ugly but fastest and safest solution now
				$output = $output_new;

				if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
					if ($self->{_include_border}) {
						$output = $self->get_shape($gxid, $output, $l_cropped, $r_cropped, $t_cropped, $b_cropped);
					}
				}

				#restore window size when autoresizing was used
				if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
					if (defined $self->{_windowresize} && $self->{_windowresize}) {
						if ($wc != $wp || $hc != $hp) {
							if ($self->{_include_border}) {
								$wnck_window->set_geometry('current', [qw/width height/], $xc, $yc, $wc, $hc);
							} else {
								$gdk_window->resize($wc, $hc);
							}
						}
					}
				}

				$self->quit_eventh_only;
						$f->done($output);
						return Future->done();
					})->retain;
					return FALSE;
				});

			} else {
				warn "WARNING: Could not get window with id $gxid\n";
				$output = 4;
				$f->done($output);
			}

			#no xid
		} else {
			$self->get_pixbuf_from_drawable_async($self->{_history}->get_last_capture)->then(sub {
				my ($output_new) = @_;
				$output = $output_new;
				$f->done($output);
				return Future->done();
			})->retain;
		}

	} else {
		$f->done($output);
	}

	return $f;
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

sub quit ($self) {

	$self->ungrab_pointer_and_keyboard(FALSE, TRUE, TRUE);
	Gtk3::Gdk::flush();

}

sub quit_eventh_only ($self) {

	$self->ungrab_pointer_and_keyboard(FALSE, TRUE, FALSE);
	Gtk3::Gdk::flush();

}

1;
