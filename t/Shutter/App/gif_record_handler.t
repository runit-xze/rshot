use strict;
use warnings;
use v5.40;

use Test::More tests => 5;
use Test::MockModule;

use lib 'share/shutter/resources/modules';

# ---------------------------------------------------------------------------
# Mock all heavy GTK/Glib dependencies before loading anything
# ---------------------------------------------------------------------------
BEGIN {
    unless (eval { require Glib; 1 }) {
        package Glib;
        use constant TRUE  => 1;
        use constant FALSE => 0;
        sub import {
            my $caller = caller;
            no strict 'refs';
            *{"${caller}::TRUE"}  = \&TRUE;
            *{"${caller}::FALSE"} = \&FALSE;
        }
    }
    unless (eval { require Gtk3; 1 }) {
        package Gtk3;
        sub import { 1 }
    }
}

# ---------------------------------------------------------------------------
# Load the modules the handler depends on FIRST, so Moo can set them up,
# THEN mock them.
# ---------------------------------------------------------------------------
require Shutter::Screenshot::SelectorAdvanced;
require Shutter::Screenshot::Window;
require Shutter::Screenshot::GifRecorder;

my $selector_mock = Test::MockModule->new('Shutter::Screenshot::SelectorAdvanced');
$selector_mock->mock('new', sub { bless {}, shift });

my $window_mock = Test::MockModule->new('Shutter::Screenshot::Window');
$window_mock->mock('new', sub { bless {}, shift });

my $gif_recorder_mock = Test::MockModule->new('Shutter::Screenshot::GifRecorder');
$gif_recorder_mock->mock('new', sub {
    my $class = shift;
    bless { @_ }, $class;
});

# Mock SimpleDialogs to capture error dialog calls
my @dialog_calls;
require Shutter::App::SimpleDialogs;
my $dialogs_mock = Test::MockModule->new('Shutter::App::SimpleDialogs');
$dialogs_mock->mock('new', sub { bless {}, shift });
$dialogs_mock->mock('dlg_error_message', sub {
    my ($self, $msg, $title) = @_;
    push @dialog_calls, { msg => $msg, title => $title };
});

# ===== Test 1: require_ok ==================================================
require_ok('Shutter::App::Handlers::Screenshot_GifRecord');

# ===== Test 2: Construction with cli attribute ==============================
subtest "Construction with cli attribute" => sub {
    plan tests => 2;

    my $mock_cli = bless {}, 'MockCLI';
    my $handler = Shutter::App::Handlers::Screenshot_GifRecord->new(
        cli => $mock_cli,
    );

    ok(defined $handler, "Handler object created");
    is($handler->cli, $mock_cli, "cli attribute accessible");
};

# ===== Test 3: Module is a Moo class =======================================
subtest "Module is a Moo class" => sub {
    plan tests => 2;

    ok(Shutter::App::Handlers::Screenshot_GifRecord->can('new'),
       "Has new() from Moo");

    my $handler = Shutter::App::Handlers::Screenshot_GifRecord->new(
        cli => bless({}, 'MockCLI'),
    );
    isa_ok($handler, 'Shutter::App::Handlers::Screenshot_GifRecord');
};

# ===== Test 4: evt_gif_record method exists =================================
subtest "evt_gif_record method exists" => sub {
    plan tests => 1;

    ok(Shutter::App::Handlers::Screenshot_GifRecord->can('evt_gif_record'),
       "evt_gif_record method is defined");
};

# ===== Test 5: x11_supported=false returns early ============================
subtest "x11_supported=false triggers error dialog and returns TRUE" => sub {
    plan tests => 3;

    @dialog_calls = ();  # Reset captured calls

    # Build mock objects for the nested call chain
    {
        package MockGettext2;
        sub new { bless {}, shift }
        sub get { return $_[1] }  # Returns the key as-is
    }
    {
        package MockSC2;
        sub new { bless {}, shift }
        sub get_gettext { return MockGettext2->new() }
    }
    {
        package MockWindow2;
        sub new { bless {}, shift }
    }
    {
        package MockCLI2;
        sub new {
            bless {
                _x11_supported => 0,
                _hide_active   => undef,
            }, shift;
        }
        sub sc     { return MockSC2->new() }
        sub window { return MockWindow2->new() }
    }

    my $handler = Shutter::App::Handlers::Screenshot_GifRecord->new(
        cli => MockCLI2->new(),
    );

    my $result = $handler->evt_gif_record(undef, 'gif_select', '/tmp', undef);

    is($result, 1, "evt_gif_record returns TRUE (early exit)");
    is(scalar @dialog_calls, 1, "Exactly one error dialog shown");
    like($dialog_calls[0]->{msg}, qr/X11/i,
         "Error message mentions X11");
};

done_testing();
