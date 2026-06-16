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

package Shutter::App::Handlers::Workflow_Session;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_create_session_notebook {
    my ($self) = @_;
    my $cli = $self->cli;
    my $notebook = $cli->{_notebook};
    my $session_start_screen = $cli->{_session_start_screen};
    my $d = $cli->sc->get_gettext;

    #~ $notebook->set( 'homogeneous' => TRUE );
    $notebook->set('scrollable' => TRUE) if $notebook;

    #enable dnd for it
    if ($notebook) {
        $notebook->drag_dest_set('all', [Gtk3::TargetEntry->new('text/uri-list', [], 0)], 'link');
        $notebook->signal_connect(drag_data_received => sub { $cli->handlers->get('Init_Handlers')->fct_drop_handler(@_) });
        $notebook->signal_connect(drag_motion => sub {
            my ($view, $ctx, $x, $y, $time) = @_;
            for my $target (@{$ctx->list_targets}) {
                if ($target->name eq 'text/uri-list') {
                    Gtk3::Gdk::drag_status($ctx, 'link', $time);
                    return TRUE;
                }
            }
            return FALSE;
        });
    }

    #packing and first page
    my $hbox_first_label = Gtk3::HBox->new(FALSE, 0);
    my $thumb_first_icon = Gtk3::Image->new_from_stock('gtk-index', 'menu');
    my $tab_first_label  = Gtk3::Label->new();
    $tab_first_label->set_markup("<b>" . $d->get("Session") . "</b>");
    $hbox_first_label->pack_start($thumb_first_icon, FALSE, FALSE, 1);
    $hbox_first_label->pack_start($tab_first_label,  FALSE, FALSE, 1);
    $hbox_first_label->show_all;

    my $new_index = $notebook->append_page($self->fct_create_tab("", TRUE), $hbox_first_label) if $notebook;
    $session_start_screen->{'first_page'}->{'tab_child'} = $notebook->get_nth_page($new_index) if $notebook;

    if ($notebook) {
        $notebook->signal_connect('switch-page' => sub { $cli->handlers->get('Screenshot_UI')->evt_notebook_switch(@_) });
    }

    return $notebook;
}

sub fct_create_tab {
    my ($self, $key, $is_all) = @_;
    my $cli = $self->cli;
    my $session_screens = $cli->{_session_screens};
    my $session_start_screen = $cli->{_session_start_screen};
    my $css_provider_alpha = $cli->{_css_provider_alpha};

    my $vbox     = Gtk3::VBox->new(FALSE, 0);
    my $vbox_tab = Gtk3::VBox->new(FALSE, 0);
    my $vbox_tab_event = Gtk3::EventBox->new;

    unless ($is_all) {
        #Gtk3::ImageView - empty at first
        try {
            $session_screens->{$key}->{'image'} = Gtk3::ImageView->new();
        } catch ($e) { }
        
        if ($session_screens->{$key}->{'image'}) {
            $session_screens->{$key}->{'image'}->set_fitting(TRUE);
            $session_screens->{$key}->{'image'}->get_style_context->add_provider($css_provider_alpha, 0) if $css_provider_alpha;
            $session_screens->{$key}->{'image'}->set('zoom-step', 1.2);
        }

        my $scrolled_window_image = Gtk3::ScrolledWindow->new;
        if ($session_screens->{$key}->{'image'}) {
            $scrolled_window_image->add_with_viewport($session_screens->{$key}->{'image'});
        } else {
             $scrolled_window_image->add_with_viewport(Gtk3::Label->new("Image View Not Available"));
        }

        if ($session_screens->{$key}->{'image'}) {
            $session_screens->{$key}->{'image'}->signal_connect(
                'scroll-event',
                sub {
                    my ($view, $ev) = @_;
                    if ($ev->direction eq 'left') {
                        $ev->direction('up');
                    } elsif ($ev->direction eq 'right') {
                        $ev->direction('down');
                    }
                    return FALSE;
                });

            $session_screens->{$key}->{'image'}->signal_connect(
                'button-press-event',
                sub {
                    my ($view, $ev) = @_;
                    if ($ev->button == 1 && $ev->type eq '2button-press') {
                        $cli->handlers->get('Core')->fct_zoom_best();
                        return TRUE;
                    } else {
                        return FALSE;
                    }
                });
        }

        $vbox_tab->pack_start($scrolled_window_image, TRUE, TRUE, 0);
        $vbox->pack_start($vbox_tab, TRUE, TRUE, 0);

        $vbox_tab_event->add($vbox);
        $vbox_tab_event->show_all;
        $vbox_tab_event->signal_connect('button-press-event' => sub { $cli->handlers->get('Events_Tray')->evt_tab_button_press(@_, $key) });

        return $vbox_tab_event;
    } else {
        #create iconview for session
        # Use existing model if available
        unless ($session_start_screen->{'first_page'}->{'model'}) {
            $session_start_screen->{'first_page'}->{'model'} = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String');
            $session_start_screen->{'first_page'}->{'model'}->set_sort_column_id(2, 'descending');
        }
        $session_start_screen->{'first_page'}->{'view'} = Gtk3::IconView->new_with_model($session_start_screen->{'first_page'}->{'model'});

        $session_start_screen->{'first_page'}->{'view'}->set_item_width(100);
        $session_start_screen->{'first_page'}->{'view'}->set_pixbuf_column(0);
        $session_start_screen->{'first_page'}->{'view'}->set_text_column(1);
        $session_start_screen->{'first_page'}->{'view'}->set_selection_mode('multiple');

        $session_start_screen->{'first_page'}->{'view'}->signal_connect('selection-changed' => sub { $cli->handlers->get('Events_Tray')->evt_iconview_sel_changed(@_) });
        $session_start_screen->{'first_page'}->{'view'}->signal_connect('item-activated'    => sub { $cli->handlers->get('Events_Tray')->evt_iconview_item_activated(@_) });

        my $scrolled_window_view = Gtk3::ScrolledWindow->new;
        $scrolled_window_view->set_policy('automatic', 'automatic');
        $scrolled_window_view->set_shadow_type('in');
        $scrolled_window_view->add($session_start_screen->{'first_page'}->{'view'});

        my $view_event = Gtk3::EventBox->new;
        $view_event->add($scrolled_window_view);
        $view_event->signal_connect('button-press-event' => sub { $cli->handlers->get('Events_Tray')->evt_iconview_button_press(@_, $session_start_screen->{'first_page'}->{'view'}) });

        $session_start_screen->{'first_page'}->{'view'}->enable_model_drag_source(
            'button1-mask',
            [Gtk3::TargetEntry->new('text/uri-list', [], 0)],
            ['copy']);
        $session_start_screen->{'first_page'}->{'view'}->signal_connect(
            'drag-data-get',
            sub {
                my ($widget, $context, $data, $info, $time) = @_;

                my @target_list;
                $session_start_screen->{'first_page'}->{'view'}->selected_foreach(
                    sub {
                        my ($view, $path) = @_;
                        my $iter = $session_start_screen->{'first_page'}->{'model'}->get_iter($path);
                        if (defined $iter) {
                            my $k = $session_start_screen->{'first_page'}->{'model'}->get_value($iter, 2);
                            if (exists $session_screens->{$k}->{'giofile'}
                                && defined $session_screens->{$k}->{'giofile'})
                            {
                                push @target_list, $session_screens->{$k}->{'giofile'}->get_uri;
                            }
                        }
                    });

                $data->set_uris(\@target_list);

            });

        $vbox_tab->pack_start($view_event, TRUE, TRUE, 0);

        $vbox->pack_start($vbox_tab, TRUE, TRUE, 0);
        $vbox->show_all;

        return $vbox;
    }
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Workflow_Session - Session workflow handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
