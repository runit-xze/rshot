###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2020-2021 Google LLC, contributed by Alexey Sokolov <sokolov@google.com>
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

package Shutter::App::Core::UploadManager;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has '_common' => (is => 'ro', required => 1);

sub upload_file ($self, $key, $upload_type) {
    my $sc = $self->_common;
    my $d = $sc->get_gettext;
    my $sd = Shutter::App::SimpleDialogs->new($sc->get_mainwindow);

    return FALSE unless $key;
    return FALSE unless exists $sc->cli->{_session_screens}->{$key};

    my $file = $sc->cli->{_session_screens}->{$key}->{'long'};
    my $userhash = $sc->cli->{settings_manager}->get_setting('general', 'catbox_userhash') // '';
    
    require Shutter::Upload::Catbox;
    my $upload_plugin = Shutter::Upload::Catbox->new(userhash => $userhash);

    my %upload_result = $upload_plugin->upload($file);

    if ($upload_result{success}) {
        $sc->cli->{_session_screens}->{$key}->{'links'}->{'Catbox.moe'} = {
            'direct_link' => $upload_result{url},
            'menuentry'   => 'Catbox.moe',
        };
        fct_show_status_message(1, $d->get("File uploaded successfully"));
        return $upload_result{url};
    } else {
        $sd->dlg_error_message($upload_result{error}, $d->get("Upload failed"));
        return FALSE;
    }
}

1;
