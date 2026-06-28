## no critic (Subroutines::ProhibitExplicitReturnUndef ValuesAndExpressions::ProhibitVersionStrings Modules::ProhibitMultiplePackages Subroutines::ProhibitBuiltinHomonyms Modules::RequireEndWithOne Modules::RequireExplicitPackage Modules::RequireFilenameMatchesPackage NamingConventions::ProhibitAmbiguousNames BuiltinFunctions::ProhibitUniversalIsa)
use 5.010;
use strict;
use warnings;

use Gtk3;
use Glib qw/TRUE FALSE/;
use Test::More;
use Test::MockModule;

use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use lib "$Bin/../../share/shutter/perl";

Gtk3::init;

require_ok('Shutter::Draw::Tool::Base');
require_ok('Shutter::Draw::Tool::Select');
require_ok('Shutter::Draw::DrawingTool');

sub _make_mock_item {
	my ($class, $props) = @_;
	$props //= {};
	return bless {
		_props      => { %$props },
		_can_isa    => $class,
		_visibility => 'visible',
	}, 'MockGCI2';
}

package MockGCI2 {
	sub isa {
		my ($self, $class) = @_;
		return $self->{_can_isa} eq $class ? 1 : UNIVERSAL::isa($self, $class);
	}
	sub get {
		my ($self, $key) = @_;
		return $self->{_props}{$key};
	}
	sub set {
		my ($self, %kv) = @_;
		while (my ($k, $v) = each %kv) { $self->{_props}{$k} = $v }
		return;
	}
	sub lower { return 1 }
	sub raise { return 1 }
	sub translate { return 1 }
}

package MockCanvas2 {
	sub pointer_grab { return 1 }
	sub pointer_ungrab { return 1 }
	sub keyboard_ungrab { return 1 }
	sub grab_focus { return 1 }
	sub set_bounds { return 1 }
	sub get_root_item { return bless { _children => {} }, 'MockRootItem' }
}

package MockRootItem {
	sub find_child { return undef }
	sub remove_child { return 1 }
}

package MockWindow {
	sub get_window { return bless {}, 'MockGdkWindow' }
}

package MockGdkWindow {}

package main;

my $orig_get_widget    = \&Gtk3::UIManager::get_widget;
my $orig_set_sensitive = \&Gtk3::Widget::set_sensitive;
my $orig_event_new     = \&Gtk3::Gdk::Event::new;
my $orig_ce_time       = \&Gtk3::get_current_event_time;
my $orig_cursor_new    = \&Gtk3::Gdk::Cursor::new;
BEGIN {
	*Gtk3::UIManager::get_widget = sub { bless { _sensitive => 1 }, 'Gtk3::Widget' };
	*Gtk3::Widget::set_sensitive = sub { shift; 1 };
	*Gtk3::Gdk::Event::new = sub { my ($c, $t) = @_; return bless { _type => $t }, 'MockEvent' };
	*Gtk3::get_current_event_time = sub { 0 };
	*Gtk3::Gdk::Cursor::new = sub { bless { _type => $_[1] }, 'MockCursor' };
}


package MockEvent {
	sub state  { my $s = shift; $s->{state}  = shift if @_; return $s->{state}  // 0 }
	sub time   { my $s = shift; $s->{time}   = shift if @_; return $s->{time}   // 0 }
	sub window { my $s = shift; $s->{window} = shift if @_; return $s->{window} }
	sub x      { my $s = shift; $s->{x}      = shift if @_; return $s->{x}      // 0 }
	sub y      { my $s = shift; $s->{y}      = shift if @_; return $s->{y}      // 0 }
	sub button { my $s = shift; $s->{button} = shift if @_; return $s->{button} // 1 }
	sub type   { my $s = shift; $s->{type}   = shift if @_; return $s->{type} }
	sub keyval { my $s = shift; $s->{keyval} = shift if @_; return $s->{keyval} }
}

package main;

my $_mock_dt_new;
sub _build_test_tool {
	my $items = {};
	my $bg_rect = _make_mock_item('GooCanvas2::CanvasRect', {});

	my $mock_uim = bless {}, 'Gtk3::UIManager';
	my $mock_cv  = bless {}, 'MockCanvas2';
	my $mock_win = bless {}, 'MockWindow';
	$_mock_dt_new = Test::MockModule->new('Shutter::Draw::DrawingTool');
	$_mock_dt_new->mock('new', sub {
		my $cls = shift;
		return bless {
			_items              => $items,
			_undo               => [],
			_redo               => [],
			_uimanager          => $mock_uim,
			_canvas             => $mock_cv,
			_canvas_bg_rect     => $bg_rect,
			_canvas_bg          => _make_mock_item('GooCanvas2::CanvasImage', {}),
			_drawing_window     => $mock_win,
			_busy               => FALSE,
			_current_item       => undef,
			_current_new_item   => undef,
			_current_mode       => 10,
			_current_mode_descr => 'select',
			_autoscroll         => FALSE,
			_style_bg           => 'mock_style_bg',
		}, $cls;
	});

	my $dt = Shutter::Draw::DrawingTool->new();
	$_mock_dt_new->unmock_all();

	my $mock_dt = Test::MockModule->new('Shutter::Draw::DrawingTool');
	$mock_dt->mock('adjust_rulers', sub { return 1 });
	$mock_dt->mock('push_tool_help_to_statusbar', sub { return 1 });
	$mock_dt->mock('get_parent_item', sub { return undef });
	$mock_dt->mock('get_child_item', sub { return undef });
	$mock_dt->mock('handle_rects', sub { return 1 });
	$mock_dt->mock('handle_bg_rects', sub { return 1 });
	$mock_dt->mock('handle_embedded', sub { return 1 });
	$mock_dt->mock('set_and_save_drawing_properties', sub { return 1 });
	$mock_dt->mock('deactivate_all', sub { return 1 });
	$mock_dt->mock('store_to_xdo_stack', sub { return 1 });
	$mock_dt->mock('acquire_focus', sub { return 1 });
	$mock_dt->mock('release_focus', sub { return 1 });
	$mock_dt->mock('show_status_message', sub { return 1 });
	$mock_dt->mock('show_item_properties', sub { return 1 });
	$mock_dt->mock('set_drawing_action', sub { return 1 });
	$mock_dt->mock('get_item_key', sub { return shift });
	$mock_dt->mock('xdo_remove', sub { return 1 });
	$mock_dt->mock('xdo', sub { return 1 });
	$mock_dt->mock('_current_mode_descr', sub { return 'select' });

	my $tool = Shutter::Draw::Tool::Select->new(drawing_tool => $dt);
	return ($tool, $dt, $mock_dt);
}

sub _make_event {
	my (%props) = @_;
	return bless { %props }, 'MockEvent';
}

sub _cleanup {
	my ($mock_dt) = @_;
	$mock_dt->unmock_all() if $mock_dt;
	return;
}

# Suppress "Argument isn't numeric in numeric ge" warnings from >= comparisons
# that Gtk3::Gdk::ModifierType normally handles via overloading.
no warnings 'numeric';

# --- Tests ---

subtest "on_motion_notify in dragging state calls handle_moving" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', { x => 100, y => 100 });
	$item->{dragging} = TRUE;
	$item->{drag_x} = 50;
	$item->{drag_y} = 50;
	$item->{dragging_start} = 1;
	$dt->_items->{$item} = $item;

	my $move_called = 0;
	my $mock_sel = Test::MockModule->new('Shutter::Draw::Tool::Select');
	$mock_sel->mock('handle_moving', sub { $move_called++; return 1 });

	$tool->on_motion_notify($item, undef, _make_event());

	is($move_called, 1, "handle_moving called");
	is($tool->drawing_tool, $dt, "drawing_tool accessible");
	$mock_sel->unmock_all();
	_cleanup($mock_dt);
};

subtest "on_motion_notify in resizing state calls handle_resizing" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', { x => 100, y => 100 });
	$item->{resizing} = TRUE;
	$item->{res_x} = 50;
	$item->{res_y} = 50;

	$dt->_canvas_bg_rect->{'bottom-side'} = $item;

	my $resize_called = 0;
	my $mock_sel = Test::MockModule->new('Shutter::Draw::Tool::Select');
	$mock_sel->mock('handle_resizing', sub { $resize_called++; return 1 });

	$tool->on_motion_notify($item, undef, _make_event());

	is($resize_called, 1, "handle_resizing called");
	$mock_sel->unmock_all();
	_cleanup($mock_dt);
};

subtest "on_motion_notify without drag/resize pushes status help" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', { x => 42, y => 99 });
	$dt->_items->{$item} = $item;

	my $help_called = 0;
	$mock_dt->mock('push_tool_help_to_statusbar', sub { $help_called++; return 1 });

	$tool->on_motion_notify($item, undef, _make_event(x => 42, y => 99));

	is($help_called, 1, "push_tool_help_to_statusbar called");
	_cleanup($mock_dt);
};

subtest "on_key_press Left moves item" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', { x => 100, y => 100 });
	$dt->_items->{$item} = $item;
	$dt->_current_item($item);

	$tool->on_key_press($item, undef, _make_event(keyval => Gtk3::Gdk::keyval_from_name('Left')));

	is($item->{dragging}, TRUE, "item set as dragging");
	_cleanup($mock_dt);
};

subtest "on_key_press Right moves item" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', { x => 100, y => 100 });
	$dt->_items->{$item} = $item;
	$dt->_current_item($item);

	$tool->on_key_press($item, undef, _make_event(keyval => Gtk3::Gdk::keyval_from_name('Right')));

	is($item->{dragging}, TRUE, "item set as dragging");
	_cleanup($mock_dt);
};

subtest "on_key_press without current item returns TRUE" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	$dt->_current_item(undef);

	my $result = $tool->on_key_press(_make_mock_item('GooCanvas2::CanvasRect', {}), undef,
		_make_event(keyval => Gtk3::Gdk::keyval_from_name('Left')));

	is($result, TRUE, "returns TRUE without crashing");
	_cleanup($mock_dt);
};

subtest "on_key_press unknown key returns FALSE" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', { x => 100, y => 100 });
	$dt->_items->{$item} = $item;
	$dt->_current_item($item);

	my $result = $tool->on_key_press($item, undef,
		_make_event(keyval => Gtk3::Gdk::keyval_from_name('Escape')));

	is($result, FALSE, "unknown key returns FALSE");
	_cleanup($mock_dt);
};

subtest "on_button_press activates item" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {});
	$dt->_items->{$item} = $item;
	$dt->_current_item(undef);

	$tool->on_button_press($item, undef,
		_make_event(type => 'button-press', button => 1, x => 10, y => 20, time => 12345), TRUE);

	is($dt->_busy, TRUE, "canvas marked busy");
	is($dt->_current_item, $item, "item set as current");
	_cleanup($mock_dt);
};

subtest "on_button_press locked item deactivates" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {});
	$dt->_items->{$item} = $item;
	$dt->_items->{$item}{locked} = TRUE;
	$dt->_current_item(undef);

	my $deactivated = 0;
	$mock_dt->mock('deactivate_all', sub { $deactivated++; return 1 });

	$tool->on_button_press($item, undef,
		_make_event(type => 'button-press', button => 1, time => 12345), TRUE);

	is($deactivated, 1, "deactivate_all called for locked item");
	_cleanup($mock_dt);
};

subtest "on_button_release returns TRUE" => sub {
	my ($tool, $dt, $mock_dt) = _build_test_tool();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {});

	$mock_dt->mock('get_child_item', sub { return undef });
	$mock_dt->mock('get_parent_item', sub { return undef });

	my $result = $tool->on_button_release($item, undef,
		_make_event(x => 0, y => 0, x_root => 0, y_root => 0));

	is($result, TRUE, "button release returns TRUE");
	_cleanup($mock_dt);
};

done_testing();
