package Shutter::Draw::IO::LoadImport;

use v5.40;
use feature "try";
no warnings "experimental::try";
no warnings "experimental::args_array_with_signatures";

use utf8;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;
use File::Basename qw/ fileparse /;
use File::Glob     qw/ bsd_glob /;

requires qw(
	drawing_tool
);

sub import_from_dnd ($self, $widget, $context, $x, $y, $selection, $info, $time) {
	my $dt   = $self->drawing_tool;
	my $type = $selection->get_target->name;
	return unless $type eq 'text/uri-list';
	my $data = $selection->get_data;
	$data = join('', map { chr } @$data);

	my @files = grep defined($_), split /[\r\n]+/, $data;

	my @valid_files;
	foreach my $file (@files) {
		my $giofile = Glib::IO::File::new_for_uri($file);
		my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $giofile->get_path);
		$mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;    #FIXME
		if ($mime_type && $dt->check_valid_mime_type($mime_type)) {
			push @valid_files, $file;
		}
	}

	#open all valid files
	if (@valid_files) {

		#backup current pixbuf and filename
		my $old_current  = $dt->current_pixbuf();
		my $old_filename = $dt->current_pixbuf_filename();

		foreach (@valid_files) {

			#transform uri to path
			my $new_uri  = Glib::IO::File::new_for_uri($_);
			my $new_file = $new_uri->get_path;

			$dt->current_pixbuf($dt->lp()->load($new_file, undef, undef, undef, TRUE));
			if ($dt->current_pixbuf()) {
				$dt->current_pixbuf_filename($new_file);

				#construct an event and create a new image object
				my $initevent = Gtk3::Gdk::Event->new('motion-notify');
				$initevent->time(Gtk3::get_current_event_time());
				$initevent->window($dt->drawing_window()->get_window);
				$initevent->x($x);
				$initevent->y($y);

				#new item
				my $nitem = $dt->create_image($initevent, undef, TRUE);

				#add to undo stack
				$dt->store_to_xdo_stack($nitem, 'create', 'undo');

			} else {
				$dt->abort_current_mode;
			}
		}

		#restore saved values
		$dt->current_pixbuf($old_current);
		$dt->current_pixbuf_filename($old_filename);

		#uncheck previous active item
		$dt->current_new_item(undef);

	} else {
		Gtk3::drag_finish($context, 0, 0, $time);
		return FALSE;
	}

	Gtk3::drag_finish($context, 1, 0, $time);
	return TRUE;
}

sub import_from_filesystem ($self, $button, $parent = undef, $directory = undef) {
	my $dt = $self->drawing_tool;

	my $menu_objects = Gtk3::Menu->new;

	my $dobjects = $directory || $dt->_sc->shutter_root . "/share/shutter/resources/icons/drawing_tool/objects";

	#first directory flag (see description above)
	my $fd = TRUE;
	my $ff = FALSE;

	my @objects = bsd_glob("$dobjects/*");
	foreach my $name (sort { -d $a <=> -d $b } @objects) {

		#parse filename
		my ($short, $folder, $type) = fileparse($name, qr/\.[^.]*/);

		#if current object is a directory we call the current sub
		#recursively
		if (-d $name) {

			#objects from each directory are sorted (files first)
			#we display a separator when the first directory is listed
			if ($fd && $ff) {
				$menu_objects->append(Gtk3::SeparatorMenuItem->new);
				$fd = FALSE;
			}

			#objects from directory $name
			my $subdir_item = Gtk3::ImageMenuItem->new_with_label($short);
			$subdir_item->set('always_show_image' => TRUE);
			$subdir_item->set_image(Gtk3::Image->new_from_stock('gtk-directory', 'menu'));

			#add empty menu first
			my $menu_empty = Gtk3::Menu->new;
			my $empty_item = Gtk3::MenuItem->new_with_label($dt->gettext()->get("No icon was found"));
			$empty_item->set_sensitive(FALSE);
			$menu_empty->append($empty_item);
			$subdir_item->set_submenu($menu_empty);

			#and populate later (performance)
			$subdir_item->{'nid'} = $subdir_item->signal_connect(
				'activate' => sub {
					$subdir_item->set_image(Gtk3::Image->new_from_file($dt->icons() . "/throbber_16x16.gif"));
					my $submenu = $self->import_from_filesystem($button, $subdir_item, $dobjects . "/$short");

					if ($submenu->get_children) {

						$subdir_item->set_submenu($submenu);

					} else {

						$subdir_item->set_image(Gtk3::Image->new_from_stock('gtk-directory', 'menu'));

					}

					return TRUE;
				});

			#diconnect handler when this event occurs
			$subdir_item->signal_connect(
				'leave-notify-event' => sub {
					if ($subdir_item->signal_handler_is_connected($subdir_item->{'nid'})) {
						$subdir_item->signal_handler_disconnect($subdir_item->{'nid'});
					}
				});
			$menu_objects->append($subdir_item);
			next;
		}

		#there is at least one single file
		#set the flag
		$ff = TRUE;

		#init item with filename first
		my $new_item = Gtk3::ImageMenuItem->new_with_label($short);
		$new_item->set('always_show_image' => TRUE);
		$menu_objects->append($new_item);

		#sfsdc
		$new_item->{'name'} = $name;

	}

	#do not do that when called recursively
	#top level call
	unless ($directory) {

		$menu_objects->append(Gtk3::SeparatorMenuItem->new);

		#objects from session
		my $session_menu_item = Gtk3::ImageMenuItem->new_with_label($dt->gettext()->get("Import from session..."));
		$session_menu_item->set('always_show_image' => TRUE);
		$session_menu_item->set_image(Gtk3::Image->new_from_stock('gtk-index', 'menu'));
		$session_menu_item->set_submenu($self->import_from_session($button));

		#gen thumbnails in an idle callback
		$dt->gen_thumbnail_on_idle('gtk-index', $session_menu_item, $button, TRUE, $session_menu_item->get_submenu->get_children);

		$menu_objects->append($session_menu_item);

		#objects from filesystem
		my $filesystem_menu_item = Gtk3::ImageMenuItem->new_with_label($dt->gettext()->get("Import from filesystem..."));
		$filesystem_menu_item->set('always_show_image' => TRUE);
		$filesystem_menu_item->set_image(Gtk3::Image->new_from_stock('gtk-open', 'menu'));
		$filesystem_menu_item->signal_connect(
			'activate' => sub {

				my $fs = Gtk3::FileChooserDialog->new(
					$dt->gettext()->get("Choose file to open"), $dt->drawing_window(), 'open',
					'gtk-cancel' => 'reject',
					'gtk-open'   => 'accept'
				);

				$fs->set_select_multiple(FALSE);

				#preview widget
				my $iprev = Gtk3::Image->new;
				$fs->set_preview_widget($iprev);

				$fs->signal_connect(
					'selection-changed' => sub {
						if (my $pfilename = $fs->get_preview_filename) {
							my $pixbuf = $dt->lp_ne()->load($pfilename, 200, 200, TRUE, TRUE);
							unless ($pixbuf) {
								$fs->set_preview_widget_active(FALSE);
							} else {
								$fs->get_preview_widget->set_from_pixbuf($pixbuf);
								$fs->set_preview_widget_active(TRUE);
							}
						} else {
							$fs->set_preview_widget_active(FALSE);
						}
					});

				my $filter_all = Gtk3::FileFilter->new;
				$filter_all->set_name($dt->gettext()->get("All compatible image formats"));
				$fs->add_filter($filter_all);

				foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
					my $filter = Gtk3::FileFilter->new;
					$filter->set_name($format->get_name . " - " . $format->get_description);
					foreach my $ext (@{$format->get_extensions}) {
						$filter->add_pattern("*." . uc $ext);
						$filter_all->add_pattern("*." . uc $ext);
						$filter->add_pattern("*." . $ext);
						$filter_all->add_pattern("*." . $ext);
					}
					$fs->add_filter($filter);
				}

				if ($ENV{'HOME'}) {
					$fs->set_current_folder($ENV{'HOME'});
				}
				my $fs_resp = $fs->run;

				my $new_file;
				if ($fs_resp eq "accept") {
					$new_file = $fs->get_filenames;

					$dt->current_pixbuf($dt->lp()->load($new_file, undef, undef, undef, TRUE));
					if ($dt->current_pixbuf()) {
						$dt->current_pixbuf_filename($new_file);
						$button->set_icon_widget(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size($dt->dicons() . '/draw-image.svg', Gtk3::IconSize->lookup('menu'))));
						$button->show_all;
						$dt->canvas()->get_window->set_cursor($dt->change_cursor_to_current_pixbuf);
					} else {
						$dt->abort_current_mode;
					}

					$fs->destroy();
				} else {
					$fs->destroy();
				}

			});

		$menu_objects->append($filesystem_menu_item);

	}

	$button->show_all;
	$menu_objects->show_all;

	#generate thumbnails in an idle callback
	$dt->gen_thumbnail_on_idle('gtk-directory', $parent, $button, FALSE, $menu_objects->get_children);

	return $menu_objects;
}

sub import_from_utheme ($self, $icontheme, $button) {
	my $dt = $self->drawing_tool;

	my $menu_ctxt = Gtk3::Menu->new;

	foreach my $context (sort $icontheme->list_contexts) {

		#objects from current theme (contexts)
		my $utheme_ctxt = Gtk3::ImageMenuItem->new_with_label($context);
		$utheme_ctxt->set('always_show_image' => TRUE);
		$utheme_ctxt->set_image(Gtk3::Image->new_from_stock('gtk-directory', 'menu'));

		#add empty menu first
		my $menu_empty = Gtk3::Menu->new;
		my $empty_item = Gtk3::MenuItem->new_with_label($dt->gettext()->get("No icon was found"));
		$empty_item->set_sensitive(FALSE);
		$menu_empty->append($empty_item);
		$utheme_ctxt->set_submenu($menu_empty);

		#and populate later (performance)
		$utheme_ctxt->{'nid'} = $utheme_ctxt->signal_connect(
			'activate' => sub {

				$utheme_ctxt->set_image(Gtk3::Image->new_from_file($dt->icons() . "/throbber_16x16.gif"));
				my $context_submenu = $self->import_from_utheme_ctxt($icontheme, $context, $button);

				if ($context_submenu->get_children) {

					$utheme_ctxt->set_submenu($context_submenu);

					#gen thumbnails in an idle callback
					$dt->gen_thumbnail_on_idle('gtk-directory', $utheme_ctxt, $button, TRUE, $utheme_ctxt->get_submenu->get_children);

				} else {
					$utheme_ctxt->set_image(Gtk3::Image->new_from_stock('gtk-directory', 'menu'));
				}

				return TRUE;
			});

		#disconnect handler when this event occurs
		$utheme_ctxt->signal_connect(
			'leave-notify-event' => sub {
				if ($utheme_ctxt->signal_handler_is_connected($utheme_ctxt->{'nid'})) {
					$utheme_ctxt->signal_handler_disconnect($utheme_ctxt->{'nid'});
				}
			});

		$menu_ctxt->append($utheme_ctxt);

	}

	$menu_ctxt->show_all;

	return $menu_ctxt;
}

sub import_from_utheme_ctxt ($self, $icontheme, $context, $button) {
	my $dt = $self->drawing_tool;

	my $menu_ctxt_items = Gtk3::Menu->new;

	my $size = Gtk3::IconSize->lookup('dialog');

	foreach my $icon (sort $icontheme->list_icons($context)) {

		#objects from current theme (icons for specific contexts)
		my $utheme_ctxt_item = Gtk3::ImageMenuItem->new_with_label($icon);
		$utheme_ctxt_item->set('always_show_image' => TRUE);
		my $iconinfo = $icontheme->lookup_icon($icon, $size, 'generic-fallback');

		#save filename and generate thumbnail later
		#idle callback
		$utheme_ctxt_item->{'name'} = $iconinfo->get_filename;

		$menu_ctxt_items->append($utheme_ctxt_item);
	}

	$menu_ctxt_items->show_all;

	return $menu_ctxt_items;
}

sub import_from_session ($self, $button) {
	my $dt = $self->drawing_tool;

	my $menu_session_objects = Gtk3::Menu->new;

	my %import_hash = %{$dt->import_hash() || {}};

	foreach my $key ($dt->shf()->nsort(keys %import_hash)) {

		next unless exists $import_hash{$key}->{'short'};
		next unless defined $import_hash{$key}->{'short'};

		#init item with filename
		my $screen_menu_item = Gtk3::ImageMenuItem->new_with_label($import_hash{$key}->{'short'});
		$screen_menu_item->set('always_show_image' => TRUE);

		#set sensitive == FALSE if image eq current file
		$screen_menu_item->set_sensitive(FALSE)
			if $import_hash{$key}->{'long'} eq $dt->filename();

		#save filename and attributes
		$screen_menu_item->{'name'}         = $import_hash{$key}->{'long'};
		$screen_menu_item->{'mime_type'}    = $import_hash{$key}->{'mime_type'};
		$screen_menu_item->{'mtime'}        = $import_hash{$key}->{'mtime'};
		$screen_menu_item->{'giofile'}      = $import_hash{$key}->{'giofile'};
		$screen_menu_item->{'no_thumbnail'} = $import_hash{$key}->{'no_thumbnail'};

		$menu_session_objects->append($screen_menu_item);
	}

	$menu_session_objects->show_all;

	return $menu_session_objects;
}

1;
