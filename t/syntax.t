#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Strict        ();
use Perl::Critic::Utils qw(all_perl_files);

use FindBin qw/$Bin/;
use lib "$Bin/../share/shutter/perl";
# Check syntax, use strict and use warnings on all perl files

local $Test::Strict::TEST_WARNINGS = 1;

my @dirs = ('t', 'bin', "$Bin/../share/shutter/perl/");

my @files = all_perl_files(@dirs);
@files = grep { $_ !~ /shutter\.monolith/ } @files;

plan tests => scalar @files * 3;    # syntax, strict, warnings

foreach my $file (@files) {
	Test::Strict::syntax_ok($file);

	# Test::Strict does not recognize use v5.40; which implicitly turns on strict and warnings
	open my $fh, '<', $file or die "Cannot open $file: $!";
	my $content = do { local $/; <$fh> };
	close $fh;

	if ($content =~ /use v5\.40;/) {
		pass("use strict (implicit via v5.40) in $file");
		pass("use warnings (implicit via v5.40) in $file");
	} else {
		Test::Strict::strict_ok($file);
		Test::Strict::warnings_ok($file);
	}
}

done_testing;
