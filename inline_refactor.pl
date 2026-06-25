#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Slurp;

my @files;
find(sub { push @files, $File::Find::name if /\.pm$/ }, "share/shutter/resources/modules/");

my $total_converted = 0;
my $methods_converted = 0;

foreach my $file (@files) {
    my $content = read_file($file);
    my $orig = $content;
    
    # 1. Match single-line shift->{...}
    # sub gettext { shift->{_d} } -> sub gettext ($self) { $self->{_d} }
    my $count = ($content =~ s/^[ \t]*sub\s+([a-zA-Z0-9_]+)\s*\{\s*shift->([^{}]+)\s*\}/sub $1 (\$self) { \$self->$2 }/gm);
    $methods_converted += $count;
    
    # 2. Match single line shift->method(...)
    $count = ($content =~ s/^[ \t]*sub\s+([a-zA-Z0-9_]+)\s*\{\s*shift->([a-zA-Z0-9_]+.*?)\s*\}/sub $1 (\$self) { \$self->$2 }/gm);
    $methods_converted += $count;
    
    # 3. Match sub new { bless {}, shift }
    $count = ($content =~ s/^[ \t]*sub\s+new\s*\{\s*(my\s+\$class\s*=\s*shift;)?\s*(return\s+)?bless\s*(.*?),\s*shift\s*;/sub new (\$class) { $2bless $3, \$class;/gm);
    $methods_converted += $count;

    if ($content ne $orig) {
        write_file($file, $content);
        if (system("perl -I share/shutter/resources/modules/ -c $file >/dev/null 2>&1") != 0) {
            print "Syntax error in $file. Reverting.\n";
            write_file($file, $orig);
            $methods_converted -= $count; # approximate revert of count
        } else {
            print "Converted in $file\n";
            $total_converted++;
        }
    }
}
print "Total files modified: $total_converted\n";
print "Total inline methods converted: $methods_converted\n";
