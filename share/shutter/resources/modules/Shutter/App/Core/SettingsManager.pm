###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2020-2021 Google LLC, contributed by Alexey Sokolov <sokolov@google.com>
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

package Shutter::App::Core::SettingsManager;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib       qw/TRUE FALSE/;
use File::Copy qw/cp mv/;
use File::Temp qw/tempfile/;
use File::Spec;
use XML::Simple;
use IO::File;

has '_common'   => (is => 'ro', required => 1);
has '_settings' => (is => 'rw', default  => sub { {} });

sub save_settings ($self, $profilename = undef) {
	my $sc  = $self->_common;
	my $shf = $sc->get_helper_functions;
	my $sd  = Shutter::App::SimpleDialogs->new($sc->main_window);
	my $d   = $sc->gettext_object;

	my $settingsfile = "$ENV{ HOME }/.shutter/settings.xml";
	if (defined $profilename && $profilename ne "") {
		$settingsfile = "$ENV{ HOME }/.shutter/profiles/$profilename.xml";
	}

	my %settings = %{$self->_settings};
	$settings{'general'}->{'app_version'} = $sc->version . $sc->rev;

	eval {
		my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
		XMLout(\%settings, OutputFile => $tmpfilename, NoAttr => 1, KeepRoot => 1);
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

	my $settingsfile = "$ENV{ HOME }/.shutter/settings.xml";
	$settingsfile = "$ENV{ HOME }/.shutter/profiles/$profilename.xml" if defined $profilename;

	my $settings_xml = {};
	if ($shf->file_exists($settingsfile)) {
		eval { $settings_xml = XMLin(IO::File->new($settingsfile), ForceArray => 0, KeyAttr => [], KeepRoot => 1); };
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Settings could not be restored!"));
			unlink $settingsfile;
		}
	}
	$self->_settings($settings_xml);
	return $settings_xml;
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

	my $accountsfile = "$ENV{ HOME }/.shutter/accounts.xml";
	$accountsfile = "$ENV{ HOME }/.shutter/profiles/$profilename\_accounts.xml" if defined $profilename;

	my %accounts;
	if ($shf->file_exists($accountsfile)) {
		my $accounts_xml;
		eval { $accounts_xml = XMLin(IO::File->new($accountsfile)) };
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Account-settings could not be restored!"));
			unlink $accountsfile;
		} else {
			foreach my $ac (keys %{$accounts_xml}) {
				if ($shf->file_exists($accounts_xml->{$ac}->{path})) {
					$accounts{$ac} = $accounts_xml->{$ac};
				}
			}
		}
	}

	require File::Glob;
	require File::Basename;
	require JSON::MaybeXS;
	my $shutter_root = $sc->shutter_root;
	my @sxcu_paths   = ("$shutter_root/share/shutter/resources/system/uploaders/*.sxcu", $ENV{'HOME'} . "/.shutter/uploaders/*.sxcu");
	my $json         = JSON::MaybeXS->new;
	foreach my $sxcu_path (@sxcu_paths) {
		my @sxcus = File::Glob::bsd_glob($sxcu_path);
		foreach my $ukey (@sxcus) {
			if (-f $ukey) {
				my ($name, $folder, $type) = File::Basename::fileparse($ukey, qr/\.[^.]*/);

				eval {
					open(my $fh, '<', $ukey) or die "Cannot open $ukey";
					my $json_text = do { local $/; <$fh> };
					close($fh);
					my $sxcu = $json->decode($json_text);

					my $display_name = $sxcu->{Name} || $name;

					$accounts{$display_name}->{path}                       = $ukey;
					$accounts{$display_name}->{module}                     = "ShareX";
					$accounts{$display_name}->{host}                       = $sxcu->{RequestURL};
					$accounts{$display_name}->{folder}                     = "$shutter_root/share/shutter/resources/modules/Shutter/Upload";
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
