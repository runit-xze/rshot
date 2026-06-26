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

package Shutter::App::Handlers::Screenshot_UI;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub evt_notebook_switch ($self, $widget, $pointer, $int) {
	my $cli             = $self->cli;
	my $notebook        = $cli->{_notebook};
	my $session_screens = $cli->{_session_screens};
	my $lp              = $cli->{_lp};

	my $key = $cli->handlers->get('UI_Tabs')->fct_get_file_by_index($int);
	if ($key) {
		Glib::Idle->add(
			sub {

				#is key still current page?
				if (defined $key) {
					return FALSE unless exists $session_screens->{$key};
					return FALSE
						unless $session_screens->{$key}->{'tab_child'} == $notebook->get_nth_page($notebook->get_current_page);
				}
				foreach my $ckey (keys %$session_screens) {

					#set pixbuf for current item
					if ($ckey eq $key) {
						if ($session_screens->{$key}->{'long'}) {

							#update window title
							$cli->handlers->get('UI_Status')->fct_update_info_and_tray($key);

							#do nothing if the view does already show a pixbuf
							if (exists $session_screens->{$ckey}
								&& defined $session_screens->{$ckey}->{'image'})
							{
								unless ($session_screens->{$ckey}->{'image'}->get_pixbuf) {
									$session_screens->{$ckey}->{'image'}->set_pixbuf($lp->load($session_screens->{$key}->{'long'}, undef, undef, undef, TRUE), TRUE) if $lp;
								}
							}
						}
						next;
					}

					#unset imageview for all other items
					if (exists $session_screens->{$ckey}
						&& defined $session_screens->{$ckey}->{'image'})
					{
						if ($session_screens->{$ckey}->{'image'}->get_pixbuf) {
							$session_screens->{$ckey}->{'image'}->set_pixbuf(undef);
						}
					}
				}
				return FALSE;
			});
	} else {
		Glib::Idle->add(
			sub {
				$cli->handlers->get('UI_Status')->fct_update_info_and_tray("session");
				return FALSE;
			});
	}

	#unselect all items in session tab
	#when we move away
	if ($int == 0) {
		$self->cli->{_session_start_screen}->{'first_page'}->{'view'}->unselect_all;
	}

	#enable/disable menu entry when we switch tabs
	$cli->handlers->get('Screenshot_Actions')->fct_update_actions($int, $key);

	return TRUE;
}

sub evt_value_changed ($self, $widget, $data) {
	my $cli                = $self->cli;
	my $sc                 = $cli->sc;
	my $d                  = $cli->sc->get_gettext;
	my $window             = $cli->window;
	my $css_provider_alpha = $cli->{_css_provider_alpha};
	my $shutter_root       = $cli->shutter_root;

	# a small workaround when the widget is undef
	$widget ||= "undef";

	print "\n$data was emitted by widget $widget\n"
		if $sc->get_debug;

	return FALSE unless $data;

	#checkbox for "open with" -> entry active/inactive
	if ($data eq "progname_toggled") {
		my $progname_active = $cli->{_progname_active};
		my $progname        = $cli->{_progname};
		if ($progname_active->get_active) {
			$progname->set_sensitive(TRUE);
		} else {
			$progname->set_sensitive(FALSE);
		}
	}

	#checkbox for "color depth" -> entry active/inactive
	if ($data eq "im_colors_toggled") {
		my $im_colors_active   = $cli->{_im_colors_active};
		my $combobox_im_colors = $cli->{_combobox_im_colors};
		if ($im_colors_active->get_active) {
			$combobox_im_colors->set_sensitive(TRUE);
		} else {
			$combobox_im_colors->set_sensitive(FALSE);
		}
	}

	#radiobuttons for "transparent parts"
	if ($data eq "transp_toggled") {
		my $trans_check      = $cli->{_trans_check};
		my $trans_custom     = $cli->{_trans_custom};
		my $trans_custom_btn = $cli->{_trans_custom_btn};
		my $trans_backg      = $cli->{_trans_backg};

		#Sets how the view should draw transparent parts of images with an alpha channel
		if ($trans_check->get_active) {
			$css_provider_alpha->load_from_data("
                .imageview.transparent {
                    background-image: url('$shutter_root/share/shutter/resources/gui/checkers.svg');
                }
            ");
		} elsif ($trans_custom->get_active) {
			my $color_string = $trans_custom_btn->get_rgba->to_string;
			$css_provider_alpha->load_from_data("
                .imageview.transparent {
                    background-color: $color_string;
                }
            ");
		} elsif ($trans_backg->get_active) {
			$css_provider_alpha->load_from_data(" ");
		}
		$window->queue_draw;
	}

	#"cursor_status" toggled
	if ($data eq "cursor_status_toggled") {
		$cli->{_cursor_active}->set_active($cli->{_cursor_status_active}->get_active);
	}

	#"cursor" toggled
	if ($data eq "cursor_toggled") {
		$cli->{_cursor_status_active}->set_active($cli->{_cursor_active}->get_active);
	}

	#value for "delay" -> update text
	if ($data eq "delay_changed") {
		$cli->{_delay_status}->set_value($cli->{_delay}->get_value);
		$cli->{_delay_vlabel}->set_text($d->nget("second", "seconds", $cli->{_delay}->get_value));
	}

	#value for "delay" -> update text
	if ($data eq "delay_status_changed") {
		$cli->{_delay}->set_value($cli->{_delay_status}->get_value);
		$cli->{_delay_status_vlabel}->set_text($d->nget("second", "seconds", $cli->{_delay_status}->get_value));
	}

	#value for "menu_delay" -> update text
	if ($data eq "menu_delay_changed") {
		$cli->{_menu_delay_vlabel}->set_text($d->nget("second", "seconds", $cli->{_menu_delay}->get_value));
	}

	#value for "hide_time" -> update text
	if ($data eq "hide_time_changed") {
		$cli->{_hide_time_vlabel}->set_text($d->nget("millisecond", "milliseconds", $cli->{_hide_time}->get_value));
	}

	#checkbox for "thumbnail" -> HScale active/inactive
	if ($data eq "thumbnail_toggled") {
		my $thumbnail_active = $cli->{_thumbnail_active};
		my $thumbnail        = $cli->{_thumbnail};
		if ($thumbnail_active->get_active) {
			$thumbnail->set_sensitive(TRUE);
		} else {
			$thumbnail->set_sensitive(FALSE);
		}
	}

	#quality value changed
	if ($data eq "qvalue_changed") {
		my $settings = undef;
		if (defined $sc->get_globalsettings_object) {
			$settings = $sc->get_globalsettings_object;
		} else {
			$settings = Shutter::App::GlobalSettings->new();
			$sc->set_globalsettings_object($settings);
		}
		my $combobox_type = $cli->{_combobox_type};
		my $scale         = $cli->{_scale};
		if ($combobox_type->get_active_text =~ /jpeg/) {
			$settings->set_image_quality("jpg", $scale->get_value);
		} elsif ($combobox_type->get_active_text =~ /jpg/) {
			$settings->set_image_quality("jpg", $scale->get_value);
		} elsif ($combobox_type->get_active_text =~ /png/) {
			$settings->set_image_quality("png", $scale->get_value);
		} elsif ($combobox_type->get_active_text =~ /webp/) {
			$settings->set_image_quality("webp", $scale->get_value);
		} elsif ($combobox_type->get_active_text =~ /avif/) {
			$settings->set_image_quality("avif", $scale->get_value);
		} else {
			$settings->clear_quality_settings();
		}
	}

	#checkbox for "bordereffect" -> HScale active/inactive
	if ($data eq "bordereffect_toggled") {
		my $bordereffect_active = $cli->{_bordereffect_active};
		my $bordereffect        = $cli->{_bordereffect};
		if ($bordereffect_active->get_active) {
			$bordereffect->set_sensitive(TRUE);
		} else {
			$bordereffect->set_sensitive(FALSE);
		}
	}

	#value for "bordereffect" -> update text
	if ($data eq "bordereffect_changed") {
		$cli->{_bordereffect_vlabel}->set_text($d->nget("pixel", "pixels", $cli->{_bordereffect}->get_value));
	}

	#filetype changed
	if ($data eq "type_changed") {
		my $scale         = $cli->{_scale};
		my $scale_label   = $cli->{_scale_label};
		my $combobox_type = $cli->{_combobox_type};
		$scale->set_sensitive(TRUE);
		$scale_label->set_sensitive(TRUE);
		$scale_label->set_text($d->get("Quality") . ":");
		if ($combobox_type->get_active_text =~ /jpeg/) {
			$scale->set_range(1, 100);
			$scale->set_value(90);
		} elsif ($combobox_type->get_active_text =~ /jpg/) {
			$scale->set_range(1, 100);
			$scale->set_value(90);
		} elsif ($combobox_type->get_active_text =~ /png/) {
			$scale->set_range(0, 9);
			$scale->set_value(9);
			$scale_label->set_text($d->get("Compression") . ":");
		} elsif ($combobox_type->get_active_text =~ /webp/) {
			$scale->set_range(0, 100);
			$scale->set_value(98);
		} elsif ($combobox_type->get_active_text =~ /avif/) {
			$scale->set_range(0, 100);
			$scale->set_value(68);
		} else {
			$scale->set_sensitive(FALSE);
			$scale_label->set_sensitive(FALSE);
		}
	}

	#notify agent changed
	if ($data eq "ns_changed") {
		my $combobox_ns = $cli->{_combobox_ns};
		if ($combobox_ns->get_active == 0) {
			$sc->set_notification_object(Shutter::App::Notification->new);
		} else {
			$sc->set_notification_object(Shutter::App::ShutterNotification->new($sc));
		}
	}

	return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Screenshot_UI - Screenshot UI handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
