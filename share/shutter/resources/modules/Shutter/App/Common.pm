###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2021 Alexander Ruzhnikov <ruzhnikov85@gmail.com>
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

package Shutter::App::Common;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Moo;
use Gtk3;
use Log::Any;

#Gettext and filename parsing
use POSIX qw/ setlocale /;
use Locale::gettext;

#Glib
use Glib qw/ TRUE FALSE /;

has shutter_root => ( is => "ro", required => 1 );
has main_window  => ( is => "rw", required => 1 );
has appname      => ( is => "ro", required => 1 );
has version      => ( is => "ro", required => 1 );
has rev          => ( is => "ro", required => 1 );
has pid          => ( is => "ro", required => 1 );
has cli          => ( is => "ro" );

has debug              => ( is => "rw", default => sub {FALSE} );
has clear_cache        => ( is => "rw", default => sub {FALSE} );
has min                => ( is => "rw", default => sub {FALSE} );
has disable_systray    => ( is => "rw", default => sub {FALSE} );
has exit_after_capture => ( is => "rw", default => sub {FALSE} );
has no_session         => ( is => "rw", default => sub {FALSE} );
has mock_capture       => ( is => "rw", default => sub {FALSE} );

has log_file  => ( is => "rw", default => sub {undef} );
has log_json  => ( is => "rw", default => sub {FALSE} );
has log_level => ( is => "rw", default => sub {"info"} );

# private attributes
has _start_with       => ( is => "rw", lazy => 1 );
has _start_with_extra => ( is => "rw", lazy => 1 );

has profile_to_start_with => ( is => "rw", lazy => 1 );
has export_filename       => ( is => "rw", lazy => 1 );
has delay                 => ( is => "rw", lazy => 1 );
has include_cursor        => ( is => "rw", lazy => 1 );
has remove_cursor         => ( is => "rw", lazy => 1 );

has gettext_object => (
    is      => "rw",
    lazy    => 1,
    builder => sub {
        my $self = shift;

        my $l = Locale::gettext->domain("shutter");
        $l->dir( $self->shutter_root . "/share/locale" );

        return $l;
    },
);

has notification    => ( is => "rw", lazy => 1 );
has global_settings => ( is => "rw", lazy => 1 );

#icontheme to determine if icons exist or not
#in some cases we deliver fallback icons
has icontheme => (
    is      => "rw",
    lazy    => 1,
    builder => "_setup_icontheme",
);

#recently used upload tab
has ruu_tab => ( is => "rw", default => sub {0} );

#... and details
has ruu_hosting => ( is => "rw", default => sub {0} );
has ruu_places  => ( is => "rw", default => sub {0} );

# TODO: this attribute looks like isn't used. Consider to remove it later
has ruu_u1 => ( is => "rw", default => sub {0} );

#recently used save folder
has rusf => ( is => "rw", lazy => 1 );

#recently used open folder
has ruof => ( is => "rw", lazy => 1 );

sub BUILD ($self, $args) {

    setlocale( LC_NUMERIC,  "C" );
    setlocale( LC_MESSAGES, "" );

    $ENV{'SHUTTER_INTL'} = $args->{shutter_root} . "/share/locale";

    return;
}

sub _setup_icontheme ($self) {

    my $theme = Gtk3::IconTheme::get_default();
    $theme->append_search_path( $self->shutter_root . "/share/icons" );

    return $theme;
}

sub get_current_monitor ($self) {

    my ( $window_at_pointer, $x, $y, $mask ) = Gtk3::Gdk::get_default_root_window->get_pointer;
    my $mon = Gtk3::Gdk::Screen::get_default->get_monitor_geometry(
        Gtk3::Gdk::Screen::get_default->get_monitor_at_point( $x, $y ) );

    return ($mon);
}

# Methods that were used in the old implementation and needed for backward compatibility

sub get_root ($self) { return $self->shutter_root  }
sub get_appname ($self) { return $self->appname  }
sub get_version ($self) { return $self->version  }
sub get_rev ($self) { return $self->rev  }
sub get_gettext ($self) { return $self->gettext_object  }
sub get_theme ($self) { return $self->icontheme  }
sub get_helper_functions ($self) { return $self->cli->shf  }
sub get_notification_object ($self) { return $self->notification  }
sub set_notification_object ($self, $val=undef) { $self->notification($val) if defined $val; return }
sub get_globalsettings_object ($self) { return $self->global_settings  }
sub set_globalsettings_object ($self, $val=undef) { $self->global_settings($val) if defined $val; return }
sub get_rusf ($self) { return $self->rusf  }
sub set_rusf ($self, $val=undef) { $self->rusf($val) if defined $val; return }
sub get_ruof ($self) { return $self->ruof  }
sub set_ruof ($self, $val=undef) { $self->ruof($val) if defined $val; return }
sub get_ruu_tab ($self) { return $self->ruu_tab  }
sub set_ruu_tab ($self, $val=undef) { $self->ruu_tab($val) if defined $val; return }
sub get_ruu_hosting ($self) { return $self->ruu_hosting  }
sub set_ruu_hosting ($self, $val=undef) { $self->ruu_hosting($val) if defined $val; return }
sub get_ruu_places ($self) { return $self->ruu_places  }
sub set_ruu_places ($self, $val=undef) { $self->ruu_places($val) if defined $val; return }
sub get_debug ($self) { return $self->debug  }
sub set_debug ($self, $val=undef) { $self->debug($val) if defined $val; return }
sub get_clear_cache ($self) { return $self->clear_cache  }
sub set_clear_cache ($self, $val=undef) { $self->clear_cache($val) if defined $val; return }
sub get_mainwindow ($self) { return $self->main_window  }
sub set_mainwindow ($self, $val=undef) { $self->main_window($val) if defined $val; return }
sub get_min ($self) { return $self->min  }
sub set_min ($self, $val=undef) { $self->min($val) if defined $val; return }
sub get_disable_systray ($self) { return $self->disable_systray  }
sub set_disable_systray ($self, $val=undef) { $self->disable_systray($val) if defined $val; return }
sub get_exit_after_capture ($self) { return $self->exit_after_capture  }
sub set_exit_after_capture ($self, $val=undef) { $self->exit_after_capture($val) if defined $val; return }
sub get_no_session ($self) { return $self->no_session  }
sub set_no_session ($self, $val=undef) { $self->no_session($val) if defined $val; return }
sub get_mock_capture ($self) { return $self->mock_capture  }
sub set_mock_capture ($self, $val=undef) { $self->mock_capture($val) if defined $val; return }

sub get_log_file ($self) { return $self->log_file  }
sub set_log_file ($self, $val=undef) { $self->log_file($val) if defined $val; return }
sub get_log_json ($self) { return $self->log_json  }
sub set_log_json ($self, $val=undef) { $self->log_json($val) if defined $val; return }
sub get_log_level ($self) { return $self->log_level  }
sub set_log_level ($self, $val=undef) { $self->log_level($val) if defined $val; return }

sub get_start_with ($self) {
    return ( $self->_start_with, $self->_start_with_extra );
}

sub set_start_with ($self, @args) {
    if (@args) {
        $self->_start_with(shift @args);
        $self->_start_with_extra(shift @args);
    }

    return ( $self->_start_with, $self->_start_with_extra );
}

sub get_profile_to_start_with ($self) { return $self->profile_to_start_with  }
sub set_profile_to_start_with ($self, $val=undef) { $self->profile_to_start_with($val) if defined $val; return }
sub get_export_filename ($self) { return $self->export_filename  }
sub set_export_filename ($self, $val=undef) { $self->export_filename($val) if defined $val; return }
sub get_include_cursor ($self) { return $self->include_cursor  }
sub set_include_cursor ($self, $val=undef) { $self->include_cursor($val) if defined $val; return }
sub get_remove_cursor ($self) { return $self->remove_cursor  }
sub set_remove_cursor ($self, $val=undef) { $self->remove_cursor($val) if defined $val; return }
sub get_delay ($self) { return $self->delay  }
sub set_delay ($self, $val=undef) { $self->delay($val) if defined $val; return }

1;
