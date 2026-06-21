#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

my $state_mgr_file = 'share/shutter/resources/modules/Shutter/Draw/StateManager.pm';

if ($dt =~ s/(my \$self = \{_sc => shift\};\n)(.*?)(?=\n\trequire Shutter::Draw::PropertyManager;)/$1\trequire Shutter::Draw::StateManager;\n\tShutter::Draw::StateManager::init_state(\$self);\n/ms) {
    my $body = $2;
    
    my $state_code = <<EOF;
package Shutter::Draw::StateManager;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

sub init_state {
    my \$self = shift;
$body
}

1;
EOF

    #write_file($state_mgr_file, $state_code);
    write_file($dt_file, $dt);
    print "State extracted!\n";
} else {
    print "Failed to extract state.\n";
}
