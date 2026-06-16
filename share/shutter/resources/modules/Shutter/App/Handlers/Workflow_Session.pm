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

		#~ $notebook->set( 'homogeneous' => TRUE );
		$notebook->set('scrollable' => TRUE);

		#enable dnd for it
		$notebook->drag_dest_set('all', [Gtk3::TargetEntry->new('text/uri-list', [], 0)], 'link');
		$notebook->signal_connect(drag_data_received => \&fct_drop_handler);
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

		#packing and first page
		my $hbox_first_label = Gtk3::HBox->new(FALSE, 0);
		my $thumb_first_icon = Gtk3::Image->new_from_stock('gtk-index', 'menu');
		my $tab_first_label  = Gtk3::Label->new();
		$tab_first_label->set_markup("<b>" . $d->get("Session") . "</b>");
		$hbox_first_label->pack_start($thumb_first_icon, FALSE, FALSE, 1);
		$hbox_first_label->pack_start($tab_first_label,  FALSE, FALSE, 1);
		$hbox_first_label->show_all;

		my $new_index = $notebook->append_page(fct_create_tab("", TRUE), $hbox_first_label);
		$session_start_screen{'first_page'}->{'tab_child'} = $notebook->get_nth_page($new_index);

		$notebook->signal_connect('switch-page' => \&evt_notebook_switch);

		return $notebook;
	}

	sub fct_create_tab {
		my ($key, $is_all) = @_;

		my $vbox     = Gtk3::VBox->new(FALSE, 0);
		my $vbox_tab = Gtk3::VBox->new(FALSE, 0);
		my $vbox_tab_event = Gtk3::EventBox->new;

		unless ($is_all) {

			#Gtk2::ImageView - empty at first
			$session_screens{$key}->{'image'} = Gtk3::ImageView->new();
			#$session_screens{$key}->{'image'}->set_show_frame(FALSE);
			$session_screens{$key}->{'image'}->set_fitting(TRUE);
			$session_screens{$key}->{'image'}->get_style_context->add_provider($css_provider_alpha, 0);
			$session_screens{$key}->{'image'}->set('zoom-step', 1.2);

			#Gtk2::ImageView::ScrollWin packaged in a Gtk2::ScrolledWindow
			#my $scrolled_window_image = Gtk2::ImageView::ScrollWin->new($session_screens{$key}->{'image'});
			my $scrolled_window_image = Gtk3::ScrolledWindow->new;
			$scrolled_window_image->add_with_viewport($session_screens{$key}->{'image'});

			#WORKAROUND
			#upstream bug
			#http://trac.bjourne.webfactional.com/ticket/21
			#left  => zoom in
			#right => zoom out
			$session_screens{$key}->{'image'}->signal_connect(
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

			$session_screens{$key}->{'image'}->signal_connect(
				'button-press-event',
				sub {
					my ($view, $ev) = @_;
					if ($ev->button == 1 && $ev->type eq '2button-press') {
						fct_zoom_best();
						return TRUE;
					} else {
						return FALSE;
					}
				});

			$session_screens{$key}->{'image'}->signal_connect(
				'dnd-start',
				sub {
					my ($view, $x, $y, $button) = @_;
					my $list = Gtk3::TargetList->new;
					$list->add_table([Gtk3::TargetEntry->new('text/uri-list', [], 0)]);
					my $ctx = $view->drag_begin_with_coordinates(
						$list,
						['copy'],
						$button,
						undef,
						$x, $y,
					);
					Gtk3::drag_set_icon_pixbuf($ctx, $view->{thumb}, 0, 0);
					return TRUE;
				}
			);
			$session_screens{$key}->{'image'}->signal_connect(
				'drag-data-get',
				sub {
					my ($widget, $context, $data, $info, $time) = @_;
					$data->set_uris([$session_screens{$key}->{'giofile'}->get_uri]);
				}
			);
			$session_screens{$key}->{'image'}->signal_connect(
				'zoom-changed',
				sub {
					my ($view, $zoom) = @_;
					if ($zoom >= 1) {
						$view->set_interpolation('nearest');
					} else {
						$view->set_interpolation('bilinear');
					}
				}
			);

			$vbox_tab->pack_start($scrolled_window_image, TRUE, TRUE, 0);

			$vbox->pack_start($vbox_tab, TRUE, TRUE, 0);

			#pack vbox into an event box so we can listen
			#to various key and button events
			$vbox_tab_event->add($vbox);
			$vbox_tab_event->show_all;
			$vbox_tab_event->signal_connect('button-press-event', \&evt_tab_button_press, $key);

			return $vbox_tab_event;

		} else {

			#create iconview for session
			$session_start_screen{'first_page'}->{'model'} = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String');
			$session_start_screen{'first_page'}->{'model'}->set_sort_column_id(2, 'descending');
			$session_start_screen{'first_page'}->{'view'} = Gtk3::IconView->new_with_model($session_start_screen{'first_page'}->{'model'});

			#~ $session_start_screen{'first_page'}->{'view'}->set_orientation('horizontal');
			$session_start_screen{'first_page'}->{'view'}->set_item_width(100);
			$session_start_screen{'first_page'}->{'view'}->set_pixbuf_column(0);
			$session_start_screen{'first_page'}->{'view'}->set_text_column(1);
			$session_start_screen{'first_page'}->{'view'}->set_selection_mode('multiple');

			#~ $session_start_screen{'first_page'}->{'view'}->set_columns(0);
			$session_start_screen{'first_page'}->{'view'}->signal_connect('selection-changed', \&evt_iconview_sel_changed,    'sel_changed');
			$session_start_screen{'first_page'}->{'view'}->signal_connect('item-activated',    \&evt_iconview_item_activated, 'item_activated');

			#pack into scrolled window
			my $scrolled_window_view = Gtk3::ScrolledWindow->new;
			$scrolled_window_view->set_policy('automatic', 'automatic');
			$scrolled_window_view->set_shadow_type('in');
			$scrolled_window_view->add($session_start_screen{'first_page'}->{'view'});

			#add an event box to show a context menu on right-click
			my $view_event = Gtk3::EventBox->new;
			$view_event->add($scrolled_window_view);
			$view_event->signal_connect('button-press-event', \&evt_iconview_button_press, $session_start_screen{'first_page'}->{'view'});

			#dnd
			$session_start_screen{'first_page'}->{'view'}->enable_model_drag_source(
				'button1-mask',
				[Gtk3::TargetEntry->new('text/uri-list', [], 0)],
				['copy']);
			$session_start_screen{'first_page'}->{'view'}->signal_connect(
				'drag-data-get',
				sub {
					my ($widget, $context, $data, $info, $time) = @_;

					my @target_list;
					$session_start_screen{'first_page'}->{'view'}->selected_foreach(
						sub {
							my ($view, $path) = @_;
							my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
							if (defined $iter) {
								my $key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
								if (exists $session_screens{$key}->{'giofile'}
									&& defined $session_screens{$key}->{'giofile'})
								{
									push @target_list, $session_screens{$key}->{'giofile'}->get_uri;
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
