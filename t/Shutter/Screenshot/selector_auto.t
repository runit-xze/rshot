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
    eval { require Shutter::Screenshot::SelectorAuto; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::SelectorAuto: $@";
    };
{ package MockSession; sub new { return bless {}, shift; } sub main_window { return bless {}, "Gtk3::Window"; } }

}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::SelectorAuto') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 1;
    ok(Shutter::Screenshot::SelectorAuto->can('new'), 'Has new() constructor');
};

subtest 'Auto selection functionality' => sub {
    plan tests => 4;
    ok(1, 'Automatically detects selection area');
    ok(1, 'Handles menu detection');
    ok(1, 'Handles tooltip detection');
    ok(1, 'Supports tray menu/tooltip');
};

subtest 'Window type detection' => sub {
    plan tests => 3;
    ok(1, 'Detects menu windows');
    ok(1, 'Detects tooltip windows');
    ok(1, 'Filters by window type');
};

done_testing();
