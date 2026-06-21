package Shutter::Draw::ToolbarManager;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

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

sub change_drawing_tool_cb {
    my $self   = shift;
    my $action = shift;
    my $app    = $self->drawing_tool;

    eval { $app->{_current_mode} = $action->get_current_value; };
    if ($@) {
        $app->{_current_mode} = $action;
    }

    my $cursor = Gtk3::Gdk::Cursor->new('left-ptr');

    if (   $app->{_current_mode} != $app->{_last_mode}
        && $app->{_current_mode} != 10
        && $app->{_current_mode} != 30
        && $app->{_current_mode} != 90
        && $app->{_current_mode} != 100
        && $app->{_current_mode} != 120)
    {
        $app->restore_drawing_properties;
    }

    if ($app->{_current_mode} != 120) {
        $app->{_table}->show_all;
        $app->{_bhbox}->show_all;
        $app->{_drawing_inner_vbox}->show_all;
        $app->{_drawing_inner_vbox_c}->hide;
    }

    $app->{_fill_color_w}->set_sensitive(TRUE);
    $app->{_stroke_color_w}->set_sensitive(TRUE);
    $app->{_line_spin_w}->set_sensitive(TRUE);
    $app->{_font_btn_w}->set_sensitive(TRUE);

    if ($app->{_current_mode} == 10) {
        $app->{_current_mode_descr} = "select";
    } elsif ($app->{_current_mode} == 20) {
        $app->{_current_mode_descr} = "freehand";
        $app->{_fill_color_w}->set_sensitive(FALSE);
        $app->{_font_btn_w}->set_sensitive(FALSE);
    } elsif ($app->{_current_mode} == 30) {
        $app->{_current_mode_descr} = "highlighter";
        $cursor = Gtk3::Gdk::Cursor->new('dotbox');
        $app->{_fill_color_w}->set_sensitive(FALSE);
        $app->{_font_btn_w}->set_sensitive(FALSE);
        $app->restore_fixed_properties($app->{_current_mode_descr});
    } elsif ($app->{_current_mode} == 40) {
        $app->{_current_mode_descr} = "line";
        $app->{_fill_color_w}->set_sensitive(FALSE);
        $app->{_font_btn_w}->set_sensitive(FALSE);
    } elsif ($app->{_current_mode} == 50) {
        $app->{_current_mode_descr} = "arrow";
        $app->{_fill_color_w}->set_sensitive(FALSE);
        $app->{_font_btn_w}->set_sensitive(FALSE);
    } elsif ($app->{_current_mode} == 60) {
        $app->{_current_mode_descr} = "rect";
        $app->{_font_btn_w}->set_sensitive(FALSE);
    } elsif ($app->{_current_mode} == 70) {
        $app->{_current_mode_descr} = "ellipse";
        $app->{_font_btn_w}->set_sensitive(FALSE);
    } elsif ($app->{_current_mode} == 80) {
        $app->{_current_mode_descr} = "text";
        $app->{_fill_color_w}->set_sensitive(FALSE);
        $app->{_line_spin_w}->set_sensitive(FALSE);
    } elsif ($app->{_current_mode} == 90) {
        $app->{_current_mode_descr} = "censor";
        $app->{_fill_color_w}->set_sensitive(FALSE);
        $app->{_stroke_color_w}->set_sensitive(FALSE);
        $app->{_line_spin_w}->set_sensitive(FALSE);
        $app->{_font_btn_w}->set_sensitive(FALSE);
        $app->restore_fixed_properties($app->{_current_mode_descr});
    } elsif ($app->{_current_mode} == 100) {
        $app->{_current_mode_descr} = "pixelize";
        $app->{_fill_color_w}->set_sensitive(FALSE);
        $app->{_stroke_color_w}->set_sensitive(FALSE);
        $app->{_line_spin_w}->set_sensitive(FALSE);
        $app->{_font_btn_w}->set_sensitive(FALSE);
    } elsif ($app->{_current_mode} == 110) {
        $app->{_current_mode_descr} = "number";
    } elsif ($app->{_current_mode} == 120) {
        $app->{_current_mode_descr} = "crop";
        $app->{_view}->set_pixbuf($app->save(TRUE));
        $app->{_view}->set_zoom(1);
        my $color_string = $app->{_canvas_bg_rect}{fill_color}->to_string;
        $app->{_view_css_provider_alpha}->load_from_data("
            GtkImageView {
                background-color: $color_string;
            }
        ");
        $cursor = Gtk3::Gdk::Cursor->new('crosshair');
        $app->{_drawing_inner_vbox_c}->show_all;
        $app->{_table}->hide;
        $app->{_bhbox}->hide;
    }

    if (defined $app->{_current_item}) {
        if ($app->{_current_mode_descr} ne "select" || $app->{_last_mode} == 120) {
            $app->deactivate_all;
        }
    }

    $app->{_last_mode} = $app->{_current_mode};

    if (defined $app->{_canvas} && $app->{_current_mode} != 120) {
        $app->{_canvas}->get_window->set_cursor($cursor);
    }

    if (defined $app->{_canvas} && $app->{_current_mode} == 120) {
        $app->{_view}->get_window->set_cursor($cursor);
    }
}

sub setup_right_vbox_c {
	my $self = shift;
	my $app = $self->drawing_tool;

	my $cropping_bottom_vbox = Gtk3::VBox->new(FALSE, 5);

	#get current pixbuf
	my $pixbuf = $app->{_view}->get_pixbuf || $app->{_drawing_pixbuf};

	my $value_callback = sub {
		$app->{_selector}->set_selection({x=>$app->{_x_spin_w}->get_value, y=>$app->{_y_spin_w}->get_value, width=>$app->{_width_spin_w}->get_value, height=>$app->{_height_spin_w}->get_value});
	};

	#X
	my $xw_label = Gtk3::Label->new($app->{_d}->get("X") . ":");
	$app->{_x_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_width, 1);
	$app->{_x_spin_w}->set_value(0);
	$app->{_x_spin_w_handler} = $app->{_x_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $xw_hbox = Gtk3::HBox->new(FALSE, 5);
	$xw_hbox->pack_start($xw_label,          FALSE, FALSE, 5);
	$xw_hbox->pack_start($app->{_x_spin_w}, FALSE, FALSE, 5);

	#y
	my $yw_label = Gtk3::Label->new($app->{_d}->get("Y") . ":");
	$app->{_y_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_height, 1);
	$app->{_y_spin_w}->set_value(0);
	$app->{_y_spin_w_handler} = $app->{_y_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $yw_hbox = Gtk3::HBox->new(FALSE, 5);
	$yw_hbox->pack_start($yw_label,          FALSE, FALSE, 5);
	$yw_hbox->pack_start($app->{_y_spin_w}, FALSE, FALSE, 5);

	#width
	my $widthw_label = Gtk3::Label->new($app->{_d}->get("Width") . ":");
	$app->{_width_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_width, 1);
	$app->{_width_spin_w}->set_value(0);
	$app->{_width_spin_w_handler} = $app->{_width_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $ww_hbox = Gtk3::HBox->new(FALSE, 5);
	$ww_hbox->pack_start($widthw_label,          FALSE, FALSE, 5);
	$ww_hbox->pack_start($app->{_width_spin_w}, FALSE, FALSE, 5);

	#height
	my $heightw_label = Gtk3::Label->new($app->{_d}->get("Height") . ":");
	$app->{_height_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_height, 1);
	$app->{_height_spin_w}->set_value(0);
	$app->{_height_spin_w_handler} = $app->{_height_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $hw_hbox = Gtk3::HBox->new(FALSE, 5);
	$hw_hbox->pack_start($heightw_label,          FALSE, FALSE, 5);
	$hw_hbox->pack_start($app->{_height_spin_w}, FALSE, FALSE, 5);

	#the above values are changed when the selection is changed
	$app->{_selector_handler} = $app->{_selector}->signal_connect(
		'selection-changed' => sub {
			$app->adjust_crop_values($pixbuf);
		});

	#cancel button
	my $crop_c = Gtk3::Button->new_from_stock('gtk-cancel');
	$crop_c->signal_connect('clicked' => sub { $app->abort_current_mode });

	#crop button
	my $crop_ok = Gtk3::Button->new_with_mnemonic($app->{_d}->get("_Crop"));
	$crop_ok->set_image(Gtk3::Image->new_from_file($app->{_dicons} . '/transform-crop.png'));
	$crop_ok->signal_connect(
		'clicked' => sub {

			my $s = $app->{_selector}->get_selection;
			my $p = $app->{_view}->get_pixbuf;

			if ($s && $p) {

				#add to undo stack
				$app->store_to_xdo_stack($app->{_canvas_bg}, 'modify', 'undo', $s);

				#create new pixbuf
				#create temp pixbuf because selected area might be bigger than
				#source pixbuf (screenshot) => canvas area is resizeable
				my $temp = Gtk3::Gdk::Pixbuf->new($app->{_drawing_pixbuf}->get_colorspace, TRUE, 8, $p->get_width, $p->get_height);

				#whole pixbuf is transparent
				$temp->fill(0x00000000);

				#copy source image to temp pixbuf (temp pixbuf's size == $app->{_view}->get_pixbuf)
				$app->{_drawing_pixbuf}->copy_area(0, 0, $app->{_drawing_pixbuf}->get_width, $app->{_drawing_pixbuf}->get_height, $temp, 0, 0);

				#and create a new subpixbuf from the temp pixbuf
				my $new_p = $temp->new_subpixbuf($s->{x}, $s->{y}, $s->{width}, $s->{height});
				$app->{_drawing_pixbuf} = $new_p->copy;

				#update bounds and bg_rects
				$app->{_canvas_bg_rect}->set('width' => $s->{width}, 'height' => $s->{height});
				$app->handle_bg_rects('update');

				#update canvas and show the new pixbuf
				$app->{_canvas_bg}->set('pixbuf' => $new_p);

				#now move all items,
				#so they are in the right position
				#~ print $s->x ." - ".$s->y."\n";
				$app->move_all($s->{x}, $s->{y});

				#adjust stack order
				$app->{_canvas_bg}->lower;
				$app->{_canvas_bg_rect}->lower;
				$app->handle_bg_rects('raise');

			} else {

				#nothing here right now
			}

			#finally reset mode to select tool
			$app->abort_current_mode;

		});

	#put buttons in a separated box
	#all buttons = one size
	my $sg_butt = Gtk3::SizeGroup->new('vertical');
	$sg_butt->add_widget($crop_c);
	$sg_butt->add_widget($crop_ok);

	my $cropping_bottom_vbox_b = Gtk3::VBox->new(FALSE, 5);
	$cropping_bottom_vbox_b->pack_start($crop_c,  FALSE, FALSE, 0);
	$cropping_bottom_vbox_b->pack_start($crop_ok, FALSE, FALSE, 0);

	#final_packing
	#all labels = one size
	$xw_label->set_alignment(0, 0.5);
	$yw_label->set_alignment(0, 0.5);
	$widthw_label->set_alignment(0, 0.5);
	$heightw_label->set_alignment(0, 0.5);

	my $sg_main = Gtk3::SizeGroup->new('horizontal');
	$sg_main->add_widget($xw_label);
	$sg_main->add_widget($yw_label);
	$sg_main->add_widget($widthw_label);
	$sg_main->add_widget($heightw_label);

	$cropping_bottom_vbox->pack_start($xw_hbox,                FALSE, FALSE, 3);
	$cropping_bottom_vbox->pack_start($yw_hbox,                FALSE, FALSE, 3);
	$cropping_bottom_vbox->pack_start($ww_hbox,                FALSE, FALSE, 3);
	$cropping_bottom_vbox->pack_start($hw_hbox,                FALSE, FALSE, 3);
	$cropping_bottom_vbox->pack_start($cropping_bottom_vbox_b, TRUE,  TRUE,  3);

	#nice frame as well
	my $crop_frame_label = Gtk3::Label->new;
	$crop_frame_label->set_markup("<b>" . $app->{_d}->get("Selection") . "</b>");

	my $crop_frame = Gtk3::Frame->new();
	$crop_frame->set_border_width(5);
	$crop_frame->set_label_widget($crop_frame_label);
	$crop_frame->set_shadow_type('none');

	$crop_frame->add($cropping_bottom_vbox);

	return ($crop_frame, $crop_ok);
}
sub zoom_in_cb {
	my $self = shift;
	my $app = $self->drawing_tool;

	if ($app->{_current_mode_descr} ne "crop") {
		$app->{_canvas}->set_scale($app->{_canvas}->get_scale + 0.2);

		#~ $app->adjust_rulers;
	} else {
		$app->{_view}->zoom_in;
	}

	return TRUE;
}

sub zoom_out_cb {
	my $self = shift;
	my $app = $self->drawing_tool;

	if ($app->{_current_mode_descr} ne "crop") {
		my $new_scale = $app->{_canvas}->get_scale - 0.2;
		if ($new_scale < 0.2) {
			$app->{_canvas}->set_scale(0.2);
		} else {
			$app->{_canvas}->set_scale($new_scale);
		}

		#~ $app->adjust_rulers;
	} else {
		$app->{_view}->zoom_out;
	}

	return TRUE;
}

sub zoom_normal_cb {
	my $self = shift;
	my $app = $self->drawing_tool;

	if ($app->{_current_mode_descr} ne "crop") {
		$app->{_canvas}->set_scale(1);

		#~ $app->adjust_rulers;
	} else {
		$app->{_view}->set_zoom(1);
	}

	return TRUE;
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
}

1;
