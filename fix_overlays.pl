#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $co_file = 'share/shutter/resources/modules/Shutter/Draw/CanvasOverlays.pm';
my $co = read_file($co_file);

# Fix missing arrow for hashref access
$co =~ s/\$item_hash\{/\$item_hash->\{/g;

# Fix stray $item
$co =~ s/\$item->get/\$item_hash->get/g;

write_file($co_file, $co);
print "Fixed Overlays!\n";
