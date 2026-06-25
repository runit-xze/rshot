#!/usr/bin/env perl
use strict;
use warnings;

my @tools = glob("share/shutter/resources/modules/Shutter/Draw/Tool/*.pm");

for my $file (@tools) {
    next if $file =~ /Base\.pm$/; # We already fixed Base.pm differently
    
    open my $fh, '<', $file or die "Cannot open $file: $!";
    my $content = do { local $/; <$fh> };
    close $fh;

    # The block we are looking for is roughly:
    # eval { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], undef, $ev->time); };
    # if ($@) { $dt->{_canvas}->pointer_grab($dt->{_items}{$item}{'bottom-right-corner'}, ['pointer-motion-mask', 'button-release-mask'], Gtk3::Gdk::Cursor->new('left-ptr'), $ev->time); }
    # $dt->{_canvas}->grab_focus($item);

    my $replacement = "\t\$dt->acquire_focus(\$dt->{_items}{\$item}{'bottom-right-corner'}, \$ev, undef);\n";
    
    $content =~ s/^\s*eval\s*\{\s*\$dt->\{_canvas\}->pointer_grab\(\$dt->\{_items\}\{\$item\}\{'bottom-right-corner'\}.*?\n\s*if\s*\(\$\@\)\s*\{\s*\$dt->\{_canvas\}->pointer_grab.*?\n\s*\$dt->\{_canvas\}->grab_focus\(\$item\);\s*\n/$replacement/ms;

    open $fh, '>', $file or die "Cannot open $file for writing: $!";
    print $fh $content;
    close $fh;
}

print "Replaced pointer grabs in tools!\n";
