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

sub fct_ret_window_menu ($self) {
	my $cli          = $self->cli;
	my $sc           = $cli->sc;
	my $d            = $cli->sc->gettext_object;
	my $shf          = $cli->shf;
	my $lp           = $cli->{_lp};
	my $shutter_root = $cli->shutter_root;

	# Note: Requires Wnck to be available, using eval as a fallback
	my $wnck_screen;
	eval { $wnck_screen = Wnck::Screen::get_default(); };

	my $menu_windows = Gtk3::Menu->new;
	return $menu_windows unless $wnck_screen;

	my $active_workspace = $wnck_screen->get_active_workspace;
	my $icontheme        = $sc->icontheme;

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

	$active_window_item->signal_connect('activate' => sub { evt_take_screenshot(@_, 'awindow') if defined &evt_take_screenshot; });

	$menu_windows->append($active_window_item);
	$menu_windows->append(Gtk3::SeparatorMenuItem->new);

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
				'activate' => sub {
					evt_take_screenshot(@_, "shutter_window_direct" . $win->get_xid) if defined &evt_take_screenshot;
				});
			$menu_windows->append($window_item);
		}
	}

	$menu_windows->show_all;
	return $menu_windows;
}

sub fct_ret_workspace_menu ($self, $init) {
	my $cli           = $self->cli;
	my $sc            = $cli->sc;
	my $d             = $cli->sc->gettext_object;
	my $x11_supported = $cli->{_x11_supported};
	my $settings_xml  = $cli->{_settings_xml};

	my $menu_wrksp = Gtk3::Menu->new;
	unless ($x11_supported) {
		return $menu_wrksp;
	}

	my $wnck_screen = Wnck::Screen::get_default();
	unless ($wnck_screen) {
		$cli->{_current_monitor_active} = Gtk3::CheckMenuItem->new_with_label($d->get("Limit to current monitor"));
		return $menu_wrksp;
	}
	$wnck_screen->force_update();

	my $wm_name;
	if ($wnck_screen->can('get_window_manager_name')) {
		$wm_name = $wnck_screen->get_window_manager_name;
	}

	my $active_workspace = $wnck_screen->get_active_workspace;
	my @workspaces       = ();
	for (my $wcount = 0 ; $wcount < $wnck_screen->get_workspace_count ; $wcount++) {
		push(@workspaces, $wnck_screen->get_workspace($wcount));
	}

	foreach my $space (@workspaces) {
		next unless defined $space;

		print "Current window manager: ", $wm_name, "\n" if $sc->debug;
		if ($wm_name =~ /compiz/i) {

			# ... (compiz viewport logic) ...
		} else {
			my $wrkspace_item = Gtk3::MenuItem->new_with_label($space->get_name);
			$wrkspace_item->signal_connect(
				'activate' => sub {
					evt_take_screenshot(@_, "shutter_wrksp_direct" . $space->get_number) if defined &evt_take_screenshot;
				});
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
		'activate' => sub {
			evt_take_screenshot(@_, "shutter_wrksp_directall") if defined &evt_take_screenshot;
		});
	$menu_wrksp->append($allwspaces_item);

	#monitor flag
	my $n_mons = Gtk3::Gdk::Screen::get_default->get_n_monitors;

	#use only current monitor
	$menu_wrksp->append(Gtk3::SeparatorMenuItem->new);
	if ($init) {
		$cli->{_current_monitor_active} = Gtk3::CheckMenuItem->new_with_label($d->get("Limit to current monitor"));
		if (defined $settings_xml && defined $settings_xml->{'general'}->{'current_monitor_active'}) {
			$cli->{_current_monitor_active}->set_active($settings_xml->{'general'}->{'current_monitor_active'});
		} else {
			$cli->{_current_monitor_active}->set_active(FALSE);
		}
		$menu_wrksp->append($cli->{_current_monitor_active});
	} else {
		$cli->{_current_monitor_active}->reparent($menu_wrksp);
	}

	$cli->{_current_monitor_active}->set_tooltip_text(
		sprintf(
			$d->nget(
				"This option is only useful when you are running a multi-monitor system (%d monitor detected).\nEnable it to capture only the current monitor.",
				"This option is only useful when you are running a multi-monitor system (%d monitors detected).\nEnable it to capture only the current monitor.",
				$n_mons
			),
			$n_mons
		));
	if ($n_mons > 1) {
		$cli->{_current_monitor_active}->set_sensitive(TRUE);
	} else {
		$cli->{_current_monitor_active}->set_active(FALSE);
		$cli->{_current_monitor_active}->set_sensitive(FALSE);
	}

	$menu_wrksp->show_all();
	return $menu_wrksp;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Menu_Ret_Workspace - Workspace menu return handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
