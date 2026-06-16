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
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package Shutter::App::Init;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;

use Shutter::App::Constants qw(:all);
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
use Shutter::App::Handlers::Workflow;
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

use Glib qw/TRUE FALSE/;

sub initialize ($cli) {
    my $sc = $cli->sc;
    
    # Initialize session state hash
    $cli->{session_screens} = {};
    $cli->{session_start_screen} = {};
    
    # Create core managers
    my $session_manager = Shutter::App::Core::SessionManager->new(_common => $sc);
    $cli->{session_manager} = $session_manager;
    
    my $settings_manager = Shutter::App::Core::SettingsManager->new(_common => $sc);
    $cli->{settings_manager} = $settings_manager;
    
    my $screenshot_handler = Shutter::App::Core::ScreenshotHandler->new(_common => $sc);
    $cli->{screenshot_handler} = $screenshot_handler;
    
    my $upload_manager = Shutter::App::Core::UploadManager->new(_common => $sc);
    $cli->{upload_manager} = $upload_manager;
    
    # Create UI components
    my $sd = Shutter::App::SimpleDialogs->new($sc->get_mainwindow);
    $cli->{sd} = $sd;
    
    my $sp = Shutter::Pixbuf::Save->new($sc);
    $cli->{sp} = $sp;
    
    my $lp = Shutter::Pixbuf::Load->new($sc);
    $cli->{lp} = $lp;
    
    my $lp_ne = Shutter::Pixbuf::Load->new($sc, undef, TRUE);
    $cli->{lp_ne} = $lp_ne;
    
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
        accounts => {},
        settings => {},
        supported_formats => [],
    );
    $cli->{globals} = \%globals;
    
    return \%globals;
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