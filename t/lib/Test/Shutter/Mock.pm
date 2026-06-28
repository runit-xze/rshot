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
    
    # Mock Wnck
    {
        package Wnck::Screen;
        sub get_default { return bless {}, 'Wnck::Screen::Mock' }
    }
    {
        package Wnck::Screen::Mock;
        our $AUTOLOAD;
        sub new { bless {}, shift }
        sub AUTOLOAD { return 1; }
        sub DESTROY {}
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
    {
        package Gtk3::BaseMock;
        our $AUTOLOAD;
        sub new { bless {}, shift }
        sub AUTOLOAD { return 1; }
        sub DESTROY {}
        sub get_children { return (bless {}, 'Gtk3::VBox') }
        sub get_style_context { return bless {}, 'Gtk3::StyleContext' }
        sub get_submenu { return bless {}, 'Gtk3::Menu' }
    }
    {
        package Gtk3::Window;
        our @ISA = qw(Gtk3::BaseMock);
        sub get { return '' }
    }
    {
        package Gtk3::Dialog;
        our @ISA = qw(Gtk3::BaseMock);
        sub run { return 1 }
        sub get_child { return bless {}, 'Gtk3::VBox' }
    }
    { package Gtk3::Menu; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::VBox; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::HBox; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::SpinButton; our @ISA = qw(Gtk3::BaseMock); sub new_with_range { bless {}, shift } }
    { package Gtk3::ColorButton; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::FontButton; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::MessageDialog; our @ISA = qw(Gtk3::BaseMock); sub run { 1 } }
    { package Gtk3::SizeGroup; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::CheckButton; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::TextBuffer; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::StyleContext; our @ISA = qw(Gtk3::BaseMock); sub get_background_color { bless {}, 'Gtk3::Gdk::RGBA' } }
    { package Gtk3::TextView; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::ImageView; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::ImageView::Tool::Selector; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::ImageView::Tool::Dragger; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::CssProvider; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::SeparatorToolItem; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::Clipboard; our @ISA = qw(Gtk3::BaseMock); sub get { bless {}, 'Gtk3::Clipboard' } }
    { package Gtk3::SeparatorMenuItem; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::DrawingArea; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::Label; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::Frame; our @ISA = qw(Gtk3::BaseMock); }
    { package Gtk3::Image; our @ISA = qw(Gtk3::BaseMock); sub new_from_stock { bless {}, shift } }
    { package Gtk3::ImageMenuItem; our @ISA = qw(Gtk3::BaseMock); sub new_with_label { bless {}, shift } }
    {
        package Gtk3::Gdk::PixbufLoader;
        our @ISA = qw(Gtk3::BaseMock);
    }
    
    # Mock JSON::MaybeXS
    {
        package JSON::MaybeXS;
        our @ISA = qw(Gtk3::BaseMock);
        sub new { bless {}, shift }
        sub decode { return {} }
        sub encode { return "{}" }
    }
    
    # Mock GooCanvas2
    {
        package GooCanvas2;
        our $VERSION = '0.06';
        sub import { }
    }
    {
        package GooCanvas2::Canvas;
        our @ISA = ('Gtk3::BaseMock');
        sub new { return bless {}, 'GooCanvas2::Canvas'; }
        sub get_root_item { return bless {}, 'GooCanvas2::CanvasGroup'; }
    }
    {
        package GooCanvas2::CanvasPoints;
        our @ISA = ('Gtk3::BaseMock');
        sub new { return bless {}, 'GooCanvas2::CanvasPoints'; }
    }
    {
        package GooCanvas2::CanvasGroup;
        our @ISA = ('Gtk3::BaseMock');
    }
    
    {
        package Gtk3::Gdk::Pixbuf;
        our @ISA = qw(Gtk3::BaseMock);
        sub new_from_file { bless {}, shift }
    }
    {
        package Gtk3::Gdk::RGBA;
        our @ISA = qw(Gtk3::BaseMock);
        sub new { bless {}, 'Gtk3::Gdk::RGBA' }
        sub parse { bless {}, 'Gtk3::Gdk::RGBA' }
    }
    {
        package Gtk3::Gdk::Screen;
        our @ISA = ('Gtk3::BaseMock');
        sub get_default { return bless {}, 'Gtk3::Gdk::Screen'; }
        sub get_root_window { return bless {}, 'Gtk3::Gdk::Window'; }
        sub get_display { return bless {}, 'Gtk3::Gdk::Display'; }
    }
    {
        package Gtk3::Gdk::Display;
        sub get_default { return bless {}, 'Gtk3::Gdk::Display'; }
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
        sub get_user_cache_dir { return '/tmp' }
        sub get_user_config_dir { return '/tmp' }
        sub get_home_dir { return '/tmp' }
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
    
    # Mock Pango - Text rendering library
    {
        package Pango;
        our $VERSION = '1.227';
        use constant SCALE => 1024;
        sub import { }
    }
    
    # Mock Pango::Layout
    {
        package Pango::Layout;
        sub new { return bless {}, shift; }
        sub set_text { }
        sub set_font_description { }
        sub get_pixel_size { return (100, 20); }
    }
    
    # Mock Pango::FontDescription
    {
        package Pango::FontDescription;
        sub new { return bless {}, shift; }
        sub from_string { return bless {}, shift; }
        sub set_size { }
        sub set_family { }
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
    $INC{'Pango.pm'} = __FILE__;
    $INC{'Pango/Layout.pm'} = __FILE__;
    $INC{'Pango/FontDescription.pm'} = __FILE__;
    $INC{'GooCanvas2.pm'} = __FILE__;
    $INC{'Gtk3/ImageView.pm'} = __FILE__;
    $INC{'JSON/MaybeXS.pm'} = __FILE__;
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
