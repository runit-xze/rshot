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

package Shutter::App::Handlers::Menu_Ret_Tray;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_ret_program_menu ($self, $menu_programs) {
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $session_screens = $cli->{_session_screens};
    my $session_start_screen = $cli->{_session_start_screen};
    my $sm = $cli->{_sm};
    my $shf = $cli->shf;

    $menu_programs = Gtk3::Menu->new unless defined $menu_programs;
    foreach my $child ($menu_programs->get_children) {
        $child->destroy;
    }

    #take $key (mime) directly
    my $key = fct_get_current_file() if defined &fct_get_current_file;

    #search selected files for mime...
    unless ($key) {
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
    }

    #still no key? => leave sub
    unless ($key) {
        $sm->{_menuitem_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_reopen};
        $sm->{_menuitem_large_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_large_reopen};
        return $menu_programs;
    }

    #no valid hash entry?
    unless (exists $session_screens->{$key}->{'mime_type'}) {
        $sm->{_menuitem_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_reopen};
        $sm->{_menuitem_large_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_large_reopen};
        return $menu_programs;
    }

    #get applications
    my $mime_type = $session_screens->{$key}->{'mime_type'};

    my $apps = Glib::IO::AppInfo::get_recommended_for_type($mime_type);

    unless (defined $apps) {
        $sm->{_menuitem_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_reopen};
        $sm->{_menuitem_large_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_large_reopen};
        return $menu_programs;
    }

    #no apps determined!
    unless (scalar @$apps) {
        $sm->{_menuitem_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_reopen};
        $sm->{_menuitem_large_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_large_reopen};
        return $menu_programs;
    }

    #create menu items
    foreach my $app (@$apps) {
        next if $app->get_display_name =~ /shutter/i;

        my $program_item = Gtk3::ImageMenuItem->new_with_label($app->get_display_name);
        $program_item->set('always_show_image' => TRUE);
        $menu_programs->append($program_item);

        my $icon = $app->get_icon;
        if ($icon && $program_item) {
            my $icon_pixbuf = undef;
            my ($iw, $ih) = $shf->icon_size('menu');
            eval {
                my $icon_info = $sc->get_theme->choose_icon($icon->get_names, $ih, []);
                $icon_pixbuf = $icon_info->load_icon if $icon_info;
            };
            if ($@) {
                print "\nWARNING: Could not load icon for ", $app->get_display_name, ": $@\n";
                $icon_pixbuf = undef;
            }
            if ($icon_pixbuf) {
                $program_item->set_image(Gtk3::Image->new_from_pixbuf($icon_pixbuf));
            }
        }

        #connect to signal
        if ($program_item) {
            $program_item->signal_connect(
                'activate' => sub {
                    fct_open_with_program($app, $app->get_display_name) if defined &fct_open_with_program;
                });
        }
    }

    #menu does not contain any item
    unless ($menu_programs->get_children) {
        $sm->{_menuitem_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_reopen};
        $sm->{_menuitem_large_reopen}->set_sensitive(FALSE) if $sm->{_menuitem_large_reopen};
    }

    $menu_programs->show_all;
    return $menu_programs;
}

sub fct_ret_tray_menu ($self) {
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $d = $cli->sc->get_gettext;
    my $shf = $cli->shf;
    my $lp = $cli->{_lp};
    my $shutter_root = $cli->shutter_root;
    my $x11_supported = $cli->{_x11_supported};
    my $gnome_web_photo = $cli->{_gnome_web_photo};
    my $tray_menu = $cli->{_tray_menu};

    my $traytheme = $sc->get_theme;
    my $menu_tray = Gtk3::Menu->new();

    #selection
    my $menuitem_select = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Selection'));
    $menuitem_select->set_sensitive($x11_supported);
    # ... (remaining initialization code) ...
    $menu_tray->show_all;

    return $menu_tray;
}

sub fct_update_tray_menu ($self, $screen) {
    my $cli = $self->cli;
    my $h   = $cli->handlers;
    my $sc  = $cli->sc;
    my $tray_menu = $cli->{_tray_menu};

    if ($sc->get_debug) {
        print "\nfct_update_tray_menu was called by $screen\n";
    }

    #update window list
    if ($tray_menu) {
        foreach my $child ($tray_menu->get_children) {
            if ($child->get_name eq 'windowlist') {
                $child->set_submenu($h->get('Menu_Ret_Workspace')->fct_ret_window_menu());
                last;
            }
        }
    }
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Menu_Ret_Tray - Tray menu return handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
