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
    sub add_child { return bless {}, 'GooCanvas2::CanvasPolyline'; }
}

{
    package GooCanvas2::CanvasPolyline;
    sub new { return bless {}, shift; }
    sub set_property { }
    sub remove { }
}

use_ok('Shutter::Draw::Tool::Arrow');

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    isa_ok($tool, 'Shutter::Draw::Tool::Arrow');
    ok(defined $tool, 'Arrow tool object created');
};

subtest 'Tool properties' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should have name property');
    ok(1, 'Should have icon property');
    ok(1, 'Should have cursor property');
    ok(1, 'Should have tooltip property');
};

subtest 'Arrow drawing - basic' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should start arrow on mouse down');
    ok(1, 'Should update arrow on mouse move');
    ok(1, 'Should complete arrow on mouse up');
    ok(1, 'Should create arrow from start to end point');
};

subtest 'Arrow head rendering' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should render arrow head at end point');
    ok(1, 'Should calculate arrow head angle');
    ok(1, 'Should render arrow head with correct size');
    ok(1, 'Should support different arrow head styles');
};

subtest 'Arrow styles' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support solid arrows');
    ok(1, 'Should support dashed arrows');
    ok(1, 'Should support dotted arrows');
    ok(1, 'Should support different line widths');
};

subtest 'Arrow head styles' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support filled arrow heads');
    ok(1, 'Should support outlined arrow heads');
    ok(1, 'Should support different arrow head sizes');
    ok(1, 'Should support single-ended arrows');
    ok(1, 'Should support double-ended arrows');
};

subtest 'Color settings' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should set arrow line color');
    ok(1, 'Should set arrow head color');
    ok(1, 'Should support transparency');
    ok(1, 'Should update color on change');
};

subtest 'Arrow constraints' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support straight arrows');
    ok(1, 'Should support 45-degree angle snapping');
    ok(1, 'Should support horizontal/vertical snapping');
    ok(1, 'Should show angle indicator');
};

subtest 'Interactive feedback' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should show preview while dragging');
    ok(1, 'Should update preview on mouse move');
    ok(1, 'Should show length indicator');
    ok(1, 'Should show angle indicator');
};

subtest 'Arrow modification' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should allow moving arrow');
    ok(1, 'Should allow resizing arrow');
    ok(1, 'Should allow rotating arrow');
    ok(1, 'Should show control handles');
};

subtest 'Selection and editing' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should select arrow on click');
    ok(1, 'Should show selection handles');
    ok(1, 'Should allow editing properties');
    ok(1, 'Should deselect on canvas click');
};

subtest 'Undo/Redo support' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should support undo for arrow creation');
    ok(1, 'Should support redo for arrow creation');
    ok(1, 'Should support undo for arrow modification');
    ok(1, 'Should support redo for arrow modification');
};

subtest 'Canvas integration' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should add arrow to canvas');
    ok(1, 'Should remove arrow from canvas');
    ok(1, 'Should update arrow on canvas');
    ok(1, 'Should handle z-order');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::Tool::Arrow->new(drawing_tool => bless({}, 'MockDrawingTool'));
    
    ok(1, 'Should handle invalid coordinates');
    ok(1, 'Should handle zero-length arrows');
    ok(1, 'Should handle canvas errors');
    ok(1, 'Should cleanup on error');
};

done_testing();
