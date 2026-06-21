package Shutter::Draw::MouseManager;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

sub event_item_on_motion_notify ($mgr, $item, $target, $ev) {
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_motion_notify($item, $target, $ev) if $tool;
	return FALSE;
}

sub event_item_on_key_press ($mgr, $item, $target, $ev) {
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_key_press($item, $target, $ev) if $tool;
	return FALSE;
}

sub event_item_on_button_press ($mgr, $item, $target, $ev, $select) {
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_button_press($item, $target, $ev, $select) if $tool;
	return FALSE;
}

sub event_item_on_button_release ($mgr, $item, $target, $ev) {
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_button_release($item, $target, $ev) if $tool;
	return FALSE;
}

sub event_item_on_enter_notify ($mgr, $item, $target, $ev) {
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_enter_notify($item, $target, $ev) if $tool;
	return FALSE;
}

sub event_item_on_leave_notify ($mgr, $item, $target, $ev) {
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_leave_notify($item, $target, $ev) if $tool;
	return FALSE;
}

1;
