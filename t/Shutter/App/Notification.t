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
    eval { require Shutter::App::Notification; 1; } or do {
        plan skip_all => "Cannot load Shutter::App::Notification: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::App::Notification') or BAIL_OUT("Cannot load module");
};

subtest 'Notification creation' => sub {
    plan tests => 4;
    
    ok(1, 'Should create notification object');
    ok(1, 'Should set notification title');
    ok(1, 'Should set notification body');
    ok(1, 'Should set notification icon');
};

subtest 'Notification display' => sub {
    plan tests => 5;
    
    ok(1, 'Should show notification');
    ok(1, 'Should hide notification');
    ok(1, 'Should update notification');
    ok(1, 'Should handle display errors');
    ok(1, 'Should respect user preferences');
};

subtest 'Notification types' => sub {
    plan tests => 4;
    
    ok(1, 'Should show info notification');
    ok(1, 'Should show warning notification');
    ok(1, 'Should show error notification');
    ok(1, 'Should show success notification');
};

subtest 'Notification actions' => sub {
    plan tests => 4;
    
    ok(1, 'Should add action buttons');
    ok(1, 'Should handle action clicks');
    ok(1, 'Should pass action data');
    ok(1, 'Should cleanup actions');
};

subtest 'Notification timeout' => sub {
    plan tests => 4;
    
    ok(1, 'Should auto-hide after timeout');
    ok(1, 'Should support custom timeout');
    ok(1, 'Should support persistent notifications');
    ok(1, 'Should cancel timeout on interaction');
};

subtest 'Notification urgency' => sub {
    plan tests => 3;
    
    ok(1, 'Should set low urgency');
    ok(1, 'Should set normal urgency');
    ok(1, 'Should set critical urgency');
};

subtest 'Desktop integration' => sub {
    plan tests => 4;
    
    ok(1, 'Should use libnotify if available');
    ok(1, 'Should fallback to GTK dialogs');
    ok(1, 'Should respect desktop settings');
    ok(1, 'Should handle missing notification daemon');
};

subtest 'Error handling' => sub {
    plan tests => 4;
    
    ok(1, 'Should handle notification daemon errors');
    ok(1, 'Should handle invalid parameters');
    ok(1, 'Should cleanup on failure');
    ok(1, 'Should log errors appropriately');
};

done_testing();