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

package Shutter::App::Handlers::Util;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_check_installed_plugins {

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
		# maybe the plugin
		# does not provide a custom icon
		my $fb_pixbuf_path = "$shutter_root/share/shutter/resources/icons/executable.svg";
		my $fb_pixbuf      = $lp->load($fb_pixbuf_path, $shf->icon_size('menu'));

		foreach my $plugin_path (@plugin_paths) {
			my @plugins = bsd_glob($plugin_path);
			foreach my $pkey (@plugins) {
				if (-d $pkey) {
					my $dir_name = $pkey;

					#parse filename
					my ($name, $folder, $type) = fileparse($dir_name, qr/\.[^.]*/);

					#file exists
					if ($shf->file_exists("$dir_name/$name")) {

						#file is executable
						if ($shf->file_executable("$dir_name/$name")) {

							#new plugin information?
							unless ($plugins{$pkey}->{'binary'}
								&& $plugins{$pkey}->{'name'}
								&& $plugins{$pkey}->{'category'}
								&& $plugins{$pkey}->{'tooltip'}
								&& $plugins{$pkey}->{'lang'})
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
								$plugins{$pkey}->{'binary'} = "$dir_name/$name";

								#name
								$plugins{$pkey}->{'name'} = fct_plugin_get_info($plugins{$pkey}->{'binary'}, 'name');

								#category
								$plugins{$pkey}->{'category'} = fct_plugin_get_info($plugins{$pkey}->{'binary'}, 'sort');

								#tooltip
								$plugins{$pkey}->{'tooltip'} = fct_plugin_get_info($plugins{$pkey}->{'binary'}, 'tip');

								#language (shell, perl etc.)
								#=> directory name
								my $folder_name = dirname($dir_name);
								$folder_name =~ /.*\/(.*)/;
								$plugins{$pkey}->{'lang'} = $1;

								#refresh the progressbar
								$plugin_progress->pulse;
								$current_plugin->set_text($plugins{$pkey}->{'binary'});

								#refresh gui
								fct_update_gui();

							}

							$plugins{$pkey}->{'lang'} = "shell"
								if $plugins{$pkey}->{'lang'} eq "";

							chomp($plugins{$pkey}->{'name'});
							chomp($plugins{$pkey}->{'category'});
							chomp($plugins{$pkey}->{'tooltip'});
							chomp($plugins{$pkey}->{'lang'});

							#pixbuf
							$plugins{$pkey}->{'pixbuf'} = $plugins{$pkey}->{'binary'} . ".png"
								if ($shf->file_exists($plugins{$pkey}->{'binary'} . ".png"));
							$plugins{$pkey}->{'pixbuf'} = $plugins{$pkey}->{'binary'} . ".svg"
								if ($shf->file_exists($plugins{$pkey}->{'binary'} . ".svg"));

							if ($shf->file_exists($plugins{$pkey}->{'pixbuf'})) {
								$plugins{$pkey}->{'pixbuf_object'} = $lp->load($plugins{$pkey}->{'pixbuf'}, $shf->icon_size('menu'));
							} else {
								$plugins{$pkey}->{'pixbuf'}        = $fb_pixbuf_path;
								$plugins{$pkey}->{'pixbuf_object'} = $fb_pixbuf;
							}
							if ($sc->get_debug) {
								print "$plugins{$pkey}->{'name'} - $plugins{$pkey}->{'binary'}\n";
							}

						} else {
							my $changed = chmod(0755, "$dir_name/$name");
							unless ($changed) {
								print "\nERROR: plugin exists but is not executable - $dir_name/$name\n";
								delete $plugins{$pkey};
							}
						}    #endif plugin is executable

					} else {
						delete $plugins{$pkey};
					}    #endif plugin exists

				}
			}
		}

		#destroys the plugin dialog
		$plugin_dialog->response('ok');

		return TRUE;
	}

	sub fct_check_installed_programs {

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
			$model = fct_get_program_model();
			$progname->set_model($model);

			#...and try to set last	value
			if ($progname_value) {
				$model->foreach(\&fct_iter_programs, $progname_value);
			} else {
				$progname->set_active(0);
			}

			#nothing has been set
			if ($progname->get_active == -1) {
				$progname->set_active(0);
			}
		}

		return TRUE;
	}

	sub fct_check_installed_upload_plugins {

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

		#plugins in user-home not supported yet FIXME
		my @upload_plugin_paths = ("$shutter_root/share/shutter/resources/system/upload_plugins/upload/*");

		foreach my $upload_plugin_path (@upload_plugin_paths) {
			my @upload_plugins = bsd_glob($upload_plugin_path);
			foreach my $ukey (@upload_plugins) {

				#Checking if file exists
				if ($shf->file_exists("$ukey")) {

					#file is executable
					if ($shf->file_executable("$ukey")) {

						#parse filename
						my ($name, $folder, $type) = fileparse($ukey, qr/\.[^.]*/);

						#~ print $name, $folder, $type, "\n";

						if (   !exists $accounts{$name}
							|| !exists $accounts{$name}->{module}
							|| $accounts{$name}->{supports_anonymous_upload} ne fct_upload_plugin_get_info($ukey, 'supports_anonymous_upload')
							|| $accounts{$name}->{supports_authorized_upload} ne fct_upload_plugin_get_info($ukey, 'supports_authorized_upload')
							|| $accounts{$name}->{supports_oauth_upload} ne fct_upload_plugin_get_info($ukey, 'supports_oauth_upload'))
						{

							#show dialog and progress bar
							if (   !$upload_plugin_dialog->get_window
								&& !$upload_plugin_dialog->{destroyed})
							{
								$upload_plugin_progress->show;
								$upload_plugin_dialog->show_all;
							}

							print "\nINFO: new upload-plugin information detected - $folder$name\n";

							if (fct_upload_plugin_get_info($ukey, 'module')) {

								# Path
								$accounts{$name}->{path} = $ukey;

								# Module Name
								$accounts{$name}->{module} = fct_upload_plugin_get_info($ukey, 'module');

								# URL
								$accounts{$name}->{host} = fct_upload_plugin_get_info($ukey, 'url');

								# Folder
								$accounts{$name}->{folder} = $folder;

								# Description
								$accounts{$name}->{description} = fct_plugin_get_info($ukey, 'description');

								# Username
								$accounts{$name}->{username} = ""
									unless defined $accounts{$name}->{username};

								# Password
								$accounts{$name}->{password} = ""
									unless defined $accounts{$name}->{password};

								# Register Color
								$accounts{$name}->{register_color} = "blue";

								# Register Text
								$accounts{$name}->{register_text} = fct_upload_plugin_get_info($ukey, 'registration');

								# Upload Features
								$accounts{$name}->{supports_anonymous_upload}  = fct_upload_plugin_get_info($ukey, 'supports_anonymous_upload');
								$accounts{$name}->{supports_authorized_upload} = fct_upload_plugin_get_info($ukey, 'supports_authorized_upload');
								$accounts{$name}->{supports_oauth_upload}      = fct_upload_plugin_get_info($ukey, 'supports_oauth_upload');

								#refresh the progressbar
								$upload_plugin_progress->pulse;
								$current_plugin->set_text($accounts{$name}->{path});

							} else {
								print "\nERROR: upload-plugin exists but does not work properly - $folder$name\n";
								delete $accounts{$name};
							}

							#refresh gui
							fct_update_gui();

						}

					} else {
						my $changed = chmod(0755, "$ukey");
						unless ($changed) {

							#parse filename
							my ($name, $folder, $type) = fileparse($ukey, qr/\.[^.]*/);
							print "\nERROR: upload-plugin exists but is not executable - $ukey\n";
							delete $accounts{$name};
						}    #endif plugin is executable
					}
				}
			}

		}

		# Parse custom ShareX (.sxcu) uploaders
		my @sxcu_paths = (
			"$shutter_root/share/shutter/resources/system/uploaders/*.sxcu",
			$ENV{'HOME'} . "/.shutter/uploaders/*.sxcu"
		);
		use JSON::MaybeXS;
		my $json = JSON::MaybeXS->new;
		foreach my $sxcu_path (@sxcu_paths) {
			my @sxcus = bsd_glob($sxcu_path);
			foreach my $ukey (@sxcus) {
				if (-f $ukey) {
					my ($name, $folder, $type) = fileparse($ukey, qr/\.[^.]*/);
					
					eval {
						open(my $fh, '<', $ukey) or die "Cannot open $ukey";
						my $json_text = do { local $/; <$fh> };
						close($fh);
						my $sxcu = $json->decode($json_text);
						
						my $display_name = $sxcu->{Name} || $name;
						
						$accounts{$display_name}->{path} = $ukey;
						$accounts{$display_name}->{module} = "ShareX";
						$accounts{$display_name}->{host} = $sxcu->{RequestURL};
						$accounts{$display_name}->{folder} = "$shutter_root/share/shutter/resources/modules/Shutter/Upload";
						$accounts{$display_name}->{description} = "ShareX Custom Uploader ($display_name)";
						$accounts{$display_name}->{register_color} = "blue";
						$accounts{$display_name}->{register_text} = "";
						$accounts{$display_name}->{supports_anonymous_upload} = TRUE;
						$accounts{$display_name}->{supports_authorized_upload} = FALSE;
						$accounts{$display_name}->{supports_oauth_upload} = FALSE;
						$accounts{$display_name}->{username} = "" unless defined $accounts{$display_name}->{username};
						$accounts{$display_name}->{password} = "" unless defined $accounts{$display_name}->{password};
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

	sub fct_get_next_filename {
		my ($filename_value, $folder, $filetype_value) = @_;

		#remove possible dots
		$filetype_value =~ s/\.//;

		$filename_value =~ s/\\//g;

		#random number - should be earlier than %N reading, as $R is actually a part of date
		if ($filename_value =~ /\$R{1,}/) {

			#how many Rs are used? (important for formatting)
			my $pos_proc  = index($filename_value, "\$R", 0);
			my $r_counter = 0;
			my $last_pos  = $pos_proc;
			$pos_proc++;

			while ($pos_proc <= length($filename_value)) {
				$last_pos = index($filename_value, "R", $pos_proc);
				if ($last_pos != -1 && ($last_pos - $pos_proc <= 1)) {
					$r_counter++;
					$pos_proc++;
				} else {
					last;
				}
			}

			#prepare filename
			print "---$r_counter Rs used in wild-card\n" if $sc->get_debug;
			my $marks = "";
			my $i     = 0;

			# Md5 will contain a salt (shutter) and a seconds since 1970
			my $md5_data = "shutter" . time;
			my $md5_hash = md5_hex($md5_data);

			# TODO: set random offset? I guess, current implementation is sufficient
			$marks = substr($md5_hash, 0, $r_counter);

			#switch $Rs to a part of the hash
			$filename_value =~ s/\$R{1,}/$marks/g;
		}

		#auto increment  (%NNN is the pattern for the increment placeholder)
		if ($filename_value =~ /\%(N{1,})/) {
			#how many Ns are used? (important for formatting)
			my $n_counter = length($1);

			#prepare filename
			print "$n_counter Ns used in wild-card\n" if $sc->get_debug;

			my $filename_template = quotemeta $filename_value;

			#replace %NNN by a \d+ regex to search for digits
			#also take into account conflicted filenames Ex.: "_014(002)"
			$filename_template =~ s/\\\%N+/(\\d+)(?:\\(\\d+\\))?/g;
			#store regex to string
			my $search_pattern = qr/$filename_template\.$filetype_value/;

			print "Searching for files with pattern: $search_pattern\n"
				if $sc->get_debug;

			#get_all files from directory
			#we handle the listing with GnomeVFS to read remote dirs as well
			my $dir        = Glib::IO::File::new_for_path($folder);
			my $next_count = 0;
			eval {
				my $enumerator = $dir->enumerate_children('standard::*', []);
				while (my $fileinfo = $enumerator->next_file) {
					my $fname = $shf->utf8_decode($fileinfo->get_name);

					#not a regular file? -> skip
					next unless $fileinfo->get_file_type eq 'regular';

					#does the current file match the pattern?
					# print "Comparing $fname\n" if $sc->get_debug;
					if ($fname =~ $search_pattern) {
						my $curr_value = $1;
						if ($curr_value && $curr_value > $next_count) {
							$next_count = $curr_value;
							print "$next_count is currently greatest value...\n"
								if $sc->get_debug;
						}
					}
				}
				$enumerator->close;
			};
			if ($@) {
				my $response = $sd->dlg_error_message(
					sprintf($d->get("Error while opening directory %s."), "'" . $folder . "'"),
					$d->get("There was an error determining the filename."),
					undef, undef, undef, undef, undef, undef, $@
				);
				return FALSE;
			}

			$next_count = 0 unless $next_count =~ /^(\d+\.?\d*|\.\d+)$/;

			$next_count = sprintf("%0" . $n_counter . "d", $next_count + 1);

			#switch placeholder to $next_count
			$filename_value =~ s/\%N+/$next_count/g;

		}

		#create new uri
		my $new_giofile = Glib::IO::File::new_for_path("$folder/$filename_value.$filetype_value");
		if ($new_giofile->query_exists) {
			my $count             = 1;
			my $existing_filename = $filename_value;
			while ($new_giofile->query_exists) {
				$filename_value = $existing_filename . "(" . sprintf("%03d", $count++) . ")";
				$new_giofile    = Glib::IO::File::new_for_path($folder);
				$new_giofile    = $new_giofile->append_string("$filename_value.$filetype_value");
				print "Checking new uri: " . $new_giofile->to_string . "\n"
					if $sc->get_debug;
			}
		}

		return $new_giofile;
	}

	sub fct_imagemagick_perform {
		my ($function, $file, $data) = @_;

		my $pixbuf = undef;
		my $result = undef;
		$file = $shf->switch_home_in_file($file);

		if ($function eq "reduce_colors") {
			$result = `convert '$file' -colors $data '$file'`;
			$pixbuf = $lp->load($file);
		}

		return $pixbuf;
	}

	sub fct_iter_programs {
		my ($model, $path, $iter, $search_for) = @_;
		my $progname_value = $model->get_value($iter, 1);
		return FALSE if $search_for ne $progname_value;
		$progname->set_active_iter($iter);
		return TRUE;
	}

	sub fct_parse_filename_wildcards {
		my ($filename_value, $screenshooter, $screenshot) = @_;

		my $screenshot_name = $filename_value;

		print "Parsing wildcards for $screenshot_name\n"
			if $sc->get_debug;
		
		#parse width and height
		my $swidth  = $screenshot->get_width;
		my $sheight = $screenshot->get_height;

		$screenshot_name =~ s/\$w/$swidth/g;
		$screenshot_name =~ s/\$h/$sheight/g;

		print "Parsed \$width and \$height: $screenshot_name\n"
			if $sc->get_debug;

		#parse profile name
		my $current_pname = $combobox_settings_profiles->get_active_text;
		$screenshot_name =~ s/\$profile/$current_pname/g;

		print "Parsed \$profile: $screenshot_name\n"
			if $sc->get_debug;

		#set name
		#e.g. window or workspace name
		if ($x11_supported) {
			if (my $action_name = $screenshooter->get_action_name) {
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
			if $sc->get_debug;

		# --- ShareX-style macro templates (TODO-ShareX.md #3) ---
		# Evaluate at capture time for consistency across all profiles.
		my @lt = localtime(time);
		my ($sec, $min, $hour, $mday, $mon, $year) = @lt;
		$year += 1900; $mon += 1;

		# Date/time macros: %y %mo %d %h %mi %s
		$screenshot_name =~ s/%y/sprintf('%04d', $year)/ge;
		$screenshot_name =~ s/%mo/sprintf('%02d', $mon)/ge;
		$screenshot_name =~ s/%d/sprintf('%02d', $mday)/ge;
		$screenshot_name =~ s/%h/sprintf('%02d', $hour)/ge;
		$screenshot_name =~ s/%mi/sprintf('%02d', $min)/ge;
		$screenshot_name =~ s/%s/sprintf('%02d', $sec)/ge;

		# %pn = profile name (ShareX calls it "project name")
		$screenshot_name =~ s/%pn/$current_pname/g;

		# %wt = window title (same as $name but ShareX-style)
		if ($x11_supported && $screenshooter) {
			my $wt = $screenshooter->get_action_name // 'unknown';
			utf8::decode $wt;
			$wt =~ s/(\/|\#|\>|\<|\%|\*)/-/g;
			$screenshot_name =~ s/%wt/$wt/g;
		} else {
			$screenshot_name =~ s/%wt/unknown/g;
		}

		# %wx %wy %ww %wh = screenshot width/height at capture (aliases)
		$screenshot_name =~ s/%ww/$swidth/g;
		$screenshot_name =~ s/%wh/$sheight/g;

		print "Parsed ShareX macros: $screenshot_name\n"
			if $sc->get_debug;

		return $screenshot_name;
	}

	sub fct_unlink_tempfiles {
		my $key = shift;

		foreach my $tmpf (@{$session_screens{$key}->{'undo'}}) {
			unlink $tmpf;
		}

		foreach my $tmpf (@{$session_screens{$key}->{'redo'}}) {
			unlink $tmpf;
		}

		return TRUE;
	}

	sub fct_validate_filename{
		my $myfilename	= shift;
		my $myfilename_hint	= shift;
		my @invalid_codes = (47, 92);
		$myfilename->signal_connect(
			'key-press-event' => sub {
				shift;
				my $event = shift;

				my $input = Gtk3::Gdk::keyval_to_unicode($event->keyval);

				#invalid input
				#~ print $input."\n";
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
	}


1;
