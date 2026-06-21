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
{
	no warnings 'redefine';
	sub lookup {
		my $self = shift;
		my $size = shift;
		Shutter::App::HelperFunctions->icon_size($size);
	}
}

1;

package Shutter::Draw::DrawingTool;

#modules
#--------------------------------------
use utf8;
use strict;
use warnings;

use constant {
	DEFAULT_FONT => "Sans Regular 16"
};

use Gtk3;

use Exporter;
use GooCanvas2;
use GooCanvas2::CairoTypes;
use File::Basename qw/ fileparse dirname basename /;
use File::Glob qw/ bsd_glob /;
use File::Temp qw/ tempfile tempdir /;
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
	my $class = shift;

	my $self = {_sc => shift};
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
	$self->{_fill_color}         = Gtk3::Gdk::RGBA::parse('#0000ff');
	$self->{_fill_color}->alpha(0.25);
	$self->{_stroke_color}       = Gtk3::Gdk::RGBA::parse('#ff0000');
	$self->{_stroke_color}->alpha(1);
	$self->{_line_width}         = 3;
	$self->{_font}               = DEFAULT_FONT;

	#obtain current colors and font_desc from the main window
	$self->{_style}    = $self->{_sc}->get_mainwindow->get_style_context;
	$self->{_style_bg} = $self->{_style}->get_background_color('selected');
	$self->{_style_bg}->alpha(1);
	#$self->{_style_tx} = $self->{_style}->text('selected');

	#remember drawing colors, line width and font settings
	#maybe we have to restore them
	$self->{_last_fill_color}         = Gtk3::Gdk::RGBA::parse('#0000ff');
	$self->{_last_fill_color}->alpha(0.25);
	$self->{_last_stroke_color}       = Gtk3::Gdk::RGBA::parse('#ff0000');
	$self->{_last_stroke_color}->alpha(1);
	$self->{_last_line_width}         = 3;
	$self->{_last_font}               = DEFAULT_FONT;

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
	$registry->register_tool('rect', 'Shutter::Draw::Tool::Rectangle');
	$registry->register_tool('ellipse', 'Shutter::Draw::Tool::Ellipse');
	$registry->register_tool('text', 'Shutter::Draw::Tool::Text');
	$registry->register_tool('line', 'Shutter::Draw::Tool::Line');
	$registry->register_tool('arrow', 'Shutter::Draw::Tool::Arrow');
	$registry->register_tool('highlighter', 'Shutter::Draw::Tool::Highlighter');
	$registry->register_tool('freehand', 'Shutter::Draw::Tool::Pen');
	$registry->register_tool('censor', 'Shutter::Draw::Tool::Censor');
	$registry->register_tool('pixelize', 'Shutter::Draw::Tool::Blur');
	$registry->register_tool('number', 'Shutter::Draw::Tool::Number');
	$registry->register_tool('image', 'Shutter::Draw::Tool::Image');
	require Shutter::Draw::CanvasManager;
	$self->{_canvas_manager} = Shutter::Draw::CanvasManager->new(registry => $registry, drawing_tool => $self);

	require Shutter::Draw::PropertyManager;
	$self->{_property_manager} = Shutter::Draw::PropertyManager->new(drawing_tool => $self);

	require Shutter::Draw::IOManager;
	$self->{_io_manager} = Shutter::Draw::IOManager->new(drawing_tool => $self);

	return $self;
	}

	#~ sub DESTROY {
	#~ my $self = shift;
	#~ print "$self dying at\n";
	#~ }

	# Workaround for broken xpm parsing in glycin:
	# https://gitlab.gnome.org/GNOME/glycin/-/work_items/291
	sub parse_xpm_hotspot {
	my ($xpm_path) = @_;
	my ($x_hot, $y_hot);

	open my $fh, '<', $xpm_path or do {
	    print "ERROR: Cannot open $xpm_path: $!\n";
	    return (undef, undef);
	};

	while (my $line = <$fh>) {
	    chomp($line);

	    # Look for the XPM header line with format:
	    # "width height ncolors chars_per_pixel [x_hot y_hot]"
	    # Example: "32 32 3 1 4 4"
	    if ($line =~ /"(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+)\s+(\d+))?/) {
	        my ($width, $height, $ncolors, $cpp, $xh, $yh) = ($1, $2, $3, $4, $5, $6);

	        if (defined($xh) && defined($yh)) {
	            $x_hot = $xh;
	            $y_hot = $yh;
	        } else {
	            print "DEBUG: No hotspot in header in $xpm_path\n";
	        }

	        last;  # Header is on the first data line
	    }
	}
	close $fh;

	return ($x_hot, $y_hot);
	}

	sub show {
	my $self = shift;
	print "DrawingTool show called\n" if $self->{_sc}->get_debug;
	$self->{_filename}    = shift;
	$self->{_filetype}    = shift;
	$self->{_mimetype}    = shift;
	$self->{_name}        = shift;
	$self->{_is_unsaved}  = shift;
	$self->{_import_hash} = shift;
	my $icon_theme = shift;

	#gettext
	$self->{_d} = $self->{_sc}->get_gettext;


	#MAIN WINDOW
	#-------------------------------------------------
	$self->{_root} = Gtk3::Gdk::get_default_root_window();
	($self->{_root}->{x}, $self->{_root}->{y}, $self->{_root}->{w}, $self->{_root}->{h}) = $self->{_root}->get_geometry;
	($self->{_root}->{x}, $self->{_root}->{y}) = $self->{_root}->get_origin;

	$self->{_drawing_window} = Gtk3::Window->new('toplevel');
	if (defined $self->{_is_unsaved} && $self->{_is_unsaved}) {
		$self->{_drawing_window}->set_title("*" . $self->{_name} . " - Shutter DrawingTool");
	} else {
		$self->{_drawing_window}->set_title($self->{_filename} . " - Shutter DrawingTool");
	}
	$self->{_drawing_window}->set_position('center');
	$self->{_drawing_window}->set_modal(1);
	$self->{_drawing_window}->signal_connect('delete_event', sub { return $self->quit(TRUE) });

	#adjust toplevel window size
	if ($self->{_root}->{w} > 640 && $self->{_root}->{h} > 480) {
		$self->{_drawing_window}->set_default_size(640, 480);
	} else {
		$self->{_drawing_window}->set_default_size($self->{_root}->{w} - 100, $self->{_root}->{h} - 100);
	}

	#dialogs, thumbnail generator and pixbuf loader
	$self->{_dialogs} = Shutter::App::SimpleDialogs->new($self->{_drawing_window});
	$self->{_lp}      = Shutter::Pixbuf::Load->new($self->{_sc}, $self->{_drawing_window});
	$self->{_lp_ne}   = Shutter::Pixbuf::Load->new($self->{_sc}, $self->{_drawing_window}, TRUE);

	#define own icons
	if ($icon_theme eq 'auto') {
		# Heuristic to detect whether GTK theme is light or dark
		my $context = $self->{_drawing_window}->get_style_context();
		my $bg = $context->get_background_color('normal');
		my $avg_color = ($bg->red + $bg->green + $bg->blue) / 3.0;
		if ($avg_color > 0.5) {
			$icon_theme = 'dark';
		} else {
			$icon_theme = 'light';
		}
	}
	if ($icon_theme eq 'dark') {
		$self->{_dicons} = $self->{_sc}->get_root . "/share/shutter/resources/icons/drawing_tool";
	} else {
		$self->{_dicons} = $self->{_sc}->get_root . "/share/shutter/resources/icons/drawing_tool_dark";
	}

	$self->{_icons}  = $self->{_sc}->get_root . "/share/shutter/resources/icons";

	#setup cursor-hash
	#
	#cursors borrowed from inkscape
	#http://www.inkscape.org
	my @cursors = bsd_glob($self->{_dicons} . "/cursor/*");
	foreach my $cursor_path (@cursors) {
	    my ($cname, $folder, $type) = fileparse($cursor_path, qr/\.[^.]*/);
	    my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($cursor_path);

		if (!$pixbuf) {
			print "ERROR: Failed to load pixbuf from $cursor_path\n";
			next;
		}
		my $width = $pixbuf->get_width();
		my $height = $pixbuf->get_height();
		
		# Parse hotspot from file
		my ($x_hot, $y_hot) = parse_xpm_hotspot($cursor_path);

		# Fallback to center if not found
		$x_hot //= $width / 2;
		$y_hot //= $height / 2;

		# Store as a hash with pixbuf and hotspot data
		$self->{_cursors}{$cname} = {
			'pixbuf' => $pixbuf,
			'x_hot'  => $x_hot,
			'y_hot'  => $y_hot,
		};
	}

	#setu ui
	$self->{_uimanager} = $self->setup_uimanager();

	#load settings
	$self->load_settings;

	#load file
	$self->{_drawing_pixbuf} = $self->{_lp}->load($self->{_filename}, undef, undef, undef, TRUE);
	unless ($self->{_drawing_pixbuf}) {
		$self->{_drawing_window}->destroy if $self->{_drawing_window};
		return FALSE;
	}

	#CANVAS
	#-------------------------------------------------
	$self->{_canvas} = GooCanvas2::Canvas->new();

	#enable dnd for it
	$self->{_canvas}->drag_dest_set('all', [Gtk3::TargetEntry->new('text/uri-list', [], 0)], 'copy');
	$self->{_canvas}->signal_connect(drag_data_received => sub { $self->import_from_dnd(@_) });
	$self->{_canvas}->signal_connect(drag_motion => sub {
		my ($view, $ctx, $x, $y, $time) = @_;
		for my $target (@{$ctx->list_targets}) {
			if ($target->name eq 'text/uri-list') {
				Gtk3::Gdk::drag_status($ctx, 'copy', $time);
				return TRUE;
			}
		}
		return FALSE;
	});

	#'redraw-when-scrolled' to reduce the flicker of static items
	#
	#this property is not available in older versions
	#it was added to goocanvas on Mon Nov 17 10:28:07 2008 UTC
	#http://svn.gnome.org/viewvc/goocanvas?view=revision&revision=28
	if ($self->{_canvas}->find_property('redraw-when-scrolled')) {
		$self->{_canvas}->set('redraw-when-scrolled' => TRUE);
	}

	#~ my $bg = Gtk3::Gdk::RGBA::parse('gray');
	$self->{_canvas}->set(
		'automatic-bounds'   => FALSE,
		'bounds-from-origin' => FALSE,

		#~ 'background-color' 		=> sprintf( "#%04x%04x%04x", $bg->red, $bg->green, $bg->blue ),
	);

	#and attach scroll event
	#to imitate scroll behavior of
	#Gtk3::ImageView widget Ctrl+Mouse Wheel
	$self->{_canvas}->signal_connect(
		'scroll-event' => sub {
			my ($canvas, $ev) = @_;

			my $alloc = $self->{_canvas}->get_allocation;
			my $scale = $canvas->get_scale;

			if ($ev->state >= 'control-mask' && ($ev->direction eq 'up' || $ev->direction eq 'left')) {
				$self->zoom_in_cb;
				$canvas->scroll_to(int($ev->x - $alloc->{width} / 2) / $scale, int($ev->y - $alloc->{height} / 2) / $scale);
				return TRUE;
			} elsif ($ev->state >= 'control-mask' && ($ev->direction eq 'down' || $ev->direction eq 'right')) {
				$self->zoom_out_cb;
				return TRUE;
			}
			return FALSE;
		});

	require Shutter::Draw::CanvasOverlays;
	$self->{_canvas_overlays} = Shutter::Draw::CanvasOverlays->new(
		canvas        => $self->{_canvas},
		items         => $self->{_items},
		setup_signals => sub { $self->setup_item_signals_extra(@_) },
		style_bg      => $self->{_drawing_window}->get_style_context->get_background_color(Gtk3::StateFlags::lookup('normal')),
	);

	#create rectangle to resize the background
	$self->{_canvas_bg_rect} = GooCanvas2::CanvasRect->new(
		parent=>$self->{_canvas}->get_root_item, x=>0, y=>0, width=>$self->{_drawing_pixbuf}->get_width, height=>$self->{_drawing_pixbuf}->get_height,
		'fill-color-gdk-rgba' => Gtk3::Gdk::RGBA::parse('gray'),
		'line-dash'    => GooCanvas2::CanvasLineDash->newv([5, 5]),
		'line-width'   => 1,
		'stroke-color' => 'black',
	);

	#save color
	$self->{_canvas_bg_rect}{fill_color} = Gtk3::Gdk::RGBA::parse('gray');
	$self->setup_item_signals($self->{_canvas_bg_rect});

	$self->handle_bg_rects('create');
	$self->handle_bg_rects('update');

	#~ #create canvas background (:= screenshot)
	#~ $self->{_canvas_bg} = Goo::Canvas::Image->new(
	#~ $self->{_canvas}->get_root_item,
	#~ $self->{_drawing_pixbuf},
	#~ 0, 0,
	#~ );
	#~ $self->setup_item_signals( $self->{_canvas_bg} );

	#set variables
	$self->{_current_pixbuf_filename} = $self->{_filename};
	$self->{_current_pixbuf}          = $self->{_drawing_pixbuf};

	#construct an event and create a new image object
	my $initevent = Gtk3::Gdk::Event->new('motion-notify');
	$initevent->time(Gtk3::get_current_event_time());
	$initevent->window($self->{_drawing_window}->get_window);
	$initevent->x(int($self->{_canvas_bg_rect}->get('width') / 2));
	$initevent->y(int($self->{_canvas_bg_rect}->get('height') / 2));

	#new item
	my $nitem = $self->create_image($initevent, undef, TRUE);
	$self->{_canvas_bg} = $self->{_items}{$nitem}{image};

	#this item is locked at first
	$self->{_items}{$nitem}{locked} = FALSE;

	$self->handle_bg_rects('raise');

	#PACKING
	#-------------------------------------------------
	$self->{_drawing_vbox}         = Gtk3::VBox->new(FALSE, 0);
	$self->{_drawing_inner_vbox}   = Gtk3::VBox->new(FALSE, 0);
	$self->{_drawing_inner_vbox_c} = Gtk3::VBox->new(FALSE, 0);
	$self->{_drawing_hbox}         = Gtk3::HBox->new(FALSE, 0);
	$self->{_drawing_hbox_c}       = Gtk3::HBox->new(FALSE, 0);

	#mark some actions as important
	$self->{_uimanager}->get_widget("/ToolBar/Close")->set_is_important(TRUE);
	$self->{_uimanager}->get_widget("/ToolBar/Save")->set_is_important(TRUE);
	$self->{_uimanager}->get_widget("/ToolBar/Undo")->set_is_important(TRUE);

	#disable undo/redo actions at startup
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Undo")->set_sensitive(FALSE);
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Redo")->set_sensitive(FALSE);

	$self->{_uimanager}->get_widget("/ToolBar/Undo")->set_sensitive(FALSE);
	$self->{_uimanager}->get_widget("/ToolBar/Redo")->set_sensitive(FALSE);

	$self->{_drawing_window}->add($self->{_drawing_vbox});

	my $menubar = $self->{_uimanager}->get_widget("/MenuBar");
	$self->{_drawing_vbox}->pack_start($menubar, FALSE, FALSE, 0);

	my $toolbar_drawing = $self->{_uimanager}->get_widget("/ToolBarDrawing");
	$toolbar_drawing->set_orientation('vertical');
	$toolbar_drawing->set_style('icons');
	$toolbar_drawing->set_icon_size('menu');
	$toolbar_drawing->set_show_arrow(FALSE);
	$self->{_drawing_hbox}->pack_start($toolbar_drawing, FALSE, FALSE, 0);

	#DRAWING TOOL CONTAINER
	#-------------------------------------------------
	#scrolled window for the canvas
	$self->{_scrolled_window} = Gtk3::ScrolledWindow->new;
	$self->{_scrolled_window}->set_policy('automatic', 'automatic');
	$self->{_scrolled_window}->add($self->{_canvas});
	$self->{_hscroll_hid} = $self->{_scrolled_window}->get_hscrollbar->signal_connect('value-changed' => sub { $self->adjust_rulers });
	$self->{_vscroll_hid} = $self->{_scrolled_window}->get_vscrollbar->signal_connect('value-changed' => sub { $self->adjust_rulers });

	#vruler
	#$self->{_vruler} = Gtk3::VRuler->new;
	#$self->{_vruler}->set_metric('pixels');
	#$self->{_vruler}->set_range(0, $self->{_drawing_pixbuf}->get_height, 0, $self->{_drawing_pixbuf}->get_height);

	#hruler
	#$self->{_hruler} = Gtk3::HRuler->new;
	#$self->{_hruler}->set_metric('pixels');
	#$self->{_hruler}->set_range(0, $self->{_drawing_pixbuf}->get_width, 0, $self->{_drawing_pixbuf}->get_width);

	#create a table for placing the ruler and scrolle window
	$self->{_table} = Gtk3::Table->new(3, 2, FALSE);

	#attach scrolled window and rulers to the table
	$self->{_table}->attach($self->{_scrolled_window}, 1, 2, 1, 2, ['expand', 'fill'], ['expand', 'fill'], 0, 0);
	#$self->{_table}->attach($self->{_hruler}, 1, 2, 0, 1, ['expand', 'shrink', 'fill'], [], 0, 0);
	#$self->{_table}->attach($self->{_vruler}, 0, 1, 1, 2, [], ['fill', 'expand', 'shrink'], 0, 0);

	$self->{_bhbox} = $self->{_toolbar_manager}->setup_bottom_hbox;
	$self->{_drawing_inner_vbox}->pack_start($self->{_table}, TRUE,  TRUE, 0);
	$self->{_drawing_inner_vbox}->pack_start($self->{_bhbox}, FALSE, TRUE, 0);

	#CROPPING TOOL CONTAINER
	#-------------------------------------------------
	#scrolled window for the cropping tool
	#$self->{_scrolled_window_c} = Gtk3::ImageView::ScrollWin->new($self->{_view});
	$self->{_scrolled_window_c} = Gtk3::ScrolledWindow->new;
	$self->{_scrolled_window_c}->add_with_viewport($self->{_view});
	($self->{_rframe_c}, $self->{_btn_ok_c}) = $self->setup_right_vbox_c;
	$self->{_drawing_hbox_c}->pack_start($self->{_scrolled_window_c}, TRUE,  TRUE,  0);
	$self->{_drawing_hbox_c}->pack_start($self->{_rframe_c},          FALSE, FALSE, 3);

	$self->{_drawing_inner_vbox_c}->pack_start($self->{_drawing_hbox_c}, TRUE, TRUE, 0);

	#MAIN CONTAINER
	#-------------------------------------------------
	#pack both containers to the main hbox
	$self->{_drawing_hbox}->pack_start($self->{_drawing_inner_vbox},   TRUE, TRUE, 0);
	$self->{_drawing_hbox}->pack_start($self->{_drawing_inner_vbox_c}, TRUE, TRUE, 0);

	$self->{_drawing_vbox}->pack_start($self->{_uimanager}->get_widget("/ToolBar"), FALSE, FALSE, 0);
	$self->{_drawing_vbox}->pack_start($self->{_drawing_hbox},                      TRUE,  TRUE,  0);

	#statusbar
	$self->{_drawing_statusbar}       = Gtk3::Statusbar->new;
	$self->{_drawing_statusbar_image} = Gtk3::Image->new;
	$self->{_drawing_statusbar}->pack_start($self->{_drawing_statusbar_image}, FALSE, FALSE, 3);
	$self->{_drawing_statusbar}->reorder_child($self->{_drawing_statusbar_image}, 0);
	$self->{_drawing_vbox}->pack_start($self->{_drawing_statusbar}, FALSE, FALSE, 6);

	$self->{_drawing_window}->show_all();

	#STARTUP PROCEDURE
	#-------------------------------------------------
	$self->{_drawing_window}->get_window->focus(Gtk3::get_current_event_time());

	$self->adjust_rulers;

	#save start time to show in close dialog
	$self->{_start_time} = time;

	#remember drawing colors, line width and font settings
	#maybe we have to restore them
	$self->{_last_fill_color}         = $self->{_fill_color_w}->get_rgba;
	$self->{_last_stroke_color}       = $self->{_stroke_color_w}->get_rgba;
	$self->{_last_line_width}         = $self->{_line_spin_w}->get_value;
	$self->{_last_font}               = $self->{_font_btn_w}->get_font_name;

	#init last mode
	$self->{_last_mode} = 0;

	#init current tool
	$self->set_drawing_action(int($self->{_current_mode} / 10));

	#do show these actions because the user would be confused
	#to see multiple shortcuts to handle zooming
	#controlequal is used for english keyboard layouts for example
	$self->{_uimanager}->get_action("/MenuBar/View/ControlEqual")->set_visible(FALSE);
	$self->{_uimanager}->get_action("/MenuBar/View/ControlKpAdd")->set_visible(FALSE);
	$self->{_uimanager}->get_action("/MenuBar/View/ControlKpSub")->set_visible(FALSE);

	#start with everything deactivated
	$self->deactivate_all;

	Gtk3->main;

	return TRUE;
}


sub setup_right_vbox_c {
	my $self = shift;
	return $self->{_toolbar_manager}->setup_right_vbox_c(@_);
}

sub adjust_crop_values {
	my $self   = shift;
	my $pixbuf = shift;

	#block 'value-change' handlers for widgets
	#so we do not apply the changes twice
	$self->{_x_spin_w}->signal_handler_block($self->{_x_spin_w_handler});
	$self->{_y_spin_w}->signal_handler_block($self->{_y_spin_w_handler});
	$self->{_width_spin_w}->signal_handler_block($self->{_width_spin_w_handler});
	$self->{_height_spin_w}->signal_handler_block($self->{_height_spin_w_handler});

	my $s = $self->{_selector}->get_selection;

	if ($s) {
		$self->{_x_spin_w}->set_value($s->{x});
		$self->{_x_spin_w}->set_range(0, $pixbuf->get_width - $s->{width});

		$self->{_y_spin_w}->set_value($s->{y});
		$self->{_y_spin_w}->set_range(0, $pixbuf->get_height - $s->{height});

		$self->{_width_spin_w}->set_value($s->{width});
		$self->{_width_spin_w}->set_range(0, $pixbuf->get_width - $s->{x});

		$self->{_height_spin_w}->set_value($s->{height});
		$self->{_height_spin_w}->set_range(0, $pixbuf->get_height - $s->{y});
	}

	#unblock 'value-change' handlers for widgets
	$self->{_x_spin_w}->signal_handler_unblock($self->{_x_spin_w_handler});
	$self->{_y_spin_w}->signal_handler_unblock($self->{_y_spin_w_handler});
	$self->{_width_spin_w}->signal_handler_unblock($self->{_width_spin_w_handler});
	$self->{_height_spin_w}->signal_handler_unblock($self->{_height_spin_w_handler});

	return TRUE;

}

sub push_tool_help_to_statusbar {
	my ($self, $x, $y, $action) = @_;

	#init $action if not defined
	$action = 'none' unless defined $action;

	#current event coordinates
	my $status_text = int($x) . " x " . int($y);

	if ($self->{_current_mode} == 10) {

		if ($action eq 'resize') {
			$status_text .= " " . $self->{_d}->get("Click-Drag to scale (try Control to scale uniformly)");
		} elsif ($action eq 'canvas_resize') {
			$status_text .= " " . $self->{_d}->get("Click-Drag to resize the canvas");
		}

	} elsif ($self->{_current_mode} == 20 || $self->{_current_mode} == 30) {

		$status_text .= " " . $self->{_d}->get("Click to paint (try Control or Shift for a straight line)");

	} elsif ($self->{_current_mode} == 40) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new straight line");

	} elsif ($self->{_current_mode} == 50) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new arrow");

	} elsif ($self->{_current_mode} == 60) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new rectangle");

	} elsif ($self->{_current_mode} == 70) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new ellipse");

	} elsif ($self->{_current_mode} == 80) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to add a new text area");

	} elsif ($self->{_current_mode} == 90) {

		$status_text .= " " . $self->{_d}->get("Click to censor (try Control or Shift for a straight line)");

	} elsif ($self->{_current_mode} == 100) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a pixelized region");

	} elsif ($self->{_current_mode} == 110) {

		$status_text .= " " . $self->{_d}->get("Click to add an auto-increment shape");

	} elsif ($self->{_current_mode} == 120) {

		#nothing to do here....

	}

	#update statusbar
	$self->show_status_message(1, $status_text);

	return TRUE;

}

sub show_status_message {
	my $self         = shift;
	my $index        = shift;
	my $status_text  = shift;
	my $status_image = shift;    #this is a stock-id

	#~ #remove old message and timer
	#~ $self->{_drawing_statusbar}->pop($index);
	#~ Glib::Source->remove ($self->{_drawing_statusbar}->{statusbar_timer}) if defined $self->{_drawing_statusbar}->{statusbar_timer};

	#new message and image
	if (defined $status_image) {
		$self->{_drawing_statusbar_image}->set_from_stock($status_image, 'menu');
	} else {
		$self->{_drawing_statusbar_image}->clear;
	}
	$self->{_drawing_statusbar}->push($index, $status_text);

	#~ #...and remove it
	#~ $self->{_drawing_statusbar}->{statusbar_timer} = Glib::Timeout->add(
	#~ 3000,
	#~ sub {
	#~ $self->{_drawing_statusbar}->pop($index) if defined $self->{_drawing_statusbar};
	#~ return FALSE;
	#~ }
	#~ );

	return TRUE;
}

sub change_drawing_tool_cb {
	my $self = shift;
	return $self->{_toolbar_manager}->change_drawing_tool_cb(@_);
}

sub zoom_in_cb {
	my $self = shift;
	return $self->{_toolbar_manager}->zoom_in_cb(@_);
}

sub zoom_out_cb {
	my $self = shift;
	return $self->{_toolbar_manager}->zoom_out_cb(@_);
}

sub zoom_normal_cb {
	my $self = shift;
	return $self->{_toolbar_manager}->zoom_normal_cb(@_);
}

sub adjust_rulers {
	return TRUE;
	my ($self, $ev, $item) = @_;

	my $s = $self->{_canvas}->get_scale;

	my ($hlower, $hupper, $hposition, $hmax_size) = $self->{_hruler}->get_range;
	my ($vlower, $vupper, $vposition, $vmax_size) = $self->{_vruler}->get_range;

	if ($ev) {

		my $copy_event = $ev->copy;

		#modify event to respect scrollbars and canvas scale
		$copy_event->x(($copy_event->x_root - $hlower) * $s);
		$copy_event->y(($copy_event->y_root - $vlower) * $s);

		$self->{_hruler}->signal_emit('motion-notify-event', $copy_event);
		$self->{_vruler}->signal_emit('motion-notify-event', $copy_event);

	} else {

		#modify rulers (e.g. done when scrolling or zooming)
		if ($self->{_hruler} && $self->{_hruler}) {

			my ($x, $y, $width, $height, $depth) = $self->{_canvas}->get_window->get_geometry;
			my $ha = $self->{_scrolled_window}->get_hadjustment->get_value / $s;
			my $va = $self->{_scrolled_window}->get_vadjustment->get_value / $s;

			$self->{_hruler}->set_range($ha, $ha + $width / $s,  0, $hmax_size);
			$self->{_vruler}->set_range($va, $va + $height / $s, 0, $vmax_size);

		}

	}

	return TRUE;
}

sub quit {
	my ($self, $show_warning) = @_;

	my ($name, $folder, $type) = fileparse($self->{_filename}, qr/\.[^.]*/);

	#save settings to a file in the shutter folder
	#is there already a .shutter folder?
	mkdir("$ENV{ 'HOME' }/.shutter")
		unless (-d "$ENV{ 'HOME' }/.shutter");

	if ($show_warning && (defined $self->{_undo} && scalar(@{$self->{_undo}}) > 0)) {

		#warn the user if there are any unsaved changes
		my $warn_dialog = Gtk3::MessageDialog->new($self->{_drawing_window}, [qw/modal destroy-with-parent/], 'other', 'none', undef);

		#set question text
		$warn_dialog->set('text' => sprintf($self->{_d}->get("Save the changes to image %s before closing?"), "'$name$type'"));

		#set text...
		$self->update_warning_text($warn_dialog);

		#...and update it
		my $id = Glib::Timeout->add(
			1000,
			sub {
				$self->update_warning_text($warn_dialog);
				return TRUE;
			});

		$warn_dialog->set('image' => Gtk3::Image->new_from_stock('gtk-save', 'dialog'));

		$warn_dialog->set('title' => $self->{_d}->get("Close") . " " . $name . $type);

		#don't save button
		my $dsave_btn = Gtk3::Button->new_with_mnemonic($self->{_d}->get("Do_n't save"));
		$dsave_btn->set_image(Gtk3::Image->new_from_stock('gtk-delete', 'button'));

		#cancel button
		my $cancel_btn = Gtk3::Button->new_from_stock('gtk-cancel');
		$cancel_btn->set_can_default(TRUE);

		#save button
		my $save_btn = Gtk3::Button->new_from_stock('gtk-save');

		$warn_dialog->add_action_widget($dsave_btn,  10);
		$warn_dialog->add_action_widget($cancel_btn, 20);
		$warn_dialog->add_action_widget($save_btn,   30);

		$warn_dialog->set_default_response(20);

		$warn_dialog->get_child->show_all;
		my $response = $warn_dialog->run;
		Glib::Source->remove($id);
		if ($response == 20) {
			$warn_dialog->destroy;
			return TRUE;
		} elsif ($response == 30) {
			$self->save();
		}

		$self->{_drawing_window}->hide if $self->{_drawing_window};
		$warn_dialog->hide;
		$warn_dialog->destroy;

	}

	$self->save_settings;

	if ($self->{_selector_handler}) {
		$self->{_selector}->signal_handler_disconnect($self->{_selector_handler});
	}

	$self->{_drawing_window}->hide if $self->{_drawing_window};

	$self->{_drawing_window}->destroy if $self->{_drawing_window};

	#remove statusbar timer
	#Glib::Source->remove($self->{_drawing_statusbar}->{statusbar_timer}) if defined $self->{_drawing_statusbar}->{statusbar_timer};

	#delete hash entries to avoid any
	#possible circularity
	#
	#this would lead to a memory leak
	foreach (keys %{$self}) {
		delete $self->{$_};
	}

	Gtk3->main_quit();

	return FALSE;
}

sub update_warning_text {
	my ($self, $warn_dialog) = @_;

	my $minutes = int((time - $self->{_start_time}) / 60);
	$minutes = 1 if $minutes == 0;

	my $txt = $self->{_d}->nget(
		"If you don't save the image, changes from the last minute will be lost",
		"If you don't save the image, changes from the last %d minutes will be lost",
		$minutes
	);

	$txt = sprintf($txt, $minutes) if $minutes > 1;

	$warn_dialog->set(
		'secondary-text' => "$txt."
	);

	return TRUE;
}

sub load_settings {
	my $self = shift;
	return $self->{_settings_manager}->load_settings(@_);
}

sub save_settings {
	my $self = shift;
	return $self->{_settings_manager}->save_settings(@_);
}

sub import_from_dnd {
	my $self = shift;
	return $self->{_io_manager}->import_from_dnd(@_);
}

sub import_from_filesystem {
	my $self = shift;
	return $self->{_io_manager}->import_from_filesystem(@_);
}

sub import_from_utheme {
	my $self = shift;
	return $self->{_io_manager}->import_from_utheme(@_);
}

sub import_from_utheme_ctxt {
	my $self = shift;
	return $self->{_io_manager}->import_from_utheme_ctxt(@_);
}

sub import_from_session {
	my $self = shift;
	return $self->{_io_manager}->import_from_session(@_);
}

sub get_pixelated_pixbuf_from_canvas {
	my $self = shift;
	return $self->{_item_factory}->get_pixelated_pixbuf_from_canvas(@_);
}
sub export_to_file {
	my $self = shift;
	return $self->{_io_manager}->export_to_file(@_);
}

sub export_to_svg {
	my $self = shift;
	return $self->{_io_manager}->export_to_svg(@_);
}

sub export_to_ps {
	my $self = shift;
	return $self->{_io_manager}->export_to_ps(@_);
}

sub export_to_pdf {
	my $self = shift;
	return $self->{_io_manager}->export_to_pdf(@_);
}

sub save {
	my $self = shift;
	return $self->{_io_manager}->save(@_);
}

#ITEM SIGNALS
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

sub event_item_on_motion_notify {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_motion_notify(@_);
}
sub get_opposite_rect {
	my $self = shift;
	return $self->{_item_factory}->get_opposite_rect(@_);
}
sub get_parent_item {
	my $self = shift;
	return $self->{_item_factory}->get_parent_item(@_);
}
sub get_highest_auto_digit {
	my $self = shift;
	return $self->{_item_factory}->get_highest_auto_digit(@_);
}
sub get_child_item {
	my $self = shift;
	return $self->{_item_factory}->get_child_item(@_);
}
sub abort_current_mode {
	my ($self) = @_;

	if ($self->{_current_item}) {
		$self->{_canvas}->pointer_ungrab($self->{_current_item}, Gtk3::get_current_event_time());
		$self->{_canvas}->keyboard_ungrab($self->{_current_item}, Gtk3::get_current_event_time());
	}

	#~ print "abort_current_mode\n";

	$self->set_drawing_action(1);

	return TRUE;
}

sub clear_item_from_canvas {
	my ($self, $item) = @_;

	#~ print "clear_item_from_canvas\n";

	$self->{_current_item}     = undef;
	$self->{_current_new_item} = undef;

	if ($item) {

		#maybe there is a parent item to delete?
		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		#get child
		my $child = $self->get_child_item($item);

		#only delete if not already deleted (hidden)
		return FALSE if ($child && $child->get('visibility') eq 'hidden');

		#~ print "1st passed\n";
		return FALSE if (!$child && $item->get('visibility') eq 'hidden');

		#~ print "2nd passed\n";

		$self->store_to_xdo_stack($item, 'delete', 'undo');
		$item->set('visibility' => 'hidden');
		$self->handle_rects('hide', $item);
		$self->handle_embedded('hide', $item);

	}

	return TRUE;
}

sub store_to_xdo_stack {
	my $self = shift;
	return $self->{_macro_manager}->store_to_xdo_stack(@_);
}

sub xdo_remove {
	my $self = shift;
	return $self->{_macro_manager}->xdo_remove(@_);
}

sub xdo {
	my $self = shift;
	return $self->{_macro_manager}->xdo(@_);
}
sub set_and_save_drawing_properties {
	my $self = shift;
	return $self->{_settings_manager}->set_and_save_drawing_properties(@_);
}

sub restore_fixed_properties {
	my $self = shift;
	return $self->{_settings_manager}->restore_fixed_properties(@_);
}

sub restore_drawing_properties {
	my $self = shift;
	return $self->{_settings_manager}->restore_drawing_properties(@_);
}

sub event_item_on_key_press {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_key_press(@_);
}
sub event_item_on_button_press {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_button_press(@_);
}
sub ret_background_menu {
	my $self = shift;
	return $self->{_context_menu_manager}->ret_background_menu(@_);
}

sub ret_item_menu {
	my $self = shift;
	return $self->{_context_menu_manager}->ret_item_menu(@_);
}
sub get_item_key {
	my ($self, $item, $parent) = @_;
	if (exists $self->{_items}{$item}) {
		return $item;
	} else {
		return $parent;
	}
}

sub show_item_properties {
	my $self = shift;
	return $self->{_property_manager}->show_item_properties(@_);
}


sub apply_properties {
	my $self = shift;
	return $self->{_property_manager}->apply_properties(@_);
}


sub modify_text_in_properties {
	my $self = shift;
	return $self->{_property_manager}->modify_text_in_properties(@_);
}

sub move_all {
	my ($self, $x, $y) = @_;

	foreach (keys %{$self->{_items}}) {

		my $item = $self->{_items}{$_};

		#embedded item?
		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		#real shape
		if (exists $self->{_items}{$item}) {

			if ($item->isa('GooCanvas2::CanvasRect')) {

				$item->set(
					'x' => $item->get('x') - $x,
					'y' => $item->get('y') - $y,
				);

				my $child = $self->get_child_item($item);
				$child = $item unless $child;

				#it item is hidden, keep the status
				if ($child->get('visibility') eq 'hidden') {
					$self->handle_rects('hide', $item);
					$self->handle_embedded('hide', $item);
				} else {
					$self->handle_rects('update', $item);

					#pixelizer is treated differently
					if ($child && $child->isa('GooCanvas2::CanvasImage')) {
						my $parent = $self->get_parent_item($child);

						if (exists $self->{_items}{$parent}{pixelize}) {

							Glib::Idle->add(
								sub {
									$self->{_items}{$parent}{pixelize}->set(
										'x'      => int $self->{_items}{$parent}->get('x'),
										'y'      => int $self->{_items}{$parent}->get('y'),
										'width'  => $self->{_items}{$parent}->get('width'),
										'height' => $self->{_items}{$parent}->get('height'),
										'pixbuf' => $self->get_pixelated_pixbuf_from_canvas($self->{_items}{$parent}),
									);

									$self->handle_embedded('update', $parent, undef, undef, TRUE);

									#deactivate all after move
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

				#freehand line for example
			} else {

				$item->translate(-$x, -$y);

			}

		}
	}

	#deactivate all after move
	$self->deactivate_all;

	return TRUE;
}

sub deactivate_all {
	my $self    = shift;
	my $exclude = shift || 0;

	#~ print "deactivate_all\n";

	foreach (keys %{$self->{_items}}) {

		my $item = $self->{_items}{$_};

		next if $item == $exclude;

		#embedded item?
		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		#real shape
		if (exists $self->{_items}{$item}) {
			$self->handle_rects('hide', $item);
		}

	}

	$self->{_current_item}     = undef;
	$self->{_current_new_item} = undef;

	return TRUE;
}

sub handle_embedded {
	my $self = shift;
	return $self->{_canvas_overlays}->handle_embedded(@_);
}
sub handle_bg_rects {
	my $self = shift;
	return $self->{_canvas_overlays}->handle_bg_rects(@_);
}
sub handle_rects {
	my $self = shift;
	return $self->{_canvas_overlays}->handle_item_handles(@_);
}
sub event_item_on_button_release {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_button_release(@_);
}
sub event_item_on_enter_notify {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_enter_notify(@_);
}
sub event_item_on_leave_notify {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_leave_notify(@_);
}
sub setup_uimanager {
	my $self = shift;

	return Shutter::Draw::UIManager->new( app => $self )->setup;
}



sub utf8_decode {
	my $self   = shift;
	my $string = shift;

	#see https://bugs.launchpad.net/shutter/+bug/347821
	utf8::decode $string;

	return $string;
}

sub check_valid_mime_type {
	my $self      = shift;
	my $mime_type = shift;

	foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
		foreach my $mime (@{$format->get_mime_types}) {
			return TRUE if $mime_type eq $mime_type;
			last;
		}
	}

	return FALSE;
}



sub gen_thumbnail_on_idle {
	my $self       = shift;
	my $stock      = shift;
	my $parent     = shift;
	my $button     = shift;
	my $no_init    = shift;
	my @menu_items = @_;

	my $shutter_hfunct = Shutter::App::HelperFunctions->new($self->{_sc});

	#generate thumbnails in an idle callback
	my $next_item = 0;
	Glib::Idle->add(
		sub {

			#get next item
			my $child = $menu_items[$next_item];

			#no valid item - stop the idle handler
			unless ($child) {
				$parent->set_image(Gtk3::Image->new_from_stock($stock, 'menu')) if $parent;
				return FALSE;
			}

			my $name = $child->{'name'};

			#no valid item - stop the idle handler
			unless ($name) {
				$parent->set_image(Gtk3::Image->new_from_stock($stock, 'menu')) if $parent;
				return FALSE;
			}

			#increment counter
			$next_item++;

			#create thumbnail
			my $small_image;
			eval {

				#if uri exists we generate a thumbnail
				#with Shutter::Pixbuf::Thumbnail
				if (exists $child->{'giofile'}) {
					my $thumb;
					unless ($child->{'no_thumbnail'}) {
						$thumb = $self->{_lp_ne}->load($shutter_hfunct->utf8_decode($child->{'giofile'}->get_path), Gtk3::IconSize->lookup('small-toolbar'));
					} else {
						$thumb = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, 5, 5);
						$thumb->fill(0x00000000);
					}

					$small_image = Gtk3::Image->new_from_pixbuf($thumb);
				} else {
					my $pixbuf = $self->{_lp_ne}->load($name, undef, undef, undef, TRUE);

					#16x16 is minimum size
					if ($pixbuf->get_width >= 16 && $pixbuf->get_height >= 16) {
						$small_image = Gtk3::Image->new_from_pixbuf($pixbuf->scale_simple(Gtk3::IconSize->lookup('menu'), 'bilinear'));
					}
				}
			};
			unless ($@) {
				if ($small_image) {
					$child->set_image($small_image);

					#init when toplevel
					unless ($no_init) {
						unless ($button->get_icon_widget) {
							$button->set_icon_widget(Gtk3::Image->new_from_pixbuf($small_image->get_pixbuf));
							$self->{_current_pixbuf_filename} = $name;
							$button->show_all;
						}
					}

					$child->signal_connect(
						'activate' => sub {
							$self->{_current_pixbuf_filename} = $name;
							$button->set_icon_widget(Gtk3::Image->new_from_pixbuf($small_image->get_pixbuf));
							$button->show_all;
							$self->{_canvas}->get_window->set_cursor($self->change_cursor_to_current_pixbuf);
						});
				} else {
					$child->destroy;
				}
			} else {
				$child->destroy;
			}

			return TRUE;
		});    #end idle callback

}

sub set_drawing_action {
	my $self  = shift;
	my $index = shift;

	#~ print "set_drawing_action\n";

	my $item_index = 0;
	my $toolbar    = $self->{_uimanager}->get_widget("/ToolBarDrawing");
	for (my $i = 0 ; $i < $toolbar->get_n_items ; $i++) {
		my $item = $toolbar->get_nth_item($i);

		#skip separators
		#we only want to activate tools
		next if $item->isa('Gtk3::SeparatorToolItem');

		#add 1 to item index
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

}

sub change_cursor_to_current_pixbuf {
	my $self = shift;

	#~ print "change_cursor_to_current_pixbuf\n";

	$self->{_current_mode_descr} = "image";

	my $cursor = undef;

	#load file
	$self->{_current_pixbuf} = $self->{_lp}->load($self->{_current_pixbuf_filename}, undef, undef, undef, TRUE);
	unless ($self->{_current_pixbuf}) {
		$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), Gtk3::Gdk::Pixbuf->new_from_file($self->{_dicons} . '/draw-image.svg'), Gtk3::IconSize->lookup('menu'));
	}

	#very big images usually don't work as a cursor (no error though??)
	my $pb_w = $self->{_current_pixbuf}->get_width;
	my $pb_h = $self->{_current_pixbuf}->get_height;

	if ($pb_w < 800 && $pb_h < 800) {
		eval {

			#maximum cursor size
			my ($cw, $ch) = Gtk3::Gdk::Display::get_default->get_maximal_cursor_size;

			#images smaller than max cursor size?
			# => don't scale to a bigger size
			if ($cw > $pb_w || $ch > $pb_w) {
				$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), $self->{_current_pixbuf}, int($pb_w / 2), int($pb_h / 2));
			} else {
				my $cpixbuf = $self->{_lp}->load($self->{_current_pixbuf_filename}, $cw, $ch, TRUE, TRUE);
				$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), $cpixbuf, int($cpixbuf->get_width / 2), int($cpixbuf->get_height / 2));
			}

		};
		if ($@) {
			my $response = $self->{_dialogs}->dlg_error_message(
				sprintf($self->{_d}->get("Error while opening image %s."), "'" . $self->{_current_pixbuf_filename} . "'"),
				$self->{_d}->get("There was an error opening the image."),
				undef, undef, undef, undef, undef, undef, $@
			);
			$self->abort_current_mode;
		}
	} else {
		$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), Gtk3::Gdk::Pixbuf->new_from_file($self->{_dicons} . '/draw-image.svg'), Gtk3::IconSize->lookup('menu'));
	}

	return $cursor;
}

sub paste_item {
	my $self = shift;
	return $self->{_item_factory}->paste_item(@_);
}
sub create_polyline {
	my $self = shift;
	return $self->{_item_factory}->create_polyline(@_);
}
sub create_censor {
	my $self = shift;
	return $self->{_item_factory}->create_censor(@_);
}
sub create_pixel_image {
	my $self = shift;
	return $self->{_item_factory}->create_pixel_image(@_);
}
sub create_image {
	my $self = shift;
	return $self->{_item_factory}->create_image(@_);
}
sub create_text {
	my $self = shift;
	return $self->{_item_factory}->create_text(@_);
}
sub create_line {
	my $self = shift;
	return $self->{_item_factory}->create_line(@_);
}
sub create_ellipse {
	my $self = shift;
	return $self->{_item_factory}->create_ellipse(@_);
}
sub create_rectangle {
	my $self = shift;
	return $self->{_item_factory}->create_rectangle(@_);
}
sub gettext { shift->{_d} }
sub dicons { shift->{_dicons} }
sub icons { shift->{_icons} }
sub clipboard { shift->{_clipboard} }
sub items { shift->{_items} }
sub drawing_window { shift->{_drawing_window} }
sub canvas { shift->{_canvas} }
sub stipple_pixbuf { shift->{_stipple_pixbuf} }

sub cut {
	my $self = shift;
	$self->{_cut} = shift if scalar @_;
	return $self->{_cut};
}
sub current_copy_item {
	my $self = shift;
	$self->{_current_copy_item} = shift if scalar @_;
	return $self->{_current_copy_item};
}

sub current_item {
	my $self = shift;
	$self->{_current_item} = shift if scalar @_;
	return $self->{_current_item};
}

sub current_new_item {
	my $self = shift;
	$self->{_current_new_item} = shift if scalar @_;
	return $self->{_current_new_item};
}

sub canvas_bg {
	my $self = shift;
	$self->{_canvas_bg} = shift if scalar @_;
	return $self->{_canvas_bg};
}

sub factory {
	my $self = shift;
	$self->{_factory} = shift if scalar @_;
	return $self->{_factory};
}

sub autoscroll {
	my $self = shift;
	$self->{_autoscroll} = shift if scalar @_;
	return $self->{_autoscroll};
}

sub stroke_color {
	my $self = shift;
	$self->{_stroke_color} = shift if scalar @_;
	return $self->{_stroke_color};
}

sub fill_color {
	my $self = shift;
	$self->{_fill_color} = shift if scalar @_;
	return $self->{_fill_color};
}

sub line_width {
	my $self = shift;
	$self->{_line_width} = shift if scalar @_;
	return $self->{_line_width};
}

sub font {
	my $self = shift;
	$self->{_font} = shift if scalar @_;
	return $self->{_font};
}

sub uid { shift->{_uid} }

sub increase_uid { shift->{_uid}++ }

sub uimanager { shift->{_uimanager} }

sub toolbar_manager { shift->{_toolbar_manager} }

1;

