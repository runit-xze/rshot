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

package Shutter::App::Handlers::Workflow_Control;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Net::DBus;
use Log::Any;

my $log = Log::Any->get_logger;

has cli => (is => 'ro', required => 1);

sub fct_control_wm_settings ($self, $mode, $restore_value) {

    #compiz via dbus
    my $bus    = undef;
    my $compiz = undef;
    my $fpl    = undef;

    #disable focus_prevention
    my $curr_value = -1;

    #disable focus prevention when using compiz
    eval {
        $bus = Net::DBus->find;

        #Get a handle to the compiz service
        $compiz = $bus->get_service("org.freedesktop.compiz");

        #Get the relevant object
        $fpl = $compiz->get_object("/org/freedesktop/compiz/core/screen0/focus_prevention_level", "org.freedesktop.compiz");
    };
    if ($@) {
        $log->info("DBus connection to org.freedesktop.compiz failed --> skipping compiz related tasks: $@");
        return $curr_value;
    }

    if (defined $fpl && $fpl) {
        eval {
            if ($mode eq 'start') {

                #save and return current value
                if (defined $fpl && $fpl) {
                    $curr_value = $fpl->get;
                }
                if (defined $fpl && $fpl && $fpl->get != 0) {
                    $fpl->set(0);
                }

                #re-enable focus prevention -> restore value
            } elsif ($mode eq 'stop') {
                if (defined $fpl && $fpl && defined $restore_value) {
                    $fpl->set($restore_value);
                } elsif (defined $fpl && $fpl) {
                    $fpl->set(1);
                }
            }
        };
        if ($@) {
            $log->error("Unable to set/get focus_level_prevention --> skipping compiz related tasks: $@");
        }
    }

    return $curr_value;
}


1;

__END__

=head1 NAME

Shutter::App::Handlers::Workflow_Control - Workflow control handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
