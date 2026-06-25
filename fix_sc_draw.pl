#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;
use File::Glob;

my @files = File::Glob::bsd_glob("share/shutter/resources/modules/Shutter/Draw/*.pm");

foreach my $file (@files) {
    next unless -f $file;
    my $content = read_file($file);
    my $original = $content;

    $content =~ s/\$dt->sc\(\)/\$dt->{_sc}/g;
    $content =~ s/\$dt->sc([^a-zA-Z0-9_])/\$dt->{_sc}$1/g;

    if ($content ne $original) {
        write_file($file, $content);
        print "Fixed sc in $file\n";
    }
}
