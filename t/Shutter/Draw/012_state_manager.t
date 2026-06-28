## no critic (Modules::RequireEndWithOne Modules::RequireExplicitPackage RegularExpressions::RequireExtendedFormatting)
use 5.010;
use strict;
use warnings;

use Gtk3;
use Locale::gettext;
use Glib qw/TRUE FALSE/;
use Test::More;
use Test::MockModule;

use FindBin qw/$Bin/;
use lib "$Bin/../../lib";
use lib "$Bin/../../share/shutter/perl";

require_ok('Shutter::Draw::StateManager');
require_ok('Shutter::Draw::DrawingTool');

# Stub gettext domain for tests
my $domain = Locale::gettext->domain("shutter");

# Pre-bless objects (avoid nested bless in hash literal)
{ package Gtk3::Statusbar; sub DESTROY {} }
{ package Gtk3::Image; sub DESTROY {} }
{ package Gtk3::UIManager; sub DESTROY {} }
my $_sb = bless {}, 'Gtk3::Statusbar';
my $_img = bless {}, 'Gtk3::Image';
my $_uimgr = bless {}, 'Gtk3::UIManager';

sub _build_mock_dt {
	my $self = bless {
		_start_time           => time(),
		_d                    => $domain,
		_current_mode         => 10,
		_current_mode_descr   => 'select',
		_drawing_statusbar    => $_sb,
		_drawing_statusbar_image => $_img,
		_uimanager            => $_uimgr,
		_undo                 => [],
		_toolbar_manager      => undef,
	}, 'Shutter::Draw::DrawingTool';

	$self->{_state_manager} = Shutter::Draw::StateManager->new(drawing_tool => $self);
	return $self;
}

# Mock DrawingTool::show_status_message so StateManager's push_tool_help_to_statusbar
# doesn't need a real _toolbar_manager. Instead, call the statusbar directly.
my $_mock_dt_sm;
sub _install_statusbar_mocks {
	$_mock_dt_sm = Test::MockModule->new('Shutter::Draw::DrawingTool');
	$_mock_dt_sm->mock('show_status_message', sub {
		my $dt = shift;
		my ($index, $status_text) = @_;
		$dt->{_drawing_statusbar}->push($index, $status_text);
		return 1;
	});
	# push_tool_help_to_statusbar delegates to toolbar_manager — route back to state_manager
	$_mock_dt_sm->mock('push_tool_help_to_statusbar', sub {
		my $dt = shift;
		return $dt->{_state_manager}->push_tool_help_to_statusbar(@_);
	});
	return;
}

BEGIN { _install_statusbar_mocks(); }

# Mock Gtk3::Statusbar::push to capture calls
my @statusbar_pushes;
my $orig_statusbar_push;
BEGIN {
	$orig_statusbar_push = \&Gtk3::Statusbar::push;
	*Gtk3::Statusbar::push = sub { push @statusbar_pushes, [@_[1,2]]; return 1 };
}


# Mock Gtk3::Image::set_from_stock / clear
BEGIN {
	no warnings 'redefine';
	*Gtk3::Image::set_from_stock = sub { return 1 };
	*Gtk3::Image::clear = sub { return 1 };
}

# Mock Gtk3::UIManager::get_widget / Gtk3::Widget::set_sensitive
my $orig_get_widget = \&Gtk3::UIManager::get_widget;
my $orig_set_sensitive = \&Gtk3::Widget::set_sensitive;
BEGIN {
	*Gtk3::UIManager::get_widget = sub { bless { _sensitive => 1 }, 'Gtk3::Widget' };
	*Gtk3::Widget::set_sensitive  = sub { shift; 1 };
}


subtest "push_tool_help_to_statusbar in select mode (10)" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 10;
	$dt->{_current_mode_descr} = 'select';
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(100, 200);

	is(scalar @statusbar_pushes, 1, "one statusbar push");
	like($statusbar_pushes[0]->[1], qr/100 x 200/, "coordinates in status text");
};

subtest "push_tool_help_to_statusbar with resize action" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 10;
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(50, 75, 'resize');

	is(scalar @statusbar_pushes, 1, "statusbar push");
	like($statusbar_pushes[0]->[1], qr/scale/i, "scale hint included");
};

subtest "push_tool_help_to_statusbar with canvas_resize action" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 10;
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(50, 75, 'canvas_resize');

	is(scalar @statusbar_pushes, 1, "statusbar push");
	like($statusbar_pushes[0]->[1], qr/canvas/i, "canvas resize hint");
};

subtest "push_tool_help_to_statusbar in rectangle mode (60)" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 60;
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(10, 20);

	like($statusbar_pushes[0]->[1], qr/Click-Drag.*rectangle/i, "rectangle hint");
};

subtest "push_tool_help_to_statusbar in arrow mode (50)" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 50;
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(10, 20);

	like($statusbar_pushes[0]->[1], qr/Click-Drag.*arrow/i, "arrow hint");
};

subtest "push_tool_help_to_statusbar in text mode (80)" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 80;
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(10, 20);

	like($statusbar_pushes[0]->[1], qr/Click-Drag.*text/i, "text hint");
};

subtest "push_tool_help_to_statusbar in freehand mode (20)" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 20;
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(10, 20);

	like($statusbar_pushes[0]->[1], qr/Click to paint/i, "freehand hint");
};

subtest "push_tool_help_to_statusbar in censor mode (90)" => sub {
	my $dt = _build_mock_dt();
	$dt->{_current_mode} = 90;
	@statusbar_pushes = ();

	$dt->{_state_manager}->push_tool_help_to_statusbar(10, 20);

	like($statusbar_pushes[0]->[1], qr/Click to censor/i, "censor hint");
};

subtest "show_status_message pushes to statusbar" => sub {
	my $dt = _build_mock_dt();
	@statusbar_pushes = ();

	$dt->{_state_manager}->show_status_message(1, "hello world");

	is(scalar @statusbar_pushes, 1, "statusbar push");
	is($statusbar_pushes[0]->[0], 1, "correct context id");
	is($statusbar_pushes[0]->[1], "hello world", "correct message");
};

subtest "show_status_message with stock image" => sub {
	my $dt = _build_mock_dt();
	@statusbar_pushes = ();

	$dt->{_state_manager}->show_status_message(2, "test", 'gtk-ok');

	is(scalar @statusbar_pushes, 1, "statusbar push");
};

subtest "show_status_message without stock image calls clear" => sub {
	my $dt = _build_mock_dt();
	@statusbar_pushes = ();

	$dt->{_state_manager}->show_status_message(1, "no icon");

	is(scalar @statusbar_pushes, 1, "statusbar push");
};

done_testing();
