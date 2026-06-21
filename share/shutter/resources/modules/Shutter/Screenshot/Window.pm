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

#Glib
use Gtk3;
use Future;
use Pango;
use Glib qw/TRUE FALSE/;

#--------------------------------------

sub new ($class, $sc, $include_cursor, $delay, $notify_timeout, $include_border, $windowresize, $windowresize_w, $windowresize_h, $hide_time, $mode, $auto_shape, $is_hidden, $show_visible, $ignore_type) {

	#call constructor of super class (shutter_common, include_cursor, delay, notify_timeout)
	my $self = $class->SUPER::new($sc, $include_cursor, $delay, $notify_timeout);

	#get params
	$self->{_include_border} = $include_border;
	$self->{_windowresize}   = $windowresize;
	$self->{_windowresize_w} = $windowresize_w;
	$self->{_windowresize_h} = $windowresize_h;
	$self->{_hide_time}      = $hide_time;    #a short timeout to give the server a chance to redraw the area that was obscured
	$self->{_mode}           = $mode;
	$self->{_auto_shape}     = $auto_shape;    #shape the window without XShape support
	$self->{_is_hidden}      = $is_hidden;
	$self->{_show_visible}   = $show_visible;    #show user-visible windows only when selecting a window
	$self->{_ignore_type}    = $ignore_type;    #Ignore possibly wrong type hints

	#X11 protocol and XSHAPE ext
	require X11::Protocol;

	$self->{_x11} = X11::Protocol->new($ENV{'DISPLAY'});
	$self->{_x11}{ext_shape} = $self->{_x11}->init_extension('SHAPE');

	#main window
	$self->{_main_gtk_window} = $self->{_sc}->get_mainwindow;
	$self->{_dpi_scale} = $self->{_main_gtk_window}->get('scale-factor');

	#only used when selecting a window
	if (defined $self->{_mode} && $self->{_mode} =~ m/(window|section)/ig) {

		#check if compositing is available
		my $compos = $self->{_main_gtk_window}->get_screen->is_composited;

		#higlighter (borderless gtk window)
		$self->{_highlighter} = Gtk3::Window->new('popup');
		if ($compos) {
			my $screen = $self->{_main_gtk_window}->get_screen;
			# Glib::Object::Introspection doesn't support method call via
			# cross-package inheritance, call it as a free function instead
			# (X11Screen inherits from Screen)
			$self->{_highlighter}->set_visual(Gtk3::Gdk::Screen::get_rgba_visual($screen) || Gtk3::Gdb::Screen::get_system_visual($screen));
		}

		$self->{_highlighter}->set_app_paintable(TRUE);
		$self->{_highlighter}->set_decorated(FALSE);
		$self->{_highlighter}->set_skip_taskbar_hint(TRUE);
		$self->{_highlighter}->set_skip_pager_hint(TRUE);
		$self->{_highlighter}->set_keep_above(TRUE);
		$self->{_highlighter}->set_accept_focus(FALSE);

		#obtain current colors and font_desc from the main window
		my $style     = $self->{_main_gtk_window}->get_style_context;
		my $sel_bg    = $style->get_background_color('selected');
		my $font_fam  = $style->get_font('normal')->get_family;
		my $font_size = $style->get_font('normal')->get_size / Pango::SCALE;

		#get current monitor
		my $mon = $self->get_current_monitor;

		$self->{_highlighter_expose} = $self->{_highlighter}->signal_connect(
			'draw' => sub {
				return FALSE unless $self->{_highlighter}->get_window;

				#Place window and resize it
				$self->{_highlighter}->get_window->move_resize($self->{_c}{'cw'}{'x'} / $self->{_dpi_scale} - 3, $self->{_c}{'cw'}{'y'} / $self->{_dpi_scale} - 3, $self->{_c}{'cw'}{'width'} / $self->{_dpi_scale} + 6, $self->{_c}{'cw'}{'height'} / $self->{_dpi_scale} + 6);

				print $self->{_c}{'cw'}{'window'}->get_name, "\n" if $self->{_sc}->get_debug;

				my $text = Glib::Markup::escape_text($self->{_c}{'cw'}{'window'}->get_name);
				utf8::decode $text;

				my $sec_text = "\n" . $self->{_c}{'cw'}{'width'} . "x" . $self->{_c}{'cw'}{'height'};

				#window size and position
				my ($w, $h) = $self->{_highlighter}->get_size;
				my ($x, $y) = $self->{_highlighter}->get_position;

				#app icon
				my $icon = $self->{_c}{'cw'}{'window'}->get_icon;

				#create cairo context
				my $cr = $_[1];

				#pango layout
				my $layout = Pango::Cairo::create_layout($cr);
				$layout->set_width(($w - $icon->get_width - $font_size * 3) * Pango::SCALE);
				$layout->set_alignment('left');
				$layout->set_wrap('char');

				#warning if there are no subwindows
				#when we are in section mode and
				#a toplevel window was already selected
				if ($self->{_c}{'ws'}) {
					my $xwindow = $self->{_c}{'ws'}->get_xid;
					if (scalar @{$self->{_c}{'cw'}{$xwindow}} <= 1) {

						#error icon
						$icon = Gtk3::Widget::render_icon(Gtk3::Invisible->new, "gtk-dialog-error", 'dialog');

						#error message
						my $d = $self->{_sc}->get_gettext;
						$text     = $d->get("No subwindow detected");
						$sec_text = "\n" . $d->get("Maybe this window is using client-side windows (or similar).\nShutter is not yet able to query the tree information of such windows.");

						#wrap nicely
						$layout->set_wrap('word-char');
					}
				}

				#set text
				$layout->set_markup(
					"<span font_desc=\"$font_fam $font_size\" weight=\"bold\" foreground=\"#FFFFFF\">$text</span><span font_desc=\"$font_fam $font_size\" foreground=\"#FFFFFF\">$sec_text</span>");

				#get layout size
				my ($lw, $lh) = $layout->get_pixel_size;

				#adjust values
				$lw += $icon->get_width;
				$lh = $icon->get_height if $icon->get_height > $lh;

				#calculate values for rounded/shaped rectangle
				my $wi = $lw + $font_size * 3;
				my $hi = $lh + $font_size * 2;
				my $xi = int(($w - $wi) / 2);
				my $yi = int(($h - $hi) / 2);
				my $ri = 20;

				#two different ways - compositing or not
				if ($compos) {

					#fill window
					$cr->set_operator('source');
					$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.3);
					$cr->paint;

					#Parent window with text and icon
					if ($self->{_c}{'cw'}{'is_parent'}) {

						$cr->set_operator('over');

						#create small frame (window outlines)
						$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.75);
						$cr->set_line_width(6);
						$cr->rectangle(0, 0, $w, $h);
						$cr->stroke;

						if ($lw <= $w && $lh <= $h) {

							#rounded rectangle to display the window name
							$cr->move_to($xi + $ri, $yi);
							$cr->line_to($xi + $wi - $ri, $yi);
							$cr->curve_to($xi + $wi, $yi, $xi + $wi, $yi, $xi + $wi, $yi + $ri);
							$cr->line_to($xi + $wi, $yi + $hi - $ri);
							$cr->curve_to($xi + $wi, $yi + $hi, $xi + $wi, $yi + $hi, $xi + $wi - $ri, $yi + $hi);
							$cr->line_to($xi + $ri, $yi + $hi);
							$cr->curve_to($xi, $yi + $hi, $xi, $yi + $hi, $xi, $yi + $hi - $ri);
							$cr->line_to($xi, $yi + $ri);
							$cr->curve_to($xi, $yi, $xi, $yi, $xi + $ri, $yi);
							$cr->fill;

							#app icon
							Gtk3::Gdk::cairo_set_source_pixbuf($cr, $icon, $xi + $font_size, $yi + $font_size);
							$cr->paint;

							#draw the pango layout
							$cr->move_to($xi + $font_size * 2 + $icon->get_width, $yi + $font_size);
							Pango::Cairo::show_layout($cr, $layout);

						}

					} else {

						#create small frame
						$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.75);
						$cr->set_line_width(6);
						$cr->rectangle(0, 0, $w, $h);
						$cr->stroke;
					}

					#no compositing
				} else {

					#fill window
					$cr->set_operator('over');
					$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.75);
					$cr->paint;

					#Parent window with text and icon
					if ($self->{_c}{'cw'}{'is_parent'}) {

						if ($lw <= $w && $lh <= $h) {

							#app icon
							Gtk3::Gdk::cairo_set_source_pixbuf($cr, $icon, $xi + $font_size, $yi + $font_size);
							$cr->paint;

							#draw the pango layout
							$cr->move_to($xi + $font_size * 2 + $icon->get_width, $yi + $font_size);
							Pango::Cairo::show_layout($cr, $layout);
						}

					}

					my $shape_region1 = Cairo::Region->create({
						x=>0, y=>0, width=>$w, height=>$h,
					});
					my $shape_region2 = Cairo::Region->create({
						x=>3, y=>3, width=>$w - 6, height=>$h - 6,
					});
					my $shape_region3 = Cairo::Region->create({
						x=>$xi, y=>$yi, width=>$wi, height=>$hi,
					});

					#Parent window with text and icon
					if ($self->{_c}{'cw'}{'is_parent'}) {
						if ($lw <= $w && $lh <= $h) {
							$shape_region2->subtract($shape_region3);
						}
					}

					$shape_region1->subtract($shape_region2);
					$self->{_highlighter}->get_window->shape_combine_region($shape_region1, 0, 0);

				}

				return TRUE;
			});

	}

	return $self;
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
						});
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
	});

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
					});
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
			});
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
