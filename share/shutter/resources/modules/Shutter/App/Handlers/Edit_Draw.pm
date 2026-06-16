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

1;

__END__

=head1 NAME

Shutter::App::Handlers::Edit_Draw – Edit draw/plugin handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
