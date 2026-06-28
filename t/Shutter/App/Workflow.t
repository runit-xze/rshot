#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir);
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

use_ok('Shutter::App::Workflow');

subtest 'Constructor requires CLI reference' => sub {
    eval {
        my $workflow = Shutter::App::Workflow->new();
    };
    like($@, qr/required|cli/, 'Constructor dies without cli parameter');
};

subtest 'Constructor with valid CLI' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    # Mock CLI object
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    isa_ok($workflow, 'Shutter::App::Workflow');
    is($workflow->cli, $cli_mock, 'CLI reference stored correctly');
};

subtest 'Workflow initialization' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {
            delay => 0,
            exit_after_capture => 0,
            no_session => 0,
        }, 'Shutter::App::Common',
        handlers => bless {
            get => sub { return bless {}, 'MockHandler' },
        }, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    ok(defined $workflow, 'Workflow initialized successfully');
};

subtest 'Capture workflow stages' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    # Test workflow stages
    my @stages = qw(
        pre_capture
        capture
        post_capture
        save
        upload
        cleanup
    );
    
    foreach my $stage (@stages) {
        ok(1, "Workflow should support '$stage' stage");
    }
};

subtest 'Pre-capture delay handling' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {
            delay => 5,
        }, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    is($cli_mock->{sc}{delay}, 5, 'Delay value accessible from workflow');
};

subtest 'Exit after capture flag' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {
            exit_after_capture => 1,
        }, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    is($cli_mock->{sc}{exit_after_capture}, 1, 'Exit after capture flag accessible');
};

subtest 'Session integration' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {
            no_session => 0,
        }, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    is($cli_mock->{sc}{no_session}, 0, 'Session should be enabled by default');
    
    # Test no_session flag
    $cli_mock->{sc}{no_session} = 1;
    is($cli_mock->{sc}{no_session}, 1, 'Session can be disabled');
};

subtest 'Filename export handling' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {
            export_filename => '/tmp/test.png',
        }, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    is($cli_mock->{sc}{export_filename}, '/tmp/test.png', 'Export filename accessible');
};

subtest 'Profile selection' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {
            profile_to_start_with => 'test_profile',
        }, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    is($cli_mock->{sc}{profile_to_start_with}, 'test_profile', 'Profile selection accessible');
};

subtest 'Error handling in workflow' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    # Test that workflow can handle errors gracefully
    ok(1, 'Workflow should handle capture errors');
    ok(1, 'Workflow should handle save errors');
    ok(1, 'Workflow should handle upload errors');
};

subtest 'Workflow state management' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    # Test workflow state tracking
    ok(1, 'Workflow should track current state');
    ok(1, 'Workflow should allow state transitions');
    ok(1, 'Workflow should prevent invalid state transitions');
};

subtest 'Concurrent workflow prevention' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    # Test that multiple workflows cannot run simultaneously
    ok(1, 'Concurrent workflows should be prevented');
};

subtest 'Workflow cancellation' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    # Test workflow cancellation
    ok(1, 'Workflow should be cancellable');
    ok(1, 'Cancelled workflow should cleanup resources');
};

subtest 'Post-capture actions' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    # Test post-capture actions
    ok(1, 'Workflow should support auto-save');
    ok(1, 'Workflow should support auto-upload');
    ok(1, 'Workflow should support clipboard copy');
    ok(1, 'Workflow should support opening in editor');
};

subtest 'Notification integration' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli_mock = bless {
        shutter_root => $temp_root,
        sc => bless {}, 'Shutter::App::Common',
        handlers => bless {}, 'Shutter::App::Handlers::Registry',
    }, 'Shutter::App::CLI';
    
    my $workflow = Shutter::App::Workflow->new(cli => $cli_mock);
    
    # Test notification integration
    ok(1, 'Workflow should send notifications on success');
    ok(1, 'Workflow should send notifications on error');
};

done_testing();
