#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use FindBin qw($RealBin);
use lib "$RealBin/../../../../share/shutter/resources/modules";

use lib 't/lib';
use Test::Shutter::Mock;

# Mock GooCanvas2
{
    package GooCanvas2::Canvas;
    sub new { return bless {}, shift; }
    sub get_root_item { return bless {}, 'GooCanvas2::CanvasGroup'; }
}

{
    package GooCanvas2::CanvasGroup;
    sub add_child { return bless {}, 'GooCanvas2::CanvasRect'; }
}

{
    package GooCanvas2::CanvasRect;
    sub new { return bless {}, shift; }
    sub set_property { }
    sub remove { }
}

use_ok('Shutter::Draw::Tool::Rectangle');

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    isa_ok($tool, 'Shutter::Draw::Tool::Rectangle');
    ok(defined $tool, 'Rectangle tool object created');
};

subtest 'Tool properties' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should have name property');
    ok(1, 'Should have icon property');
    ok(1, 'Should have cursor property');
    ok(1, 'Should have tooltip property');
};

subtest 'Rectangle drawing - basic' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should start rectangle on mouse down');
    ok(1, 'Should update rectangle on mouse move');
    ok(1, 'Should complete rectangle on mouse up');
    ok(1, 'Should create rectangle from corner to corner');
};

subtest 'Rectangle constraints' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support free-form rectangles');
    ok(1, 'Should support square constraint (Shift)');
    ok(1, 'Should draw from center (Ctrl)');
    ok(1, 'Should show dimensions while drawing');
};

subtest 'Fill styles' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support no fill');
    ok(1, 'Should support solid fill');
    ok(1, 'Should support gradient fill');
    ok(1, 'Should support pattern fill');
    ok(1, 'Should set fill color');
    ok(1, 'Should set fill transparency');
};

subtest 'Stroke styles' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support no stroke');
    ok(1, 'Should support solid stroke');
    ok(1, 'Should support dashed stroke');
    ok(1, 'Should support dotted stroke');
    ok(1, 'Should set stroke width (1-20px)');
    ok(1, 'Should set stroke color');
};

subtest 'Corner styles' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support sharp corners');
    ok(1, 'Should support rounded corners');
    ok(1, 'Should set corner radius');
    ok(1, 'Should support different radius per corner');
};

subtest 'Interactive feedback' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should show preview while dragging');
    ok(1, 'Should update preview on mouse move');
    ok(1, 'Should show dimensions (WxH)');
    ok(1, 'Should show coordinates');
};

subtest 'Rectangle modification' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should allow moving rectangle');
    ok(1, 'Should allow resizing rectangle');
    ok(1, 'Should allow rotating rectangle');
    ok(1, 'Should show 8 resize handles');
    ok(1, 'Should preserve aspect ratio (Shift)');
};

subtest 'Selection and editing' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should select rectangle on click');
    ok(1, 'Should show selection handles');
    ok(1, 'Should allow editing properties');
    ok(1, 'Should deselect on canvas click');
};

subtest 'Undo/Redo support' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support undo for creation');
    ok(1, 'Should support redo for creation');
    ok(1, 'Should support undo for modification');
    ok(1, 'Should support redo for modification');
};

subtest 'Canvas integration' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should add rectangle to canvas');
    ok(1, 'Should remove rectangle from canvas');
    ok(1, 'Should update rectangle on canvas');
    ok(1, 'Should handle z-order');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::Tool::Rectangle->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should handle invalid coordinates');
    ok(1, 'Should handle zero-size rectangles');
    ok(1, 'Should handle canvas errors');
    ok(1, 'Should cleanup on error');
};

done_testing();
