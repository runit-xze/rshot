#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

my $ui_mgr_file = 'share/shutter/resources/modules/Shutter/Draw/UIManager.pm';
my $ui_mgr = read_file($ui_mgr_file);

# Extract setup_item_signals, setup_item_signals_extra, check_valid_mime_type, utf8_decode
for my $method (qw/setup_item_signals setup_item_signals_extra check_valid_mime_type utf8_decode/) {
    if ($dt =~ s/^sub $method \{.*?\n(?=^sub )//ms) {
        my $body = $&;
        $body =~ s/my \$self\s*=\s*shift;/my \$mgr = shift;\n\tmy \$self = \$mgr->drawing_tool;/;
        # For setup_item_signals which uses my ($self, $item) = @_;
        if ($body =~ /my \(\$self, (.*?)\) = \@_;/) {
            my $vars = $1;
            $body =~ s/my \(\$self, (.*?)\) = \@_;/my \(\$mgr, $vars\) = \@_;\n\tmy \$self = \$mgr->drawing_tool;/;
        }

        $ui_mgr =~ s/\n1;\n$/\n$body\n1;\n/;
        $dt .= "sub $method { shift->{_UIManager}->$method(\@_) }\n";
    }
}

#write_file($ui_mgr_file, $ui_mgr);
write_file($dt_file, $dt);
print "Final final strip done!\n";
