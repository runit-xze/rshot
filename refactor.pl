#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $co_file = 'share/shutter/resources/modules/Shutter/Draw/CanvasOverlays.pm';

my $dt = read_file($dt_file);
my $co = read_file($co_file);

# 1. Update DrawingTool.pm requires
$dt =~ s/require Shutter::Draw::UndoManager;/require Shutter::Draw::UndoManager;\nrequire Shutter::Draw::CanvasOverlays;/;

# 2. Update _items init
$dt =~ s/\$self->\{_items\}\s*=\s*undef;/\$self->{_items}         = {};/;

# 3. CanvasOverlays instantiation
my $overlay_init = <<'EOF';
	if ($self->{_canvas}->find_property('redraw-when-scrolled')) {
		$self->{_canvas}->set('redraw-when-scrolled' => TRUE);
	}

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
$dt =~ s/if \(\$self->\{_canvas\}->find_property\('redraw-when-scrolled'\)\) \{\n\s*\$self->\{_canvas\}->set\('redraw-when-scrolled' => TRUE\);\n\s*\}/$overlay_init/;

# 4. Extract logic from handle_embedded
my ($update_body) = $dt =~ /if \(\$action eq 'update'\) \{(.*?)\}\s*elsif \(\$action eq 'delete'\)/s;
my ($delete_body) = $dt =~ /elsif \(\$action eq 'delete'\) \{(.*?)\}\s*elsif \(\$action eq 'hide'\)/s;
my ($hide_body)   = $dt =~ /elsif \(\$action eq 'hide'\) \{(.*?)\}\s*elsif \(\$action eq 'mirror'\)/s;
my ($mirror_body) = $dt =~ /elsif \(\$action eq 'mirror'\) \{(.*?)\}\s*return TRUE;/s;

# Replace $self->{_items}{$item} with $item_hash
for my $body ($update_body, $delete_body, $hide_body, $mirror_body) {
	$body =~ s/\$self->\{_items\}\{\$item\}/\$item_hash/g;
}
# delete_body uses $self->{_canvas}->get_root_item
$delete_body =~ s/\$self->\{_canvas\}/\$self->canvas/g;

my $new_co_methods = <<"EOF";
# Actual embedded item logic
require Shutter::Draw::Utils;

sub _update_embedded {
    my (\$self, \$item_hash, \$force_show) = \@_;
$update_body
}

sub _delete_embedded {
    my (\$self, \$item_hash) = \@_;
$delete_body
}

sub _hide_embedded {
    my (\$self, \$item_hash) = \@_;
$hide_body
}

sub _mirror_line {
    my (\$self, \$item_hash, \$new_width, \$new_height) = \@_;
$mirror_body
}
EOF

# Replace stubs in CanvasOverlays
$co =~ s/# Stub implementations.*?sub _mirror_line \{ \}/$new_co_methods/s;
#write_file($co_file, $co);

# 5. Remove handle_embedded, handle_bg_rects, handle_rects from DrawingTool.pm
my $dt_new_handlers = <<'EOF';
sub handle_embedded {
	my $self = shift;
	return $self->{_overlays}->handle_embedded(@_);
}

sub handle_bg_rects {
	my ($self, $action) = @_;
	return $self->{_overlays}->handle_bg_rects($action, $self->{_canvas_bg_rect});
}

sub handle_rects {
	my $self = shift;
	return $self->{_overlays}->handle_item_handles(@_);
}
EOF

$dt =~ s/sub handle_embedded \{.*?sub setup_item_signals/$dt_new_handlers\n\nsub setup_item_signals/s;
write_file($dt_file, $dt);

print "Refactoring applied!\n";
