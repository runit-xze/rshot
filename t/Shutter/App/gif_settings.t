## no critic (Subroutines::RequireFinalReturn Modules::RequireEndWithOne Modules::RequireExplicitPackage Modules::RequireFilenameMatchesPackage)
use strict;
use warnings;
use v5.40;

use Test::More tests => 6;

use lib 'share/shutter/resources/modules';

# ---------------------------------------------------------------------------
# Mock Glib so the module can load without a display
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
}

# ===== Test 1: require_ok ==================================================
require_ok('Shutter::App::GlobalSettings');

# ===== Test 2: Constructor creates _gif_settings with defaults ==============
subtest "Constructor defaults for GIF settings" => sub {
	plan tests => 5;

	my $gs = Shutter::App::GlobalSettings->new();
	ok(defined $gs, "GlobalSettings object created");
	is($gs->{_gif_settings}{fps},          10, "Default fps is 10");
	is($gs->{_gif_settings}{max_duration}, 30, "Default max_duration is 30");
	is($gs->{_gif_settings}{countdown},    3,  "Default countdown is 3");
	is($gs->{_gif_settings}{cursor},       1,  "Default cursor is 1");
};

# ===== Test 3: get_gif_setting('fps') returns 10 ===========================
subtest "get_gif_setting('fps') returns default" => sub {
	plan tests => 1;

	my $gs = Shutter::App::GlobalSettings->new();
	is($gs->get_gif_setting('fps'), 10, "get_gif_setting('fps') == 10");
};

# ===== Test 4: set then get round-trip ======================================
subtest "set_gif_setting then get_gif_setting round-trip" => sub {
	plan tests => 2;

	my $gs = Shutter::App::GlobalSettings->new();
	$gs->set_gif_setting('fps', 15);
	is($gs->get_gif_setting('fps'), 15, "fps updated to 15");

	# Verify other settings are unaffected
	is($gs->get_gif_setting('max_duration'), 30, "max_duration still 30");
};

# ===== Test 5: Round-trip for all 4 GIF setting keys ========================
subtest "Round-trip for all GIF setting keys" => sub {
	my %test_values = (
		fps          => 24,
		max_duration => 60,
		countdown    => 5,
		cursor       => 0,
	);
	plan tests => scalar keys %test_values;

	my $gs = Shutter::App::GlobalSettings->new();

	for my $key (sort keys %test_values) {
		$gs->set_gif_setting($key, $test_values{$key});
		is($gs->get_gif_setting($key), $test_values{$key}, "Round-trip for '$key': set $test_values{$key}, got $test_values{$key}");
	}
};

# ===== Test 6: get_gif_setting for unknown key returns undef ================
subtest "get_gif_setting for unknown key returns undef" => sub {
	plan tests => 2;

	my $gs = Shutter::App::GlobalSettings->new();
	is($gs->get_gif_setting('nonexistent_key'), undef, "Unknown key 'nonexistent_key' returns undef");
	is($gs->get_gif_setting(''),                undef, "Empty string key returns undef");
};

done_testing();
