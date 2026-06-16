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

package Shutter::App::Handlers::Menu_Ret;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_get_last_capture {

		#~ #determine last capture and return the relevant key
		#~ my $last_capture_tstamp = 0;
		#~ my $last_capture_key 	= 0;
		#~ foreach my $key (keys %session_screens){
		#~ if(exists $session_screens{$key}->{'history'} && defined $session_screens{$key}->{'history'}){
		#~ if(exists $session_screens{$key}->{'history_timestamp'} && defined $session_screens{$key}->{'history_timestamp'}){
		#~ if($session_screens{$key}->{'history_timestamp'} > $last_capture_tstamp){
		#~ $last_capture_tstamp = $session_screens{$key}->{'history_timestamp'};
		#~ $last_capture_key = $key;
		#~ }
		#~ }
		#~ }
		#~ }
		#~ return $last_capture_key;
		if (exists $session_start_screen{'first_page'}->{'history'}
			&& defined $session_start_screen{'first_page'}->{'history'})
		{
			return $session_start_screen{'first_page'}->{'history'};
		}
		return FALSE;
	}

	sub fct_get_program_model {
		my $model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::Scalar');

		#add Shutter's built-in editor to the list
		if ($goocanvas) {
			my $icon_pixbuf = undef;
			my $icon        = 'shutter';
			if ($sc->get_theme->has_icon($icon)) {
				my ($iw, $ih) = $shf->icon_size('menu');
				eval { $icon_pixbuf = $sc->get_theme->load_icon($icon, $ih, 'generic-fallback'); };
				if ($@) {
					print "\nWARNING: Could not load icon $icon: $@\n";
					$icon_pixbuf = undef;
				}
			}
			$model->set($model->append, 0, $icon_pixbuf, 1, $d->get("Built-in Editor"), 2, 'shutter-built-in');
		}

		#get applications
		my $apps = Glib::IO::AppInfo::get_recommended_for_type('image/png');

		# $apps is undefined if Glib::IO::AppInfo::get_recommended_for_type fails
		unless (defined $apps) {
			return $model;
		}

		#no apps determined!
		unless (scalar @$apps) {
			return $model;
		}

		#create menu items
		foreach my $app (@$apps) {

			#ignore Shutter's desktop entry
			next if $app->get_id eq 'shutter.desktop';

			$app->{'name'} = $shf->utf8_decode($app->get_display_name);

			#get icon
			my $icon_pixbuf = undef;
			my $icon        = $app->get_icon;
			if ($icon) {
				my ($iw, $ih) = $shf->icon_size('menu');
				eval {
					my $icon_info = $sc->get_theme->choose_icon($icon->get_names, $ih, []);
					$icon_pixbuf = $icon_info->load_icon if $icon_info;
				};
				if ($@) {
					print "\nWARNING: Could not load icon for ", $app->{'name'}, ": $@\n";
					$icon_pixbuf = undef;
				}
			}
			$model->set($model->append, 0, $icon_pixbuf, 1, $app->{'name'}, 2, $app);
		}

		return $model;
	}

	sub fct_ret_profile_menu {
		my $combobox_settings_profiles = shift;
		my $current_profiles_ref       = shift;
		my $menu_profile               = shift;

		$menu_profile = Gtk3::Menu->new unless defined $menu_profile;
		foreach my $child ($menu_profile->get_children) {
			$child->destroy;
		}

		my $group   = undef;
		my $counter = 0;
		foreach my $profile (@{$current_profiles_ref}) {
			my $profile_item = Gtk3::RadioMenuItem->new_with_label($group, $profile);
			$profile_item->set_active(TRUE)
				if $profile eq $combobox_settings_profiles->get_active_text;
			$profile_item->signal_connect(
				'toggled' => sub {
					my $widget = shift;
					return TRUE unless $widget->get_active;

					for (my $i = 0 ; $i < scalar @{$current_profiles_ref} ; $i++) {
						$combobox_settings_profiles->set_active($i);
						$current_profile_indx = $i;
						if ($profile eq $combobox_settings_profiles->get_active_text) {
							evt_apply_profile($widget, $combobox_settings_profiles, $current_profiles_ref);
							last;
						}
					}
				});
			$group = $profile_item unless $group;
			$menu_profile->append($profile_item);
			$counter++;
		}

		$menu_profile->show_all;
		return $menu_profile;
	}

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

	sub fct_ret_upload_links_menu {
		my $key        = shift;
		my $menu_links = shift;

		my $traytheme = $sc->get_theme;

		if (defined $menu_links) {
			foreach my $child ($menu_links->get_children) {
				$child->destroy;
			}
		} else {
			$menu_links = Gtk3::Menu->new;
		}

		my $nmenu_entries = 0;

		if (defined $key && exists $session_screens{$key}->{'links'}) {
			foreach my $hoster (keys %{$session_screens{$key}->{'links'}}) {

				#no longer valid
				next
					unless defined $session_screens{$key}->{'links'}->{$hoster};
				next
					unless scalar keys %{$session_screens{$key}->{'links'}->{$hoster}} > 0;
				next
					unless defined $session_screens{$key}->{'links'}->{$hoster}->{'menuentry'};

				#create menu entry
				my $menuitem_hoster = Gtk3::ImageMenuItem->new_with_mnemonic($session_screens{$key}->{'links'}->{$hoster}->{'menuentry'});
				if (defined $session_screens{$key}->{'links'}->{$hoster}->{'menuimage'}) {
					if ($traytheme->has_icon($session_screens{$key}->{'links'}->{$hoster}->{'menuimage'})) {
						$menuitem_hoster->set_image(Gtk3::Image->new_from_icon_name($session_screens{$key}->{'links'}->{$hoster}->{'menuimage'}, 'menu'));
					}
				}

				#create submenu with urls
				my $menu_urls = Gtk3::Menu->new;
				foreach my $url (keys %{$session_screens{$key}->{'links'}->{$hoster}}) {
					next if $url eq 'menuimage';
					next if $url eq 'menuentry';
					next if $url eq 'pubfile';

					#create item
					my $menuitem_url = Gtk3::MenuItem->new_with_label($session_screens{$key}->{'links'}->{$hoster}->{$url});
					foreach my $child ($menuitem_url->get_children) {
						if ($child =~ m/Gtk3::AccelLabel/) {
							$child->set_ellipsize('middle');
							$child->set_width_chars(20);
							last;
						}
					}
					$menuitem_url->signal_connect(
						activate => sub {
							$clipboard->set_text($session_screens{$key}->{'links'}->{$hoster}->{$url});
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

	sub fct_ret_web_menu {

		my $menu_web = Gtk3::Menu->new;

		my $timeout0 = Gtk3::RadioMenuItem->new_with_label(undef, $d->get("Wait indefinitely"));
		my $timeout1 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d second", "Wait max %d seconds", 10), 10));
		my $timeout2 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d second", "Wait max %d seconds", 10), 30));
		my $timeout3 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d minute", "Wait max %d minutes", 1), 1));
		my $timeout4 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d minute", "Wait max %d minutes", 2), 2));

		$timeout0->set_name("timeout0");
		$timeout1->set_name("timeout10");
		$timeout2->set_name("timeout30");
		$timeout3->set_name("timeout60");
		$timeout4->set_name("timeout120");

		$timeout0->set_tooltip_text($d->get("Shutter will wait indefinitely for the screenshot to capture"));
		$timeout1->set_tooltip_text(
			sprintf(
				$d->nget(
					"Shutter will wait up to %d second for the screenshot to capture before aborting the process if it's taking too long",
					"Shutter will wait up to %d seconds for the screenshot to capture before aborting the process if it's taking too long",
					10
				),
				10
			));
		$timeout2->set_tooltip_text(
			sprintf(
				$d->nget(
					"Shutter will wait up to %d second for the screenshot to capture before aborting the process if it's taking too long",
					"Shutter will wait up to %d seconds for the screenshot to capture before aborting the process if it's taking too long",
					30
				),
				30
			));
		$timeout3->set_tooltip_text(
			sprintf(
				$d->nget(
					"Shutter will wait up to %d minute for the screenshot to capture before aborting the process if it's taking too long",
					"Shutter will wait up to %d minutes for the screenshot to capture before aborting the process if it's taking too long",
					1
				),
				1
			));
		$timeout4->set_tooltip_text(
			sprintf(
				$d->nget(
					"Shutter will wait up to %d minute for the screenshot to capture before aborting the process if it's taking too long",
					"Shutter will wait up to %d minutes for the screenshot to capture before aborting the process if it's taking too long",
					2
				),
				2
			));

		$timeout2->set_active(TRUE);
		$menu_web->append($timeout0);
		$menu_web->append($timeout1);
		$menu_web->append($timeout2);
		$menu_web->append($timeout3);
		$menu_web->append($timeout4);

		if (defined $settings_xml->{'general'}->{'web_timeout'}) {

			#determining timeout
			my @timeouts = $menu_web->get_children;
			my $timeout  = undef;
			foreach my $to (@timeouts) {
				$timeout = $to->get_name;
				$timeout =~ /([0-9]+)/;
				$timeout = $1;
				if ($settings_xml->{'general'}->{'web_timeout'} == $timeout) {
					$to->set_active(TRUE);
				}
			}
		}
		$menu_web->show_all;
		return $menu_web;
	}

	sub fct_ret_window_menu {

		my $menu_windows = Gtk3::Menu->new;
		return $menu_windows unless $wnck_screen;

		my $active_workspace = $wnck_screen->get_active_workspace;
		my $icontheme        = $sc->get_theme;

		#add item for active window
		my $active_window_item_image;
		if ($icontheme->has_icon('preferences-system-windows')) {
			$active_window_item_image = Gtk3::Image->new_from_icon_name('preferences-system-windows', 'menu');
		} else {
			$active_window_item_image = Gtk3::Image->new_from_pixbuf($lp->load("$shutter_root/share/shutter/resources/icons/sel_window_active.svg", $shf->icon_size('menu')));
		}

		my $active_window_item = Gtk3::ImageMenuItem->new_with_label($d->get("Active Window"));
		$active_window_item->set_image($active_window_item_image);
		$active_window_item->set('always_show_image' => TRUE);

		$active_window_item->set_tooltip_text($d->get("Capture the last active window"));

		$active_window_item->signal_connect(
			'activate' => \&evt_take_screenshot,
			'awindow'
		);

		$menu_windows->append($active_window_item);
		$menu_windows->append(Gtk3::SeparatorMenuItem->new);

		# Check if we can retrieve the list of stacked windows first, otherwise we will run into a crash, see issue 659
		
		unless ($wnck_screen->get_windows_stacked) {
			print "ERROR: The window list could not be retrieved and has been disabled, see https://github.com/shutter-project/shutter/issues/659";
			return $menu_windows;
		}

		#add all windows to menu to capture it directly

		foreach my $win (@{$wnck_screen->get_windows_stacked}) {
			if ($active_workspace && $win->is_on_workspace($active_workspace)) {
				my $win_name = $win->get_name;
				Encode::_utf8_on($win_name);
				my $window_item = Gtk3::ImageMenuItem->new_with_label($win_name);
				foreach my $child ($window_item->get_children) {
					if ($child =~ /Gtk3::AccelLabel/) {
						$child->set_width_chars(50);
						$child->set_ellipsize('middle');
						last;
					}
				}
				$window_item->set_image(Gtk3::Image->new_from_pixbuf($win->get_mini_icon));
				$window_item->set('always_show_image' => TRUE);
				$window_item->signal_connect(
					'activate' => \&evt_take_screenshot,
					"shutter_window_direct" . $win->get_xid
				);
				$menu_windows->append($window_item);
			}
		}

		$menu_windows->show_all;
		return $menu_windows;
	}

	sub fct_ret_workspace_menu {
		my $init = shift;

		my $menu_wrksp = Gtk3::Menu->new;
		unless ($x11_supported) {
			return $menu_wrksp;
		}

		my $wnck_screen = Wnck::Screen::get_default();
		unless ($wnck_screen) {
			$current_monitor_active = Gtk3::CheckMenuItem->new_with_label($d->get("Limit to current monitor"));
			return $menu_wrksp;
		}
		$wnck_screen->force_update();

		#we determine the wm name but on older
		#version of libwnck (or the bindings)
		#the needed method is not available
		#in this case we use gdk to do it
		#
		#this leads to a known problem when switching
		#the wm => wm_name will still remain the old one
		#but it doesn't work on gtk3
		my $wm_name;
		if ($wnck_screen->can('get_window_manager_name')) {
			$wm_name = $wnck_screen->get_window_manager_name;
		}

		my $active_workspace = $wnck_screen->get_active_workspace;

		#we need to handle different window managers here because there are some different models related
		#to workspaces and viewports
		#	compiz uses "multiple workspaces" - "multiple viewports" model for example
		#	default gnome wm metacity simply uses multiple workspaces
		#we will try to handle them by name
		my @workspaces = ();
		for (my $wcount = 0 ; $wcount < $wnck_screen->get_workspace_count ; $wcount++) {
			push(@workspaces, $wnck_screen->get_workspace($wcount));
		}

		foreach my $space (@workspaces) {
			next unless defined $space;

			#compiz
			print "Current window manager: ", $wm_name, "\n" if $sc->get_debug;
			if ($wm_name =~ /compiz/i) {

				#calculate viewports with size of workspace
				my $vpx = $space->get_viewport_x;
				my $vpy = $space->get_viewport_y;

				my $n_viewports_column = int($space->get_width / $wnck_screen->get_width);
				my $n_viewports_rows   = int($space->get_height / $wnck_screen->get_height);

				#rows
				for (my $j = 0 ; $j < $n_viewports_rows ; $j++) {

					#columns
					for (my $i = 0 ; $i < $n_viewports_column ; $i++) {
						my @vp      = ($i * $wnck_screen->get_width, $j * $wnck_screen->get_height);
						my $vp_name = "$wm_name x: $i y: $j";

						print "shutter_wrksp_direct_compiz" . $vp[0] . "x" . $vp[1] . "\n"
							if $sc->get_debug;

						my $vp_item = Gtk3::MenuItem->new_with_label(ucfirst $vp_name);
						$vp_item->signal_connect(
							'activate' => \&evt_take_screenshot,
							"shutter_wrksp_direct_compiz" . $vp[0] . "x" . $vp[1]);
						$menu_wrksp->append($vp_item);

						#do not offer current viewport
						if ($vp[0] == $vpx && $vp[1] == $vpy) {
							$vp_item->set_sensitive(FALSE);
						}
					}    #columns
				}    #rows

				#all other wm manager like metacity etc.
				#we could add more of them here if needed
			} else {

				my $wrkspace_item = Gtk3::MenuItem->new_with_label($space->get_name);
				$wrkspace_item->signal_connect(
					'activate' => \&evt_take_screenshot,
					"shutter_wrksp_direct" . $space->get_number
				);
				$menu_wrksp->append($wrkspace_item);

				if (   $active_workspace
					&& $active_workspace->get_number == $space->get_number)
				{
					$wrkspace_item->set_sensitive(FALSE);
				}

			}
		}

		#entry for capturing all workspaces
		$menu_wrksp->append(Gtk3::SeparatorMenuItem->new);

		my $allwspaces_item = Gtk3::MenuItem->new_with_label($d->get("Capture All Workspaces"));
		$allwspaces_item->signal_connect(
			'activate' => \&evt_take_screenshot,
			"shutter_wrksp_direct" . 'all'
		);
		$menu_wrksp->append($allwspaces_item);

		#monitor flag
		my $n_mons = Gtk3::Gdk::Screen::get_default->get_n_monitors;

		#use only current monitor
		$menu_wrksp->append(Gtk3::SeparatorMenuItem->new);
		if ($init) {
			$current_monitor_active = Gtk3::CheckMenuItem->new_with_label($d->get("Limit to current monitor"));
			if (defined $settings_xml->{'general'}->{'current_monitor_active'}) {
				$current_monitor_active->set_active($settings_xml->{'general'}->{'current_monitor_active'});
			} else {
				$current_monitor_active->set_active(FALSE);
			}
			$menu_wrksp->append($current_monitor_active);
		} else {
			$current_monitor_active->reparent($menu_wrksp);
		}

		$current_monitor_active->set_tooltip_text(
			sprintf(
				$d->nget(
					"This option is only useful when you are running a multi-monitor system (%d monitor detected).\nEnable it to capture only the current monitor.",
					"This option is only useful when you are running a multi-monitor system (%d monitors detected).\nEnable it to capture only the current monitor.",
					$n_mons
				),
				$n_mons
			));
		if ($n_mons > 1) {
			$current_monitor_active->set_sensitive(TRUE);
		} else {
			$current_monitor_active->set_active(FALSE);
			$current_monitor_active->set_sensitive(FALSE);
		}

		$menu_wrksp->show_all();
		return $menu_wrksp;
	}


1;
