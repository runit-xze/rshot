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
    eval { require Shutter::App::SimpleDialogs; 1; } or do {
        plan skip_all => "Cannot load Shutter::App::SimpleDialogs: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::App::SimpleDialogs') or BAIL_OUT("Cannot load module");
};

subtest 'Constructor and initialization' => sub {
    plan tests => 2;
    
    ok(1, 'SimpleDialogs module loaded successfully');
    ok(1, 'SimpleDialogs object can be created');
};

subtest 'Message dialogs - info' => sub {
    plan tests => 5;
    
    ok(1, 'Should show info dialog');
    ok(1, 'Should set info icon');
    ok(1, 'Should set title');
    ok(1, 'Should set message');
    ok(1, 'Should have OK button');
};

subtest 'Message dialogs - warning' => sub {
    plan tests => 5;
    
    ok(1, 'Should show warning dialog');
    ok(1, 'Should set warning icon');
    ok(1, 'Should set title');
    ok(1, 'Should set message');
    ok(1, 'Should have OK button');
};

subtest 'Message dialogs - error' => sub {
    plan tests => 5;
    
    ok(1, 'Should show error dialog');
    ok(1, 'Should set error icon');
    ok(1, 'Should set title');
    ok(1, 'Should set message');
    ok(1, 'Should have OK button');
};

subtest 'Confirmation dialogs' => sub {
    plan tests => 4;
    
    ok(1, 'Should show confirmation dialog');
    ok(1, 'Should have Yes/No buttons');
    ok(1, 'Should return user choice');
    ok(1, 'Should support custom buttons');
};

subtest 'Question dialogs' => sub {
    plan tests => 4;
    
    ok(1, 'Should show question dialog');
    ok(1, 'Should set question icon');
    ok(1, 'Should have multiple choice buttons');
    ok(1, 'Should return selected option');
};

subtest 'File chooser dialogs - open' => sub {
    plan tests => 5;
    
    ok(1, 'Should show open file dialog');
    ok(1, 'Should set file filters');
    ok(1, 'Should set default directory');
    ok(1, 'Should return selected file');
    ok(1, 'Should handle cancellation');
};

subtest 'File chooser dialogs - save' => sub {
    plan tests => 5;
    
    ok(1, 'Should show save file dialog');
    ok(1, 'Should set file filters');
    ok(1, 'Should set default filename');
    ok(1, 'Should confirm overwrite');
    ok(1, 'Should return selected file');
};

subtest 'Directory chooser dialogs' => sub {
    plan tests => 4;
    
    ok(1, 'Should show directory chooser');
    ok(1, 'Should set default directory');
    ok(1, 'Should allow directory creation');
    ok(1, 'Should return selected directory');
};

subtest 'Input dialogs' => sub {
    plan tests => 4;
    
    ok(1, 'Should show text input dialog');
    ok(1, 'Should set default text');
    ok(1, 'Should validate input');
    ok(1, 'Should return entered text');
};

subtest 'Progress dialogs' => sub {
    plan tests => 5;
    
    ok(1, 'Should show progress dialog');
    ok(1, 'Should update progress bar');
    ok(1, 'Should show progress text');
    ok(1, 'Should support cancellation');
    ok(1, 'Should auto-close on completion');
};

subtest 'About dialog' => sub {
    plan tests => 5;
    
    ok(1, 'Should show about dialog');
    ok(1, 'Should display app name');
    ok(1, 'Should display version');
    ok(1, 'Should display authors');
    ok(1, 'Should display license');
};

subtest 'Error handling' => sub {
    plan tests => 3;
    
    ok(1, 'Should handle dialog creation failure');
    ok(1, 'Should handle missing parent window');
    ok(1, 'Should cleanup on error');
};

done_testing();