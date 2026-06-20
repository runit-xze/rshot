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

package Shutter::App::Session;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);
has manager => (is => 'rw');
has notebook => (is => 'rw');

sub BUILD ($self, $args) {
    $self->manager(Shutter::App::Core::SessionManager->new(_common => $self->cli->sc));
    $self->notebook(Gtk3::Notebook->new);
    $self->cli->notebook($self->notebook);
    $self->cli->{_notebook} = $self->notebook;
    # Note: fct_create_session_notebook is called from CLI._initialize_modules
    # after handlers are ready. It creates the proper Session tab with IconView,
    # sets scrollable=TRUE, sets up DnD, and connects the switch-page signal.
}

sub create_notebook ($self) {
    return $self->notebook;
}

sub add_tab ($self, $content, $label) {
    my $page_num = $self->notebook->append_page($content, $label);
    $self->notebook->set_current_page($page_num);
    return $page_num;
}

1;

__END__

=head1 NAME

Shutter::App::Session – Session tab management

=head1 SYNOPSIS

    my $session = Shutter::App::Session->new(cli => $cli);
    my $nb = $session->create_notebook();

=head1 DESCRIPTION

Manages the session notebook where screenshots are displayed as tabs.
Wraps SessionManager and provides tab operations.

=cut