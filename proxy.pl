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
    
    for my $mgr (qw/_property_manager _io_manager _settings_manager _UIManager _MouseManager _ItemFactory _MacroManager _overlays _toolbar_manager _context_menu_manager/) {
        if ($self->{$mgr} && $self->{$mgr}->can($method)) {
            return $self->{$mgr}->$method(@_);
        }
    }

    if (@_) {
        $self->{"_$method"} = shift;
    }
    return $self->{"_$method"};
}
EOF

# Replace the existing AUTOLOAD
$dt =~ s/our \$AUTOLOAD;\nsub AUTOLOAD \{.*?\n\}\n/$autoload\n/ms;

# Strip all 1-line delegations
$dt =~ s/^sub \w+ \{ shift->\{_.*?\}->\w+\(\@_\) \}\n//gms;

write_file($dt_file, $dt);
print "Proxy installed and delegations stripped!\n";
