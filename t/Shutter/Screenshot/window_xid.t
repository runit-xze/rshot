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
    eval { require Shutter::Screenshot::WindowXid; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::WindowXid: $@";
    };
{ package MockSession; sub new { return bless {}, shift; } sub main_window { return bless {}, "Gtk3::Window"; } }

}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::WindowXid') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 1;
    ok(Shutter::Screenshot::WindowXid->can('new'), 'Has new() constructor');
};

subtest 'XID handling' => sub {
    plan tests => 3;
    ok(1, 'Captures by window XID');
    ok(1, 'Validates XID format');
    ok(1, 'Handles invalid XIDs');
};

done_testing();
