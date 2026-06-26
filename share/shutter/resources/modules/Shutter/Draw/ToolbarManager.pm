package Shutter::Draw::ToolbarManager;

use Moo;
use utf8;
use v5.40;
use Glib           qw/TRUE FALSE/;
use File::Glob     qw/bsd_glob/;
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
	my $fill_color_label = Gtk3::Label->new($app->_d->get("Fill color") . ":");
	$app->_fill_color_w(Gtk3::ColorButton->new());
	$app->_fill_color_w->set_rgba($app->_fill_color);
	$app->_fill_color_w->set_use_alpha(TRUE);
	$app->_fill_color_w->set_title($app->_d->get("Choose fill color"));

	$fill_color_label->set_tooltip_text($app->_d->get("Adjust fill color and opacity"));
	$app->_fill_color_w->set_tooltip_text($app->_d->get("Adjust fill color and opacity"));

	$drawing_bottom_hbox->pack_start($fill_color_label,     FALSE, FALSE, 5);
	$drawing_bottom_hbox->pack_start($app->_fill_color_w, FALSE, FALSE, 5);

	# stroke color
	my $stroke_color_label = Gtk3::Label->new($app->_d->get("Stroke color") . ":");
	$app->_stroke_color_w(Gtk3::ColorButton->new());
	$app->_stroke_color_w->set_rgba($app->_stroke_color);
	$app->_stroke_color_w->set_use_alpha(TRUE);
	$app->_stroke_color_w->set_title($app->_d->get("Choose stroke color"));

	$stroke_color_label->set_tooltip_text($app->_d->get("Adjust stroke color and opacity"));
	$app->_stroke_color_w->set_tooltip_text($app->_d->get("Adjust stroke color and opacity"));

	$drawing_bottom_hbox->pack_start($stroke_color_label,     FALSE, FALSE, 5);
	$drawing_bottom_hbox->pack_start($app->_stroke_color_w, FALSE, FALSE, 5);

	# line_width
	my $linew_label = Gtk3::Label->new($app->_d->get("Line width") . ":");
	$app->_line_spin_w(Gtk3::SpinButton->new_with_range(0.5, 300, 0.1));
	$app->_line_spin_w->set_value($app->_line_width);

	$linew_label->set_tooltip_text($app->_d->get("Adjust line width"));
	$app->_line_spin_w->set_tooltip_text($app->_d->get("Adjust line width"));

	$drawing_bottom_hbox->pack_start($linew_label,         FALSE, FALSE, 5);
	$drawing_bottom_hbox->pack_start($app->_line_spin_w, FALSE, FALSE, 5);

	# font button
	my $font_label = Gtk3::Label->new($app->_d->get("Font") . ":");
	$app->_font_btn_w(Gtk3::FontButton->new());
	$app->_font_btn_w->set_font_name($app->_font);

	$font_label->set_tooltip_text($app->_d->get("Select font family and size"));
	$app->_font_btn_w->set_tooltip_text($app->_d->get("Select font family and size"));

	$drawing_bottom_hbox->pack_start($font_label,         FALSE, FALSE, 5);
	$drawing_bottom_hbox->pack_start($app->_font_btn_w, FALSE, FALSE, 5);

	# image button
	my $image_label = Gtk3::Label->new($app->_d->get("Insert image") . ":");
	my $image_btn   = Gtk3::MenuToolButton->new(undef, undef);

	Glib::Idle->add(
		sub {
			$image_btn->set_menu($app->import_from_filesystem($image_btn));
			return FALSE;
		});

	# handle property changes
	$app->_line_spin_wh($app->_line_spin_w->signal_connect(
		'value-changed' => sub {
			$app->_line_width($app->_line_spin_w->get_value);

			if ($app->_current_item) {
				my $item = $app->_current_item;
				if (my $child = $app->get_child_item($item)) {
					$item = $child;
				}
				my $parent = $app->get_parent_item($item);
				my $key    = $app->get_item_key($item, $parent);
				$app->apply_properties($item, $parent, $key, $app->_fill_color_w, $app->_stroke_color_w, $app->_line_spin_w, $app->_stroke_color_w, $app->_font_btn_w);
			}
		}));

	$app->_stroke_color_wh($app->_stroke_color_w->signal_connect(
		'color-set' => sub {
			$app->_stroke_color($app->_stroke_color_w->get_rgba);

			if ($app->_current_item) {
				my $item = $app->_current_item;
				if (my $child = $app->get_child_item($item)) {
					$item = $child;
				}
				my $parent = $app->get_parent_item($item);
				my $key    = $app->get_item_key($item, $parent);
				$app->apply_properties($item, $parent, $key, $app->_fill_color_w, $app->_stroke_color_w, $app->_line_spin_w, $app->_stroke_color_w, $app->_font_btn_w);
			}
		}));

	$app->_fill_color_wh($app->_fill_color_w->signal_connect(
		'color-set' => sub {
			$app->_fill_color($app->_fill_color_w->get_rgba);

			if ($app->_current_item) {
				my $item = $app->_current_item;
				if (my $child = $app->get_child_item($item)) {
					$item = $child;
				}
				my $parent = $app->get_parent_item($item);
				my $key    = $app->get_item_key($item, $parent);
				$app->apply_properties($item, $parent, $key, $app->_fill_color_w, $app->_stroke_color_w, $app->_line_spin_w, $app->_stroke_color_w, $app->_font_btn_w);
			}
		}));

	$app->_font_btn_wh($app->_font_btn_w->signal_connect(
		'font-set' => sub {
			my $font_descr = Pango::FontDescription::from_string($app->_font_btn_w->get_font_name);
			$app->_font($app->_font_btn_w->get_font_name);

			if ($app->_current_item) {
				my $item = $app->_current_item;
				if (my $child = $app->get_child_item($item)) {
					$item = $child;
				}
				my $parent = $app->get_parent_item($item);
				my $key    = $app->get_item_key($item, $parent);
				$app->apply_properties($item, $parent, $key, $app->_fill_color_w, $app->_stroke_color_w, $app->_line_spin_w, $app->_stroke_color_w, $app->_font_btn_w);
			}
		}));

	$image_btn->signal_connect(
		'clicked' => sub {
			$app->_canvas->get_window->set_cursor($app->change_cursor_to_current_pixbuf);
		});

	$image_label->set_tooltip_text($app->_d->get("Insert an arbitrary object or file"));
	$image_btn->set_tooltip_text($app->_d->get("Insert an arbitrary object or file"));

	$drawing_bottom_hbox->pack_start($image_label, FALSE, FALSE, 5);
	$drawing_bottom_hbox->pack_start($image_btn,   FALSE, FALSE, 5);

	return $drawing_bottom_hbox;
}

sub setup_view {
	my $self = shift;
	my $app  = $self->drawing_tool;

	#view, selector, dragger
	$app->_view(Gtk3::ImageView->new);
	$app->_selector(Gtk3::ImageView::Tool::Selector->new($app->_view));
	$app->{_dragger}  = Gtk3::ImageView::Tool::Dragger->new($app->_view);
	$app->_view->set_tool($app->_selector);
	$app->_view_css_provider_alpha(Gtk3::CssProvider->new);
	$app->_view->get_style_context->add_provider($app->_view_css_provider_alpha, 0);
	$app->_view->set('zoom-step', 1.2);

	#WORKAROUND
	#upstream bug
	#http://trac.bjourne.webfactional.com/ticket/21
	#left  => zoom in
	#right => zoom out
	$app->_view->signal_connect(
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
	$app->_view->signal_connect(
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

sub _init_window_and_title ($self) {
	my $app = $self->drawing_tool;

	$app->_d($app->_sc->gettext_object);

	$app->_root(Gtk3::Gdk::get_default_root_window());
	($app->_root->{x}, $app->_root->{y}, $app->_root->{w}, $app->_root->{h}) = $app->_root->get_geometry;
	($app->_root->{x}, $app->_root->{y}) = $app->_root->get_origin;

	$app->_drawing_window(Gtk3::Window->new('toplevel'));
	if (defined $app->_is_unsaved && $app->_is_unsaved) {
		$app->_drawing_window->set_title("*" . $app->_name . " - Shutter DrawingTool");
	} else {
		$app->_drawing_window->set_title($app->_filename . " - Shutter DrawingTool");
	}
	$app->_drawing_window->set_position('center');
	$app->_drawing_window->set_modal(1);
	$app->_drawing_window->signal_connect('delete_event', sub { return $app->quit(TRUE) });

	if ($app->_root->{w} > 640 && $app->_root->{h} > 480) {
		$app->_drawing_window->set_default_size(640, 480);
	} else {
		$app->_drawing_window->set_default_size($app->_root->{w} - 100, $app->_root->{h} - 100);
	}

	$app->_dialogs(Shutter::App::SimpleDialogs->new($app->_drawing_window));
	$app->_lp(Shutter::Pixbuf::Load->new($app->_sc, $app->_drawing_window));
	$app->_lp_ne(Shutter::Pixbuf::Load->new($app->_sc, $app->_drawing_window, TRUE));

	return;
}

sub _load_cursors ($self, $icon_theme) {
	my $app = $self->drawing_tool;

	if ($icon_theme eq 'auto') {
		my $context   = $app->_drawing_window->get_style_context();
		my $bg        = $context->get_background_color('normal');
		my $avg_color = ($bg->red + $bg->green + $bg->blue) / 3.0;
		$icon_theme = $avg_color > 0.5 ? 'dark' : 'light';
	}

	if ($icon_theme eq 'dark') {
		$app->_dicons($app->_sc->shutter_root . "/share/shutter/resources/icons/drawing_tool");
	} else {
		$app->_dicons($app->_sc->shutter_root . "/share/shutter/resources/icons/drawing_tool_dark");
	}

	$app->_icons($app->_sc->shutter_root . "/share/shutter/resources/icons");

	my @cursors = bsd_glob($app->_dicons . "/cursor/*");
	foreach my $cursor_path (@cursors) {
		my ($cname, $folder, $type) = fileparse($cursor_path, qr/\.[^.]*/);
		my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($cursor_path);

		if (!$pixbuf) {
			print "ERROR: Failed to load pixbuf from $cursor_path\n";
			next;
		}
		my $width  = $pixbuf->get_width();
		my $height = $pixbuf->get_height();

		my ($x_hot, $y_hot) = parse_xpm_hotspot($cursor_path);

		$x_hot //= $width / 2;
		$y_hot //= $height / 2;

		$app->_cursors->{$cname} = {
			'pixbuf' => $pixbuf,
			'x_hot'  => $x_hot,
			'y_hot'  => $y_hot,
		};
	}

	return;
}

sub _init_canvas ($self) {
	my $app = $self->drawing_tool;

	$app->_canvas(GooCanvas2::Canvas->new());

	$app->_canvas->drag_dest_set('all', [Gtk3::TargetEntry->new('text/uri-list', [], 0)], 'copy');
	$app->_canvas->signal_connect(drag_data_received => sub { $app->import_from_dnd(@_) });
	$app->_canvas->signal_connect(
		drag_motion => sub {
			my ($view, $ctx, $x, $y, $time) = @_;
			for my $target (@{$ctx->list_targets}) {
				if ($target->name eq 'text/uri-list') {
					Gtk3::Gdk::drag_status($ctx, 'copy', $time);
					return TRUE;
				}
			}
			return FALSE;
		});

	if ($app->_canvas->find_property('redraw-when-scrolled')) {
		$app->_canvas->set('redraw-when-scrolled' => TRUE);
	}

	$app->_canvas->set(
		'automatic-bounds'   => FALSE,
		'bounds-from-origin' => FALSE,
	);

	$app->_canvas->signal_connect(
		'scroll-event' => sub {
			my ($canvas, $ev) = @_;

			my $alloc = $app->_canvas->get_allocation;
			my $scale = $canvas->get_scale;

			if ($ev->state >= 'control-mask' && ($ev->direction eq 'up' || $ev->direction eq 'left')) {
				$app->zoom_in_cb;
				$canvas->scroll_to(int($ev->x - $alloc->{width} / 2) / $scale, int($ev->y - $alloc->{height} / 2) / $scale);
				return TRUE;
			} elsif ($ev->state >= 'control-mask' && ($ev->direction eq 'down' || $ev->direction eq 'right')) {
				$app->zoom_out_cb;
				return TRUE;
			}
			return FALSE;
		});

	require Shutter::Draw::CanvasOverlays;
	$app->_canvas_overlays(Shutter::Draw::CanvasOverlays->new(
		canvas        => $app->_canvas,
		items         => $app->_items,
		setup_signals => sub { $app->setup_item_signals_extra(@_) },
		style_bg      => $app->_drawing_window->get_style_context->get_background_color('normal'),
	));

	$app->_canvas_bg_rect(GooCanvas2::CanvasRect->new(
		parent                => $app->_canvas->get_root_item,
		x                     => 0,
		y                     => 0,
		width                 => $app->_drawing_pixbuf->get_width,
		height                => $app->_drawing_pixbuf->get_height,
		'fill-color-gdk-rgba' => Gtk3::Gdk::RGBA::parse('gray'),
		'line-dash'           => GooCanvas2::CanvasLineDash->newv([5, 5]),
		'line-width'          => 1,
		'stroke-color'        => 'black',
	));

	$app->_canvas_bg_rect->{fill_color} = Gtk3::Gdk::RGBA::parse('gray');
	$app->setup_item_signals($app->_canvas_bg_rect);

	$app->handle_bg_rects('create');
	$app->handle_bg_rects('update');

	$app->_current_pixbuf_filename($app->_filename);
	$app->_current_pixbuf($app->_drawing_pixbuf);

	my $initevent = Gtk3::Gdk::Event->new('motion-notify');
	$initevent->time(Gtk3::get_current_event_time());
	$initevent->window($app->_drawing_window->get_window);
	$initevent->x(int($app->_canvas_bg_rect->get('width') / 2));
	$initevent->y(int($app->_canvas_bg_rect->get('height') / 2));

	my $nitem = $app->create_image($initevent, undef, TRUE);
	$app->_canvas_bg($app->_items->{$nitem}{image});

	$app->_items->{$nitem}{locked} = FALSE;

	$app->handle_bg_rects('raise');

	return;
}

sub _build_layout ($self) {
	my $app = $self->drawing_tool;

	$app->_drawing_vbox(Gtk3::VBox->new(FALSE, 0));
	$app->_drawing_inner_vbox(Gtk3::VBox->new(FALSE, 0));
	$app->_drawing_inner_vbox_c(Gtk3::VBox->new(FALSE, 0));
	$app->_drawing_hbox(Gtk3::HBox->new(FALSE, 0));
	$app->_drawing_hbox_c(Gtk3::HBox->new(FALSE, 0));

	$app->_uimanager->get_widget("/ToolBar/Close")->set_is_important(TRUE);
	$app->_uimanager->get_widget("/ToolBar/Save")->set_is_important(TRUE);
	$app->_uimanager->get_widget("/ToolBar/Undo")->set_is_important(TRUE);

	$app->_uimanager->get_widget("/MenuBar/Edit/Undo")->set_sensitive(FALSE);
	$app->_uimanager->get_widget("/MenuBar/Edit/Redo")->set_sensitive(FALSE);
	$app->_uimanager->get_widget("/ToolBar/Undo")->set_sensitive(FALSE);
	$app->_uimanager->get_widget("/ToolBar/Redo")->set_sensitive(FALSE);

	$app->_drawing_window->add($app->_drawing_vbox);

	my $menubar = $app->_uimanager->get_widget("/MenuBar");
	$app->_drawing_vbox->pack_start($menubar, FALSE, FALSE, 0);

	my $toolbar_drawing = $app->_uimanager->get_widget("/ToolBarDrawing");
	$toolbar_drawing->set_orientation('vertical');
	$toolbar_drawing->set_style('icons');
	$toolbar_drawing->set_icon_size('menu');
	$toolbar_drawing->set_show_arrow(FALSE);
	$app->_drawing_hbox->pack_start($toolbar_drawing, FALSE, FALSE, 0);

	$app->_scrolled_window(Gtk3::ScrolledWindow->new);
	$app->_scrolled_window->set_policy('automatic', 'automatic');
	$app->_scrolled_window->add($app->_canvas);
	$app->_hscroll_hid($app->_scrolled_window->get_hscrollbar->signal_connect('value-changed' => sub { $self->adjust_rulers }));
	$app->_vscroll_hid($app->_scrolled_window->get_vscrollbar->signal_connect('value-changed' => sub { $self->adjust_rulers }));

	$app->_table(Gtk3::Table->new(3, 2, FALSE));
	$app->_table->attach($app->_scrolled_window, 1, 2, 1, 2, ['expand', 'fill'], ['expand', 'fill'], 0, 0);

	$app->_bhbox($app->_toolbar_manager->setup_bottom_hbox);
	$app->_drawing_inner_vbox->pack_start($app->_table, TRUE,  TRUE, 0);
	$app->_drawing_inner_vbox->pack_start($app->_bhbox, FALSE, TRUE, 0);

	$app->_scrolled_window_c(Gtk3::ScrolledWindow->new);
	$app->_scrolled_window_c->add_with_viewport($app->_view);
	my ($rframe_c, $btn_ok_c) = $app->setup_right_vbox_c;
	$app->_rframe_c($rframe_c);
	$app->_btn_ok_c($btn_ok_c);
	$app->_drawing_hbox_c->pack_start($app->_scrolled_window_c, TRUE,  TRUE,  0);
	$app->_drawing_hbox_c->pack_start($app->_rframe_c,          FALSE, FALSE, 3);

	$app->_drawing_inner_vbox_c->pack_start($app->_drawing_hbox_c, TRUE, TRUE, 0);

	$app->_drawing_hbox->pack_start($app->_drawing_inner_vbox,   TRUE, TRUE, 0);
	$app->_drawing_hbox->pack_start($app->_drawing_inner_vbox_c, TRUE, TRUE, 0);

	$app->_drawing_vbox->pack_start($app->_uimanager->get_widget("/ToolBar"), FALSE, FALSE, 0);
	$app->_drawing_vbox->pack_start($app->_drawing_hbox,                      TRUE,  TRUE,  0);

	$app->_drawing_statusbar(Gtk3::Statusbar->new);
	$app->_drawing_statusbar_image(Gtk3::Image->new);
	$app->_drawing_statusbar->pack_start($app->_drawing_statusbar_image, FALSE, FALSE, 3);
	$app->_drawing_statusbar->reorder_child($app->_drawing_statusbar_image, 0);
	$app->_drawing_vbox->pack_start($app->_drawing_statusbar, FALSE, FALSE, 6);

	$app->_drawing_window->show_all();

	return;
}

sub _finish_startup ($self) {
	my $app = $self->drawing_tool;

	$app->_drawing_window->get_window->focus(Gtk3::get_current_event_time());
	$self->adjust_rulers;

	$app->_start_time(time);

	$app->_last_fill_color($app->_fill_color_w->get_rgba);
	$app->_last_stroke_color($app->_stroke_color_w->get_rgba);
	$app->_last_line_width($app->_line_spin_w->get_value);
	$app->_last_font($app->_font_btn_w->get_font_name);

	$app->_last_mode(0);
	$app->set_drawing_action(int($app->_current_mode / 10));

	$app->_uimanager->get_action("/MenuBar/View/ControlEqual")->set_visible(FALSE);
	$app->_uimanager->get_action("/MenuBar/View/ControlKpAdd")->set_visible(FALSE);
	$app->_uimanager->get_action("/MenuBar/View/ControlKpSub")->set_visible(FALSE);

	$app->deactivate_all;

	Gtk3->main;

	return;
}

sub setup_main_window ($mgr, @args) {
	my $app = $mgr->drawing_tool;

	print "DrawingTool show called\n" if $app->_sc->debug;
	$app->_filename($args[0]);
	$app->_filetype($args[1]);
	$app->_mimetype($args[2]);
	$app->_name($args[3]);
	$app->_is_unsaved($args[4]);
	$app->_import_hash($args[5]);
	my $icon_theme = $args[6];

	$mgr->_init_window_and_title;
	$mgr->_load_cursors($icon_theme // 'auto');

	$app->_uimanager($app->setup_uimanager());
	$app->load_settings;

	$app->_drawing_pixbuf($app->_lp->load($app->_filename, undef, undef, undef, TRUE));
	unless ($app->_drawing_pixbuf) {
		$app->_drawing_window->destroy if $app->_drawing_window;
		return FALSE;
	}

	$mgr->_init_canvas;
	$mgr->_build_layout;
	$mgr->_finish_startup;

	return TRUE;
}

sub adjust_rulers ($self, @rest) {
	return;
}

sub push_tool_help_to_statusbar ($self, @rest) {
	return;
}

1;
