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

package Shutter::App::Handlers::Init_Accounts;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use XML::Simple;
use IO::File;

has cli => (is => 'ro', required => 1);

sub fct_load_accounts ($self, $profilename) {
    my $cli = $self->cli;
    my $shf = $cli->shf;
    my $sc = $cli->sc;
    my $sd = $cli->sc->{_sd};
    my $d = $cli->sc->get_gettext;
    my $accounts = $cli->{_accounts};

    #accounts file
    my $accountsfile = "$ENV{ HOME }/.shutter/accounts.xml";
    $accountsfile = "$ENV{ HOME }/.shutter/profiles/$profilename\_accounts.xml"
        if (defined $profilename);

    if ($shf->file_exists($accountsfile)) {
        my $accounts_xml = undef;
        eval { $accounts_xml = XMLin(IO::File->new($accountsfile)) };
        if ($@) {
            $sd->dlg_error_message($@, $d->get("Account-settings could not be restored!"));
            unlink $accountsfile;
        } else {
            foreach (keys %{$accounts_xml}) {

                #check if plugin still exists
                if ($shf->file_exists($accounts_xml->{$_}->{path})) {

                    #clear cache
                    if (!$sc->get_clear_cache) {
                        $accounts->{$_}->{path}                       = $accounts_xml->{$_}->{path};
                        $accounts->{$_}->{module}                     = $accounts_xml->{$_}->{module};
                        $accounts->{$_}->{host}                       = $accounts_xml->{$_}->{host};
                        $accounts->{$_}->{folder}                     = $accounts_xml->{$_}->{folder};
                        $accounts->{$_}->{description}                = $accounts_xml->{$_}->{description};
                        $accounts->{$_}->{register_color}             = "blue";
                        $accounts->{$_}->{register_text}              = $accounts_xml->{$_}->{register_text};
                        $accounts->{$_}->{supports_anonymous_upload}  = $accounts_xml->{$_}->{supports_anonymous_upload};
                        $accounts->{$_}->{supports_authorized_upload} = $accounts_xml->{$_}->{supports_authorized_upload};
                        $accounts->{$_}->{supports_oauth_upload}      = $accounts_xml->{$_}->{supports_oauth_upload};

                        utf8::decode $accounts->{$_}->{'host'};
                    }
                    $accounts->{$_}->{username} = $accounts_xml->{$_}->{username};
                    $accounts->{$_}->{password} = $accounts_xml->{$_}->{password};

                    utf8::decode $accounts->{$_}->{'username'};
                    utf8::decode $accounts->{$_}->{'password'};
                }
            }
        }
    }

    return TRUE;
}

sub fct_load_accounts_tree ($self) {
    my $accounts = $self->cli->{_accounts};

    my $accounts_model = Gtk3::ListStore->new(
        'Glib::String', 'Glib::String', 'Glib::String',  'Glib::String',  'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String',
        'Glib::String', 'Glib::String', 'Glib::Boolean', 'Glib::Boolean', 'Glib::Boolean'
    );

    foreach (keys %$accounts) {
        my $hidden_text = "";
        for (my $i = 1 ; $i <= length($accounts->{$_}->{'password'}) ; $i++) {
            $hidden_text .= '*';
        }
        $accounts_model->set(
            $accounts_model->append,                       0,  $accounts->{$_}->{'host'},         1,  $accounts->{$_}->{'username'},                  2,
            $hidden_text,                                  3,  $accounts->{$_}->{'not_used_yet'}, 4,  $accounts->{$_}->{'register_color'},            5,
            $accounts->{$_}->{'register_text'},              6,  $accounts->{$_}->{'module'},       7,  $accounts->{$_}->{'path'},                      8,
            $accounts->{$_}->{'folder'},                     9,  $accounts->{$_}->{'description'},  10, $accounts->{$_}->{'supports_anonymous_upload'}, 11,
            $accounts->{$_}->{'supports_authorized_upload'}, 12, $accounts->{$_}->{'supports_oauth_upload'},
        );
    }

    return $accounts_model;
}

sub fct_load_plugin_tree ($self) {
    my $cli = $self->cli;
    my $shutter_root = $cli->shutter_root;
    my $shf = $cli->shf;
    my $lp = $cli->{_lp};
    my $plugins = $cli->{_plugins};

    my $effects_model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String',);
    foreach my $pkey (sort keys %$plugins) {
        if ($plugins->{$pkey}->{'binary'}) {

            #we need to update the pixbuf of the plugins again in some cases
            unless ($plugins->{$pkey}->{'pixbuf'}
                || $plugins->{$pkey}->{'pixbuf_object'})
            {
                $plugins->{$pkey}->{'pixbuf'} = $plugins->{$pkey}->{'binary'} . ".png"
                    if ($shf->file_exists($plugins->{$pkey}->{'binary'} . ".png"));
                $plugins->{$pkey}->{'pixbuf'} = $plugins->{$pkey}->{'binary'} . ".svg"
                    if ($shf->file_exists($plugins->{$pkey}->{'binary'} . ".svg"));

                if ($shf->file_exists($plugins->{$pkey}->{'pixbuf'})) {
                    $plugins->{$pkey}->{'pixbuf_object'} = $lp->load($plugins->{$pkey}->{'pixbuf'}, $shf->icon_size('menu')) if $lp;
                } else {
                    $plugins->{$pkey}->{'pixbuf'}        = "$shutter_root/share/shutter/resources/icons/executable.svg";
                    $plugins->{$pkey}->{'pixbuf_object'} = $lp->load($plugins->{$pkey}->{'pixbuf'}, $shf->icon_size('menu')) if $lp;
                }
            }

            $effects_model->set(
                $effects_model->append,       0, $plugins->{$pkey}->{'pixbuf_object'}, 1, $plugins->{$pkey}->{'name'},   2, $plugins->{$pkey}->{'category'}, 3,
                $plugins->{$pkey}->{'tooltip'}, 4, $plugins->{$pkey}->{'lang'},          5, $plugins->{$pkey}->{'binary'}, 6, $pkey,
            );
        } else {
            print "\nWARNING: Plugin $pkey is not configured properly, ignoring\n";
            delete $plugins->{$pkey};
        }
    }

    return $effects_model;
}


1;

__END__

=head1 NAME

Shutter::App::Handlers::Init_Accounts - Initialization accounts handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
