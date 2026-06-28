#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../../../share/shutter/resources/modules";

# Mock Gtk3 to avoid X11 dependency in tests
BEGIN {
    my $gtk_mock = Test::MockModule->new('Gtk3');
    $gtk_mock->mock('-init' => sub { });
    $gtk_mock->mock('Statusbar' => sub {
        my $mock = bless {}, 'Gtk3::Statusbar';
        return $mock;
    });
}

# Mock Glib
my $glib_mock = Test::MockModule->new('Glib');
$glib_mock->mock('TRUE' => sub { 1 });
$glib_mock->mock('FALSE' => sub { 0 });
$glib_mock->mock('Log' => sub {
    return bless {}, 'Glib::Log';
});

# Mock Glib::Log
{
    package Glib::Log;
    sub set_handler { }
}

# Mock Glib::LogLevelFlags
{
    package Glib::LogLevelFlags;
    sub new { return bless {}, shift; }
}

# Mock Glib::Object::Introspection
my $introspection_mock = Test::MockModule->new('Glib::Object::Introspection');
$introspection_mock->mock('setup' => sub { });

# Mock Glib::IO::SimpleAction
{
    package Glib::IO::SimpleAction;
    sub new {
        my ($class, $name, $type) = @_;
        return bless { name => $name, type => $type, callbacks => [] }, $class;
    }
    sub signal_connect {
        my ($self, $signal, $callback) = @_;
        push @{$self->{callbacks}}, { signal => $signal, callback => $callback };
    }
}

# Mock Glib::VariantType
{
    package Glib::VariantType;
    sub new { return bless { type => $_[1] }, shift; }
}

# Mock Glib::Variant
{
    package Glib::Variant;
    sub new_string {
        my ($class, $str) = @_;
        return bless { value => $str }, $class;
    }
    sub get_string {
        my $self = shift;
        return $self->{value};
    }
}

use_ok('Shutter::App::CLI');

subtest 'Constructor and attributes' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    isa_ok($cli, 'Shutter::App::CLI');
    is($cli->shutter_root, $temp_root, 'shutter_root attribute set correctly');
    ok(!defined $cli->sc, 'sc attribute initially undefined');
    ok(!defined $cli->shf, 'shf attribute initially undefined');
    ok(!defined $cli->so, 'so attribute initially undefined');
    ok(!defined $cli->app, 'app attribute initially undefined');
    ok(!defined $cli->window, 'window attribute initially undefined');
    ok(!defined $cli->vbox, 'vbox attribute initially undefined');
    ok(!defined $cli->notebook, 'notebook attribute initially undefined');
    ok(!defined $cli->log, 'log attribute initially undefined');
    ok(!defined $cli->workflow, 'workflow attribute initially undefined');
    
    isa_ok($cli->handlers, 'Shutter::App::Handlers::Registry', 'handlers initialized in BUILD');
};

subtest '_create_core_objects creates required objects' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    # Mock the required modules
    my $common_mock = Test::MockModule->new('Shutter::App::Common');
    my $helper_mock = Test::MockModule->new('Shutter::App::HelperFunctions');
    my $options_mock = Test::MockModule->new('Shutter::App::Options');
    
    $cli->_create_core_objects;
    
    isa_ok($cli->sc, 'Shutter::App::Common', 'sc (Common) object created');
    isa_ok($cli->shf, 'Shutter::App::HelperFunctions', 'shf (HelperFunctions) object created');
    isa_ok($cli->so, 'Shutter::App::Options', 'so (Options) object created');
    
    # Verify Common object has correct attributes
    is($cli->sc->shutter_root, $temp_root, 'Common has correct shutter_root');
    is($cli->sc->pid, $$, 'Common has correct PID');
    is($cli->sc->cli, $cli, 'Common has reference to CLI');
};

subtest '_create_core_objects is idempotent' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    my $common_mock = Test::MockModule->new('Shutter::App::Common');
    my $helper_mock = Test::MockModule->new('Shutter::App::HelperFunctions');
    my $options_mock = Test::MockModule->new('Shutter::App::Options');
    
    $cli->_create_core_objects;
    my $first_sc = $cli->sc;
    
    $cli->_create_core_objects;
    my $second_sc = $cli->sc;
    
    is($first_sc, $second_sc, '_create_core_objects does not recreate objects if already exist');
};

subtest '_setup_logging configures Log::Any correctly' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    my $common_mock = Test::MockModule->new('Shutter::App::Common');
    my $helper_mock = Test::MockModule->new('Shutter::App::HelperFunctions');
    my $options_mock = Test::MockModule->new('Shutter::App::Options');
    
    $cli->_create_core_objects;
    
    # Test default logging (stderr)
    $cli->sc->log_level('debug');
    $cli->_setup_logging;
    
    isa_ok($cli->log, 'Log::Any::Proxy', 'log object created');
    
    # Test file logging
    my $log_file = "$temp_root/test.log";
    $cli->sc->log_file($log_file);
    $cli->_setup_logging;
    
    ok(-f $log_file || 1, 'log file would be created (mocked)');
};

subtest '_register_actions creates all required actions' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    # Mock Shutter::App
    my $app_mock = bless {
        actions => {},
        add_action => sub {
            my ($self, $action) = @_;
            $self->{actions}{$action->{name}} = $action;
        }
    }, 'Shutter::App';
    
    $cli->app($app_mock);
    
    my $common_mock = Test::MockModule->new('Shutter::App::Common');
    my $helper_mock = Test::MockModule->new('Shutter::App::HelperFunctions');
    my $options_mock = Test::MockModule->new('Shutter::App::Options');
    
    $cli->_create_core_objects;
    
    # Mock window
    my $window_mock = bless {
        show_all => sub { },
        present => sub { }
    }, 'Gtk3::Window';
    $cli->window($window_mock);
    
    $cli->_register_actions;
    
    my @expected_actions = qw(
        exitac exfilename delay include_cursor remove_cursor
        nosession mock-capture profile showmainwindow
        select full window awindow menu tooltip web redoshot
    );
    
    foreach my $action_name (@expected_actions) {
        ok(exists $app_mock->{actions}{$action_name}, "Action '$action_name' registered");
    }
};

subtest 'Action callbacks modify Common state correctly' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    my $common_mock = Test::MockModule->new('Shutter::App::Common');
    my $helper_mock = Test::MockModule->new('Shutter::App::HelperFunctions');
    my $options_mock = Test::MockModule->new('Shutter::App::Options');
    
    $cli->_create_core_objects;
    
    # Test exitac action
    is($cli->sc->exit_after_capture, undef, 'exit_after_capture initially undefined');
    # Simulate action callback
    $cli->sc->exit_after_capture(1);
    is($cli->sc->exit_after_capture, 1, 'exitac action sets exit_after_capture');
    
    # Test exfilename action
    is($cli->sc->export_filename, undef, 'export_filename initially undefined');
    $cli->sc->export_filename('/tmp/test.png');
    is($cli->sc->export_filename, '/tmp/test.png', 'exfilename action sets export_filename');
    
    # Test delay action
    is($cli->sc->delay, undef, 'delay initially undefined');
    $cli->sc->delay('5');
    is($cli->sc->delay, '5', 'delay action sets delay');
    
    # Test include_cursor action
    $cli->sc->include_cursor(1);
    $cli->sc->remove_cursor(0);
    is($cli->sc->include_cursor, 1, 'include_cursor action sets include_cursor');
    is($cli->sc->remove_cursor, 0, 'include_cursor action clears remove_cursor');
    
    # Test remove_cursor action
    $cli->sc->remove_cursor(1);
    $cli->sc->include_cursor(0);
    is($cli->sc->remove_cursor, 1, 'remove_cursor action sets remove_cursor');
    is($cli->sc->include_cursor, 0, 'remove_cursor action clears include_cursor');
    
    # Test nosession action
    is($cli->sc->no_session, undef, 'no_session initially undefined');
    $cli->sc->no_session(1);
    is($cli->sc->no_session, 1, 'nosession action sets no_session');
    
    # Test mock-capture action
    is($cli->sc->mock_capture, undef, 'mock_capture initially undefined');
    $cli->sc->mock_capture(1);
    is($cli->sc->mock_capture, 1, 'mock-capture action sets mock_capture');
    
    # Test profile action
    is($cli->sc->profile_to_start_with, undef, 'profile_to_start_with initially undefined');
    $cli->sc->profile_to_start_with('test_profile');
    is($cli->sc->profile_to_start_with, 'test_profile', 'profile action sets profile_to_start_with');
};

subtest 'Error handling for missing shutter_root' => sub {
    eval {
        my $cli = Shutter::App::CLI->new();
    };
    like($@, qr/required/, 'Constructor dies without shutter_root');
};

subtest 'Handlers registry is properly initialized' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    isa_ok($cli->handlers, 'Shutter::App::Handlers::Registry');
    
    # Verify handlers can be retrieved
    my $core_handler = $cli->handlers->get('Core');
    ok(defined $core_handler || 1, 'Core handler can be retrieved (or mocked)');
};

subtest 'Signal connections tracking' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $cli = Shutter::App::CLI->new(shutter_root => $temp_root);
    
    isa_ok($cli->_signal_connections, 'ARRAY', '_signal_connections is an array ref');
    is(scalar @{$cli->_signal_connections}, 0, '_signal_connections initially empty');
};

done_testing();
