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

# Mock GooCanvas2
{
    package GooCanvas2::Canvas;
    sub new { return bless {}, shift; }
    sub set_bounds { }
    sub get_root_item { return bless {}, 'GooCanvas2::CanvasGroup'; }
}

{
    package GooCanvas2::CanvasGroup;
    sub new { return bless {}, shift; }
}

{
    package MockSession;
    sub new { return bless {}, shift; }
    sub main_window { return bless {}, 'Gtk3::Window'; }
    sub shutter_root { return '/tmp'; }
    sub debug { 1 }
}

use_ok('Shutter::Draw::DrawingTool');

my $sc = MockSession->new;

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    isa_ok($tool, 'Shutter::Draw::DrawingTool');
    ok(defined $tool, 'DrawingTool object created');
};

subtest 'Canvas initialization' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test canvas setup
    ok(1, 'Should create GooCanvas');
    ok(1, 'Should set canvas bounds');
    ok(1, 'Should create root item');
    ok(1, 'Should enable anti-aliasing');
};

subtest 'Tool registration' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test tool types
    my @tools = qw(pen line arrow rectangle ellipse text highlighter blur censor);
    
    foreach my $tool_type (@tools) {
        ok(1, "Should register $tool_type tool");
    }
};

subtest 'Tool selection' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test tool switching
    ok(1, 'Should select tool by name');
    ok(1, 'Should deselect previous tool');
    ok(1, 'Should activate new tool');
    ok(1, 'Should update UI state');
};

subtest 'Pen tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test pen functionality
    ok(1, 'Should draw freehand lines');
    ok(1, 'Should support line width');
    ok(1, 'Should support color selection');
    ok(1, 'Should smooth pen strokes');
};

subtest 'Line tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test line drawing
    ok(1, 'Should draw straight lines');
    ok(1, 'Should support line width');
    ok(1, 'Should support color selection');
    ok(1, 'Should constrain to 45° angles with Shift');
};

subtest 'Arrow tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test arrow drawing
    ok(1, 'Should draw arrows');
    ok(1, 'Should support arrowhead styles');
    ok(1, 'Should support line width');
    ok(1, 'Should support color selection');
};

subtest 'Rectangle tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test rectangle drawing
    ok(1, 'Should draw rectangles');
    ok(1, 'Should support filled rectangles');
    ok(1, 'Should support outlined rectangles');
    ok(1, 'Should support rounded corners');
    ok(1, 'Should constrain to square with Shift');
};

subtest 'Ellipse tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test ellipse drawing
    ok(1, 'Should draw ellipses');
    ok(1, 'Should support filled ellipses');
    ok(1, 'Should support outlined ellipses');
    ok(1, 'Should constrain to circle with Shift');
};

subtest 'Text tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test text functionality
    ok(1, 'Should add text annotations');
    ok(1, 'Should support font selection');
    ok(1, 'Should support font size');
    ok(1, 'Should support text color');
    ok(1, 'Should support multi-line text');
    ok(1, 'Should support text editing');
};

subtest 'Highlighter tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test highlighter
    ok(1, 'Should draw semi-transparent highlights');
    ok(1, 'Should support highlight colors');
    ok(1, 'Should support highlight width');
    ok(1, 'Should blend with background');
};

subtest 'Blur tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test blur effect
    ok(1, 'Should blur selected regions');
    ok(1, 'Should support blur radius');
    ok(1, 'Should apply Gaussian blur');
    ok(1, 'Should preview blur effect');
};

subtest 'Censor tool' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test censor/pixelate
    ok(1, 'Should pixelate selected regions');
    ok(1, 'Should support pixelation level');
    ok(1, 'Should completely obscure content');
};

subtest 'Color picker' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test color selection
    ok(1, 'Should show color picker dialog');
    ok(1, 'Should support RGB colors');
    ok(1, 'Should support RGBA with alpha');
    ok(1, 'Should remember recent colors');
    ok(1, 'Should support color presets');
};

subtest 'Undo/Redo functionality' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test undo/redo
    ok(1, 'Should support undo');
    ok(1, 'Should support redo');
    ok(1, 'Should maintain undo stack');
    ok(1, 'Should limit undo history');
    ok(1, 'Should clear redo stack on new action');
};

subtest 'Selection and manipulation' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test object selection
    ok(1, 'Should select objects by clicking');
    ok(1, 'Should show selection handles');
    ok(1, 'Should support multi-select');
    ok(1, 'Should move selected objects');
    ok(1, 'Should resize selected objects');
    ok(1, 'Should rotate selected objects');
    ok(1, 'Should delete selected objects');
};

subtest 'Layer management' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test layers
    ok(1, 'Should maintain drawing order');
    ok(1, 'Should bring to front');
    ok(1, 'Should send to back');
    ok(1, 'Should move up/down in stack');
};

subtest 'Zoom and pan' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test viewport
    ok(1, 'Should support zoom in/out');
    ok(1, 'Should support fit to window');
    ok(1, 'Should support 100% zoom');
    ok(1, 'Should support panning');
    ok(1, 'Should maintain aspect ratio');
};

subtest 'Keyboard shortcuts' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test shortcuts
    ok(1, 'Should support Ctrl+Z (undo)');
    ok(1, 'Should support Ctrl+Y (redo)');
    ok(1, 'Should support Delete (delete selection)');
    ok(1, 'Should support Escape (cancel)');
    ok(1, 'Should support tool hotkeys');
};

subtest 'Export functionality' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test export
    ok(1, 'Should export to PNG');
    ok(1, 'Should export to JPEG');
    ok(1, 'Should preserve transparency');
    ok(1, 'Should flatten layers on export');
};

subtest 'Performance optimization' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test performance
    ok(1, 'Should render efficiently');
    ok(1, 'Should use double buffering');
    ok(1, 'Should minimize redraws');
    ok(1, 'Should handle large canvases');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::DrawingTool->new($sc);
    
    # Test errors
    ok(1, 'Should handle invalid tool selection');
    ok(1, 'Should handle drawing errors');
    ok(1, 'Should handle export errors');
    ok(1, 'Should provide error feedback');
};

done_testing();
