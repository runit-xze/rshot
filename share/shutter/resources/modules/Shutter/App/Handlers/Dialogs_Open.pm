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

package Shutter::App::Handlers::Dialogs_Open;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use File::Basename qw(fileparse);
use Shutter::App::SimpleDialogs;

has cli => (is => 'ro', required => 1);

sub dlg_open ($self, $widget, $data) {
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $window = $cli->window;
    my $d = $sc->get_gettext;
    my $lp_ne = $cli->{_lp_ne};
    my $shf = $cli->shf;
    my $session_screens = $cli->{_session_screens};
    my $saveDir_button = $cli->{_saveDir_button};
    my $sm = $cli->{_sm};

    print "\n$data was emitted by widget $widget\n"
        if $sc->get_debug && defined $data && defined $widget;

    #do we need to open a filechooserdialog?
    #maybe we open a recently opened file that is
    #selected via menu
    my @new_files;
    if ($widget !~ /Gtk3::RecentChooserMenu/) {
        my $fs = Gtk3::FileChooserDialog->new(
            $d->get("Choose file to open"), $window,
            'open',
            'gtk-cancel' => 'reject',
            'gtk-open'   => 'accept'
        );
        $fs->set_select_multiple(TRUE);

        #preview widget
        my $iprev = Gtk3::Image->new;
        $fs->set_preview_widget($iprev);

        $fs->signal_connect(
            'selection-changed' => sub {
                if (my $pfilename = $fs->get_preview_filename) {
                    #without error dialog
                    my $pixbuf = $lp_ne->load($pfilename, 200, 200, TRUE, TRUE) if $lp_ne;
                    unless (defined $pixbuf) {
                        $fs->set_preview_widget_active(FALSE);
                    } else {
                        $fs->get_preview_widget->set_from_pixbuf($pixbuf);
                        $fs->set_preview_widget_active(TRUE);
                    }
                } else {
                    $fs->set_preview_widget_active(FALSE);
                }
            });

        my $filter_all = Gtk3::FileFilter->new;
        $filter_all->set_name($d->get("All compatible image formats"));
        $fs->add_filter($filter_all);

        foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
            my $filter = Gtk3::FileFilter->new;

            #add all known formats to the dialog
            $filter->set_name($format->get_name . " - " . $format->get_description);

            foreach my $ext (@{$format->get_extensions}) {
                $filter->add_pattern("*." . uc $ext);
                $filter_all->add_pattern("*." . uc $ext);
                $filter->add_pattern("*." . $ext);
                $filter_all->add_pattern("*." . $ext);
            }
            $fs->add_filter($filter);
        }

        #set default filter
        $fs->set_filter($filter_all);

        #get current file
        my $key = fct_get_current_file() if defined &fct_get_current_file;

        #go to recently used folder
        if (defined $sc->get_ruof && $shf->folder_exists($sc->get_ruof)) {
            $fs->set_current_folder_uri($sc->get_ruof);
        } else {
            if ($key && $session_screens->{$key} && $session_screens->{$key}->{'long'}) {
                $fs->set_filename($session_screens->{$key}->{'long'});
            } elsif ($saveDir_button && $saveDir_button->get_filename) {
                $fs->set_current_folder($saveDir_button->get_filename);
            } else {
                $fs->set_current_folder($ENV{'HOME'});
            }
        }

        my $fs_resp = $fs->run;

        if ($fs_resp eq "accept") {
            @new_files = @{$fs->get_uris};

            #keep folder in mind
            if ($new_files[0]) {
                my ($oshort, $ofolder, $oext) = fileparse($new_files[0], qr/\.[^.]*/);
                $sc->set_ruof($ofolder) if defined $ofolder;
            }

            $fs->destroy();
        } else {
            $fs->destroy();
        }

    } else {
        if ($sm && $sm->{_menu_recent} && $sm->{_menu_recent}->get_current_item) {
            print "Trying to open file via RecentChooserMenu ", $sm->{_menu_recent}->get_current_item->get_uri, "\n"
                if $sc->get_debug;
            push @new_files, $sm->{_menu_recent}->get_current_item->get_uri;
        }
    }

    #call function to open files - with progress bar etc.
    fct_open_files(@new_files) if defined &fct_open_files;

    return TRUE;
}

sub dlg_save_as ($self, $key, $rfiletype, $rfilename, $rpixbuf, $rquality) {
    
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $window = $cli->window;
    my $d = $sc->get_gettext;
    my $shf = $cli->shf;
    my $session_screens = $cli->{_session_screens};
    my $saveDir_button = $cli->{_saveDir_button};
    my $lp_ne = $cli->{_lp_ne};
    my $sp = $cli->{_sp};

    $rfilename = $session_screens->{$key}->{'long'} if $key && $session_screens->{$key};

    my $fs = Gtk3::FileChooserDialog->new(
        $d->get("Choose a location to save to"),
        $window, 'save',
        'gtk-cancel' => 'reject',
        'gtk-save'   => 'accept'
    );

    #parse filename
    my ($short, $folder, $ext) = ('', '', '');
    ($short, $folder, $ext) = fileparse($rfilename, qr/\.[^.]*/) if defined $rfilename;

    #go to recently used folder
    if (defined $sc->get_rusf && $shf->folder_exists($sc->get_rusf)) {
        $fs->set_current_folder($sc->get_rusf);
        $fs->set_current_name($short . $ext);
    } elsif (defined $key
        && defined $session_screens->{$key}->{'is_unsaved'}
        && $session_screens->{$key}->{'is_unsaved'})
    {
        $fs->set_current_folder($saveDir_button->get_current_folder) if $saveDir_button;
        $fs->set_current_name($short . $ext);
    } else {
        $fs->set_current_folder($folder) if $folder;
        $fs->set_current_name($short . $ext) if $short || $ext;
    }

    #preview widget
    my $iprev = Gtk3::Image->new;
    $fs->set_preview_widget($iprev);

    $fs->signal_connect(
        'selection-changed' => sub {
            if (my $pfilename = $fs->get_preview_filename) {
                #without error dialog
                my $pixbuf = $lp_ne->load($pfilename, 200, 200, TRUE, TRUE) if $lp_ne;
                unless (defined $pixbuf) {
                    $fs->set_preview_widget_active(FALSE);
                } else {
                    $fs->get_preview_widget->set_from_pixbuf($pixbuf);
                    $fs->set_preview_widget_active(TRUE);
                }
            } else {
                $fs->set_preview_widget_active(FALSE);
            }
        });

    #change extension related to the requested filetype
    if (defined $rfiletype && defined $rfilename) {
        my ($short_tmp, $folder_tmp, $ext_tmp) = fileparse($rfilename, qr/\.[^.]*/);
        $fs->set_current_name($short_tmp . "." . $rfiletype);
    }

    my $extra_hbox = Gtk3::HBox->new(FALSE, 5);

    my $label_save_as_type = Gtk3::Label->new($d->get("Image format") . ":");

    my $combobox_save_as_type = Gtk3::ComboBoxText->new;

    #add supported formats to combobox
    my $counter     = 0;
    my $png_counter = undef;

    #add pdf support
    if (defined $rfiletype && $rfiletype eq 'pdf') {

        $combobox_save_as_type->insert_text($counter, "pdf - Portable Document Format");
        $combobox_save_as_type->set_active(0);

    } elsif (defined $rfiletype && $rfiletype eq 'ps') {

        $combobox_save_as_type->insert_text($counter, "ps - PostScript");
        $combobox_save_as_type->set_active(0);

        #images
    } else {

        foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {

            #we don't want svg here - this is a dedicated action in the DrawingTool
            next if !defined $rfiletype && $format->get_name =~ /svg/;

            #we have a requested filetype - nothing else will be offered
            next if defined $rfiletype && $format->get_name ne $rfiletype;

            #we want jpg not jpeg
            if ($format->get_name eq "jpeg" || $format->get_name eq "jpg") {
                $combobox_save_as_type->insert_text($counter, "jpg" . " - " . $format->get_description);
            } else {
                $combobox_save_as_type->insert_text($counter, $format->get_name . " - " . $format->get_description);
            }

            #set active when mime_type is matching
            #loop because multiple mime types are registered for fome file formats
            foreach my $mime (@{$format->get_mime_types}) {

                if (defined $key) {
                    if (defined $session_screens->{$key} && $mime eq $session_screens->{$key}->{'mime_type'}
                        || defined $rfiletype)
                    {
                        $combobox_save_as_type->set_active($counter);
                    }
                } else {

                    #Fix Bug #966159
                    if (defined $rfilename) {
                        my ($short_tmp, $folder_tmp, $ext_tmp) = fileparse($rfilename, qr/\.[^.]*/);
                        if ($mime eq "image/jpeg" && $ext_tmp eq ".jpg"
                            || $mime eq "image/png" && $ext_tmp eq ".png"
                            || $mime eq "image/bmp" && $ext_tmp eq ".bmp"
                            || $mime eq "image/webp" && $ext_tmp eq ".webp"
                            || $mime eq "image/avif" && $ext_tmp eq ".avif") {
                            $combobox_save_as_type->set_active($counter);
                        }
                    }
                }

                #save png_counter as well as fallback
                $png_counter = $counter if $mime eq 'image/png';
            }

            $counter++;

        }

    }

    #something went wrong here
    #filetype was not detected automatically
    #set to png as default
    unless ($combobox_save_as_type->get_active_text) {
        if (defined $png_counter) {
            $combobox_save_as_type->set_active($png_counter);
        }
    }

    $combobox_save_as_type->signal_connect(
        'changed' => sub {
            my $filename = $shf->utf8_decode($fs->get_filename);

            my $choosen_format = $combobox_save_as_type->get_active_text;
            if ($choosen_format) {
                $choosen_format =~ s/ \-.*//;    #get png or jpeg (jpg) for example
                                                #~ print $choosen_format . "\n";

                #parse filename
                my ($short_tmp, $folder_tmp, $ext_tmp) = fileparse($filename, qr/\.[^.]*/);

                $fs->set_current_name($short_tmp . "." . $choosen_format);
            }
        });

    #emit the signal once in order to invoke the sub above
    #~ $combobox_save_as_type->signal_emit('changed');

    $extra_hbox->pack_start($label_save_as_type,    FALSE, FALSE, 5);
    $extra_hbox->pack_start($combobox_save_as_type, FALSE, FALSE, 5);

    my $align_save_as_type = Gtk3::Alignment->new(1, 0, 0, 0);

    $align_save_as_type->add($extra_hbox);
    $align_save_as_type->show_all;

    $fs->set_extra_widget($align_save_as_type);

    my $fs_resp = $fs->run;

    if ($fs_resp eq "accept") {
        my $filename = $shf->utf8_decode($fs->get_filename);

        #parse filename
        my ($short_tmp, $folder_tmp, $ext_tmp) = fileparse($filename, qr/\.[^.]*/);

        #keep selected folder in mind
        $sc->set_rusf($folder_tmp);

        #handle file format
        my $choosen_format = $combobox_save_as_type->get_active_text;
        $choosen_format =~ s/ \-.*// if $choosen_format;    #get png or jpeg (jpg) for example

        $filename = $folder_tmp . $short_tmp . "." . $choosen_format if $choosen_format;

        unless ($shf->file_exists($filename)) {

            #get pixbuf from param
            my $pixbuf = $rpixbuf;
            unless ($pixbuf) {
                #or load pixbuf from existing file
                $pixbuf = $lp_ne->load($rfilename) if $lp_ne;
            }

            #save as (pixbuf, new_filename, filetype, quality - auto here, old_filename)
            if ($sp && $sp->save_pixbuf_to_file($pixbuf, $filename, $choosen_format, $rquality)) {

                if ($key) {

                    #do not try to update when exporting to pdf or ps
                    unless (defined $rfiletype
                        && ($rfiletype eq 'pdf' || $rfiletype eq 'ps'))
                    {

                        #cancel handle
                        if (exists $session_screens->{$key}->{'handle'}) {

                            $session_screens->{$key}->{'handle'}->cancel;
                        }
                        if (defined &fct_update_tab && fct_update_tab($key, undef, Glib::IO::File::new_for_path($filename), FALSE, 'clear')) {

                            #setup a new filemonitor, so we get noticed if the file changed
                            fct_add_file_monitor($key) if defined &fct_add_file_monitor;

                            fct_show_status_message(1, "$session_screens->{ $key }->{ 'long' } " . $d->get("saved")) if defined &fct_show_status_message;
                        }

                    } else {
                        if ($shf->file_exists($filename)) {
                            fct_show_status_message(1, "$filename " . $d->get("saved")) if defined &fct_show_status_message;
                        }
                    }

                }

                #successfully saved
                $fs->destroy();
                return $filename;

            } else {

                #error while saving
                $fs->destroy();
                return FALSE;

            }

        } else {

            #ask the user to replace the image
            #replace button
            my $replace_btn = Gtk3::Button->new_with_mnemonic($d->get("_Replace"));
            $replace_btn->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'button'));

            my $sd_local = Shutter::App::SimpleDialogs->new($window);

            my $response = $sd_local->dlg_warning_message(
                sprintf($d->get("The image already exists in %s. Replacing it will overwrite its contents."), "'" . $folder_tmp . "'"),
                sprintf($d->get("An image named %s already exists. Do you want to replace it?"),              "'" . $short_tmp . "." . $choosen_format . "'"),
                undef, undef, undef, $replace_btn, undef, undef
            );

            if ($response == 40) {

                #get pixbuf from param
                my $pixbuf = $rpixbuf;
                unless ($pixbuf) {
                    #or load pixbuf from existing file
                    $pixbuf = $lp_ne->load($rfilename) if $lp_ne;
                }

                if ($sp && $sp->save_pixbuf_to_file($pixbuf, $filename, $choosen_format, $rquality)) {

                    if ($key) {

                        #do not try to update when exporting to pdf
                        unless (defined $rfiletype
                            && ($rfiletype eq 'pdf' || $rfiletype eq 'ps'))
                        {

                            #cancel handle
                            if (exists $session_screens->{$key}->{'handle'}) {

                                $session_screens->{$key}->{'handle'}->cancel;
                            }

                            if (defined &fct_update_tab && fct_update_tab($key, undef, Glib::IO::File::new_for_path($filename), FALSE, 'clear')) {

                                #setup a new filemonitor, so we get noticed if the file changed
                                fct_add_file_monitor($key) if defined &fct_add_file_monitor;

                                #maybe file is in session as well, need to set the handler again ;-)
                                foreach my $searchkey (keys %$session_screens) {
                                    next if $key eq $searchkey;
                                    if ($session_screens->{$searchkey}->{'long'} eq $filename) {
                                        $session_screens->{$searchkey}->{'changed'} = TRUE;
                                        fct_update_tab($searchkey, undef, undef, FALSE, 'clear');
                                    }
                                }

                                fct_show_status_message(1, "$session_screens->{ $key }->{ 'long' } " . $d->get("saved")) if defined &fct_show_status_message;

                            }

                        } else {
                            if ($shf->file_exists($filename)) {
                                fct_show_status_message(1, "$filename " . $d->get("saved")) if defined &fct_show_status_message;
                            }
                        }

                    }    #end if $key

                    #successfully saved
                    $fs->destroy();
                    return $filename;

                } else {

                    #error while saving
                    $fs->destroy();
                    return FALSE;

                }

            } else {

                #user cancelled overwrite
                $fs->destroy();
                return 'user_cancel';

            }

        }

    } else {

        #user cancelled
        $fs->destroy();
        return 'user_cancel';
    }

    $fs->destroy();
    return;

}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Dialogs_Open - Open and Save As dialog handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
