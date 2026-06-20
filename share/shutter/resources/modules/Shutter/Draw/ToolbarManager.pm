package Shutter::Draw::ToolbarManager;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has app => (is => 'ro', required => 1);

sub setup_bottom_hbox {
    my $self = shift;
    my $app  = $self->app;

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
    my $app    = $self->app;

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

1;
