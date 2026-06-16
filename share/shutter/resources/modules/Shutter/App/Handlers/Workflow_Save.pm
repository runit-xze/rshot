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

package Shutter::App::Handlers::Workflow_Save;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_load_settings {
		my ($data, $profilename) = @_;

		#settings file
		my $settingsfile = "$ENV{ HOME }/.shutter/settings.xml";
		$settingsfile = "$ENV{ HOME }/.shutter/profiles/$profilename.xml"
			if (defined $profilename);

		my $settings_xml;
		if ($shf->file_exists($settingsfile)) {
			eval {
				$settings_xml = XMLin(IO::File->new($settingsfile));

				if ($data eq 'profile_load') {
					$combobox_type->set_active($settings_xml->{'general'}->{'filetype'});

					#main
					$scale->set_value($settings_xml->{'general'}->{'quality'});
					utf8::decode $settings_xml->{'general'}->{'filename'};
					$filename->set_text($settings_xml->{'general'}->{'filename'});

					utf8::decode $settings_xml->{'general'}->{'folder'};
					$saveDir_button->set_filename($settings_xml->{'general'}->{'folder'});

					$save_auto_active->set_active($settings_xml->{'general'}->{'save_auto'});
					$save_ask_active->set_active($settings_xml->{'general'}->{'save_ask'});
					$save_no_active->set_active($settings_xml->{'general'}->{'save_no'});

					$image_autocopy_active->set_active($settings_xml->{'general'}->{'image_autocopy'});
					$fname_autocopy_active->set_active($settings_xml->{'general'}->{'fname_autocopy'});
					$no_autocopy_active->set_active($settings_xml->{'general'}->{'no_autocopy'});

					$cursor_active->set_active($settings_xml->{'general'}->{'cursor'});
					$delay->set_value($settings_xml->{'general'}->{'delay'});

					$drawing_tool_light_icons_active->set_active($settings_xml->{'general'}->{'drawing_tool_light_icons'});
					$drawing_tool_dark_icons_active->set_active($settings_xml->{'general'}->{'drawing_tool_dark_icons'});
					$drawing_tool_auto_icons_active->set_active($settings_xml->{'general'}->{'drawing_tool_auto_icons'});

					#FIXME
					#this is a dirty hack to force the setting to be enabled in session tab
					#at the moment i simply dont know why the filechooser "caches" the old value
					# => weird...
					$settings_xml->{'general'}->{'folder_force'} = TRUE;

					#wrksp -> submenu
					$current_monitor_active->set_active($settings_xml->{'general'}->{'current_monitor_active'});

					#determining timeout
					my $web_menu = $st->{_web}->get_menu;
					if (defined $web_menu) {
						my @timeouts = $web_menu->get_children;
						my $timeout  = undef;
						foreach my $to (@timeouts) {
							$timeout = $to->get_name;
							$timeout =~ /([0-9]+)/;
							$timeout = $1;
							if ($settings_xml->{'general'}->{'web_timeout'} == $timeout) {
								$to->set_active(TRUE);
							}
						}
					}

					#action settings
					my $model = $progname->get_model;
					utf8::decode $settings_xml->{'general'}->{'prog'};
					$model->foreach(\&fct_iter_programs, $settings_xml->{'general'}->{'prog'});
					$progname_active->set_active($settings_xml->{'general'}->{'prog_active'});

					$im_colors_active->set_active($settings_xml->{'general'}->{'im_colors_active'});
					$combobox_im_colors->set_active($settings_xml->{'general'}->{'im_colors'});

					$thumbnail->set_value($settings_xml->{'general'}->{'thumbnail'});
					$thumbnail_active->set_active($settings_xml->{'general'}->{'thumbnail_active'});

					$bordereffect->set_value($settings_xml->{'general'}->{'bordereffect'});
					$bordereffect_active->set_active($settings_xml->{'general'}->{'bordereffect_active'});
					if (defined $settings_xml->{'general'}->{'bordereffect_col'}) {
						$bordereffect_cbtn->set_rgba(Gtk3::Gdk::RGBA::parse($settings_xml->{'general'}->{'bordereffect_col'}));
					}

					#advanced settings
					$zoom_active->set_active($settings_xml->{'general'}->{'zoom_active'});
					$as_help_active->set_active($settings_xml->{'general'}->{'as_help_active'});
					$as_confirmation_necessary->set_active($settings_xml->{'general'}->{'as_confirmation_necessary'});

					$asel_size3->set_value($settings_xml->{'general'}->{'asel_x'});
					$asel_size4->set_value($settings_xml->{'general'}->{'asel_y'});
					$asel_size1->set_value($settings_xml->{'general'}->{'asel_w'});
					$asel_size2->set_value($settings_xml->{'general'}->{'asel_h'});

					$border_active->set_active($settings_xml->{'general'}->{'border'});

					$winresize_active->set_active($settings_xml->{'general'}->{'winresize_active'});
					$winresize_w->set_value($settings_xml->{'general'}->{'winresize_w'});
					$winresize_h->set_value($settings_xml->{'general'}->{'winresize_h'});

					$autoshape_active->set_active($settings_xml->{'general'}->{'autoshape_active'});
					$visible_windows_active->set_active($settings_xml->{'general'}->{'visible_windows'});
					$menu_waround_active->set_active($settings_xml->{'general'}->{'menu_waround'});
					$menu_delay->set_value($settings_xml->{'general'}->{'menu_delay'});
					$combobox_web_width->set_active($settings_xml->{'general'}->{'web_width'});

					#imageview
					$trans_check->set_active($settings_xml->{'general'}->{'trans_check'});
					$trans_custom->set_active($settings_xml->{'general'}->{'trans_custom'});
					if (defined $settings_xml->{'general'}->{'trans_custom_col'}) {
						$trans_custom_btn->set_rgba(Gtk3::Gdk::RGBA::parse($settings_xml->{'general'}->{'trans_custom_col'}));
					}
					$trans_backg->set_active($settings_xml->{'general'}->{'trans_backg'});

					$session_asc->set_active($settings_xml->{'general'}->{'session_asc'});
					$session_asc_combo->set_active($settings_xml->{'general'}->{'session_asc_combo'});
					$session_desc->set_active($settings_xml->{'general'}->{'session_desc'});
					$session_desc_combo->set_active($settings_xml->{'general'}->{'session_desc_combo'});

					#behavior
					$fs_active->set_active($settings_xml->{'general'}->{'autofs'});
					$fs_min_active->set_active($settings_xml->{'general'}->{'autofs_min'});
					$fs_nonot_active->set_active($settings_xml->{'general'}->{'autofs_not'});
					$hide_active->set_active($settings_xml->{'general'}->{'autohide'});
					$hide_time->set_value($settings_xml->{'general'}->{'autohide_time'});
					$present_after_active->set_active($settings_xml->{'general'}->{'present_after'});
					$close_at_close_active->set_active($settings_xml->{'general'}->{'close_at_close'});
					$notify_after_active->set_active($settings_xml->{'general'}->{'notify_after'});
					$notify_timeout_active->set_active($settings_xml->{'general'}->{'notify_timeout'});
					$notify_ptimeout_active->set_active($settings_xml->{'general'}->{'notify_ptimeout'});
					$combobox_ns->set_active($settings_xml->{'general'}->{'notify_agent'});
					$ask_on_delete_active->set_active($settings_xml->{'general'}->{'ask_on_delete'});
					$delete_on_close_active->set_active($settings_xml->{'general'}->{'delete_on_close'});
					$ask_on_fs_delete_active->set_active($settings_xml->{'general'}->{'ask_on_fs_delete'});

					#ftp_upload
					utf8::decode $settings_xml->{'general'}->{'ftp_uri'};
					utf8::decode $settings_xml->{'general'}->{'ftp_mode'};
					utf8::decode $settings_xml->{'general'}->{'ftp_username'};
					utf8::decode $settings_xml->{'general'}->{'ftp_password'};
					utf8::decode $settings_xml->{'general'}->{'ftp_wurl'};

					$ftp_remote_entry->set_text($settings_xml->{'general'}->{'ftp_uri'});
					$ftp_mode_combo->set_active($settings_xml->{'general'}->{'ftp_mode'});
					$ftp_username_entry->set_text($settings_xml->{'general'}->{'ftp_username'});
					$ftp_password_entry->set_text($settings_xml->{'general'}->{'ftp_password'});
					$ftp_wurl_entry->set_text($settings_xml->{'general'}->{'ftp_wurl'});

					#we store the version info, so we know if there was a new version installed
					#when starting new version we clear the cache on first startup
					if (defined $settings_xml->{'general'}->{'app_version'}) {
						if ($sc->get_version . $sc->get_rev ne $settings_xml->{'general'}->{'app_version'}) {
							$sc->set_clear_cache(TRUE);
						}
					} else {
						$sc->set_clear_cache(TRUE);
					}

					#load account data from profile unless param is set to ignore it
					fct_load_accounts($profilename);
					if (defined $accounts_tree) {
						fct_load_accounts_tree();
						$accounts_tree->set_model($accounts_model);
						fct_set_model_accounts($accounts_tree);
					}

					#endif profile load
				} else {

					#recently used
					$sc->set_ruu_tab($settings_xml->{'recent'}->{'ruu_tab'});
					$sc->set_ruu_hosting($settings_xml->{'recent'}->{'ruu_hosting'});
					$sc->set_ruu_places($settings_xml->{'recent'}->{'ruu_places'});

					#we store the version info, so we know if there was a new version installed
					#when starting new version we clear the cache on first startup
					if (defined $settings_xml->{'general'}->{'app_version'}) {
						if ($sc->get_version . $sc->get_rev ne $settings_xml->{'general'}->{'app_version'}) {
							$sc->set_clear_cache(TRUE);
						}
					} else {
						$sc->set_clear_cache(TRUE);
					}

					#get plugins from cache unless param is set to ignore it
					if (!$sc->get_clear_cache) {

						foreach my $plugin_key (sort keys %{$settings_xml->{'plugins'}}) {
							utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'binary'};

							#check if plugin still exists in filesystem
							if ($shf->file_exists($settings_xml->{'plugins'}->{$plugin_key}->{'binary'})) {

								#restore newlines <![CDATA[<br>]]> tags => \n
								$settings_xml->{'plugins'}->{$plugin_key}->{'tooltip'} =~ s/\<\!\[CDATA\[\<br\>\]\]\>/\n/g;

								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'name_plugin'};
								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'category'};
								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'tooltip'};
								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'lang'};
								$plugins{$plugin_key}->{'binary'}   = $settings_xml->{'plugins'}->{$plugin_key}->{'binary'};
								$plugins{$plugin_key}->{'name'}     = $settings_xml->{'plugins'}->{$plugin_key}->{'name_plugin'};
								$plugins{$plugin_key}->{'category'} = $settings_xml->{'plugins'}->{$plugin_key}->{'category'};
								$plugins{$plugin_key}->{'tooltip'}  = $settings_xml->{'plugins'}->{$plugin_key}->{'tooltip'};
								$plugins{$plugin_key}->{'lang'}     = $settings_xml->{'plugins'}->{$plugin_key}->{'lang'} || "shell";
								$plugins{$plugin_key}->{'recent'}   = $settings_xml->{'plugins'}->{$plugin_key}->{'recent'};
							}

						}    #endforeach

					}    #endif plugins from cache

				}

			};
			if ($@) {
				$sd->dlg_error_message($@, $d->get("Settings could not be restored!"));
				unlink $settingsfile;
			} else {
				fct_show_status_message(1, $d->get("Settings loaded successfully"));
			}

			#endif file exists
		} else {
			warn "ERROR: settingsfile " . $settingsfile . " does not exist\n\n";
		}

		return $settings_xml;
	}

	sub fct_save_settings {
		my ($profilename) = @_;

		#settings file
		my $settingsfile = "$ENV{ HOME }/.shutter/settings.xml";
		if (defined $profilename) {
			$settingsfile = "$ENV{ HOME }/.shutter/profiles/$profilename.xml"
				if ($profilename ne "");
		}

		#session file
		my $sessionfile = "$ENV{ HOME }/.shutter/session.xml";

		#accounts file
		my $accountsfile = "$ENV{ HOME }/.shutter/accounts.xml";
		if (defined $profilename) {
			$accountsfile = "$ENV{ HOME }/.shutter/profiles/$profilename\_accounts.xml"
				if ($profilename ne "");
		}

		#we store the version info, so we know if there was a new version installed
		#when starting new version we clear the cache on first startup
		$settings{'general'}->{'app_version'} = $sc->get_version . $sc->get_rev;

		$settings{'general'}->{'last_profile'}      = $combobox_settings_profiles->get_active;
		$settings{'general'}->{'last_profile_name'} = $combobox_settings_profiles->get_active_text || "";

		#menu
		$settings{'gui'}->{'btoolbar_active'} = $sm->{_menuitem_btoolbar}->get_active();

		#recently used
		$settings{'recent'}->{'ruu_tab'}     = $sc->get_ruu_tab;
		$settings{'recent'}->{'ruu_hosting'} = $sc->get_ruu_hosting;
		$settings{'recent'}->{'ruu_places'}  = $sc->get_ruu_places;

		#main
		$settings{'general'}->{'filetype'} = $combobox_type->get_active;
		$settings{'general'}->{'quality'}  = $scale->get_value();
		if ($filename->get_text() =~ "\%NN" || $filename->get_text() =~ "\%T") {
			$settings{'general'}->{'filename'} = $filename->get_text();
		} else {
			$sd->dlg_error_message($@, $d->get("Settings could not be saved! Please make sure that the filename contains a wildcard like \%NN or \%T!"));
			evt_show_settings();
			return 1;
		}
		$settings{'general'}->{'folder'}   = Glib::filename_to_unicode($saveDir_button->get_filename());

		#~ print "Pfad ".$saveDir_button->get_filename()."\n";
		#~ print "Pfad ".$saveDir_button->get_uri()."\n";
		$settings{'general'}->{'save_auto'}                     = $save_auto_active->get_active();
		$settings{'general'}->{'save_ask'}                      = $save_ask_active->get_active();
		$settings{'general'}->{'save_no'}                       = $save_no_active->get_active();
		$settings{'general'}->{'image_autocopy'}                = $image_autocopy_active->get_active();
		$settings{'general'}->{'fname_autocopy'}                = $fname_autocopy_active->get_active();
		$settings{'general'}->{'no_autocopy'}                   = $no_autocopy_active->get_active();
		$settings{'general'}->{'cursor'}                        = $cursor_active->get_active();
		$settings{'general'}->{'delay'}                         = $delay->get_value();
		$settings{'general'}->{'drawing_tool_light_icons'}      = $drawing_tool_light_icons_active->get_active();
		$settings{'general'}->{'drawing_tool_dark_icons'}       = $drawing_tool_dark_icons_active->get_active();
		$settings{'general'}->{'drawing_tool_auto_icons'}       = $drawing_tool_auto_icons_active->get_active();
		#wrksp -> submenu
		if ($x11_supported) {
			$settings{'general'}->{'current_monitor_active'} = $current_monitor_active->get_active;
		}
		#determining timeout
		if ($gnome_web_photo) {
			my $web_menu = $st->{_web}->get_menu;
			my @timeouts = $web_menu->get_children;
			my $timeout  = undef;
			foreach my $to (@timeouts) {
				if ($to->get_active) {
					$timeout = $to->get_name;
					$timeout =~ /([0-9]+)/;
					$timeout = $1;
				}
			}
			$settings{'general'}->{'web_timeout'} = $timeout;
		}

		my $model         = $progname->get_model();
		my $progname_iter = $progname->get_active_iter();

		if (defined $progname_iter) {
			my $progname_value = $model->get_value($progname_iter, 1);
			$settings{'general'}->{'prog'} = $progname_value;
		}

		#actions
		$settings{'general'}->{'prog_active'}         = $progname_active->get_active();
		$settings{'general'}->{'im_colors'}           = $combobox_im_colors->get_active();
		$settings{'general'}->{'im_colors_active'}    = $im_colors_active->get_active();
		$settings{'general'}->{'thumbnail'}           = $thumbnail->get_value();
		$settings{'general'}->{'thumbnail_active'}    = $thumbnail_active->get_active();
		$settings{'general'}->{'bordereffect'}        = $bordereffect->get_value();
		$settings{'general'}->{'bordereffect_active'} = $bordereffect_active->get_active();
		my $bcolor = $bordereffect_cbtn->get_color;
		$settings{'general'}->{'bordereffect_col'} = sprintf("#%02x%02x%02x", $bcolor->red / 257, $bcolor->green / 257, $bcolor->blue / 257);

		#advanced
		$settings{'general'}->{'zoom_active'}      = $zoom_active->get_active();
		$settings{'general'}->{'as_help_active'}   = $as_help_active->get_active();
		$settings{'general'}->{'as_confirmation_necessary'}   = $as_confirmation_necessary->get_active();
		$settings{'general'}->{'asel_x'}           = $asel_size3->get_value();
		$settings{'general'}->{'asel_y'}           = $asel_size4->get_value();
		$settings{'general'}->{'asel_w'}           = $asel_size1->get_value();
		$settings{'general'}->{'asel_h'}           = $asel_size2->get_value();
		$settings{'general'}->{'border'}           = $border_active->get_active();
		$settings{'general'}->{'winresize_active'} = $winresize_active->get_active();
		$settings{'general'}->{'winresize_w'}      = $winresize_w->get_value();
		$settings{'general'}->{'winresize_h'}      = $winresize_h->get_value();
		$settings{'general'}->{'autoshape_active'} = $autoshape_active->get_active();
		$settings{'general'}->{'visible_windows'}  = $visible_windows_active->get_active();
		$settings{'general'}->{'menu_delay'}       = $menu_delay->get_value();
		$settings{'general'}->{'menu_waround'}     = $menu_waround_active->get_active();
		$settings{'general'}->{'web_width'}        = $combobox_web_width->get_active();

		#imageview
		$settings{'general'}->{'trans_check'}  = $trans_check->get_active();
		$settings{'general'}->{'trans_custom'} = $trans_custom->get_active();
		my $tcolor = $trans_custom_btn->get_color;
		$settings{'general'}->{'trans_custom_col'} = sprintf("#%02x%02x%02x", $tcolor->red / 257, $tcolor->green / 257, $tcolor->blue / 257);
		$settings{'general'}->{'trans_backg'}      = $trans_backg->get_active();

		$settings{'general'}->{'session_asc'}        = $session_asc->get_active();
		$settings{'general'}->{'session_asc_combo'}  = $session_asc_combo->get_active();
		$settings{'general'}->{'session_desc'}       = $session_desc->get_active();
		$settings{'general'}->{'session_desc_combo'} = $session_desc_combo->get_active();

		#behavior
		$settings{'general'}->{'autofs'}           = $fs_active->get_active();
		$settings{'general'}->{'autofs_min'}       = $fs_min_active->get_active();
		$settings{'general'}->{'autofs_not'}       = $fs_nonot_active->get_active();
		$settings{'general'}->{'autohide'}         = $hide_active->get_active();
		$settings{'general'}->{'autohide_time'}    = $hide_time->get_value();
		$settings{'general'}->{'present_after'}    = $present_after_active->get_active();
		$settings{'general'}->{'close_at_close'}   = $close_at_close_active->get_active();
		$settings{'general'}->{'notify_after'}     = $notify_after_active->get_active();
		$settings{'general'}->{'notify_timeout'}   = $notify_timeout_active->get_active();
		$settings{'general'}->{'notify_ptimeout'}  = $notify_ptimeout_active->get_active();
		$settings{'general'}->{'notify_agent'}     = $combobox_ns->get_active();
		$settings{'general'}->{'ask_on_delete'}    = $ask_on_delete_active->get_active();
		$settings{'general'}->{'delete_on_close'}  = $delete_on_close_active->get_active();
		$settings{'general'}->{'ask_on_fs_delete'} = $ask_on_fs_delete_active->get_active();

		#ftp upload
		$settings{'general'}->{'ftp_uri'}      = $ftp_remote_entry->get_text();
		$settings{'general'}->{'ftp_mode'}     = $ftp_mode_combo->get_active();
		$settings{'general'}->{'ftp_username'} = $ftp_username_entry->get_text();
		$settings{'general'}->{'ftp_password'} = $ftp_password_entry->get_text();
		$settings{'general'}->{'ftp_wurl'}     = $ftp_wurl_entry->get_text();

		#pipeline steps (ShareX workflow)
		if ($vbox_workflow && $vbox_workflow->{_get_pipeline_steps}) {
			my @steps = $vbox_workflow->{_get_pipeline_steps}->();
			$settings{'general'}->{'pipeline_steps'} = JSON::MaybeXS->new->encode(\@steps);
		}

		#plugins
		foreach my $plugin_key (sort keys %plugins) {
			$settings{'plugins'}->{$plugin_key}->{'name'}        = $plugin_key;
			$settings{'plugins'}->{$plugin_key}->{'binary'}      = $plugins{$plugin_key}->{'binary'};
			$settings{'plugins'}->{$plugin_key}->{'name_plugin'} = $plugins{$plugin_key}->{'name'};
			$settings{'plugins'}->{$plugin_key}->{'category'}    = $plugins{$plugin_key}->{'category'};

			#keep newlines => switch them to <![CDATA[<br>]]> tags
			#the load routine does it the other way round
			my $temp_tooltip = $plugins{$plugin_key}->{'tooltip'};
			$temp_tooltip =~ s/\n/\<\!\[CDATA\[\<br\>\]\]\>/g;
			$settings{'plugins'}->{$plugin_key}->{'tooltip'} = $temp_tooltip;
			$settings{'plugins'}->{$plugin_key}->{'lang'}    = $plugins{$plugin_key}->{'lang'};
			$settings{'plugins'}->{$plugin_key}->{'recent'}  = $plugins{$plugin_key}->{'recent'}
				if defined $plugins{$plugin_key}->{'recent'};
		}

		#settings
		eval {
			my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
			XMLout(\%settings, OutputFile => $tmpfilename);

			#and finally move the file
			mv($tmpfilename, $settingsfile);
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Settings could not be saved!"));
		} else {
			fct_show_status_message(1, $d->get("Settings saved successfully!"));
		}

		#we need to clean the hashkeys, so they become parseable
		my %clean_files;
		my $counter = 0;
		foreach my $key ($shf->nsort(keys %session_screens)) {
			next unless exists $session_screens{$key}->{'long'};

			#8 leading zeros to counter
			$counter = sprintf("%08d", $counter);
			if ($shf->file_exists($session_screens{$key}->{'long'})) {
				$clean_files{"file" . $counter}{'filename'} = $session_screens{$key}->{'long'};
				$counter++;
			}
		}

		#session
		eval {
			my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
			XMLout(\%clean_files, OutputFile => $tmpfilename);

			#and finally move the file
			mv($tmpfilename, $sessionfile);
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Session could not be saved!"));
		}

		#accounts
		#~ print Dumper %accounts;
		my %clean_accounts;
		foreach my $ac (keys %accounts) {
			$clean_accounts{$ac}->{'path'}                       = $accounts{$ac}->{'path'};
			$clean_accounts{$ac}->{'host'}                       = $accounts{$ac}->{'host'};
			$clean_accounts{$ac}->{'password'}                   = $accounts{$ac}->{'password'};
			$clean_accounts{$ac}->{'username'}                   = $accounts{$ac}->{'username'};
			$clean_accounts{$ac}->{'module'}                     = $accounts{$ac}->{'module'};
			$clean_accounts{$ac}->{'folder'}                     = $accounts{$ac}->{'folder'};
			$clean_accounts{$ac}->{'description'}                = $accounts{$ac}->{'description'};
			$clean_accounts{$ac}->{'register_text'}              = $accounts{$ac}->{'register_text'};
			$clean_accounts{$ac}->{'register_color'}             = $accounts{$ac}->{'register_color'};
			$clean_accounts{$ac}->{'supports_anonymous_upload'}  = $accounts{$ac}->{'supports_anonymous_upload'};
			$clean_accounts{$ac}->{'supports_authorized_upload'} = $accounts{$ac}->{'supports_authorized_upload'};
			$clean_accounts{$ac}->{'supports_oauth_upload'}      = $accounts{$ac}->{'supports_oauth_upload'};
		}

		eval {
			my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
			XMLout(\%clean_accounts, OutputFile => $tmpfilename);

			#and finally move the file
			mv($tmpfilename, $accountsfile);
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Account-settings could not be saved!"));
		}

		return TRUE;
	}


1;
