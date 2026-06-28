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
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package Shutter::App::Events::File;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub dlg_open ($self, $widget, $type) {
	my @files = grep { $self->cli->shf->file_exists($_) } @ARGV;
	$self->cli->handlers->get('Init_Handlers')->fct_open_files(@files);
	$self->cli->handlers->get('Core')->fct_control_main_window('show');
	return;
}

sub evt_save_as ($self, $widget, $mode) {
	fct_save_as($mode);
	return;
}

sub evt_delete_window ($self, $widget, $reason) {
	if ($reason eq 'quit') {
		$self->cli->sc->set_exit_after_capture(TRUE);
	}
	$self->cli->app->quit;
	return;
}

sub evt_show_settings ($self) {
	$self->cli->handlers->get('Menu')->evt_show_settings();
	return;
}

sub fct_email ($self, $mode) {
	$self->cli->handlers->get('Upload_Main')->fct_email($mode);
	return;
}

sub fct_print ($self, $mode) {
	$self->cli->handlers->get('Upload_Main')->fct_print($mode);
	return;
}

sub evt_page_setup ($self) {
	$self->cli->handlers->get('Menu')->evt_page_setup();
	return;
}

sub fct_clipboard_import ($self) {
	$self->cli->handlers->get('Edit_Nav')->fct_clipboard_import();
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Events::File – File-related event handlers

=head1 SYNOPSIS

    my $file_events = Shutter::App::Events::File->new(cli => $cli);
    $file_events->dlg_open($widget, $type);

=head1 DESCRIPTION

Contains all file operation handlers: open, save, print, email, clipboard
import, and application shutdown.

=cut
