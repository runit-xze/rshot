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

package Shutter::App::Handlers::Dialogs_Settings;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Shutter::App::UI::SettingsDialog;

has cli => (is => 'ro', required => 1);

sub evt_show_settings ($self) {
    my $sd = Shutter::App::UI::SettingsDialog->new(cli => $self->cli);
    $sd->create_settings_dialog($self->cli->window);
    $sd->show;
    $sd->save;
    $sd->hide;
    return;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Dialogs_Settings - Settings dialog handlers

=head1 DESCRIPTION

Manages the lifecycle of the settings (preferences) dialog.

=cut
