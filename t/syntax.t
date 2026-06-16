#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Strict;

use FindBin qw/$Bin/;

# Check syntax, use strict and use warnings on all perl files

local $Test::Strict::TEST_WARNINGS = 1;

my @dirs  = ('t', 'bin', "$Bin/../share/shutter/resources/modules/");

my @files = all_perl_files(@dirs);
@files = grep { $_ !~ /shutter\.monolith/ } @files;

plan tests => scalar @files * 3; # syntax, strict, warnings

foreach my $file (@files) {
    syntax_ok($file);
    strict_ok($file);
    warnings_ok($file);
}

done_testing;
