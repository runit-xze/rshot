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

package Shutter::App::UI::Menus;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);
has sm  => (is => 'rw');
has st  => (is => 'rw');

sub BUILD ($self, $args) {
	my $sc   = $self->cli->sc;
	my $vbox = $self->cli->vbox;

	$self->sm($self->cli->{sm} // Shutter::App::Menu->new($sc));
	$self->st($self->cli->{st} // Shutter::App::Toolbar->new($sc));

	my $menu = $self->sm->create_menu;
	print STDERR "Packing menu: " . (defined $menu ? ref($menu) : "undef") . "
";
	$vbox->pack_start($menu, FALSE, TRUE, 0);
	my $toolbar = $self->st->create_toolbar;
	print STDERR "Packing toolbar: " . (defined $toolbar ? ref($toolbar) : "undef") . "
";
	$vbox->pack_start($toolbar, FALSE, TRUE, 0);
	my $nb = $self->cli->notebook;
	print STDERR "Packing notebook: " . (defined $nb ? ref($nb) : "undef") . "\n";
	$vbox->pack_start($nb, TRUE, TRUE, 0) if defined $nb;

	$self->_connect_menu_items;
	$self->_connect_toolbar_items;
	return;
}

sub _connect_menu_items ($self) {
	my $sm = $self->sm;
	my $h  = $self->cli->handlers;

	$sm->_menuitem_open->signal_connect(
		'activate' => sub {
			my @files = grep { $self->cli->shf->file_exists($_) } @ARGV;
			$h->get('Init_Handlers')->fct_open_files(@files);
			$h->get('Core')->fct_control_main_window('show');
		});

	$sm->_menuitem_quit->signal_connect('activate' => sub { $h->get('Core')->evt_delete_window(undef, 'quit') });
	$sm->_menuitem_undo->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_undo() });
	$sm->_menuitem_redo->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_redo() });
	$sm->_menuitem_zoom_in->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_zoom_in() });
	$sm->_menuitem_zoom_out->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_zoom_out() });
	$sm->_menuitem_fullscreen->signal_connect('toggled' => sub ($widget) { $h->get('Edit_Nav')->fct_fullscreen($widget) });
	$sm->_menuitem_about->signal_connect('activate' => sub { $h->get('Core')->evt_about() });
	$sm->_menuitem_settings->signal_connect('activate' => sub { $h->get('Core')->evt_show_settings() });
	$sm->_menuitem_selection->signal_connect('activate' => sub { $h->get('Core')->evt_take_screenshot(undef, 'select', undef, undef) });
	$sm->_menuitem_draw->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_draw() });
	$sm->_menuitem_large_draw->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_draw() });
	$sm->_menuitem_gif->signal_connect('activate' => sub { $h->get('Core')->evt_take_screenshot(undef, 'gif_select', undef, undef) })     if $sm->_menuitem_gif;
	$sm->_menuitem_video->signal_connect('activate' => sub { $h->get('Core')->evt_take_screenshot(undef, 'video_select', undef, undef) }) if $sm->_menuitem_video;
	$sm->_menuitem_upload->signal_connect('activate' => sub { $h->get('Core')->fct_upload() })                                            if $sm->_menuitem_upload;
	$sm->_menuitem_large_upload->signal_connect('activate' => sub { $h->get('Core')->fct_upload() })                                      if $sm->_menuitem_large_upload;

	# Right-click large menu missing handlers
	$sm->_menuitem_large_reopen->signal_connect('activate' => sub { $h->get('Upload_Main')->fct_open_with_program(undef, TRUE) })                   if $sm->_menuitem_large_reopen;
	$sm->_menuitem_large_show_in_folder->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_show_in_folder() })                           if $sm->_menuitem_large_show_in_folder;
	$sm->_menuitem_large_rename->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_rename() })                                           if $sm->_menuitem_large_rename;
	$sm->_menuitem_large_send->signal_connect('activate' => sub { $h->get('Upload_Main')->fct_send() })                                             if $sm->_menuitem_large_send;
	$sm->_menuitem_large_copy->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_clipboard(undef, 'image') })                             if $sm->_menuitem_large_copy;
	$sm->_menuitem_large_copy_filename->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_clipboard(undef, 'filename') })                 if $sm->_menuitem_large_copy_filename;
	$sm->_menuitem_large_trash->signal_connect('activate' => sub { $h->get('Edit_Delete')->fct_delete(undef, 'trash') })                            if $sm->_menuitem_large_trash;
	$sm->_menuitem_large_plugin->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_plugin() })                                           if $sm->_menuitem_large_plugin;
	$sm->_menuitem_large_redoshot_this->signal_connect('activate' => sub { $h->get('Core')->evt_take_screenshot(undef, 'redoshot', undef, undef) }) if $sm->_menuitem_large_redoshot_this;

	# Normal menu missing handlers
	$sm->_menuitem_copy->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_clipboard(undef, 'image') })                        if $sm->_menuitem_copy;
	$sm->_menuitem_copy_filename->signal_connect('activate' => sub { $h->get('Edit_Nav')->fct_clipboard(undef, 'filename') })            if $sm->_menuitem_copy_filename;
	$sm->_menuitem_trash->signal_connect('activate' => sub { $h->get('Edit_Delete')->fct_delete(undef, 'trash') })                       if $sm->_menuitem_trash;
	$sm->_menuitem_reopen->signal_connect('activate' => sub { $h->get('Upload_Main')->fct_open_with_program(undef, TRUE) })              if $sm->_menuitem_reopen;
	$sm->_menuitem_show_in_folder->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_show_in_folder() })                      if $sm->_menuitem_show_in_folder;
	$sm->_menuitem_rename->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_rename() })                                      if $sm->_menuitem_rename;
	$sm->_menuitem_send->signal_connect('activate' => sub { $h->get('Upload_Main')->fct_send() })                                        if $sm->_menuitem_send;
	$sm->_menuitem_plugin->signal_connect('activate' => sub { $h->get('Edit_Draw')->fct_plugin() })                                      if $sm->_menuitem_plugin;
	$sm->_menuitem_redoshot->signal_connect('activate' => sub { $h->get('Core')->evt_take_screenshot(undef, 'redoshot', undef, undef) }) if $sm->_menuitem_redoshot;

	# Go menu items
	$sm->_menuitem_back->signal_connect('activate' => sub { $self->cli->notebook->prev_page() })          if $sm->_menuitem_back;
	$sm->_menuitem_forward->signal_connect('activate' => sub { $self->cli->notebook->next_page() })       if $sm->_menuitem_forward;
	$sm->_menuitem_first->signal_connect('activate' => sub { $self->cli->notebook->set_current_page(0) }) if $sm->_menuitem_first;
	$sm->_menuitem_last->signal_connect('activate' => sub { $self->cli->notebook->set_current_page(-1) }) if $sm->_menuitem_last;
	return;
}

sub _connect_toolbar_items ($self) {
	my $st = $self->st;
	my $h  = $self->cli->handlers;

	$st->_redoshot->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'redoshot', undef, undef) });
	$st->_select->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'select', undef, undef) });
	$st->_full->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'full', undef, undef) });
	$st->_window->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'window', undef, undef) });
	$st->_menu->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'menu', undef, undef) });
	$st->_tooltip->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'tooltip', undef, undef) });
	$st->_gif->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'gif_select', undef, undef) })     if $st->_gif;
	$st->_video->signal_connect('clicked' => sub { $h->get('Core')->evt_take_screenshot(undef, 'video_select', undef, undef) }) if $st->_video;
	$st->_edit->signal_connect('clicked' => sub { $h->get('Edit_Draw')->fct_draw() })                                           if $st->_edit;
	$st->_upload->signal_connect('clicked' => sub { $h->get('Core')->fct_upload() })                                            if $st->_upload;

	# Navigation toolbar
	$st->_back->signal_connect('clicked' => sub { $self->cli->notebook->prev_page() })          if $st->_back;
	$st->_forward->signal_connect('clicked' => sub { $self->cli->notebook->next_page() })       if $st->_forward;
	$st->_first->signal_connect('clicked' => sub { $self->cli->notebook->set_current_page(0) }) if $st->_first;
	$st->_last->signal_connect('clicked' => sub { $self->cli->notebook->set_current_page(-1) }) if $st->_last;
	return;
}

1;

__END__

=head1 NAME

Shutter::App::UI::Menus – Menu and toolbar signal wiring

=head1 SYNOPSIS

    my $menus = Shutter::App::UI::Menus->new(cli => $cli);

=head1 DESCRIPTION

Creates menu and toolbar, then connects all UI signals to handler methods.
Uses handler objects for actual logic implementation.

=cut
