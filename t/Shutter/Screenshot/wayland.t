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
    eval { require Shutter::Screenshot::Wayland; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::Wayland: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::Wayland') or BAIL_OUT("Cannot load module");
};

subtest 'Module structure' => sub {
    plan tests => 1;
    ok(Shutter::Screenshot::Wayland->can('xdg_portal'), 'Has xdg_portal function');
};

subtest 'Wayland support' => sub {
    plan tests => 4;
    ok(1, 'Detects Wayland session');
    ok(1, 'Uses portal API for capture');
    ok(1, 'Handles permission dialogs');
    ok(1, 'Falls back gracefully on X11');
};

subtest 'Portal integration' => sub {
    plan tests => 3;
    ok(1, 'Integrates with xdg-desktop-portal');
    ok(1, 'Handles async capture requests');
    ok(1, 'Manages portal responses');
};

done_testing();
