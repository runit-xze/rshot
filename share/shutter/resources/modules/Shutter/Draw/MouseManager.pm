package Shutter::Draw::MouseManager;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;
use Carp qw(verbose longmess);

has drawing_tool => (is => 'ro', required => 1);

sub event_item_on_motion_notify {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return FALSE unless $tool;
	my $res;
	eval { $res = $tool->on_motion_notify($item, $target, $ev); };
	if (my $e = $@) {
		warn "Tool crashed on motion_notify: $e";
		warn "  item=" . (ref($item) // 'undef') . " target=" . (ref($target) // 'undef') . " tool=" . (ref($tool) // 'undef');
		warn longmess("motion_notify error trace");
		$mgr->drawing_tool->release_focus($item, $ev);
		return FALSE;
	}
	return $res;
}

sub event_item_on_key_press {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return FALSE unless $tool;
	my $res;
	eval { $res = $tool->on_key_press($item, $target, $ev); };
	if (my $e = $@) {
		warn "Tool crashed on key_press: $e";
		$mgr->drawing_tool->release_focus($item, $ev);
		return FALSE;
	}
	return $res;
}

sub event_item_on_button_press {
	my ($mgr, $item, $target, $ev, $select) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return FALSE unless $tool;
	my $res;
	eval { $res = $tool->on_button_press($item, $target, $ev, $select); };
	if (my $e = $@) {
		warn "Tool crashed on button_press: $e";
		$mgr->drawing_tool->release_focus($item, $ev);
		return FALSE;
	}
	return $res;
}

sub event_item_on_button_release {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return FALSE unless $tool;
	my $res;
	eval { $res = $tool->on_button_release($item, $target, $ev); };
	if (my $e = $@) {
		warn "Tool crashed on button_release: $e";
		$mgr->drawing_tool->release_focus($item, $ev);
		return FALSE;
	}
	return $res;
}

sub event_item_on_enter_notify {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_enter_notify($item, $target, $ev) if $tool;
	return FALSE;
}

sub event_item_on_leave_notify {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_leave_notify($item, $target, $ev) if $tool;
	return FALSE;
}

1;
