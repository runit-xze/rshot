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

package Shutter::App::Handlers::Events_Tray;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub evt_accounts ($self, $tree, $path, $column) {
	my $cli = $self->cli;
	my $d   = $cli->sc->gettext_object;
	my $shf = $cli->shf;

	#open browser if register url is clicked
	if ($column->get_title eq $d->get("Register")) {
		my $model         = $tree->get_model();
		my $account_iter  = $model->get_iter($path);
		my $account_value = $model->get_value($account_iter, 5);
		$shf->xdg_open(undef, $account_value, undef) if $account_value;
	}
	return TRUE;
}

sub evt_activate_systray_statusicon ($self, $widget, $data, $tray) {
	my $cli = $self->cli;
	my $sc  = $cli->sc;

	if ($sc->debug) {
		print "\n$data was emitted by widget $widget\n";
	}

	unless ($cli->{_is_hidden}) {
		$self->cli->handlers->get('Core')->fct_control_main_window('hide');
	} else {
		$self->cli->handlers->get('Core')->fct_control_main_window('show');
	}
	return TRUE;
}

sub evt_iconview_button_press ($self, $ev_box, $ev, $view) {
	my $cli = $self->cli;
	my $sm  = $cli->{_sm};

	my $path = $view->get_path_at_pos($ev->x, $ev->y);

	if ($path) {

		#select item
		$view->select_path($path);

		$sm->{_menu_large_actions}->popup(
			undef,    # parent menu shell
			undef,    # parent menu item
			undef,    # menu pos func
			undef,    # data
			$ev->button,
			$ev->time
		) if $sm->{_menu_large_actions};

	}

	return TRUE;
}

sub evt_iconview_item_activated ($self, $view, $path, $data) {
	my $cli             = $self->cli;
	my $notebook        = $cli->{_notebook};
	my $session_screens = $cli->{_session_screens};

	my $model = $view->get_model;

	my $iter = $model->get_iter($path);
	my $key  = $model->get_value($iter, 2);

	$notebook->set_current_page($notebook->page_num($session_screens->{$key}->{'tab_child'})) if ($notebook && $session_screens->{$key});

	return TRUE;
}

sub evt_iconview_sel_changed ($self, $view, $data = undef) {

	#we don't handle selection changes
	#if we are not in the session tab
	if ($self->cli->handlers->get('Menu_Ret_Get')->fct_get_current_file()) {
		return FALSE;
	}

	my $items = $view->get_selected_items;
	my @sel_items;
	@sel_items = @$items if $items;

	#enable/disable menu entry when we are in the session tab and selection changes
	if (scalar @sel_items == 1) {
		my $key                  = undef;
		my $session_start_screen = $self->cli->{_session_start_screen};
		$session_start_screen->{'first_page'}->{'view'}->selected_foreach(
			sub {
				my ($view, $path) = @_;
				my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
				if (defined $iter) {
					$key = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
				}
			},
			undef
		);
		$self->cli->handlers->get('Screenshot_Actions')->fct_update_actions(scalar @sel_items, $key);
	} else {
		$self->cli->handlers->get('Screenshot_Actions')->fct_update_actions(scalar @sel_items);
	}

	return TRUE;
}

sub evt_show_systray ($self, $widget, $data) {
	my $cli       = $self->cli;
	my $sc        = $cli->sc;
	my $window    = $cli->window;
	my $tray_menu = $cli->{_tray_menu};

	if ($sc->debug) {
		print "\n$data was emitted by widget $widget\n";
	}

	#left button (mouse)
	if ($data->button == 1) {
		if ($window->visible) {
			$self->cli->handlers->get('Core')->fct_control_main_window('hide');
		} else {
			$self->cli->handlers->get('Core')->fct_control_main_window('show');
		}
	}

	#right button (mouse)
	elsif ($data->button == 3) {
		$tray_menu->popup(
			undef,    # parent menu shell
			undef,    # parent menu item
			undef,    # menu pos func
			undef,    # data
			$data->button,
			$data->time
		) if $tray_menu;
	}
	return TRUE;
}

sub evt_show_systray_statusicon ($self, $widget, $button, $time, $tray) {
	my $sc        = $self->cli->sc;
	my $tray_menu = $self->cli->{_tray_menu};

	if ($sc->debug) {
		print "\n$button, $time was emitted by widget $widget\n";
	}

	$tray_menu->popup(
		undef,    # parent menu shell
		undef,    # parent menu item
		sub {
			return Gtk3::StatusIcon::position_menu($tray_menu, 0, 0, $tray);
		},        # menu pos func
		undef,    # data
		$time ? $button : 0,
		$time
	) if $tray_menu;

	return TRUE;
}

sub evt_tab_button_press ($self, $ev_box, $ev, $key) {
	my $sm = $self->cli->{_sm};

	#right click
	if ($key && $ev->button == 3 && $ev->type eq 'button-press') {
		$sm->{_menu_large_actions}->popup(
			undef,    # parent menu shell
			undef,    # parent menu item
			undef,    # menu pos func
			undef,    # data
			$ev->button,
			$ev->time
		) if $sm->{_menu_large_actions};
	}

	return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Events_Tray - Tray event handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
