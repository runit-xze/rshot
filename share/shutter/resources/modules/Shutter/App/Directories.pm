###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2021 Alexander Ruzhnikov <ruzhnikov85@gmail.com>
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

package Shutter::App::Directories;

use v5.40;
use feature "try";
no warnings "experimental::try";

use Glib qw/ TRUE /;

use constant {
	SHUTTER_DIR        => "shutter",
	UNSAVED_DIR        => "unsaved",
	TEMP_DIR           => "temp",
	AUTOSTART_DIR      => "autostart",
	HIDDEN_SHUTTER_DIR => ".shutter",
	PROFILES_DIR       => "profiles"
};

sub create_if_not_exists ($dir) {
	Shutter::App::Core::FileSystemAPI->new->make_dir($dir) unless Shutter::App::Core::FileSystemAPI->new->is_directory($dir) && Shutter::App::Core::FileSystemAPI->new->is_path_readable($dir);

	return $dir;
}

sub get_root_dir {
	return create_if_not_exists(Glib::get_user_cache_dir() . "/" . SHUTTER_DIR);
}

sub get_cache_dir {
	return create_if_not_exists(get_root_dir() . "/" . UNSAVED_DIR);
}

sub get_temp_dir {
	return create_if_not_exists(get_root_dir() . "/" . TEMP_DIR);
}

sub get_autostart_dir {
	return create_if_not_exists(Glib::get_user_config_dir() . "/" . AUTOSTART_DIR);
}

sub get_home_dir   { return Glib::get_home_dir() }
sub get_config_dir { return Glib::get_user_config_dir() }

sub get_hidden_home_dir       { return Glib::get_home_dir() . "/" . HIDDEN_SHUTTER_DIR }
sub get_hidden_profiles_dir   { return get_hidden_home_dir() . "/" . PROFILES_DIR }
sub get_settings_file         { return get_hidden_home_dir() . "/settings.xml" }
sub get_accounts_file         { return get_hidden_home_dir() . "/accounts.xml" }
sub get_session_file          { return get_hidden_home_dir() . "/session.xml" }
sub get_printing_file         { return get_hidden_home_dir() . "/printing.xml" }
sub get_drawingtool_file      { return get_hidden_home_dir() . "/drawingtool.xml" }
sub get_uploaders_dir         { return get_hidden_home_dir() . "/uploaders" }
sub get_plugins_dir           { return get_hidden_home_dir() . "/plugins" }

sub get_profile_settings_file ($name) {
	return get_hidden_profiles_dir() . "/${name}.xml";
}

sub get_profile_accounts_file ($name) {
	return get_hidden_profiles_dir() . "/${name}_accounts.xml";
}

sub create_hidden_home_dir_if_not_exist {
	my $hidden_dir          = get_hidden_home_dir;
	my $hidden_profiles_dir = get_hidden_profiles_dir;

	Shutter::App::Core::FileSystemAPI->new->make_dir($hidden_dir)          unless Shutter::App::Core::FileSystemAPI->new->is_directory($hidden_dir);
	Shutter::App::Core::FileSystemAPI->new->make_dir($hidden_profiles_dir) unless Shutter::App::Core::FileSystemAPI->new->is_directory($hidden_profiles_dir);

	return TRUE;
}

1;
