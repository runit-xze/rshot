###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 3 of the License, or
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

# The Gtk3::IconSize::lookup override is installed by bin/rshot via
# Shutter::App::Compat::Gtk3IconSize. DrawingTool no longer monkey-patches
# the Gtk3 namespace itself.

package Shutter::Draw::DrawingTool;

use utf8;
use v5.40;
use Moo;
use feature "try";
no warnings "experimental::try";

use constant {DEFAULT_FONT => "Sans Regular 16"};

use Gtk3;
use GooCanvas2;
use GooCanvas2::CairoTypes;
use File::Basename qw/ fileparse dirname basename /;
use File::Glob     qw/ bsd_glob /;
use File::Temp     qw/ tempfile tempdir /;

use Glib qw/TRUE FALSE/;
use Gtk3::ImageView;

use Shutter::App::Core::ClipboardAPI;
require Shutter::Draw::Utils;
require Shutter::App::Directories;
use Shutter::App::HelperFunctions;
require Shutter::Draw::UIManager;

# Constructor argument
has '_sc' => (is => 'ro', required => 1);

# Derived objects
has '_shf'              => (is => 'rw');
has '_view'             => (is => 'rw');
has '_selector'         => (is => 'rw');
has '_dragger'          => (is => 'rw');
has '_view_css_provider_alpha' => (is => 'rw');
has '_clipboard'        => (is => 'rw');

# File state
has '_filename'         => (is => 'rw');
has '_filetype'         => (is => 'rw');
has '_mimetype'         => (is => 'rw');
has '_import_hash'      => (is => 'rw');

# Cursors, UI, Canvas
has '_cursors'          => (is => 'rw');
has '_uimanager'        => (is => 'rw');
has '_factory'          => (is => 'rw');
has '_canvas'           => (is => 'rw');

# Items
has '_items'            => (is => 'rw');
has '_items_history'    => (is => 'rw');
has '_uid'              => (is => 'rw');

# Undo/redo stacks
has '_undo'             => (is => 'rw');
has '_redo'             => (is => 'rw');

# Autoscroll
has '_autoscroll'       => (is => 'rw');

# Drawing colors, line width, font
has '_fill_color'       => (is => 'rw');
has '_stroke_color'     => (is => 'rw');
has '_line_width'       => (is => 'rw');
has '_font'             => (is => 'rw');

# Style
has '_style'            => (is => 'rw');
has '_style_bg'         => (is => 'rw');

# Last remembered drawing settings
has '_last_fill_color'      => (is => 'rw');
has '_last_stroke_color'    => (is => 'rw');
has '_last_line_width'      => (is => 'rw');
has '_last_font'            => (is => 'rw');

# Status variables
has '_busy'                 => (is => 'rw');
has '_current_item'         => (is => 'rw');
has '_current_new_item'     => (is => 'rw');
has '_current_copy_item'    => (is => 'rw');
has '_last_mode'            => (is => 'rw');
has '_current_mode'         => (is => 'rw');
has '_current_mode_descr'   => (is => 'rw');
has '_current_pixbuf'       => (is => 'rw');
has '_current_pixbuf_filename' => (is => 'rw');
has '_cut'                  => (is => 'rw');
has '_start_time'           => (is => 'rw');

# Stipple pixbuf for censor tool
has '_stipple_pixbuf'       => (is => 'rw');

# UI widgets set by ToolbarManager during show()
has '_d'                        => (is => 'rw');
has '_dicons'                   => (is => 'rw');
has '_icons'                    => (is => 'rw');
has '_drawing_window'           => (is => 'rw');
has '_name'                     => (is => 'rw');
has '_line_spin_w'              => (is => 'rw');
has '_line_spin_wh'             => (is => 'rw');
has '_stroke_color_w'           => (is => 'rw');
has '_stroke_color_wh'          => (is => 'rw');
has '_fill_color_w'             => (is => 'rw');
has '_fill_color_wh'            => (is => 'rw');
has '_font_btn_w'               => (is => 'rw');
has '_font_btn_wh'              => (is => 'rw');
has '_scrolled_window'          => (is => 'rw');
has '_drawing_statusbar'        => (is => 'rw');
has '_drawing_statusbar_image'  => (is => 'rw');
has '_canvas_bg'                => (is => 'rw');
has '_canvas_bg_rect'           => (is => 'rw');
has '_drawing_pixbuf'           => (is => 'rw');
has '_drawing_inner_vbox'       => (is => 'rw');
has '_drawing_inner_vbox_c'     => (is => 'rw');
has '_table'                    => (is => 'rw');
has '_bhbox'                    => (is => 'rw');
has '_selector_handler'         => (is => 'rw');
has '_x_spin_w'                 => (is => 'rw');
has '_y_spin_w'                 => (is => 'rw');
has '_width_spin_w'             => (is => 'rw');
has '_height_spin_w'            => (is => 'rw');
has '_x_spin_w_handler'         => (is => 'rw');
has '_y_spin_w_handler'         => (is => 'rw');
has '_width_spin_w_handler'     => (is => 'rw');
has '_height_spin_w_handler'    => (is => 'rw');
has '_lp'                       => (is => 'rw');
has '_lp_ne'                    => (is => 'rw');
has '_dialogs'                  => (is => 'rw');
has '_drawing_vbox'             => (is => 'rw');
has '_drawing_hbox'             => (is => 'rw');
has '_drawing_hbox_c'           => (is => 'rw');
has '_scrolled_window_c'        => (is => 'rw');
has '_rframe_c'                 => (is => 'rw');
has '_btn_ok_c'                 => (is => 'rw');
has '_hscroll_hid'              => (is => 'rw');
has '_vscroll_hid'              => (is => 'rw');
has '_root'                     => (is => 'rw');
has '_is_unsaved'               => (is => 'rw');

# Canvas overlays (set by ToolbarManager)
has '_canvas_overlays'          => (is => 'rw');

# Manager objects
has '_toolbar_manager'          => (is => 'rw');
has '_context_menu_manager'     => (is => 'rw');
has '_settings_manager'         => (is => 'rw');
has '_mouse_manager'            => (is => 'rw');
has '_macro_manager'            => (is => 'rw');
has '_item_factory'             => (is => 'rw');
has '_canvas_manager'           => (is => 'rw');
has '_property_manager'         => (is => 'rw');
has '_io_manager'               => (is => 'rw');
has '_state_manager'            => (is => 'rw');
has '_undo_manager'             => (is => 'rw');

sub BUILDARGS {
	my ($class, $sc) = @_;
	return { _sc => $sc };
}

sub BUILD ($self) {

	$self->_shf(Shutter::App::HelperFunctions->new($self->_sc));

	#view, selector, dragger
	$self->_view(Gtk3::ImageView->new);
	$self->_selector(Gtk3::ImageView::Tool::Selector->new($self->_view));
	$self->_dragger(Gtk3::ImageView::Tool::Dragger->new($self->_view));
	$self->_view->set_tool($self->_selector);
	$self->_view_css_provider_alpha(Gtk3::CssProvider->new);
	$self->_view->get_style_context->add_provider($self->_view_css_provider_alpha, 0);
	$self->_view->set('zoom-step', 1.2);

	# Note: Remap scroll direction because Gtk3::ImageView maps left/right incorrectly
	# upstream bug: http://trac.bjourne.webfactional.com/ticket/21
	#left  => zoom in
	#right => zoom out
	$self->_view->signal_connect(
		'scroll-event',
		sub {
			my ($view, $ev) = @_;
			if ($ev->direction eq 'left') {
				$ev->direction('up');
			} elsif ($ev->direction eq 'right') {
				$ev->direction('down');
			}
			return FALSE;
		});

	#handle zoom events
	#ignore zoom values greater 10 (see: #654185)
	$self->_view->signal_connect(
		'zoom-changed' => sub {
			my ($view, $zoom) = @_;
			if ($zoom >= 1) {
				$view->set_interpolation('nearest');
				$view->set_zoom(10) if $zoom > 10;
			} else {
				$view->set_interpolation('bilinear');
			}
		});

	#clipboard
	require Shutter::App::Core::ClipboardAPI;
	$self->_clipboard(Shutter::App::Core::ClipboardAPI->new);

	#file
	$self->_filename(undef);
	$self->_filetype(undef);
	$self->_mimetype(undef);
	$self->_import_hash(undef);

	#custom cursors
	$self->_cursors({});

	#ui
	$self->_uimanager(undef);
	$self->_factory(undef);

	#canvas
	$self->_canvas(undef);

	#all items are stored here
	$self->_uid(time);
	$self->_items({});
	$self->_items_history(undef);

	#undo and redo stacks
	$self->_undo([]);
	$self->_redo([]);

	#autoscroll option, disabled by default
	$self->_autoscroll(FALSE);

	#drawing colors and line width
	#general - shown in the bottom hbox
	$self->_fill_color(_make_rgba('#0000ff', 0.25));
	$self->_stroke_color(_make_rgba('#ff0000', 1));
	$self->_line_width(3);
	$self->_font(DEFAULT_FONT);

	#obtain current colors and font_desc from the main window
	$self->_style($self->_sc->main_window->get_style_context);
	$self->_style_bg($self->_style->get_background_color('selected'));
	$self->_style_bg->alpha(1);

	#remember drawing colors, line width and font settings
	#maybe we have to restore them
	$self->_last_fill_color(_make_rgba('#0000ff', 0.25));
	$self->_last_stroke_color(_make_rgba('#ff0000', 1));
	$self->_last_line_width(3);
	$self->_last_font(DEFAULT_FONT);

	#some status variables
	$self->_busy(undef);
	$self->_current_item(undef);
	$self->_current_new_item(undef);
	$self->_current_copy_item(undef);
	$self->_last_mode(10);
	$self->_current_mode(10);
	$self->_current_mode_descr("select");
	$self->_current_pixbuf(undef);
	$self->_current_pixbuf_filename(undef);
	$self->_cut(FALSE);

	$self->_start_time(undef);

	$self->_stipple_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file($self->_sc->shutter_root . '/share/shutter/resources/gui/stipple.png'));

	print "DrawingTool initialized\n" if $self->_sc->debug;

	require Shutter::Draw::ToolbarManager;
	$self->_toolbar_manager(Shutter::Draw::ToolbarManager->new(drawing_tool => $self));

	require Shutter::Draw::ContextMenuManager;
	$self->_context_menu_manager(Shutter::Draw::ContextMenuManager->new(drawing_tool => $self));

	require Shutter::Draw::SettingsManager;
	$self->_settings_manager(Shutter::Draw::SettingsManager->new(drawing_tool => $self));

	require Shutter::Draw::MouseManager;
	$self->_mouse_manager(Shutter::Draw::MouseManager->new(drawing_tool => $self));

	require Shutter::Draw::MacroManager;
	$self->_macro_manager(Shutter::Draw::MacroManager->new(drawing_tool => $self));

	require Shutter::Draw::ItemFactory;
	$self->_item_factory(Shutter::Draw::ItemFactory->new(drawing_tool => $self));

	require Shutter::Draw::Tool::Registry;
	my $registry = Shutter::Draw::Tool::Registry->new;
	$registry->register_tool('select',      'Shutter::Draw::Tool::Select');
	$registry->register_tool('freehand',    'Shutter::Draw::Tool::Pen');
	$registry->register_tool('highlighter', 'Shutter::Draw::Tool::Highlighter');
	$registry->register_tool('line',        'Shutter::Draw::Tool::Line');
	$registry->register_tool('arrow',       'Shutter::Draw::Tool::Arrow');
	$registry->register_tool('rect',        'Shutter::Draw::Tool::Rectangle');
	$registry->register_tool('ellipse',     'Shutter::Draw::Tool::Ellipse');
	$registry->register_tool('text',        'Shutter::Draw::Tool::Text');
	$registry->register_tool('censor',      'Shutter::Draw::Tool::Censor');
	$registry->register_tool('pixelize',    'Shutter::Draw::Tool::Blur');
	$registry->register_tool('number',      'Shutter::Draw::Tool::Number');
	$registry->register_tool('image',       'Shutter::Draw::Tool::Image');

	require Shutter::Draw::CanvasManager;
	$self->_canvas_manager(Shutter::Draw::CanvasManager->new(registry => $registry, drawing_tool => $self));

	require Shutter::Draw::PropertyManager;
	$self->_property_manager(Shutter::Draw::PropertyManager->new(drawing_tool => $self));

	require Shutter::Draw::IOManager;
	$self->_io_manager(Shutter::Draw::IOManager->new(drawing_tool => $self));

	require Shutter::Draw::StateManager;
	$self->_state_manager(Shutter::Draw::StateManager->new(drawing_tool => $self));

	require Shutter::Draw::UndoManager;
	$self->_undo_manager(Shutter::Draw::UndoManager->new(drawing_tool => $self));

	return;
}

sub _make_rgba {
	my ($hex, $alpha) = @_;
	my $c = Gtk3::Gdk::RGBA::parse($hex);
	$c->alpha($alpha);
	return $c;
}

sub current_tool ($self) {
	return $self->_canvas_manager->active_tool;
}

sub acquire_focus {
	my ($self, $item, $ev, $cursor) = @_;
	$self->_canvas_manager->acquire_focus($item, $ev, $cursor);
	return;
}

sub release_focus {
	my ($self, $item, $ev) = @_;
	$self->_canvas_manager->release_focus($item, $ev);
	return;
}

sub show {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->setup_main_window(@args);
}

sub setup_right_vbox_c {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->setup_right_vbox_c(@args);
}

sub adjust_crop_values {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->adjust_crop_values(@args);
}

sub push_tool_help_to_statusbar {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->push_tool_help_to_statusbar(@args);
}

sub show_status_message {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->show_status_message(@args);
}

sub change_drawing_tool_cb {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->change_drawing_tool_cb(@args);
}

sub zoom_in_cb {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->zoom_in_cb(@args);
}

sub zoom_out_cb {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->zoom_out_cb(@args);
}

sub zoom_normal_cb {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->zoom_normal_cb(@args);
}

sub adjust_rulers {
	my ($self, @args) = @_;
	return $self->_toolbar_manager->adjust_rulers(@args);
}

sub quit {
	my ($self, @args) = @_;
	return $self->_state_manager->quit(@args);
}

sub update_warning_text {
	my ($self, @args) = @_;
	return $self->_state_manager->update_warning_text(@args);
}

#ITEM SIGNALS

sub get_item_key {
	my ($self, $item, $parent) = @_;
	if (exists $self->_items->{$item}) {
		return $item;
	} else {
		return $parent;
	}
}

sub setup_uimanager ($self) {
	return Shutter::Draw::UIManager->new(app => $self)->setup;
}

sub utf8_decode {
	my ($self, $string) = @_;

	#see https://bugs.launchpad.net/shutter/+bug/347821
	utf8::decode $string;

	return $string;
}

sub check_valid_mime_type ($self, $mime_type) {
	foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
		foreach my $mime (@{$format->get_mime_types}) {
			return TRUE if $mime_type eq $mime;
		}
	}

	return FALSE;
}

# Public accessor methods (wrappers around Moo attributes)
sub gettext         { return shift->_d }
sub dicons          { return shift->_dicons }
sub line_spin_w     { return shift->_line_spin_w }
sub line_spin_wh    { return shift->_line_spin_wh }
sub stroke_color_w  { return shift->_stroke_color_w }
sub stroke_color_wh { return shift->_stroke_color_wh }
sub fill_color_w    { return shift->_fill_color_w }
sub fill_color_wh   { return shift->_fill_color_wh }
sub font_btn_w      { return shift->_font_btn_w }
sub font_btn_wh     { return shift->_font_btn_wh }

sub icons          { return shift->_icons }
sub clipboard      { return shift->_clipboard }
sub items          { return shift->_items }
sub drawing_window { return shift->_drawing_window }
sub canvas         { return shift->_canvas }
sub stipple_pixbuf { return shift->_stipple_pixbuf }

sub cut {
	my ($self, @args) = @_;
	$self->_cut($args[0]) if @args;
	return $self->_cut;
}

sub current_copy_item {
	my ($self, @args) = @_;
	$self->_current_copy_item($args[0]) if @args;
	return $self->_current_copy_item;
}

sub current_item {
	my ($self, @args) = @_;
	$self->_current_item($args[0]) if @args;
	return $self->_current_item;
}

sub current_mode {
	my ($self, @args) = @_;
	$self->_current_mode($args[0]) if @args;
	return $self->_current_mode;
}

sub current_new_item {
	my ($self, @args) = @_;
	$self->_current_new_item($args[0]) if @args;
	return $self->_current_new_item;
}

sub canvas_bg {
	my ($self, @args) = @_;
	$self->_canvas_bg($args[0]) if @args;
	return $self->_canvas_bg;
}

sub factory {
	my ($self, @args) = @_;
	$self->_factory($args[0]) if @args;
	return $self->_factory;
}

sub autoscroll {
	my ($self, @args) = @_;
	$self->_autoscroll($args[0]) if @args;
	return $self->_autoscroll;
}

sub stroke_color {
	my ($self, @args) = @_;
	$self->_stroke_color($args[0]) if @args;
	return $self->_stroke_color;
}

sub fill_color {
	my ($self, @args) = @_;
	$self->_fill_color($args[0]) if @args;
	return $self->_fill_color;
}

sub line_width {
	my ($self, @args) = @_;
	$self->_line_width($args[0]) if @args;
	return $self->_line_width;
}

sub font {
	my ($self, @args) = @_;
	$self->_font($args[0]) if @args;
	return $self->_font;
}

sub uid { return shift->_uid }

sub increase_uid ($self) {
	return $self->_uid($self->_uid + 1);
}

sub uimanager { return shift->_uimanager }
sub toolbar_manager { return shift->_toolbar_manager }
sub item_factory { return shift->_item_factory }
sub settings_manager { return shift->_settings_manager }
sub mouse_manager { return shift->_mouse_manager }
sub macro_manager { return shift->_macro_manager }
sub canvas_manager { return shift->_canvas_manager }
sub property_manager { return shift->_property_manager }
sub io_manager { return shift->_io_manager }
sub state_manager { return shift->_state_manager }
sub undo_manager { return shift->_undo_manager }
sub context_menu_manager { return shift->_context_menu_manager }
sub canvas_overlays { return shift->_canvas_overlays }

# Methods consolidated from Shutter::Draw::LegacyDelegators
sub load_settings ($self) {
	return $self->_settings_manager->load_settings(@_);
}

sub save_settings ($self) {
	return $self->_settings_manager->save_settings(@_);
}

sub import_from_dnd ($self) {
	return $self->_io_manager->import_from_dnd(@_);
}

sub import_from_filesystem ($self) {
	return $self->_io_manager->import_from_filesystem(@_);
}

sub import_from_utheme ($self) {
	return $self->_io_manager->import_from_utheme(@_);
}

sub import_from_utheme_ctxt ($self) {
	return $self->_io_manager->import_from_utheme_ctxt(@_);
}

sub import_from_session ($self) {
	return $self->_io_manager->import_from_session(@_);
}

sub get_pixelated_pixbuf_from_canvas ($self) {
	return $self->_item_factory->get_pixelated_pixbuf_from_canvas(@_);
}

sub export_to_file ($self) {
	return $self->_io_manager->export_to_file(@_);
}

sub export_to_svg ($self) {
	return $self->_io_manager->export_to_svg(@_);
}

sub export_to_ps ($self) {
	return $self->_io_manager->export_to_ps(@_);
}

sub export_to_pdf ($self) {
	return $self->_io_manager->export_to_pdf(@_);
}

sub save ($self) {
	return $self->_io_manager->save(@_);
}

sub setup_item_signals {
	my ($self, $item) = @_;
	$item->signal_connect(
		'motion_notify_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_motion_notify($item, $target, $ev);
		});
	$item->signal_connect(
		'key_press_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_key_press($item, $target, $ev);
		});
	$item->signal_connect(
		'button_press_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_button_press($item, $target, $ev);
		});
	$item->signal_connect(
		'button_release_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_button_release($item, $target, $ev);
		});

	return TRUE;
}

sub setup_item_signals_extra {
	my ($self, $item) = @_;
	$item->signal_connect(
		'enter_notify_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_enter_notify($item, $target, $ev);
		});

	$item->signal_connect(
		'leave_notify_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_leave_notify($item, $target, $ev);
		});

	return TRUE;
}

sub event_item_on_motion_notify ($self) {
	return $self->_mouse_manager->event_item_on_motion_notify(@_);
}

sub get_opposite_rect ($self) {
	return $self->_item_factory->get_opposite_rect(@_);
}

sub get_parent_item ($self) {
	return $self->_item_factory->get_parent_item(@_);
}

sub get_highest_auto_digit ($self) {
	return $self->_item_factory->get_highest_auto_digit(@_);
}

sub get_child_item ($self) {
	return $self->_item_factory->get_child_item(@_);
}

sub abort_current_mode ($self) {
	if ($self->_current_item) {
		$self->_canvas->pointer_ungrab($self->_current_item, Gtk3::get_current_event_time());
		$self->_canvas->keyboard_ungrab($self->_current_item, Gtk3::get_current_event_time());
	}

	$self->set_drawing_action(1);

	return TRUE;
}

sub clear_item_from_canvas {
	my ($self, $item) = @_;

	$self->_current_item(undef);
	$self->_current_new_item(undef);

	if ($item) {

		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		my $child = $self->get_child_item($item);

		return FALSE if ($child && $child->get('visibility') eq 'hidden');

		return FALSE if (!$child && $item->get('visibility') eq 'hidden');

		$self->store_to_xdo_stack($item, 'delete', 'undo');
		$item->set('visibility' => 'hidden');
		$self->handle_rects('hide', $item);
		$self->handle_embedded('hide', $item);

	}

	return TRUE;
}

sub store_to_xdo_stack ($self) {
	return $self->_macro_manager->store_to_xdo_stack(@_);
}

sub xdo_remove ($self) {
	return $self->_macro_manager->xdo_remove(@_);
}

sub xdo ($self, @args) {
	return $self->_macro_manager->xdo(@args);
}

sub set_and_save_drawing_properties ($self, @args) {
	return $self->_settings_manager->set_and_save_drawing_properties(@args);
}

sub restore_fixed_properties ($self, @args) {
	return $self->_settings_manager->restore_fixed_properties(@args);
}

sub restore_drawing_properties ($self, @args) {
	return $self->_settings_manager->restore_drawing_properties(@args);
}

sub event_item_on_key_press ($self) {
	return $self->_mouse_manager->event_item_on_key_press(@_);
}

sub event_item_on_button_press ($self) {
	return $self->_mouse_manager->event_item_on_button_press(@_);
}

sub ret_background_menu ($self) {
	return $self->_context_menu_manager->ret_background_menu(@_);
}

sub ret_item_menu ($self) {
	return $self->_context_menu_manager->ret_item_menu(@_);
}

sub show_item_properties ($self) {
	return $self->_property_manager->show_item_properties(@_);
}

sub apply_properties ($self) {
	return $self->_property_manager->apply_properties(@_);
}

sub modify_text_in_properties ($self) {
	return $self->_property_manager->modify_text_in_properties(@_);
}

sub move_all {
	my ($self, $x, $y) = @_;
	foreach (keys %{$self->_items}) {

		my $item = $self->_items->{$_};

		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		if (exists $self->_items->{$item}) {

			if ($item->isa('GooCanvas2::CanvasRect')) {

				$item->set(
					'x' => $item->get('x') - $x,
					'y' => $item->get('y') - $y,
				);

				my $child = $self->get_child_item($item);
				$child = $item unless $child;

				if ($child->get('visibility') eq 'hidden') {
					$self->handle_rects('hide', $item);
					$self->handle_embedded('hide', $item);
				} else {
					$self->handle_rects('update', $item);

					if ($child && $child->isa('GooCanvas2::CanvasImage')) {
						my $parent = $self->get_parent_item($child);

						if (exists $self->_items->{$parent}{pixelize}) {

							Glib::Idle->add(
								sub {
									$self->_items->{$parent}{pixelize}->set(
										'x'      => int $self->_items->{$parent}->get('x'),
										'y'      => int $self->_items->{$parent}->get('y'),
										'width'  => $self->_items->{$parent}->get('width'),
										'height' => $self->_items->{$parent}->get('height'),
										'pixbuf' => $self->get_pixelated_pixbuf_from_canvas($self->_items->{$parent}),
									);

									$self->handle_embedded('update', $parent, undef, undef, TRUE);

									$self->deactivate_all;

									return FALSE;
								});

						} else {

							$self->handle_embedded('update', $item);

						}

					} else {

						$self->handle_embedded('update', $item);

					}
				}

			} else {

				$item->translate(-$x, -$y);

			}

		}
	}

	$self->deactivate_all;

	return TRUE;
}

sub deactivate_all {
	my $self    = shift;
	my $exclude = shift || 0;

	foreach (keys %{$self->_items}) {

		my $item = $self->_items->{$_};

		next if $item == $exclude;

		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		if (exists $self->_items->{$item}) {
			$self->handle_rects('hide', $item);
		}

	}

	$self->_current_item(undef);
	$self->_current_new_item(undef);

	return TRUE;
}

sub handle_embedded ($self) {
	return $self->_canvas_overlays->handle_embedded(@_);
}

sub handle_bg_rects {
	my ($self, $action, $bg_rect) = @_;
	$bg_rect //= $self->_canvas_bg_rect;
	return $self->_canvas_overlays->handle_bg_rects($action, $bg_rect);
}

sub handle_rects ($self) {
	return $self->_canvas_overlays->handle_item_handles(@_);
}

sub event_item_on_button_release ($self) {
	return $self->_mouse_manager->event_item_on_button_release(@_);
}

sub event_item_on_enter_notify ($self) {
	return $self->_mouse_manager->event_item_on_enter_notify(@_);
}

sub event_item_on_leave_notify ($self) {
	return $self->_mouse_manager->event_item_on_leave_notify(@_);
}

sub gen_thumbnail_on_idle {
	my ($self, $stock, $parent, $button, $no_init) = @_;
	my @menu_items = @_;

	my $shutter_hfunct = Shutter::App::HelperFunctions->new($self->_sc);

	my $next_item = 0;
	Glib::Idle->add(
		sub {

			my $child = $menu_items[$next_item];

			unless ($child) {
				$parent->set_image(Gtk3::Image->new_from_stock($stock, 'menu')) if $parent;
				return FALSE;
			}

			my $name = $child->{'name'};

			unless ($name) {
				$parent->set_image(Gtk3::Image->new_from_stock($stock, 'menu')) if $parent;
				return FALSE;
			}

			$next_item++;

			my $small_image;
			eval {

				if (exists $child->{'giofile'}) {
					my $thumb;
					unless ($child->{'no_thumbnail'}) {
						$thumb = $self->_lp_ne->load($shutter_hfunct->utf8_decode($child->{'giofile'}->get_path), Gtk3::IconSize->lookup('small-toolbar'));
					} else {
						$thumb = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, 5, 5);
						$thumb->fill(0x00000000);
					}

					$small_image = Gtk3::Image->new_from_pixbuf($thumb);
				} else {
					my $pixbuf = $self->_lp_ne->load($name, undef, undef, undef, TRUE);

					if ($pixbuf->get_width >= 16 && $pixbuf->get_height >= 16) {
						$small_image = Gtk3::Image->new_from_pixbuf($pixbuf->scale_simple(Gtk3::IconSize->lookup('menu'), 'bilinear'));
					}
				}
			};
			unless ($@) {
				if ($small_image) {
					$child->set_image($small_image);

					unless ($no_init) {
						unless ($button->get_icon_widget) {
							$button->set_icon_widget(Gtk3::Image->new_from_pixbuf($small_image->get_pixbuf));
							$self->_current_pixbuf_filename($name);
							$button->show_all;
						}
					}

					$child->signal_connect(
						'activate' => sub {
							$self->_current_pixbuf_filename($name);
							$button->set_icon_widget(Gtk3::Image->new_from_pixbuf($small_image->get_pixbuf));
							$button->show_all;
							$self->_canvas->get_window->set_cursor($self->change_cursor_to_current_pixbuf);
						});
				} else {
					$child->destroy;
				}
			} else {
				$child->destroy;
			}

			return TRUE;
		});

	return;
}

sub set_drawing_action {
	my ($self, $index) = @_;

	my $item_index = 0;
	my $toolbar    = $self->_uimanager->get_widget("/ToolBarDrawing");
	for (my $i = 0 ; $i < $toolbar->get_n_items ; $i++) {
		my $item = $toolbar->get_nth_item($i);

		next if $item->isa('Gtk3::SeparatorToolItem');

		$item_index++;

		if ($item_index == $index) {
			if ($item->get_active) {
				$self->change_drawing_tool_cb($item_index * 10);
			} else {
				$item->set_active(TRUE);
			}
			last;
		}
	}

	return;
}

sub change_cursor_to_current_pixbuf ($self) {

	$self->_current_mode_descr("image");

	my $cursor = undef;

	$self->_current_pixbuf($self->_lp->load($self->_current_pixbuf_filename, undef, undef, undef, TRUE));
	unless ($self->_current_pixbuf) {
		$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), Gtk3::Gdk::Pixbuf->new_from_file($self->_dicons . '/draw-image.svg'), Gtk3::IconSize->lookup('menu'));
	}

	my $pb_w = $self->_current_pixbuf->get_width;
	my $pb_h = $self->_current_pixbuf->get_height;

	if ($pb_w < 800 && $pb_h < 800) {
		eval {

			my ($cw, $ch) = Gtk3::Gdk::Display::get_default->get_maximal_cursor_size;

			if ($cw > $pb_w || $ch > $pb_w) {
				$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), $self->_current_pixbuf, int($pb_w / 2), int($pb_h / 2));
			} else {
				my $cpixbuf = $self->_lp->load($self->_current_pixbuf_filename, $cw, $ch, TRUE, TRUE);
				$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), $cpixbuf, int($cpixbuf->get_width / 2), int($cpixbuf->get_height / 2));
			}

		};
		if ($@) {
			my $response = $self->_dialogs->dlg_error_message(
				sprintf($self->_d->get("Error while opening image %s."), "'" . $self->_current_pixbuf_filename . "'"),
				$self->_d->get("There was an error opening the image."),
				undef, undef, undef, undef, undef, undef, $@
			);
			$self->abort_current_mode;
		}
	} else {
		$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), Gtk3::Gdk::Pixbuf->new_from_file($self->_dicons . '/draw-image.svg'), Gtk3::IconSize->lookup('menu'));
	}

	return $cursor;
}

sub paste_item ($self) {
	return $self->_item_factory->paste_item(@_);
}

sub create_polyline ($self) {
	return $self->_item_factory->create_polyline(@_);
}

sub create_censor ($self) {
	return $self->_item_factory->create_censor(@_);
}

sub create_pixel_image ($self) {
	return $self->_item_factory->create_pixel_image(@_);
}

sub create_image ($self) {
	return $self->_item_factory->create_image(@_);
}

sub create_text ($self) {
	return $self->_item_factory->create_text(@_);
}

sub create_line ($self) {
	return $self->_item_factory->create_line(@_);
}

sub create_ellipse ($self) {
	return $self->_item_factory->create_ellipse(@_);
}

sub create_rectangle ($self) {
	return $self->_item_factory->create_rectangle(@_);
}

1;
