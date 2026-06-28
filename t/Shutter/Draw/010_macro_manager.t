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

require_ok('Shutter::Draw::MacroManager');
require_ok('Shutter::Draw::DrawingTool');

# Helper: create a mock GooCanvas2 item with overridable isa
sub _make_mock_item {
	my ($class, $props) = @_;
	$props //= {};
	return bless {
		_props      => $props,
		_can_isa    => $class,
		_dummy_data => {},
	}, 'MockGooCanvasItem';
}

package MockGooCanvasItem {
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

package main;

# Gtk3::UIManager and Gtk3::Widget packages exist from use Gtk3 above.
# We need to mock get_widget/set_sensitive because there's no .pm file for
# Test::MockModule to load. Use direct package manipulation instead.
BEGIN {
	# Save originals
	my $orig_get_widget = \&Gtk3::UIManager::get_widget;
	my $orig_set_sensitive = \&Gtk3::Widget::set_sensitive;

	# Override
	*Gtk3::UIManager::get_widget = sub { bless { _sensitive => 1 }, 'Gtk3::Widget' };
	*Gtk3::Widget::set_sensitive  = sub { shift; 1 };

	# Restore on exit
	END {
		*Gtk3::UIManager::get_widget = $orig_get_widget if $orig_get_widget;
		*Gtk3::Widget::set_sensitive = $orig_set_sensitive if $orig_set_sensitive;
	}
}

# Helper: build a minimal mocked DrawingTool for MacroManager
# We mock the constructor to avoid running the real BUILD which requires Gtk3 widgets
sub _build_mock_dt {
	my $items = {};

	# Mock DrawingTool::new so we can create a lightweight instance
	# Pre-bless _canvas_bg and _canvas_bg_rect with mock items to avoid crashes
	my $bg_item = _make_mock_item('GooCanvas2::CanvasImage', {});

	my $ui_mgr  = bless {}, 'Gtk3::UIManager';
	my $bg_rect = _make_mock_item('GooCanvas2::CanvasRect', {});

	my $mock_new = Test::MockModule->new('Shutter::Draw::DrawingTool');
	$mock_new->mock('new', sub {
		my $cls = shift;
		my $self = bless {
			_items          => $items,
			_undo           => [],
			_redo           => [],
			_uimanager      => $ui_mgr,
			_canvas_bg      => $bg_item,
			_canvas_bg_rect => $bg_rect,
			_drawing_pixbuf => undef,
		}, $cls;

		# Attach real MacroManager
		$self->{_macro_manager} = Shutter::Draw::MacroManager->new(drawing_tool => $self);
		return $self;
	});

	my $dt = Shutter::Draw::DrawingTool->new();
	$mock_new->unmock_all();

	return $dt;
}

subtest "store_to_xdo_stack stores undo entry for CanvasRect items" => sub {
	my $dt = _build_mock_dt();

	my $item = _make_mock_item('GooCanvas2::CanvasRect', {
		'x'      => 10,
		'y'      => 20,
		'width'  => 100,
		'height' => 200,
		'line-width' => 3,
	});

	$dt->_items->{$item} = $item;
	$dt->_items->{$item}{stroke_color} = 'red';
	$dt->_items->{$item}{fill_color}   = 'blue';

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'create', 'undo');

	is(scalar @{$dt->_undo}, 1, "one entry in undo stack");
	my $entry = $dt->_undo->[0];
	is($entry->{action}, 'create', "action stored correctly");
	is($entry->{x}, 10, "x stored");
	is($entry->{y}, 20, "y stored");
	is($entry->{'line-width'}, 3, "line-width stored");
	is($entry->{stroke_color}, 'red', "stroke_color stored");
	is($entry->{fill_color}, 'blue', "fill_color stored");
};

subtest "store_to_xdo_stack stores redo entry" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {
		'x' => 10, 'y' => 20, 'width' => 100, 'height' => 200,
	});
	$dt->_items->{$item} = $item;

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'modify', 'redo');

	is(scalar @{$dt->_redo}, 1, "one entry in redo stack");
	is($dt->_redo->[0]->{action}, 'modify', "redo action stored");
	is(scalar @{$dt->_undo}, 0, "undo stack untouched");
};

subtest "store_to_xdo_stack clears redo on new undo (non-ui source)" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {});
	$dt->_items->{$item} = $item;

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'modify', 'redo');
	$mm->store_to_xdo_stack($item, 'create', 'undo');

	is(scalar @{$dt->_redo}, 0, "redo cleared on new undo action");
	is(scalar @{$dt->_undo}, 1, "undo has new entry");
};

subtest "store_to_xdo_stack preserves redo when source is ui" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {});
	$dt->_items->{$item} = $item;

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'modify', 'redo');
	$mm->store_to_xdo_stack($item, 'create', 'undo', undef, 'ui');

	is(scalar @{$dt->_redo}, 1, "redo preserved when source is 'ui'");
	is(scalar @{$dt->_undo}, 1, "undo has new entry");
};

subtest "xdo_remove removes matching entries from undo stack" => sub {
	my $dt = _build_mock_dt();
	my $item1 = _make_mock_item('GooCanvas2::CanvasRect', {});
	my $item2 = _make_mock_item('GooCanvas2::CanvasRect', {});
	$dt->_items->{$item1} = $item1;
	$dt->_items->{$item2} = $item2;

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item1, 'create', 'undo');
	$mm->store_to_xdo_stack($item2, 'create', 'undo');
	$mm->store_to_xdo_stack($item1, 'modify', 'undo');

	is(scalar @{$dt->_undo}, 3, "three undo entries before remove");
	$mm->xdo_remove('undo', $item1);
	is(scalar @{$dt->_undo}, 1, "one entry left after removing item1");
	is($dt->_undo->[0]->{item}, $item2, "remaining entry is item2");
};

subtest "xdo_remove removes matching entries from redo stack" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {});
	$dt->_items->{$item} = $item;

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'modify', 'redo');
	$mm->store_to_xdo_stack($item, 'modify', 'redo');

	is(scalar @{$dt->_redo}, 2, "two redo entries");
	$mm->xdo_remove('redo', $item);
	is(scalar @{$dt->_redo}, 0, "redo emptied after remove");
};

subtest "xdo pops from undo and stores reverse action to redo" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {
		'x' => 10, 'y' => 20, 'width' => 100, 'height' => 200,
	});

	# xdo() sets _current_item, so we need _items to have a key
	# that .isa check passes. Since xdo checks $item->isa('GooCanvas2::CanvasRect')
	# when action eq 'modify', we need a rect item in _items.
	$dt->_items->{$item} = $item;
	$dt->_items->{$item}{stroke_color} = 'red';
	$dt->_items->{$item}{fill_color}   = 'blue';

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'modify', 'undo');

	is(scalar @{$dt->_undo}, 1, "one undo entry before xdo");

	# Mock the methods xdo() calls on drawing_tool to avoid crashes
	my $mock_dt = Test::MockModule->new('Shutter::Draw::DrawingTool');
	$mock_dt->mock('handle_rects', sub { return 1 });
	$mock_dt->mock('handle_embedded', sub { return 1 });
	$mock_dt->mock('set_and_save_drawing_properties', sub { return 1 });
	$mock_dt->mock('handle_bg_rects', sub { return 1 });
	$mock_dt->mock('deactivate_all', sub { return 1 });
	$mock_dt->mock('get_child_item', sub { return undef });
	$mock_dt->mock('get_parent_item', sub { return undef });

	$mm->xdo('undo');

	is(scalar @{$dt->_undo}, 0, "undo popped");
	is(scalar @{$dt->_redo}, 1, "reverse action stored to redo");
	is($dt->_redo->[0]->{action}, 'modify', "reverse action is 'modify'");

	$mock_dt->unmock_all();
};

subtest "xdo with 'create' action stores 'delete_xdo' reverse" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {
		'x' => 10, 'y' => 20, 'width' => 100, 'height' => 200,
	});
	$dt->_items->{$item} = $item;
	$dt->_items->{$item}{stroke_color} = 'red';
	$dt->_items->{$item}{fill_color}   = 'blue';

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'create', 'undo');

	my $mock_dt = Test::MockModule->new('Shutter::Draw::DrawingTool');
	$mock_dt->mock('handle_rects', sub { return 1 });
	$mock_dt->mock('handle_embedded', sub { return 1 });
	$mock_dt->mock('deactivate_all', sub { return 1 });
	$mock_dt->mock('get_parent_item', sub { return undef });
	$mock_dt->mock('get_child_item', sub { return undef });

	$mm->xdo('undo');

	is($dt->_redo->[0]->{action}, 'delete_xdo', "reverse action for 'create' is 'delete_xdo'");

	$mock_dt->unmock_all();
};

subtest "empty stack does not crash" => sub {
	my $dt = _build_mock_dt();
	my $mm = $dt->_macro_manager;

	my $result = $mm->xdo('undo');
	is($result, FALSE, "xdo on empty stack returns FALSE");

	$result = $mm->xdo('redo');
	is($result, FALSE, "xdo on empty redo stack returns FALSE");
};

subtest "store_to_xdo_stack handles CanvasPolyline items" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasPolyline', {
		'points'     => '0,0 100,0 100,100',
		'line-width' => 2,
	});
	$dt->_items->{$item} = $item;
	$dt->_items->{$item}{stroke_color} = 'green';

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'modify', 'undo');

	is(scalar @{$dt->_undo}, 1, "polyline entry stored");
	is($dt->_undo->[0]->{points}, '0,0 100,0 100,100', "polyline points stored");
	is($dt->_undo->[0]->{'line-width'}, 2, "polyline line-width stored");
};

subtest "store_to_xdo_stack handles CanvasImage (canvas_bg)" => sub {
	my $dt = _build_mock_dt();
	my $bg_item = _make_mock_item('GooCanvas2::CanvasImage', {});
	$dt->_canvas_bg($bg_item);
	$dt->_canvas_bg_rect(_make_mock_item('GooCanvas2::CanvasRect', {
		'x' => 0, 'y' => 0, 'width' => 800, 'height' => 600,
	}));
	$dt->_drawing_pixbuf('fake_pixbuf');

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($bg_item, 'modify', 'undo');

	is(scalar @{$dt->_undo}, 1, "canvas_bg entry stored");
	is($dt->_undo->[0]->{action}, 'modify', "canvas_bg action correct");
	is($dt->_undo->[0]->{drawing_pixbuf}, 'fake_pixbuf', "canvas_bg pixbuf stored");
};

subtest "store_to_xdo_stack handles CanvasRect (canvas_bg_rect)" => sub {
	my $dt = _build_mock_dt();
	my $bg_rect = _make_mock_item('GooCanvas2::CanvasRect', {
		'x' => 0, 'y' => 0, 'width' => 800, 'height' => 600,
	});
	$dt->_canvas_bg_rect($bg_rect);

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($bg_rect, 'modify', 'undo');

	is(scalar @{$dt->_undo}, 1, "canvas_bg_rect entry stored");
	is($dt->_undo->[0]->{x}, 0, "canvas_bg_rect x stored");
	is($dt->_undo->[0]->{width}, 800, "canvas_bg_rect width stored");
};

subtest "xdo with block_reverse skips reverse storage" => sub {
	my $dt = _build_mock_dt();
	my $item = _make_mock_item('GooCanvas2::CanvasRect', {
		'x' => 10, 'y' => 20, 'width' => 100, 'height' => 200,
	});
	$dt->_items->{$item} = $item;
	$dt->_items->{$item}{stroke_color} = 'red';
	$dt->_items->{$item}{fill_color}   = 'blue';

	my $mm = $dt->_macro_manager;
	$mm->store_to_xdo_stack($item, 'modify', 'undo');

	my $mock_dt = Test::MockModule->new('Shutter::Draw::DrawingTool');
	$mock_dt->mock('handle_rects', sub { return 1 });
	$mock_dt->mock('handle_embedded', sub { return 1 });
	$mock_dt->mock('set_and_save_drawing_properties', sub { return 1 });
	$mock_dt->mock('handle_bg_rects', sub { return 1 });
	$mock_dt->mock('deactivate_all', sub { return 1 });
	$mock_dt->mock('get_child_item', sub { return undef });
	$mock_dt->mock('get_parent_item', sub { return undef });

	$mm->xdo('undo', undef, TRUE);

	is(scalar @{$dt->_undo}, 0, "undo popped");
	is(scalar @{$dt->_redo}, 0, "no reverse action stored (blocked)");

	$mock_dt->unmock_all();
};

done_testing();
