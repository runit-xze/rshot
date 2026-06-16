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

package Shutter::App::Init;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;

use Shutter::App::Constants qw(:all);
use Shutter::App::Autostart;
use Shutter::App::Menu;
use Shutter::App::Toolbar;
use Shutter::App::SimpleDialogs;
use Shutter::Pixbuf::Save;
use Shutter::Pixbuf::Load;
use Shutter::App::AfterCapturePipeline;
use Shutter::App::PinToScreen;
use Shutter::Geometry::Region;

sub initialize ($cli) {
    my $sc = $cli->sc;
    
    my %globals = (
        plugins => {},
        accounts => {},
        settings => {},
        supported_formats => [],
    );
    
    my $sas  = Shutter::App::Autostart->new();
    my $sm   = Shutter::App::Menu->new($sc);
    my $st   = Shutter::App::Toolbar->new($sc);
    my $sd   = Shutter::App::SimpleDialogs->new($cli->window);
    
    my $sp    = Shutter::Pixbuf::Save->new($sc);
    my $lp    = Shutter::Pixbuf::Load->new($sc);
    my $lp_ne = Shutter::Pixbuf::Load->new($sc, undef, TRUE);
    
    my $acp  = Shutter::App::AfterCapturePipeline->new($sc, $sc->get_gettext, $cli->window);
    my $pins = Shutter::App::PinToScreen->new();
    
    $cli->{_globals} = \%globals;
    $cli->{sas} = $sas;
    $cli->{sm} = $sm;
    $cli->{st} = $st;
    $cli->{sd} = $sd;
    $cli->{sp} = $sp;
    $cli->{lp} = $lp;
    $cli->{lp_ne} = $lp_ne;
    $cli->{acp} = $acp;
    $cli->{pins} = $pins;
    
    return \%globals;
}

1;

__END__

=head1 NAME

Shutter::App::Init – Core object initialization

=head1 SYNOPSIS

    my $globals = Shutter::App::Init::initialize($cli);

=head1 DESCRIPTION

Creates and initializes all core application objects. Returns a hashref
containing global state used by other modules.

=cut