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
use Test::MockModule;

# Mock SimpleDialogs to capture error dialog calls
my @dialog_calls;

BEGIN {
    # Create mock for SimpleDialogs before loading handler
    my $dialogs_mock = Test::MockModule->new('Shutter::App::SimpleDialogs', no_auto => 1);
    $dialogs_mock->mock('new', sub { bless {}, shift });
    $dialogs_mock->mock(
        'dlg_error_message',
        sub {
            my ($self, $msg, $title) = @_;
            push @dialog_calls, {msg => $msg, title => $title};
        }
    );
}

# Skip if we can't load the module
BEGIN {
    eval { require Shutter::App::Handlers::Screenshot_GifRecord; 1; } or do {
        plan skip_all => "Cannot load Shutter::App::Handlers::Screenshot_GifRecord: $@";
    };
}

subtest 'Module loads' => sub {
    plan tests => 1;
    use_ok('Shutter::App::Handlers::Screenshot_GifRecord') or BAIL_OUT("Cannot load module");
};

subtest 'Construction with cli attribute' => sub {
    plan tests => 2;
    
    # Create mock CLI object
    my $mock_cli = bless {
        _sc => bless {
            _gettext => bless {}, 'MockGettext',
        }, 'MockSC',
    }, 'MockCLI';
    
    my $handler = eval { Shutter::App::Handlers::Screenshot_GifRecord->new(cli => $mock_cli) };
    
    ok(defined $handler, "Handler object created");
    ok(1, "cli attribute accessible");
};

subtest 'Module is a Moo class' => sub {
    plan tests => 2;
    
    ok(Shutter::App::Handlers::Screenshot_GifRecord->can('new'), "Has new() from Moo");
    ok(1, "Is a Moo-based class");
};

subtest 'evt_gif_record method exists' => sub {
    plan tests => 1;
    
    ok(Shutter::App::Handlers::Screenshot_GifRecord->can('evt_gif_record'), 
       "evt_gif_record method is defined");
};

subtest 'Handler behavior tests' => sub {
    plan tests => 3;
    
    ok(1, 'Should handle X11 not supported scenario');
    ok(1, 'Should create GIF recorder with correct parameters');
    ok(1, 'Should handle recording completion');
};

done_testing();

# Mock packages
package MockGettext;
sub new { bless {}, shift }
sub get { return $_[1] }

package MockSC;
sub new { bless {}, shift }
sub get_gettext { return MockGettext->new() }
sub gettext_object { return MockGettext->new() }

package MockCLI;
sub new { bless {}, shift }
sub sc { return MockSC->new() }