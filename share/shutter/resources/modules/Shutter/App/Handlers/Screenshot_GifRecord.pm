package Shutter::App::Handlers::Screenshot_GifRecord;

## no critic (Subroutines::ProtectPrivateSubs)

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Glib qw/TRUE FALSE/;
use Gtk3;
use File::Basename;
use POSIX       qw(strftime);
use URI::Escape qw(uri_unescape);
use Shutter::Screenshot::SelectorAdvanced;
use Shutter::Screenshot::Window;
use Shutter::Screenshot::GifRecorder;
use Shutter::App::SimpleDialogs;

has cli          => (is => 'ro', required => 1);
has _recorder    => (is => 'rw');
has _stop_window => (is => 'rw');

sub evt_gif_record ($self, $widget, $data, $folder_from_config, $extra) {
	my $cli           = $self->cli;
	my $sc            = $cli->sc;
	my $window        = $cli->window;
	my $d             = $sc->gettext_object;
	my $x11_supported = $cli->{_x11_supported};
	my $hide_active   = $cli->{_hide_active};

	if (!$x11_supported) {
		my $sd = Shutter::App::SimpleDialogs->new;
		$sd->dlg_error_message($d->get("Can't take GIF screenshots without X11 server"), $d->get("Failed"));
		return TRUE;
	}

	if ($hide_active && $hide_active->get_active) {
		$cli->handlers->get('Core')->fct_control_main_window('hide');
	} else {
		($window->{x}, $window->{y}) = $window->get_position;
	}

	my $notify = $sc->notification;
	$notify->close if $notify;

	$cli->handlers->get('Core')->fct_control_signals('block');

	# A short timeout to hide the window
	Glib::Timeout->add(
		$cli->{_hide_time}->get_value || 250,
		sub {
			$self->_start_capture_flow($data, $folder_from_config, $extra);
			$cli->handlers->get('Core')->fct_control_signals('unblock');
			return FALSE;
		});

	return TRUE;
}

sub _start_capture_flow ($self, $data, $folder_from_config, $extra) {
	my $cli = $self->cli;
	my $sc  = $cli->sc;

	my $region;

	if ($data eq 'gif_select' || $data eq 'tray_gif_select') {

		# Use SelectorAdvanced to get region
		my $screenshooter = Shutter::Screenshot::SelectorAdvanced->new($sc, FALSE, 0, FALSE, FALSE, 0, FALSE, 0, 0, 0, 0, FALSE);
		my $dummy_pixbuf  = $screenshooter->select_advanced();
		return unless $dummy_pixbuf;    # Cancelled

		my $history = $screenshooter->get_history();
		return unless $history;

		my ($drawable, $x, $y, $w, $h) = $history->get_last_capture();
		$region = {x => $x, y => $y, w => $w, h => $h};
	} elsif ($data eq 'gif_window' || $data eq 'tray_gif_window') {

		# Select window
		my $screenshooter = Shutter::Screenshot::Window->new($sc, FALSE, 0, FALSE, FALSE, FALSE, 800, 600, 0, "window", FALSE, FALSE, FALSE, FALSE);
		my $dummy_pixbuf  = $screenshooter->window();
		return unless $dummy_pixbuf;    # Cancelled

		my $history = $screenshooter->get_history();
		return unless $history;

		my ($drawable, $x, $y, $w, $h) = $history->get_last_capture();
		$region = {x => $x, y => $y, w => $w, h => $h};
	} else {
		return;
	}

	$self->_show_countdown(
		$region,
		sub {
			$self->_begin_recording($data, $region, $folder_from_config);
		});
	return;
}

sub _show_countdown ($self, $region, $on_done) {
	my $sc        = $self->cli->sc;
	my $sm        = $self->cli->{settings_manager};
	my $countdown = $sm->get_setting('gif', 'countdown') // 3;

	if ($countdown <= 0) {
		$on_done->();
		return;
	}

	# Optional overlay implementation here, for now just use a timeout
	# Or implement Cairo overlay
	my $counter = $countdown;
	my $overlay = Gtk3::Window->new('toplevel');
	$overlay->set_decorated(FALSE);
	$overlay->set_app_paintable(TRUE);

	# Try to make transparent
	my $screen = $overlay->get_screen;
	my $visual = $screen->get_rgba_visual;
	$overlay->set_visual($visual) if $visual;

	$overlay->resize($region->{w}, $region->{h});
	$overlay->move($region->{x}, $region->{y});

	$overlay->signal_connect(
		'draw' => sub {
			my ($widget, $cr) = @_;
			$cr->set_source_rgba(0, 0, 0, 0.4);
			$cr->set_operator('source');
			$cr->paint;

			$cr->set_source_rgba(1, 0, 0, 1);
			$cr->select_font_face("Sans", 'normal', 'bold');
			$cr->set_font_size(72);

			my $text    = "$counter";
			my $extents = $cr->text_extents($text);

			my $x = ($region->{w} - $extents->{width}) / 2;
			my $y = ($region->{h} + $extents->{height}) / 2;

			$cr->move_to($x, $y);
			$cr->show_text($text);
			return FALSE;
		});

	$overlay->show_all;

	Glib::Timeout->add(
		1000,
		sub {
			$counter--;
			if ($counter > 0) {
				$overlay->queue_draw;
				return TRUE;
			} else {
				$overlay->destroy;
				$on_done->();
				return FALSE;
			}
		});
	return;
}

sub _begin_recording ($self, $data, $region, $folder_from_config) {
	my $cli = $self->cli;
	my $sc  = $cli->sc;
	print STDERR "[DEBUG] _begin_recording called\n";
	my $shf = $cli->shf;
	my $sm  = $cli->{settings_manager};

	my $fps          = $sm->get_setting('gif', 'fps')          // 10;
	my $max_duration = $sm->get_setting('gif', 'max_duration') // 30;

	my $folder         = $sm->get_setting('general', 'folder')   // $folder_from_config // Glib::get_user_special_dir('pictures') // Glib::get_home_dir();
	my $filename_value = $sm->get_setting('general', 'filename') // '$name_%NNN';

	# Determine output path
	my $output_path;
	if ($sc->export_filename) {
		my ($short, $folder_path, $ext) = fileparse($shf->switch_home_in_file($shf->utf8_decode($sc->export_filename)), qr/\.[^.]*/);
		$short = strftime $short, localtime;
		$short =~ s/(\/|\#)/-/g;
		$output_path = $folder_path . $short . ".gif";
		$output_path = File::Spec->rel2abs($output_path) unless File::Spec->file_name_is_absolute($output_path);
	} else {
		$filename_value = $shf->utf8_decode(strftime $filename_value, localtime);
		$filename_value =~ s/(\/|\#)/-/g;
		$filename_value = $cli->handlers->get('Util_File')->fct_parse_filename_wildcards($filename_value, undef, undef);
		my $giofile = $cli->handlers->get('Util_Get')->fct_get_next_filename($filename_value, $folder, "gif");
		$output_path = $shf->utf8_decode(uri_unescape($giofile->get_path));
	}

	print STDERR "[DEBUG] Output path generated: " . ($output_path // 'undef') . "\n";

	my $recorder = Shutter::Screenshot::GifRecorder->new(
		_common  => $sc,
		region   => $region,
		fps      => $fps,
		duration => $max_duration,
		output   => $output_path,
		on_done  => sub {
			my $path = shift;
			$self->_on_recording_done($path);
		});

	$self->_recorder($recorder);
	print STDERR "[DEBUG] Calling recorder->start()\n";
	$recorder->start();

	print STDERR "[DEBUG] Calling _show_stop_ui()\n";
	$self->_show_stop_ui();
	return;
}

sub _show_stop_ui ($self) {
	print STDERR "[DEBUG] _show_stop_ui: creating window\n";

	# Floating mini-window for Stop
	my $stop_win = Gtk3::Window->new('toplevel');
	$stop_win->set_decorated(FALSE);
	$stop_win->set_keep_above(TRUE);

	my $button = Gtk3::Button->new_with_label("Stop Recording");
	my $ctx    = $button->get_style_context();
	$ctx->add_class("destructive-action");

	$button->signal_connect(
		clicked => sub {
			$self->_recorder->stop() if $self->_recorder;
			$stop_win->destroy;
			$self->_stop_window(undef);
		});

	$stop_win->add($button);
	$stop_win->show_all;

	print STDERR "[DEBUG] _show_stop_ui: getting monitor geometry\n";

	# Place it somewhere visible, like bottom right
	my $screen = $stop_win->get_screen;
	my $mon    = $screen->get_primary_monitor;
	my $geom   = $screen->get_monitor_geometry($mon);
	$stop_win->move($geom->{x} + $geom->{width} - 150, $geom->{y} + $geom->{height} - 100);

	$self->_stop_window($stop_win);
	print STDERR "[DEBUG] _show_stop_ui: done\n";
	return;
}

sub _on_recording_done ($self, $gif_path) {
	if ($self->_stop_window) {
		$self->_stop_window->destroy;
		$self->_stop_window(undef);
	}
	$self->_recorder(undef);

	my $cli       = $self->cli;
	my $sc        = $cli->sc;
	my $acp       = $cli->{acp};
	require Shutter::App::Core::ClipboardAPI;
	my $clipboard = Shutter::App::Core::ClipboardAPI->new;

	if (!$gif_path || !Shutter::App::Core::FileSystemAPI->new->path_exists($gif_path)) {
		my $sd = Shutter::App::SimpleDialogs->new;
		$sd->dlg_error_message($sc->gettext_object->get("Failed to assemble GIF."), $sc->gettext_object->get("Failed"));
		$cli->handlers->get('Core')->fct_control_main_window('show');
		return;
	}

	my $giofile = Glib::IO::File::new_for_path($gif_path);

	# Create thumbnail from first frame for the session manager
	my $thumb_pixbuf;
	try {
		my $thumb_path = "$gif_path.thumb.png";
		require Shutter::App::Core::SecureSystemCommandAPI;
		Shutter::App::Core::SecureSystemCommandAPI->new->capture('convert', "$gif_path\[0]", $thumb_path);
		if (Shutter::App::Core::FileSystemAPI->new->path_exists($thumb_path)) {
			$thumb_pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($thumb_path);
			Shutter::App::Core::FileSystemAPI->new->Shutter::App::Core::FileSystemAPI->new->remove($thumb_path);
		}
	} catch ($e) {
	}

	unless ($sc->no_session) {
		$cli->handlers->get('Workflow_Integrate')->fct_integrate_screenshot_in_notebook($giofile, $thumb_pixbuf);
	}

	if ($acp && $acp->get_steps) {
		my $upload_link_container = \ '';
		$acp->execute({
				filename    => $gif_path,
				pixbuf      => $thumb_pixbuf,             # We pass the thumb so clipboard can work
				clipboard   => $clipboard,
				upload_link => \$upload_link_container,
				editor_cb   => sub {
					$cli->handlers->get('Upload_Main')->fct_open_with_program(@_);
				},
				upload_cb => sub {
					$cli->handlers->get('Dialogs_Upload')->fct_upload();
				},
				pin_cb => sub {
					my ($pbuf) = @_;
					$cli->{pins}->pin($pbuf, $sc) if $cli->{pins};
				},
			});
	}

	my $present_after_active = $cli->{_present_after_active} // Shutter::App::Init::_mock_widget(FALSE);
	$cli->handlers->get('Core')->fct_control_main_window('show', $present_after_active->get_active);
	return;
}

1;
