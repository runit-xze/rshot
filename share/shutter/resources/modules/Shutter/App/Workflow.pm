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

package Shutter::App::Workflow;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;

use Shutter::App::AfterCapturePipeline;
use Shutter::App::PinToScreen;

has cli => (is => 'ro', required => 1);
has acp => (is => 'rw');
has pins => (is => 'rw');

sub BUILD ($self) {
    my $sc = $self->cli->sc;
    $self->acp(Shutter::App::AfterCapturePipeline->new($sc, $sc->get_gettext, $self->cli->window));
    $self->pins(Shutter::App::PinToScreen->new);
}

sub get_workflow_widget ($self) {
    return $self->cli->{vbox_workflow};
}

1;

__END__

=head1 NAME

Shutter::App::Workflow – After-capture pipeline setup

=head1 SYNOPSIS

    my $workflow = Shutter::App::Workflow->new(cli => $cli);

=head1 DESCRIPTION

Instantiates the AfterCapturePipeline and PinToScreen objects that handle
the post-capture workflow configuration and window pinning.

=cut