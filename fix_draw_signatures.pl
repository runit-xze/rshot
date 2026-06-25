#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;
use File::Glob;

my @files = File::Glob::bsd_glob("share/shutter/resources/modules/Shutter/Draw/*.pm");
push @files, "share/shutter/resources/modules/Shutter/Draw/CanvasOverlays.pm";

foreach my $file (@files) {
    next unless -f $file;
    my $content = read_file($file);
    my $original = $content;

    # Restore `sub foo { my $self = shift;` for methods with `$self` or `$class`
    $content =~ s/sub ([a-zA-Z0-9_]+)\s*\(\$self\)\s*\{/sub $1 {\n\tmy \$self = shift;/g;
    $content =~ s/sub ([a-zA-Z0-9_]+)\s*\(\$class\)\s*\{/sub $1 {\n\tmy \$class = shift;/g;
    $content =~ s/sub ([a-zA-Z0-9_]+)\s*\(\$mgr\)\s*\{/sub $1 {\n\tmy \$mgr = shift;/g;

    # For multi-arg signatures, just replace with `my ($arg1, $arg2) = @_;` ?
    # But wait, if there are shifts inside, we must be careful!
    # If the sub uses shift, and we use my ($arg) = @_, then shift will return the first arg again!
    # The automated script ONLY replaced `my $self = shift;` with `sub foo ($self)`.
    # So if there are other arguments, they were just comma-separated?
    # No, the automated script did this:
    # If it matched `my $self = shift;`, it became `sub foo ($self)`.
    # If it matched `my ($self, $args) = @_;`, it became `sub foo ($self, $args)`.
    # Let's just strip all signatures and put `my ($self, $args) = @_;` but wait, if it only had `my $self = shift`, then other args are shifted.
    # It's better to just do `my $VAR = shift;` for single argument signatures.
    $content =~ s/sub ([a-zA-Z0-9_]+)\s*\(\$([a-zA-Z0-9_]+)\)\s*\{/sub $1 {\n\tmy \$$2 = shift;/g;

    # For multiple args, we do my ($arg1, $arg2) = @_;
    # This is safe if they didn't use shift for the rest.
    $content =~ s/sub ([a-zA-Z0-9_]+)\s*\((.*?)\)\s*\{/sub $1 {\n\tmy ($2) = \@_;/g;

    if ($content ne $original) {
        write_file($file, $content);
        print "Fixed $file\n";
    }
}
