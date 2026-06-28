package Shutter::Screenshot::GifRecorder;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Glib qw/TRUE FALSE/;
use Gtk3;
use File::Temp qw/tempdir/;

use Shutter::App::Core::SecureSystemCommandAPI;
has '_common'  => (is => 'ro', required => 1);
has 'region'   => (is => 'rw', required => 1);            # { x, y, w, h }
has 'fps'      => (is => 'ro', default  => sub { 10 });
has 'duration' => (is => 'ro', default  => sub { 0 });    # 0 = manual stop
has 'output'   => (is => 'ro', required => 1);            # .gif path
has 'on_done'  => (is => 'ro', required => 1);            # coderef($path)

has '_frames'   => (is => 'rw', default => sub { [] });
has '_tmpdir'   => (is => 'rw');
has '_timer_id' => (is => 'rw');
has '_running'  => (is => 'rw', default => sub { FALSE });

sub start ($self) {
	print STDERR "[DEBUG] GifRecorder::start called\n";
	return if $self->_running;

	$self->_running(TRUE);
	$self->_frames([]);
	$self->_tmpdir(tempdir(CLEANUP => 1));
	print STDERR "[DEBUG] GifRecorder::start initialized tmpdir\n";

	my $interval_ms = int(1000 / ($self->fps || 10));
	my $max_frames  = $self->duration > 0 ? $self->fps * $self->duration : 0;

	$self->_timer_id(
		Glib::Timeout->add(
			$interval_ms,
			sub {
				if (!$self->_running) {
					return FALSE;
				}

				my $pbuf = $self->_grab_frame();
				if ($pbuf) {
					my $n = scalar(@{$self->_frames});
					$self->_save_frame($pbuf, $n);
				}

				if ($max_frames > 0 && scalar(@{$self->_frames}) >= $max_frames) {
					$self->stop();
					return FALSE;
				}

				return TRUE;
			}));
	return;
}

sub stop ($self) {
	return unless $self->_running;
	$self->_running(FALSE);

	if (defined $self->_timer_id) {
		Glib::Source->remove($self->_timer_id);
		$self->_timer_id(undef);
	}

	$self->_assemble();
	return;
}

sub _grab_frame ($self) {
	my $r    = $self->region;
	my $root = Gtk3::Gdk::get_default_root_window();
	my $pbuf;
	try {
		$pbuf = Gtk3::Gdk::pixbuf_get_from_window($root, $r->{x}, $r->{y}, $r->{w}, $r->{h});
	} catch ($e) {

		# Silent fail on grab error
	}
	return $pbuf;
}

sub _save_frame ($self, $pbuf, $n) {
	my $filename = sprintf("%s/frame_%05d.png", $self->_tmpdir, $n);
	try {
		$pbuf->save($filename, "png");
		push @{$self->_frames}, $filename;
	} catch ($e) {

		# Failed to save frame
	}
	return;
}

sub _assemble ($self) {
	my $frames_ref = $self->_frames;
	if (!@$frames_ref) {

		# No frames recorded
		$self->on_done->(undef);
		return;
	}

	my $delay = int(100 / ($self->fps || 10));

	require Shutter::App::Core::SecureSystemCommandAPI;
	my $api = Shutter::App::Core::SecureSystemCommandAPI->new;
	my $res = $api->capture('convert', '-delay', $delay, '-loop', '0', @$frames_ref, $self->output);

	if ($res->{success}) {
		$self->on_done->($self->output);
	} else {
		$self->on_done->(undef);
	}
	return;
}

sub get_mode       ($self) { return 'gif_select' }
sub get_error_text ($self) { return 'Failed to record GIF.' }

1;
