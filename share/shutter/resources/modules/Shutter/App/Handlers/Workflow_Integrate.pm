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

package Shutter::App::Handlers::Workflow_Integrate;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use URI::Escape qw(uri_unescape);

has cli => (is => 'ro', required => 1);

sub fct_integrate_screenshot_in_notebook ($self, $giofile, $pixbuf, $history = undef, $count = undef) {
    my $cli = $self->cli;
    my $d = $cli->sc->get_gettext;
    my $session_screens = $cli->{_session_screens};
    my $session_start_screen = $cli->{_session_start_screen};
    my $notebook = $cli->{_notebook};
    my $shf = $cli->shf;

    #check parameters
    return FALSE unless $giofile;

    unless ($giofile->query_exists) {
        $self->fct_show_status_message(1, $giofile->get_path . " " . $d->get("not found")) if defined &fct_show_status_message;
        return FALSE;
    }

    #check mime type
    my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $giofile->get_path);
    $mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;    #FIXME
    if ($mime_type =~ m/(pdf|ps|svg)/ig) {
        return FALSE;
    }

    #add to recentmanager
    Gtk3::RecentManager::get_default->add_item($giofile->get_path);

    my $num_files = $session_start_screen->{'first_page'}->{'num_session_files'};

    #append a page to notebook using with label == filename
    my $fname = $shf->utf8_decode(uri_unescape($giofile->get_basename));
    my $key   = 0;
    my $indx  = 0;
    if (defined $num_files && $num_files > 0) {
        if (defined $history && $history->get_history) {
            $indx = $num_files + 1;

            #update it (e.g. when taking more than one screenshot when still loading session)
            $session_start_screen->{'first_page'}->{'num_session_files'} = $indx;
        } elsif (defined $count) {
            $indx = $count;
        } else {
            $indx = $num_files + 1;
            my $h_get = $cli->handlers->get('Menu_Ret_Get');
            while ($indx < $h_get->fct_get_latest_tab_key()) {
                $indx++;
            }

            #update it (e.g. when taking more than one screenshot when still loading session)
            $session_start_screen->{'first_page'}->{'num_session_files'} = $indx;
        }
    } else {
        $indx = $cli->handlers->get('Menu_Ret_Get')->fct_get_latest_tab_key();
    }

    $key = "[" . $indx . "] - $fname";

    #store the history object
    if (defined $history && $history->get_history) {
        $session_screens->{$key}->{'history'}              = $history;
        $session_start_screen->{'first_page'}->{'history'} = $history;
        $session_screens->{$key}->{'history_timestamp'}    = time;
    }

    #setup tab label (thumb, preview etc.)
    my $hbox_tab_label = Gtk3::HBox->new(FALSE, 0);
    my $close_icon     = Gtk3::Image->new_from_icon_name('window-close', 'menu');

    $session_screens->{$key}->{'tab_icon'} = Gtk3::Image->new;

    #setup tab label
    my $tab_close_button = Gtk3::Button->new;
    $tab_close_button->set_relief('none');
    $tab_close_button->set_image($close_icon);
    $tab_close_button->set_name('tab-close-button');

    my $tab_label = Gtk3::Label->new($key);
    $tab_label->set_ellipsize('middle');
    $tab_label->set_width_chars(20);
    $hbox_tab_label->pack_start($session_screens->{$key}->{'tab_icon'}, FALSE, FALSE, 1);
    $hbox_tab_label->pack_start($tab_label,                           TRUE,  TRUE,  1);
    $hbox_tab_label->pack_start(Gtk3::HBox->new,                      TRUE,  TRUE,  1);
    $hbox_tab_label->pack_start($tab_close_button,                    FALSE, FALSE, 1);
    $hbox_tab_label->show_all;

    #and append page with label == key
    my $new_index = 0;
    if ($notebook) {
        my $h_session = $cli->handlers->get('Workflow_Session');
        if (defined $num_files && $num_files > 0) {
            if (defined $history && $history->get_history) {
                $new_index = $notebook->insert_page($h_session->fct_create_tab($key, FALSE), $hbox_tab_label, $indx);
            } elsif (defined $count) {
                $new_index = $notebook->insert_page($h_session->fct_create_tab($key, FALSE), $hbox_tab_label, $count);
            } else {
                $new_index = $notebook->insert_page($h_session->fct_create_tab($key, FALSE), $hbox_tab_label, $indx);
            }
        } else {
            $new_index = $notebook->append_page($h_session->fct_create_tab($key, FALSE), $hbox_tab_label);
        }
        $session_screens->{$key}->{'tab_child'}      = $notebook->get_nth_page($new_index);
    }
    $session_screens->{$key}->{'tab_indx'}       = $indx;
    $session_screens->{$key}->{'tab_label'}      = $tab_label;
    $session_screens->{$key}->{'hbox_tab_label'} = $hbox_tab_label;
    $tab_close_button->signal_connect(clicked => sub { $cli->handlers->get('Edit_Delete')->fct_remove($key); });

    #this value is undefined when all files are loaded
    #in this case we switch to any new image
    if ($notebook) {
        unless (defined $session_start_screen->{'first_page'}->{'num_session_files'}) {
            $notebook->set_current_page($new_index);
        } else {

            #if there is a history we recently took a screenshot
            #switch to that page
            #(even though the session is still loading)
            if (defined $history && $history->get_history) {
                $notebook->set_current_page($new_index);
            }
        }
    }

    my $h_status = $cli->handlers->get('UI_Status');
    if ($h_status->fct_update_tab($key, $pixbuf, $giofile, undef, undef, TRUE)) {
        #setup a filemonitor, so we get noticed if the file changed
        $cli->handlers->get('Events_Init')->fct_add_file_monitor($key);
    }

    return $key;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Workflow_Integrate - Workflow integration handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
