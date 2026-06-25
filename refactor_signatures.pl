#!/usr/bin/env perl
use strict;
use warnings;
use File::Find;
use File::Slurp;

my @files;
find(sub { push @files, $File::Find::name if /\.pm$/ }, "share/shutter/resources/modules/");

my $total_converted = 0;

foreach my $file (@files) {
    my $content = read_file($file);
    my $original_content = $content;
    my $changed = 0;
    
    my @lines = split /\n/, $content;
    my $out = "";
    my $in_sub = 0;
    my $sub_name = "";
    my @args;
    my $buffer = "";
    
    for (my $i = 0; $i < @lines; $i++) {
        my $line = $lines[$i];
        
        if (!$in_sub && $line =~ /^[ \t]*sub\s+([a-zA-Z0-9_]+)\s*\{\s*$/) {
            $sub_name = $1;
            $in_sub = 1;
            @args = ();
            $buffer = $line . "\n";
            next;
        }
        
        if ($in_sub) {
            if ($line =~ /^\s*$/ || $line =~ /^\s*\#/) {
                $buffer .= $line . "\n";
            } elsif ($line =~ /^[ \t]*my\s+([\$\@\%][a-zA-Z0-9_]+)\s*=\s*shift\b\s*;/) {
                push @args, $1;
                $buffer .= $line . "\n";
            } elsif ($line =~ /^[ \t]*my\s*\([ \t]*(.*?)[ \t]*\)\s*=\s*\@_\s*;/) {
                my $vars = $1;
                push @args, split(/\s*,\s*/, $vars);
                $buffer .= $line . "\n";
            } else {
                if (@args) {
                    my $sig = join(", ", @args);
                    $out .= "sub $sub_name ($sig) {\n";
                    my @buf_lines = split(/\n/, $buffer);
                    shift @buf_lines; # Remove the original 'sub foo {' line
                    foreach my $b (@buf_lines) {
                        if ($b !~ /^[ \t]*my\s+([\$\@\%][a-zA-Z0-9_]+)\s*=\s*shift\b\s*;/ &&
                            $b !~ /^[ \t]*my\s*\([ \t]*(.*?)[ \t]*\)\s*=\s*\@_\s*;/) {
                            $out .= $b . "\n";
                        }
                    }
                    $out .= $line . "\n";
                    $changed++;
                } else {
                    $out .= $buffer . $line . "\n";
                }
                $in_sub = 0;
            }
        } else {
            $out .= $line . "\n";
        }
    }
    
    if ($changed) {
        write_file($file, $out);
        if (system("perl -I share/shutter/resources/modules/ -c $file >/dev/null 2>&1") != 0) {
            print "Syntax error introduced in $file. Reverting.\n";
            write_file("$file.bad", $out); write_file("$file.bad", $out); write_file($file, $original_content);
        } else {
            print "Converted $changed methods in $file.\n";
            $total_converted += $changed;
        }
    }
}

print "Total methods converted: $total_converted\n";
