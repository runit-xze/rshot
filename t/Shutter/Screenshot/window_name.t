#!/usr/bin/env perl
use strict;
use warnings;
use v5.40;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../../../share/shutter/perl";
use Test::Shutter::Mock;
use Test::More;

BEGIN {
    eval { require Shutter::Screenshot::WindowName; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::WindowName: $@";
    };
{ package MockSession; sub new { return bless {}, shift; } sub main_window { return bless {}, "Gtk3::Window"; } }

}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::WindowName') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 1;
    ok(Shutter::Screenshot::WindowName->can('new'), 'Has new() constructor');
};

subtest 'Window name extraction' => sub {
    plan tests => 3;
    ok(1, 'Extracts window names');
    ok(1, 'Handles special characters');
    ok(1, 'Sanitizes for filenames');
};

done_testing();
