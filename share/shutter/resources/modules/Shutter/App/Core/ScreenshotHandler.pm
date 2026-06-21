###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2020-2021 Google LLC, contributed by Alexey Sokolov <sokolov@google.com>
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

package Shutter::App::Core::ScreenshotHandler;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;
use Time::HiRes qw/usleep/;

has '_common' => (is => 'ro', required => 1);

sub take_screenshot ($self, $widget, $data, $folder_from_config, $extra) {
    my $sc = $self->_common;
    my $shf = $sc->get_helper_functions;
    my $d = $sc->get_gettext;
    my $sd = Shutter::App::SimpleDialogs->new($sc->get_mainwindow);
    my $window = $sc->get_mainwindow;
    my $hide_active = $sc->get_hide_active;
    my $x11_supported = $sc->get_x11_supported;
    my $is_hidden = $sc->get_is_hidden;

    my $selfcapture = FALSE;
    if ($data =~ /^shutter_window_direct(.*)/) {
        my $xid = $1;
        $selfcapture = TRUE if $xid == $window->get_window->get_xid;
    }

    if ($hide_active->get_active && $data ne "web" && $data ne "tray_web" && !$is_hidden && !$selfcapture) {
        fct_control_main_window('hide');
    } else {
        ($window->{x}, $window->{y}) = $window->get_position;
    }

    my $notify = $sc->get_notification_object;
    $notify->close;

    fct_control_signals('block');

    if ($data eq "web" || $data eq "tray_web") {
        fct_take_screenshot($widget, $data, $folder_from_config, $extra);
        fct_control_signals('unblock');
        return TRUE;
    }

    unless ($x11_supported) {
        my $sd_tmp = Shutter::App::SimpleDialogs->new;
        $sd_tmp->dlg_error_message($d->get("Can't take screenshots without X11 server"), $d->get("Failed"));
        fct_control_signals('unblock');
        fct_control_main_window('show');
        return TRUE;
    }

    if ($data =~ /^(menu|tray_menu|tooltip|tray_tooltip)$/) {
        my $scd_text = $d->get("Please activate the menu you want to capture");
        if ($data =~ /^(menu|tray_menu)$/ && $ENV{GDK_SCALE} > 1) {
            my $sd_tmp = Shutter::App::SimpleDialogs->new;
            $sd_tmp->dlg_info_message("Capturing a cascading menu is known to be broken with HiDPI.\nPlease unset GDK_SCALE variable and restart Shutter.\nPlease follow https://github.com/shutter-project/shutter/issues/326 and send us the patch\nWill attempt capturing it anyway...", undef, 'gtk-ok');
        }

        if ($sc->get_notify_ptimeout_active) {
            my $ttw = $sc->get_menu_delay->get_value;
            $notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text);
            $ttw--;
            if ($ttw >= 1) {
                Glib::Timeout->add(1000, sub {
                    $notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text);
                    $ttw--;
                    if ($ttw == 0) {
                        Glib::Timeout->add(500, sub { $notify->close; return FALSE; });
                        return FALSE;
                    }
                    return TRUE;
                });
            } else {
                Glib::Timeout->add(500, sub { $notify->close; return FALSE; });
            }
        }

        Glib::Timeout->add($sc->get_menu_delay->get_value * 1000, sub {
            fct_take_screenshot($widget, $data, $folder_from_config, $extra);
            fct_control_signals('unblock');
            return FALSE;
        });
    } else {
        if ($data =~ /^section/ && $ENV{GDK_SCALE} > 1) {
            my $sd_tmp = Shutter::App::SimpleDialogs->new;
            $sd_tmp->dlg_info_message("Capturing a window section is known to be broken with HiDPI.\nPlease unset GDK_SCALE variable and restart Shutter.\nPlease follow https://github.com/shutter-project/shutter/issues/326 and send us the patch\nWill attempt capturing it anyway...", undef, 'gtk-ok');
        }

        Glib::Timeout->add($sc->get_hide_time->get_value, sub {
            fct_take_screenshot($widget, $data, $folder_from_config, $extra);
            fct_control_signals('unblock');
            return FALSE;
        });
    }

    return TRUE;
}

1;
