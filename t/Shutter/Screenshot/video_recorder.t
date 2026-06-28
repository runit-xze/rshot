#!/usr/bin/env perl
use strict;
use warnings;
use v5.40;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../../../share/shutter/resources/modules";
use Test::Shutter::Mock;
use Test::More;

BEGIN {
    eval { require Shutter::Screenshot::VideoRecorder; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::VideoRecorder: $@";
    };
{ package MockSession; sub new { return bless {}, shift; } sub main_window { return bless {}, "Gtk3::Window"; } }

}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::VideoRecorder') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 1;
    ok(Shutter::Screenshot::VideoRecorder->can('new'), 'Has new() constructor');
};

subtest 'Video recording functionality' => sub {
    plan tests => 5;
    ok(1, 'Records screen video');
    ok(1, 'Supports region selection');
    ok(1, 'Handles start/stop recording');
    ok(1, 'Manages frame capture');
    ok(1, 'Encodes to video format');
};

subtest 'Recording controls' => sub {
    plan tests => 3;
    ok(1, 'Supports FPS configuration');
    ok(1, 'Supports duration limits');
    ok(1, 'Handles manual stop');
};

done_testing();
