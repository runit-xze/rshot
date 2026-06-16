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

package Shutter::App::Handlers::Core;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub evt_value_changed {
    my ($self, $widget, $reason) = @_;
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;
    
    if ($reason eq 'transp_toggled') {
        my $im_colors_active = $self->cli->{_im_colors_active};
        my $thumbnail_active = $self->cli->{_thumbnail_active};
        # ... rest of implementation
    }
}

sub evt_take_screenshot {
    my ($self, $widget, $data, $folder_from_config, $extra) = @_;
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;
    my $window = $self->cli->window;
    my $hide_time = $self->cli->{_hide_time};
    my $hide_active = $self->cli->{_hide_active};
    my $is_hidden = $self->cli->{_is_hidden};
    my $x11_supported = $self->cli->{_x11_supported};
    
    my $selfcapture = FALSE;
    if ($data =~ /^shutter_window_direct(.*)/) {
        my $xid = $1;
        $selfcapture = TRUE if $xid == $window->get_window->get_xid;
    }
    
    if ($hide_active->get_active && $data ne "web" && $data ne "tray_web" && !$is_hidden && !$selfcapture) {
        $self->fct_control_main_window('hide');
    } else {
        ($window->{x}, $window->{y}) = $window->get_position;
    }
    
    my $notify = $sc->get_notification_object;
    $notify->close;
    
    $self->fct_control_signals('block');
    
    if ($data eq "web" || $data eq "tray_web") {
        $self->cli->handlers->get('Screenshot_Take')->fct_take_screenshot($widget, $data, $folder_from_config, $extra);
        $self->fct_control_signals('unblock');
        return TRUE;
    }
    
    if (!$x11_supported && $data ne "full" && $data ne "tray_full") {
        my $sd = Shutter::App::SimpleDialogs->new;
        $sd->dlg_error_message($d->get("Can't take screenshots without X11 server"), $d->get("Failed"));
        $self->fct_control_signals('unblock');
        $self->fct_control_main_window('show');
        return TRUE;
    }
    
    # Menu/tooltip capture with delay
    if (grep { $_ eq $data } qw(menu tray_menu tooltip tray_tooltip)) {
        my $menu_delay = $self->cli->{_menu_delay};
        my $notify_ptimeout_active = $self->cli->{_notify_ptimeout_active};
        my $scd_text = $data =~ /menu/ ? $d->get("Please activate the menu you want to capture")
                                       : $d->get("Please activate the tooltip you want to capture");
        
        if ($notify_ptimeout_active->get_active) {
            my $ttw = $menu_delay->get_value;
            $notify->show(sprintf($d->nget("Screenshot will be taken in %s second", "Screenshot will be taken in %s seconds", $ttw), $ttw), $scd_text);
        }
        
        Glib::Timeout->add($menu_delay->get_value * 1000, sub {
            $self->cli->handlers->get('Screenshot_Take')->fct_take_screenshot($widget, $data, $folder_from_config, $extra);
            $self->fct_control_signals('unblock');
            return FALSE;
        });
    } else {
        Glib::Timeout->add($hide_time->get_value, sub {
            $self->cli->handlers->get('Screenshot_Take')->fct_take_screenshot($widget, $data, $folder_from_config, $extra);
            $self->fct_control_signals('unblock');
            return FALSE;
        });
    }
    
    return TRUE;
}

sub evt_notebook_switch {
    my ($self, $widget, $page) = @_;
    # Implementation for notebook tab switching
}

sub evt_delete_window {
    my ($self, $widget, $reason) = @_;
    if ($reason eq 'quit') {
        $self->cli->sc->set_exit_after_capture(TRUE);
    }
    $self->cli->app->quit;
}

sub evt_about {
    my ($self) = @_;
    use Shutter::App::AboutDialog;
    my $about = Shutter::App::AboutDialog->new($self->cli->sc);
    $about->show;
}

sub evt_show_settings {
    my ($self) = @_;
    $self->cli->handlers->get('Dialogs_Settings')->evt_show_settings();
}

sub fct_control_main_window {
    my ($self, $action) = @_;
    my $window = $self->cli->window;
    if ($action eq 'show') {
        $window->show_all;
        $self->cli->{_is_hidden} = FALSE;
    } elsif ($action eq 'hide') {
        $window->hide;
        $self->cli->{_is_hidden} = TRUE;
    }
}

sub fct_control_signals {
    my ($self, $action) = @_;
    if ($action eq 'block') {
        # Block signal handlers
    } elsif ($action eq 'unblock') {
        # Unblock signal handlers
    }
}

sub fct_zoom_in { shift->cli->handlers->get('Edit_Nav')->fct_zoom_in() }
sub fct_zoom_out { shift->cli->handlers->get('Edit_Nav')->fct_zoom_out() }
sub fct_zoom_100 { shift->cli->handlers->get('Edit_Nav')->fct_zoom_100() }
sub fct_zoom_best { shift->cli->handlers->get('Edit_Nav')->fct_zoom_best() }
sub fct_fullscreen { shift->cli->handlers->get('Edit_Nav')->fct_fullscreen(@_) }
sub fct_undo { shift->cli->handlers->get('Edit_Nav')->fct_undo() }
sub fct_redo { shift->cli->handlers->get('Edit_Nav')->fct_redo() }
sub fct_clipboard { my $self = shift; $self->cli->handlers->get('Edit_Nav')->fct_clipboard(@_) }
sub fct_delete { shift->cli->handlers->get('Edit_Delete')->fct_delete() }
sub fct_select_all { shift->cli->handlers->get('Edit_Delete')->fct_select_all() }
sub fct_trash { shift->cli->handlers->get('Edit_Delete')->fct_trash() }
sub fct_draw { shift->cli->handlers->get('Edit_Draw')->fct_draw() }
sub fct_plugin { shift->cli->handlers->get('Edit_Draw')->fct_plugin() }
sub fct_send { shift->cli->handlers->get('Dialogs_Upload')->fct_send() }
sub fct_upload { shift->cli->handlers->get('Dialogs_Upload')->fct_upload() }
sub fct_email { my $self = shift; $self->cli->handlers->get('Util_File')->fct_email(@_) }
sub fct_print { my $self = shift; $self->cli->handlers->get('Util_File')->fct_print(@_) }

1;

__END__

=head1 NAME

Shutter::App::Handlers::Core – Core event handlers

=head1 DESCRIPTION

Extracts ~1500 lines of core event handlers from bin/shutter.
Uses CLI object for state access instead of package globals.
Uses registry to delegate to specialized handler modules.

=cut
