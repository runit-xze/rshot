#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $file = "share/shutter/resources/modules/Shutter/App/Common.pm";
my $content = read_file($file);

$content =~ s/sub (set_\w+) \(\$self\) \{\s*\$self->([a-zA-Z0-9_]+)\(shift\)\s+if\s+\@_\s*\}/sub $1 (\$self, \$val=undef) { \$self->$2(\$val) if defined \$val }/g;

write_file($file, $content);

print "Fixed Common.pm\n";
