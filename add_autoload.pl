#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

my $autoload = <<'EOF';

our $AUTOLOAD;
sub AUTOLOAD {
    my $self = shift;
    my ($method) = $AUTOLOAD =~ /.*::(\w+)/;
    return if $method eq 'DESTROY';
    
    if (@_) {
        $self->{"_$method"} = shift;
    }
    return $self->{"_$method"};
}
EOF

# Append AUTOLOAD to the end of the file
unless ($dt =~ /sub AUTOLOAD/) {
    $dt .= "\n$autoload\n";
    write_file($dt_file, $dt);
    print "Added AUTOLOAD\n";
} else {
    print "AUTOLOAD already exists\n";
}
