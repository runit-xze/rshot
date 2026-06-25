###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2025 Shutter Team
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
###################################################

package Shutter::App::Init;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Log::Any;

my $log = Log::Any->get_logger;

use Shutter::App::Constants qw(MAX_ERROR SHUTTER_REV SHUTTER_NAME SHUTTER_VERSION);
use Shutter::App::Autostart;
use Shutter::App::Menu;
use Shutter::App::Toolbar;
use Shutter::App::SimpleDialogs;
use Shutter::Pixbuf::Save;
use Shutter::Pixbuf::Load;
use Shutter::App::AfterCapturePipeline;
use Shutter::App::PinToScreen;
use Shutter::Geometry::Region;

use Shutter::App::Handlers::Core;
use Shutter::App::Handlers::Workflow_Init;
use Shutter::App::Handlers::Workflow_Control;
use Shutter::App::Handlers::Workflow_Save;
use Shutter::App::Handlers::Workflow_Session;
use Shutter::App::Handlers::Workflow_Integrate;
use Shutter::App::Handlers::Workflow_Post;
use Shutter::App::Handlers::Init_Handlers;
use Shutter::App::Handlers::Init_Accounts;
use Shutter::App::Handlers::Init_Model;

use Shutter::App::Core::SessionManager;
use Shutter::App::Core::SettingsManager;
use Shutter::App::Core::ScreenshotHandler;
use Shutter::App::Core::UploadManager;
use Shutter::App::Notification;

use Glib qw/TRUE FALSE/;

sub initialize ($cli) {
    my $sc = $cli->sc;
    $log->debug("Initializing modules in Init.pm");
    
    # Initialize session state hash
    $cli->{_session_screens} = {};
    $cli->{_session_start_screen} = {
        'first_page' => {
            'num_session_files' => 0,
            'model' => Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String'),
        }
    };
    $cli->{_session_start_screen}->{'first_page'}->{'model'}->set_sort_column_id(2, 'descending');

    # Mock widgets for state that used to be in the GUI
    $cli->{_hide_active} = _mock_widget(TRUE);
    $cli->{_hide_time}   = _mock_widget(250);
    $cli->{_menu_delay}  = _mock_widget(0);
    $cli->{_notify_ptimeout_active} = _mock_widget(FALSE);
    $cli->{_is_hidden}   = FALSE;
    
    if (-e '/.flatpak-info') {
        $cli->{_x11_supported} = FALSE;
    } else {
        $cli->{_x11_supported} = ($ENV{XDG_SESSION_TYPE} // '') eq "wayland" ? FALSE : TRUE;
    }
    
    # Create core managers
    my $session_manager = Shutter::App::Core::SessionManager->new(
        _common => $sc,
        _session_screens => $cli->{_session_screens},
        _session_start_screen => $cli->{_session_start_screen}
    );
    $cli->{session_manager} = $session_manager;
    
    my $settings_manager = Shutter::App::Core::SettingsManager->new(_common => $sc);
    $cli->{settings_manager} = $settings_manager;
    
    # Load settings and accounts
    my $settings_xml = $settings_manager->load_settings;
    my $accounts = $settings_manager->load_accounts;
    $cli->{_accounts} = $accounts;
    
    my $screenshot_handler = Shutter::App::Core::ScreenshotHandler->new(_common => $sc);
    $cli->{screenshot_handler} = $screenshot_handler;
    
    my $upload_manager = Shutter::App::Core::UploadManager->new(_common => $sc);
    $cli->{upload_manager} = $upload_manager;

    # Initialize notifications
    $sc->set_notification_object(Shutter::App::Notification->new);
    
    # Create UI components
    my $sd = Shutter::App::SimpleDialogs->new($sc->get_mainwindow);
    $cli->{_sd} = $sd;
    $sc->{_sd}  = $sd;   # handlers read it via $cli->sc->{_sd}
    
    my $sp = Shutter::Pixbuf::Save->new($sc);
    $cli->{_sp} = $sp;
    
    my $lp = Shutter::Pixbuf::Load->new($sc);
    $cli->{_lp} = $lp;
    
    my $lp_ne = Shutter::Pixbuf::Load->new($sc, undef, TRUE);
    $cli->{_lp_ne} = $lp_ne;
    
    # Create after-capture pipeline
    my $d = $sc->get_gettext;
    my $acp = Shutter::App::AfterCapturePipeline->new($sc, $d, $cli->window);
    $cli->{acp} = $acp;
    
    my $pins = Shutter::App::PinToScreen->new();
    $cli->{pins} = $pins;
    
    # Store for backward compatibility with bin/shutter subroutines
    $cli->{sas} = Shutter::App::Autostart->new();
    $cli->{sm} = Shutter::App::Menu->new($sc);
    $cli->{st} = Shutter::App::Toolbar->new($sc);
    
    # Initialize global state
    my %globals = (
        plugins => {},
        accounts => $accounts,
        settings => $settings_xml,
        supported_formats => [],
    );

    # Initialize dependencies
    Shutter::App::Handlers::Workflow_Init->new(cli => $cli)->fct_init_depend;

    $cli->{globals} = \%globals;

    $cli->{settings_xml} = $settings_xml; # for backward compat
    
    return \%globals;
}

sub _mock_widget ($val) {
    return bless { val => $val }, 'MockWidget';
}

package MockWidget {
    sub get_active { return shift->{val} }
    sub get_value  { return shift->{val} }
    sub get_text   { return shift->{val} }
    sub get_active_text { return shift->{val} }
}

1;

__END__

=head1 NAME

Shutter::App::Init – Core object initialization

=head1 SYNOPSIS

    my $globals = Shutter::App::Init::initialize($cli);

=head1 DESCRIPTION

Creates and initializes all core application objects including managers, UI components,
and the after-capture pipeline. Returns a hashref containing global state used by
other modules.

=cut
