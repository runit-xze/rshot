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

#perl -x -S perltidy -l=0 -b "%f"

# Native Gtk3::IconSize doesn't work for some reason
# FIXME This package should be cleaned up when fixing DrawingTool
package Gtk3::IconSize;

use v5.40;
use feature "try";
no warnings "experimental::try";
{
	no warnings 'redefine';

	sub lookup {
		my ($self, $size) = @_;
		return Shutter::App::HelperFunctions->icon_size($size);
	}
}

1;

package Shutter::Draw::DrawingTool;

use v5.40;
use feature "try";
no warnings "experimental::try";
use parent 'Shutter::Draw::LegacyDelegators';

#modules
#--------------------------------------
use utf8;
use strict;
use warnings;

use constant {DEFAULT_FONT => "Sans Regular 16"};

use Gtk3;

use Exporter;
use GooCanvas2;
use GooCanvas2::CairoTypes;
use File::Basename qw/ fileparse dirname basename /;
use File::Glob     qw/ bsd_glob /;
use File::Temp     qw/ tempfile tempdir /;
use Data::Dumper;

#load and save settings
use XML::Simple;

#Glib
use Glib qw/TRUE FALSE/;
use Gtk3::ImageView;

require Shutter::Draw::Utils;
require Shutter::App::Directories;
require Shutter::Draw::UIManager;

#--------------------------------------

sub new {
	my ($class, $sc) = @_;
	my $self = {_sc => $sc};
	$self->{_shf} = Shutter::App::HelperFunctions->new($self->{_sc});

	#view, selector, dragger
	$self->{_view}     = Gtk3::ImageView->new;
	$self->{_selector} = Gtk3::ImageView::Tool::Selector->new($self->{_view});
	$self->{_dragger}  = Gtk3::ImageView::Tool::Dragger->new($self->{_view});
	$self->{_view}->set_tool($self->{_selector});
	$self->{_view_css_provider_alpha} = Gtk3::CssProvider->new;
	$self->{_view}->get_style_context->add_provider($self->{_view_css_provider_alpha}, 0);
	$self->{_view}->set('zoom-step', 1.2);

	#WORKAROUND
	#upstream bug
	#http://trac.bjourne.webfactional.com/ticket/21
	#left  => zoom in
	#right => zoom out
	$self->{_view}->signal_connect(
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
	$self->{_view}->signal_connect(
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
	$self->{_clipboard} = Gtk3::Clipboard::get($Gtk3::Gdk::SELECTION_CLIPBOARD);

	#file
	$self->{_filename}    = undef;
	$self->{_filetype}    = undef;
	$self->{_mimetype}    = undef;
	$self->{_import_hash} = undef;

	#custom cursors
	$self->{_cursors} = undef;

	#ui
	$self->{_uimanager} = undef;
	$self->{_factory}   = undef;

	#canvas
	$self->{_canvas} = undef;

	#all items are stored here
	$self->{_uid}           = time;
	$self->{_items}         = {};
	$self->{_items_history} = undef;

	#undo and redo stacks
	$self->{_undo} = undef;
	$self->{_redo} = undef;

	#autoscroll option, disabled by default
	$self->{_autoscroll} = FALSE;

	#drawing colors and line width
	#general - shown in the bottom hbox
	$self->{_fill_color} = Gtk3::Gdk::RGBA::parse('#0000ff');
	$self->{_fill_color}->alpha(0.25);
	$self->{_stroke_color} = Gtk3::Gdk::RGBA::parse('#ff0000');
	$self->{_stroke_color}->alpha(1);
	$self->{_line_width} = 3;
	$self->{_font}       = DEFAULT_FONT;

	#obtain current colors and font_desc from the main window
	$self->{_style}    = $self->{_sc}->get_mainwindow->get_style_context;
	$self->{_style_bg} = $self->{_style}->get_background_color('selected');
	$self->{_style_bg}->alpha(1);

	#$self->{_style_tx} = $self->{_style}->text('selected');

	#remember drawing colors, line width and font settings
	#maybe we have to restore them
	$self->{_last_fill_color} = Gtk3::Gdk::RGBA::parse('#0000ff');
	$self->{_last_fill_color}->alpha(0.25);
	$self->{_last_stroke_color} = Gtk3::Gdk::RGBA::parse('#ff0000');
	$self->{_last_stroke_color}->alpha(1);
	$self->{_last_line_width} = 3;
	$self->{_last_font}       = DEFAULT_FONT;

	#some status variables
	$self->{_busy}                    = undef;
	$self->{_current_item}            = undef;
	$self->{_current_new_item}        = undef;
	$self->{_current_copy_item}       = undef;
	$self->{_last_mode}               = 10;
	$self->{_current_mode}            = 10;
	$self->{_current_mode_descr}      = "select";
	$self->{_current_pixbuf}          = undef;
	$self->{_current_pixbuf_filename} = undef;
	$self->{_cut}                     = FALSE;

	$self->{_start_time} = undef;

	$self->{_stipple_pixbuf} = Gtk3::Gdk::Pixbuf->new_from_file($self->{_sc}->get_root . '/share/shutter/resources/gui/stipple.png');

	print "DrawingTool initialized\n" if $self->{_sc}->get_debug;

	bless $self, $class;

	require Shutter::Draw::ToolbarManager;
	$self->{_toolbar_manager} = Shutter::Draw::ToolbarManager->new(drawing_tool => $self);

	require Shutter::Draw::ContextMenuManager;
	$self->{_context_menu_manager} = Shutter::Draw::ContextMenuManager->new(drawing_tool => $self);

	require Shutter::Draw::SettingsManager;
	$self->{_settings_manager} = Shutter::Draw::SettingsManager->new(drawing_tool => $self);

	require Shutter::Draw::MouseManager;
	$self->{_mouse_manager} = Shutter::Draw::MouseManager->new(drawing_tool => $self);

	require Shutter::Draw::MacroManager;
	$self->{_macro_manager} = Shutter::Draw::MacroManager->new(drawing_tool => $self);

	require Shutter::Draw::ItemFactory;
	$self->{_item_factory} = Shutter::Draw::ItemFactory->new(drawing_tool => $self);

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
	$self->{_canvas_manager} = Shutter::Draw::CanvasManager->new(registry => $registry, drawing_tool => $self);

	require Shutter::Draw::PropertyManager;
	$self->{_property_manager} = Shutter::Draw::PropertyManager->new(drawing_tool => $self);

	require Shutter::Draw::IOManager;
	$self->{_io_manager} = Shutter::Draw::IOManager->new(drawing_tool => $self);

	require Shutter::Draw::StateManager;
	$self->{_state_manager} = Shutter::Draw::StateManager->new(drawing_tool => $self);

	require Shutter::Draw::UndoManager;
	$self->{_undo_manager} = Shutter::Draw::UndoManager->new(drawing_tool => $self);

	return $self;
}

sub current_tool {
	my $self = shift;
	return $self->{_canvas_manager}->active_tool;
}

sub acquire_focus {
	my ($self, $item, $ev, $cursor) = @_;
	$self->{_canvas_manager}->acquire_focus($item, $ev, $cursor);
	return;
}

sub release_focus {
	my ($self, $item, $ev) = @_;
	$self->{_canvas_manager}->release_focus($item, $ev);
	return;
}

our $AUTOLOAD;

sub AUTOLOAD {
	my $self = shift;
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	return if $name eq 'DESTROY';

	if (@_) {
		$self->{"_$name"} = shift;
	}
	return $self->{"_$name"};
}

#~ sub DESTROY {
#~ my $self = shift;
#~ print "$self dying at\n";
#~ }

sub show {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->setup_main_window(@args);
}

sub setup_right_vbox_c {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->setup_right_vbox_c(@args);
}

sub adjust_crop_values {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->adjust_crop_values(@args);
}

sub push_tool_help_to_statusbar {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->push_tool_help_to_statusbar(@args);
}

sub show_status_message {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->show_status_message(@args);
}

sub change_drawing_tool_cb {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->change_drawing_tool_cb(@args);
}

sub zoom_in_cb {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->zoom_in_cb(@args);
}

sub zoom_out_cb {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->zoom_out_cb(@args);
}

sub zoom_normal_cb {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->zoom_normal_cb(@args);
}

sub adjust_rulers {
	my ($self, @args) = @_;
	return $self->{_toolbar_manager}->adjust_rulers(@args);
}

sub quit {
	my ($self, @args) = @_;
	return $self->{_state_manager}->quit(@args);
}

sub update_warning_text {
	my ($self, @args) = @_;
	return $self->{_state_manager}->update_warning_text(@args);
}

#ITEM SIGNALS

sub get_item_key {
	my ($self, $item, $parent) = @_;
	if (exists $self->{_items}{$item}) {
		return $item;
	} else {
		return $parent;
	}
}

sub setup_uimanager {
	my $self = shift;
	return Shutter::Draw::UIManager->new(app => $self)->setup;
}

sub utf8_decode {
	my ($self, $string) = @_;

	#see https://bugs.launchpad.net/shutter/+bug/347821
	utf8::decode $string;

	return $string;
}

sub check_valid_mime_type {
	my ($self, $mime_type) = @_;
	foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
		foreach my $mime (@{$format->get_mime_types}) {
			return TRUE if $mime_type eq $mime_type;
			last;
		}
	}

	return FALSE;
}

sub gettext         { return shift->{_d} }
sub dicons          { return shift->{_dicons} }
sub line_spin_w     { return shift->{_line_spin_w} }
sub line_spin_wh    { return shift->{_line_spin_wh} }
sub stroke_color_w  { return shift->{_stroke_color_w} }
sub stroke_color_wh { return shift->{_stroke_color_wh} }
sub fill_color_w    { return shift->{_fill_color_w} }
sub fill_color_wh   { return shift->{_fill_color_wh} }
sub font_btn_w      { return shift->{_font_btn_w} }
sub font_btn_wh     { return shift->{_font_btn_wh} }

sub icons          { return shift->{_icons} }
sub clipboard      { return shift->{_clipboard} }
sub items          { return shift->{_items} }
sub drawing_window { return shift->{_drawing_window} }
sub canvas         { return shift->{_canvas} }
sub stipple_pixbuf { return shift->{_stipple_pixbuf} }

sub cut {
	my ($self, @args) = @_;
	$self->{_cut} = $args[0] if @args;
	return $self->{_cut};
}

sub current_copy_item {
	my ($self, @args) = @_;
	$self->{_current_copy_item} = $args[0] if @args;
	return $self->{_current_copy_item};
}

sub current_item {
	my ($self, @args) = @_;
	$self->{_current_item} = $args[0] if @args;
	return $self->{_current_item};
}

sub current_new_item {
	my ($self, @args) = @_;
	$self->{_current_new_item} = $args[0] if @args;
	return $self->{_current_new_item};
}

sub canvas_bg {
	my ($self, @args) = @_;
	$self->{_canvas_bg} = $args[0] if @args;
	return $self->{_canvas_bg};
}

sub factory {
	my ($self, @args) = @_;
	$self->{_factory} = $args[0] if @args;
	return $self->{_factory};
}

sub autoscroll {
	my ($self, @args) = @_;
	$self->{_autoscroll} = $args[0] if @args;
	return $self->{_autoscroll};
}

sub stroke_color {
	my ($self, @args) = @_;
	$self->{_stroke_color} = $args[0] if @args;
	return $self->{_stroke_color};
}

sub fill_color {
	my ($self, @args) = @_;
	$self->{_fill_color} = $args[0] if @args;
	return $self->{_fill_color};
}

sub line_width {
	my ($self, @args) = @_;
	$self->{_line_width} = $args[0] if @args;
	return $self->{_line_width};
}

sub font {
	my ($self, @args) = @_;
	$self->{_font} = $args[0] if @args;
	return $self->{_font};
}

sub uid { return shift->{_uid} }

sub increase_uid { return shift->{_uid}++ }

sub uimanager { return shift->{_uimanager} }

sub toolbar_manager { return shift->{_toolbar_manager} }

1;
