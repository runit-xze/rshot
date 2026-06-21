package Shutter::Draw::IOManager;

use utf8;
use strict;
use warnings;

use Moo;

use Gtk3;
use Glib qw/TRUE FALSE/;
use Cairo;
use File::Basename qw/ fileparse dirname basename /;
use File::Glob qw/ bsd_glob /;

has drawing_tool => (
    is => 'ro',
    required => 1,
);

sub export_to_file {
	my $self      = shift;
	my $dt = $self->drawing_tool;
	my $rfiletype = shift;

	my $fs = Gtk3::FileChooserDialog->new(
		$dt->gettext()->get("Choose a location to save to"),
		$dt->drawing_window(), 'save',
		'gtk-cancel' => 'reject',
		'gtk-save'   => 'accept'
	);

	my $shutter_hfunct = Shutter::App::HelperFunctions->new($dt->sc());

	#parse filename
	my ($short, $folder, $ext) = fileparse($dt->filename(), qr/\.[^.]*/);

	#go to recently used folder
	if (defined $dt->sc()->get_rusf && $shutter_hfunct->folder_exists($dt->sc()->get_rusf)) {
		$fs->set_current_folder($dt->sc()->get_rusf);
		$fs->set_current_name($short . $ext);
	} elsif (defined $dt->is_unsaved() && $dt->is_unsaved()) {
		$fs->set_current_folder(Shutter::App::Directories::get_home_dir());
		$fs->set_current_name($short . $ext);
	} else {
		$fs->set_current_folder($folder);
		$fs->set_current_name($short . $ext);
	}

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

	#change extension related to the requested filetype
	if (defined $rfiletype) {
		my ($short, $folder, $ext) = fileparse($dt->filename(), qr/\.[^.]*/);
		$fs->set_current_name($short . "." . $rfiletype);
	}

	my $extra_hbox = Gtk3::HBox->new;

	my $label_save_as_type = Gtk3::Label->new($dt->gettext()->get("Image format") . ":");

	my $combobox_save_as_type = Gtk3::ComboBoxText->new;

	#add supported formats to combobox
	my $counter     = 0;
	my $png_counter = undef;

	#add pdf support
	if (defined $rfiletype && $rfiletype eq 'pdf') {

		$combobox_save_as_type->insert_text($counter, "pdf - Portable Document Format");
		$combobox_save_as_type->set_active(0);

		#add ps support
	} elsif (defined $rfiletype && $rfiletype eq 'ps') {

		$combobox_save_as_type->insert_text($counter, "ps - PostScript");
		$combobox_save_as_type->set_active(0);

		#images
	} else {

		foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {

			#we don't want svg here - this is a dedicated action in the DrawingTool
			next if !defined $rfiletype && $format->get_name =~ /svg/;

			#we have a requested filetype - nothing else will be offered
			next if defined $rfiletype && $format->get_name ne $rfiletype;

			#we want jpg not jpeg
			if ($format->get_name eq "jpeg" || $format->get_name eq "jpg") {
				$combobox_save_as_type->insert_text($counter, "jpg" . " - " . $format->get_description);
			} else {
				$combobox_save_as_type->insert_text($counter, $format->get_name . " - " . $format->get_description);
			}

			#set active when mime_type is matching
			#loop because multiple mime types are registered for fome file formats
			foreach my $mime (@{$format->get_mime_types}) {
				$combobox_save_as_type->set_active($counter)
					if $mime eq $dt->mimetype() || defined $rfiletype;

				#save png_counter as well as fallback
				$png_counter = $counter if $mime eq 'image/png';
			}

			$counter++;

		}

	}

	#something went wrong here
	#filetype was not detected automatically
	#set to png as default
	unless ($combobox_save_as_type->get_active_text) {
		if (defined $png_counter) {
			$combobox_save_as_type->set_active($png_counter);
		}
	}

	$combobox_save_as_type->signal_connect(
		'changed' => sub {
			my $filename = $dt->shf()->utf8_decode($fs->get_filename);

			my $choosen_format = $combobox_save_as_type->get_active_text;
			$choosen_format =~ s/ \-.*//;    #get png or jpeg (jpg) for example
											 #~ print $choosen_format . "\n";

			#parse filename
			my ($short, $folder, $ext) = fileparse($filename, qr/\.[^.]*/);

			$fs->set_current_name($short . "." . $choosen_format);
		});

	#emit the signal once in order to invoke the sub above
	#~ $combobox_save_as_type->signal_emit('changed');

	$extra_hbox->pack_start($label_save_as_type,    FALSE, FALSE, 5);
	$extra_hbox->pack_start($combobox_save_as_type, FALSE, FALSE, 5);

	my $align_save_as_type = Gtk3::Alignment->new(1, 0, 0, 0);

	$align_save_as_type->add($extra_hbox);
	$align_save_as_type->show_all;

	$fs->set_extra_widget($align_save_as_type);

	my $fs_resp = $fs->run;

	if ($fs_resp eq "accept") {
		my $filename = $dt->shf()->utf8_decode($fs->get_filename);

		#parse filename
		my ($short, $folder, $ext) = fileparse($filename, qr/\.[^.]*/);

		#keep selected folder in mind
		$dt->sc()->set_rusf($folder);

		#handle file format
		my $choosen_format = $combobox_save_as_type->get_active_text;
		$choosen_format =~ s/ \-.*//;    #get png or jpeg (jpg) for example

		$filename = $folder . $short . "." . $choosen_format;

		my $shutter_hfunct = Shutter::App::HelperFunctions->new($dt->sc());

		unless ($shutter_hfunct->file_exists($filename)) {

			#save
			$self->save(FALSE, $filename, $choosen_format);

		} else {

			#ask the user to replace the image
			#replace button
			my $replace_btn = Gtk3::Button->new_with_mnemonic($dt->gettext()->get("_Replace"));
			$replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

			my $response = $dt->dialogs()->dlg_warning_message(
				sprintf($dt->gettext()->get("The image already exists in %s. Replacing it will overwrite its contents."), "'" . $folder . "'"),
				sprintf($dt->gettext()->get("An image named %s already exists. Do you want to replace it?"),              "'" . $short . "." . $choosen_format . "'"),
				undef, undef, undef, $replace_btn, undef, undef
			);

			if ($response == 40) {

				#save
				$self->save(FALSE, $filename, $choosen_format);

			}

		}

	}

	$fs->destroy();

}

sub export_to_svg {
	my $self = shift;
	my $dt = $self->drawing_tool;

	#here might be some more features in future releases of Shutter

	#just call the dialog
	$self->export_to_file('svg');

	return TRUE;
}

sub export_to_ps {
	my $self = shift;
	my $dt = $self->drawing_tool;

	#here might be some more features in future releases of Shutter

	#just call the dialog
	$self->export_to_file('ps');

	return TRUE;
}

sub export_to_pdf {
	my $self = shift;
	my $dt = $self->drawing_tool;

	#here might be some more features in future releases of Shutter

	#just call the dialog
	$self->export_to_file('pdf');

	return TRUE;
}

sub save {
	my $self        = shift;
	my $dt = $self->drawing_tool;
	my $save_to_mem = shift;
	my $filename    = shift || $dt->filename();
	my $filetype    = shift || $dt->filetype();

	#make sure not to save the bounding rectangles
	$dt->deactivate_all;

	#hide line and change background color, e.g. for saving
	$dt->handle_bg_rects('hide');

	unless ($save_to_mem) {

		#image format supports transparency or not
		#we need to support more formats here I think
		if ($filetype eq 'jpeg' || $filetype eq 'jpg' || $filetype eq 'bmp') {
			$dt->canvas_bg_rect()->set(
				'fill-color-gdk-rgba' => $dt->canvas_bg_rect()->{fill_color},
				'line-width'   => 0,
			);
		} elsif ($dt->canvas_bg_rect()->{fill_color}->equal(Gtk3::Gdk::RGBA::parse('gray'))) {
			$dt->canvas_bg_rect()->set('visibility' => 'hidden');
		} else {

			#ask the user if he wants to save the background color
			my $bg_dialog = Gtk3::MessageDialog->new($dt->drawing_window(), [qw/modal destroy-with-parent/], 'other', 'none', undef);

			#set attributes
			$bg_dialog->set('text'           => $dt->gettext()->get("Do you want to save the changed background color?"));
			$bg_dialog->set('secondary-text' => $dt->gettext()->get("The background is likely to be transparent if you decide to ignore the background color."));
			$bg_dialog->set('image'          => Gtk3::Image->new_from_stock('gtk-save', 'dialog'));
			$bg_dialog->set('title'          => $dt->gettext()->get("Save Background Color"));

			#ignore bg button
			my $cancel_btn = Gtk3::Button->new_with_mnemonic($dt->gettext()->get("_Ignore Background Color"));

			#save bg button
			my $bg_btn = Gtk3::Button->new_with_mnemonic($dt->gettext()->get("_Save Background Color"));
			$bg_btn->set_can_default(TRUE);

			$bg_dialog->add_action_widget($cancel_btn, 10);
			$bg_dialog->add_action_widget($bg_btn,     20);

			$bg_dialog->set_default_response(20);

			$bg_dialog->get_child->show_all;

			my $response = $bg_dialog->run;
			if ($response == 10) {
				$dt->canvas_bg_rect()->set('visibility' => 'hidden');
			} elsif ($response == 20) {
				$dt->canvas_bg_rect()->set(
					'fill-color-gdk-rgba' => $dt->canvas_bg_rect()->{fill_color},
					'line-width'   => 0,
				);
			}

			$bg_dialog->destroy;

		}
	} else {
		$dt->canvas_bg_rect()->set('visibility' => 'hidden');
	}

	if ($filetype eq 'svg') {

		#0.8? => 72 / 90 dpi
		my $surface = Cairo::SvgSurface->create($filename, $dt->canvas_bg_rect()->get('width') * 0.8, $dt->canvas_bg_rect()->get('height') * 0.8);
		my $cr      = Cairo::Context->create($surface);
		$cr->scale(0.8, 0.8);
		$dt->canvas()->render($cr, $dt->canvas_bg_rect()->get_bounds, 1);
		$cr->show_page;

	} elsif ($filetype eq 'ps') {

		#0.8? => 72 / 90 dpi
		my $surface = Cairo::PsSurface->create($filename, $dt->canvas_bg_rect()->get('width') * 0.8, $dt->canvas_bg_rect()->get('height') * 0.8);
		my $cr      = Cairo::Context->create($surface);
		$cr->scale(0.8, 0.8);
		$dt->canvas()->render($cr, $dt->canvas_bg_rect()->get_bounds, 1);
		$cr->show_page;

	} elsif ($filetype eq 'pdf') {

		#0.8? => 72 / 90 dpi
		my $surface = Cairo::PdfSurface->create($filename, $dt->canvas_bg_rect()->get('width') * 0.8, $dt->canvas_bg_rect()->get('height') * 0.8);
		my $cr      = Cairo::Context->create($surface);
		$cr->scale(0.8, 0.8);
		$dt->canvas()->render($cr, $dt->canvas_bg_rect()->get_bounds, 1);
		$cr->show_page;

	} else {

		my $surface = Cairo::ImageSurface->create('argb32', $dt->canvas_bg_rect()->get('width'), $dt->canvas_bg_rect()->get('height'));
		my $cr      = Cairo::Context->create($surface);
		$dt->canvas()->render($cr, $dt->canvas_bg_rect()->get_bounds, 1);

		my $loader = Gtk3::Gdk::PixbufLoader->new;
		$surface->write_to_png_stream(
			sub {
				my ($closure, $data) = @_;
				$loader->write([map ord, split //, $data]);
				return TRUE;
			});
		$loader->close;
		my $pixbuf = $loader->get_pixbuf;

		#just return pixbuf
		if ($save_to_mem) {

			#update the canvas_rect again
			$dt->canvas_bg_rect()->set(
				'fill-color-gdk-rgba' => $dt->canvas_bg_rect()->{fill_color},
				'line-width'   => 1,
				'visibility'   => 'visible',

			);
			$dt->handle_bg_rects('show');
			return $pixbuf;
		}
		#save pixbuf to file
		my $pixbuf_save = Shutter::Pixbuf::Save->new($dt->sc(), $dt->drawing_window());
		return $pixbuf_save->save_pixbuf_to_file($pixbuf, $filename, $filetype, undef);

	}

}

sub import_from_dnd {
	my ($self, $widget, $context, $x, $y, $selection, $info, $time) = @_;
	my $dt = $self->drawing_tool;
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

sub import_from_filesystem {
	my $self   = shift;
	my $dt = $self->drawing_tool;
	my $button = shift;

	#used when called recursively
	my $parent    = shift;
	my $directory = shift;

	my $menu_objects = Gtk3::Menu->new;

	my $dobjects = $directory || $dt->sc()->get_root . "/share/shutter/resources/icons/drawing_tool/objects";

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

		#~ #objects from icontheme
		#~ if ( Gtk3->CHECK_VERSION( 2, 12, 0 ) ) {
		#~ my $icontheme = Gtk3::IconTheme::get_default();
		#~
		#~ my $utheme_item = Gtk3::ImageMenuItem->new_with_label( $dt->gettext()->get("Import from current theme...") );
		#~ $utheme_item->set( 'always_show_image' => TRUE ) if Gtk3->CHECK_VERSION( 2, 16, 0 );
		#~ if ( $icontheme->has_icon('preferences-desktop-theme') ) {
		#~ $utheme_item->set_image( Gtk3::Image->new_from_icon_name( 'preferences-desktop-theme', 'menu' ) );
		#~ }
		#~
		#~ $utheme_item->set_submenu( $self->import_from_utheme( $icontheme, $button ) );
		#~
		#~ $menu_objects->append($utheme_item);
		#~
		#~ $menu_objects->append( Gtk3::SeparatorMenuItem->new );
		#~ }

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

sub import_from_utheme {
	my $self      = shift;
	my $dt = $self->drawing_tool;
	my $icontheme = shift;
	my $button    = shift;

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
		my @menu_items;
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

sub import_from_utheme_ctxt {
	my $self      = shift;
	my $dt = $self->drawing_tool;
	my $icontheme = shift;
	my $context   = shift;
	my $button    = shift;

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

sub import_from_session {
	my $self   = shift;
	my $dt = $self->drawing_tool;
	my $button = shift;

	my $menu_session_objects = Gtk3::Menu->new;

	my %import_hash = %{$dt->import_hash()};

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
