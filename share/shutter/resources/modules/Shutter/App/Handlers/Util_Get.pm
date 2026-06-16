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

package Shutter::App::Handlers::Util_Get;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Digest::MD5 qw(md5_hex);

has cli => (is => 'ro', required => 1);

sub fct_get_last_capture {
    my ($self) = @_;
    my $session_start_screen = $self->cli->{_session_start_screen};

    if ($session_start_screen && exists $session_start_screen->{'first_page'}->{'history'}
        && defined $session_start_screen->{'first_page'}->{'history'})
    {
        return $session_start_screen->{'first_page'}->{'history'};
    }
    return FALSE;
}

sub fct_get_next_filename {
    my ($self, $filename_value, $folder, $filetype_value) = @_;
    
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $shf = $cli->shf;
    my $sd = $cli->sc->{_sd};
    my $d = $cli->sc->get_gettext;

    #remove possible dots
    $filetype_value =~ s/\.//;

    $filename_value =~ s/\\//g;

    #random number - should be earlier than %N reading, as $R is actually a part of date
    if ($filename_value =~ /\$R{1,}/) {

        #how many Rs are used? (important for formatting)
        my $pos_proc  = index($filename_value, "\$R", 0);
        my $r_counter = 0;
        my $last_pos  = $pos_proc;
        $pos_proc++;

        while ($pos_proc <= length($filename_value)) {
            $last_pos = index($filename_value, "R", $pos_proc);
            if ($last_pos != -1 && ($last_pos - $pos_proc <= 1)) {
                $r_counter++;
                $pos_proc++;
            } else {
                last;
            }
        }

        #prepare filename
        print "---$r_counter Rs used in wild-card\n" if $sc->get_debug;
        my $marks = "";

        # Md5 will contain a salt (shutter) and a seconds since 1970
        my $md5_data = "shutter" . time;
        my $md5_hash = md5_hex($md5_data);

        # TODO: set random offset? I guess, current implementation is sufficient
        $marks = substr($md5_hash, 0, $r_counter);

        #switch $Rs to a part of the hash
        $filename_value =~ s/\$R{1,}/$marks/g;
    }

    #auto increment  (%NNN is the pattern for the increment placeholder)
    if ($filename_value =~ /\%(N{1,})/) {
        #how many Ns are used? (important for formatting)
        my $n_counter = length($1);

        #prepare filename
        print "$n_counter Ns used in wild-card\n" if $sc->get_debug;

        my $filename_template = quotemeta $filename_value;

        #replace %NNN by a \d+ regex to search for digits
        #also take into account conflicted filenames Ex.: "_014(002)"
        $filename_template =~ s/\\\%N+/(\\d+)(?:\\(\\d+\\))?/g;
        #store regex to string
        my $search_pattern = qr/$filename_template\.$filetype_value/;

        print "Searching for files with pattern: $search_pattern\n"
            if $sc->get_debug;

        #get_all files from directory
        my $dir        = Glib::IO::File::new_for_path($folder);
        my $next_count = 0;
        eval {
            my $enumerator = $dir->enumerate_children('standard::*', []);
            while (my $fileinfo = $enumerator->next_file) {
                my $fname = $shf->utf8_decode($fileinfo->get_name);

                #not a regular file? -> skip
                next unless $fileinfo->get_file_type eq 'regular';

                #does the current file match the pattern?
                if ($fname =~ $search_pattern) {
                    my $curr_value = $1;
                    if ($curr_value && $curr_value > $next_count) {
                        $next_count = $curr_value;
                        print "$next_count is currently greatest value...\n"
                            if $sc->get_debug;
                    }
                }
            }
            $enumerator->close;
        };
        if ($@) {
            my $response = $sd->dlg_error_message(
                sprintf($d->get("Error while opening directory %s."), "'" . $folder . "'"),
                $d->get("There was an error determining the filename."),
                undef, undef, undef, undef, undef, undef, $@
            );
            return FALSE;
        }

        $next_count = 0 unless $next_count =~ /^(\d+\.?\d*|\.\d+)$/;

        $next_count = sprintf("%0" . $n_counter . "d", $next_count + 1);

        #switch placeholder to $next_count
        $filename_value =~ s/\%N+/$next_count/g;

    }

    #create new uri
    my $new_giofile = Glib::IO::File::new_for_path("$folder/$filename_value.$filetype_value");
    if ($new_giofile->query_exists) {
        my $count             = 1;
        my $existing_filename = $filename_value;
        while ($new_giofile->query_exists) {
            $filename_value = $existing_filename . "(" . sprintf("%03d", $count++) . ")";
            $new_giofile    = Glib::IO::File::new_for_path($folder);
            $new_giofile    = $new_giofile->get_child("$filename_value.$filetype_value");
            print "Checking new uri: " . $new_giofile->get_path . "\n"
                if $sc->get_debug;
        }
    }

    return $new_giofile;
}

sub fct_get_program_model {
    my ($self) = @_;
    my $cli = $self->cli;
    my $sc = $cli->sc;
    my $shf = $cli->shf;
    my $d = $sc->get_gettext;
    my $goocanvas = $cli->{_goocanvas};

    my $model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::Scalar');

    #add Shutter's built-in editor to the list
    if ($goocanvas) {
        my $icon_pixbuf = undef;
        my $icon        = 'shutter';
        if ($sc->get_theme->has_icon($icon)) {
            my ($iw, $ih) = $shf->icon_size('menu');
            eval { $icon_pixbuf = $sc->get_theme->load_icon($icon, $ih, 'generic-fallback'); };
            if ($@) {
                print "\nWARNING: Could not load icon $icon: $@\n";
                $icon_pixbuf = undef;
            }
        }
        $model->set($model->append, 0, $icon_pixbuf, 1, $d->get("Built-in Editor"), 2, 'shutter-built-in');
    }

    #get applications
    my $apps = Glib::IO::AppInfo::get_recommended_for_type('image/png');

    # $apps is undefined if Glib::IO::AppInfo::get_recommended_for_type fails
    unless (defined $apps) {
        return $model;
    }

    #no apps determined!
    unless (scalar @$apps) {
        return $model;
    }

    #create menu items
    foreach my $app (@$apps) {

        #ignore Shutter's desktop entry
        next if $app->get_id eq 'shutter.desktop';

        $app->{'name'} = $shf->utf8_decode($app->get_display_name);

        #get icon
        my $icon_pixbuf = undef;
        my $icon        = $app->get_icon;
        if ($icon) {
            my ($iw, $ih) = $shf->icon_size('menu');
            eval {
                my $icon_info = $sc->get_theme->choose_icon($icon->get_names, $ih, []);
                $icon_pixbuf = $icon_info->load_icon if $icon_info;
            };
            if ($@) {
                print "\nWARNING: Could not load icon for ", $app->{'name'}, ": $@\n";
                $icon_pixbuf = undef;
            }
        }
        $model->set($model->append, 0, $icon_pixbuf, 1, $app->{'name'}, 2, $app);
    }

    return $model;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Util_Get - Utility getters handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
