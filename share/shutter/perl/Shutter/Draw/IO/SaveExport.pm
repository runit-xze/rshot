package Shutter::Draw::IO::SaveExport;

use v5.40;
use feature "try";
no warnings "experimental::try";
no warnings "experimental::args_array_with_signatures";

use utf8;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;
use Cairo;
use File::Basename qw/ fileparse /;

requires qw(
	drawing_tool
);

sub export_to_file ($self, $rfiletype = undef) {
	my $dt = $self->drawing_tool;

	my $fs = Gtk3::FileChooserDialog->new(
		$dt->gettext()->get("Choose a location to save to"),
		$dt->drawing_window(), 'save',
		'gtk-cancel' => 'reject',
		'gtk-save'   => 'accept'
	);

	my $shutter_hfunct = Shutter::App::HelperFunctions->new($dt->_sc);

	#parse filename
	my ($short, $folder, $ext) = fileparse($dt->_filename(), qr/\.[^.]*/);

	#go to recently used folder
	if (defined $dt->_sc->rusf && $shutter_hfunct->folder_exists($dt->_sc->rusf)) {
		$fs->set_current_folder($dt->_sc->rusf);
		$fs->set_current_name($short . $ext);
	} elsif (defined $dt->_is_unsaved() && $dt->_is_unsaved()) {
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
		my ($short, $folder, $ext) = fileparse($dt->_filename(), qr/\.[^.]*/);
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
					if $mime eq $dt->_mimetype() || defined $rfiletype;

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
			my $filename = $dt->_shf()->utf8_decode($fs->get_filename);

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
		my $filename = $dt->_shf()->utf8_decode($fs->get_filename);

		#parse filename
		my ($short, $folder, $ext) = fileparse($filename, qr/\.[^.]*/);

		#keep selected folder in mind
		$dt->_sc->rusf($folder);

		#handle file format
		my $choosen_format = $combobox_save_as_type->get_active_text;
		$choosen_format =~ s/ \-.*//;    #get png or jpeg (jpg) for example

		$filename = $folder . $short . "." . $choosen_format;

		my $shutter_hfunct = Shutter::App::HelperFunctions->new($dt->_sc);

		unless ($shutter_hfunct->file_exists($filename)) {

			#save
			$self->save(FALSE, $filename, $choosen_format);

		} else {

			#ask the user to replace the image
			#replace button
			my $replace_btn = Gtk3::Button->new_with_mnemonic($dt->gettext()->get("_Replace"));
			$replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

			my $response = $dt->_dialogs()->dlg_warning_message(
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
	return;

}

sub export_to_svg ($self) {
	my $dt = $self->drawing_tool;

	#here might be some more features in future releases of Shutter

	#just call the dialog
	$self->export_to_file('svg');

	return TRUE;
}

sub export_to_ps ($self) {
	my $dt = $self->drawing_tool;

	#here might be some more features in future releases of Shutter

	#just call the dialog
	$self->export_to_file('ps');

	return TRUE;
}

sub export_to_pdf ($self) {
	my $dt = $self->drawing_tool;

	#here might be some more features in future releases of Shutter

	#just call the dialog
	$self->export_to_file('pdf');

	return TRUE;
}

sub save {
	my $self        = shift;
	my $dt          = $self->drawing_tool;
	my $save_to_mem = shift;
	my $filename    = shift || $dt->_filename();
	my $filetype    = shift || $dt->_filetype();

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
				'line-width'          => 0,
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
					'line-width'          => 0,
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
				'line-width'          => 1,
				'visibility'          => 'visible',

			);
			$dt->handle_bg_rects('show');
			return $pixbuf;
		}

		#save pixbuf to file
		my $pixbuf_save = Shutter::Pixbuf::Save->new($dt->_sc, $dt->drawing_window());
		return $pixbuf_save->save_pixbuf_to_file($pixbuf, $filename, $filetype, undef);

	}
	return;

}

1;
