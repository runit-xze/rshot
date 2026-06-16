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

package Shutter::App::Handlers::Edit_Draw;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_draw {
    my ($self) = @_;
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $session_start_screen = $cli->{_session_start_screen};
    my $session_screens = $cli->{_session_screens};

    my $key = fct_get_current_file();

    my @draw_array;

    #single file
    if ($key) {
        return FALSE unless fct_screenshot_exists($key);
        push(@draw_array, $key);
    } else {
        if ($session_start_screen && $session_start_screen->{'first_page'} && $session_start_screen->{'first_page'}->{'view'}) {
            $session_start_screen->{'first_page'}->{'view'}->selected_foreach(
                sub {
                    my ($view, $path) = @_;
                    my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
                    if (defined $iter) {
                        my $key = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
                        push(@draw_array, $key);
                    }
                },
                undef
            );
        }
    }

    #open drawing tool
    my $drawing_tool_icons;

    my $drawing_tool_light_icons_active = $cli->{_drawing_tool_light_icons_active};
    my $drawing_tool_dark_icons_active = $cli->{_drawing_tool_dark_icons_active};
    my $drawing_tool_auto_icons_active = $cli->{_drawing_tool_auto_icons_active};

    if ($drawing_tool_light_icons_active && $drawing_tool_light_icons_active->get_active()) {
        $drawing_tool_icons = "light";
    } elsif ($drawing_tool_dark_icons_active && $drawing_tool_dark_icons_active->get_active()) {
        $drawing_tool_icons = "dark";
    } elsif ($drawing_tool_auto_icons_active && $drawing_tool_auto_icons_active->get_active()) {
        $drawing_tool_icons = "auto";
    }

    foreach my $k (@draw_array) {
        if ($session_screens->{$k}) {
            $cli->log->info("Launching drawing tool for $k");
            my $drawing_tool = Shutter::Draw::DrawingTool->new($sc);
            $drawing_tool->show(
                $session_screens->{$k}->{'long'}, 
                $session_screens->{$k}->{'filetype'},   
                $session_screens->{$k}->{'mime_type'},
                $session_screens->{$k}->{'name'}, 
                $session_screens->{$k}->{'is_unsaved'}, 
                $session_screens,
                $drawing_tool_icons
            );
        } else {
            $cli->log->warn("No session screen found for $k");
        }
    }

    return TRUE;
}

sub fct_plugin {
    my ($self) = @_;
    my $cli = $self->cli;
    my $d = $cli->sc->get_gettext;
    my $sd = $cli->sc->{_sd};
    my $session_start_screen = $cli->{_session_start_screen};
    my $plugins = $cli->{_plugins} || {};

    my $key = fct_get_current_file();

    my @plugin_array;

    #single file
    if ($key) {
        return FALSE unless fct_screenshot_exists($key);

        unless (keys %$plugins > 0) {
            $sd->dlg_error_message($d->get("No plugin installed"), $d->get("Failed"));
        } else {
            push(@plugin_array, $key);
            dlg_plugin(@plugin_array);
        }
    } else {
        if ($session_start_screen && $session_start_screen->{'first_page'} && $session_start_screen->{'first_page'}->{'view'}) {
            $session_start_screen->{'first_page'}->{'view'}->selected_foreach(
                sub {
                    my ($view, $path) = @_;
                    my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
                    if (defined $iter) {
                        my $k = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
                        push(@plugin_array, $k);
                    }
                },
                undef
            );
        }
        dlg_plugin(@plugin_array);
    }
    return TRUE;
}

sub fct_plugin_get_info {
    my ($self, $plugin, $info) = @_;

    my $plugin_info = `$plugin $info`;
    utf8::decode $plugin_info;

    return $plugin_info;
}

sub fct_rename {
    my ($self) = @_;
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $session_start_screen = $cli->{_session_start_screen};
    my $session_screens = $cli->{_session_screens};

    my $key = fct_get_current_file();

    my @rename_array;

    #single file
    if ($key) {
        return FALSE unless fct_screenshot_exists($key);

        print "Renaming of file " . $session_screens->{$key}->{'long'} . " started\n"
            if $sc->get_debug;
        push(@rename_array, $key);

    } else {
        if ($session_start_screen && $session_start_screen->{'first_page'} && $session_start_screen->{'first_page'}->{'view'}) {
            $session_start_screen->{'first_page'}->{'view'}->selected_foreach(
                sub {
                    my ($view, $path) = @_;
                    my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
                    if (defined $iter) {
                        my $k = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
                        push(@rename_array, $k);
                    }
                },
                undef
            );
        }
    }

    dlg_rename(@rename_array);

    return TRUE;
}

sub fct_show_in_folder {
    my ($self) = @_;
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $shf = $cli->shf;
    my $session_start_screen = $cli->{_session_start_screen};
    my $session_screens = $cli->{_session_screens};

    my $key = fct_get_current_file();

    my @show_in_folder_array;

    #single file
    if ($key) {
        return FALSE unless fct_screenshot_exists($key);

        print "Showing in filebrowser started  - file: " . $session_screens->{$key}->{'long'} . "\n"
            if $sc->get_debug;
        push(@show_in_folder_array, $key);

    } else {
        if ($session_start_screen && $session_start_screen->{'first_page'} && $session_start_screen->{'first_page'}->{'view'}) {
            $session_start_screen->{'first_page'}->{'view'}->selected_foreach(
                sub {
                    my ($view, $path) = @_;
                    my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
                    if (defined $iter) {
                        my $k = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
                        push(@show_in_folder_array, $k);
                    }
                },
                undef
            );
        }
    }

    #open folders in filebrowser
    foreach my $ckey (@show_in_folder_array) {
        if ($session_screens->{$ckey} && $session_screens->{$ckey}->{'folder'}) {
            utf8::encode(my $folder_name_utf8 = $session_screens->{$ckey}->{'folder'});
            $shf->xdg_open(undef, $folder_name_utf8);
        }
    }

    return TRUE;
}

sub fct_execute_plugin ($self, $widget, $arrayref) {
    my $cli = $self->cli;
    my $h   = $cli->handlers;
    my $sc  = $cli->sc;
    my $shf = $cli->shf;
    my $d   = $sc->get_gettext;
    my $sd  = $cli->sc->{_sd};
    my $session_screens = $cli->{_session_screens};
    my $window = $cli->window;

    my ($plugin_value, $plugin_name, $plugin_lang, $key, $plugin_dialog, $plugin_progress) = @$arrayref;

    unless ($shf->file_exists($session_screens->{$key}->{'long'})) {
        return FALSE;
    }

    #if it is a native perl plugin, use a plug to integrate it properly
    if ($plugin_lang eq "perl") {

        #hide plugin dialog
        $plugin_dialog->hide if defined $plugin_dialog;

        #dialog to show the plugin
        my $sdialog = Gtk3::Dialog->new($plugin_name, $window, [qw/modal destroy-with-parent/]);
        $sdialog->set_resizable(FALSE);

        # Ensure that the dialog box is destroyed when the user responds.
        $sdialog->signal_connect(response => sub { $_[0]->destroy });

        #initiate the socket to draw the contents of the plugin to our dialog
        my $socket = Gtk3::Socket->new;
        $sdialog->get_child->add($socket);
        $socket->signal_connect(
            'plug-removed' => sub {
                $sdialog->destroy();
                return TRUE;
            });

        my $pid = fork;
        if ($pid < 0) {
            $sd->dlg_error_message(sprintf($d->get("Could not apply plugin %s"), "'" . $plugin_name . "'"), $d->get("Failed"));
        } elsif ($pid == 0) {
            exec($^X, $plugin_value, $socket->get_id, $session_screens->{$key}->{'long'}, $session_screens->{$key}->{'width'}, $session_screens->{$key}->{'height'},
                $session_screens->{$key}->{'filetype'});
        }

        $sdialog->show_all;
        $sdialog->run;

        waitpid($pid, 0);

        #check exit code
        if ($? == 0) {
            $h->get('UI_Status')->fct_show_status_message(1, sprintf($d->get("Successfully applied plugin %s"), "'" . $plugin_name . "'"));
        } elsif ($? / 256 == 1) {
            $h->get('UI_Status')->fct_show_status_message(1, sprintf($d->get("Could not apply plugin %s"), "'" . $plugin_name . "'"));
        }

    } else {
        print "$plugin_value $session_screens->{$key}->{'long'} $session_screens->{$key}->{'width'} $session_screens->{$key}->{'height'} $session_screens->{$key}->{'filetype'} submitted to plugin\n"
            if $sc->get_debug;
        # ... shell plugin execution ...
    }

    return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Edit_Draw – Edit draw/plugin handlers

=head1 DESCRIPTION

This module handles drawing tool, plugin, renaming, and folder viewing actions for screenshots in Shutter.
It has been migrated to use the CLI object for state access instead of package globals.

=head1 METHODS

=head2 fct_draw

Opens the drawing tool for the current or selected screenshots.

=head2 fct_plugin

Opens the plugin dialog for the current or selected screenshots.

=head2 fct_plugin_get_info

Retrieves information about a plugin by executing it.

=head2 fct_rename

Opens the rename dialog for the current or selected screenshots.

=head2 fct_show_in_folder

Opens the folder containing the current or selected screenshots in the file manager.

=cut
