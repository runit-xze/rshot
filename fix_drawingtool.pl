#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $file = "share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm";
my $content = read_file($file);

# Fix new
$content =~ s/sub new \(\$class\) \{\s*my \$self = \{_sc => shift\};/sub new (\$class, \$sc) {\n\tmy \$self = {_sc => \$sc};/g;

# Fix setters
$content =~ s/sub ([a-zA-Z0-9_]+) \(\$self\) \{\s*\$self->\{([a-zA-Z0-9_]+)\} = shift if scalar \@_;\s*return \$self->\{[a-zA-Z0-9_]+\};\s*\}/sub $1 (\$self, \@args) {\n\t\$self->{$2} = \$args[0] if \@args;\n\treturn \$self->{$2};\n}/g;

# Fix delegates
$content =~ s/sub ([a-zA-Z0-9_]+) \(\$self\) \{\s*return \$self->\{([a-zA-Z0-9_]+)\}->([a-zA-Z0-9_]+)\(\@_\);\s*\}/sub $1 (\$self, \@args) {\n\treturn \$self->{$2}->$3(\@args);\n}/g;

write_file($file, $content);
print "Fixed DrawingTool.pm delegates\n";
