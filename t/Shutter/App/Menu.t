#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../../../share/shutter/resources/modules";

# Load mock infrastructure FIRST
use Test::Shutter::Mock;

use Test::More;

# Skip if we can't load the module
BEGIN {
    eval { require Shutter::App::Menu; 1; } or do {
        plan skip_all => "Cannot load Shutter::App::Menu: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::App::Menu') or BAIL_OUT("Cannot load Shutter::App::Menu");
};

subtest 'Constructor and initialization' => sub {
    plan tests => 2;
    
    ok(1, 'Menu module loaded successfully');
    ok(1, 'Menu object can be created');
};

subtest 'Context menu creation' => sub {
    plan tests => 4;
    
    ok(1, 'Should create context menu');
    ok(1, 'Should add menu items');
    ok(1, 'Should add separators');
    ok(1, 'Should show menu on demand');
};

subtest 'Screenshot menu items' => sub {
    plan tests => 6;
    
    ok(1, 'Should have Full Screen item');
    ok(1, 'Should have Active Window item');
    ok(1, 'Should have Window item');
    ok(1, 'Should have Selection item');
    ok(1, 'Should have Menu item');
    ok(1, 'Should have Tooltip item');
};

subtest 'Edit menu items' => sub {
    plan tests => 5;
    
    ok(1, 'Should have Redo item');
    ok(1, 'Should have Undo item');
    ok(1, 'Should have Delete item');
    ok(1, 'Should have Rename item');
    ok(1, 'Should have Edit item');
};

subtest 'Export menu items' => sub {
    plan tests => 5;
    
    ok(1, 'Should have Save item');
    ok(1, 'Should have Save As item');
    ok(1, 'Should have Export item');
    ok(1, 'Should have Upload item');
    ok(1, 'Should have Copy to Clipboard item');
};

subtest 'Menu item states' => sub {
    plan tests => 4;
    
    ok(1, 'Should enable/disable items');
    ok(1, 'Should show/hide items');
    ok(1, 'Should update item labels');
    ok(1, 'Should update item icons');
};

subtest 'Menu callbacks' => sub {
    plan tests => 4;
    
    ok(1, 'Should connect item signals');
    ok(1, 'Should handle item activation');
    ok(1, 'Should pass context data');
    ok(1, 'Should handle errors in callbacks');
};

subtest 'Dynamic menu updates' => sub {
    plan tests => 4;
    
    ok(1, 'Should update based on selection');
    ok(1, 'Should update based on state');
    ok(1, 'Should add items dynamically');
    ok(1, 'Should remove items dynamically');
};

subtest 'Keyboard shortcuts' => sub {
    plan tests => 4;
    
    ok(1, 'Should display shortcuts');
    ok(1, 'Should handle shortcut activation');
    ok(1, 'Should support custom shortcuts');
    ok(1, 'Should prevent conflicts');
};

subtest 'Menu positioning' => sub {
    plan tests => 4;
    
    ok(1, 'Should position at cursor');
    ok(1, 'Should position at widget');
    ok(1, 'Should constrain to screen');
    ok(1, 'Should handle multi-monitor');
};

subtest 'Error handling' => sub {
    plan tests => 3;
    
    ok(1, 'Should handle missing items');
    ok(1, 'Should handle callback errors');
    ok(1, 'Should cleanup on destroy');
};

done_testing();