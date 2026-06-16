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

package Shutter::App::Handlers::Menu_Ret_Workspace;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_ret_window_menu {

		my $menu_windows = Gtk3::Menu->new;
		return $menu_windows unless $wnck_screen;

		my $active_workspace = $wnck_screen->get_active_workspace;
		my $icontheme        = $sc->get_theme;

		#add item for active window
		my $active_window_item_image;
		if ($icontheme->has_icon('preferences-system-windows')) {
			$active_window_item_image = Gtk3::Image->new_from_icon_name('preferences-system-windows', 'menu');
		} else {
			$active_window_item_image = Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/sel_window_active.svg", $shf->icon_size('menu')));
		}

		my $active_window_item = Gtk3::ImageMenuItem->new_with_label($d->get("Active Window"));
		$active_window_item->set_image($active_window_item_image);
		$active_window_item->set('always_show_image' => TRUE);

		$active_window_item->set_tooltip_text($d->get("Capture the last active window"));

		$active_window_item->signal_connect(
			'activate' => \&evt_take_screenshot,
			'awindow'
		);

		$menu_windows->append($active_window_item);
		$menu_windows->append(Gtk3::SeparatorMenuItem->new);

		# Check if we can retrieve the list of stacked windows first, otherwise we will run into a crash, see issue 659
		
		unless ($wnck_screen->get_windows_stacked) {
			print "ERROR: The window list could not be retrieved and has been disabled, see https://github.com/shutter-project/shutter/issues/659";
			return $menu_windows;
		}

		#add all windows to menu to capture it directly

		foreach my $win (@{$wnck_screen->get_windows_stacked}) {
			if ($active_workspace && $win->is_on_workspace($active_workspace)) {
				my $win_name = $win->get_name;
				Encode::_utf8_on($win_name);
				my $window_item = Gtk3::ImageMenuItem->new_with_label($win_name);
				foreach my $child ($window_item->get_children) {
					if ($child =~ /Gtk3::AccelLabel/) {
						$child->set_width_chars(50);
						$child->set_ellipsize('middle');
						last;
					}
				}
				$window_item->set_image(Gtk3::Image->new_from_pixbuf($win->get_mini_icon));
				$window_item->set('always_show_image' => TRUE);
				$window_item->signal_connect(
					'activate' => \&evt_take_screenshot,
					"shutter_window_direct" . $win->get_xid
				);
				$menu_windows->append($window_item);
			}
		}

		$menu_windows->show_all;
		return $menu_windows;
	}

	sub fct_ret_workspace_menu {
		my $init = shift;

		my $menu_wrksp = Gtk3::Menu->new;
		unless ($x11_supported) {
			return $menu_wrksp;
		}

		my $wnck_screen = Wnck::Screen::get_default();
		unless ($wnck_screen) {
			$current_monitor_active = Gtk3::CheckMenuItem->new_with_label($d->get("Limit to current monitor"));
			return $menu_wrksp;
		}
		$wnck_screen->force_update();

		#we determine the wm name but on older
		#version of libwnck (or the bindings)
		#the needed method is not available
		#in this case we use gdk to do it
		#
		#this leads to a known problem when switching
		#the wm => wm_name will still remain the old one
		#but it doesn't work on gtk3
		my $wm_name;
		if ($wnck_screen->can('get_window_manager_name')) {
			$wm_name = $wnck_screen->get_window_manager_name;
		}

		my $active_workspace = $wnck_screen->get_active_workspace;

		#we need to handle different window managers here because there are some different models related
		#to workspaces and viewports
		#	compiz uses "multiple workspaces" - "multiple viewports" model for example
		#	default gnome wm metacity simply uses multiple workspaces
		#we will try to handle them by name
		my @workspaces = ();
		for (my $wcount = 0 ; $wcount < $wnck_screen->get_workspace_count ; $wcount++) {
			push(@workspaces, $wnck_screen->get_workspace($wcount));
		}

		foreach my $space (@workspaces) {
			next unless defined $space;

			#compiz
			print "Current window manager: ", $wm_name, "\n" if $sc->get_debug;
			if ($wm_name =~ /compiz/i) {

				#calculate viewports with size of workspace
				my $vpx = $space->get_viewport_x;
				my $vpy = $space->get_viewport_y;

				my $n_viewports_column = int($space->get_width / $wnck_screen->get_width);
				my $n_viewports_rows   = int($space->get_height / $wnck_screen->get_height);

				#rows
				for (my $j = 0 ; $j < $n_viewports_rows ; $j++) {

					#columns
					for (my $i = 0 ; $i < $n_viewports_column ; $i++) {
						my @vp      = ($i * $wnck_screen->get_width, $j * $wnck_screen->get_height);
						my $vp_name = "$wm_name x: $i y: $j";

						print "shutter_wrksp_direct_compiz" . $vp[0] . "x" . $vp[1] . "\n"
							if $sc->get_debug;

						my $vp_item = Gtk3::MenuItem->new_with_label(ucfirst $vp_name);
						$vp_item->signal_connect(
							'activate' => \&evt_take_screenshot,
							"shutter_wrksp_direct_compiz" . $vp[0] . "x" . $vp[1]);
						$menu_wrksp->append($vp_item);

						#do not offer current viewport
						if ($vp[0] == $vpx && $vp[1] == $vpy) {
							$vp_item->set_sensitive(FALSE);
						}
					}    #columns
				}    #rows

				#all other wm manager like metacity etc.
				#we could add more of them here if needed
			} else {

				my $wrkspace_item = Gtk3::MenuItem->new_with_label($space->get_name);
				$wrkspace_item->signal_connect(
					'activate' => \&evt_take_screenshot,
					"shutter_wrksp_direct" . $space->get_number
				);
				$menu_wrksp->append($wrkspace_item);

				if (   $active_workspace
					&& $active_workspace->get_number == $space->get_number)
				{
					$wrkspace_item->set_sensitive(FALSE);
				}

			}
		}

		#entry for capturing all workspaces
		$menu_wrksp->append(Gtk3::SeparatorMenuItem->new);

		my $allwspaces_item = Gtk3::MenuItem->new_with_label($d->get("Capture All Workspaces"));
		$allwspaces_item->signal_connect(
			'activate' => \&evt_take_screenshot,
			"shutter_wrksp_direct" . 'all'
		);
		$menu_wrksp->append($allwspaces_item);

		#monitor flag
		my $n_mons = Gtk3::Gdk::Screen::get_default->get_n_monitors;

		#use only current monitor
		$menu_wrksp->append(Gtk3::SeparatorMenuItem->new);
		if ($init) {
			$current_monitor_active = Gtk3::CheckMenuItem->new_with_label($d->get("Limit to current monitor"));
			if (defined $settings_xml->{'general'}->{'current_monitor_active'}) {
				$current_monitor_active->set_active($settings_xml->{'general'}->{'current_monitor_active'});
			} else {
				$current_monitor_active->set_active(FALSE);
			}
			$menu_wrksp->append($current_monitor_active);
		} else {
			$current_monitor_active->reparent($menu_wrksp);
		}

		$current_monitor_active->set_tooltip_text(
			sprintf(
				$d->nget(
					"This option is only useful when you are running a multi-monitor system (%d monitor detected).\nEnable it to capture only the current monitor.",
					"This option is only useful when you are running a multi-monitor system (%d monitors detected).\nEnable it to capture only the current monitor.",
					$n_mons
				),
				$n_mons
			));
		if ($n_mons > 1) {
			$current_monitor_active->set_sensitive(TRUE);
		} else {
			$current_monitor_active->set_active(FALSE);
			$current_monitor_active->set_sensitive(FALSE);
		}

		$menu_wrksp->show_all();
		return $menu_wrksp;
	}


1;
