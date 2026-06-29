###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2020-2021 Google LLC, contributed by Alexey Sokolov <sokolov@google.com>
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

package Shutter::App::Core::SettingsManager;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Glib       qw/TRUE FALSE/;
use File::Copy qw/mv/;
use File::Temp qw/tempfile/;
use Shutter::App::Directories;
use Shutter::App::Core::FileSystemAPI;
use JSON::MaybeXS;
use IO::File;

has '_common'   => (is => 'ro', required => 1);
has '_settings' => (is => 'rw', default  => sub { {} });
has '_json'     => (is => 'lazy', default => sub { JSON::MaybeXS->new->utf8(1)->pretty(1)->canonical(1) });



sub _settings_path ($self, $profilename = undef) {
	return defined $profilename && $profilename ne ""
		? Shutter::App::Directories::get_profile_settings_file($profilename)
		: Shutter::App::Directories::get_settings_file;
}

sub _accounts_path ($self, $profilename = undef) {
	return defined $profilename && $profilename ne ""
		? Shutter::App::Directories::get_profile_accounts_file($profilename)
		: Shutter::App::Directories::get_accounts_file;
}

sub save_settings ($self, $profilename = undef) {
	my $sc = $self->_common;
	my $sd = Shutter::App::SimpleDialogs->new($sc->main_window);
	my $d  = $sc->gettext_object;

	my $settingsfile = $self->_settings_path($profilename);

	my %settings = %{$self->_settings};
	$settings{'general'}->{'app_version'} = $sc->version . $sc->rev;

	eval {
		my $json_text = $self->_json->encode(\%settings);
		my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
		print $tmpfh $json_text;
		close $tmpfh;
		mv($tmpfilename, $settingsfile);
	};
	if ($@) {
		$sd->dlg_error_message($@, $d->get("Settings could not be saved!"));
		return FALSE;
	}
	return TRUE;
}

sub load_settings ($self, $profilename = undef) {
	my $sc  = $self->_common;
	my $d   = $sc->gettext_object;
	my $shf = $sc->get_helper_functions;
	my $sd  = Shutter::App::SimpleDialogs->new($sc->main_window);

	my $settingsfile = $self->_settings_path($profilename);

	my $settings = {};
	if ($shf->file_exists($settingsfile)) {

		eval {
			my $json_text = Shutter::App::Core::FileSystemAPI->new->slurp_utf8($settingsfile);
			$settings = $self->_json->decode($json_text);
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Settings could not be restored!"));
			Shutter::App::Core::FileSystemAPI->new->remove($settingsfile);
			$settings = {};
		}
	}
	$self->_settings($settings);
	return $settings;
}

sub get_setting ($self, $section, $key) {
	return $self->_settings->{$section}->{$key} if exists $self->_settings->{$section} && exists $self->_settings->{$section}->{$key};
	return;
}

sub set_setting ($self, $section, $key, $value) {
	$self->_settings->{$section} = {} unless exists $self->_settings->{$section};
	$self->_settings->{$section}->{$key} = $value;
	return;
}

sub load_accounts ($self, $profilename = undef) {
	my $sc  = $self->_common;
	my $d   = $sc->gettext_object;
	my $shf = $sc->get_helper_functions;
	my $sd  = Shutter::App::SimpleDialogs->new($sc->main_window);

	my $accountsfile = $self->_accounts_path($profilename);

	my %accounts;
	if ($shf->file_exists($accountsfile)) {

		eval {
			my $json_text = Shutter::App::Core::FileSystemAPI->new->slurp_utf8($accountsfile);
			my $parsed    = $self->_json->decode($json_text);
			$accounts{$_} = {%{$parsed->{$_}}} for keys %{$parsed};
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Account-settings could not be restored!"));
			Shutter::App::Core::FileSystemAPI->new->remove($accountsfile);
		}
	}

	require File::Glob;
	require File::Basename;
	my $shutter_root = $sc->shutter_root;
	my @sxcu_paths   = ("$shutter_root/share/shutter/resources/system/uploaders/*.sxcu", Shutter::App::Directories::get_uploaders_dir() . "/*.sxcu");
	foreach my $sxcu_path (@sxcu_paths) {
		my @sxcus = File::Glob::bsd_glob($sxcu_path);
		foreach my $ukey (@sxcus) {
			if (Shutter::App::Core::FileSystemAPI->new->is_regular_file($ukey)) {
				my ($name, $folder, $type) = File::Basename::fileparse($ukey, qr/\.[^.]*/);

				eval {
					my $json_text = Shutter::App::Core::FileSystemAPI->new->slurp_utf8($ukey);
					my $sxcu      = $self->_json->decode($json_text);

					my $display_name = $sxcu->{Name} // $name;

					$accounts{$display_name}->{path}                       = $ukey;
					$accounts{$display_name}->{module}                     = "ShareX";
					$accounts{$display_name}->{host}                       = $sxcu->{RequestURL};
					$accounts{$display_name}->{folder}                     = "$shutter_root/share/shutter/perl/Shutter/Upload";
					$accounts{$display_name}->{description}                = "ShareX Custom Uploader ($display_name)";
					$accounts{$display_name}->{register_color}             = "blue";
					$accounts{$display_name}->{register_text}              = "";
					$accounts{$display_name}->{supports_anonymous_upload}  = TRUE;
					$accounts{$display_name}->{supports_authorized_upload} = FALSE;
					$accounts{$display_name}->{supports_oauth_upload}      = FALSE;
					$accounts{$display_name}->{username}                   = "" unless defined $accounts{$display_name}->{username};
					$accounts{$display_name}->{password}                   = "" unless defined $accounts{$display_name}->{password};
				};
			}
		}
	}

	return \%accounts;
}

1;

__END__

=head1 NAME

Shutter::App::Core::SettingsManager - Application settings persistence

=head1 SYNOPSIS

    my $sm = Shutter::App::Core::SettingsManager->new(_common => $sc);
    $sm->set_setting('general', 'filetype', 'png');
    $sm->save_settings;

=head1 DESCRIPTION

Persists application settings and accounts to disk as JSON.

=cut