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

package Shutter::App::Handlers::Workflow;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_control_wm_settings {
		my $mode          = shift;
		my $restore_value = shift;

		#compiz via dbus
		my $bus    = undef;
		my $compiz = undef;
		my $fpl    = undef;

		#disable focus_prevention
		my $curr_value = -1;

		#disable focus prevention when using compiz
		eval {
			$bus = Net::DBus->find;

			#Get a handle to the compiz service
			$compiz = $bus->get_service("org.freedesktop.compiz");

			#Get the relevant object
			$fpl = $compiz->get_object("/org/freedesktop/compiz/core/screen0/focus_prevention_level", "org.freedesktop.compiz");
		};
		if ($@) {
			warn "INFO: DBus connection to org.freedesktop.compiz failed --> skipping compiz related tasks\n\n";
			warn $@ . "\n\n";
			return $curr_value;
		}

		if (defined $fpl && $fpl) {
			eval {
				if ($mode eq 'start') {

					#save and return current value
					if (defined $fpl && $fpl) {
						$curr_value = $fpl->get;
					}
					if (defined $fpl && $fpl && $fpl->get != 0) {
						$fpl->set(0);
					}

					#re-enable focus prevention -> restore value
				} elsif ($mode eq 'stop') {
					if (defined $fpl && $fpl && defined $restore_value) {
						$fpl->set($restore_value);
					} elsif (defined $fpl && $fpl) {
						$fpl->set(1);
					}
				}
			};
			if ($@) {
				warn "ERROR: Unable to set/get focus_level_prevention --> skipping compiz related tasks\n\n";
				warn $@ . "\n\n";
			}
		}

		return $curr_value;
	}

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

	sub fct_init_debug_output {

		print "\nINFO: gathering system information...";
		print "\n";
		print "\n";
		print "Shutter ";
		print SHUTTER_VERSION;
		print ' ';
		print SHUTTER_REV;
		print "\n";

		#kernel info
		if (can_run('uname')) {
			print `uname -a`, "\n";
		}

		eval {
			open my $fh, '<', '/etc/os-release' or die;
			my %map = map {
				chomp;
				my ($key, $value) = split /=/, $_, 2;
				$value =~ s/^(['"])(.*)\1$/$2/;
				($key, $value)
			} <$fh>;
			local $, = ' ';
			say grep { $_ } map { $map{$_} } qw/NAME VERSION_ID BUILD_ID/;
		};
		say "Cannot open /etc/os-release" if $@;

		printf "Glib %s \n", $Glib::VERSION;
		printf "Gtk3 %s \n", $Gtk3::VERSION;
		print "\n";

		# The version info stuff appeared in 1.040.
		print "Glib built for " . join(".", Glib->GET_VERSION_INFO) . ", running with " . join(".", Glib::major_version(), Glib::minor_version(), Glib::micro_version()) . "\n"
			if $Glib::VERSION >= 1.040;
		print "Gtk3 built for " . join(".", Gtk3->GET_VERSION_INFO) . ", running with " . join(".", Gtk3::major_version(), Gtk3::minor_version(), Gtk3::micro_version()) . "\n"
			if $Gtk3::VERSION >= 1.040;
		print "\n";

		return TRUE;
	}

	sub fct_init_depend {

		#imagemagick/perlmagick
		unless (can_run('convert')) {
			# warn "WARNING: imagemagick is missing --> color reduction features disabled!\n\n";
		}

		#gnome-web-photo
		unless (can_run('gnome-web-photo')) {
			# warn "WARNING: gnome-web-photo is missing --> screenshots of websites will be disabled!\n\n";
			$gnome_web_photo = FALSE;
		}

		#nautilus-sendto
		unless (can_run('nautilus-sendto')) {
			$nautilus_sendto = FALSE;
		}

		#goocanvas
		eval { require GooCanvas2; require GooCanvas2::CairoTypes; };
		if ($@) {
			# warn "WARNING: Goo::Canvas/libgoo-canvas-perl is missing --> drawing tool will be disabled!\n\n";
			$goocanvas = FALSE;
		}

		#libimage-exiftool-perl
		eval { require Image::ExifTool };
		if ($@) {
			# warn "WARNING: Image::ExifTool is missing --> writing Exif information will be disabled!\n\n";
			$exiftool = FALSE;
		}

		#dev-libs/libappindicator[introspection]
		eval {
			Glib::Object::Introspection->setup(
				basename => 'AppIndicator3',
				version  => '0.1',
				package  => 'AppIndicator',
			);
		};
		if ($@) {
			eval {
				Glib::Object::Introspection->setup(
					basename => 'AyatanaAppIndicator3',
					version  => '0.1',
					package  => 'AppIndicator',
				);
			};
			if ($@) {
				# warn "WARNING: AppIndicator is missing --> there will be no icon showing up in the status bar when running Unity!\n\n";
				$appindicator = FALSE;
			}
		}

		return TRUE;
	}

	sub fct_init_unsaved_files {

		#delete all files in this folder
		#except the ones that are in the current session
		my @unsaved_files = bsd_glob(Shutter::App::Directories::get_cache_dir() . "/*");
		foreach my $unsaved_file (@unsaved_files) {
			utf8::decode $unsaved_file;
			print $unsaved_file, " checking \n" if $sc->get_debug;
			unless (fct_get_key_by_filename($unsaved_file)) {
				print $unsaved_file, " deleted \n" if $sc->get_debug;
				unlink $unsaved_file;
			}
		}
	}

	sub fct_integrate_screenshot_in_notebook {
		my ($giofile, $pixbuf, $history, $count) = @_;

		#check parameters
		return FALSE unless $giofile;

		unless ($giofile->query_exists) {
			fct_show_status_message(1, $giofile->get_path . " " . $d->get("not found"));
			return FALSE;
		}

		#check mime type
		my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $giofile->get_path);
		$mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;    #FIXME
		if ($mime_type =~ m/(pdf|ps|svg)/ig) {

			#not a supported mime type
			#~ my $response = $sd->dlg_error_message(
			#~ sprintf ( $d->get(  "Error while opening image %s." ), "'" . $giofile->get_path . "'" ) ,
			#~ $d->get( "There was an error opening the image." ),
			#~ undef, undef, undef,
			#~ undef, undef, undef,
			#~ $d->get( "MimeType not supported." )
			#~ );
			#~ fct_show_status_message( 1, $giofile->get_path . " " . $d->get("not supported") );
			return FALSE;
		}

		#add to recentmanager
		Gtk3::RecentManager::get_default->add_item($giofile->get_path);

		#FIXME
		my $num_files = $session_start_screen{'first_page'}->{'num_session_files'};

		#append a page to notebook using with label == filename
		my $fname = $shf->utf8_decode(unescape_string_for_display($giofile->get_basename));
		my $key   = 0;
		my $indx  = 0;
		if (defined $num_files && $num_files > 0) {
			if (defined $history && $history->get_history) {
				$indx = $num_files + 1;

				#update it (e.g. when taking more than one screenshot when still loading session)
				$session_start_screen{'first_page'}->{'num_session_files'} = $indx;
			} elsif (defined $count) {
				$indx = $count;
			} else {
				$indx = $num_files + 1;
				while ($indx < fct_get_latest_tab_key()) {
					$indx++;
				}

				#update it (e.g. when taking more than one screenshot when still loading session)
				$session_start_screen{'first_page'}->{'num_session_files'} = $indx;
			}
		} else {
			$indx = fct_get_latest_tab_key();
		}

		$key = "[" . $indx . "] - $fname";

		#~ print $key, "-", $giofile->to_string, "\n";

		#store the history object
		if (defined $history && $history->get_history) {
			$session_screens{$key}->{'history'}              = $history;
			$session_start_screen{'first_page'}->{'history'} = $history;
			$session_screens{$key}->{'history_timestamp'}    = time;
		}

		#setup tab label (thumb, preview etc.)
		my $hbox_tab_label = Gtk3::HBox->new(FALSE, 0);
		my $close_icon     = Gtk3::Image->new_from_icon_name('window-close', 'menu');

		$session_screens{$key}->{'tab_icon'} = Gtk3::Image->new;

		#setup tab label
		my $tab_close_button = Gtk3::Button->new;
		$tab_close_button->set_relief('none');
		$tab_close_button->set_image($close_icon);
		$tab_close_button->set_name('tab-close-button');

		my $tab_label = Gtk3::Label->new($key);
		$tab_label->set_ellipsize('middle');
		$tab_label->set_width_chars(20);
		$hbox_tab_label->pack_start($session_screens{$key}->{'tab_icon'}, FALSE, FALSE, 1);
		$hbox_tab_label->pack_start($tab_label,                           TRUE,  TRUE,  1);
		$hbox_tab_label->pack_start(Gtk3::HBox->new,                      TRUE,  TRUE,  1);
		$hbox_tab_label->pack_start($tab_close_button,                    FALSE, FALSE, 1);
		$hbox_tab_label->show_all;

		#and append page with label == key
		my $new_index = 0;
		if (defined $num_files && $num_files > 0) {
			if (defined $history && $history->get_history) {
				$new_index = $notebook->insert_page(fct_create_tab($key, FALSE), $hbox_tab_label, $indx);
			} elsif (defined $count) {
				$new_index = $notebook->insert_page(fct_create_tab($key, FALSE), $hbox_tab_label, $count);
			} else {
				$new_index = $notebook->insert_page(fct_create_tab($key, FALSE), $hbox_tab_label, $indx);
			}
		} else {
			$new_index = $notebook->append_page(fct_create_tab($key, FALSE), $hbox_tab_label);
		}
		$session_screens{$key}->{'tab_indx'}       = $indx;
		$session_screens{$key}->{'tab_label'}      = $tab_label;
		$session_screens{$key}->{'hbox_tab_label'} = $hbox_tab_label;
		$session_screens{$key}->{'tab_child'}      = $notebook->get_nth_page($new_index);
		$tab_close_button->signal_connect(clicked => sub { fct_remove($key); });

		#this value is undefined when all files are loaded
		#in this case we switch to any new image
		unless (defined $session_start_screen{'first_page'}->{'num_session_files'}) {
			$notebook->set_current_page($new_index);
		} else {

			#if there is a history we recently took a screenshot
			#switch to that page
			#(even though the session is still loading)
			if (defined $history && $history->get_history) {
				$notebook->set_current_page($new_index);
			}
		}

		if (fct_update_tab($key, $pixbuf, $giofile, undef, undef, TRUE)) {

			#setup a filemonitor, so we get noticed if the file changed
			fct_add_file_monitor($key);
		}

		return $key;
	}

	sub fct_load_settings {
		my ($data, $profilename) = @_;

		#settings file
		my $settingsfile = "$ENV{ HOME }/.shutter/settings.xml";
		$settingsfile = "$ENV{ HOME }/.shutter/profiles/$profilename.xml"
			if (defined $profilename);

		my $settings_xml;
		if ($shf->file_exists($settingsfile)) {
			eval {
				$settings_xml = XMLin(IO::File->new($settingsfile));

				if ($data eq 'profile_load') {
					$combobox_type->set_active($settings_xml->{'general'}->{'filetype'});

					#main
					$scale->set_value($settings_xml->{'general'}->{'quality'});
					utf8::decode $settings_xml->{'general'}->{'filename'};
					$filename->set_text($settings_xml->{'general'}->{'filename'});

					utf8::decode $settings_xml->{'general'}->{'folder'};
					$saveDir_button->set_filename($settings_xml->{'general'}->{'folder'});

					$save_auto_active->set_active($settings_xml->{'general'}->{'save_auto'});
					$save_ask_active->set_active($settings_xml->{'general'}->{'save_ask'});
					$save_no_active->set_active($settings_xml->{'general'}->{'save_no'});

					$image_autocopy_active->set_active($settings_xml->{'general'}->{'image_autocopy'});
					$fname_autocopy_active->set_active($settings_xml->{'general'}->{'fname_autocopy'});
					$no_autocopy_active->set_active($settings_xml->{'general'}->{'no_autocopy'});

					$cursor_active->set_active($settings_xml->{'general'}->{'cursor'});
					$delay->set_value($settings_xml->{'general'}->{'delay'});

					$drawing_tool_light_icons_active->set_active($settings_xml->{'general'}->{'drawing_tool_light_icons'});
					$drawing_tool_dark_icons_active->set_active($settings_xml->{'general'}->{'drawing_tool_dark_icons'});
					$drawing_tool_auto_icons_active->set_active($settings_xml->{'general'}->{'drawing_tool_auto_icons'});

					#FIXME
					#this is a dirty hack to force the setting to be enabled in session tab
					#at the moment i simply dont know why the filechooser "caches" the old value
					# => weird...
					$settings_xml->{'general'}->{'folder_force'} = TRUE;

					#wrksp -> submenu
					$current_monitor_active->set_active($settings_xml->{'general'}->{'current_monitor_active'});

					#determining timeout
					my $web_menu = $st->{_web}->get_menu;
					if (defined $web_menu) {
						my @timeouts = $web_menu->get_children;
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

					#action settings
					my $model = $progname->get_model;
					utf8::decode $settings_xml->{'general'}->{'prog'};
					$model->foreach(\&fct_iter_programs, $settings_xml->{'general'}->{'prog'});
					$progname_active->set_active($settings_xml->{'general'}->{'prog_active'});

					$im_colors_active->set_active($settings_xml->{'general'}->{'im_colors_active'});
					$combobox_im_colors->set_active($settings_xml->{'general'}->{'im_colors'});

					$thumbnail->set_value($settings_xml->{'general'}->{'thumbnail'});
					$thumbnail_active->set_active($settings_xml->{'general'}->{'thumbnail_active'});

					$bordereffect->set_value($settings_xml->{'general'}->{'bordereffect'});
					$bordereffect_active->set_active($settings_xml->{'general'}->{'bordereffect_active'});
					if (defined $settings_xml->{'general'}->{'bordereffect_col'}) {
						$bordereffect_cbtn->set_rgba(Gtk3::Gdk::RGBA::parse($settings_xml->{'general'}->{'bordereffect_col'}));
					}

					#advanced settings
					$zoom_active->set_active($settings_xml->{'general'}->{'zoom_active'});
					$as_help_active->set_active($settings_xml->{'general'}->{'as_help_active'});
					$as_confirmation_necessary->set_active($settings_xml->{'general'}->{'as_confirmation_necessary'});

					$asel_size3->set_value($settings_xml->{'general'}->{'asel_x'});
					$asel_size4->set_value($settings_xml->{'general'}->{'asel_y'});
					$asel_size1->set_value($settings_xml->{'general'}->{'asel_w'});
					$asel_size2->set_value($settings_xml->{'general'}->{'asel_h'});

					$border_active->set_active($settings_xml->{'general'}->{'border'});

					$winresize_active->set_active($settings_xml->{'general'}->{'winresize_active'});
					$winresize_w->set_value($settings_xml->{'general'}->{'winresize_w'});
					$winresize_h->set_value($settings_xml->{'general'}->{'winresize_h'});

					$autoshape_active->set_active($settings_xml->{'general'}->{'autoshape_active'});
					$visible_windows_active->set_active($settings_xml->{'general'}->{'visible_windows'});
					$menu_waround_active->set_active($settings_xml->{'general'}->{'menu_waround'});
					$menu_delay->set_value($settings_xml->{'general'}->{'menu_delay'});
					$combobox_web_width->set_active($settings_xml->{'general'}->{'web_width'});

					#imageview
					$trans_check->set_active($settings_xml->{'general'}->{'trans_check'});
					$trans_custom->set_active($settings_xml->{'general'}->{'trans_custom'});
					if (defined $settings_xml->{'general'}->{'trans_custom_col'}) {
						$trans_custom_btn->set_rgba(Gtk3::Gdk::RGBA::parse($settings_xml->{'general'}->{'trans_custom_col'}));
					}
					$trans_backg->set_active($settings_xml->{'general'}->{'trans_backg'});

					$session_asc->set_active($settings_xml->{'general'}->{'session_asc'});
					$session_asc_combo->set_active($settings_xml->{'general'}->{'session_asc_combo'});
					$session_desc->set_active($settings_xml->{'general'}->{'session_desc'});
					$session_desc_combo->set_active($settings_xml->{'general'}->{'session_desc_combo'});

					#behavior
					$fs_active->set_active($settings_xml->{'general'}->{'autofs'});
					$fs_min_active->set_active($settings_xml->{'general'}->{'autofs_min'});
					$fs_nonot_active->set_active($settings_xml->{'general'}->{'autofs_not'});
					$hide_active->set_active($settings_xml->{'general'}->{'autohide'});
					$hide_time->set_value($settings_xml->{'general'}->{'autohide_time'});
					$present_after_active->set_active($settings_xml->{'general'}->{'present_after'});
					$close_at_close_active->set_active($settings_xml->{'general'}->{'close_at_close'});
					$notify_after_active->set_active($settings_xml->{'general'}->{'notify_after'});
					$notify_timeout_active->set_active($settings_xml->{'general'}->{'notify_timeout'});
					$notify_ptimeout_active->set_active($settings_xml->{'general'}->{'notify_ptimeout'});
					$combobox_ns->set_active($settings_xml->{'general'}->{'notify_agent'});
					$ask_on_delete_active->set_active($settings_xml->{'general'}->{'ask_on_delete'});
					$delete_on_close_active->set_active($settings_xml->{'general'}->{'delete_on_close'});
					$ask_on_fs_delete_active->set_active($settings_xml->{'general'}->{'ask_on_fs_delete'});

					#ftp_upload
					utf8::decode $settings_xml->{'general'}->{'ftp_uri'};
					utf8::decode $settings_xml->{'general'}->{'ftp_mode'};
					utf8::decode $settings_xml->{'general'}->{'ftp_username'};
					utf8::decode $settings_xml->{'general'}->{'ftp_password'};
					utf8::decode $settings_xml->{'general'}->{'ftp_wurl'};

					$ftp_remote_entry->set_text($settings_xml->{'general'}->{'ftp_uri'});
					$ftp_mode_combo->set_active($settings_xml->{'general'}->{'ftp_mode'});
					$ftp_username_entry->set_text($settings_xml->{'general'}->{'ftp_username'});
					$ftp_password_entry->set_text($settings_xml->{'general'}->{'ftp_password'});
					$ftp_wurl_entry->set_text($settings_xml->{'general'}->{'ftp_wurl'});

					#we store the version info, so we know if there was a new version installed
					#when starting new version we clear the cache on first startup
					if (defined $settings_xml->{'general'}->{'app_version'}) {
						if ($sc->get_version . $sc->get_rev ne $settings_xml->{'general'}->{'app_version'}) {
							$sc->set_clear_cache(TRUE);
						}
					} else {
						$sc->set_clear_cache(TRUE);
					}

					#load account data from profile unless param is set to ignore it
					fct_load_accounts($profilename);
					if (defined $accounts_tree) {
						fct_load_accounts_tree();
						$accounts_tree->set_model($accounts_model);
						fct_set_model_accounts($accounts_tree);
					}

					#endif profile load
				} else {

					#recently used
					$sc->set_ruu_tab($settings_xml->{'recent'}->{'ruu_tab'});
					$sc->set_ruu_hosting($settings_xml->{'recent'}->{'ruu_hosting'});
					$sc->set_ruu_places($settings_xml->{'recent'}->{'ruu_places'});

					#we store the version info, so we know if there was a new version installed
					#when starting new version we clear the cache on first startup
					if (defined $settings_xml->{'general'}->{'app_version'}) {
						if ($sc->get_version . $sc->get_rev ne $settings_xml->{'general'}->{'app_version'}) {
							$sc->set_clear_cache(TRUE);
						}
					} else {
						$sc->set_clear_cache(TRUE);
					}

					#get plugins from cache unless param is set to ignore it
					if (!$sc->get_clear_cache) {

						foreach my $plugin_key (sort keys %{$settings_xml->{'plugins'}}) {
							utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'binary'};

							#check if plugin still exists in filesystem
							if ($shf->file_exists($settings_xml->{'plugins'}->{$plugin_key}->{'binary'})) {

								#restore newlines <![CDATA[<br>]]> tags => \n
								$settings_xml->{'plugins'}->{$plugin_key}->{'tooltip'} =~ s/\<\!\[CDATA\[\<br\>\]\]\>/\n/g;

								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'name_plugin'};
								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'category'};
								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'tooltip'};
								utf8::decode $settings_xml->{'plugins'}->{$plugin_key}->{'lang'};
								$plugins{$plugin_key}->{'binary'}   = $settings_xml->{'plugins'}->{$plugin_key}->{'binary'};
								$plugins{$plugin_key}->{'name'}     = $settings_xml->{'plugins'}->{$plugin_key}->{'name_plugin'};
								$plugins{$plugin_key}->{'category'} = $settings_xml->{'plugins'}->{$plugin_key}->{'category'};
								$plugins{$plugin_key}->{'tooltip'}  = $settings_xml->{'plugins'}->{$plugin_key}->{'tooltip'};
								$plugins{$plugin_key}->{'lang'}     = $settings_xml->{'plugins'}->{$plugin_key}->{'lang'} || "shell";
								$plugins{$plugin_key}->{'recent'}   = $settings_xml->{'plugins'}->{$plugin_key}->{'recent'};
							}

						}    #endforeach

					}    #endif plugins from cache

				}

			};
			if ($@) {
				$sd->dlg_error_message($@, $d->get("Settings could not be restored!"));
				unlink $settingsfile;
			} else {
				fct_show_status_message(1, $d->get("Settings loaded successfully"));
			}

			#endif file exists
		} else {
			warn "ERROR: settingsfile " . $settingsfile . " does not exist\n\n";
		}

		return $settings_xml;
	}

	sub fct_post_settings {
		my $settings_dialog = shift;

		#unset profile combobox when profile was not applied
		if ($current_profile_indx != $combobox_settings_profiles->get_active) {
			$combobox_settings_profiles->set_active($current_profile_indx);
		}

		if (defined $settings_dialog && $settings_dialog) {
			$settings_dialog->hide();
		}

		#save directly
		fct_save_settings(undef);
		fct_save_settings($combobox_settings_profiles->get_active_text)
			if $combobox_settings_profiles->get_active != -1;

		#autostart
		$sas->create_autostart_file(
			Shutter::App::Directories::get_autostart_dir(),
			$fs_active->get_active,
			$fs_min_active->get_active,
			$fs_nonot_active->get_active
		);

		#we need to update the first tab here
		#because the profile might have changed
		fct_update_info_and_tray();

		return TRUE;
	}

	sub fct_save_settings {
		my ($profilename) = @_;

		#settings file
		my $settingsfile = "$ENV{ HOME }/.shutter/settings.xml";
		if (defined $profilename) {
			$settingsfile = "$ENV{ HOME }/.shutter/profiles/$profilename.xml"
				if ($profilename ne "");
		}

		#session file
		my $sessionfile = "$ENV{ HOME }/.shutter/session.xml";

		#accounts file
		my $accountsfile = "$ENV{ HOME }/.shutter/accounts.xml";
		if (defined $profilename) {
			$accountsfile = "$ENV{ HOME }/.shutter/profiles/$profilename\_accounts.xml"
				if ($profilename ne "");
		}

		#we store the version info, so we know if there was a new version installed
		#when starting new version we clear the cache on first startup
		$settings{'general'}->{'app_version'} = $sc->get_version . $sc->get_rev;

		$settings{'general'}->{'last_profile'}      = $combobox_settings_profiles->get_active;
		$settings{'general'}->{'last_profile_name'} = $combobox_settings_profiles->get_active_text || "";

		#menu
		$settings{'gui'}->{'btoolbar_active'} = $sm->{_menuitem_btoolbar}->get_active();

		#recently used
		$settings{'recent'}->{'ruu_tab'}     = $sc->get_ruu_tab;
		$settings{'recent'}->{'ruu_hosting'} = $sc->get_ruu_hosting;
		$settings{'recent'}->{'ruu_places'}  = $sc->get_ruu_places;

		#main
		$settings{'general'}->{'filetype'} = $combobox_type->get_active;
		$settings{'general'}->{'quality'}  = $scale->get_value();
		if ($filename->get_text() =~ "\%NN" || $filename->get_text() =~ "\%T") {
			$settings{'general'}->{'filename'} = $filename->get_text();
		} else {
			$sd->dlg_error_message($@, $d->get("Settings could not be saved! Please make sure that the filename contains a wildcard like \%NN or \%T!"));
			evt_show_settings();
			return 1;
		}
		$settings{'general'}->{'folder'}   = Glib::filename_to_unicode($saveDir_button->get_filename());

		#~ print "Pfad ".$saveDir_button->get_filename()."\n";
		#~ print "Pfad ".$saveDir_button->get_uri()."\n";
		$settings{'general'}->{'save_auto'}                     = $save_auto_active->get_active();
		$settings{'general'}->{'save_ask'}                      = $save_ask_active->get_active();
		$settings{'general'}->{'save_no'}                       = $save_no_active->get_active();
		$settings{'general'}->{'image_autocopy'}                = $image_autocopy_active->get_active();
		$settings{'general'}->{'fname_autocopy'}                = $fname_autocopy_active->get_active();
		$settings{'general'}->{'no_autocopy'}                   = $no_autocopy_active->get_active();
		$settings{'general'}->{'cursor'}                        = $cursor_active->get_active();
		$settings{'general'}->{'delay'}                         = $delay->get_value();
		$settings{'general'}->{'drawing_tool_light_icons'}      = $drawing_tool_light_icons_active->get_active();
		$settings{'general'}->{'drawing_tool_dark_icons'}       = $drawing_tool_dark_icons_active->get_active();
		$settings{'general'}->{'drawing_tool_auto_icons'}       = $drawing_tool_auto_icons_active->get_active();
		#wrksp -> submenu
		if ($x11_supported) {
			$settings{'general'}->{'current_monitor_active'} = $current_monitor_active->get_active;
		}
		#determining timeout
		if ($gnome_web_photo) {
			my $web_menu = $st->{_web}->get_menu;
			my @timeouts = $web_menu->get_children;
			my $timeout  = undef;
			foreach my $to (@timeouts) {
				if ($to->get_active) {
					$timeout = $to->get_name;
					$timeout =~ /([0-9]+)/;
					$timeout = $1;
				}
			}
			$settings{'general'}->{'web_timeout'} = $timeout;
		}

		my $model         = $progname->get_model();
		my $progname_iter = $progname->get_active_iter();

		if (defined $progname_iter) {
			my $progname_value = $model->get_value($progname_iter, 1);
			$settings{'general'}->{'prog'} = $progname_value;
		}

		#actions
		$settings{'general'}->{'prog_active'}         = $progname_active->get_active();
		$settings{'general'}->{'im_colors'}           = $combobox_im_colors->get_active();
		$settings{'general'}->{'im_colors_active'}    = $im_colors_active->get_active();
		$settings{'general'}->{'thumbnail'}           = $thumbnail->get_value();
		$settings{'general'}->{'thumbnail_active'}    = $thumbnail_active->get_active();
		$settings{'general'}->{'bordereffect'}        = $bordereffect->get_value();
		$settings{'general'}->{'bordereffect_active'} = $bordereffect_active->get_active();
		my $bcolor = $bordereffect_cbtn->get_color;
		$settings{'general'}->{'bordereffect_col'} = sprintf("#%02x%02x%02x", $bcolor->red / 257, $bcolor->green / 257, $bcolor->blue / 257);

		#advanced
		$settings{'general'}->{'zoom_active'}      = $zoom_active->get_active();
		$settings{'general'}->{'as_help_active'}   = $as_help_active->get_active();
		$settings{'general'}->{'as_confirmation_necessary'}   = $as_confirmation_necessary->get_active();
		$settings{'general'}->{'asel_x'}           = $asel_size3->get_value();
		$settings{'general'}->{'asel_y'}           = $asel_size4->get_value();
		$settings{'general'}->{'asel_w'}           = $asel_size1->get_value();
		$settings{'general'}->{'asel_h'}           = $asel_size2->get_value();
		$settings{'general'}->{'border'}           = $border_active->get_active();
		$settings{'general'}->{'winresize_active'} = $winresize_active->get_active();
		$settings{'general'}->{'winresize_w'}      = $winresize_w->get_value();
		$settings{'general'}->{'winresize_h'}      = $winresize_h->get_value();
		$settings{'general'}->{'autoshape_active'} = $autoshape_active->get_active();
		$settings{'general'}->{'visible_windows'}  = $visible_windows_active->get_active();
		$settings{'general'}->{'menu_delay'}       = $menu_delay->get_value();
		$settings{'general'}->{'menu_waround'}     = $menu_waround_active->get_active();
		$settings{'general'}->{'web_width'}        = $combobox_web_width->get_active();

		#imageview
		$settings{'general'}->{'trans_check'}  = $trans_check->get_active();
		$settings{'general'}->{'trans_custom'} = $trans_custom->get_active();
		my $tcolor = $trans_custom_btn->get_color;
		$settings{'general'}->{'trans_custom_col'} = sprintf("#%02x%02x%02x", $tcolor->red / 257, $tcolor->green / 257, $tcolor->blue / 257);
		$settings{'general'}->{'trans_backg'}      = $trans_backg->get_active();

		$settings{'general'}->{'session_asc'}        = $session_asc->get_active();
		$settings{'general'}->{'session_asc_combo'}  = $session_asc_combo->get_active();
		$settings{'general'}->{'session_desc'}       = $session_desc->get_active();
		$settings{'general'}->{'session_desc_combo'} = $session_desc_combo->get_active();

		#behavior
		$settings{'general'}->{'autofs'}           = $fs_active->get_active();
		$settings{'general'}->{'autofs_min'}       = $fs_min_active->get_active();
		$settings{'general'}->{'autofs_not'}       = $fs_nonot_active->get_active();
		$settings{'general'}->{'autohide'}         = $hide_active->get_active();
		$settings{'general'}->{'autohide_time'}    = $hide_time->get_value();
		$settings{'general'}->{'present_after'}    = $present_after_active->get_active();
		$settings{'general'}->{'close_at_close'}   = $close_at_close_active->get_active();
		$settings{'general'}->{'notify_after'}     = $notify_after_active->get_active();
		$settings{'general'}->{'notify_timeout'}   = $notify_timeout_active->get_active();
		$settings{'general'}->{'notify_ptimeout'}  = $notify_ptimeout_active->get_active();
		$settings{'general'}->{'notify_agent'}     = $combobox_ns->get_active();
		$settings{'general'}->{'ask_on_delete'}    = $ask_on_delete_active->get_active();
		$settings{'general'}->{'delete_on_close'}  = $delete_on_close_active->get_active();
		$settings{'general'}->{'ask_on_fs_delete'} = $ask_on_fs_delete_active->get_active();

		#ftp upload
		$settings{'general'}->{'ftp_uri'}      = $ftp_remote_entry->get_text();
		$settings{'general'}->{'ftp_mode'}     = $ftp_mode_combo->get_active();
		$settings{'general'}->{'ftp_username'} = $ftp_username_entry->get_text();
		$settings{'general'}->{'ftp_password'} = $ftp_password_entry->get_text();
		$settings{'general'}->{'ftp_wurl'}     = $ftp_wurl_entry->get_text();

		#pipeline steps (ShareX workflow)
		if ($vbox_workflow && $vbox_workflow->{_get_pipeline_steps}) {
			my @steps = $vbox_workflow->{_get_pipeline_steps}->();
			$settings{'general'}->{'pipeline_steps'} = JSON::MaybeXS->new->encode(\@steps);
		}

		#plugins
		foreach my $plugin_key (sort keys %plugins) {
			$settings{'plugins'}->{$plugin_key}->{'name'}        = $plugin_key;
			$settings{'plugins'}->{$plugin_key}->{'binary'}      = $plugins{$plugin_key}->{'binary'};
			$settings{'plugins'}->{$plugin_key}->{'name_plugin'} = $plugins{$plugin_key}->{'name'};
			$settings{'plugins'}->{$plugin_key}->{'category'}    = $plugins{$plugin_key}->{'category'};

			#keep newlines => switch them to <![CDATA[<br>]]> tags
			#the load routine does it the other way round
			my $temp_tooltip = $plugins{$plugin_key}->{'tooltip'};
			$temp_tooltip =~ s/\n/\<\!\[CDATA\[\<br\>\]\]\>/g;
			$settings{'plugins'}->{$plugin_key}->{'tooltip'} = $temp_tooltip;
			$settings{'plugins'}->{$plugin_key}->{'lang'}    = $plugins{$plugin_key}->{'lang'};
			$settings{'plugins'}->{$plugin_key}->{'recent'}  = $plugins{$plugin_key}->{'recent'}
				if defined $plugins{$plugin_key}->{'recent'};
		}

		#settings
		eval {
			my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
			XMLout(\%settings, OutputFile => $tmpfilename);

			#and finally move the file
			mv($tmpfilename, $settingsfile);
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Settings could not be saved!"));
		} else {
			fct_show_status_message(1, $d->get("Settings saved successfully!"));
		}

		#we need to clean the hashkeys, so they become parseable
		my %clean_files;
		my $counter = 0;
		foreach my $key ($shf->nsort(keys %session_screens)) {
			next unless exists $session_screens{$key}->{'long'};

			#8 leading zeros to counter
			$counter = sprintf("%08d", $counter);
			if ($shf->file_exists($session_screens{$key}->{'long'})) {
				$clean_files{"file" . $counter}{'filename'} = $session_screens{$key}->{'long'};
				$counter++;
			}
		}

		#session
		eval {
			my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
			XMLout(\%clean_files, OutputFile => $tmpfilename);

			#and finally move the file
			mv($tmpfilename, $sessionfile);
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Session could not be saved!"));
		}

		#accounts
		#~ print Dumper %accounts;
		my %clean_accounts;
		foreach my $ac (keys %accounts) {
			$clean_accounts{$ac}->{'path'}                       = $accounts{$ac}->{'path'};
			$clean_accounts{$ac}->{'host'}                       = $accounts{$ac}->{'host'};
			$clean_accounts{$ac}->{'password'}                   = $accounts{$ac}->{'password'};
			$clean_accounts{$ac}->{'username'}                   = $accounts{$ac}->{'username'};
			$clean_accounts{$ac}->{'module'}                     = $accounts{$ac}->{'module'};
			$clean_accounts{$ac}->{'folder'}                     = $accounts{$ac}->{'folder'};
			$clean_accounts{$ac}->{'description'}                = $accounts{$ac}->{'description'};
			$clean_accounts{$ac}->{'register_text'}              = $accounts{$ac}->{'register_text'};
			$clean_accounts{$ac}->{'register_color'}             = $accounts{$ac}->{'register_color'};
			$clean_accounts{$ac}->{'supports_anonymous_upload'}  = $accounts{$ac}->{'supports_anonymous_upload'};
			$clean_accounts{$ac}->{'supports_authorized_upload'} = $accounts{$ac}->{'supports_authorized_upload'};
			$clean_accounts{$ac}->{'supports_oauth_upload'}      = $accounts{$ac}->{'supports_oauth_upload'};
		}

		eval {
			my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);
			XMLout(\%clean_accounts, OutputFile => $tmpfilename);

			#and finally move the file
			mv($tmpfilename, $accountsfile);
		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Account-settings could not be saved!"));
		}

		return TRUE;
	}


1;
