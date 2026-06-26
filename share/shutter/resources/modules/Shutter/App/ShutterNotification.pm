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

package Shutter::App::ShutterNotification;

use Moo;
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Glib qw/TRUE FALSE/;

use Gtk3;

use Log::Any;

my $log = Log::Any->get_logger;

has _sc => (
	is       => 'rwp',
	required => 1,
);
has _nid => (
	is      => 'rwp',
	lazy    => 1,
	default => 0,
);
has _summary => (
	is  => 'rwp',
	clearer => 1,
);
has _body => (
	is  => 'rwp',
	clearer => 1,
);
has _notifications_timeout => (
	is      => 'rwp',
	lazy    => 1,
	default => 0,
);
has _enter_notify_timeout => (
	is      => 'rwp',
	lazy    => 1,
	default => 0,
);
has _notifications_window => (
	is       => 'rwp',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build__notifications_window',
);

sub _build__notifications_window ($self) {
	try {
		my $win = Gtk3::Window->new('popup');
		if ($self->_sc->main_window->get_screen->is_composited) {
			my $screen = $self->_sc->main_window->get_screen;

			$win->set_visual(Gtk3::Gdk::Screen::get_rgba_visual($screen) || Gtk3::Gdb::Screen::get_system_visual($screen));
		}

		$win->set_app_paintable(TRUE);
		$win->set_decorated(FALSE);
		$win->set_skip_taskbar_hint(TRUE);
		$win->set_skip_pager_hint(TRUE);
		$win->set_keep_above(TRUE);
		$win->set_accept_focus(FALSE);
		$win->add_events('GDK_ENTER_NOTIFY_MASK');

		my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($self->_sc->shutter_root . "/share/shutter/resources/icons/notify.svg");

		my $fixed = Gtk3::Fixed->new;
		$fixed->set_size_request(300, 120);
		$win->add($fixed);

		$win->signal_connect(
			'draw' => sub {

				return FALSE unless $self->_notifications_window;

				return FALSE unless $self->_summary;

				my $mon = $self->_sc->get_current_monitor;

				unless (defined $win->{'pos'}) {
					$win->move($mon->{x} + $mon->{width} - 315, $mon->{y} + $mon->{height} - 140);
					$win->{'pos'} = 1;
				}

				my ($w, $h) = $win->get_size;
				my ($x, $y) = $win->get_position;

				my $style     = $self->_sc->main_window->get_style_context;
				my $sel_bg    = Gtk3::Gdk::RGBA::parse('#131313');
				my $font_fam  = $style->get_font('normal')->get_family;
				my $font_size = $style->get_font('normal')->get_size / Pango::SCALE;

				my $cr = $_[1];

				my $layout = Pango::Cairo::create_layout($cr);
				$layout->set_width(($w - 30) * Pango::SCALE);

				$layout->set_height(($h - 20) * Pango::SCALE);

				$layout->set_ellipsize('middle');

				$layout->set_alignment('left');
				$layout->set_wrap('word-char');

				$layout->set_markup("<span font_desc=\"$font_fam $font_size\" weight=\"bold\" foreground=\"#FFFFFF\">"
						. Glib::Markup::escape_text($self->_summary)
						. "</span><span font_desc=\"$font_fam $font_size\" foreground=\"#FFFFFF\">\n"
						. Glib::Markup::escape_text($self->_body)
						. "</span>");

				$cr->set_operator('source');

				if ($self->_sc->main_window->get_screen->is_composited) {
					$cr->set_source_rgba(1.0, 1.0, 1.0, 0);
					Gtk3::Gdk::cairo_set_source_pixbuf($cr, $pixbuf, 0, 0);
					$cr->paint;
				} else {
					$cr->set_source_rgb($sel_bg->red, $sel_bg->green, $sel_bg->blue);
					$cr->paint;
				}

				$cr->set_operator('over');

				my ($lw, $lh) = $layout->get_pixel_size;
				$cr->move_to(($w - $lw) / 2, ($h - $lh) / 2);
				Pango::Cairo::show_layout($cr, $layout);

				return TRUE;
			});

		$win->signal_connect(
			'enter-notify-event' => sub {

				if ($self->_enter_notify_timeout) {
					Glib::Source->remove($self->_enter_notify_timeout);
				}

				my $mon = $self->_sc->get_current_monitor;

				if (defined $win->{'pos'} && $win->{'pos'} == 1) {
					$win->move($mon->{x} + $mon->{width} - 315, $mon->{y} + 40);
					$win->{'pos'} = 0;
				} else {
					$win->move($mon->{x} + $mon->{width} - 315, $mon->{y} + $mon->{height} - 140);
					$win->{'pos'} = 1;
				}

				$self->_set__enter_notify_timeout(Glib::Timeout->add(
					100,
					sub {
						$self->show($self->_summary, $self->_body);
						$self->_set__enter_notify_timeout(0);
						return FALSE;
					}));

				return FALSE;
			});

		return $win;
	} catch ($e) {
		$log->warn("ShutterNotification init warning: $e");
		return undef;
	}
}

sub BUILDARGS ($class, @args) {
	return {_sc => $args[0]};
}

sub show ($self, $summary, $body) {

	if ($self->_notifications_timeout) {
		Glib::Source->remove($self->_notifications_timeout);
	}

	$self->_set__summary($summary);
	$self->_set__body($body);

	$self->_notifications_window->show_all if $self->_notifications_window;

	$self->_notifications_window->queue_draw if $self->_notifications_window;

	$self->_set__notifications_timeout(Glib::Timeout->add(
		3000,
		sub {
			$self->close;
			$self->_set__notifications_timeout(0);
			return FALSE;
		}));

	return 0;
}

sub close ($self, $no_clear = undef) {

	unless ($no_clear) {
		$self->_clear_summary;
		$self->_clear_body;
	}

	$self->_notifications_window->hide if $self->_notifications_window;

	$self->_notifications_window->{'pos'} = undef if $self->_notifications_window;

	return 0;
}

1;
