#!/usr/bin/perl

use v5.40;
use utf8;
use File::Find;
use File::Spec;
use FindBin qw($Bin);

my $lib_root = File::Spec->catdir($Bin, '..', 'share', 'shutter', 'resources', 'modules');
my %deps;
my %is_moo;

find(sub {
    return unless /\.pm$/;
    my $file = $File::Find::name;
    my $rel = File::Spec->abs2rel($file, $lib_root);
    my $pkg = $rel;
    $pkg =~ s/\.pm$//;
    $pkg =~ s/\//::/g;

    open my $fh, '<', $file or return;
    while (<$fh>) {
        if (/^\s*use\s+(Moo|Moo::Role|Moose|Mouse)/) {
            $is_moo{$pkg} = 1;
        }
        if (/^\s*use\s+([\w:]+)/) {
            my $used = $1;
            next if $used =~ /^(v5|utf8|strict|warnings|feature|Moo|Gtk3|Glib|POSIX|Locale|File|FindBin|Time|Encode|Getopt|Pod|XML|Net|HTTP|GooCanvas2|Mojo)/;
            push @{$deps{$pkg}}, $used;
        }
    }
    close $fh;
}, $lib_root);

say "graph TD";
# Define styles
say "  classDef moo fill:#f9f,stroke:#333,stroke-width:2px";
say "  classDef legacy fill:#fff,stroke:#333,stroke-dasharray: 5 5";

foreach my $pkg (sort keys %deps) {
    my $style = $is_moo{$pkg} ? ":::moo" : ":::legacy";
    foreach my $used (sort @{$deps{$pkg}}) {
        say "  $pkg --> $used";
    }
    if ($is_moo{$pkg}) {
        say "  $pkg$style";
    }
}
