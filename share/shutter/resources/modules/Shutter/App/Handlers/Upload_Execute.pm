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

package Shutter::App::Handlers::Upload_Execute;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_execute_plugin {
		my $arrayref = $_[1];
		my ($plugin_value, $plugin_name, $plugin_lang, $key, $plugin_dialog, $plugin_progress) = @$arrayref;

		unless ($shf->file_exists($session_screens{$key}->{'long'})) {
			return FALSE;
		}

		#if it is a native perl plugin, use a plug to integrate it properly
		if ($plugin_lang eq "perl") {

			#hide plugin dialog
			$plugin_dialog->hide if defined $plugin_dialog;

			#dialog to show the plugin
			my $sdialog = Gtk3::Dialog->new($plugin_name, $window, [qw/modal destroy-with-parent/]);
			$sdialog->set_resizable(FALSE);

			# Ensure that the dialog box is destroyed when the user responds.
			$sdialog->signal_connect(response => sub { $_[0]->destroy });

			#initiate the socket to draw the contents of the plugin to our dialog
			my $socket = Gtk3::Socket->new;
			$sdialog->get_child->add($socket);
			$socket->signal_connect(
				'plug-removed' => sub {
					$sdialog->destroy();
					return TRUE;
				});

			printf("\n", $socket->get_id);

			my $pid = fork;
			if ($pid < 0) {
				$sd->dlg_error_message(sprintf($d->get("Could not apply plugin %s"), "'" . $plugin_name . "'"), $d->get("Failed"));
			} elsif ($pid == 0) {

				#see Bug #661424
				#my $qfilename = quotemeta $session_screens{$key}->{'long'};
				exec($^X, $plugin_value, $socket->get_id, $session_screens{$key}->{'long'}, $session_screens{$key}->{'width'}, $session_screens{$key}->{'height'},
					$session_screens{$key}->{'filetype'});
			}

			$sdialog->show_all;
			$sdialog->run;

			waitpid($pid, 0);

			#check exit code
			if ($? == 0) {
				fct_show_status_message(1, sprintf($d->get("Successfully applied plugin %s"), "'" . $plugin_name . "'"));
			} elsif ($? / 256 == 1) {
				fct_show_status_message(1, sprintf($d->get("Could not apply plugin %s"), "'" . $plugin_name . "'"));
			}

			#...if not => simple execute the plugin via system (e.g. shell plugins)
		} else {

			print "$plugin_value $session_screens{$key}->{'long'} $session_screens{$key}->{'width'} $session_screens{$key}->{'height'} $session_screens{$key}->{'filetype'} submitted to plugin\n"
				if $sc->get_debug;

			#cancel handle, because file gets manipulated
			#multiple times
			if (exists $session_screens{$key}->{'handle'}) {
				$session_screens{$key}->{'handle'}->cancel;
			}

			#create a new process, so we are able to cancel the current operation
			my $pid = fork();
			if (!defined $pid) {
				die "Cannot fork: $!";
			} elsif ($pid == 0) {
				system($plugin_value, $session_screens{$key}->{'long'}, $session_screens{$key}->{'width'}, $session_screens{$key}->{'height'}, $session_screens{$key}->{'filetype'});
				POSIX::_exit($? >> 8);
			}

			#ignore delete-event during execute
			$plugin_dialog->signal_connect(
				'delete-event' => sub {
					return TRUE;
				});

			#we are also able to show a little progress bar to give some feedback
			#to the user. there is no real progress because we are just executing a shell script
			my $exit_status = 0;
			while (waitpid($pid, WNOHANG) == 0) {
				$plugin_progress->set_text($plugin_name . " - " . $session_screens{$key}->{'short'});
				$plugin_progress->pulse;
				fct_update_gui();
				usleep 100000;
			}
			$exit_status = $? >> 8;

			fct_update_gui();

			#finally show some status messages
			if ($exit_status == 0) {
				fct_show_status_message(1, sprintf($d->get("Successfully applied plugin %s"), "'" . $plugin_name . "'"));
			} else {
				$sd->dlg_error_message(sprintf($d->get("Error while executing plugin %s."), "'" . $plugin_name . "'"), $d->get("There was an error executing the plugin."),);
			}

			#update session tab manually
			fct_update_tab($key, undef, $session_screens{$key}->{'giofile'});

			#setup a new filemonitor, so we get noticed if the file changed
			fct_add_file_monitor($key);

		}

		return TRUE;
	}

	sub fct_show_status_message {
		my $index       = shift;
		my $status_text = shift;

		$status->pop($index);
		if ($session_start_screen{'first_page'}->{'statusbar_timer'}) {
			Glib::Source->remove($session_start_screen{'first_page'}->{'statusbar_timer'});
		}
		$status->push($index, $status_text);

		#...and remove it
		$session_start_screen{'first_page'}->{'statusbar_timer'} = Glib::Timeout->add(
			3000,
			sub {
				$status->pop($index);
				# avoid remove non-exist source
				$session_start_screen{'first_page'}->{'statusbar_timer'} = 0;

				#show file or session info again
				fct_update_info_and_tray();
				return FALSE;
			});

		return TRUE;
	}

	sub fct_update_info_and_tray {
		my $force_key = shift;

		my $key = undef;
		if ($force_key) {
			if ($force_key eq "session") {
				$key = undef;
			} else {
				$key = $force_key;
			}
		} else {
			$key = fct_get_current_file();
		}

		#STATUSBAR AND WINDOW TITLE
		#--------------------------------------
		#update statusbar when this image is current tab
		if (   $key
			&& defined $session_screens{$key}->{'long'}
			&& defined $session_screens{$key}->{'width'})
		{

			#change window title
			if (defined $session_screens{$key}->{'is_unsaved'}
				&& $session_screens{$key}->{'is_unsaved'})
			{
				$window->set_title("*" . $session_screens{$key}->{'name'} . " - " . SHUTTER_NAME);
			} else {
				$window->set_title($session_screens{$key}->{'long'} . " - " . SHUTTER_NAME);
			}

			$status->push(1,
				$session_screens{$key}->{'width'} . " x " . $session_screens{$key}->{'height'} . " " . $d->get("pixels") . "  " . $shf->utf8_decode($shf->format_bytes($session_screens{$key}->{'size'})));

			#session tab
		} else {

			#change window title
			$window->set_title($d->get("Session") . " - " . SHUTTER_NAME);

			$status->push(1,
				sprintf($d->nget("%s screenshot", "%s screenshots", scalar(keys(%session_screens))), scalar(keys(%session_screens))) . "  "
					. $shf->utf8_decode($shf->format_bytes(fct_get_total_size_of_session())));

		}

		#TRAY TOOLTIP
		#--------------------------------------
		if ($combobox_settings_profiles) {
			if ($tray && $tray->isa('Gtk3::StatusIcon')) {
				if ($combobox_settings_profiles->get_active_text) {
					$tray->set_tooltip_text($d->get("Current profile") . ": " . $combobox_settings_profiles->get_active_text);
				} else {
					$tray->set_tooltip_text(SHUTTER_NAME . " " . SHUTTER_VERSION);
				}
			}
		}

		return TRUE;
	}

	sub fct_update_tray_menu {
		my $screen = shift;
		if ($sc->get_debug) {
			print "\nfct_update_tray_menu was called by $screen\n";
		}

		#update window list
		foreach my $child ($tray_menu->get_children) {
			if ($child->get_name eq 'windowlist') {
				$child->set_submenu(fct_ret_window_menu());
				last;
			}
		}
	}


1;
