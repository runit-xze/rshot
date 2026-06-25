package Shutter::Draw::ToolbarManager;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;
use File::Glob qw/bsd_glob/;
use File::Basename qw/fileparse/;

has drawing_tool => (is => 'ro', required => 1);

with 'Shutter::Draw::Tool::ModeManager';
with 'Shutter::Draw::ZoomControl';
with 'Shutter::Draw::CropPanel';

sub setup_bottom_hbox {
	my $self = shift;
    my $app  = $self->drawing_tool;

    my $drawing_bottom_hbox = Gtk3::HBox->new(FALSE, 5);

    # fill color
    my $fill_color_label = Gtk3::Label->new($app->{_d}->get("Fill color") . ":");
    $app->{_fill_color_w} = Gtk3::ColorButton->new();
    $app->{_fill_color_w}->set_rgba($app->{_fill_color});
    $app->{_fill_color_w}->set_use_alpha(TRUE);
    $app->{_fill_color_w}->set_title($app->{_d}->get("Choose fill color"));

    $fill_color_label->set_tooltip_text($app->{_d}->get("Adjust fill color and opacity"));
    $app->{_fill_color_w}->set_tooltip_text($app->{_d}->get("Adjust fill color and opacity"));

    $drawing_bottom_hbox->pack_start($fill_color_label,      FALSE, FALSE, 5);
    $drawing_bottom_hbox->pack_start($app->{_fill_color_w}, FALSE, FALSE, 5);

    # stroke color
    my $stroke_color_label = Gtk3::Label->new($app->{_d}->get("Stroke color") . ":");
    $app->{_stroke_color_w} = Gtk3::ColorButton->new();
    $app->{_stroke_color_w}->set_rgba($app->{_stroke_color});
    $app->{_stroke_color_w}->set_use_alpha(TRUE);
    $app->{_stroke_color_w}->set_title($app->{_d}->get("Choose stroke color"));

    $stroke_color_label->set_tooltip_text($app->{_d}->get("Adjust stroke color and opacity"));
    $app->{_stroke_color_w}->set_tooltip_text($app->{_d}->get("Adjust stroke color and opacity"));

    $drawing_bottom_hbox->pack_start($stroke_color_label,      FALSE, FALSE, 5);
    $drawing_bottom_hbox->pack_start($app->{_stroke_color_w}, FALSE, FALSE, 5);

    # line_width
    my $linew_label = Gtk3::Label->new($app->{_d}->get("Line width") . ":");
    $app->{_line_spin_w} = Gtk3::SpinButton->new_with_range(0.5, 300, 0.1);
    $app->{_line_spin_w}->set_value($app->{_line_width});

    $linew_label->set_tooltip_text($app->{_d}->get("Adjust line width"));
    $app->{_line_spin_w}->set_tooltip_text($app->{_d}->get("Adjust line width"));

    $drawing_bottom_hbox->pack_start($linew_label,          FALSE, FALSE, 5);
    $drawing_bottom_hbox->pack_start($app->{_line_spin_w}, FALSE, FALSE, 5);

    # font button
    my $font_label = Gtk3::Label->new($app->{_d}->get("Font") . ":");
    $app->{_font_btn_w} = Gtk3::FontButton->new();
    $app->{_font_btn_w}->set_font_name($app->{_font});

    $font_label->set_tooltip_text($app->{_d}->get("Select font family and size"));
    $app->{_font_btn_w}->set_tooltip_text($app->{_d}->get("Select font family and size"));

    $drawing_bottom_hbox->pack_start($font_label,          FALSE, FALSE, 5);
    $drawing_bottom_hbox->pack_start($app->{_font_btn_w}, FALSE, FALSE, 5);

    # image button
    my $image_label = Gtk3::Label->new($app->{_d}->get("Insert image") . ":");
    my $image_btn   = Gtk3::MenuToolButton->new(undef, undef);

    Glib::Idle->add(
        sub {
            $image_btn->set_menu($app->import_from_filesystem($image_btn));
            return FALSE;
        });

    # handle property changes
    $app->{_line_spin_wh} = $app->{_line_spin_w}->signal_connect(
        'value-changed' => sub {
            $app->{_line_width} = $app->{_line_spin_w}->get_value;

            if ($app->{_current_item}) {
                my $item = $app->{_current_item};
                if (my $child = $app->get_child_item($item)) {
                    $item = $child;
                }
                my $parent = $app->get_parent_item($item);
                my $key = $app->get_item_key($item, $parent);
                $app->apply_properties($item, $parent, $key, $app->{_fill_color_w}, $app->{_stroke_color_w}, $app->{_line_spin_w}, $app->{_stroke_color_w}, $app->{_font_btn_w});
            }
        });

    $app->{_stroke_color_wh} = $app->{_stroke_color_w}->signal_connect(
        'color-set' => sub {
            $app->{_stroke_color} = $app->{_stroke_color_w}->get_rgba;

            if ($app->{_current_item}) {
                my $item = $app->{_current_item};
                if (my $child = $app->get_child_item($item)) {
                    $item = $child;
                }
                my $parent = $app->get_parent_item($item);
                my $key = $app->get_item_key($item, $parent);
                $app->apply_properties($item, $parent, $key, $app->{_fill_color_w}, $app->{_stroke_color_w}, $app->{_line_spin_w}, $app->{_stroke_color_w}, $app->{_font_btn_w});
            }
        });

    $app->{_fill_color_wh} = $app->{_fill_color_w}->signal_connect(
        'color-set' => sub {
            $app->{_fill_color} = $app->{_fill_color_w}->get_rgba;

            if ($app->{_current_item}) {
                my $item = $app->{_current_item};
                if (my $child = $app->get_child_item($item)) {
                    $item = $child;
                }
                my $parent = $app->get_parent_item($item);
                my $key = $app->get_item_key($item, $parent);
                $app->apply_properties($item, $parent, $key, $app->{_fill_color_w}, $app->{_stroke_color_w}, $app->{_line_spin_w}, $app->{_stroke_color_w}, $app->{_font_btn_w});
            }
        });

    $app->{_font_btn_wh} = $app->{_font_btn_w}->signal_connect(
        'font-set' => sub {
            my $font_descr = Pango::FontDescription::from_string($app->{_font_btn_w}->get_font_name);
            $app->{_font} = $app->{_font_btn_w}->get_font_name;

            if ($app->{_current_item}) {
                my $item = $app->{_current_item};
                if (my $child = $app->get_child_item($item)) {
                    $item = $child;
                }
                my $parent = $app->get_parent_item($item);
                my $key = $app->get_item_key($item, $parent);
                $app->apply_properties($item, $parent, $key, $app->{_fill_color_w}, $app->{_stroke_color_w}, $app->{_line_spin_w}, $app->{_stroke_color_w}, $app->{_font_btn_w});
            }
        });

    $image_btn->signal_connect(
        'clicked' => sub {
            $app->{_canvas}->get_window->set_cursor($app->change_cursor_to_current_pixbuf);
        });

    $image_label->set_tooltip_text($app->{_d}->get("Insert an arbitrary object or file"));
    $image_btn->set_tooltip_text($app->{_d}->get("Insert an arbitrary object or file"));

    $drawing_bottom_hbox->pack_start($image_label, FALSE, FALSE, 5);
    $drawing_bottom_hbox->pack_start($image_btn,   FALSE, FALSE, 5);

    return $drawing_bottom_hbox;
}


sub setup_view {
	my $self = shift;
	my $app = $self->drawing_tool;
	#view, selector, dragger
	$app->{_view}     = Gtk3::ImageView->new;
	$app->{_selector} = Gtk3::ImageView::Tool::Selector->new($app->{_view});
	$app->{_dragger}  = Gtk3::ImageView::Tool::Dragger->new($app->{_view});
	$app->{_view}->set_tool($app->{_selector});
	$app->{_view_css_provider_alpha} = Gtk3::CssProvider->new;
	$app->{_view}->get_style_context->add_provider($app->{_view_css_provider_alpha}, 0);
	$app->{_view}->set('zoom-step', 1.2);

	#WORKAROUND
	#upstream bug
	#http://trac.bjourne.webfactional.com/ticket/21
	#left  => zoom in
	#right => zoom out
	$app->{_view}->signal_connect(
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
	$app->{_view}->signal_connect(
		'zoom-changed' => sub {
			my ($view, $zoom) = @_;
			if ($zoom >= 1) {
				$view->set_interpolation('nearest');
				$view->set_zoom(10) if $zoom > 10;
			} else {
				$view->set_interpolation('bilinear');
			}
		});
    return;
}


# Workaround for broken xpm parsing in glycin:
# https://gitlab.gnome.org/GNOME/glycin/-/work_items/291
sub parse_xpm_hotspot {
	my $xpm_path = shift;
	my ($x_hot, $y_hot);

	open my $fh, '<', $xpm_path or do {
	    print "ERROR: Cannot open $xpm_path: $!\n";
	    return (undef, undef);
	};

	while (my $line = <$fh>) {
	    chomp($line);

	    if ($line =~ /"(\d+)\s+(\d+)\s+(\d+)\s+(\d+)(?:\s+(\d+)\s+(\d+))?/) {
	        my ($width, $height, $ncolors, $cpp, $xh, $yh) = ($1, $2, $3, $4, $5, $6);

	        if (defined($xh) && defined($yh)) {
	            $x_hot = $xh;
	            $y_hot = $yh;
	        } else {
	            print "DEBUG: No hotspot in header in $xpm_path\n";
	        }

	        last;
	    }
	}
	close $fh;

	return ($x_hot, $y_hot);
}

sub setup_main_window {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
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
		style_bg      => $self->{_drawing_window}->get_style_context->get_background_color('normal'),
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

sub adjust_rulers {
	my $self = shift;
    return;
}

sub push_tool_help_to_statusbar {
	my $self = shift;
    return;
}

1;
