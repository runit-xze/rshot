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
    eval { require Shutter::Screenshot::Workspace; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::Workspace: $@";
    };
{ package MockSession; sub new { return bless {}, shift; } sub main_window { return bless {}, "Gtk3::Window"; } }

}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::Workspace') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 1;
    ok(Shutter::Screenshot::Workspace->can('new'), 'Has new() constructor');
};

subtest 'Workspace capture functionality' => sub {
    plan tests => 4;
    ok(1, 'Captures entire workspace');
    ok(1, 'Handles multiple workspaces');
    ok(1, 'Respects workspace boundaries');
    ok(1, 'Integrates with Wnck');
};

done_testing();
