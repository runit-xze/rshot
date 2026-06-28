package Test::Shutter::Mock;

use strict;
use warnings;
use v5.40;

# Comprehensive mock infrastructure for Shutter testing
# This allows testing business logic without GTK3/X11 dependencies

BEGIN {
    # Mock Gtk3 - Main GTK library
    {
        package Gtk3;
        our $VERSION = '0.038';
        
        sub import {
            my ($class, @args) = @_;
            return if !@args || $args[0] eq '-init';
        }
        
        sub init { return 1; }
        sub main { }
        sub main_quit { }
        sub check_version { return 1; }
        sub get_major_version { return 3; }
        sub get_minor_version { return 24; }
        sub get_micro_version { return 0; }
    }
    
    # Mock Gtk3::Gdk - GDK library with constants
    {
        package Gtk3::Gdk;
        use constant CURRENT_TIME => 0;
        use constant BUTTON_PRESS => 4;
        use constant BUTTON_RELEASE => 7;
        use constant KEY_PRESS => 8;
        use constant KEY_RELEASE => 9;
        use constant KEY_Escape => 65307;
        use constant KEY_Return => 65293;
        use constant KEY_KP_Enter => 65421;
    }
    
    # Mock Glib - Core GLib library
    {
        package Glib;
        our $VERSION = '1.329';
        
        sub import {
            my ($class, @args) = @_;
            if (@args) {
                my $caller = caller;
                no strict 'refs';
                for my $sym (@args) {
                    if ($sym eq 'TRUE') {
                        *{"${caller}::TRUE"} = sub { 1 };
                    } elsif ($sym eq 'FALSE') {
                        *{"${caller}::FALSE"} = sub { 0 };
                    }
                }
            }
        }
        
        sub TRUE { 1 }
        sub FALSE { 0 }
    }
    
    # Mock Glib::Log
    {
        package Glib::Log;
        sub set_handler { return 1; }
        sub default_handler { }
        sub remove_handler { }
    }
    
    # Mock Glib::Type
    {
        package Glib::Type;
        sub register_object { return 1; }
        sub register { return 1; }
    }
    
    # Mock Glib::LogLevelFlags
    {
        package Glib::LogLevelFlags;
        sub new { return bless {}, shift; }
    }
    
    # Mock Glib::Object::Introspection
    {
        package Glib::Object::Introspection;
        sub setup { return 1; }
    }
    
    # Mock Glib::Object::Subclass
    {
        package Glib::Object::Subclass;
        sub import { }
    }
    
    # Mock Log::Any
    {
        package Log::Any;
        sub import { }
        sub get_logger { 
            return bless {
                category => $_[1] // 'default',
            }, 'Log::Any::Proxy';
        }
    }
    
    {
        package Log::Any::Proxy;
        sub new { return bless {}, shift; }
        sub debug { }
        sub info { }
        sub notice { }
        sub warn { }
        sub warning { }
        sub error { }
        sub critical { }
        sub alert { }
        sub emergency { }
        sub fatal { }
        sub trace { }
        sub is_debug { 0 }
        sub is_info { 0 }
        sub is_warn { 0 }
        sub is_error { 0 }
    }
    
    # Mark all modules as loaded
    $INC{'Gtk3.pm'} = __FILE__;
    $INC{'Gtk3/Gdk.pm'} = __FILE__;
    $INC{'Glib.pm'} = __FILE__;
    $INC{'Glib/Log.pm'} = __FILE__;
    $INC{'Glib/Type.pm'} = __FILE__;
    $INC{'Glib/LogLevelFlags.pm'} = __FILE__;
    $INC{'Glib/Object/Introspection.pm'} = __FILE__;
    $INC{'Glib/Object/Subclass.pm'} = __FILE__;
    $INC{'Log/Any.pm'} = __FILE__;
}

1;

__END__

=head1 NAME

Test::Shutter::Mock - Comprehensive mock infrastructure for Shutter testing

=head1 SYNOPSIS

    use lib 't/lib';
    use Test::Shutter::Mock;
    use Test::More;
    
    # Now you can test Shutter modules without GTK3/X11
    use Shutter::App::HelperFunctions;
    
    # Test business logic
    my $result = Shutter::App::HelperFunctions::sanitize_filename('../../../etc/passwd');
    is($result, 'etc_passwd', 'Path traversal prevented');

=head1 DESCRIPTION

This module provides comprehensive mock implementations of Gtk3, Glib, and Log::Any
to enable IBM-standard unit testing of Shutter modules without requiring:

- GTK3 installation
- X11 or Wayland display server
- Actual GUI rendering

The mocks focus on allowing business logic testing while stubbing out UI dependencies.

=head1 TESTING PHILOSOPHY

These mocks follow IBM testing standards:

1. Test behavior, not implementation
2. Focus on business logic and data flow
3. Verify method calls, parameters, and return values
4. Test error handling and edge cases
5. Keep tests fast and CI-friendly

=head1 AUTHOR

IBM Bob <bob@ibm.com>

=cut
