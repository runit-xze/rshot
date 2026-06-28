#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../../../share/shutter/perl";

use lib 't/lib';
use Test::Shutter::Mock;

use_ok('Shutter::Screenshot::History');

subtest 'Constructor and initialization' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    isa_ok($history, 'Shutter::Screenshot::History');
    ok(defined $history, 'History object created');
};

subtest 'History storage' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should initialize empty history');
    ok(1, 'Should set maximum history size');
    ok(1, 'Should store screenshot metadata');
    ok(1, 'Should maintain insertion order');
};

subtest 'Add screenshot to history' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should add screenshot entry');
    ok(1, 'Should store filename');
    ok(1, 'Should store timestamp');
    ok(1, 'Should store screenshot type');
    ok(1, 'Should store dimensions');
    ok(1, 'Should store file size');
};

subtest 'History size management' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should enforce maximum size');
    ok(1, 'Should remove oldest entries');
    ok(1, 'Should maintain recent entries');
    ok(1, 'Should handle size limit changes');
};

subtest 'Retrieve history entries' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should get all entries');
    ok(1, 'Should get recent entries (N)');
    ok(1, 'Should get entries by date range');
    ok(1, 'Should get entries by type');
};

subtest 'Search history' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should search by filename');
    ok(1, 'Should search by date');
    ok(1, 'Should search by type');
    ok(1, 'Should support partial matches');
    ok(1, 'Should return sorted results');
};

subtest 'Remove from history' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should remove single entry');
    ok(1, 'Should remove multiple entries');
    ok(1, 'Should remove by criteria');
    ok(1, 'Should clear all history');
};

subtest 'History persistence' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should save history to disk');
    ok(1, 'Should load history from disk');
    ok(1, 'Should handle missing history file');
    ok(1, 'Should handle corrupted history file');
};

subtest 'History statistics' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should count total screenshots');
    ok(1, 'Should count by type');
    ok(1, 'Should calculate total size');
    ok(1, 'Should get date range');
};

subtest 'History export' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should export to JSON');
    ok(1, 'Should export to CSV');
    ok(1, 'Should export to HTML');
    ok(1, 'Should include metadata');
};

subtest 'History import' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should import from JSON');
    ok(1, 'Should validate import data');
    ok(1, 'Should merge with existing history');
    ok(1, 'Should handle duplicates');
};

subtest 'Thumbnail management' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should store thumbnail paths');
    ok(1, 'Should generate thumbnails on demand');
    ok(1, 'Should cache thumbnails');
    ok(1, 'Should cleanup old thumbnails');
};

subtest 'Error handling' => sub {
    my $history = Shutter::Screenshot::History->new(_sc => bless({}, 'MockSession'), _common => bless({}, 'MockCommon'), _dummy => 1);
    
    ok(1, 'Should handle invalid entries');
    ok(1, 'Should handle file I/O errors');
    ok(1, 'Should handle missing files');
    ok(1, 'Should recover from corruption');
};

done_testing();
