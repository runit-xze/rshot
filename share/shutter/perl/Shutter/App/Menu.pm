###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
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

package Shutter::App::Menu;

use Moo;
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Gtk3;

use Glib qw/TRUE FALSE/;

has _common => (
	is       => 'rwp',
	required => 1,
);
has _shf => (
	is       => 'rwp',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build__shf',
);

sub _build__shf ($self) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return Shutter::App::HelperFunctions->new($self->_common);
}

has _menubar => (is => 'rwp', predicate => 1);
has _menuitem_file => (is => 'rwp', predicate => 1);
has _menuitem_edit => (is => 'rwp', predicate => 1);
has _menuitem_view => (is => 'rwp', predicate => 1);
has _menuitem_actions => (is => 'rwp', predicate => 1);
has _menuitem_session => (is => 'rwp', predicate => 1);
has _menuitem_help => (is => 'rwp', predicate => 1);

has _menu_file => (is => 'rwp', predicate => 1);
has _menu_edit => (is => 'rwp', predicate => 1);
has _menu_view => (is => 'rwp', predicate => 1);
has _menu_session => (is => 'rwp', predicate => 1);
has _menu_help => (is => 'rwp', predicate => 1);
has _menu_new => (is => 'rwp', predicate => 1);
has _menu_recent => (is => 'rwp', predicate => 1);

# fct_ret_file_menu items
has _menuitem_new => (is => 'rwp', predicate => 1);
has _menuitem_open => (is => 'rwp', predicate => 1);
has _menuitem_recent => (is => 'rwp', predicate => 1);
has _menuitem_save_as => (is => 'rwp', predicate => 1);
has _menuitem_export_pdf => (is => 'rwp', predicate => 1);
has _menuitem_export_pscript => (is => 'rwp', predicate => 1);
has _menuitem_pagesetup => (is => 'rwp', predicate => 1);
has _menuitem_print => (is => 'rwp', predicate => 1);
has _menuitem_email => (is => 'rwp', predicate => 1);
has _menuitem_close => (is => 'rwp', predicate => 1);
has _menuitem_close_all => (is => 'rwp', predicate => 1);
has _menuitem_quit => (is => 'rwp', predicate => 1);

# fct_ret_edit_menu items
has _menuitem_undo => (is => 'rwp', predicate => 1);
has _menuitem_redo => (is => 'rwp', predicate => 1);
has _menuitem_copy => (is => 'rwp', predicate => 1);
has _menuitem_copy_filename => (is => 'rwp', predicate => 1);
has _menuitem_trash => (is => 'rwp', predicate => 1);
has _menuitem_select_all => (is => 'rwp', predicate => 1);
has _menuitem_quicks => (is => 'rwp', predicate => 1);
has _menuitem_settings => (is => 'rwp', predicate => 1);

# fct_ret_view_menu items
has _menuitem_btoolbar => (is => 'rwp', predicate => 1);
has _menuitem_zoom_in => (is => 'rwp', predicate => 1);
has _menuitem_zoom_out => (is => 'rwp', predicate => 1);
has _menuitem_zoom_100 => (is => 'rwp', predicate => 1);
has _menuitem_zoom_best => (is => 'rwp', predicate => 1);
has _menuitem_fullscreen_image => (is => 'rwp', predicate => 1);
has _menuitem_fullscreen => (is => 'rwp', predicate => 1);

# fct_ret_session_menu items
has _menuitem_back => (is => 'rwp', predicate => 1);
has _menuitem_forward => (is => 'rwp', predicate => 1);
has _menuitem_first => (is => 'rwp', predicate => 1);
has _menuitem_last => (is => 'rwp', predicate => 1);

# fct_ret_help_menu items
has _menuitem_about => (is => 'rwp', predicate => 1);

# fct_ret_new_menu items
has _menuitem_redoshot => (is => 'rwp', predicate => 1);
has _menuitem_selection => (is => 'rwp', predicate => 1);
has _menuitem_full => (is => 'rwp', predicate => 1);
has _menuitem_awindow => (is => 'rwp', predicate => 1);
has _menuitem_window => (is => 'rwp', predicate => 1);
has _menuitem_menu => (is => 'rwp', predicate => 1);
has _menuitem_tooltip => (is => 'rwp', predicate => 1);
has _menuitem_web => (is => 'rwp', predicate => 1);
has _menuitem_gif => (is => 'rwp', predicate => 1);
has _menuitem_video => (is => 'rwp', predicate => 1);
has _menuitem_iclipboard => (is => 'rwp', predicate => 1);

# _build_actions_menu items (normal)
has _menu_actions => (is => 'rwp', predicate => 1);
has _menuitem_reopen => (is => 'rwp', predicate => 1);
has _menuitem_show_in_folder => (is => 'rwp', predicate => 1);
has _menuitem_rename => (is => 'rwp', predicate => 1);
has _menuitem_send => (is => 'rwp', predicate => 1);
has _menuitem_upload => (is => 'rwp', predicate => 1);
has _menuitem_links => (is => 'rwp', predicate => 1);
has _menuitem_draw => (is => 'rwp', predicate => 1);
has _menuitem_plugin => (is => 'rwp', predicate => 1);
has _menuitem_redoshot_this => (is => 'rwp', predicate => 1);

# _build_actions_menu items (large)
has _menu_large_actions => (is => 'rwp', predicate => 1);
has _menuitem_large_reopen => (is => 'rwp', predicate => 1);
has _menuitem_large_show_in_folder => (is => 'rwp', predicate => 1);
has _menuitem_large_rename => (is => 'rwp', predicate => 1);
has _menuitem_large_send => (is => 'rwp', predicate => 1);
has _menuitem_large_upload => (is => 'rwp', predicate => 1);
has _menuitem_large_links => (is => 'rwp', predicate => 1);
has _menuitem_large_copy => (is => 'rwp', predicate => 1);
has _menuitem_large_copy_filename => (is => 'rwp', predicate => 1);
has _menuitem_large_trash => (is => 'rwp', predicate => 1);
has _menuitem_large_draw => (is => 'rwp', predicate => 1);
has _menuitem_large_plugin => (is => 'rwp', predicate => 1);
has _menuitem_large_redoshot_this => (is => 'rwp', predicate => 1);

sub BUILDARGS ($class, @args) {
	return {_common => $args[0]};
}

sub create_menu ($self) {

	my $d            = $self->_common->gettext_object;
	my $shutter_root = $self->_common->shutter_root;

	my $accel_group = Gtk3::AccelGroup->new;
	$self->_common->main_window->add_accel_group($accel_group);

	$self->_set__menubar(Gtk3::MenuBar->new());

	$self->_set__menuitem_file(Gtk3::MenuItem->new_with_mnemonic($d->get('_File')));
	$self->_menuitem_file->set_submenu($self->fct_ret_file_menu($accel_group, $d, $shutter_root));
	$self->_menubar->append($self->_menuitem_file);

	$self->_set__menuitem_edit(Gtk3::MenuItem->new_with_mnemonic($d->get('_Edit')));
	$self->_menuitem_edit->set_submenu($self->fct_ret_edit_menu($accel_group, $d, $shutter_root));
	$self->_menubar->append($self->_menuitem_edit);

	$self->_set__menuitem_view(Gtk3::MenuItem->new_with_mnemonic($d->get('_View')));
	$self->_menuitem_view->set_submenu($self->fct_ret_view_menu($accel_group, $d, $shutter_root));
	$self->_menubar->append($self->_menuitem_view);

	$self->_set__menuitem_actions(Gtk3::MenuItem->new_with_mnemonic($d->get('_Screenshot')));
	$self->_menuitem_actions->set_submenu($self->fct_ret_actions_menu($accel_group, $d, $shutter_root));
	$self->_menubar->append($self->_menuitem_actions);

	$self->_set__menuitem_session(Gtk3::MenuItem->new_with_mnemonic($d->get('_Go')));
	$self->_menuitem_session->set_submenu($self->fct_ret_session_menu($accel_group, $d, $shutter_root));
	$self->_menubar->append($self->_menuitem_session);

	$self->_set__menuitem_help(Gtk3::MenuItem->new_with_mnemonic($d->get('_Help')));
	$self->_menuitem_help->set_submenu($self->fct_ret_help_menu($accel_group, $d, $shutter_root));
	$self->_menubar->append($self->_menuitem_help);

	$self->fct_ret_actions_menu_large($accel_group, $d, $shutter_root);

	return $self->_menubar;
}

sub fct_ret_file_menu ($self, $accel_group, $d, $shutter_root) {

	my $icontheme = $self->_common->icontheme;

	$self->_set__menu_file(Gtk3::Menu->new());

	$self->_set__menuitem_new(Gtk3::ImageMenuItem->new_from_stock('gtk-new'));
	$self->_menuitem_new->set_submenu($self->fct_ret_new_menu($accel_group, $d, $shutter_root));
	$self->_menu_file->append($self->_menuitem_new);

	$self->_menu_file->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_open(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Open...')));
	$self->_menuitem_open->set_image(Gtk3::Image->new_from_stock('gtk-open', 'menu'));
	$self->_menuitem_open->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>O'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_open);

	$self->_set__menuitem_recent(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Recent _Files')));
	$self->_menu_file->append($self->_menuitem_recent);

	$self->_menu_file->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_save_as(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Save _As...')));
	$self->_menuitem_save_as->set_image(Gtk3::Image->new_from_stock('gtk-save-as', 'menu'));
	$self->_menuitem_save_as->set_sensitive(FALSE);
	$self->_menuitem_save_as->add_accelerator('activate', $accel_group, $self->_shf->accel('<Shift><Control>S'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_save_as);

	$self->_set__menuitem_export_pdf(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('E_xport to PDF...')));
	$self->_menuitem_export_pdf->set_sensitive(FALSE);
	$self->_menuitem_export_pdf->add_accelerator('activate', $accel_group, $self->_shf->accel('<Shift><Alt>P'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_export_pdf);

	$self->_set__menuitem_export_pscript(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Export to Post_Script...')));
	$self->_menuitem_export_pscript->set_sensitive(FALSE);
	$self->_menuitem_export_pscript->add_accelerator('activate', $accel_group, $self->_shf->accel('<Shift><Alt>S'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_export_pscript);

	$self->_menu_file->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_pagesetup(Gtk3::ImageMenuItem->new($d->get('Page Set_up')));
	$self->_menuitem_pagesetup->set_image(Gtk3::Image->new_from_icon_name('document-page-setup', 'menu'));
	$self->_menuitem_pagesetup->set_sensitive(FALSE);
	$self->_menu_file->append($self->_menuitem_pagesetup);

	$self->_set__menuitem_print(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Print...')));
	$self->_menuitem_print->set_image(Gtk3::Image->new_from_stock('gtk-print', 'menu'));
	$self->_menuitem_print->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>P'), qw/visible/);
	$self->_menuitem_print->set_sensitive(FALSE);
	$self->_menu_file->append($self->_menuitem_print);

	$self->_menu_file->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_email(Gtk3::ImageMenuItem->new($d->get('Send by E_mail...')));
	$self->_menuitem_email->set_image(Gtk3::Image->new_from_icon_name('mail-send', 'menu'));
	$self->_menuitem_email->set_sensitive(FALSE);
	$self->_menuitem_email->add_accelerator('activate', $accel_group, $self->_shf->accel('<Shift><Control>E'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_email);

	$self->_menu_file->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_close(Gtk3::ImageMenuItem->new_from_stock('gtk-close'));
	$self->_menuitem_close->set_sensitive(FALSE);
	$self->_menuitem_close->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>W'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_close);

	$self->_set__menuitem_close_all(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('C_lose all')));
	$self->_menuitem_close_all->set_image(Gtk3::Image->new_from_stock('gtk-close', 'menu'));
	$self->_menuitem_close_all->set_sensitive(FALSE);
	$self->_menuitem_close_all->add_accelerator('activate', $accel_group, $self->_shf->accel('<Shift><Control>W'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_close_all);

	$self->_menu_file->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_quit(Gtk3::ImageMenuItem->new_from_stock('gtk-quit'));
	$self->_menuitem_quit->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>Q'), qw/visible/);
	$self->_menu_file->append($self->_menuitem_quit);

	return $self->_menu_file;
}

sub fct_ret_edit_menu ($self, $accel_group, $d, $shutter_root) {

	my $icontheme = $self->_common->icontheme;

	$self->_set__menu_edit(Gtk3::Menu->new());

	$self->_set__menuitem_undo(Gtk3::ImageMenuItem->new_from_stock('gtk-undo'));
	$self->_menuitem_undo->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>Z'), qw/visible/);
	$self->_menuitem_undo->set_sensitive(FALSE);
	$self->_menu_edit->append($self->_menuitem_undo);

	$self->_set__menuitem_redo(Gtk3::ImageMenuItem->new_from_stock('gtk-redo'));
	$self->_menuitem_redo->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>Y'), qw/visible/);
	$self->_menuitem_redo->set_sensitive(FALSE);
	$self->_menu_edit->append($self->_menuitem_redo);

	$self->_menu_edit->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_copy(Gtk3::ImageMenuItem->new_from_stock('gtk-copy'));
	$self->_menuitem_copy->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>C'), qw/visible/);
	$self->_menuitem_copy->set_sensitive(FALSE);
	$self->_menu_edit->append($self->_menuitem_copy);

	$self->_set__menuitem_copy_filename(Gtk3::ImageMenuItem->new_from_stock('gtk-copy'));
	$self->_menuitem_copy_filename->get_child->set_text_with_mnemonic($d->get('Copy _Filename'));
	$self->_menuitem_copy_filename->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control><Shift>C'), qw/visible/);
	$self->_menuitem_copy_filename->set_sensitive(FALSE);
	$self->_menu_edit->append($self->_menuitem_copy_filename);

	$self->_set__menuitem_trash(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Move to _Trash')));
	$self->_menuitem_trash->add_accelerator('activate', $accel_group, $self->_shf->accel('Delete'), qw/visible/);
	$self->_menuitem_trash->set_image(Gtk3::Image->new_from_icon_name('user-trash', 'menu'));
	$self->_menuitem_trash->set_sensitive(FALSE);
	$self->_menu_edit->append($self->_menuitem_trash);

	$self->_menu_edit->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_select_all(Gtk3::ImageMenuItem->new_from_stock('gtk-select-all'));
	$self->_menuitem_select_all->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>A'), qw/visible/);
	$self->_menu_edit->append($self->_menuitem_select_all);

	$self->_menu_edit->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_quicks(Gtk3::MenuItem->new_with_mnemonic($d->get('_Quick profile select')));
	$self->_menu_edit->append($self->_menuitem_quicks);

	$self->_menu_edit->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_settings(Gtk3::ImageMenuItem->new_from_stock('gtk-preferences'));
	$self->_menuitem_settings->add_accelerator('activate', $accel_group, $self->_shf->accel('<Mod1>P'), qw/visible/);
	$self->_menu_edit->append($self->_menuitem_settings);

	return $self->_menu_edit;
}

sub fct_ret_view_menu ($self, $accel_group, $d, $shutter_root) {

	my $icontheme = $self->_common->icontheme;

	$self->_set__menu_view(Gtk3::Menu->new());

	$self->_set__menuitem_btoolbar(Gtk3::CheckMenuItem->new_with_mnemonic($d->get('Show Navigation _Toolbar')));
	$self->_menuitem_btoolbar->set_active(FALSE);
	$self->_menu_view->append($self->_menuitem_btoolbar);

	$self->_menu_view->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_zoom_in(Gtk3::ImageMenuItem->new_from_stock('gtk-zoom-in'));
	$self->_menuitem_zoom_in->add_accelerator('activate', $accel_group, $self->_shf->accel('<control>plus'),   qw/visible/);
	$self->_menuitem_zoom_in->add_accelerator('activate', $accel_group, $self->_shf->accel('<control>equal'),  qw/visible/);
	$self->_menuitem_zoom_in->add_accelerator('activate', $accel_group, $self->_shf->accel('<control>KP_Add'), qw/visible/);
	$self->_menuitem_zoom_in->set_sensitive(FALSE);
	$self->_menu_view->append($self->_menuitem_zoom_in);

	$self->_set__menuitem_zoom_out(Gtk3::ImageMenuItem->new_from_stock('gtk-zoom-out'));
	$self->_menuitem_zoom_out->add_accelerator('activate', $accel_group, $self->_shf->accel('<control>minus'),       qw/visible/);
	$self->_menuitem_zoom_out->add_accelerator('activate', $accel_group, $self->_shf->accel('<control>KP_Subtract'), qw/visible/);
	$self->_menuitem_zoom_out->set_sensitive(FALSE);
	$self->_menu_view->append($self->_menuitem_zoom_out);

	$self->_set__menuitem_zoom_100(Gtk3::ImageMenuItem->new_from_stock('gtk-zoom-100'));
	$self->_menuitem_zoom_100->add_accelerator('activate', $accel_group, $self->_shf->accel('<control>0'), qw/visible/);
	$self->_menuitem_zoom_100->set_sensitive(FALSE);
	$self->_menu_view->append($self->_menuitem_zoom_100);

	$self->_set__menuitem_zoom_best(Gtk3::ImageMenuItem->new_from_stock('gtk-zoom-fit'));
	$self->_menuitem_zoom_best->set_sensitive(FALSE);
	$self->_menu_view->append($self->_menuitem_zoom_best);

	$self->_menu_view->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_fullscreen_image(Gtk3::ImageMenuItem->new_from_stock('gtk-fullscreen'));
	$self->_set__menuitem_fullscreen(Gtk3::CheckMenuItem->new_with_label($self->_menuitem_fullscreen_image->get_child->get_text));
	$self->_menuitem_fullscreen->add_accelerator('activate', $accel_group, $self->_shf->accel('F11'), qw/visible/);
	$self->_menu_view->append($self->_menuitem_fullscreen);

	return $self->_menu_view;
}

sub fct_ret_session_menu ($self, $accel_group, $d, $shutter_root) {

	my $icontheme = $self->_common->icontheme;

	$self->_set__menu_session(Gtk3::Menu->new());

	$self->_set__menuitem_back(Gtk3::ImageMenuItem->new_from_stock('gtk-go-back'));
	$self->_menuitem_back->add_accelerator('activate', $accel_group, $self->_shf->accel('<Mod1>Left'), qw/visible/);
	$self->_menu_session->append($self->_menuitem_back);

	$self->_set__menuitem_forward(Gtk3::ImageMenuItem->new_from_stock('gtk-go-forward'));
	$self->_menuitem_forward->add_accelerator('activate', $accel_group, $self->_shf->accel('<Mod1>Right'), qw/visible/);
	$self->_menu_session->append($self->_menuitem_forward);

	$self->_menu_session->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_first(Gtk3::ImageMenuItem->new_from_stock('gtk-goto-first'));
	$self->_menuitem_first->add_accelerator('activate', $accel_group, $self->_shf->accel('<Mod1>Home'), qw/visible/);
	$self->_menu_session->append($self->_menuitem_first);

	$self->_set__menuitem_last(Gtk3::ImageMenuItem->new_from_stock('gtk-goto-last'));
	$self->_menuitem_last->add_accelerator('activate', $accel_group, $self->_shf->accel('<Mod1>End'), qw/visible/);
	$self->_menu_session->append($self->_menuitem_last);

	return $self->_menu_session;
}

sub fct_ret_help_menu ($self, $accel_group, $d, $shutter_root) {

	$self->_set__menu_help(Gtk3::Menu->new());

	$self->_set__menuitem_about(Gtk3::ImageMenuItem->new_from_stock('gtk-about'));
	$self->_menuitem_about->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>I'), qw/visible/);
	$self->_menu_help->append($self->_menuitem_about);

	return $self->_menu_help;
}

sub fct_ret_new_menu ($self, $accel_group, $d, $shutter_root) {

	my $icontheme = $self->_common->icontheme;

	$self->_set__menu_new(Gtk3::Menu->new);

	$self->_set__menuitem_redoshot(Gtk3::ImageMenuItem->new_from_stock('gtk-refresh'));
	$self->_menuitem_redoshot->get_child->set_text_with_mnemonic($d->get('_Redo last screenshot'));
	$self->_menuitem_redoshot->add_accelerator('activate', $accel_group, $self->_shf->accel('F5'), qw/visible/);
	$self->_menuitem_redoshot->set_sensitive(FALSE);
	$self->_menu_new->append($self->_menuitem_redoshot);

	$self->_menu_new->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_selection(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Selection')));

	try {
		my $cursor_img = Gtk3::Gdk::Cursor->new('left_ptr')->get_image;
		die "no cursor image" unless $cursor_img;
		my $ccursor_pb = $cursor_img->scale_simple($self->_shf->icon_size('menu'), 'bilinear');
		$self->_menuitem_selection->set_image(Gtk3::Image->new_from_pixbuf($ccursor_pb));
	} catch ($e) {
		if ($icontheme->has_icon('applications-accessories')) {
			$self->_menuitem_selection->set_image(Gtk3::Image->new_from_icon_name('applications-accessories', 'menu'));
		} else {
			$self->_menuitem_selection
				->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/selection.svg", $self->_shf->icon_size('menu'))));
		}
	}
	$self->_menu_new->append($self->_menuitem_selection);

	$self->_set__menuitem_full(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Desktop')));
	if ($icontheme->has_icon('user-desktop')) {
		$self->_menuitem_full->set_image(Gtk3::Image->new_from_icon_name('user-desktop', 'menu'));
	} elsif ($icontheme->has_icon('desktop')) {
		$self->_menuitem_full->set_image(Gtk3::Image->new_from_icon_name('desktop', 'menu'));
	} else {
		$self->_menuitem_full
			->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/desktop.svg", $self->_shf->icon_size('menu'))));
	}
	$self->_menu_new->append($self->_menuitem_full);

	$self->_set__menuitem_awindow(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Active Window')));
	if ($icontheme->has_icon('preferences-system-windows')) {
		$self->_menuitem_awindow->set_image(Gtk3::Image->new_from_icon_name('preferences-system-windows', 'menu'));
	} else {
		$self->_menuitem_awindow
			->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/sel_window_active.svg", $self->_shf->icon_size('menu'))));
	}
	$self->_menu_new->append($self->_menuitem_awindow);

	$self->_set__menuitem_window(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Select W_indow')));
	if ($icontheme->has_icon('preferences-system-windows')) {
		$self->_menuitem_window->set_image(Gtk3::Image->new_from_icon_name('preferences-system-windows', 'menu'));
	} else {
		$self->_menuitem_window
			->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/sel_window.svg", $self->_shf->icon_size('menu'))));
	}
	$self->_menu_new->append($self->_menuitem_window);

	$self->_set__menuitem_menu(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Menu')));
	if ($icontheme->has_icon('alacarte')) {
		$self->_menuitem_menu->set_image(Gtk3::Image->new_from_icon_name('alacarte', 'menu'));
	} else {
		$self->_menuitem_menu
			->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/sel_window_menu.svg", $self->_shf->icon_size('menu'))));
	}
	$self->_menu_new->append($self->_menuitem_menu);

	$self->_set__menuitem_tooltip(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Tooltip')));
	if ($icontheme->has_icon('help-faq')) {
		$self->_menuitem_tooltip->set_image(Gtk3::Image->new_from_icon_name('help-faq', 'menu'));
	} else {
		$self->_menuitem_tooltip
			->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/sel_window_tooltip.svg", $self->_shf->icon_size('menu'))));
	}
	$self->_menu_new->append($self->_menuitem_tooltip);

	$self->_set__menuitem_web(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Web')));
	if ($icontheme->has_icon('web-browser')) {
		$self->_menuitem_web->set_image(Gtk3::Image->new_from_icon_name('web-browser', 'menu'));
	} else {
		$self->_menuitem_web
			->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/web_image.svg", $self->_shf->icon_size('menu'))));
	}
	$self->_menu_new->append($self->_menuitem_web);

	$self->_set__menuitem_gif(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Record _GIF')));
	$self->_menuitem_gif->set_image(Gtk3::Image->new_from_icon_name('media-record', 'menu'));
	$self->_menuitem_gif->add_accelerator('activate', $accel_group, $self->_shf->accel('<Shift><Control>G'), qw/visible/);
	$self->_menu_new->append($self->_menuitem_gif);

	$self->_set__menuitem_video(Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Record _Video')));
	$self->_menuitem_video->set_image(Gtk3::Image->new_from_icon_name('camera-video', 'menu'));
	$self->_menuitem_video->add_accelerator('activate', $accel_group, $self->_shf->accel('<Shift><Control>V'), qw/visible/);
	$self->_menu_new->append($self->_menuitem_video);

	$self->_menu_new->append(Gtk3::SeparatorMenuItem->new);

	$self->_set__menuitem_iclipboard(Gtk3::ImageMenuItem->new_from_stock('gtk-paste'));
	$self->_menuitem_iclipboard->get_child->set_text_with_mnemonic($d->get('Import from clip_board'));
	$self->_menuitem_iclipboard->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control><Shift>V'), qw/visible/);
	$self->_menu_new->append($self->_menuitem_iclipboard);

	$self->_menu_new->show_all;

	return $self->_menu_new;
}

sub fct_ret_actions_menu ($self, $accel_group, $d, $shutter_root) {
	return $self->_build_actions_menu($accel_group, $d, $shutter_root, '');
}

sub fct_ret_actions_menu_large ($self, $accel_group, $d, $shutter_root) {
	return $self->_build_actions_menu($accel_group, $d, $shutter_root, 'large_');
}

sub _build_actions_menu ($self, $accel_group, $d, $shutter_root, $prefix) {
	my $icontheme  = $self->_common->icontheme;
	my $with_accel = !$prefix;

	my $menu_key    = $prefix ? "_menu_${prefix}actions" : '_menu_actions';
	my $item_prefix = $prefix ? "_menuitem_${prefix}"    : '_menuitem_';
	my $nm_prefix   = $prefix ? 'item-large-'            : 'item-';

	$self->set_attr($menu_key, Gtk3::Menu->new());

	$self->set_attr("${item_prefix}reopen", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Open wit_h')));
	$self->get_attr("${item_prefix}reopen")->set_image(Gtk3::Image->new_from_stock('gtk-open', 'menu'));
	$self->get_attr("${item_prefix}reopen")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}reopen")->set_name($prefix ? 'item-large-reopen-list' : 'item-reopen-list');
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}reopen"));

	$self->set_attr("${item_prefix}show_in_folder", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Show in _folder')));
	$self->get_attr("${item_prefix}show_in_folder")->set_image(Gtk3::Image->new_from_stock('gtk-open', 'menu'));
	$self->get_attr("${item_prefix}show_in_folder")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}show_in_folder")->set_name('item-reopen-default');
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}show_in_folder"));

	$self->set_attr("${item_prefix}rename", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Rename...')));
	$self->get_attr("${item_prefix}rename")->add_accelerator('activate', $accel_group, $self->_shf->accel('F2'), qw/visible/) if $with_accel && $accel_group;
	$self->get_attr("${item_prefix}rename")->set_image(Gtk3::Image->new_from_stock('gtk-edit', 'menu'));
	$self->get_attr("${item_prefix}rename")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}rename")->set_name("${nm_prefix}rename");
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}rename"));

	$self->get_attr($menu_key)->append(Gtk3::SeparatorMenuItem->new);

	$self->set_attr("${item_prefix}send", Gtk3::ImageMenuItem->new($d->get('_Send To...')));
	$self->get_attr("${item_prefix}send")->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>S'), qw/visible/) if $with_accel;
	$self->get_attr("${item_prefix}send")->set_image(Gtk3::Image->new_from_icon_name('document-send', 'menu'));
	$self->get_attr("${item_prefix}send")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}send")->set_name("${nm_prefix}send");
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}send"));

	$self->set_attr("${item_prefix}upload", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('E_xport...')));
	$self->get_attr("${item_prefix}upload")->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>U'), qw/visible/) if $with_accel && $accel_group;
	$self->get_attr("${item_prefix}upload")->set_image(Gtk3::Image->new_from_stock('gtk-network', 'menu'));
	$self->get_attr("${item_prefix}upload")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}upload")->set_name("${nm_prefix}upload");
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}upload"));

	$self->set_attr("${item_prefix}links", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Public URLs')));
	$self->get_attr("${item_prefix}links")->set_image(Gtk3::Image->new_from_stock('gtk-network', 'menu'));
	$self->get_attr("${item_prefix}links")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}links")->set_name("${nm_prefix}links");
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}links"));

	$self->get_attr($menu_key)->append(Gtk3::SeparatorMenuItem->new);

	if ($prefix) {
		$self->set_attr("${item_prefix}copy", Gtk3::ImageMenuItem->new_from_stock('gtk-copy'));
		$self->get_attr("${item_prefix}copy")->set_sensitive(FALSE);
		$self->get_attr("${item_prefix}copy")->set_name("${nm_prefix}copy");
		$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}copy"));

		$self->set_attr("${item_prefix}copy_filename", Gtk3::ImageMenuItem->new_from_stock('gtk-copy'));
		$self->get_attr("${item_prefix}copy_filename")->get_child->set_text_with_mnemonic($d->get('Copy _Filename'));
		$self->get_attr("${item_prefix}copy_filename")->set_sensitive(FALSE);
		$self->get_attr("${item_prefix}copy_filename")->set_name("${nm_prefix}copy-filename");
		$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}copy_filename"));

		$self->set_attr("${item_prefix}trash", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Move to _Trash')));
		$self->get_attr("${item_prefix}trash")->set_image(Gtk3::Image->new_from_icon_name('gnome-stock-trash', 'menu'));
		$self->get_attr("${item_prefix}trash")->set_sensitive(FALSE);
		$self->get_attr("${item_prefix}trash")->set_name("${nm_prefix}trash");
		$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}trash"));

		$self->get_attr($menu_key)->append(Gtk3::SeparatorMenuItem->new);
	}

	$self->set_attr("${item_prefix}draw", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('_Edit...')));
	$self->get_attr("${item_prefix}draw")->set_image(Gtk3::Image->new_from_stock('gtk-edit', 'menu'));
	$self->get_attr("${item_prefix}draw")->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>E'), qw/visible/) if $with_accel && $accel_group;
	if ($icontheme->has_icon('applications-graphics')) {
		$self->get_attr("${item_prefix}draw")->set_image(Gtk3::Image->new_from_icon_name('applications-graphics', 'menu'));
	} else {
		$self->get_attr("${item_prefix}draw")
			->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size("$shutter_root/share/shutter/resources/icons/draw.svg", $self->_shf->icon_size('menu'))));
	}
	$self->get_attr("${item_prefix}draw")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}draw")->set_name("${nm_prefix}draw");
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}draw"));

	my $plugin_label = $prefix ? 'Run a _Plugin...' : 'Run a _plugin...';
	$self->set_attr("${item_prefix}plugin", Gtk3::ImageMenuItem->new_with_mnemonic($d->get($plugin_label)));
	$self->get_attr("${item_prefix}plugin")->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control><Shift>P'), qw/visible/) if $with_accel && $accel_group;
	$self->get_attr("${item_prefix}plugin")->set_image(Gtk3::Image->new_from_stock('gtk-execute', 'menu'));
	$self->get_attr("${item_prefix}plugin")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}plugin")->set_name("${nm_prefix}plugin");
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}plugin"));

	$self->get_attr($menu_key)->append(Gtk3::SeparatorMenuItem->new);

	$self->set_attr("${item_prefix}redoshot_this", Gtk3::ImageMenuItem->new_with_mnemonic($d->get('Redo _this screenshot')));
	$self->get_attr("${item_prefix}redoshot_this")->add_accelerator('activate', $accel_group, $self->_shf->accel('<Control>F5'), qw/visible/) if $with_accel && $accel_group;
	$self->get_attr("${item_prefix}redoshot_this")->set_image(Gtk3::Image->new_from_stock('gtk-refresh', 'menu'));
	$self->get_attr("${item_prefix}redoshot_this")->set_sensitive(FALSE);
	$self->get_attr("${item_prefix}redoshot_this")->set_name("${nm_prefix}redoshot");
	$self->get_attr($menu_key)->append($self->get_attr("${item_prefix}redoshot_this"));

	$self->get_attr($menu_key)->show_all;

	return $self->get_attr($menu_key);
}

sub set_attr ($self, $name, $value) {
	my $setter = "_set_$name";
	return $self->$setter($value);
}

sub get_attr ($self, $name) {
	return $self->$name;
}

1;
