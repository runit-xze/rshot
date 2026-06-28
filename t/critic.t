#! /usr/bin/perl
use strict;
use warnings;
use Test::More;
use Cwd qw(abs_path);
use File::Spec;

eval {
	require Test::Perl::Critic::Progressive;
	Test::Perl::Critic::Progressive->import(':all');
};

if ($@) {
	plan skip_all => "Test::Perl::Critic::Progressive required for testing PBP compliance";
}

my $history = File::Spec->catfile(abs_path('t'), '.perlcritic-history');
set_critic_args(-profile => '.perlcriticrc', -verbose => 8);
set_history_file($history);
progressive_critic_ok('bin', 'share/shutter/perl', 't');
