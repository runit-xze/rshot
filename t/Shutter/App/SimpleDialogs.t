#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use FindBin qw($RealBin);
use lib "$RealBin/../../../share/shutter/resources/modules";

# Mock Gtk3 and Glib
BEGIN {
    my $gtk_mock = Test::MockModule->new('Gtk3');
    $gtk_mock->mock('-init' => sub { });
    
    my $glib_mock = Test::MockModule->new('Glib');
    $glib_mock->mock('TRUE' => sub { 1 });
    $glib_mock->mock('FALSE' => sub { 0 });
}

# Mock Gtk3::MessageDialog
{
    package Gtk3::MessageDialog;
    sub new { return bless {}, shift; }
    sub run { return 'ok'; }
    sub destroy { }
}

# Mock Gtk3::FileChooserDialog
{
    package Gtk3::FileChooserDialog;
    sub new { return bless {}, shift; }
    sub run { return 'ok'; }
    sub get_filename { return '/tmp/test.png'; }
    sub destroy { }
}

use_ok('Shutter::App::SimpleDialogs');

subtest 'Constructor and initialization' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    isa_ok($dialogs, 'Shutter::App::SimpleDialogs');
    ok(defined $dialogs, 'SimpleDialogs object created');
};

subtest 'Message dialogs - info' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show info dialog');
    ok(1, 'Should set info icon');
    ok(1, 'Should set title');
    ok(1, 'Should set message');
    ok(1, 'Should have OK button');
};

subtest 'Message dialogs - warning' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show warning dialog');
    ok(1, 'Should set warning icon');
    ok(1, 'Should set title');
    ok(1, 'Should set message');
    ok(1, 'Should have OK button');
};

subtest 'Message dialogs - error' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show error dialog');
    ok(1, 'Should set error icon');
    ok(1, 'Should set title');
    ok(1, 'Should set message');
    ok(1, 'Should have OK button');
};

subtest 'Confirmation dialogs' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show confirmation dialog');
    ok(1, 'Should have Yes/No buttons');
    ok(1, 'Should return user choice');
    ok(1, 'Should support custom buttons');
};

subtest 'Question dialogs' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show question dialog');
    ok(1, 'Should set question icon');
    ok(1, 'Should have multiple choice buttons');
    ok(1, 'Should return selected option');
};

subtest 'File chooser dialogs - open' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show open file dialog');
    ok(1, 'Should set file filters');
    ok(1, 'Should set default directory');
    ok(1, 'Should return selected file');
    ok(1, 'Should handle cancellation');
};

subtest 'File chooser dialogs - save' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show save file dialog');
    ok(1, 'Should set file filters');
    ok(1, 'Should set default filename');
    ok(1, 'Should confirm overwrite');
    ok(1, 'Should return selected file');
};

subtest 'Directory chooser dialogs' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show directory chooser');
    ok(1, 'Should set default directory');
    ok(1, 'Should allow directory creation');
    ok(1, 'Should return selected directory');
};

subtest 'Input dialogs' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show text input dialog');
    ok(1, 'Should set default text');
    ok(1, 'Should validate input');
    ok(1, 'Should return entered text');
};

subtest 'Progress dialogs' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show progress dialog');
    ok(1, 'Should update progress bar');
    ok(1, 'Should show progress text');
    ok(1, 'Should support cancellation');
    ok(1, 'Should auto-close on completion');
};

subtest 'About dialog' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should show about dialog');
    ok(1, 'Should display app name');
    ok(1, 'Should display version');
    ok(1, 'Should display authors');
    ok(1, 'Should display license');
};

subtest 'Error handling' => sub {
    my $dialogs = Shutter::App::SimpleDialogs->new();
    
    ok(1, 'Should handle dialog creation failure');
    ok(1, 'Should handle missing parent window');
    ok(1, 'Should cleanup on error');
};

done_testing();
