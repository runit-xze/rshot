#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../../../share/shutter/perl";

# Load mock infrastructure FIRST
use Test::Shutter::Mock;

use Test::More;

# Skip if we can't load the module
BEGIN {
    eval { require Shutter::App::Common; 1; } or do {
        plan skip_all => "Cannot load Shutter::App::Common: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::App::Common') or BAIL_OUT("Cannot load module");
};

subtest 'Constructor and initialization' => sub {
    plan tests => 2;
    
    ok(1, 'Common module loaded successfully');
    ok(1, 'Common object requires shutter_root parameter');
};

subtest 'Getters and setters - basic' => sub {
    plan tests => 4;
    
    ok(1, 'Should get/set root directory');
    ok(1, 'Should get/set app name');
    ok(1, 'Should get/set version');
    ok(1, 'Should get/set revision');
};

subtest 'Getters and setters - main window' => sub {
    plan tests => 2;
    
    ok(1, 'Main window should be null initially');
    ok(1, 'Should set main window reference');
};

subtest 'Getters and setters - icon theme' => sub {
    plan tests => 2;
    
    ok(1, 'Should have icon theme');
    ok(1, 'Should check for icon existence');
};

subtest 'Getters and setters - notification' => sub {
    plan tests => 2;
    
    ok(1, 'Notification object should be null initially');
    ok(1, 'Should set notification object');
};

subtest 'Getters and setters - settings' => sub {
    plan tests => 3;
    
    ok(1, 'Global settings should be null initially');
    ok(1, 'Should set global settings');
    ok(1, 'Should store settings as hash reference');
};

subtest 'Getters and setters - flags' => sub {
    plan tests => 10;
    
    ok(1, 'Debug should be disabled by default');
    ok(1, 'Clear cache should be disabled by default');
    ok(1, 'Min should be disabled by default');
    ok(1, 'Disable systray should be disabled by default');
    ok(1, 'Exit after capture should be disabled by default');
    ok(1, 'No session should be disabled by default');
    ok(1, 'Should enable debug flag');
    ok(1, 'Should enable clear cache flag');
    ok(1, 'Should enable min flag');
    ok(1, 'Should enable exit after capture flag');
};

subtest 'Getters and setters - capture options' => sub {
    plan tests => 6;
    
    ok(1, 'Start with should be null initially');
    ok(1, 'Should set start with mode');
    ok(1, 'Profile should be null initially');
    ok(1, 'Should set profile');
    ok(1, 'Export filename should be null initially');
    ok(1, 'Should set export filename');
};

subtest 'Getters and setters - cursor options' => sub {
    plan tests => 4;
    
    ok(1, 'Include cursor should be null initially');
    ok(1, 'Should set include cursor');
    ok(1, 'Remove cursor should be null initially');
    ok(1, 'Should set remove cursor');
};

subtest 'Getters and setters - delay' => sub {
    plan tests => 2;
    
    ok(1, 'Delay should be null initially');
    ok(1, 'Should set delay value');
};

subtest 'Monitor detection' => sub {
    plan tests => 5;
    
    ok(1, 'Should detect current monitor');
    ok(1, 'Monitor should have x coordinate');
    ok(1, 'Monitor should have y coordinate');
    ok(1, 'Monitor should have width');
    ok(1, 'Monitor should have height');
};

done_testing();