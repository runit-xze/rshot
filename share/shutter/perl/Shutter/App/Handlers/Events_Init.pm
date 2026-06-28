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

package Shutter::App::Handlers::Events_Init;

use utf8;
use v5.40;
use Shutter::App::Core::FileSystemAPI;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_add_file_monitor ($self, $key) {
	my $cli             = $self->cli;
	my $session_screens = $cli->{_session_screens};
	my $sc              = $cli->sc;
	my $sd              = $cli->sc->{_sd};
	my $d               = $cli->sc->gettext_object;

	return FALSE unless exists $session_screens->{$key};

	$session_screens->{$key}->{'changed'} = FALSE;
	$session_screens->{$key}->{'deleted'} = FALSE;
	$session_screens->{$key}->{'created'} = FALSE;

	eval {
		if (defined $session_screens->{$key}->{'giofile'}) {
			my $monitor = $session_screens->{$key}->{'giofile'}->monitor_file([]);
			$session_screens->{$key}->{'monitor'} = $monitor;
			$monitor->signal_connect(
				'changed',
				sub {
					my ($handle, $file1, $file2, $event, $k) = @_;

					print $event. " - $k\n" if $sc->debug;

					if ($event eq 'deleted') {

						my $v = $session_screens->{$k};
						if ($v && $v->{'giofile'} && Shutter::App::Core::FileSystemAPI->new->path_exists($v->{'giofile'}->get_path)) {
							print "got event 'deleted', but file $k still exists, ignoring\n" if $sc->debug;
							return;
						}

						$handle->cancel;

						if (exists $session_screens->{$k}) {
							$session_screens->{$k}->{'deleted'} = TRUE;
							$session_screens->{$k}->{'changed'} = TRUE;
							fct_update_tab($k) if defined &fct_update_tab;
						}

					} elsif ($event eq 'changed') {

						print $session_screens->{$k}->{'giofile'}->get_path . " - " . $event . "\n"
							if $sc->debug;
						$session_screens->{$k}->{'changed'} = TRUE;
						fct_update_tab($k) if defined &fct_update_tab;
					}
				},
				$key
			);
		}
	};
	if ($@) {

		#show error dialog when installing the file
		#monitor failed
		$sd->dlg_error_message("$@", $d->get("Error while adding the file monitor."));
		return FALSE;
	}

	return TRUE;
}

sub fct_iter_programs ($self, $model, $path, $iter, $search_for) {
	my $progname = $self->cli->{_progname};

	my $progname_value = $model->get_value($iter, 1);
	return FALSE                      if $search_for ne $progname_value;
	$progname->set_active_iter($iter) if $progname;
	return TRUE;
}

sub fct_navigation_toolbar ($self, $widget) {
	my $nav_toolbar = $self->cli->{_nav_toolbar};

	return unless $nav_toolbar;

	if ($widget->get_active) {
		$nav_toolbar->show;
		foreach my $child ($nav_toolbar->get_children) {
			$child->show_all;
		}
	} else {
		$nav_toolbar->hide;
		foreach my $child ($nav_toolbar->get_children) {
			$child->hide_all;
		}
	}
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Events_Init - Initialization event handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
