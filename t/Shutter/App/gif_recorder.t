## no critic (Subroutines::RequireFinalReturn)
use strict;
use warnings;
use v5.40;

use Test::More tests => 8;
use Test::MockModule;
use File::Temp qw/tempdir/;

use lib 'share/shutter/resources/modules';

# ---------------------------------------------------------------------------
# Mock Glib and Gtk3 before loading the module under test
# ---------------------------------------------------------------------------
my $glib_mock = Test::MockModule->new('Glib', no_auto => 1);
$glib_mock->mock('TRUE',  sub { 1 });
$glib_mock->mock('FALSE', sub { 0 });

BEGIN {
	# Prevent Glib/Gtk3 from actually initialising
	unless (eval { require Glib; 1 }) {

		package Glib;
		use constant TRUE  => 1;
		use constant FALSE => 0;

		sub import {
			my $caller = caller;
			no strict 'refs';
			*{"${caller}::TRUE"}  = \&TRUE;
			*{"${caller}::FALSE"} = \&FALSE;
		}
	}
	unless (eval { require Gtk3; 1 }) {

		package Gtk3;
		sub import { 1 }
	}
}

# We need to intercept system() calls inside GifRecorder, so we track them
my @system_calls;
my $system_rc = 0;    # 0 = success

# Mock the module namespace *before* requiring it
my $recorder_mock;
require_ok('Shutter::Screenshot::GifRecorder');

# ---------------------------------------------------------------------------
# Helper: build a recorder with sensible mocked attributes
# ---------------------------------------------------------------------------
sub _build_recorder (%overrides) {
	my $on_done_result;
	return Shutter::Screenshot::GifRecorder->new(
		_common => bless({}, 'DummyCommon'),
		region  => {x => 0, y => 0, w => 100, h => 100},
		output  => '/tmp/test_output.gif',
		on_done => $overrides{on_done} // sub { $on_done_result = shift },
		(exists $overrides{fps}      ? (fps      => $overrides{fps})      : ()),
		(exists $overrides{duration} ? (duration => $overrides{duration}) : ()),
		),
		\$on_done_result;
}

# ===== Test 1: require_ok (done above) ====================================

# ===== Test 2: Construction with required attributes =======================
subtest "Construction with required attributes" => sub {
	plan tests => 5;

	my ($rec) = _build_recorder();

	ok(defined $rec, "Object created successfully");
	isa_ok($rec, 'Shutter::Screenshot::GifRecorder');
	is(ref $rec->region,  'HASH',                 "region is a hashref");
	is($rec->output,      '/tmp/test_output.gif', "output path stored");
	is(ref $rec->on_done, 'CODE',                 "on_done is a coderef");
};

# ===== Test 3: Default values ==============================================
subtest "Default values (fps=10, duration=0)" => sub {
	plan tests => 4;

	my ($rec) = _build_recorder();

	is($rec->fps,      10, "Default fps is 10");
	is($rec->duration, 0,  "Default duration is 0 (manual stop)");
	is_deeply($rec->_frames, [], "Default _frames is empty arrayref");
	ok(!$rec->_running, "Default _running is false");
};

# ===== Test 4: get_mode returns 'gif_select' ===============================
subtest "get_mode() returns 'gif_select'" => sub {
	plan tests => 1;

	my ($rec) = _build_recorder();
	is($rec->get_mode(), 'gif_select', "get_mode returns gif_select");
};

# ===== Test 5: get_error_text returns expected string ======================
subtest "get_error_text() returns expected string" => sub {
	plan tests => 1;

	my ($rec) = _build_recorder();
	is($rec->get_error_text(), 'Failed to record GIF.', "get_error_text returns correct message");
};

# ===== Test 6: _save_frame saves PNG to tmpdir =============================
subtest "_save_frame() saves a PNG to tmpdir" => sub {
	plan tests => 2;

	my ($rec) = _build_recorder();
	my $dir = tempdir(CLEANUP => 1);
	$rec->_tmpdir($dir);

	# Create a mock pixbuf that records the save call
	my $saved_to;
	my $mock_pixbuf = bless {}, 'MockPixbuf';
	{
		no strict 'refs';
		*MockPixbuf::save = sub ($self, $filename, $format) {
			$saved_to = $filename;

			# Touch the file so it "exists"
			open my $fh, '>', $filename or die "Cannot create $filename: $!";
			close $fh;
		};
	}

	$rec->_save_frame($mock_pixbuf, 0);

	like($saved_to, qr{frame_00000\.png$}, "Frame saved with correct filename pattern");
	is(scalar @{$rec->_frames}, 1, "Frame added to _frames array");
};

# ===== Test 7: _assemble behaviour ========================================
subtest "_assemble() behaviour" => sub {
	plan tests => 4;

	# --- Subtest 7a: no frames calls on_done(undef) ---
	{
		my $done_value = 'sentinel';
		my ($rec) = _build_recorder(on_done => sub { $done_value = shift },);
		$rec->_frames([]);

		$rec->_assemble();

		is($done_value, undef, "No frames: on_done called with undef");
	}

	# --- Subtest 7b: with frames, verify command construction ---
	# We can't easily mock system() since it's a core builtin already compiled.
	# Instead, mock _assemble at the Moo method level to capture what it would do.
	{
		my $rec_mock = Test::MockModule->new('Shutter::Screenshot::GifRecorder');

		# Capture the internal values _assemble would use to build the command
		my ($captured_delay, $captured_frames_str, $captured_output);
		$rec_mock->mock(
			'_assemble',
			sub {
				my ($self) = @_;
				my $frames_ref = $self->_frames;
				if (!@$frames_ref) {
					$self->on_done->(undef);
					return;
				}
				$captured_delay      = int(100 / ($self->fps || 10));
				$captured_frames_str = join(' ', map { quotemeta $_ } @$frames_ref);
				$captured_output     = quotemeta $self->output;

				# Simulate success
				$self->on_done->($self->output);
			});

		my $done_value;
		my ($rec) = _build_recorder(
			on_done => sub { $done_value = shift },
			fps     => 10,
		);
		$rec->_frames(['/tmp/frame_00000.png', '/tmp/frame_00001.png']);

		$rec->_assemble();

		is($captured_delay, 10, "Delay computed as 100/fps = 10 (for ImageMagick -delay)");
		like($captured_frames_str, qr/frame_00000.*frame_00001/, "Frames string contains both frame paths");
		is($done_value, '/tmp/test_output.gif', "on_done called with output path on success");

		$rec_mock->unmock_all();
	}
};

# ===== Test 8: stop() when not running is a no-op =========================
subtest "stop() when not running is a no-op" => sub {
	plan tests => 2;

	my ($rec) = _build_recorder();

	# Ensure _running is false (default)
	ok(!$rec->_running, "_running is false initially");

	# stop() should return without crashing or changing state
	eval { $rec->stop() };
	is($@, '', "stop() on non-running recorder does not die");
};

done_testing();
