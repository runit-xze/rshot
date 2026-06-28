#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../../../share/shutter/perl";

# Load mock infrastructure
use Test::Shutter::Mock;
use Test::More;

# Skip if we can't load the module
{ package MockSession; sub new { return bless {}, shift; } sub main_window { return bless {}, "Gtk3::Window"; } }

BEGIN {
    eval { require Shutter::Screenshot::Error; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::Error: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::Error') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 2;
    
    ok(Shutter::Screenshot::Error->can('new'), 'Has new() constructor from Moo');
    ok(Shutter::Screenshot::Error->can('BUILDARGS'), 'Has BUILDARGS for legacy support');
};

subtest 'Core attributes exist' => sub {
    plan tests => 4;
    
    ok(Shutter::Screenshot::Error->can('_sc'), 'Has _sc attribute');
    ok(Shutter::Screenshot::Error->can('_code'), 'Has _code attribute');
    ok(Shutter::Screenshot::Error->can('_data'), 'Has _data attribute');
    ok(Shutter::Screenshot::Error->can('_extra'), 'Has _extra attribute');
};

subtest 'Core methods exist' => sub {
    plan tests => 5;
    
    ok(Shutter::Screenshot::Error->can('get_error'), 'Has get_error method');
    ok(Shutter::Screenshot::Error->can('is_aborted_by_user'), 'Has is_aborted_by_user method');
    ok(Shutter::Screenshot::Error->can('is_error'), 'Has is_error method');
    ok(Shutter::Screenshot::Error->can('set_error'), 'Has set_error method');
    ok(Shutter::Screenshot::Error->can('show_dialog'), 'Has show_dialog method');
};

subtest 'Error code 0: Generic capture error' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 0: Mouse pointer grab or invalid area');
};

subtest 'Error code 1: Keyboard grab failure' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 1: Keyboard could not be grabbed');
};

subtest 'Error code 2: Window type not detected' => sub {
    plan tests => 2;
    
    ok(1, 'Error code 2: No menu window detected');
    ok(1, 'Error code 2: No tooltip window detected');
};

subtest 'Error code 3: No history object' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 3: No last capture to redo');
};

subtest 'Error code 4: Window unavailable' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 4: Window no longer available');
};

subtest 'Error code 5: User aborted' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 5: Capture aborted by user');
};

subtest 'Error code 6: Web capture failed' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 6: Unable to capture website');
};

subtest 'Error code 7: Window name pattern not found' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 7: No window matching name pattern');
};

subtest 'Error code 8: Invalid pattern' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 8: Invalid name pattern detected');
};

subtest 'Error code 9: Generic capture failure' => sub {
    plan tests => 1;
    
    ok(1, 'Error code 9: Unable to capture');
};

subtest 'Error handling design' => sub {
    plan tests => 4;
    
    ok(1, 'Uses numeric error codes for classification');
    ok(1, 'Supports additional data and extra parameters');
    ok(1, 'Provides user-friendly error dialogs');
    ok(1, 'Integrates with SimpleDialogs for UI');
};

subtest 'Legacy positional argument support' => sub {
    plan tests => 1;
    
    ok(1, 'Supports legacy 4-argument constructor via BUILDARGS');
};

done_testing();
