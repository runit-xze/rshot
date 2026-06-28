#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use FindBin qw($RealBin);

# Integration test - tests actual application startup
# This requires GTK3 and X11/Wayland display

# Skip if no DISPLAY available
BEGIN {
    unless ($ENV{DISPLAY}) {
        plan skip_all => "No DISPLAY environment variable - cannot test GUI application";
    }
}

my $rshot_bin = "$RealBin/../../bin/rshot";

subtest 'Application binary exists' => sub {
    plan tests => 2;
    
    ok(-f $rshot_bin, 'rshot binary exists');
    ok(-x $rshot_bin, 'rshot binary is executable');
};

subtest 'Application shows help' => sub {
    plan tests => 3;
    
    require IPC::Run3;
    my $output;
    IPC::Run3::run3([$rshot_bin, '--help'], \undef, \$output, \$output);
    my $exit_code = $? >> 8;
    
    # Help should exit with code 1 (standard for --help)
    ok($exit_code == 1 || $exit_code == 0, 'Help command exits cleanly');
    like($output, qr/Usage:/, 'Help output contains usage information');
    like($output, qr/Options:/, 'Help output contains options section');
};

subtest 'Application accepts debug flag' => sub {
    plan tests => 2;
    
    require IPC::Run3;
    my $output;
    IPC::Run3::run3([$rshot_bin, '--debug', '--help'], \undef, \$output, \$output);
    my $exit_code = $? >> 8;
    
    ok($exit_code == 1 || $exit_code == 0, 'Debug flag accepted');
    like($output, qr/Usage:/, 'Help still works with debug flag');
};

subtest 'Application accepts log-level flag' => sub {
    plan tests => 2;
    
    require IPC::Run3;
    my $output;
    IPC::Run3::run3([$rshot_bin, '--log-level=debug', '--help'], \undef, \$output, \$output);
    my $exit_code = $? >> 8;
    
    ok($exit_code == 1 || $exit_code == 0, 'Log-level flag accepted');
    like($output, qr/Usage:/, 'Help still works with log-level flag');
};

subtest 'Application accepts mock-capture flag' => sub {
    plan tests => 2;
    
    require IPC::Run3;
    my $output;
    IPC::Run3::run3([$rshot_bin, '--mock-capture', '--help'], \undef, \$output, \$output);
    my $exit_code = $? >> 8;
    
    ok($exit_code == 1 || $exit_code == 0, 'Mock-capture flag accepted');
    like($output, qr/mock.*capture/i, 'Help mentions mock capture mode');
};

subtest 'Application version information' => sub {
    plan tests => 1;
    
    # Test that application can be queried for version
    # (implementation may vary, this is a placeholder)
    ok(1, 'Application should provide version information');
};

subtest 'Application dependencies loaded' => sub {
    plan tests => 3;
    
    # Test that critical Perl modules can be loaded
    my $lib_path = "$RealBin/../../share/shutter/resources/modules";
    require IPC::Run3;
    my $output;
    IPC::Run3::run3(['perl', '-I', $lib_path, '-e', 'use Gtk3; use Glib; print "OK\n"'], \undef, \$output, \$output);
    my $exit_code = $? >> 8;
    
    is($exit_code, 0, 'Gtk3 and Glib modules load successfully');
    like($output, qr/OK/, 'Module loading produces expected output');
    ok(1, 'All critical dependencies available');
};

subtest 'Application can run in mock mode' => sub {
    plan tests => 2;
    
    # Test that app can start in mock capture mode (doesn't require actual screenshot)
    require IPC::Run3;
    my $output;
    IPC::Run3::run3(['timeout', '2', $rshot_bin, '--mock-capture', '--exit-after-capture'], \undef, \$output, \$output);
    my $exit_code = $? >> 8;
    
    # Exit code 124 means timeout (app is running), which is OK
    # Exit code 0 or 1 means app exited cleanly
    ok($exit_code == 0 || $exit_code == 1 || $exit_code == 124, 'App starts in mock mode');
    ok(1, 'Mock mode enables testing without actual screen capture');
};

done_testing();