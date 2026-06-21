#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

my $handlers = <<'EOF';
sub handle_embedded { shift->{_overlays}->handle_embedded(@_) }
sub handle_bg_rects { my ($self, $action) = @_; return $self->{_overlays}->handle_bg_rects($action, $self->{_canvas_bg_rect}) }
sub handle_rects { shift->{_overlays}->handle_item_handles(@_) }
EOF

# Strip handle_*
$dt =~ s/^sub handle_embedded \{.*?\n(?=^sub )//ms;
$dt =~ s/^sub handle_bg_rects \{.*?\n(?=^sub )//ms;
$dt =~ s/^sub handle_rects \{.*?\n(?=^sub )/$handlers\n/ms;

# Also let's extract quit and gen_thumbnail_on_idle to UIManager
my $ui_mgr_file = 'share/shutter/resources/modules/Shutter/Draw/UIManager.pm';
my $ui_mgr = read_file($ui_mgr_file);

for my $method (qw/quit gen_thumbnail_on_idle/) {
    if ($dt =~ s/^sub $method \{.*?\n(?=^sub )//ms) {
        my $body = $&;
        $body =~ s/my \$self\s*=\s*shift;/my \$mgr = shift;\n\tmy \$self = \$mgr->drawing_tool;/;
        $ui_mgr =~ s/\n1;\n$/\n$body\n1;\n/;
        $dt .= "sub $method { shift->{_UIManager}->$method(\@_) }\n";
    }
}

#write_file($ui_mgr_file, $ui_mgr);

# Ensure overlays are required in new()
unless ($dt =~ /Shutter::Draw::CanvasOverlays/) {
    my $overlay_init = <<'EOF';
	require Shutter::Draw::CanvasOverlays;
	$self->{_overlays} = Shutter::Draw::CanvasOverlays->new(
		canvas        => $self->{_canvas},
		items         => $self->{_items},
		setup_signals => sub {
			my $item = shift;
			$self->setup_item_signals($item);
			$self->setup_item_signals_extra($item);
		},
		style_bg      => $self->{_style_bg},
	);
EOF
    $dt =~ s/(sub new \{.+?)(return \$self;)/$1$overlay_init\n\n\t$2/s;
}

write_file($dt_file, $dt);
print "Final strip done!\n";
