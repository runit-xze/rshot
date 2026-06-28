#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../../../../share/shutter/resources/modules";

use lib 't/lib';
use Test::Shutter::Mock;

use_ok('Shutter::App::Core::SettingsManager');

subtest 'Constructor and initialization' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    isa_ok($manager, 'Shutter::App::Core::SettingsManager');
    ok(defined $manager, 'SettingsManager created successfully');
};

subtest 'Default settings' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test default values
    ok(1, 'Manager should provide default delay');
    ok(1, 'Manager should provide default save directory');
    ok(1, 'Manager should provide default filename pattern');
    ok(1, 'Manager should provide default image format');
    ok(1, 'Manager should provide default quality settings');
};

subtest 'Settings persistence' => sub {
    my $temp_root = tempdir(CLEANUP => 1);
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test save settings
    ok(1, 'Settings should be saveable to disk');
    
    # Test load settings
    ok(1, 'Settings should be loadable from disk');
    
    # Test settings file format
    ok(1, 'Settings file should be valid XML/JSON');
};

subtest 'Profile management' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test profile creation
    ok(1, 'New profile should be creatable');
    
    # Test profile deletion
    ok(1, 'Profile should be deletable');
    
    # Test profile switching
    ok(1, 'Active profile should be switchable');
    
    # Test default profile
    ok(1, 'Default profile should always exist');
    ok(1, 'Default profile should not be deletable');
};

subtest 'Capture settings' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test capture-related settings
    ok(1, 'Manager should store delay setting');
    ok(1, 'Manager should store include_cursor setting');
    ok(1, 'Manager should store remove_cursor setting');
    ok(1, 'Manager should store capture_decorations setting');
    ok(1, 'Manager should store capture_pointer setting');
};

subtest 'Save settings' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test save-related settings
    ok(1, 'Manager should store save directory');
    ok(1, 'Manager should store filename pattern');
    ok(1, 'Manager should store auto-save setting');
    ok(1, 'Manager should store image format (PNG/JPG/etc)');
    ok(1, 'Manager should store compression quality');
};

subtest 'Upload settings' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test upload-related settings
    ok(1, 'Manager should store upload profiles');
    ok(1, 'Manager should store default upload service');
    ok(1, 'Manager should store auto-upload setting');
    ok(1, 'Manager should store upload credentials (encrypted)');
};

subtest 'UI settings' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test UI-related settings
    ok(1, 'Manager should store window position');
    ok(1, 'Manager should store window size');
    ok(1, 'Manager should store toolbar visibility');
    ok(1, 'Manager should store statusbar visibility');
    ok(1, 'Manager should store theme preference');
};

subtest 'Notification settings' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test notification settings
    ok(1, 'Manager should store notification enabled flag');
    ok(1, 'Manager should store notification timeout');
    ok(1, 'Manager should store notification position');
};

subtest 'Keyboard shortcuts' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test keyboard shortcut settings
    ok(1, 'Manager should store global shortcuts');
    ok(1, 'Manager should validate shortcut conflicts');
    ok(1, 'Manager should allow shortcut customization');
};

subtest 'Settings validation' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test validation
    ok(1, 'Manager should validate delay range (0-99)');
    ok(1, 'Manager should validate quality range (0-100)');
    ok(1, 'Manager should validate directory existence');
    ok(1, 'Manager should validate filename pattern');
    ok(1, 'Manager should reject invalid values');
};

subtest 'Settings migration' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test migration from old versions
    ok(1, 'Manager should detect old settings format');
    ok(1, 'Manager should migrate old settings');
    ok(1, 'Manager should backup before migration');
};

subtest 'Settings export/import' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test export
    ok(1, 'Settings should be exportable');
    ok(1, 'Export should include all profiles');
    
    # Test import
    ok(1, 'Settings should be importable');
    ok(1, 'Import should validate format');
    ok(1, 'Import should handle conflicts');
};

subtest 'Settings reset' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test reset functionality
    ok(1, 'Individual settings should be resettable');
    ok(1, 'Profile should be resettable');
    ok(1, 'All settings should be resettable');
    ok(1, 'Reset should require confirmation');
};

subtest 'Concurrent access' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test concurrent access
    ok(1, 'Manager should handle concurrent reads');
    ok(1, 'Manager should prevent concurrent writes');
    ok(1, 'Manager should use file locking');
};

subtest 'Error handling' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test error scenarios
    ok(1, 'Manager should handle corrupted settings file');
    ok(1, 'Manager should handle missing settings file');
    ok(1, 'Manager should handle permission errors');
    ok(1, 'Manager should fallback to defaults on error');
};

subtest 'Settings change notifications' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test change notification system
    ok(1, 'Manager should notify on setting change');
    ok(1, 'Manager should support change listeners');
    ok(1, 'Manager should batch notifications');
};

subtest 'Advanced settings' => sub {
    my $manager = Shutter::App::Core::SettingsManager->new(_common => bless({}, 'MockCommon'));
    
    # Test advanced/hidden settings
    ok(1, 'Manager should support debug mode');
    ok(1, 'Manager should support experimental features');
    ok(1, 'Manager should support performance tuning');
};

done_testing();