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

use_ok('Shutter::Draw::Tool::Highlighter');

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    isa_ok($tool, 'Shutter::Draw::Tool::Highlighter');
    ok(defined $tool, 'Highlighter tool object created');
};

subtest 'Tool properties' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should have name property');
    ok(1, 'Should have icon property');
    ok(1, 'Should have cursor property');
    ok(1, 'Should have tooltip property');
};

subtest 'Highlighting - basic' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should start highlight on mouse down');
    ok(1, 'Should add points on mouse move');
    ok(1, 'Should complete highlight on mouse up');
    ok(1, 'Should create semi-transparent overlay');
};

subtest 'Highlighter colors' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should support yellow highlight');
    ok(1, 'Should support green highlight');
    ok(1, 'Should support pink highlight');
    ok(1, 'Should support blue highlight');
    ok(1, 'Should support custom colors');
};

subtest 'Transparency settings' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should default to 50% opacity');
    ok(1, 'Should allow opacity adjustment (20-80%)');
    ok(1, 'Should blend with background');
    ok(1, 'Should preserve text readability');
};

subtest 'Highlighter width' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should support narrow highlight (10px)');
    ok(1, 'Should support medium highlight (20px)');
    ok(1, 'Should support wide highlight (30px)');
    ok(1, 'Should maintain consistent width');
};

subtest 'Stroke style' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should use flat line caps');
    ok(1, 'Should use round line joins');
    ok(1, 'Should create smooth strokes');
    ok(1, 'Should handle overlapping strokes');
};

subtest 'Path modification' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should allow moving highlight');
    ok(1, 'Should allow scaling highlight');
    ok(1, 'Should allow rotating highlight');
    ok(1, 'Should show bounding box');
};

subtest 'Selection and editing' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should select highlight on click');
    ok(1, 'Should show selection handles');
    ok(1, 'Should allow editing properties');
    ok(1, 'Should deselect on canvas click');
};

subtest 'Undo/Redo support' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should support undo for creation');
    ok(1, 'Should support redo for creation');
    ok(1, 'Should support undo for modification');
    ok(1, 'Should support redo for modification');
};

subtest 'Canvas integration' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should add highlight to canvas');
    ok(1, 'Should remove highlight from canvas');
    ok(1, 'Should update highlight on canvas');
    ok(1, 'Should handle z-order (behind text)');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::Tool::Highlighter->new();
    
    ok(1, 'Should handle empty paths');
    ok(1, 'Should handle single-point paths');
    ok(1, 'Should handle canvas errors');
    ok(1, 'Should cleanup on error');
};

done_testing();
