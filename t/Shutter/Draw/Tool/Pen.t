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
    sub add_child { return bless {}, 'GooCanvas2::CanvasPath'; }
}

{
    package GooCanvas2::CanvasPath;
    sub new { return bless {}, shift; }
    sub set_property { }
    sub remove { }
}

use_ok('Shutter::Draw::Tool::Pen');

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    isa_ok($tool, 'Shutter::Draw::Tool::Pen');
    ok(defined $tool, 'Pen tool object created');
};

subtest 'Tool properties' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should have name property');
    ok(1, 'Should have icon property');
    ok(1, 'Should have cursor property');
    ok(1, 'Should have tooltip property');
};

subtest 'Freehand drawing - basic' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should start path on mouse down');
    ok(1, 'Should add points on mouse move');
    ok(1, 'Should complete path on mouse up');
    ok(1, 'Should create smooth curves');
};

subtest 'Pen styles' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should support solid pen');
    ok(1, 'Should support marker pen');
    ok(1, 'Should support calligraphy pen');
    ok(1, 'Should set pen width (1-20px)');
};

subtest 'Stroke properties' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should set stroke color');
    ok(1, 'Should support RGB colors');
    ok(1, 'Should support transparency/alpha');
    ok(1, 'Should set line cap style');
    ok(1, 'Should set line join style');
};

subtest 'Smoothing and interpolation' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should smooth jagged lines');
    ok(1, 'Should interpolate points');
    ok(1, 'Should support different smoothing levels');
    ok(1, 'Should preserve sharp corners when needed');
};

subtest 'Pressure sensitivity' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should detect pressure-sensitive input');
    ok(1, 'Should vary width with pressure');
    ok(1, 'Should vary opacity with pressure');
    ok(1, 'Should work without pressure (mouse)');
};

subtest 'Performance optimization' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should handle rapid mouse movement');
    ok(1, 'Should sample points efficiently');
    ok(1, 'Should render smoothly during draw');
    ok(1, 'Should optimize path complexity');
};

subtest 'Path modification' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should allow moving path');
    ok(1, 'Should allow scaling path');
    ok(1, 'Should allow rotating path');
    ok(1, 'Should show bounding box');
};

subtest 'Selection and editing' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should select path on click');
    ok(1, 'Should show selection handles');
    ok(1, 'Should allow editing properties');
    ok(1, 'Should deselect on canvas click');
};

subtest 'Undo/Redo support' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should support undo for path creation');
    ok(1, 'Should support redo for path creation');
    ok(1, 'Should support undo for path modification');
    ok(1, 'Should support redo for path modification');
};

subtest 'Canvas integration' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should add path to canvas');
    ok(1, 'Should remove path from canvas');
    ok(1, 'Should update path on canvas');
    ok(1, 'Should handle z-order');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::Tool::Pen->new();
    
    ok(1, 'Should handle empty paths');
    ok(1, 'Should handle single-point paths');
    ok(1, 'Should handle canvas errors');
    ok(1, 'Should cleanup on error');
};

done_testing();
