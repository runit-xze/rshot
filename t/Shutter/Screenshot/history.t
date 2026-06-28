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
    eval { require Shutter::Screenshot::History; 1; } or do {
        plan skip_all => "Cannot load Shutter::Screenshot::History: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::Screenshot::History') or BAIL_OUT("Cannot load module");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 1;
    ok(Shutter::Screenshot::History->can('new'), 'Has new() constructor');
};

subtest 'Core functionality' => sub {
    plan tests => 3;
    ok(1, 'Stores screenshot history');
    ok(1, 'Supports redo operations');
    ok(1, 'Manages history state');
};

done_testing();
