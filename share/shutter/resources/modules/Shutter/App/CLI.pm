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

package Shutter::App::CLI;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Log::Any;
use Log::Any::Adapter;

BEGIN {
    use Glib::Object::Introspection;
    Glib::Object::Introspection->setup(
        basename => 'Gio',
        version  => '2.0',
        package  => 'Glib::IO',
    );
    Glib::Object::Introspection->setup(
        basename => 'Wnck',
        version  => '3.0',
        package  => 'Wnck',
    );
    Glib::Object::Introspection->setup(
        basename => 'GdkX11',
        version  => '3.0',
        package  => 'Gtk3::GdkX11',
    );
    Glib::Object::Introspection->setup(
        basename => 'PangoCairo',
        version  => '1.0',
        package  => 'Pango::Cairo',
    );
}

use Shutter::App;
use Shutter::App::Constants qw(MAX_ERROR SHUTTER_REV SHUTTER_NAME SHUTTER_VERSION);
use Shutter::App::Common;
use Shutter::App::HelperFunctions;
use Shutter::App::Options;
use Shutter::App::Init;
use Shutter::App::UI::Windows;
use Shutter::App::UI::Menus;
use Shutter::App::Events::File;
use Shutter::App::Events::Screenshot;
use Shutter::App::Events::Edit;
use Shutter::App::Workflow;
use Shutter::App::Handlers::Registry;
use Shutter::App::Session;

has shutter_root => (is => 'ro', required => 1);
has sc           => (is => 'rw');
has shf          => (is => 'rw');
has so           => (is => 'rw');
has app          => (is => 'rw');
has window       => (is => 'rw');
has vbox         => (is => 'rw');
has notebook     => (is => 'rw');
has handlers     => (is => 'rw');
has log          => (is => 'rw');
has workflow     => (is => 'rw');

has _signal_connections => (is => 'rw', default => sub { [] });

sub BUILD ($self, $args) {
    $self->handlers(Shutter::App::Handlers::Registry->new(cli => $self));
}

sub run ($self) {
    $self->_create_core_objects;
    $self->so->get_options;
    $self->_setup_logging;

    $self->log->debug("CLI run started");
    $self->_setup_app;
    $self->log->debug("Calling app->run");
    $self->app->run;
    $self->log->debug("app->run finished");
}

sub _setup_logging ($self) {
    my $sc = $self->sc;
    my $level = $sc->get_log_level // 'info';
    
    if ($sc->get_log_file) {
        Log::Any::Adapter->set('File', $sc->get_log_file, log_level => $level);
    } else {
        Log::Any::Adapter->set('Stderr', log_level => $level);
    }
    
    $self->log(Log::Any->get_logger);
}

sub _setup_app ($self) {
    $self->log->debug("Setting up app");
    $self->app(Shutter::App->new(
        application_id => 'org.shutter-project.Shutter',
        flags        => ['flags-none']
    ));

    $self->app->signal_connect('startup' => sub {
        $self->log->debug("App startup signal received");
        $self->_create_core_objects;
        $self->_initialize_modules;
    });

    $self->app->signal_connect('activate' => sub {
        $self->log->debug("App activate signal received");
        $self->_handle_remote_activation;
    });

    $self->app->signal_connect('notify::is-registered' => sub {
        return unless $self->app->get_is_registered;
        if ($self->app->get_is_remote) {
            $self->log->debug("App registered as remote instance");
            $self->_create_core_objects;
            $self->_handle_remote_activation;
        } else {
            $self->log->debug("App registered as primary instance");
        }
    });
}

sub _create_core_objects ($self) {
    return if $self->sc;
    
    $self->sc(Shutter::App::Common->new(
        shutter_root => $self->shutter_root,
        main_window  => undef,
        appname      => SHUTTER_NAME,
        version      => SHUTTER_VERSION,
        rev          => SHUTTER_REV,
        pid          => $$,
        cli          => $self,
    ));
    
    $self->shf(Shutter::App::HelperFunctions->new($self->sc));
    $self->so(Shutter::App::Options->new($self->sc, $self->shf));
}

sub _initialize_modules ($self) {
    my $globals = Shutter::App::Init::initialize($self);

    my $windows = Shutter::App::UI::Windows->new(
        common => $self->sc,
        app    => $self->app,
        cli    => $self,
    );
    $self->window($windows->get_window);
    $self->vbox($windows->get_vbox);

    $self->_register_actions;

    my $session        = Shutter::App::Session->new(cli => $self);
    my $menus          = Shutter::App::UI::Menus->new(cli => $self);
    
    my $file_events    = Shutter::App::Events::File->new(cli => $self);
    my $screenshot_events = Shutter::App::Events::Screenshot->new(cli => $self);
    my $edit_events    = Shutter::App::Events::Edit->new(cli => $self);
    $self->workflow(Shutter::App::Workflow->new(cli => $self));

    Glib::Timeout->add(1000, sub {
        $self->handlers->get('Core')->evt_show_settings();
        return FALSE;
    });
}

sub _register_actions ($self) {
    my $app = $self->app;
    my $sc = $self->sc;
    my $window = $self->window;

    my @actions = (
        ['exitac', undef, sub { $sc->set_exit_after_capture(TRUE) }],
        ['exfilename', 's', sub { $sc->set_export_filename($_[1]->get_string) }],
        ['delay', 's', sub { $sc->set_delay($_[1]->get_string) }],
        ['include_cursor', undef, sub { $sc->set_include_cursor(TRUE); $sc->set_remove_cursor(FALSE); }],
        ['remove_cursor', undef, sub { $sc->set_remove_cursor(TRUE); $sc->set_include_cursor(FALSE); }],
        ['nosession', undef, sub { $sc->set_no_session(TRUE) }],
        ['mock-capture', undef, sub { $sc->set_mock_capture(TRUE) }],
        ['profile', 's', sub { $sc->set_profile_to_start_with($_[1]->get_string) }],
        ['showmainwindow', undef, sub { 
            $window->show_all;
            $window->present;
        }],
        ['select', 'as', sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'select') }],
        ['full', undef, sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'full') }],
        ['window', 's', sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'window') }],
        ['awindow', undef, sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'awindow') }],
        ['menu', undef, sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'menu') }],
        ['tooltip', undef, sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'tooltip') }],
        ['web', 's', sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'web') }],
        ['redoshot', undef, sub { $self->handlers->get('Core')->evt_take_screenshot(undef, 'redoshot') }],
    );

    foreach my $a (@actions) {
        my ($name, $type, $callback) = @$a;
        my $action = Glib::IO::SimpleAction->new($name, $type ? Glib::VariantType->new($type) : undef);
        $action->signal_connect('activate' => $callback);
        $app->add_action($action);
    }
}

sub _handle_remote_activation ($self) {
    my ($cmdname, $extra) = $self->sc->get_start_with;
    my $profile = $self->sc->get_profile_to_start_with;
    my $exitac = $self->sc->get_exit_after_capture;
    my $exfilename = $self->sc->get_export_filename;
    my $delay = $self->sc->get_delay;
    my $include_cursor = $self->sc->get_include_cursor;
    my $remove_cursor = $self->sc->get_remove_cursor;
    my $nosession = $self->sc->get_no_session;
    my $mock_capture = $self->sc->get_mock_capture;
    
    $self->log->debug("Handling activation: cmd=" . ($cmdname // 'none'));

    $self->app->activate_action('profile', Glib::Variant->new_string($profile)) if $profile;
    $self->app->activate_action('exitac', undef) if $exitac;
    $self->app->activate_action('exfilename', Glib::Variant->new_string($exfilename)) if $exfilename;
    $self->app->activate_action('delay', Glib::Variant->new_string($delay)) if $delay;
    $self->app->activate_action('include_cursor', undef) if $include_cursor;
    $self->app->activate_action('remove_cursor', undef) if $remove_cursor;
    $self->app->activate_action('nosession', undef) if $nosession;
    $self->app->activate_action('mock-capture', undef) if $mock_capture;
    
    my %screenshot_cmds = (select => 1, full => 1, window => 1, awindow => 1, menu => 1, tooltip => 1, web => 1, redoshot => 1);
    if ($cmdname && $screenshot_cmds{$cmdname}) {
        $self->app->activate_action($cmdname, $extra ? Glib::Variant->new_string($extra) : undef);
    } else {
        $self->app->activate_action('showmainwindow', undef);
    }
}

1;

__END__

=head1 NAME

Shutter::App::CLI – Application entry point

=head1 SYNOPSIS

    my $cli = Shutter::App::CLI->new(shutter_root => $root);
    $cli->run;

=head1 DESCRIPTION

Creates the core objects, initializes modules, and runs the application.
This module contains the code previously at the bottom of bin/shutter.

=cut
