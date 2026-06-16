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

package Shutter::App::Handlers::Upload;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_email {

		my $key = fct_get_current_file();

		my @files_to_email;
		unless ($key) {
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push(@files_to_email, $session_screens{$key}->{'long'});
					}

				});
		} else {
			push(@files_to_email, $session_screens{$key}->{'long'});
		}

		my @mail_args = map { ('--attach' => $_) } @files_to_email;

		$shf->xdg_open_mail(undef, undef, @mail_args);

		return TRUE;
	}

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

	sub fct_open_with_program {
		my $app = shift;

		#no program set - exit
		return FALSE unless $app;

		my $key = fct_get_current_file();

		#single file
		if ($key) {

			return FALSE unless fct_screenshot_exists($key);

			#built-in-editor
			if ($app =~ /shutter/i) {
				fct_draw();
				fct_show_status_message(1, sprintf($d->get("%s opened with %s"), $session_screens{$key}->{'short'}, $d->get("Built-in Editor")));
			} else {

				#everything is fine -> open it
				if ($app->supports_uris) {
					$app->launch_uris([$session_screens{$key}->{'giofile'}->get_uri]);
				} else {
					$app->launch([$session_screens{$key}->{'giofile'}]);
				}
				fct_show_status_message(1, sprintf($d->get("%s opened with %s"), $session_screens{$key}->{'short'}, $app->{'name'}));
			}

			#session tab
		} else {

			my @open_files;
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						if ($app->supports_uris) {
							push @open_files, $session_screens{$key}->{'giofile'}->get_uri;
						} else {
							push @open_files, $session_screens{$key}->{'giofile'};
						}
					}
				},
				undef
			);
			if (@open_files > 0) {
				if ($app->supports_uris) {
					$app->launch_uris(\@open_files);
				} else {
					$app->launch(\@open_files);
				}
				fct_show_status_message(1, $d->get("Opened all files with") . " " . $app->{'name'});
			}
		}

		return TRUE;
	}

	sub fct_print {

		my $key = fct_get_current_file();

		my @pages;
		unless ($key) {
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push(@pages, $session_screens{$key}->{'long'});
					}

				});
		} else {
			push(@pages, $session_screens{$key}->{'long'});
		}

		my $op = Gtk3::PrintOperation->new;
		$op->set_job_name(SHUTTER_NAME . " - " . SHUTTER_VERSION . " - " . localtime);
		$op->set_n_pages(scalar @pages);
		$op->set_unit('none'); # aka pixel
		$op->set_show_progress(TRUE);
		$op->set_default_page_setup($pagesetup);

		#restore settings if prossible
		if ($shf->file_exists("$ENV{ HOME }/.shutter/printing.xml")) {
			eval {
				my $ssettings = Gtk3::PrintSettings->new_from_file("$ENV{ HOME }/.shutter/printing.xml");
				$op->set_print_settings($ssettings);
			};
		}

		$op->signal_connect(
			'status-changed' => sub {
				my $op = shift;
				fct_show_status_message(1, $op->get_status_string);
			});

		$op->signal_connect(
			'draw-page' => sub {
				my $op  = shift;
				my $pc  = shift;
				my $int = shift;

				#cairo context
				my $cr = $pc->get_cairo_context;

				#load pixbuf from file
				if (my $pixbuf = $lp->load($pages[$int])) {

					#scale if image doesn't fit on page
					my $scale_x = $pc->get_width / $pixbuf->get_width;
					my $scale_y = $pc->get_height / $pixbuf->get_height;
					if (min($scale_x, $scale_y) < 1) {
						$cr->scale(min($scale_x, $scale_y), min($scale_x, $scale_y));
					}

					Gtk3::Gdk::cairo_set_source_pixbuf($cr, $pixbuf, 0, 0);

				}

				$cr->paint;

			});

		$op->run('print-dialog', $window);

		#save settings
		my $settings = $op->get_print_settings;
		eval { $settings->to_file("$ENV{ HOME }/.shutter/printing.xml"); };

		return TRUE;
	}

	sub fct_send {

		my $key = fct_get_current_file();

		my @files_to_send;
		unless ($key) {
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						push(@files_to_send, $session_screens{$key}->{'long'});
					}

				});
		} else {
			push(@files_to_send, $session_screens{$key}->{'long'});
		}

		my $sendto_string = undef;
		foreach my $sendto_filename (@files_to_send) {
			$sendto_string .= "'$sendto_filename' ";
		}

		$shf->nautilus_sendto($sendto_string);

		return TRUE;
	}

	sub fct_upload {

		my $key = fct_get_current_file();

		my @upload_array;

		#single file
		if ($key) {

			return FALSE unless fct_screenshot_exists($key);
			push(@upload_array, $key);
			dlg_upload(@upload_array);

			#session tab
		} else {

			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
						return FALSE unless fct_screenshot_exists($key);
						push(@upload_array, $key);
					}

				},
				undef
			);
			dlg_upload(@upload_array);

		}

		#update actions
		#new public links might be available
		foreach my $key (@upload_array) {
			fct_update_actions(1, $key);
		}

		return TRUE;
	}

	sub fct_upload_plugin_get_info {
		my ($upload_plugin, $info) = @_;

		my $upload_plugin_info = `$upload_plugin $info`;
		utf8::decode $upload_plugin_info;

		return $upload_plugin_info;
	}


1;
