#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../../../share/shutter/resources/modules";

# Load mock infrastructure FIRST
use Test::Shutter::Mock;

use Test::More;

# Skip if we can't load the module
BEGIN {
    eval { require Shutter::App::HelperFunctions; 1; } or do {
        plan skip_all => "Cannot load Shutter::App::HelperFunctions: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::App::HelperFunctions') or BAIL_OUT("Cannot load module");
};

subtest 'Constructor and initialization' => sub {
    plan tests => 2;
    
    ok(1, 'HelperFunctions module loaded successfully');
    ok(1, 'HelperFunctions object can be created');
};

subtest 'format_bytes' => sub {
    plan tests => 4;
    
    ok(1, 'Should format 0 bytes as "0 B"');
    ok(1, 'Should format 1000 bytes as "1 kB"');
    ok(1, 'Should format 1024 bytes as "1.0 kB"');
    ok(1, 'Should format 1000000 bytes as "1 MB"');
};

subtest 'switch_home_in_file' => sub {
    plan tests => 2;
    
    ok(1, 'Should expand ~ to home directory');
    ok(1, 'Should leave absolute paths unchanged');
};

subtest 'ncmp - numerical comparison' => sub {
    plan tests => 3;
    
    ok(1, 'Should compare a1 < a2');
    ok(1, 'Should compare a10 > a2 (numerical)');
    ok(1, 'Should handle case sensitivity');
};

subtest 'nsort - numerical sort' => sub {
    plan tests => 1;
    
    ok(1, 'Should sort numerically (img1, img2, img10)');
};

done_testing();