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

package Shutter::App::Handlers::Registry;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;

has cli => (is => 'ro', required => 1);

# Registry cache
has _handlers => (
	is      => 'ro',
	default => sub { {} },
);

sub get ($self, $name) {

	return $self->_handlers->{$name} if exists $self->_handlers->{$name};

	# Factory: Try to load and instantiate
	my $class = "Shutter::App::Handlers::$name";

	eval "use $class;";
	if ($@) {
		die "Could not load handler class $class: $@";
	}

	my $handler = $class->new(cli => $self->cli);
	$self->_handlers->{$name} = $handler;

	return $handler;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Registry - Central handler registry

=head1 DESCRIPTION

Manages instantiation and access to all Shutter handler modules.
Ensures that the CLI object is properly injected into all handlers.

=cut
