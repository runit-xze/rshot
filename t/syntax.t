#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Strict ();
use Perl::Critic::Utils qw(all_perl_files);

use FindBin qw/$Bin/;

# Check syntax, use strict and use warnings on all perl files

local $Test::Strict::TEST_WARNINGS = 1;

my @dirs  = ('t', 'bin', "$Bin/../share/shutter/resources/modules/");

my @files = all_perl_files(@dirs);
@files = grep { $_ !~ /shutter\.monolith/ } @files;

plan tests => scalar @files * 3; # syntax, strict, warnings

foreach my $file (@files) {
    Test::Strict::syntax_ok($file);
    Test::Strict::strict_ok($file);
    Test::Strict::warnings_ok($file);
}

done_testing;
