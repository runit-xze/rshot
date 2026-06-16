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
use Glib::Object::Subclass qw/Gtk3::Application/;

use Shutter::App::Constants qw(:all);
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
use Shutter::App::Session;

has shutter_root => (is => 'ro', required => 1);
has sc           => (is => 'rw');
has shf          => (is => 'rw');
has so           => (is => 'rw');
has app          => (is => 'rw');
has window       => (is => 'rw');
has vbox         => (is => 'rw');

has _signal_connections => (is => 'rw', default => sub { [] });

sub new ($class, %args) {
    my $self = bless { %args }, $class;
    return $self;
}

sub run ($self) {
    $self->_setup_app;
    $self->_create_core_objects;
    $self->_initialize_modules;
    
    $self->app->run;
}

sub _setup_app ($self) {
    $self->app(Shutter::App->new(
        application_id => 'org.shutter-project.Shutter',
        flags        => ['flags-none']
    ));
    
    $self->app->signal_connect('activate' => sub {
        Glib::Object::Introspection->invoke(
            'Gtk', undef, 'init', 0, []
        );
    });
    
    $self->app->signal_connect('notify::is-registered' => sub {
        return unless $self->app->get_is_registered;
        return if $self->app->get_is_remote;
        
        $self->_handle_remote_activation;
    });
}

sub _create_core_objects ($self) {
    $self->sc(Shutter::App::Common->new(
        shutter_root => $self->shutter_root,
        main_window  => undef,
        appname      => SHUTTER_NAME,
        version      => SHUTTER_VERSION,
        rev          => SHUTTER_REV,
        pid          => $$,
    ));
    
    $self->shf(Shutter::App::HelperFunctions->new($self->sc));
    $self->so(Shutter::App::Options->new($self->sc, $self->shf));
}

sub _initialize_modules ($self) {
    my $globals = Shutter::App::Init::initialize($self);
    
    my $windows = Shutter::App::UI::Windows->new(cli => $self);
    $self->window($windows->get_window);
    $self->vbox($windows->get_vbox);
    
    my $menus = Shutter::App::UI::Menus->new(cli => $self);
    
    my $file_events    = Shutter::App::Events::File->new(cli => $self);
    my $screenshot_events = Shutter::App::Events::Screenshot->new(cli => $self);
    my $edit_events    = Shutter::App::Events::Edit->new(cli => $self);
    my $workflow       = Shutter::App::Workflow->new(cli => $self);
    my $session        = Shutter::App::Session->new(cli => $self);
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
    
    $self->app->activate_action('profile', Glib::Variant->new_string($profile)) if $profile;
    $self->app->activate_action('exitac', undef) if $exitac;
    $self->app->activate_action('exfilename', Glib::Variant->new_string($exfilename)) if $exfilename;
    $self->app->activate_action('delay', Glib::Variant->new_string($delay)) if $delay;
    $self->app->activate_action('include_cursor', undef) if $include_cursor;
    $self->app->activate_action('remove_cursor', undef) if $remove_cursor;
    $self->app->activate_action('nosession', undef) if $nosession;
    
    my %screenshot_cmds = (select => 1, full => 1, window => 1, awindow => 1, menu => 1, tooltip => 1, web => 1, redoshot => 1);
    if ($cmdname && $screenshot_cmds{$cmdname}) {
        $self->app->activate_action($cmdname, $extra ? Glib::Variant->new_string($extra) : undef);
    } else {
        $self->app->activate_action('showmainwindow', undef);
    }
    
    print "\nINFO: There is already another instance of Shutter running!\n";
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