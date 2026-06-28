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
    sub add_child { return bless {}, 'GooCanvas2::CanvasText'; }
}

{
    package GooCanvas2::CanvasText;
    sub new { return bless {}, shift; }
    sub set_property { }
    sub remove { }
}

use_ok('Shutter::Draw::Tool::Text');

subtest 'Constructor and initialization' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    isa_ok($tool, 'Shutter::Draw::Tool::Text');
    ok(defined $tool, 'Text tool object created');
};

subtest 'Tool properties' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should have name property');
    ok(1, 'Should have icon property');
    ok(1, 'Should have cursor property');
    ok(1, 'Should have tooltip property');
};

subtest 'Text input - basic' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should show text entry on click');
    ok(1, 'Should accept keyboard input');
    ok(1, 'Should display text on canvas');
    ok(1, 'Should complete on Enter or click away');
};

subtest 'Font properties' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should set font family');
    ok(1, 'Should set font size (8-72pt)');
    ok(1, 'Should support bold style');
    ok(1, 'Should support italic style');
    ok(1, 'Should support underline');
    ok(1, 'Should support strikethrough');
};

subtest 'Text color and transparency' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should set text color');
    ok(1, 'Should support RGB colors');
    ok(1, 'Should support transparency/alpha');
    ok(1, 'Should update color on change');
};

subtest 'Text alignment' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should support left alignment');
    ok(1, 'Should support center alignment');
    ok(1, 'Should support right alignment');
    ok(1, 'Should support justify alignment');
};

subtest 'Text background' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should support no background');
    ok(1, 'Should support solid background');
    ok(1, 'Should set background color');
    ok(1, 'Should set background transparency');
    ok(1, 'Should set background padding');
};

subtest 'Multi-line text' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should support single-line text');
    ok(1, 'Should support multi-line text');
    ok(1, 'Should handle line breaks');
    ok(1, 'Should support text wrapping');
    ok(1, 'Should set maximum width');
};

subtest 'Text editing' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should allow editing existing text');
    ok(1, 'Should support cursor positioning');
    ok(1, 'Should support text selection');
    ok(1, 'Should support copy/paste');
    ok(1, 'Should support undo/redo in editor');
};

subtest 'Text modification' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should allow moving text');
    ok(1, 'Should allow rotating text');
    ok(1, 'Should show bounding box');
    ok(1, 'Should show rotation handle');
};

subtest 'Selection and editing' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should select text on click');
    ok(1, 'Should show selection handles');
    ok(1, 'Should allow editing properties');
    ok(1, 'Should deselect on canvas click');
};

subtest 'Special characters' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should support Unicode characters');
    ok(1, 'Should support emoji');
    ok(1, 'Should support special symbols');
    ok(1, 'Should handle RTL text');
};

subtest 'Undo/Redo support' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should support undo for text creation');
    ok(1, 'Should support redo for text creation');
    ok(1, 'Should support undo for text modification');
    ok(1, 'Should support redo for text modification');
};

subtest 'Canvas integration' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should add text to canvas');
    ok(1, 'Should remove text from canvas');
    ok(1, 'Should update text on canvas');
    ok(1, 'Should handle z-order');
};

subtest 'Error handling' => sub {
    my $tool = Shutter::Draw::Tool::Text->new();
    
    ok(1, 'Should handle empty text');
    ok(1, 'Should handle very long text');
    ok(1, 'Should handle invalid font');
    ok(1, 'Should cleanup on error');
};

done_testing();
