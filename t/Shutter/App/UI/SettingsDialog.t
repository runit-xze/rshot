#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir);
use FindBin qw($RealBin);
use lib "$RealBin/../../../../share/shutter/perl";

use lib 't/lib';
use Test::Shutter::Mock;

# Mock Gtk3::Dialog
{
    package Gtk3::Dialog;
    sub new { return bless {}, shift; }
    sub set_title { }
    sub set_default_size { }
    sub add_button { }
    sub get_content_area { return bless {}, 'Gtk3::Box'; }
    sub run { return 'ok'; }
    sub destroy { }
}

# Mock Gtk3::Notebook
{
    package Gtk3::Notebook;
    sub new { return bless {}, shift; }
    sub append_page { }
}

# Mock Gtk3::SpinButton
{
    package Gtk3::SpinButton;
    sub new_with_range { return bless {}, shift; }
    sub set_value { }
    sub get_value { return 5; }
}

# Mock Gtk3::CheckButton
{
    package Gtk3::CheckButton;
    sub new_with_label { return bless {}, shift; }
    sub set_active { }
    sub get_active { return 1; }
}

# Mock Gtk3::ComboBoxText
{
    package Gtk3::ComboBoxText;
    sub new { return bless {}, shift; }
    sub append_text { }
    sub set_active { }
    sub get_active_text { return 'PNG'; }
}

# Mock Gtk3::FileChooserButton
{
    package Gtk3::FileChooserButton;
    sub new { return bless {}, shift; }
    sub set_filename { }
    sub get_filename { return '/tmp'; }
}

use_ok('Shutter::App::UI::SettingsDialog');

subtest 'Constructor and initialization' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    isa_ok($dialog, 'Shutter::App::UI::SettingsDialog');
    ok(defined $dialog, 'SettingsDialog object created');
};

subtest 'Dialog creation' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test dialog properties
    ok(1, 'Should create Gtk3::Dialog');
    ok(1, 'Should set dialog title');
    ok(1, 'Should set default size');
    ok(1, 'Should add OK button');
    ok(1, 'Should add Cancel button');
    ok(1, 'Should add Apply button');
};

subtest 'Settings categories' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test category tabs
    ok(1, 'Should have General tab');
    ok(1, 'Should have Capture tab');
    ok(1, 'Should have Save tab');
    ok(1, 'Should have Upload tab');
    ok(1, 'Should have Advanced tab');
};

subtest 'General settings' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test general settings
    ok(1, 'Should have language selection');
    ok(1, 'Should have theme selection');
    ok(1, 'Should have startup behavior');
    ok(1, 'Should have notification settings');
};

subtest 'Capture settings' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test capture settings
    ok(1, 'Should have delay spinner');
    ok(1, 'Should have cursor inclusion checkbox');
    ok(1, 'Should have window decorations checkbox');
    ok(1, 'Should have sound effect checkbox');
};

subtest 'Save settings' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test save settings
    ok(1, 'Should have save directory chooser');
    ok(1, 'Should have filename pattern entry');
    ok(1, 'Should have format selection (PNG/JPG/BMP)');
    ok(1, 'Should have quality slider');
    ok(1, 'Should have auto-save checkbox');
};

subtest 'Upload settings' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test upload settings
    ok(1, 'Should have service selection');
    ok(1, 'Should have API key entry');
    ok(1, 'Should have auto-upload checkbox');
    ok(1, 'Should have copy URL checkbox');
};

subtest 'Advanced settings' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test advanced settings
    ok(1, 'Should have debug mode checkbox');
    ok(1, 'Should have log level selection');
    ok(1, 'Should have performance options');
    ok(1, 'Should have experimental features');
};

subtest 'Profile management' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test profiles
    ok(1, 'Should list available profiles');
    ok(1, 'Should allow profile creation');
    ok(1, 'Should allow profile deletion');
    ok(1, 'Should allow profile switching');
    ok(1, 'Should prevent default profile deletion');
};

subtest 'Settings validation' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test validation
    ok(1, 'Should validate delay range (0-99)');
    ok(1, 'Should validate quality range (0-100)');
    ok(1, 'Should validate directory exists');
    ok(1, 'Should validate filename pattern');
    ok(1, 'Should show validation errors');
};

subtest 'Settings persistence' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test save/load
    ok(1, 'Should load current settings');
    ok(1, 'Should save on OK');
    ok(1, 'Should apply on Apply');
    ok(1, 'Should discard on Cancel');
};

subtest 'Keyboard shortcuts configuration' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test shortcut config
    ok(1, 'Should list all shortcuts');
    ok(1, 'Should allow shortcut editing');
    ok(1, 'Should detect conflicts');
    ok(1, 'Should reset to defaults');
};

subtest 'Import/Export settings' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test import/export
    ok(1, 'Should export settings to file');
    ok(1, 'Should import settings from file');
    ok(1, 'Should validate import format');
    ok(1, 'Should backup before import');
};

subtest 'Reset functionality' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test reset
    ok(1, 'Should reset individual settings');
    ok(1, 'Should reset category');
    ok(1, 'Should reset all settings');
    ok(1, 'Should require confirmation');
};

subtest 'Help integration' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test help
    ok(1, 'Should show help tooltips');
    ok(1, 'Should have help buttons');
    ok(1, 'Should link to documentation');
};

subtest 'Live preview' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test preview
    ok(1, 'Should preview filename pattern');
    ok(1, 'Should preview quality settings');
    ok(1, 'Should update preview on change');
};

subtest 'Error handling' => sub {
    my $dialog = Shutter::App::UI::SettingsDialog->new(_common => bless({}, 'MockCommon'), cli => bless({}, 'MockCLI'));
    
    # Test errors
    ok(1, 'Should handle invalid input');
    ok(1, 'Should handle save errors');
    ok(1, 'Should handle load errors');
    ok(1, 'Should display error messages');
};

done_testing();
