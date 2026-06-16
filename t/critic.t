#! /usr/bin/perl
use strict;
use warnings;
use Test::More;

eval { 
    require Test::Perl::Critic; 
    Test::Perl::Critic->import(-profile => '.perlcriticrc');
};

if ($@) {
    plan skip_all => "Test::Perl::Critic required for testing PBP compliance";
}

Test::Perl::Critic::all_critic_ok("bin", "share/shutter/resources/modules", "t");
