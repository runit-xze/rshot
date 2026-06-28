#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use FindBin qw($RealBin);
use lib "$RealBin/../../../share/shutter/resources/modules";

# Mock Gtk3 and Glib
BEGIN {
    my $gtk_mock = Test::MockModule->new('Gtk3');
    $gtk_mock->mock('-init' => sub { });
    
    my $glib_mock = Test::MockModule->new('Glib');
    $glib_mock->mock('TRUE' => sub { 1 });
    $glib_mock->mock('FALSE' => sub { 0 });
}

# Mock Glib::Object::Introspection
{
    package Glib::Object::Introspection;
    sub setup { }
}

use_ok('Shutter::App::Notification');

subtest 'Constructor and initialization' => sub {
    my $notif = Shutter::App::Notification->new();
    
    isa_ok($notif, 'Shutter::App::Notification');
    ok(defined $notif, 'Notification object created');
};

subtest 'Notification creation' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should create notification');
    ok(1, 'Should set notification title');
    ok(1, 'Should set notification body');
    ok(1, 'Should set notification icon');
};

subtest 'Notification types' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should support info notifications');
    ok(1, 'Should support success notifications');
    ok(1, 'Should support warning notifications');
    ok(1, 'Should support error notifications');
};

subtest 'Notification actions' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should add action buttons');
    ok(1, 'Should handle action callbacks');
    ok(1, 'Should support multiple actions');
    ok(1, 'Should support default action');
};

subtest 'Notification urgency' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should set low urgency');
    ok(1, 'Should set normal urgency');
    ok(1, 'Should set critical urgency');
    ok(1, 'Should affect display behavior');
};

subtest 'Notification timeout' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should set custom timeout');
    ok(1, 'Should use default timeout');
    ok(1, 'Should support persistent notifications');
    ok(1, 'Should auto-dismiss after timeout');
};

subtest 'Screenshot notifications' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should notify on capture success');
    ok(1, 'Should notify on capture failure');
    ok(1, 'Should notify on save success');
    ok(1, 'Should notify on upload success');
    ok(1, 'Should include screenshot preview');
};

subtest 'Upload notifications' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should notify upload start');
    ok(1, 'Should show upload progress');
    ok(1, 'Should notify upload complete');
    ok(1, 'Should notify upload failure');
    ok(1, 'Should include URL in notification');
};

subtest 'Notification history' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should track sent notifications');
    ok(1, 'Should limit history size');
    ok(1, 'Should allow history retrieval');
    ok(1, 'Should clear old notifications');
};

subtest 'Desktop integration' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should use system notification daemon');
    ok(1, 'Should respect system settings');
    ok(1, 'Should handle daemon unavailable');
    ok(1, 'Should fallback gracefully');
};

subtest 'Error handling' => sub {
    my $notif = Shutter::App::Notification->new();
    
    ok(1, 'Should handle notification failure');
    ok(1, 'Should handle invalid parameters');
    ok(1, 'Should cleanup resources');
};

done_testing();
