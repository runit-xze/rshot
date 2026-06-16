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

package Shutter::App::Constants;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Exporter 'import';

our @EXPORT_OK = qw(
    MAX_ERROR
    SHUTTER_REV
    SHUTTER_NAME
    SHUTTER_VERSION
);

use constant MAX_ERROR       => 5;
use constant SHUTTER_REV     => 'Rev.1876';
use constant SHUTTER_NAME    => 'Shutter';
use constant SHUTTER_VERSION => '0.99.7';

1;

__END__

=head1 NAME

Shutter::App::Constants – Project-wide constants

=head1 SYNOPSIS

    use Shutter::App::Constants qw(:all);

=head1 DESCRIPTION

Exports core constants used throughout Shutter.

=cut