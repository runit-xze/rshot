package Shutter::Pixbuf::Save;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use File::Basename qw/ fileparse dirname basename /;
use File::Temp     qw/ tempfile tempdir /;
use Glib qw/TRUE FALSE/;

has '_common'  => (is => 'rwp');
has '_window'  => (is => 'rwp');
has '_dialogs' => (is => 'rwp', lazy => 1, builder => '_build__dialogs');
has '_lp'      => (is => 'rwp', lazy => 1, builder => '_build__lp');
has '_quality' => (is => 'rwp');

sub _build__dialogs ($self) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	my $current_window = $self->_window || $self->_common->main_window;
	return Shutter::App::SimpleDialogs->new($current_window);
}

sub _build__lp ($self) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	my $current_window = $self->_window || $self->_common->main_window;
	return Shutter::Pixbuf::Load->new($self->_common, $current_window);
}

around BUILDARGS => sub {
	my ($orig, $class, $common, $window) = @_;
	return { _common => $common, _window => $window };
};

sub set_quality_setting ($self, $filetype) {
	my $default_image_quality = {
		"png"  => 9,
		"jpg"  => 90,
		"webp" => 98,
		"avif" => 68
	};

	if (my $settings = $self->_common->global_settings) {
		if (defined $settings->get_image_quality($filetype)) {
			$self->{_quality} = $settings->get_image_quality($filetype);
		} else {
			$self->{_quality} = $default_image_quality->{$filetype};
		}
	} else {
		$self->{_quality} = $default_image_quality->{$filetype};
	}
	return;
}

sub save_pdf_ps_svg ($self, $filename, $filetype, $pixbuf) {

	my $class = {
		pdf => 'Cairo::PdfSurface',
		ps  => 'Cairo::PsSurface',
		svg => 'Cairo::SvgSurface',
	}->{$filetype};

	my $surface = $class->create($filename, $pixbuf->get_width * 0.8, $pixbuf->get_height * 0.8);
	my $cr      = Cairo::Context->create($surface);
	$cr->scale(0.8, 0.8);
	Gtk3::Gdk::cairo_set_source_pixbuf($cr, $pixbuf, 0, 0);
	$cr->paint;
	$cr->show_page;

	undef $surface;
	undef $cr;
	return;
}

sub save_pixbuf_to_file ($self, $pixbuf, $filename, $filetype, $quality) {

	$self->{_quality} = $quality;

	my $d = $self->_common->gettext_object;

	my $option = $self->_lp->get_option($pixbuf, 'orientation');
	$option = 1 unless defined $option;

	#FIXME: NOT COVERED BY BINDINGS YET (we use Image::ExifTool instead)
	unless ($filetype eq 'jpeg' || $filetype eq 'jpg') {
		if ($option != 1) {
			$pixbuf = $self->_lp->auto_rotate($pixbuf);
		}
	}

	my $imagemagick_result = undef;
	if ($filetype eq 'jpeg' || $filetype eq 'jpg') {

		$self->set_quality_setting($filetype);

		print "Saving file $filename, $filetype, " . $self->_quality . "\n" if $self->_common->debug;

		eval {
			$pixbuf->save($filename, 'jpeg', quality => $self->_quality);

			#FIXME: NOT COVERED BY BINDINGS YET (we use Image::ExifTool instead)
			if (my $exif = Shutter::App::Optional::Exif->new()) {

				my $exiftool = $exif->get_exiftool;
				if ($exiftool) {

					$exiftool->SetNewValue('Orientation' => $option, Type => 'ValueConv');

					my $success = $exiftool->WriteInfo($filename);
				}
			}
		};
	} elsif ($filetype eq 'png') {

		$self->set_quality_setting($filetype);

		print "Saving file $filename, $filetype, " . $self->_quality . "\n" if $self->_common->debug;

		eval { $pixbuf->save($filename, $filetype, "tEXt::Software" => "Shutter", compression => $self->_quality); };
	} elsif ($filetype eq 'bmp') {
		eval { $pixbuf->save($filename, $filetype); };
	} elsif ($filetype eq 'webp') {

		$self->set_quality_setting($filetype);

		print "Saving file $filename, $filetype, " . $self->_quality . "\n" if $self->_common->debug;

		eval { $pixbuf->save($filename, $filetype, "tEXt::Software" => "Shutter", quality => $self->_quality); };

	} elsif ($filetype eq 'avif') {

		$self->set_quality_setting($filetype);

		print "Saving file $filename, $filetype, " . $self->_quality . "\n" if $self->_common->debug;

		eval { $pixbuf->save($filename, $filetype, quality => $self->_quality); };

	} elsif ($filetype eq 'pdf' || $filetype eq 'ps' || $filetype eq 'svg') {

		$self->save_pdf_ps_svg($filename, $filetype, $pixbuf);

		print "Saving file $filename, $filetype\n" if $self->_common->debug;

	} else {

		print "Saving file $filename, $filetype, " . $self->_quality . " (using fallback-mode)\n" if $self->_common->debug;

		my ($tmpfh, $tmpfilename) = tempfile();
		$tmpfilename .= '.png';
		if ($pixbuf) {
			$pixbuf->save($tmpfilename, 'png', compression => '9');
		}

		$imagemagick_result = $self->use_imagemagick_to_save($tmpfilename, $filename);
		unlink $tmpfilename;
	}

	if ($@ || $imagemagick_result) {

		my ($name, $folder, $type) = fileparse($filename, qr/\.[^.]*/);

		my $detailed_message = 'Unknown error';
		if ($@) {
			$detailed_message = $@->message;
		} elsif ($imagemagick_result) {
			$detailed_message = $imagemagick_result;
		}

		my $response = $self->_dialogs->dlg_error_message(
			sprintf($d->get("Error while saving the image %s."),           "'" . $name . $type . "'"),
			sprintf($d->get("There was an error saving the image to %s."), "'" . $folder . "'"),
			undef, undef, undef, undef, undef, undef, $detailed_message
		);
		return FALSE;

	}

	return TRUE;
}

sub use_imagemagick_to_save ($self, $file, $new_file) {

	$file     = quotemeta $file;
	$new_file = quotemeta $new_file;

	my $result = `convert $file $new_file 2>&1`;

	return $result;
}

1;