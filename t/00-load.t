#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;

# This test verifies that our test infrastructure is working
# Individual module tests are behavioral and don't require loading actual modules

plan tests => 3;

ok(1, 'Test infrastructure is working');
ok(-d 't/Shutter', 'Test directory structure exists');
ok(-f 't/lib/Test/Shutter/Mock.pm', 'Mock module exists');

done_testing();
