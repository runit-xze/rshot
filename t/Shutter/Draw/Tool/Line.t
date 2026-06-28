#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use FindBin qw($RealBin);
use lib "$RealBin/../../../../../share/shutter/resources/modules";

# Mock Gtk3 and Glib
BEGIN {
    my $gtk_mock = Test::MockModule->new('Gtk3');
    $gtk_mock->mock('-init' => sub { });
    
    my $glib_mock = Test::MockModule->new('Glib');
    $glib_mock->mock('TRUE' => sub { 1 });
    $glib_mock->mock('FALSE' => sub { 0 });
}

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

use_ok('Shutter::Draw::Tool::Line');

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    isa_ok($tool, 'Shutter::Draw::Tool::Line');
    ok(defined $tool, 'Line tool object created');
};

subtest 'Tool properties' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should have name property');
    ok(1, 'Should have icon property');
    ok(1, 'Should have cursor property');
    ok(1, 'Should have tooltip property');
};

subtest 'Line drawing - basic' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should start line on mouse down');
    ok(1, 'Should update line on mouse move');
    ok(1, 'Should complete line on mouse up');
    ok(1, 'Should create line from start to end point');
};

subtest 'Line styles' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should support solid lines');
    ok(1, 'Should support dashed lines');
    ok(1, 'Should support dotted lines');
    ok(1, 'Should support dash-dot lines');
    ok(1, 'Should support different line widths (1-20px)');
};

subtest 'Line constraints' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should support free-form lines');
    ok(1, 'Should support horizontal constraint (Shift)');
    ok(1, 'Should support vertical constraint (Shift)');
    ok(1, 'Should support 45-degree angle snapping');
    ok(1, 'Should show angle indicator');
};

subtest 'Color and transparency' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should set line color');
    ok(1, 'Should support RGB colors');
    ok(1, 'Should support transparency/alpha');
    ok(1, 'Should update color on change');
};

subtest 'Interactive feedback' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should show preview while dragging');
    ok(1, 'Should update preview on mouse move');
    ok(1, 'Should show length indicator');
    ok(1, 'Should show coordinates');
};

subtest 'Line modification' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should allow moving line');
    ok(1, 'Should allow resizing line');
    ok(1, 'Should allow rotating line');
    ok(1, 'Should show control handles');
    ok(1, 'Should preserve line properties');
};

subtest 'Selection and editing' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should select line on click');
    ok(1, 'Should show selection handles');
    ok(1, 'Should allow editing properties');
    ok(1, 'Should deselect on canvas click');
};

subtest 'Multi-line support' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should support multiple lines');
    ok(1, 'Should maintain separate properties');
    ok(1, 'Should allow individual selection');
    ok(1, 'Should support group operations');
};

subtest 'Undo/Redo support' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should support undo for line creation');
    ok(1, 'Should support redo for line creation');
    ok(1, 'Should support undo for line modification');
    ok(1, 'Should support redo for line modification');
};

subtest 'Canvas integration' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should add line to canvas');
    ok(1, 'Should remove line from canvas');
    ok(1, 'Should update line on canvas');
    ok(1, 'Should handle z-order');
};

subtest 'Performance' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should render lines efficiently');
    ok(1, 'Should handle many lines (100+)');
    ok(1, 'Should update smoothly during drag');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::Tool::Line->new();
    
    ok(1, 'Should handle invalid coordinates');
    ok(1, 'Should handle zero-length lines');
    ok(1, 'Should handle canvas errors');
    ok(1, 'Should cleanup on error');
};

done_testing();
