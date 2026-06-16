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

package Shutter::App::Handlers::Init_Handlers;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use XML::Simple;
use IO::File;
use URI::Escape qw(uri_unescape);
use File::Basename qw(basename);
use File::Copy qw(copy);

has cli => (is => 'ro', required => 1);

sub fct_check_valid_mime_type {
    foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
        foreach my $mtype (@{$format->get_mime_types}) {
            return TRUE if $mtype eq $_[1];
            last;
        }
    }

    return FALSE;
}

sub fct_drop_handler {
    my ($self, $widget, $context, $x, $y, $selection, $info, $time) = @_;
    my $cli = $self->cli;
    my $d = $cli->sc->get_gettext;
    
    my $type = $selection->get_target->name;
    return unless $type eq 'text/uri-list';
    my $data = $selection->get_data;
    
    my @files = grep defined($_), split /[\r\n]+/, $data;

    my @valid_files;
    my @sxcu_files;
    foreach my $file (@files) {
        my $giofile = Glib::IO::File::new_for_uri($file);
        my $path = $giofile->get_path;
        if ($path && $path =~ /\.sxcu$/i) {
            push @sxcu_files, $path;
        } else {
            my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $path);
            $mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;    #FIXME
            if ($mime_type && $self->fct_check_valid_mime_type($mime_type)) {
                push @valid_files, $file;
            }
        }
    }

    if (@sxcu_files) {
        my $uploaders_dir = $ENV{'HOME'} . '/.shutter/uploaders';
        mkdir $uploaders_dir unless -d $uploaders_dir;
        my $imported = 0;
        foreach my $sxcu (@sxcu_files) {
            my $name = basename($sxcu);
            if (copy($sxcu, "$uploaders_dir/$name")) {
                $imported++;
            }
        }
        $self->fct_show_status_message(3, sprintf($d->nget("Imported %d ShareX custom uploader", "Imported %d ShareX custom uploaders", $imported), $imported)) if defined &fct_show_status_message;
        
        # Re-init upload plugins to load the new ones!
        fct_init_upload_plugins() if defined &fct_init_upload_plugins;
    }

    #open all valid files
    if (@valid_files) {
        $self->fct_open_files(@valid_files);
        Gtk3::drag_finish($context, 1, 0, $time);
        return TRUE;
    } else {
        Gtk3::drag_finish($context, 0, 0, $time);
        return FALSE;
    }
}

sub fct_is_uri_in_session {
    my ($self, $giofile, $jump) = @_;
    my $cli = $self->cli;
    my $session_screens = $cli->{_session_screens};
    my $notebook = $cli->{_notebook};

    return FALSE unless $giofile;

    foreach my $key (keys %$session_screens) {
        if (exists $session_screens->{$key}->{'giofile'}) {
            if ($giofile->equal($session_screens->{$key}->{'giofile'})) {
                if (exists $session_screens->{$key}->{'tab_child'}) {
                    if ($jump && $notebook) {
                        $notebook->set_current_page($notebook->page_num($session_screens->{$key}->{'tab_child'}));
                    }
                    return TRUE;
                }
            }
        }
    }

    return FALSE;
}

sub fct_load_session {
    my ($self) = @_;
    my $cli = $self->cli;
    my $shf = $cli->shf;
    my $d = $cli->sc->get_gettext;
    my $sd = $cli->sc->{_sd};
    my $status = $cli->{_status};
    my $session_start_screen = $cli->{_session_start_screen};

    #session file
    my $sessionfile = "$ENV{ HOME }/.shutter/session.xml";

    eval {
        my $session_xml = XMLin(IO::File->new($sessionfile))
            if $shf->file_exists($sessionfile);

        return FALSE if !defined $session_xml || scalar(keys %{$session_xml}) < 1;

        #activate throbber
        my ($throbber, $sep) = $self->fct_toggle_status_throbber($status);

        #how many files have to be loaded
        #store this value in the session hash
        $session_start_screen->{'first_page'}->{'num_session_files'} = scalar(keys %{$session_xml});

        #local counter
        #is passed to several subroutines to indicate the correct index
        my $count = 0;
        foreach my $key (sort keys %{$session_xml}) {

            #increment counter
            $count++;

            #refresh gui
            $cli->handlers->get('UI_Status')->fct_update_gui();

            #do the real work
            my $new_giofile = Glib::IO::File::new_for_path(${$session_xml}{$key}{'filename'});
            if ($cli->handlers->get('Workflow_Integrate')->fct_integrate_screenshot_in_notebook($new_giofile, undef, undef, $count)) {
                $cli->handlers->get('UI_Status')->fct_show_status_message(1, $shf->utf8_decode($new_giofile->get_path) . " " . $d->get("opened"));
            } else {
                $cli->handlers->get('UI_Status')->fct_show_status_message(1, sprintf($d->get("Error while opening image %s."), "'" . $new_giofile->get_basename . "'"));
            }
        }

        #clear the value after loading the files
        $session_start_screen->{'first_page'}->{'num_session_files'} = undef;

        #de-activate the throbber
        $self->fct_toggle_status_throbber($status, $throbber, $sep);

    };
    if ($@) {
        $sd->dlg_error_message("$@", $d->get("Session could not be restored!"));
        unlink $sessionfile;
    }

    return TRUE;
}

sub fct_open_files {
    my ($self, @new_files) = @_;
    my $cli = $self->cli;
    my $shf = $cli->shf;
    my $d = $cli->sc->get_gettext;
    my $status = $cli->{_status};

    return FALSE if scalar(@new_files) < 1;

    my ($throbber, $sep) = $self->fct_toggle_status_throbber($status);

    foreach my $file (@new_files) {

        my $new_giofile = Glib::IO::File::new_for_uri($shf->utf8_decode(uri_unescape($file)));
        next if $self->fct_is_uri_in_session($new_giofile, TRUE);

        #refresh gui
        $cli->handlers->get('UI_Status')->fct_update_gui();

        #do the real work
        if ($cli->handlers->get('Workflow_Integrate')->fct_integrate_screenshot_in_notebook($new_giofile)) {
            $cli->handlers->get('UI_Status')->fct_show_status_message(1, $shf->utf8_decode($new_giofile->get_path) . " " . $d->get("opened"));
        } else {
            $cli->handlers->get('UI_Status')->fct_show_status_message(1, sprintf($d->get("Error while opening image %s."), "'" . $shf->utf8_decode($new_giofile->get_basename) . "'"));
        }
    }

    $self->fct_toggle_status_throbber($status, $throbber, $sep);

    return TRUE;
}

sub fct_toggle_status_throbber {
    my ($self, $status, $throbber, $sep) = @_;
    my $shutter_root = $self->cli->shutter_root;
    return FALSE unless $status;

    if (defined $throbber && defined $sep) {
        $throbber->destroy;
        $throbber = undef;
        $sep->destroy;
        $sep = undef;
    } else {

        #don't show more than one
        foreach my $child ($status->get_children) {
            if ($child->get_name eq 'throbber') {
                return FALSE;
            }
        }
        $throbber = Gtk3::Image->new_from_file("$shutter_root/share/shutter/resources/icons/throbber_16x16.gif");
        $throbber->set_name('throbber');
        $sep = Gtk3::HSeparator->new;
        $status->pack_start($sep, FALSE, FALSE, 3);
        $status->pack_end($throbber, FALSE, FALSE, 0);
    }

    $status->show_all;

    return ($throbber, $sep);
}


1;

__END__

=head1 NAME

Shutter::App::Handlers::Init_Handlers - File and session initialization handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
