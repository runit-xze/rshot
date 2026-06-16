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

	sub fct_ret_program_menu {
		my $menu_programs = shift;

		$menu_programs = Gtk3::Menu->new unless defined $menu_programs;
		foreach my $child ($menu_programs->get_children) {
			$child->destroy;
		}

		#take $key (mime) directly
		my $key = fct_get_current_file();

		#FIXME - different mime types
		#have different apps registered
		#we should restrict the offeres apps
		#by comparing the selected
		#
		#currently we just take the last selected file into account
		#
		#search selected files for mime...
		unless ($key) {
			$session_start_screen{'first_page'}->{'view'}->selected_foreach(
				sub {
					my ($view, $path) = @_;
					my $iter = $session_start_screen{'first_page'}->{'model'}->get_iter($path);
					if (defined $iter) {
						$key = $session_start_screen{'first_page'}->{'model'}->get_value($iter, 2);
					}
				});
		}

		#still no key? => leave sub
		unless ($key) {
			$sm->{_menuitem_reopen}->set_sensitive(FALSE);
			$sm->{_menuitem_large_reopen}->set_sensitive(FALSE);
			return $menu_programs;
		}

		#no valid hash entry?
		unless (exists $session_screens{$key}->{'mime_type'}) {
			$sm->{_menuitem_reopen}->set_sensitive(FALSE);
			$sm->{_menuitem_large_reopen}->set_sensitive(FALSE);
			return $menu_programs;
		}

		#get applications
		my $mime_type = $session_screens{$key}->{'mime_type'};

		# apps is a list of GAppInfo
		# https://developer.gnome.org/gio/stable/GAppInfo.html
		my $apps = Glib::IO::AppInfo::get_recommended_for_type($mime_type);

		# $apps is undefined if Glib::IO::AppInfo::get_recommended_for_type fails
		unless (defined $apps) {
			$sm->{_menuitem_reopen}->set_sensitive(FALSE);
			$sm->{_menuitem_large_reopen}->set_sensitive(FALSE);
			return $menu_programs;
		}

		#no apps determined!
		unless (scalar @$apps) {
			$sm->{_menuitem_reopen}->set_sensitive(FALSE);
			$sm->{_menuitem_large_reopen}->set_sensitive(FALSE);
			return $menu_programs;
		}

		#create menu items
		foreach my $app (@$apps) {

			#ignore Shutter's desktop entry
			next if $app->get_display_name =~ /shutter/i;

			# $app->{'name'} = $shf->utf8_decode( $app->{'name'} );

			#FIXME
			#we simply cut the kde* / kde4* substring here
			#is it possible to get the wrong app if there
			#is the kde3 and the kde4 version of an app installed?
			#
			#I think so ;-)
			# $app->{'id'} =~ s/^(kde4|kde)-//g;

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
						fct_open_with_program($app, $app->get_display_name);
					});
			}
		}

		#menu does not contain any item
		unless ($menu_programs->get_children) {
			$sm->{_menuitem_reopen}->set_sensitive(FALSE);
			$sm->{_menuitem_large_reopen}->set_sensitive(FALSE);
		}

		$menu_programs->show_all;
		return $menu_programs;
	}

	sub fct_ret_tray_menu {

		my $traytheme = $sc->get_theme;

		my $menu_tray = Gtk3::Menu->new();

		#selection
		my $menuitem_select = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Selection'));
		$menuitem_select->set_sensitive($x11_supported);
		eval {
			my $ccursor_pb = Gtk3::Gdk::Cursor::new('left_ptr')->get_image->scale_simple($shf->icon_size('menu'), 'bilinear');
			$menuitem_select->set_image(Gtk3::Image->new_from_pixbuf($ccursor_pb));
		};
		if ($@) {
			if ($traytheme->has_icon('applications-accessories')) {
				$menuitem_select->set_image(Gtk3::Image->new_from_icon_name('applications-accessories', 'menu'));
			} else {
				$menuitem_select->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/selection.svg", $shf->icon_size('menu'))));
			}
		}
		$menuitem_select->signal_connect(
			activate => \&evt_take_screenshot,
			'tray_select'
		);

		#full screen
		my $menuitem_full = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Desktop'));
		if ($traytheme->has_icon('user-desktop')) {
			$menuitem_full->set_image(Gtk3::Image->new_from_icon_name('user-desktop', 'menu'));
		} elsif ($traytheme->has_icon('desktop')) {
			$menuitem_full->set_image(Gtk3::Image->new_from_icon_name('desktop', 'menu'));
		} else {
			$menuitem_full->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/desktop.svg", $shf->icon_size('menu'))));
		}
		$menuitem_full->signal_connect(
			activate => \&evt_take_screenshot,
			'tray_full'
		);

		#~ #awindow
		#~ my $menuitem_awindow = Gtk3::ImageMenuItem->new_with_mnemonic( $d->get('_Active Window') );
		#~ if($traytheme->has_icon('preferences-system-windows')){
		#~ $menuitem_awindow->set_image( Gtk3::Image->new_from_icon_name( 'preferences-system-windows', 'menu' ) );
		#~ }else{
		#~ $menuitem_awindow->set_image(
		#~ Gtk3::Image->new_from_pixbuf(
		#~ $lp->load( "$shutter_root/share/shutter/resources/icons/sel_window_active.svg", $shf->icon_size('menu') )
		#~ )
		#~ );
		#~ }
		#~ $menuitem_awindow->signal_connect(
		#~ activate => \&evt_take_screenshot,
		#~ 'tray_awindow'
		#~ );

		#window
		my $menuitem_window = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Window _under Cursor'));
		$menuitem_window->set_sensitive($x11_supported);
		if ($traytheme->has_icon('preferences-system-windows')) {
			$menuitem_window->set_image(Gtk3::Image->new_from_icon_name('preferences-system-windows', 'menu'));
		} else {
			$menuitem_window->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/sel_window.svg", $shf->icon_size('menu'))));
		}
		$menuitem_window->signal_connect(
			activate => \&evt_take_screenshot,
			'tray_window'
		);

		#window list
		my $menuitem_window_list = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Select W_indow'));
		$menuitem_window_list->set_sensitive($x11_supported);
		if ($traytheme->has_icon('preferences-system-windows')) {
			$menuitem_window_list->set_image(Gtk3::Image->new_from_icon_name('preferences-system-windows', 'menu'));
		} else {
			$menuitem_window_list->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/sel_window.svg", $shf->icon_size('menu'))));
		}
		$menuitem_window_list->set_name('windowlist');
		$menuitem_window_list->set_submenu(fct_ret_window_menu());

		#section
		# No sections for now: https://github.com/shutter-project/shutter/issues/25
		#my $menuitem_window_sect = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Se_ction'));
		#if ($traytheme->has_icon('gdm-xnest')) {
		#	$menuitem_window_sect->set_image(Gtk3::Image->new_from_icon_name('gdm-xnest', 'menu'));
		#} else {
		#	$menuitem_window_sect->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/sel_window_section.svg", $shf->icon_size('menu'))));
		#}
		#$menuitem_window_sect->signal_connect(
		#	activate => \&evt_take_screenshot,
		#	'tray_section'
		#);

		#menu
		my $menuitem_window_menu = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Menu'));
		$menuitem_window_menu->set_sensitive($x11_supported);
		if ($traytheme->has_icon('alacarte')) {
			$menuitem_window_menu->set_image(Gtk3::Image->new_from_icon_name('alacarte', 'menu'));
		} else {
			$menuitem_window_menu->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/sel_window_menu.svg", $shf->icon_size('menu'))));
		}
		$menuitem_window_menu->signal_connect(
			activate => \&evt_take_screenshot,
			'tray_menu'
		);

		#tooltip
		my $menuitem_window_tooltip = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Tooltip'));
		$menuitem_window_tooltip->set_sensitive($x11_supported);
		if ($traytheme->has_icon('help-faq')) {
			$menuitem_window_tooltip->set_image(Gtk3::Image->new_from_icon_name('help-faq', 'menu'));
		} else {
			$menuitem_window_tooltip->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/sel_window_tooltip.svg", $shf->icon_size('menu'))));
		}
		$menuitem_window_tooltip->signal_connect(
			activate => \&evt_take_screenshot,
			'tray_tooltip'
		);

		#web
		my $menuitem_web = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Web'));
		$menuitem_web->set_sensitive($gnome_web_photo);
		if ($traytheme->has_icon('web-browser')) {
			$menuitem_web->set_image(Gtk3::Image->new_from_icon_name('web-browser', 'menu'));
		} else {
			$menuitem_web->set_image(Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/web_image.svg", $shf->icon_size('menu'))));
		}
		$menuitem_web->signal_connect(
			activate => \&evt_take_screenshot,
			'tray_web'
		);

		#show main window
		my $menuitem_show_window = Gtk3::MenuItem->new_with_mnemonic($d->get('S_how main window'));
		$menuitem_show_window->signal_connect('activate', sub { $is_hidden = TRUE; fct_control_main_window('show'); });
		$menuitem_show_window->set_name('show_window');
		$menuitem_show_window->set_sensitive(TRUE);

		#redo last screenshot
		my $menuitem_redoshot = Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Redo last screenshot'));
		$menuitem_redoshot->set_image(Gtk3::Image->new_from_stock('gtk-refresh', 'menu'));
		$menuitem_redoshot->signal_connect('activate', \&evt_take_screenshot, 'redoshot');
		$menuitem_redoshot->set_name('redoshot');
		$menuitem_redoshot->set_sensitive(FALSE);

		#preferences
		my $menuitem_settings = Gtk3::ImageMenuItem->new_from_stock('gtk-preferences');
		$menuitem_settings->signal_connect("activate", \&evt_show_settings);

		#quick profile selector
		my $menuitem_quicks = Gtk3::MenuItem->new_with_mnemonic($d->get('_Quick profile select'));

		#set name to identify the item later - we use this in really rare cases
		$menuitem_quicks->set_name('quicks');
		$menuitem_quicks->set_sensitive(FALSE);

		#info
		my $menuitem_info = Gtk3::ImageMenuItem->new_from_stock('gtk-about');
		$menuitem_info->signal_connect("activate", \&evt_about);

		#quit
		my $menuitem_quit = Gtk3::ImageMenuItem->new_from_stock('gtk-quit');
		$menuitem_quit->signal_connect("activate", \&evt_delete_window, 'quit');

		$menu_tray->append($menuitem_show_window);
		$menu_tray->append(Gtk3::SeparatorMenuItem->new);
		$menu_tray->append($menuitem_redoshot);
		$menu_tray->append(Gtk3::SeparatorMenuItem->new);
		$menu_tray->append($menuitem_select);

		#~ $menu_tray->append( Gtk3::SeparatorMenuItem->new );
		$menu_tray->append($menuitem_full);

		#~ $menu_tray->append( Gtk3::SeparatorMenuItem->new );
		#~ $menu_tray->append($menuitem_awindow);
		$menu_tray->append($menuitem_window);
		$menu_tray->append($menuitem_window_list);
		# No sections for now: https://github.com/shutter-project/shutter/issues/25
		#$menu_tray->append($menuitem_window_sect);
		$menu_tray->append($menuitem_window_menu);
		$menu_tray->append($menuitem_window_tooltip);

		#~ $menu_tray->append( Gtk3::SeparatorMenuItem->new );
		$menu_tray->append($menuitem_web);
		$menu_tray->append(Gtk3::SeparatorMenuItem->new);
		$menu_tray->append($menuitem_settings);
		$menu_tray->append($menuitem_quicks);
		$menu_tray->append(Gtk3::SeparatorMenuItem->new);
		$menu_tray->append($menuitem_info);
		$menu_tray->append($menuitem_quit);
		$menu_tray->show_all;

		return $menu_tray;
	}


1;
