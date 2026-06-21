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

package Shutter::App::Handlers::Menu_Ret_UploadLinks;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_ret_upload_links_menu ($self, $key, $menu_links) {
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $session_screens = $cli->{_session_screens};
    my $clipboard = $cli->{_clipboard} || Gtk3::Clipboard::get(Gtk3::Gdk::Atom::intern("CLIPBOARD", FALSE));

    my $traytheme = $sc->get_theme;

    if (defined $menu_links) {
        foreach my $child ($menu_links->get_children) {
            $child->destroy;
        }
    } else {
        $menu_links = Gtk3::Menu->new;
    }

    my $nmenu_entries = 0;

    if (defined $key && exists $session_screens->{$key}->{'links'}) {
        foreach my $hoster (keys %{$session_screens->{$key}->{'links'}}) {

            #no longer valid
            next
                unless defined $session_screens->{$key}->{'links'}->{$hoster};
            next
                unless scalar keys %{$session_screens->{$key}->{'links'}->{$hoster}} > 0;
            next
                unless defined $session_screens->{$key}->{'links'}->{$hoster}->{'menuentry'};

            #create menu entry
            my $menuitem_hoster = Gtk3::ImageMenuItem->new_with_mnemonic($session_screens->{$key}->{'links'}->{$hoster}->{'menuentry'});
            if (defined $session_screens->{$key}->{'links'}->{$hoster}->{'menuimage'}) {
                if ($traytheme->has_icon($session_screens->{$key}->{'links'}->{$hoster}->{'menuimage'})) {
                    $menuitem_hoster->set_image(Gtk3::Image->new_from_icon_name($session_screens->{$key}->{'links'}->{$hoster}->{'menuimage'}, 'menu'));
                }
            }

            #create submenu with urls
            my $menu_urls = Gtk3::Menu->new;
            foreach my $url (keys %{$session_screens->{$key}->{'links'}->{$hoster}}) {
                next if $url eq 'menuimage';
                next if $url eq 'menuentry';
                next if $url eq 'pubfile';

                #create item
                my $menuitem_url = Gtk3::MenuItem->new_with_label($session_screens->{$key}->{'links'}->{$hoster}->{$url});
                foreach my $child ($menuitem_url->get_children) {
                    if ($child =~ m/Gtk3::AccelLabel/) {
                        $child->set_ellipsize('middle');
                        $child->set_width_chars(20);
                        last;
                    }
                }
                $menuitem_url->signal_connect(
                    activate => sub {
                        $clipboard->set_text($session_screens->{$key}->{'links'}->{$hoster}->{$url});
                    });

                #prepare identifier for tooltiup
                #e.g. direct_link => Direct link
                my $prep_url = $url;
                $prep_url =~ s/_/ /ig;
                $prep_url = ucfirst $prep_url;
                $menuitem_url->set_tooltip_text($prep_url);

                $menu_urls->append($menuitem_url);
            }

            $menuitem_hoster->set_submenu($menu_urls);

            $menu_links->append($menuitem_hoster);

            $nmenu_entries++;

        }
    }

    $menu_links->show_all;

    return ($nmenu_entries, $menu_links);
}


1;

__END__

=head1 NAME

Shutter::App::Handlers::Menu_Ret_UploadLinks - Upload links menu return handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
