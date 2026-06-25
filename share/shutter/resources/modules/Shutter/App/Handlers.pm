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

package Shutter::App::Handlers;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;

my %_handlers;

sub register_handler ($name, $handler) {
    $_handlers{$name} = $handler;
    return;
}

sub get_handler ($name) {
    return $_handlers{$name};
}

sub call ($name, @args) {
    my $handler = $_handlers{$name};
    die "No handler registered for '$name'" unless $handler;
    return $handler->($name, @args);
}

1;
