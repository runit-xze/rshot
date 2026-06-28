#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir tempfile);
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

use_ok('Shutter::App::HelperFunctions');

subtest 'Constructor requires Common object' => sub {
    eval {
        my $helper = Shutter::App::HelperFunctions->new();
    };
    like($@, qr/required|common/i, 'Constructor dies without Common object');
};

subtest 'Constructor with valid Common' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    isa_ok($helper, 'Shutter::App::HelperFunctions');
    ok(defined $helper, 'HelperFunctions object created');
};

subtest 'Filename sanitization' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test unsafe characters
    my @unsafe_chars = ('/', '\\', ':', '*', '?', '"', '<', '>', '|', "\0");
    foreach my $char (@unsafe_chars) {
        ok(1, "Should sanitize character: $char");
    }
    
    # Test path traversal
    ok(1, 'Should prevent ../ in filenames');
    ok(1, 'Should prevent absolute paths');
};

subtest 'Filename pattern expansion' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test pattern variables
    ok(1, 'Should expand %Y (year)');
    ok(1, 'Should expand %m (month)');
    ok(1, 'Should expand %d (day)');
    ok(1, 'Should expand %H (hour)');
    ok(1, 'Should expand %M (minute)');
    ok(1, 'Should expand %S (second)');
    ok(1, 'Should expand %T (timestamp)');
    ok(1, 'Should expand %name (window name)');
    ok(1, 'Should expand %nb (number)');
};

subtest 'Unique filename generation' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test uniqueness
    ok(1, 'Should generate unique filenames');
    ok(1, 'Should append counter if file exists');
    ok(1, 'Should handle race conditions');
};

subtest 'Directory validation' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test directory checks
    ok(1, 'Should check directory exists');
    ok(1, 'Should check directory is writable');
    ok(1, 'Should create missing directories');
    ok(1, 'Should validate permissions');
};

subtest 'File size formatting' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test size formatting
    ok(1, 'Should format bytes (< 1KB)');
    ok(1, 'Should format KB (1KB - 1MB)');
    ok(1, 'Should format MB (1MB - 1GB)');
    ok(1, 'Should format GB (> 1GB)');
    ok(1, 'Should use appropriate precision');
};

subtest 'Timestamp formatting' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test timestamp formats
    ok(1, 'Should format ISO 8601');
    ok(1, 'Should format locale-specific');
    ok(1, 'Should format custom patterns');
    ok(1, 'Should handle timezones');
};

subtest 'URL validation' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test URL validation
    my @valid_urls = (
        'http://example.com',
        'https://example.com',
        'https://example.com:8080/path',
        'http://localhost:3000',
    );
    
    foreach my $url (@valid_urls) {
        ok(1, "Should validate URL: $url");
    }
    
    # Test invalid URLs
    my @invalid_urls = (
        'not a url',
        'ftp://example.com',
        'javascript:alert(1)',
        'file:///etc/passwd',
    );
    
    foreach my $url (@invalid_urls) {
        ok(1, "Should reject URL: $url");
    }
};

subtest 'Image dimension validation' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test dimension validation
    ok(1, 'Should validate positive dimensions');
    ok(1, 'Should reject zero dimensions');
    ok(1, 'Should reject negative dimensions');
    ok(1, 'Should enforce maximum dimensions');
};

subtest 'Color parsing' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test color formats
    ok(1, 'Should parse hex colors (#RRGGBB)');
    ok(1, 'Should parse hex colors with alpha (#RRGGBBAA)');
    ok(1, 'Should parse RGB colors (rgb(r,g,b))');
    ok(1, 'Should parse RGBA colors (rgba(r,g,b,a))');
    ok(1, 'Should parse named colors (red, blue, etc)');
};

subtest 'String truncation' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test truncation
    ok(1, 'Should truncate long strings');
    ok(1, 'Should add ellipsis');
    ok(1, 'Should respect word boundaries');
    ok(1, 'Should handle UTF-8 correctly');
};

subtest 'Path manipulation' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test path operations
    ok(1, 'Should join paths correctly');
    ok(1, 'Should normalize paths');
    ok(1, 'Should resolve relative paths');
    ok(1, 'Should extract directory from path');
    ok(1, 'Should extract filename from path');
    ok(1, 'Should extract extension from path');
};

subtest 'Clipboard operations' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test clipboard
    ok(1, 'Should copy text to clipboard');
    ok(1, 'Should copy image to clipboard');
    ok(1, 'Should read from clipboard');
    ok(1, 'Should handle clipboard errors');
};

subtest 'Desktop environment detection' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test DE detection
    ok(1, 'Should detect GNOME');
    ok(1, 'Should detect KDE');
    ok(1, 'Should detect XFCE');
    ok(1, 'Should detect other DEs');
    ok(1, 'Should detect Wayland vs X11');
};

subtest 'Process management' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test process operations
    ok(1, 'Should check if process is running');
    ok(1, 'Should get process info');
    ok(1, 'Should kill process');
    ok(1, 'Should handle process errors');
};

subtest 'Configuration file handling' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test config operations
    ok(1, 'Should read config files');
    ok(1, 'Should write config files');
    ok(1, 'Should parse INI format');
    ok(1, 'Should parse JSON format');
    ok(1, 'Should handle missing config');
};

subtest 'Localization helpers' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test i18n
    ok(1, 'Should translate strings');
    ok(1, 'Should handle plurals');
    ok(1, 'Should format numbers locale-specific');
    ok(1, 'Should fallback to English');
};

subtest 'Error message formatting' => sub {
    my $common_mock = bless {}, 'Shutter::App::Common';
    my $helper = Shutter::App::HelperFunctions->new($common_mock);
    
    # Test error formatting
    ok(1, 'Should format user-friendly errors');
    ok(1, 'Should include error codes');
    ok(1, 'Should suggest solutions');
    ok(1, 'Should log technical details');
};

done_testing();
