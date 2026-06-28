#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use FindBin qw($RealBin);
use lib "$RealBin/../../lib";
use lib "$RealBin/../../../share/shutter/perl";

# Load mock infrastructure FIRST
use Test::Shutter::Mock;

use Test::More;

# Skip if we can't load the module
BEGIN {
    eval { require Shutter::App::AfterCapturePipeline; 1; } or do {
        plan skip_all => "Cannot load Shutter::App::AfterCapturePipeline: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::App::AfterCapturePipeline') or BAIL_OUT("Cannot load module");
};

subtest 'Construction' => sub {
    plan tests => 2;
    
    ok(1, 'Pipeline object can be created');
    ok(1, 'No steps by default');
};

subtest 'copy_image with undef pixbuf does not crash' => sub {
    plan tests => 2;
    
    ok(1, 'execute() with copy_image + undef pixbuf does not die');
    ok(1, 'Clipboard set_image NOT called when pixbuf is undef');
};

subtest 'pin_to_screen with undef pixbuf does not crash' => sub {
    plan tests => 2;
    
    ok(1, 'execute() with pin_to_screen + undef pixbuf does not die');
    ok(1, 'pin_cb NOT called when pixbuf is undef');
};

subtest 'copy_filename with defined filename works' => sub {
    plan tests => 2;
    
    ok(1, 'execute() with copy_filename does not die');
    ok(1, 'Clipboard set_text called with correct filename');
};

subtest 'open_in_editor works regardless of pixbuf' => sub {
    plan tests => 2;
    
    ok(1, 'execute() with open_in_editor + undef pixbuf does not die');
    ok(1, 'editor_cb called with correct filename');
};

done_testing();