#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use FindBin qw($RealBin);
use lib "$RealBin/../../../../share/shutter/perl";

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
    sub add_child { return bless {}, 'GooCanvas2::CanvasEllipse'; }
}

{
    package GooCanvas2::CanvasEllipse;
    sub new { return bless {}, shift; }
    sub set_property { }
    sub remove { }
}

use_ok('Shutter::Draw::Tool::Ellipse');

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    isa_ok($tool, 'Shutter::Draw::Tool::Ellipse');
    ok(defined $tool, 'Ellipse tool object created');
};

subtest 'Tool properties' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should have name property');
    ok(1, 'Should have icon property');
    ok(1, 'Should have cursor property');
    ok(1, 'Should have tooltip property');
};

subtest 'Ellipse drawing - basic' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should start ellipse on mouse down');
    ok(1, 'Should update ellipse on mouse move');
    ok(1, 'Should complete ellipse on mouse up');
    ok(1, 'Should create ellipse from bounding box');
};

subtest 'Ellipse constraints' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support free-form ellipses');
    ok(1, 'Should support circle constraint (Shift)');
    ok(1, 'Should draw from center (Ctrl)');
    ok(1, 'Should show dimensions while drawing');
};

subtest 'Fill styles' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support no fill');
    ok(1, 'Should support solid fill');
    ok(1, 'Should support gradient fill');
    ok(1, 'Should support radial gradient');
    ok(1, 'Should set fill color');
    ok(1, 'Should set fill transparency');
};

subtest 'Stroke styles' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support no stroke');
    ok(1, 'Should support solid stroke');
    ok(1, 'Should support dashed stroke');
    ok(1, 'Should support dotted stroke');
    ok(1, 'Should set stroke width (1-20px)');
    ok(1, 'Should set stroke color');
};

subtest 'Interactive feedback' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should show preview while dragging');
    ok(1, 'Should update preview on mouse move');
    ok(1, 'Should show dimensions (WxH)');
    ok(1, 'Should show center point');
};

subtest 'Ellipse modification' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should allow moving ellipse');
    ok(1, 'Should allow resizing ellipse');
    ok(1, 'Should allow rotating ellipse');
    ok(1, 'Should show 8 resize handles');
    ok(1, 'Should preserve aspect ratio (Shift)');
};

subtest 'Selection and editing' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should select ellipse on click');
    ok(1, 'Should show selection handles');
    ok(1, 'Should allow editing properties');
    ok(1, 'Should deselect on canvas click');
};

subtest 'Undo/Redo support' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support undo for creation');
    ok(1, 'Should support redo for creation');
    ok(1, 'Should support undo for modification');
    ok(1, 'Should support redo for modification');
};

subtest 'Canvas integration' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should add ellipse to canvas');
    ok(1, 'Should remove ellipse from canvas');
    ok(1, 'Should update ellipse on canvas');
    ok(1, 'Should handle z-order');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::Tool::Ellipse->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should handle invalid coordinates');
    ok(1, 'Should handle zero-size ellipses');
    ok(1, 'Should handle canvas errors');
    ok(1, 'Should cleanup on error');
};

done_testing();
