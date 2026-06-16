###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2025 Shutter Team
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
###################################################

package Shutter::App::Handlers::Workflow_Init;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_init_debug_output {

		print "\nINFO: gathering system information...";
		print "\n";
		print "\n";
		print "Shutter ";
		print SHUTTER_VERSION;
		print ' ';
		print SHUTTER_REV;
		print "\n";

		#kernel info
		if (can_run('uname')) {
			print `uname -a`, "\n";
		}

		eval {
			open my $fh, '<', '/etc/os-release' or die;
			my %map = map {
				chomp;
				my ($key, $value) = split /=/, $_, 2;
				$value =~ s/^(['"])(.*)\1$/$2/;
				($key, $value)
			} <$fh>;
			local $, = ' ';
			say grep { $_ } map { $map{$_} } qw/NAME VERSION_ID BUILD_ID/;
		};
		say "Cannot open /etc/os-release" if $@;

		printf "Glib %s \n", $Glib::VERSION;
		printf "Gtk3 %s \n", $Gtk3::VERSION;
		print "\n";

		# The version info stuff appeared in 1.040.
		print "Glib built for " . join(".", Glib->GET_VERSION_INFO) . ", running with " . join(".", Glib::major_version(), Glib::minor_version(), Glib::micro_version()) . "\n"
			if $Glib::VERSION >= 1.040;
		print "Gtk3 built for " . join(".", Gtk3->GET_VERSION_INFO) . ", running with " . join(".", Gtk3::major_version(), Gtk3::minor_version(), Gtk3::micro_version()) . "\n"
			if $Gtk3::VERSION >= 1.040;
		print "\n";

		return TRUE;
	}

	sub fct_init_depend {

		#imagemagick/perlmagick
		unless (can_run('convert')) {
			# warn "WARNING: imagemagick is missing --> color reduction features disabled!\n\n";
		}

		#gnome-web-photo
		unless (can_run('gnome-web-photo')) {
			# warn "WARNING: gnome-web-photo is missing --> screenshots of websites will be disabled!\n\n";
			$gnome_web_photo = FALSE;
		}

		#nautilus-sendto
		unless (can_run('nautilus-sendto')) {
			$nautilus_sendto = FALSE;
		}

		#goocanvas
		eval { require GooCanvas2; require GooCanvas2::CairoTypes; };
		if ($@) {
			# warn "WARNING: Goo::Canvas/libgoo-canvas-perl is missing --> drawing tool will be disabled!\n\n";
			$goocanvas = FALSE;
		}

		#libimage-exiftool-perl
		eval { require Image::ExifTool };
		if ($@) {
			# warn "WARNING: Image::ExifTool is missing --> writing Exif information will be disabled!\n\n";
			$exiftool = FALSE;
		}

		#dev-libs/libappindicator[introspection]
		eval {
			Glib::Object::Introspection->setup(
				basename => 'AppIndicator3',
				version  => '0.1',
				package  => 'AppIndicator',
			);
		};
		if ($@) {
			eval {
				Glib::Object::Introspection->setup(
					basename => 'AyatanaAppIndicator3',
					version  => '0.1',
					package  => 'AppIndicator',
				);
			};
			if ($@) {
				# warn "WARNING: AppIndicator is missing --> there will be no icon showing up in the status bar when running Unity!\n\n";
				$appindicator = FALSE;
			}
		}

		return TRUE;
	}

	sub fct_init_unsaved_files {

		#delete all files in this folder
		#except the ones that are in the current session
		my @unsaved_files = bsd_glob(Shutter::App::Directories::get_cache_dir() . "/*");
		foreach my $unsaved_file (@unsaved_files) {
			utf8::decode $unsaved_file;
			print $unsaved_file, " checking \n" if $sc->get_debug;
			unless (fct_get_key_by_filename($unsaved_file)) {
				print $unsaved_file, " deleted \n" if $sc->get_debug;
				unlink $unsaved_file;
			}
		}
	}


1;
