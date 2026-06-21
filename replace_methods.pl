#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

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

$dt =~ s/sub handle_embedded \{.*?^sub event_item_on_button_release \{/$dt_new_handlers\n\nsub event_item_on_button_release \{/ms;

write_file($dt_file, $dt);
print "Replaced methods!\n";
