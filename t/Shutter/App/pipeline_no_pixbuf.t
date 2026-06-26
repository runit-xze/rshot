## no critic (Subroutines::RequireFinalReturn)
use strict;
use warnings;
use v5.40;

use Test::More tests => 6;

use lib 'share/shutter/resources/modules';

# ---------------------------------------------------------------------------
# Mock Glib/Gtk3 and other dependencies so the module loads without a display
# ---------------------------------------------------------------------------
BEGIN {
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

# ---------------------------------------------------------------------------
# Mock clipboard that records method calls
# ---------------------------------------------------------------------------
package MockClipboard;
sub new       { bless {calls => []}, shift }
sub set_image { push @{$_[0]->{calls}}, ['set_image', $_[1]] }
sub set_text  { push @{$_[0]->{calls}}, ['set_text',  $_[1]] }

package main;

# ===== Test 1: require_ok ==================================================
require_ok('Shutter::App::AfterCapturePipeline');

# ===== Test 2: Construction =================================================
subtest "Construction" => sub {
	plan tests => 2;

	my $mock_d = bless {}, 'MockGettext';
	my $acp    = Shutter::App::AfterCapturePipeline->new(undef, $mock_d, undef);
	ok(defined $acp, "Pipeline object created");
	is_deeply([$acp->get_steps], [], "No steps by default");
};

# ===== Test 3: copy_image with pixbuf => undef does NOT crash ===============
subtest "copy_image with undef pixbuf does not crash" => sub {
	plan tests => 2;

	my $mock_d = bless {}, 'MockGettext';
	my $acp    = Shutter::App::AfterCapturePipeline->new(undef, $mock_d, undef);
	$acp->set_steps({type => 'copy_image'});

	my $clipboard = MockClipboard->new();

	eval { $acp->execute({filename => '/tmp/test.png', pixbuf => undef, clipboard => $clipboard,}); };
	is($@,                            '', "execute() with copy_image + undef pixbuf does not die");
	is(scalar @{$clipboard->{calls}}, 0,  "Clipboard set_image NOT called when pixbuf is undef");
};

# ===== Test 4: pin_to_screen with pixbuf => undef does NOT crash ============
subtest "pin_to_screen with undef pixbuf does not crash" => sub {
	plan tests => 2;

	my $mock_d = bless {}, 'MockGettext';
	my $acp    = Shutter::App::AfterCapturePipeline->new(undef, $mock_d, undef);
	$acp->set_steps({type => 'pin_to_screen'});

	my $pin_called = 0;
	eval {
		$acp->execute({
			filename  => '/tmp/test.png',
			pixbuf    => undef,
			clipboard => MockClipboard->new(),
			pin_cb    => sub { $pin_called = 1 },
		});
	};
	is($@, '', "execute() with pin_to_screen + undef pixbuf does not die");
	ok(!$pin_called, "pin_cb NOT called when pixbuf is undef");
};

# ===== Test 5: copy_filename with filename defined still works ==============
subtest "copy_filename with defined filename works" => sub {
	plan tests => 2;

	my $mock_d = bless {}, 'MockGettext';
	my $acp    = Shutter::App::AfterCapturePipeline->new(undef, $mock_d, undef);
	$acp->set_steps({type => 'copy_filename'});

	my $clipboard = MockClipboard->new();

	eval { $acp->execute({filename => '/tmp/screenshot.gif', pixbuf => undef, clipboard => $clipboard,}); };
	is($@, '', "execute() with copy_filename does not die");
	is_deeply($clipboard->{calls}, [['set_text', '/tmp/screenshot.gif']], "Clipboard set_text called with correct filename");
};

# ===== Test 6: open_in_editor works regardless of pixbuf ====================
subtest "open_in_editor works regardless of pixbuf" => sub {
	plan tests => 2;

	my $mock_d = bless {}, 'MockGettext';
	my $acp    = Shutter::App::AfterCapturePipeline->new(undef, $mock_d, undef);
	$acp->set_steps({type => 'open_in_editor'});

	my $editor_received;
	eval {
		$acp->execute({
			filename  => '/tmp/screenshot.gif',
			pixbuf    => undef,
			clipboard => MockClipboard->new(),
			editor_cb => sub { $editor_received = shift },
		});
	};
	is($@,               '',                    "execute() with open_in_editor + undef pixbuf does not die");
	is($editor_received, '/tmp/screenshot.gif', "editor_cb called with correct filename");
};

done_testing();
