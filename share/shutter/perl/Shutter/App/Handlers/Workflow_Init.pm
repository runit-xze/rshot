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
use Glib     qw/TRUE FALSE/;
use IPC::Cmd qw(can_run);
use Log::Any;
use Shutter::App::Directories;

has cli => (is => 'ro', required => 1);

sub fct_init_depend ($self) {
	my $cli = $self->cli;
	my $log = Log::Any->get_logger;

	#imagemagick/perlmagick
	unless (can_run('convert')) {

		# warn "WARNING: imagemagick is missing --> color reduction features disabled!\n\n";
	}

	#gnome-web-photo
	unless (can_run('gnome-web-photo')) {

		# warn "WARNING: gnome-web-photo is missing --> screenshots of websites will be disabled!\n\n";
		$cli->{_gnome_web_photo} = FALSE;
	}

	#nautilus-sendto
	unless (can_run('nautilus-sendto')) {
		$cli->{_nautilus_sendto} = FALSE;
	}

	#goocanvas
	eval { require GooCanvas2; require GooCanvas2::CairoTypes; };
	if ($@) {
		$log->error("Failed to load GooCanvas2: $@");
		$cli->{_goocanvas} = FALSE;
	} else {
		$log->info("GooCanvas2 loaded successfully");
		$cli->{_goocanvas} = TRUE;
	}

	#libimage-exiftool-perl
	eval { require Image::ExifTool };
	if ($@) {
		$cli->{_exiftool} = FALSE;
	}

	#dev-libs/libappindicator[introspection]
	eval { Glib::Object::Introspection->setup(basename => 'AppIndicator3', version => '0.1', package => 'AppIndicator',); };
	if ($@) {
		eval { Glib::Object::Introspection->setup(basename => 'AyatanaAppIndicator3', version => '0.1', package => 'AppIndicator',); };
		if ($@) {
			$cli->{_appindicator} = FALSE;
		}
	}

	return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Workflow_Init - Workflow initialization handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
