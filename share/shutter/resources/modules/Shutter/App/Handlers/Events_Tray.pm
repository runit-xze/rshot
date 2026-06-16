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

	sub evt_accounts {
		my ($tree, $path, $column) = @_;

		#open browser if register url is clicked
		if ($column->get_title eq $d->get("Register")) {
			my $model         = $tree->get_model();
			my $account_iter  = $model->get_iter($path);
			my $account_value = $model->get_value($account_iter, 5);
			$shf->xdg_open(undef, $account_value, undef);
		}
		return TRUE;
	}

	sub evt_activate_systray_statusicon {
		my ($widget, $data, $tray) = @_;
		if ($sc->get_debug) {
			print "\n$data was emitted by widget $widget\n";
		}

		unless ($is_hidden) {
			fct_control_main_window('hide');
		} else {
			fct_control_main_window('show');
		}
		return TRUE;
	}

	sub evt_iconview_button_press {
		my $ev_box = shift;
		my $ev     = shift;
		my $view   = shift;

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
			);

		}

		return TRUE;
	}

	sub evt_iconview_item_activated {
		my ($view, $path, $data) = @_;

		my $model = $view->get_model;

		my $iter = $model->get_iter($path);
		my $key  = $model->get_value($iter, 2);

		$notebook->set_current_page($notebook->page_num($session_screens{$key}->{'tab_child'}));

		return TRUE;
	}

	sub evt_iconview_sel_changed {
		my ($view, $data) = @_;

		#we don't handle selection changes
		#if we are not in the session tab
		if (fct_get_current_file()) {

			return FALSE;
		}

		my $items = $view->get_selected_items;
		my @sel_items;
		@sel_items = @$items if $items;

		#enable/disable menu entry when we are in the session tab and selection changes
		if (scalar @sel_items == 1) {
			my $key = undef;
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						$key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
					}
				},
				undef
			);
			fct_update_actions(scalar @sel_items, $key);
		} else {
			fct_update_actions(scalar @sel_items);
		}

		return TRUE;
	}

	sub evt_show_systray {
		my ($widget, $data) = @_;
		if ($sc->get_debug) {
			print "\n$data was emitted by widget $widget\n";
		}

		#left button (mouse)
		if ($_[1]->button == 1) {
			if ($window->visible) {
				fct_control_main_window('hide');
			} else {
				fct_control_main_window('show');
			}
		}

		#right button (mouse)
		elsif ($_[1]->button == 3) {
			$tray_menu->popup(
				undef,    # parent menu shell
				undef,    # parent menu item
				undef,    # menu pos func
				undef,    # data
				$data->button,
				$data->time
			);
		}
		return TRUE;
	}

	sub evt_show_systray_statusicon {
		my ($widget, $button, $time, $tray) = @_;
		if ($sc->get_debug) {
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
		);

		return TRUE;
	}

	sub evt_tab_button_press {
		my ($ev_box, $ev, $key) = @_;

		#right click
		if ($key && $ev->button == 3 && $ev->type eq 'button-press') {
			$sm->{_menu_large_actions}->popup(
				undef,    # parent menu shell
				undef,    # parent menu item
				undef,    # menu pos func
				undef,    # data
				$ev->button,
				$ev->time
			);
		}

		return TRUE;
	}


1;
