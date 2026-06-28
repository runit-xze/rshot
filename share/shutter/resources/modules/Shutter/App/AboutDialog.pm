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

package Shutter::App::AboutDialog;

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

#--------------------------------------

has '_sc' => (is => 'ro', required => 1, init_arg => '_sc');

# Accept both positional ->new($sc) and named ->new(_sc => $sc)
around BUILDARGS => sub ($orig, $class, @args) {
	return $class->$orig(@args)           if @args % 2 == 0 && @args > 0 && $args[0] =~ /^_/;
	return $class->$orig(_sc => $args[0]) if @args == 1;
	return $class->$orig(@args);
};

sub show ($self) {

	my $shf          = Shutter::App::HelperFunctions->new($self->_sc);
	my $shutter_root = $self->_sc->shutter_root;
	my $d            = $self->_sc->gettext_object;

	require Shutter::App::Core::FileSystemAPI;
	my $all_hint = Shutter::App::Core::FileSystemAPI->new->slurp_utf8("$shutter_root/share/shutter/resources/license/gplv3_hint");
	my $all_gpl  = Shutter::App::Core::FileSystemAPI->new->slurp_utf8("$shutter_root/share/shutter/resources/license/gplv3");
	my @all_dev  = Shutter::App::Core::FileSystemAPI->new->lines_utf8("$shutter_root/share/shutter/resources/credits/dev", { chomp => 1 });
	my @all_art  = Shutter::App::Core::FileSystemAPI->new->lines_utf8("$shutter_root/share/shutter/resources/credits/art", { chomp => 1 });

	my @lines = ("rshot v1", "", "Original Developers:", @all_dev, "", "Artists:", @all_art, "", "Special Thanks:", "runit", "Google", "Anthropic", "for making this possible!");

	my $dialog = Gtk3::Dialog->new("About rshot", undef, ['destroy-with-parent'], 'gtk-close' => 'close');
	$dialog->set_default_size(450, 400);

	my $da = Gtk3::DrawingArea->new();
	$da->set_size_request(450, 400);

	my $offset = 400;
	my $timer  = Glib::Timeout->add(
		30,
		sub {
			$offset -= 1.5;
			$offset = 400     if $offset < -(scalar(@lines) * 25 + 50);
			$da->queue_draw() if $da->get_window;
			return TRUE;
		});

	my $logo_surface;
	eval { $logo_surface = Cairo::ImageSurface->create_from_png('/home/ashley/.gemini/antigravity-cli/brain/422b5aec-b8a4-4114-9ace-5e53b45146a1/rshot_logo_transparent.png'); };

	$da->signal_connect(
		'draw' => sub {
			my ($widget, $cr) = @_;

			# Fancy gradient background with a pulse based on offset
			my $pulse = (sin($offset / 20) + 1) / 2;
			my $pat   = Cairo::LinearGradient->create(0, 0, 0, 400);
			$pat->add_color_stop_rgb(0, 0.05,               0.05, 0.1);
			$pat->add_color_stop_rgb(1, 0.2 + 0.1 * $pulse, 0.3,  0.5 + 0.2 * $pulse);
			$cr->set_source($pat);
			$cr->paint;

			# Draw the rshot logo behind the scrolling text
			if ($logo_surface) {
				$cr->save;
				$cr->translate(225, 200);    # Center of the dialog
											 # Add a slow rotation effect!
				$cr->rotate($offset / 100);
				$cr->scale(0.3, 0.3);
				$cr->set_source_surface($logo_surface, -512, -512);
				$cr->paint_with_alpha(0.15 + 0.1 * $pulse);    # Subtle semi-transparent watermark
				$cr->restore;
			}

			# Draw scrolling text
			$cr->select_font_face("Sans", 'normal', 'bold');

			my $y = $offset;
			for my $i (0 .. $#lines) {
				my $line = $lines[$i];
				if ($i == 0) {
					$cr->set_source_rgb(1, 0.8, 0.2);    # Gold for title
					$cr->set_font_size(36);
					my $extents = $cr->text_extents($line);
					$cr->move_to(225 - ($extents->{width} / 2), $y);
					$cr->show_text($line);
				} elsif ($line =~ /:$/) {
					$cr->set_source_rgb(0.6, 0.9, 1);    # Light cyan for headers
					$cr->set_font_size(20);
					$cr->move_to(30, $y);
					$cr->show_text($line);
				} elsif ($line eq "runit") {

					# Rainbow colors
					my $r = (sin($offset / 10 + 0) + 1) / 2;
					my $g = (sin($offset / 10 + 2) + 1) / 2;
					my $b = (sin($offset / 10 + 4) + 1) / 2;
					$cr->set_source_rgb($r, $g, $b);
					$cr->set_font_size(24);              # Make it bigger

					my $extents = $cr->text_extents($line);
					my $cx      = 225;
					my $cy      = $y - ($extents->{height} / 2);

					$cr->save;
					$cr->translate($cx, $cy);
					$cr->rotate($offset / 10);           # Fast spin!
					$cr->move_to(-$extents->{width} / 2, $extents->{height} / 2);
					$cr->show_text($line);
					$cr->restore;
				} else {
					$cr->set_source_rgb(1, 1, 1);        # White for names
					$cr->set_font_size(15);
					$cr->move_to(50, $y);
					$cr->show_text($line);
				}
				$y += ($i == 0) ? 50 : ($line eq "runit") ? 35 : 25;
			}
			return FALSE;
		});

	$dialog->get_content_area->pack_start($da, TRUE, TRUE, 0);
	$dialog->show_all;
	$dialog->signal_connect(
		'response' => sub {
			Glib::Source->remove($timer);
			$dialog->destroy;
		});
	return;
}

1;
