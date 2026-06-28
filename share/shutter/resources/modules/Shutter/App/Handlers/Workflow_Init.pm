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
use Glib       qw/TRUE FALSE/;
use File::Glob qw(bsd_glob);
use IPC::Cmd   qw(can_run);
use Log::Any;
use Shutter::App::Directories;
use Shutter::App::Constants qw(SHUTTER_VERSION SHUTTER_REV);

has cli => (is => 'ro', required => 1);

sub fct_init_debug_output ($self) {
	my $log = Log::Any->get_logger;

	$log->debug("gathering system information...");
	$log->debug("Shutter " . SHUTTER_VERSION . " " . SHUTTER_REV);

	#kernel info
	if (can_run('uname')) {
		require Shutter::App::Core::SecureSystemCommandAPI;
		my $res = Shutter::App::Core::SecureSystemCommandAPI->new->capture('uname', '-a');
		my $uname = $res->{stdout};
		chomp $uname;
		$log->debug($uname);
	}

	eval {
		open my $fh, '<', '/etc/os-release' or die;
		my %map = map {
			chomp;
			my ($key, $value) = split /=/, $_, 2;
			$value =~ s/^(['"])(.*)\1$/$2/;
			($key, $value)
		} <$fh>;
		my $os_info = join(' ', grep { $_ } map { $map{$_} } qw/NAME VERSION_ID BUILD_ID/);
		$log->debug($os_info);
	};
	$log->debug("Cannot open /etc/os-release") if $@;

	$log->debug(sprintf "Glib %s", $Glib::VERSION);
	$log->debug(sprintf "Gtk3 %s", $Gtk3::VERSION);

	# The version info stuff appeared in 1.040.
	if ($Glib::VERSION >= 1.040) {
		$log->debug("Glib built for " . join(".", Glib->GET_VERSION_INFO) . ", running with " . join(".", Glib::major_version(), Glib::minor_version(), Glib::micro_version()));
	}
	if ($Gtk3::VERSION >= 1.040) {
		$log->debug("Gtk3 built for " . join(".", Gtk3->GET_VERSION_INFO) . ", running with " . join(".", Gtk3::major_version(), Gtk3::minor_version(), Gtk3::micro_version()));
	}

	return TRUE;
}

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

sub fct_init_unsaved_files ($self) {

	#delete all files in this folder
	#except the ones that are in the current session
	my @unsaved_files = bsd_glob(Shutter::App::Directories::get_cache_dir() . "/*");
	foreach my $unsaved_file (@unsaved_files) {
		utf8::decode $unsaved_file;
		if (defined &fct_get_key_by_filename) {
			unless (fct_get_key_by_filename($unsaved_file)) {
				Shutter::App::Core::FileSystemAPI->new->Shutter::App::Core::FileSystemAPI->new->remove($unsaved_file);
			}
		}
	}
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Workflow_Init - Workflow initialization handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
