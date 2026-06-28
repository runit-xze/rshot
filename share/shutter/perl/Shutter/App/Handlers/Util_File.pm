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

package Shutter::App::Handlers::Util_File;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib                    qw/TRUE FALSE/;
use File::Basename          qw(fileparse dirname);
use File::Glob              qw(bsd_glob);
use Shutter::App::Directories;
use Shutter::App::Constants qw(SHUTTER_NAME SHUTTER_VERSION);

has cli => (is => 'ro', required => 1);

sub fct_check_installed_plugins ($self) {
	my $cli          = $self->cli;
	my $sc           = $cli->sc;
	my $d            = $sc->gettext_object;
	my $window       = $cli->window;
	my $shutter_root = $cli->shutter_root;
	my $lp           = $cli->{_lp};
	my $shf          = $cli->shf;
	my $plugins      = $cli->{_plugins};

	my $plugin_dialog = Gtk3::MessageDialog->new($window, [qw/modal destroy-with-parent/], 'info', 'close', $d->get("Updating plugin information"));
	$plugin_dialog->{destroyed} = FALSE;

	$plugin_dialog->set_title("Shutter");

	$plugin_dialog->set('secondary-text' => $d->get("Please wait while Shutter updates the plugin information") . ".");

	$plugin_dialog->signal_connect(response => sub { $plugin_dialog->{destroyed} = TRUE; $_[0]->destroy; });

	$plugin_dialog->set_resizable(TRUE);

	my $plugin_progress = Gtk3::ProgressBar->new;
	$plugin_progress->set_no_show_all(TRUE);
	$plugin_progress->set_ellipsize('middle');
	$plugin_progress->set_orientation('horizontal');
	$plugin_progress->set_fraction(0);

	$plugin_dialog->get_child->add($plugin_progress);
	my $current_plugin = Gtk3::Label->new("");
	$current_plugin->set_line_wrap(TRUE);
	$plugin_dialog->get_child->add($current_plugin);

	my @plugin_paths = ("$shutter_root/share/shutter/resources/system/plugins/*/*", "$ENV{'HOME'}/.shutter/plugins/*/*");

	#fallback icon
	my $fb_pixbuf_path = "$shutter_root/share/shutter/resources/icons/executable.svg";
	my $fb_pixbuf      = $lp->load($fb_pixbuf_path, $shf->icon_size('menu')) if $lp;

	foreach my $plugin_path (@plugin_paths) {
		my @p_list = bsd_glob($plugin_path);
		foreach my $pkey (@p_list) {
			if (Shutter::App::Core::FileSystemAPI->new->is_directory($pkey)) {
				my $dir_name = $pkey;

				#parse filename
				my ($name, $folder, $type) = fileparse($dir_name, qr/\.[^.]*/);

				#file exists
				if ($shf->file_exists("$dir_name/$name")) {

					#file is executable
					if ($shf->file_executable("$dir_name/$name")) {

						#new plugin information?
						unless ($plugins->{$pkey}->{'binary'}
							&& $plugins->{$pkey}->{'name'}
							&& $plugins->{$pkey}->{'category'}
							&& $plugins->{$pkey}->{'tooltip'}
							&& $plugins->{$pkey}->{'lang'})
						{

							#show dialog and progress bar
							if (   !$plugin_dialog->get_window
								&& !$plugin_dialog->{destroyed})
							{
								$plugin_progress->show;
								$plugin_dialog->show_all;
							}

							print "\nINFO: new plugin information detected - $dir_name/$name\n";

							#path to executable
							$plugins->{$pkey}->{'binary'} = "$dir_name/$name";

							#name
							$plugins->{$pkey}->{'name'} = fct_plugin_get_info($plugins->{$pkey}->{'binary'}, 'name') if defined &fct_plugin_get_info;

							#category
							$plugins->{$pkey}->{'category'} = fct_plugin_get_info($plugins->{$pkey}->{'binary'}, 'sort') if defined &fct_plugin_get_info;

							#tooltip
							$plugins->{$pkey}->{'tooltip'} = fct_plugin_get_info($plugins->{$pkey}->{'binary'}, 'tip') if defined &fct_plugin_get_info;

							#language (shell, perl etc.)
							my $folder_name = dirname($dir_name);
							$folder_name =~ /.*\/(.*)/;
							$plugins->{$pkey}->{'lang'} = $1;

							#refresh the progressbar
							$plugin_progress->pulse;
							$current_plugin->set_text($plugins->{$pkey}->{'binary'});

							#refresh gui
							fct_update_gui() if defined &fct_update_gui;

						}

						$plugins->{$pkey}->{'lang'} = "shell"
							if ($plugins->{$pkey}->{'lang'} // '') eq "";

						chomp($plugins->{$pkey}->{'name'})     if defined $plugins->{$pkey}->{'name'};
						chomp($plugins->{$pkey}->{'category'}) if defined $plugins->{$pkey}->{'category'};
						chomp($plugins->{$pkey}->{'tooltip'})  if defined $plugins->{$pkey}->{'tooltip'};
						chomp($plugins->{$pkey}->{'lang'})     if defined $plugins->{$pkey}->{'lang'};

						#pixbuf
						$plugins->{$pkey}->{'pixbuf'} = $plugins->{$pkey}->{'binary'} . ".png"
							if ($shf->file_exists($plugins->{$pkey}->{'binary'} . ".png"));
						$plugins->{$pkey}->{'pixbuf'} = $plugins->{$pkey}->{'binary'} . ".svg"
							if ($shf->file_exists($plugins->{$pkey}->{'binary'} . ".svg"));

						if ($shf->file_exists($plugins->{$pkey}->{'pixbuf'})) {
							$plugins->{$pkey}->{'pixbuf_object'} = $lp->load($plugins->{$pkey}->{'pixbuf'}, $shf->icon_size('menu')) if $lp;
						} else {
							$plugins->{$pkey}->{'pixbuf'}        = $fb_pixbuf_path;
							$plugins->{$pkey}->{'pixbuf_object'} = $fb_pixbuf;
						}
						if ($sc->debug) {
							print "$plugins->{$pkey}->{'name'} - $plugins->{$pkey}->{'binary'}\n" if defined $plugins->{$pkey}->{'name'};
						}

					} else {
						my $changed = chmod(0755, "$dir_name/$name");
						unless ($changed) {
							print "\nERROR: plugin exists but is not executable - $dir_name/$name\n";
							delete $plugins->{$pkey};
						}
					}

				} else {
					delete $plugins->{$pkey};
				}

			}
		}
	}

	#destroys the plugin dialog
	$plugin_dialog->response('ok');

	return TRUE;
}

sub fct_check_installed_programs ($self) {
	my $cli      = $self->cli;
	my $progname = $cli->{_progname};

	#update list of available programs in settings dialog as well
	if ($progname) {

		my $model         = $progname->get_model();
		my $progname_iter = $progname->get_active_iter();

		#get last prog
		my $progname_value;
		if (defined $progname_iter) {
			$progname_value = $model->get_value($progname_iter, 1);
		}

		#rebuild model with new hash of installed programs...
		$model = fct_get_program_model() if defined &fct_get_program_model;
		if ($model) {
			$progname->set_model($model);

			#...and try to set last	value
			if ($progname_value) {
				$model->foreach(\&fct_iter_programs, $progname_value) if defined &fct_iter_programs;
			} else {
				$progname->set_active(0);
			}

			#nothing has been set
			if ($progname->get_active == -1) {
				$progname->set_active(0);
			}
		}
	}

	return TRUE;
}

sub fct_check_installed_upload_plugins ($self) {
	my $cli          = $self->cli;
	my $sc           = $cli->sc;
	my $d            = $sc->gettext_object;
	my $window       = $cli->window;
	my $shutter_root = $cli->shutter_root;
	my $shf          = $cli->shf;
	my $accounts     = $cli->{_accounts};

	my $upload_plugin_dialog = Gtk3::MessageDialog->new($window, [qw/modal destroy-with-parent/], 'info', 'close', $d->get("Updating upload plugin information"));
	$upload_plugin_dialog->{destroyed} = FALSE;

	$upload_plugin_dialog->set_title("Shutter");

	$upload_plugin_dialog->set('secondary-text' => $d->get("Please wait while Shutter updates the upload plugin information") . ".");

	$upload_plugin_dialog->signal_connect(response => sub { $upload_plugin_dialog->{destroyed} = TRUE; $_[0]->destroy; });

	$upload_plugin_dialog->set_resizable(TRUE);

	my $upload_plugin_progress = Gtk3::ProgressBar->new;
	$upload_plugin_progress->set_no_show_all(TRUE);
	$upload_plugin_progress->set_ellipsize('middle');
	$upload_plugin_progress->set_orientation('horizontal');
	$upload_plugin_progress->set_fraction(0);

	$upload_plugin_dialog->get_child->add($upload_plugin_progress);
	my $current_plugin = Gtk3::Label->new("");
	$current_plugin->set_line_wrap(TRUE);
	$upload_plugin_dialog->get_child->add($current_plugin);

	my @upload_plugin_paths = ("$shutter_root/share/shutter/resources/system/upload_plugins/upload/*");

	foreach my $upload_plugin_path (@upload_plugin_paths) {
		my @u_list = bsd_glob($upload_plugin_path);
		foreach my $ukey (@u_list) {

			#Checking if file exists
			if ($shf->file_exists("$ukey")) {

				#parse filename
				my ($name, $folder, $type) = fileparse($ukey, qr/\.[^.]*/);

				#file is executable
				if ($shf->file_executable("$ukey")) {

					if (   !exists $accounts->{$name}
						|| !exists $accounts->{$name}->{module}
						|| ($accounts->{$name}->{supports_anonymous_upload}  // '') ne (fct_upload_plugin_get_info($ukey, 'supports_anonymous_upload')  // '')
						|| ($accounts->{$name}->{supports_authorized_upload} // '') ne (fct_upload_plugin_get_info($ukey, 'supports_authorized_upload') // '')
						|| ($accounts->{$name}->{supports_oauth_upload}      // '') ne (fct_upload_plugin_get_info($ukey, 'supports_oauth_upload')      // ''))
					{

						#show dialog and progress bar
						if (   !$upload_plugin_dialog->get_window
							&& !$upload_plugin_dialog->{destroyed})
						{
							$upload_plugin_progress->show;
							$upload_plugin_dialog->show_all;
						}

						print "\nINFO: new upload-plugin information detected - $folder$name\n";

						if (defined &fct_upload_plugin_get_info && fct_upload_plugin_get_info($ukey, 'module')) {

							# Path
							$accounts->{$name}->{path} = $ukey;

							# Module Name
							$accounts->{$name}->{module} = fct_upload_plugin_get_info($ukey, 'module');

							# URL
							$accounts->{$name}->{host} = fct_upload_plugin_get_info($ukey, 'url');

							# Folder
							$accounts->{$name}->{folder} = $folder;

							# Description
							$accounts->{$name}->{description} = fct_plugin_get_info($ukey, 'description') if defined &fct_plugin_get_info;

							# Username
							$accounts->{$name}->{username} = ""
								unless defined $accounts->{$name}->{username};

							# Password
							$accounts->{$name}->{password} = ""
								unless defined $accounts->{$name}->{password};

							# Register Color
							$accounts->{$name}->{register_color} = "blue";

							# Register Text
							$accounts->{$name}->{register_text} = fct_upload_plugin_get_info($ukey, 'registration');

							# Upload Features
							$accounts->{$name}->{supports_anonymous_upload}  = fct_upload_plugin_get_info($ukey, 'supports_anonymous_upload');
							$accounts->{$name}->{supports_authorized_upload} = fct_upload_plugin_get_info($ukey, 'supports_authorized_upload');
							$accounts->{$name}->{supports_oauth_upload}      = fct_upload_plugin_get_info($ukey, 'supports_oauth_upload');

							#refresh the progressbar
							$upload_plugin_progress->pulse;
							$current_plugin->set_text($accounts->{$name}->{path});

						} else {
							print "\nERROR: upload-plugin exists but does not work properly - $folder$name\n";
							delete $accounts->{$name};
						}

						#refresh gui
						fct_update_gui() if defined &fct_update_gui;

					}

				} else {
					my $changed = chmod(0755, "$ukey");
					unless ($changed) {
						print "\nERROR: upload-plugin exists but is not executable - $ukey\n";
						delete $accounts->{$name};
					}
				}
			}
		}

	}

	# Parse custom ShareX (.sxcu) uploaders
	my @sxcu_paths = ("$shutter_root/share/shutter/resources/system/uploaders/*.sxcu", $ENV{'HOME'} . "/.shutter/uploaders/*.sxcu");
	use JSON::MaybeXS;
	my $json = JSON::MaybeXS->new;
	foreach my $sxcu_path (@sxcu_paths) {
		my @sxcus = bsd_glob($sxcu_path);
		foreach my $ukey (@sxcus) {
			if (Shutter::App::Core::FileSystemAPI->new->is_regular_file($ukey)) {
				my ($name, $folder, $type) = fileparse($ukey, qr/\.[^.]*/);

				eval {
					require Shutter::App::Core::FileSystemAPI;
					my $json_text = Shutter::App::Core::FileSystemAPI->new->slurp_utf8($ukey);
					my $sxcu = $json->decode($json_text);

					my $display_name = $sxcu->{Name} || $name;

					$accounts->{$display_name}->{path}                       = $ukey;
					$accounts->{$display_name}->{module}                     = "ShareX";
					$accounts->{$display_name}->{host}                       = $sxcu->{RequestURL};
					$accounts->{$display_name}->{folder}                     = "$shutter_root/share/shutter/perl/Shutter/Upload";
					$accounts->{$display_name}->{description}                = "ShareX Custom Uploader ($display_name)";
					$accounts->{$display_name}->{register_color}             = "blue";
					$accounts->{$display_name}->{register_text}              = "";
					$accounts->{$display_name}->{supports_anonymous_upload}  = TRUE;
					$accounts->{$display_name}->{supports_authorized_upload} = FALSE;
					$accounts->{$display_name}->{supports_oauth_upload}      = FALSE;
					$accounts->{$display_name}->{username}                   = "" unless defined $accounts->{$display_name}->{username};
					$accounts->{$display_name}->{password}                   = "" unless defined $accounts->{$display_name}->{password};
				};
				if ($@) {
					print "\nERROR: Could not parse .sxcu file $ukey: $@\n";
				}
			}
		}
	}

	#destroys the upload_plugin dialog
	$upload_plugin_dialog->response('ok');

	return TRUE;
}

sub fct_imagemagick_perform ($self, $function, $file, $data) {
	my $cli = $self->cli;
	my $shf = $cli->shf;
	my $lp  = $cli->{_lp};

	my $pixbuf = undef;
	my $result = undef;
	$file = $shf->switch_home_in_file($file);

	if ($function eq "reduce_colors") {
		require Shutter::App::Core::SecureSystemCommandAPI;
		my $res = Shutter::App::Core::SecureSystemCommandAPI->new->capture('convert', $file, '-colors', $data, $file);
		$result = $res->{stdout};
		$pixbuf = $lp->load($file) if $lp;
	}

	return $pixbuf;
}

sub fct_parse_filename_wildcards ($self, $filename_value, $screenshooter, $screenshot) {
	my $cli                        = $self->cli;
	my $sc                         = $cli->sc;
	my $combobox_settings_profiles = $cli->{_combobox_settings_profiles};
	my $x11_supported              = $cli->{_x11_supported};

	my $screenshot_name = $filename_value;

	print "Parsing wildcards for $screenshot_name\n"
		if $sc->debug;

	#parse width and height
	my ($swidth, $sheight) = (0, 0);
	if (defined $screenshot) {
		$swidth  = $screenshot->get_width;
		$sheight = $screenshot->get_height;

		$screenshot_name =~ s/\$w/$swidth/g;
		$screenshot_name =~ s/\$h/$sheight/g;
	} else {
		$screenshot_name =~ s/\$w/0/g;
		$screenshot_name =~ s/\$h/0/g;
	}

	print "Parsed \$width and \$height: $screenshot_name\n"
		if $sc->debug;

	#parse profile name
	my $current_pname = ($combobox_settings_profiles && $combobox_settings_profiles->get_active_text) || "";
	$screenshot_name =~ s/\$profile/$current_pname/g;

	print "Parsed \$profile: $screenshot_name\n"
		if $sc->debug;

	#set name
	#e.g. window or workspace name
	if ($x11_supported) {
		if ($screenshooter && (my $action_name = $screenshooter->get_action_name)) {
			utf8::decode $action_name;
			$action_name     =~ s/(\/|\#|\>|\<|\%|\*)/-/g;
			$screenshot_name =~ s/\$name/$action_name/g;

			#no blanks (special wildcard)
			$action_name     =~ s/\ //g;
			$screenshot_name =~ s/\$nb_name/$action_name/g;
		} else {
			$screenshot_name =~ s/(\$name|\$nb_name)/unknown/g;
		}
	} else {
		$screenshot_name =~ s/(\$name|\$nb_name)/unknown/g;
	}

	print "Parsed \$name: $screenshot_name\n"
		if $sc->debug;

	# --- ShareX-style macro templates ---
	my @lt = localtime(time);
	my ($sec, $min, $hour, $mday, $mon, $year) = @lt;
	$year += 1900;
	$mon  += 1;

	# Date/time macros: %y %mo %d %h %mi %s
	$screenshot_name =~ s/%y/sprintf('%04d', $year)/ge;
	$screenshot_name =~ s/%mo/sprintf('%02d', $mon)/ge;
	$screenshot_name =~ s/%d/sprintf('%02d', $mday)/ge;
	$screenshot_name =~ s/%h/sprintf('%02d', $hour)/ge;
	$screenshot_name =~ s/%mi/sprintf('%02d', $min)/ge;
	$screenshot_name =~ s/%s/sprintf('%02d', $sec)/ge;

	# %pn = profile name
	$screenshot_name =~ s/%pn/$current_pname/g;

	# %wt = window title
	if ($x11_supported && $screenshooter) {
		my $wt = $screenshooter->get_action_name // 'unknown';
		utf8::decode $wt;
		$wt              =~ s/(\/|\#|\>|\<|\%|\*)/-/g;
		$screenshot_name =~ s/%wt/$wt/g;
	} else {
		$screenshot_name =~ s/%wt/unknown/g;
	}

	# %wx %wy %ww %wh = screenshot width/height
	$screenshot_name =~ s/%ww/$swidth/g;
	$screenshot_name =~ s/%wh/$sheight/g;

	print "Parsed ShareX macros: $screenshot_name\n"
		if $sc->debug;

	return $screenshot_name;
}

sub fct_unlink_tempfiles ($self, $key) {
	my $session_screens = $self->cli->{_session_screens};

	if ($session_screens->{$key}) {
		foreach my $tmpf (@{$session_screens->{$key}->{'undo'} // []}) {
			Shutter::App::Core::FileSystemAPI->new->remove($tmpf);
		}

		foreach my $tmpf (@{$session_screens->{$key}->{'redo'} // []}) {
			Shutter::App::Core::FileSystemAPI->new->remove($tmpf);
		}
	}

	return TRUE;
}

sub fct_validate_filename ($self, $myfilename, $myfilename_hint) {
	my $d             = $self->cli->sc->gettext_object;
	my @invalid_codes = (47, 92);
	$myfilename->signal_connect(
		'key-press-event' => sub {
			shift;
			my $event = shift;

			my $input = Gtk3::Gdk::keyval_to_unicode($event->keyval);

			if (grep($input == $_, @invalid_codes)) {
				my $char = chr($input);
				$char = 'amp();' if $char eq '&';
				$myfilename_hint->set_markup("<span size='small'>" . sprintf($d->get("Reserved character %s is not allowed to be in a filename."), "'" . $char . "'") . "</span>");
				return TRUE;
			} else {

				#clear possible message when valid char is entered
				$myfilename_hint->set_markup("<span size='small'></span>");
				return FALSE;
			}
		});
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Util_File - Utility file handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
