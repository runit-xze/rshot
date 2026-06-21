package Shutter::Draw::MouseManager;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

sub event_item_on_motion_notify {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_motion_notify($item, $target, $ev) if $tool;
	return FALSE;
}

sub event_item_on_key_press {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_key_press($item, $target, $ev) if $tool;
	return FALSE;
}

sub event_item_on_button_press {
	my ($mgr, $item, $target, $ev, $select) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_button_press($item, $target, $ev, $select) if $tool;
	return FALSE;
}

sub event_item_on_button_release {
	my ($mgr, $item, $target, $ev) = @_;
	my $tool = $mgr->drawing_tool->current_tool;
	return $tool->on_button_release($item, $target, $ev) if $tool;
	return FALSE;
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
