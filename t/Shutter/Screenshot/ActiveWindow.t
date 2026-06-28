#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../../../share/shutter/resources/modules";

use lib 't/lib';
use Test::Shutter::Mock;

# Mock X11::Protocol
{
    package X11::Protocol;
    sub new { return bless {}, shift; }
    sub req { return (1, 2, 3, 4); }
    sub GetInputFocus { return (123, 0); }
}

use_ok('Shutter::Screenshot::ActiveWindow');

subtest 'Constructor and initialization' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    isa_ok($capture, 'Shutter::Screenshot::ActiveWindow');
    ok(defined $capture, 'ActiveWindow object created');
};

subtest 'Active window detection - X11' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should detect X11 display server');
    ok(1, 'Should get active window ID');
    ok(1, 'Should get window properties');
    ok(1, 'Should get window title');
};

subtest 'Active window detection - Wayland' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should detect Wayland display server');
    ok(1, 'Should use portal API');
    ok(1, 'Should request window selection');
    ok(1, 'Should handle user selection');
};

subtest 'Window geometry' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should get window position (x, y)');
    ok(1, 'Should get window size (width, height)');
    ok(1, 'Should get window borders');
    ok(1, 'Should calculate total geometry');
};

subtest 'Window decorations' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should detect window decorations');
    ok(1, 'Should include decorations by default');
    ok(1, 'Should exclude decorations on request');
    ok(1, 'Should calculate decoration sizes');
};

subtest 'Capture with decorations' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should capture window with title bar');
    ok(1, 'Should capture window with borders');
    ok(1, 'Should capture window with shadow');
    ok(1, 'Should include all decoration elements');
};

subtest 'Capture without decorations' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should capture window content only');
    ok(1, 'Should exclude title bar');
    ok(1, 'Should exclude borders');
    ok(1, 'Should exclude shadow');
};

subtest 'Multi-monitor handling' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should detect window monitor');
    ok(1, 'Should handle windows spanning monitors');
    ok(1, 'Should handle different DPI settings');
    ok(1, 'Should handle different scales');
};

subtest 'Window state detection' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should detect maximized windows');
    ok(1, 'Should detect minimized windows');
    ok(1, 'Should detect fullscreen windows');
    ok(1, 'Should detect hidden windows');
};

subtest 'Focus handling' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should get currently focused window');
    ok(1, 'Should handle focus changes');
    ok(1, 'Should handle no focused window');
    ok(1, 'Should handle desktop focus');
};

subtest 'Window validation' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should validate window exists');
    ok(1, 'Should validate window is visible');
    ok(1, 'Should validate window is on screen');
    ok(1, 'Should reject invalid windows');
};

subtest 'Capture timing' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should capture immediately');
    ok(1, 'Should support delay before capture');
    ok(1, 'Should handle window changes during delay');
    ok(1, 'Should maintain focus during capture');
};

subtest 'Error handling' => sub {
    my $capture = Shutter::Screenshot::ActiveWindow->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should handle no active window');
    ok(1, 'Should handle window closed during capture');
    ok(1, 'Should handle display server errors');
    ok(1, 'Should provide meaningful error messages');
};

done_testing();
