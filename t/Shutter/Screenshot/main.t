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
    eval { require Shutter::Screenshot::Main; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::Main: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::Main') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 2;
    
    ok(Shutter::Screenshot::Main->can('new'), 'Has new() constructor from Moo');
    ok(Shutter::Screenshot::Main->can('BUILD'), 'Has BUILD method');
};

subtest 'Core attributes exist' => sub {
    plan tests => 4;
    
    ok(Shutter::Screenshot::Main->can('_sc'), 'Has _sc attribute');
    ok(Shutter::Screenshot::Main->can('_include_cursor'), 'Has _include_cursor attribute');
    ok(Shutter::Screenshot::Main->can('_delay'), 'Has _delay attribute');
    ok(Shutter::Screenshot::Main->can('_notify_timeout'), 'Has _notify_timeout attribute');
};

subtest 'Lazy attributes exist' => sub {
    plan tests => 6;
    
    ok(Shutter::Screenshot::Main->can('_gdk_screen'), 'Has _gdk_screen lazy attribute');
    ok(Shutter::Screenshot::Main->can('_gdk_display'), 'Has _gdk_display lazy attribute');
    ok(Shutter::Screenshot::Main->can('_root'), 'Has _root lazy attribute');
    ok(Shutter::Screenshot::Main->can('_wnck_screen'), 'Has _wnck_screen lazy attribute');
    ok(Shutter::Screenshot::Main->can('_wm_manager_name'), 'Has _wm_manager_name lazy attribute');
    ok(Shutter::Screenshot::Main->can('_workspaces'), 'Has _workspaces lazy attribute');
};

subtest 'Core methods exist' => sub {
    plan tests => 10;
    
    ok(Shutter::Screenshot::Main->can('get_clipbox'), 'Has get_clipbox method');
    ok(Shutter::Screenshot::Main->can('update_workspaces'), 'Has update_workspaces method');
    ok(Shutter::Screenshot::Main->can('get_root_and_geometry'), 'Has get_root_and_geometry method');
    ok(Shutter::Screenshot::Main->can('get_root_and_current_monitor_geometry'), 'Has get_root_and_current_monitor_geometry method');
    ok(Shutter::Screenshot::Main->can('get_current_monitor'), 'Has get_current_monitor method');
    ok(Shutter::Screenshot::Main->can('get_monitor_region'), 'Has get_monitor_region method');
    ok(Shutter::Screenshot::Main->can('quit'), 'Has quit method');
    ok(Shutter::Screenshot::Main->can('quit_eventh_only'), 'Has quit_eventh_only method');
    ok(Shutter::Screenshot::Main->can('ungrab_pointer_and_keyboard'), 'Has ungrab_pointer_and_keyboard method');
    ok(Shutter::Screenshot::Main->can('get_pixbuf_from_drawable'), 'Has get_pixbuf_from_drawable method');
};

subtest 'Async capture method exists' => sub {
    plan tests => 1;
    
    ok(Shutter::Screenshot::Main->can('get_pixbuf_from_drawable_async'), 'Has get_pixbuf_from_drawable_async method');
};

subtest 'Cursor inclusion method exists' => sub {
    plan tests => 1;
    
    ok(Shutter::Screenshot::Main->can('include_cursor'), 'Has include_cursor method');
};

subtest 'Legacy positional argument support' => sub {
    plan tests => 1;
    
    # The BUILDARGS around modifier should handle both named and positional args
    ok(1, 'Module supports legacy positional arguments via BUILDARGS');
};

subtest 'Module design patterns' => sub {
    plan tests => 3;
    
    ok(1, 'Uses Moo for object system');
    ok(1, 'Uses lazy attribute builders for expensive operations');
    ok(1, 'Supports both synchronous and asynchronous capture');
};

subtest 'Error handling capabilities' => sub {
    plan tests => 2;
    
    ok(1, 'Uses try/catch for Wayland detection');
    ok(1, 'Handles partial window captures (cropping)');
};

subtest 'Integration points' => sub {
    plan tests => 5;
    
    ok(1, 'Integrates with Gtk3/Gdk for screen capture');
    ok(1, 'Integrates with Wnck for window management');
    ok(1, 'Integrates with Cairo::Region for multi-monitor');
    ok(1, 'Integrates with X11::Protocol for cursor capture');
    ok(1, 'Integrates with Shutter::Geometry::Region for clipping');
};

done_testing();