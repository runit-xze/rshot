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

package Shutter::App::Handlers::Edit_Delete;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_delete ($self, $key = undef, $action = undef) {
	my $cli                  = $self->cli;
	my $h                    = $cli->handlers;
	my $d                    = $cli->sc->get_gettext;
	my $sd                   = $cli->sc->{_sd};
	my $ask_on_delete_active = $cli->{_ask_on_delete_active};
	my $session_screens      = $cli->{_session_screens};
	my $session_start_screen = $cli->{_session_start_screen};
	my $notebook             = $cli->{_notebook};
	my $window               = $cli->window;
	my $is_hidden            = $cli->{_is_hidden};

	#close current tab (unless $key is provided or close_all)
	unless (defined $action && $action eq 'menu_close_all') {
		$key = $h->get('Menu_Ret_Get')->fct_get_current_file() unless $key;
	}

	#single file
	if ($key) {

		if ($ask_on_delete_active && $ask_on_delete_active->get_active) {
			my $response = $sd->dlg_question_message(
				"",           sprintf($d->get("Are you sure you want to move %s to the trash?"), "'" . $session_screens->{$key}->{'long'} . "'"),
				'gtk-cancel', $d->get("Move to _Trash"),
			);
			return FALSE unless $response == 20;
		}

		if ($session_screens->{$key}->{'giofile'}->query_exists) {
			$self->fct_trash($key);
			eval {
				#remove from recentmanager
				Gtk3::RecentManager::get_default->remove_item($session_screens->{$key}->{'giofile'}->get_path);
			};
		}

		$notebook->remove_page($notebook->page_num($session_screens->{$key}->{'tab_child'}));    #delete tab
		$h->get('UI_Status')->fct_show_status_message(1, $session_screens->{$key}->{'long'} . " " . $d->get("deleted"))
			if defined($session_screens->{$key}->{'long'});

		if (defined $session_screens->{$key}->{'iter'}
			&& $session_start_screen->{'first_page'}->{'model'}->iter_is_valid($session_screens->{$key}->{'iter'}))
		{
			$session_start_screen->{'first_page'}->{'model'}->remove($session_screens->{$key}->{'iter'});
		}

		#unlink undo and redo files
		$h->get('Util_File')->fct_unlink_tempfiles($key);

		delete $session_screens->{$key};

		$window->show_all unless $is_hidden;

		#session tab
	} else {

		if ($ask_on_delete_active && $ask_on_delete_active->get_active) {

			#any files selected?
			my $selected = FALSE;
			if ($session_start_screen->{'first_page'}->{'view'}) {
				$session_start_screen->{'first_page'}->{'view'}->selected_foreach(
					sub {
						my ($view, $path) = @_;
						my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
						if (defined $iter) {
							$selected = TRUE;
						}
					});
			}

			if ($selected) {
				my $response = $sd->dlg_question_message("", $d->get("Are you sure you want to move the selected files to the trash?"), 'gtk-cancel', $d->get("Move to _Trash"),);
				return FALSE unless $response == 20;
			} else {
				$h->get('UI_Status')->fct_show_status_message(1, $d->get("No screenshots selected"));
				return FALSE;
			}
		}

		my @to_delete;
		if ($session_start_screen->{'first_page'}->{'view'}) {
			$session_start_screen->{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
						$notebook->remove_page($notebook->page_num($session_screens->{$key}->{'tab_child'}));

						if ($session_screens->{$key}->{'giofile'}->query_exists) {
							$self->fct_trash($key);
							eval {
								#remove from recentmanager
								Gtk3::RecentManager::get_default->remove_item($session_screens->{$key}->{'giofile'}->get_path);
							};
						}

						#copy to array
						#we delete the files from hash and model
						#when exiting the sub
						push @to_delete, $key;

					}
				},
				undef
			);
		}

		if (scalar @to_delete == 0) {
			$h->get('UI_Status')->fct_show_status_message(1, $d->get("No screenshots selected"));
			return FALSE;
		}

		#delete from hash and model
		foreach my $key (@to_delete) {
			if (defined $session_screens->{$key}->{'iter'}
				&& $session_start_screen->{'first_page'}->{'model'}->iter_is_valid($session_screens->{$key}->{'iter'}))
			{
				$session_start_screen->{'first_page'}->{'model'}->remove($session_screens->{$key}->{'iter'});
			}

			#unlink undo and redo files
			$h->get('Util_File')->fct_unlink_tempfiles($key);

			delete $session_screens->{$key};
		}

		$h->get('UI_Status')->fct_show_status_message(1, $d->get("Selected screenshots deleted"));

		$window->show_all unless $is_hidden;

	}

	$h->get('UI_Status')->fct_update_info_and_tray();

	return TRUE;
}

sub fct_remove ($self, $key = undef, $action = undef) {
	my $cli                    = $self->cli;
	my $h                      = $cli->handlers;
	my $d                      = $cli->sc->get_gettext;
	my $delete_on_close_active = $cli->{_delete_on_close_active};
	my $session_screens        = $cli->{_session_screens};
	my $session_start_screen   = $cli->{_session_start_screen};
	my $notebook               = $cli->{_notebook};
	my $window                 = $cli->window;
	my $is_hidden              = $cli->{_is_hidden};

	#close current tab (unless $key is provided or close_all)
	unless (defined $action && $action eq 'menu_close_all') {
		$key = $h->get('Menu_Ret_Get')->fct_get_current_file() unless $key;
	}

	#single file
	if ($key) {

		#delete instead of remove
		if ($delete_on_close_active && $delete_on_close_active->get_active) {
			$self->fct_delete($key);
			return FALSE;
		}

		if (exists $session_screens->{$key}->{'handle'}) {

			#cancel handle
			$session_screens->{$key}->{'handle'}->cancel;
		}

		$notebook->remove_page($notebook->page_num($session_screens->{$key}->{'tab_child'}));    #delete tab
		$h->get('UI_Status')->fct_show_status_message(1, $session_screens->{$key}->{'long'} . " " . $d->get("removed from session"))
			if defined($session_screens->{$key}->{'long'});

		if (defined $session_screens->{$key}->{'iter'}
			&& $session_start_screen->{'first_page'}->{'model'}->iter_is_valid($session_screens->{$key}->{'iter'}))
		{
			$session_start_screen->{'first_page'}->{'model'}->remove($session_screens->{$key}->{'iter'});
		}

		#unlink undo and redo files
		$h->get('Util_File')->fct_unlink_tempfiles($key);

		delete $session_screens->{$key};

		$window->show_all unless $is_hidden;

	} else {

		#delete instead of remove
		if ($delete_on_close_active && $delete_on_close_active->get_active) {
			$self->fct_delete(undef, 'menu_close_all');
			return FALSE;
		}

		my @to_remove;
		if ($session_start_screen->{'first_page'}->{'view'}) {
			$session_start_screen->{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						my $key = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
						$notebook->remove_page($notebook->page_num($session_screens->{$key}->{'tab_child'}));

						if (exists $session_screens->{$key}->{'handle'}) {

							#cancel handle
							$session_screens->{$key}->{'handle'}->cancel;
						}

						#copy to array
						#we remove the files from hash and model
						#when exiting the sub
						push @to_remove, $key;

					}
				},
				undef
			);
		}

		if (scalar @to_remove == 0) {
			$h->get('UI_Status')->fct_show_status_message(1, $d->get("No screenshots selected"));
			return FALSE;
		}

		#delete from hash and model
		foreach my $key (@to_remove) {
			if (defined $session_screens->{$key}->{'iter'}
				&& $session_start_screen->{'first_page'}->{'model'}->iter_is_valid($session_screens->{$key}->{'iter'}))
			{
				$session_start_screen->{'first_page'}->{'model'}->remove($session_screens->{$key}->{'iter'});
			}

			#unlink undo and redo files
			$h->get('Util_File')->fct_unlink_tempfiles($key);

			delete $session_screens->{$key};
		}

		$h->get('UI_Status')->fct_show_status_message(1, $d->get("Selected screenshots removed"));

		$window->show_all unless $is_hidden;

	}

	$h->get('UI_Status')->fct_update_info_and_tray();

	return TRUE;
}

sub fct_select_all ($self) {
	my $session_start_screen = $self->cli->{_session_start_screen};

	if ($session_start_screen && $session_start_screen->{'first_page'} && $session_start_screen->{'first_page'}->{'view'}) {
		$session_start_screen->{'first_page'}->{'view'}->select_all;
	}

	return TRUE;
}

sub fct_trash ($self, $key) {
	my $session_screens = $self->cli->{_session_screens};

	#cancel handle
	if (exists $session_screens->{$key}->{'handle'}) {
		$session_screens->{$key}->{'handle'}->cancel;
	}

	if ($session_screens->{$key}->{'giofile'}) {
		$session_screens->{$key}->{'giofile'}->trash;
	}
	return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Edit_Delete – Edit action handlers (Delete, Remove, Select All, Trash)

=head1 DESCRIPTION

This module handles edit actions related to deleting or removing screenshots in Shutter.
It has been migrated to use the CLI object for state access instead of package globals.

=head1 METHODS

=head2 fct_delete

Moves a screenshot (or selected screenshots) to the trash.

=head2 fct_remove

Removes a screenshot (or selected screenshots) from the session.

=head2 fct_select_all

Selects all screenshots in the session.

=head2 fct_trash

Moves a single file to the trash.

=cut
