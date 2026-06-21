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

package Shutter::App::Handlers::Screenshot_Actions;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_update_actions ($self, $n_items, $key) {
    my $cli = $self->cli;
    my $session_screens = $cli->{_session_screens};
    my $notebook = $cli->{_notebook};
    my $sm = $cli->{_sm};
    my $st = $cli->{_st};
    my $tray_menu = $cli->{_tray_menu};
    my $goocanvas = $cli->{_goocanvas};
    my $nautilus_sendto = $cli->{_nautilus_sendto};

    Glib::Idle->add(
        sub {

            #does the file still exist?
            if (defined $key) {
                return FALSE unless exists $session_screens->{$key};
            }

            #is key still current page?
            if (defined $key && $notebook->get_current_page != 0) {
                return FALSE unless exists $session_screens->{$key};
                return FALSE
                    unless $session_screens->{$key}->{'tab_child'} == $notebook->get_nth_page($notebook->get_current_page);
            }

            #MENU
            #--------------------------------------
            $sm->{_menuitem_reopen}->set_submenu(fct_ret_program_menu($sm->{_menuitem_reopen}->get_submenu)) if defined &fct_ret_program_menu;

            #NAVIGATION BAR
            #--------------------------------------
            if (defined $key && $notebook->get_current_page != 0) {

                #does the file still exist?
                return FALSE unless exists $session_screens->{$key};

                #disable sort buttons when session tab is active
                $st->{_sorta}->set_sensitive(FALSE) if $st->{_sorta};
                $st->{_sortd}->set_sensitive(FALSE) if $st->{_sortd};
            } else {

                #enable sort buttons when session tab is active
                $st->{_sorta}->set_sensitive(TRUE) if $st->{_sorta};
                $st->{_sortd}->set_sensitive(TRUE) if $st->{_sortd};
            }

            #TRAY
            #--------------------------------------

            #last capture
            if ($tray_menu) {
                foreach my $child ($tray_menu->get_children) {
                    if ($child->get_name eq 'redoshot') {
                        $child->set_sensitive(fct_get_last_capture() ? TRUE : FALSE) if defined &fct_get_last_capture;
                        last;
                    }
                }
            }

            #TOOLBAR
            #--------------------------------------

            #last capture
            $st->{_redoshot}->set_sensitive(fct_get_last_capture() ? TRUE : FALSE) if ($st->{_redoshot} && defined &fct_get_last_capture);

            #goocanvas is optional, don't enable it when not installed
            if ($goocanvas) {
                $st->{_edit}->set_sensitive($n_items) if $st->{_edit};
            } else {
                $st->{_edit}->set_sensitive(FALSE) if $st->{_edit};
            }

            #upload links
            my (undef, $menu_links_tb) = $self->cli->handlers->get('Menu_Ret_UploadLinks')->fct_ret_upload_links_menu($key, $st->{_upload}->get_menu);
            if ($st->{_upload}) {
                $st->{_upload}->set_menu($menu_links_tb) if $menu_links_tb;
                $st->{_upload}->set_sensitive($n_items);
            }

            #MENU
            #--------------------------------------

            #last capture
            $sm->{_menuitem_redoshot}->set_sensitive($st->{_redoshot}->is_sensitive) if ($sm->{_menuitem_redoshot} && $st->{_redoshot});

            $sm->{_menuitem_save_as}->set_sensitive($n_items) if $sm->{_menuitem_save_as};

            $sm->{_menuitem_export_pdf}->set_sensitive($n_items) if $sm->{_menuitem_export_pdf};
            $sm->{_menuitem_export_pscript}->set_sensitive($n_items) if $sm->{_menuitem_export_pscript};
            $sm->{_menuitem_pagesetup}->set_sensitive($n_items) if $sm->{_menuitem_pagesetup};
            $sm->{_menuitem_print}->set_sensitive($n_items) if $sm->{_menuitem_print};
            $sm->{_menuitem_email}->set_sensitive($n_items) if $sm->{_menuitem_email};
            $sm->{_menuitem_close}->set_sensitive($n_items) if $sm->{_menuitem_close};
            $sm->{_menuitem_close_all}->set_sensitive($n_items) if $sm->{_menuitem_close_all};

            #edit
            if (   $n_items
                && defined $key
                && $session_screens->{$key}
                && defined $session_screens->{$key}->{'undo'}
                && scalar @{$session_screens->{$key}->{'undo'}} > 1)
            {
                $sm->{_menuitem_undo}->set_sensitive(TRUE) if $sm->{_menuitem_undo};
            } else {
                $sm->{_menuitem_undo}->set_sensitive(FALSE) if $sm->{_menuitem_undo};
            }

            if (   $n_items
                && defined $key
                && $session_screens->{$key}
                && defined $session_screens->{$key}->{'redo'}
                && scalar @{$session_screens->{$key}->{'redo'}} > 0)
            {
                $sm->{_menuitem_redo}->set_sensitive(TRUE) if $sm->{_menuitem_redo};
            } else {
                $sm->{_menuitem_redo}->set_sensitive(FALSE) if $sm->{_menuitem_redo};
            }

            $sm->{_menuitem_trash}->set_sensitive($n_items) if $sm->{_menuitem_trash};
            $sm->{_menuitem_copy}->set_sensitive($n_items) if $sm->{_menuitem_copy};
            $sm->{_menuitem_copy_filename}->set_sensitive($n_items) if $sm->{_menuitem_copy_filename};

            #view
            $sm->{_menuitem_zoom_in}->set_sensitive($n_items) if $sm->{_menuitem_zoom_in};
            $sm->{_menuitem_zoom_out}->set_sensitive($n_items) if $sm->{_menuitem_zoom_out};
            $sm->{_menuitem_zoom_100}->set_sensitive($n_items) if $sm->{_menuitem_zoom_100};
            $sm->{_menuitem_zoom_best}->set_sensitive($n_items) if $sm->{_menuitem_zoom_best};

            #screenshot
            $sm->{_menuitem_reopen}->set_sensitive($n_items) if $sm->{_menuitem_reopen};
            $sm->{_menuitem_show_in_folder}->set_sensitive($n_items) if $sm->{_menuitem_show_in_folder};
            $sm->{_menuitem_rename}->set_sensitive($n_items) if $sm->{_menuitem_rename};

            #upload links
            my ($nmenu_entries, $menu_links) = $self->cli->handlers->get('Menu_Ret_UploadLinks')->fct_ret_upload_links_menu($key, $sm->{_menuitem_links}->get_submenu) if $sm->{_menuitem_links};

            if ($sm->{_menuitem_links}) {
                $sm->{_menuitem_links}->set_submenu($menu_links) if $menu_links;
                $sm->{_menuitem_links}->set_sensitive($nmenu_entries);
            }

            #nautilus-sendto is optional, don't enable it when not installed
            if ($nautilus_sendto) {
                $sm->{_menuitem_send}->set_sensitive($n_items) if $sm->{_menuitem_send};
            } else {
                $sm->{_menuitem_send}->set_sensitive(FALSE) if $sm->{_menuitem_send};
            }

            $sm->{_menuitem_upload}->set_sensitive($n_items) if $sm->{_menuitem_upload};

            #goocanvas is optional, don't enable it when not installed
            if ($goocanvas) {
                $sm->{_menuitem_draw}->set_sensitive($n_items) if $sm->{_menuitem_draw};
            } else {
                $sm->{_menuitem_draw}->set_sensitive(FALSE) if $sm->{_menuitem_draw};
            }

            $sm->{_menuitem_plugin}->set_sensitive($n_items) if $sm->{_menuitem_plugin};

            #redoshot_this
            if (   defined $key
                && $session_screens->{$key}
                && exists $session_screens->{$key}->{'history'}
                && defined $session_screens->{$key}->{'history'})
            {
                $sm->{_menuitem_redoshot_this}->set_sensitive($n_items) if $sm->{_menuitem_redoshot_this};
            } else {
                $sm->{_menuitem_redoshot_this}->set_sensitive(FALSE) if $sm->{_menuitem_redoshot_this};
            }

            #right-click menu
            $sm->{_menuitem_large_reopen}->set_sensitive($n_items) if $sm->{_menuitem_large_reopen};
            $sm->{_menuitem_large_show_in_folder}->set_sensitive($n_items) if $sm->{_menuitem_large_show_in_folder};
            $sm->{_menuitem_large_rename}->set_sensitive($n_items) if $sm->{_menuitem_large_rename};
            $sm->{_menuitem_large_trash}->set_sensitive($n_items) if $sm->{_menuitem_large_trash};
            $sm->{_menuitem_large_copy}->set_sensitive($n_items) if $sm->{_menuitem_large_copy};
            $sm->{_menuitem_large_copy_filename}->set_sensitive($n_items) if $sm->{_menuitem_large_copy_filename};

            #upload links
            my ($nmenu_entries_large, $menu_links_large) = $self->cli->handlers->get('Menu_Ret_UploadLinks')->fct_ret_upload_links_menu($key, $sm->{_menuitem_large_links}->get_submenu) if $sm->{_menuitem_large_links};

            if ($sm->{_menuitem_large_links}) {
                $sm->{_menuitem_large_links}->set_submenu($menu_links_large) if $menu_links_large;
                $sm->{_menuitem_large_links}->set_sensitive($nmenu_entries_large);
            }

            #nautilus-sendto is optional, don't enable it when not installed
            if ($nautilus_sendto) {
                $sm->{_menuitem_large_send}->set_sensitive($n_items) if $sm->{_menuitem_large_send};
            } else {
                $sm->{_menuitem_large_send}->set_sensitive(FALSE) if $sm->{_menuitem_large_send};
            }

            $sm->{_menuitem_large_upload}->set_sensitive($n_items) if $sm->{_menuitem_large_upload};

            #goocanvas is optional, don't enable it when not installed
            if ($goocanvas) {
                $sm->{_menuitem_large_draw}->set_sensitive($n_items) if $sm->{_menuitem_large_draw};
            } else {
                $sm->{_menuitem_large_draw}->set_sensitive(FALSE) if $sm->{_menuitem_large_draw};
            }

            $sm->{_menuitem_large_plugin}->set_sensitive($n_items) if $sm->{_menuitem_large_plugin};

            #redoshot_this
            if (   defined $key
                && $session_screens->{$key}
                && exists $session_screens->{$key}->{'history'}
                && defined $session_screens->{$key}->{'history'})
            {
                $sm->{_menuitem_large_redoshot_this}->set_sensitive($n_items) if $sm->{_menuitem_large_redoshot_this};
            } else {
                $sm->{_menuitem_large_redoshot_this}->set_sensitive(FALSE) if $sm->{_menuitem_large_redoshot_this};
            }

            return FALSE;
        });

    return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Screenshot_Actions - Screenshot actions handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
