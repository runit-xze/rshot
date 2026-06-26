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

package Shutter::App::UI;

use v5.40;
use feature "try";
no warnings "experimental::try";

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;
use Log::Any;

my $log = Log::Any->get_logger;

# This module provides backward compatibility - it wraps the Common object
# and provides UI setup methods that were previously in bin/shutter
has common => (is => 'ro', required => 1);

sub create_main_window ($self, $app) {
	my $sc     = $self->common;
	my $window = Gtk3::ApplicationWindow->new($app);
	$sc->set_mainwindow($window);
	$window->signal_connect('delete-event' => \&evt_delete_window);
	$window->set_border_width(0);
	$window->set_resizable(TRUE);
	$window->set_focus_on_map(TRUE);
	$window->set_default_size(-1, 500);
	return $window;
}

sub setup_app_objects ($self) {
	my $sc = $self->common;

	my $sas = Shutter::App::Autostart->new();
	my $sm  = Shutter::App::Menu->new($sc);
	my $st  = Shutter::App::Toolbar->new($sc);
	my $sd  = Shutter::App::SimpleDialogs->new($sc->get_mainwindow);

	my $vbox = Gtk3::VBox->new(FALSE, 0);
	$sc->get_mainwindow->add($vbox);

	my $menu    = $sm->create_menu;
	my $toolbar = $st->create_toolbar;

	$log->debug("Packing menu: " . (defined $menu       ? ref($menu)    : "undef"));
	$log->debug("Packing toolbar: " . (defined $toolbar ? ref($toolbar) : "undef"));

	$vbox->pack_start($menu,    FALSE, TRUE, 0);
	$vbox->pack_start($toolbar, FALSE, TRUE, 0);

	my $status = Gtk3::Statusbar->new;
	$status->set_name('main-window-statusbar');
	$vbox->pack_start($status, FALSE, TRUE, 0);

	# Store references for backward compatibility
	$sc->{_sas}    = $sas;
	$sc->{_sm}     = $sm;
	$sc->{_st}     = $st;
	$sc->{_sd}     = $sd;
	$sc->{_vbox}   = $vbox;
	$sc->{_status} = $status;

	return ($sas, $sm, $st, $sd, $vbox, $status);
}

# Accessor for backward compatibility
sub get_common { return $_[0]->common }

1;

__END__

=head1 NAME

Shutter::App::UI – UI orchestration module

=head1 SYNOPSIS

    my $ui = Shutter::App::UI->new(common => $sc);
    $window = $ui->create_main_window($app);
    my ($sm, $st, $sd) = $ui->setup_app_objects()[1,2,3];

=cut
