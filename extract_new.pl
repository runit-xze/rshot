#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

my $ui_mgr_file = 'share/shutter/resources/modules/Shutter/Draw/UIManager.pm';
my $ui_mgr = read_file($ui_mgr_file);

if ($dt =~ s/(\t\$self->\{_drawing_vbox\}\s*=\s*Gtk3::VBox->new.*?)(?=\n\treturn TRUE;)//ms) {
    my $body = $1;
    
    my $setup_ui_method = <<EOF;

sub setup_ui {
    my \$mgr = shift;
    my \$self = \$mgr->drawing_tool;
$body
}
EOF

    $ui_mgr =~ s/\n1;\n$/$setup_ui_method\n1;\n/;
    #write_file($ui_mgr_file, $ui_mgr);
    
    my $call = "\t\$self->{_UIManager}->setup_ui();\n";
    $dt =~ s/(return TRUE;)/$call\t$1/;
    
    write_file($dt_file, $dt);
    print "Successfully extracted new() body!\n";
} else {
    print "Failed to extract new() body.\n";
}
