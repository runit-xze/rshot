package Shutter::Draw::CropPanel;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;

requires qw(
    drawing_tool
);

sub setup_right_vbox_c ($self) {
    my $app = $self->drawing_tool;

    my $cropping_bottom_vbox = Gtk3::VBox->new(FALSE, 5);

    my $pixbuf = $app->{_view}->get_pixbuf || $app->{_drawing_pixbuf};

    my $value_callback = sub {
        $app->{_selector}->set_selection({x=>$app->{_x_spin_w}->get_value, y=>$app->{_y_spin_w}->get_value, width=>$app->{_width_spin_w}->get_value, height=>$app->{_height_spin_w}->get_value});
    };

    my $xw_label = Gtk3::Label->new($app->{_d}->get("X") . ":");
    $app->{_x_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_width, 1);
    $app->{_x_spin_w}->set_value(0);
    $app->{_x_spin_w_handler} = $app->{_x_spin_w}->signal_connect(
        'value-changed' => $value_callback);

    my $xw_hbox = Gtk3::HBox->new(FALSE, 5);
    $xw_hbox->pack_start($xw_label,          FALSE, FALSE, 5);
    $xw_hbox->pack_start($app->{_x_spin_w}, FALSE, FALSE, 5);

    my $yw_label = Gtk3::Label->new($app->{_d}->get("Y") . ":");
    $app->{_y_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_height, 1);
    $app->{_y_spin_w}->set_value(0);
    $app->{_y_spin_w_handler} = $app->{_y_spin_w}->signal_connect(
        'value-changed' => $value_callback);

    my $yw_hbox = Gtk3::HBox->new(FALSE, 5);
    $yw_hbox->pack_start($yw_label,          FALSE, FALSE, 5);
    $yw_hbox->pack_start($app->{_y_spin_w}, FALSE, FALSE, 5);

    my $widthw_label = Gtk3::Label->new($app->{_d}->get("Width") . ":");
    $app->{_width_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_width, 1);
    $app->{_width_spin_w}->set_value(0);
    $app->{_width_spin_w_handler} = $app->{_width_spin_w}->signal_connect(
        'value-changed' => $value_callback);

    my $ww_hbox = Gtk3::HBox->new(FALSE, 5);
    $ww_hbox->pack_start($widthw_label,          FALSE, FALSE, 5);
    $ww_hbox->pack_start($app->{_width_spin_w}, FALSE, FALSE, 5);

    my $heightw_label = Gtk3::Label->new($app->{_d}->get("Height") . ":");
    $app->{_height_spin_w} = Gtk3::SpinButton->new_with_range(0, $pixbuf->get_height, 1);
    $app->{_height_spin_w}->set_value(0);
    $app->{_height_spin_w_handler} = $app->{_height_spin_w}->signal_connect(
        'value-changed' => $value_callback);

    my $hw_hbox = Gtk3::HBox->new(FALSE, 5);
    $hw_hbox->pack_start($heightw_label,          FALSE, FALSE, 5);
    $hw_hbox->pack_start($app->{_height_spin_w}, FALSE, FALSE, 5);

    $app->{_selector_handler} = $app->{_selector}->signal_connect(
        'selection-changed' => sub {
            $app->adjust_crop_values($pixbuf);
        });

    my $crop_c = Gtk3::Button->new_from_stock('gtk-cancel');
    $crop_c->signal_connect('clicked' => sub { $app->abort_current_mode });

    my $crop_ok = Gtk3::Button->new_with_mnemonic($app->{_d}->get("_Crop"));
    $crop_ok->set_image(Gtk3::Image->new_from_file($app->{_dicons} . '/transform-crop.png'));
    $crop_ok->signal_connect(
        'clicked' => sub {

            my $s = $app->{_selector}->get_selection;
            my $p = $app->{_view}->get_pixbuf;

            if ($s && $p) {

                $app->store_to_xdo_stack($app->{_canvas_bg}, 'modify', 'undo', $s);

                my $temp = Gtk3::Gdk::Pixbuf->new($app->{_drawing_pixbuf}->get_colorspace, TRUE, 8, $p->get_width, $p->get_height);

                $temp->fill(0x00000000);

                $app->{_drawing_pixbuf}->copy_area(0, 0, $app->{_drawing_pixbuf}->get_width, $app->{_drawing_pixbuf}->get_height, $temp, 0, 0);

                my $new_p = $temp->new_subpixbuf($s->{x}, $s->{y}, $s->{width}, $s->{height});
                $app->{_drawing_pixbuf} = $new_p->copy;

                $app->{_canvas_bg_rect}->set('width' => $s->{width}, 'height' => $s->{height});
                $app->handle_bg_rects('update');

                $app->{_canvas_bg}->set('pixbuf' => $new_p);

                $app->move_all($s->{x}, $s->{y});

                $app->{_canvas_bg}->lower;
                $app->{_canvas_bg_rect}->lower;
                $app->handle_bg_rects('raise');

            }

            $app->abort_current_mode;

        });

    my $sg_butt = Gtk3::SizeGroup->new('vertical');
    $sg_butt->add_widget($crop_c);
    $sg_butt->add_widget($crop_ok);

    my $cropping_bottom_vbox_b = Gtk3::VBox->new(FALSE, 5);
    $cropping_bottom_vbox_b->pack_start($crop_c,  FALSE, FALSE, 0);
    $cropping_bottom_vbox_b->pack_start($crop_ok, FALSE, FALSE, 0);

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

    my $crop_frame_label = Gtk3::Label->new;
    $crop_frame_label->set_markup("<b>" . $app->{_d}->get("Selection") . "</b>");

    my $crop_frame = Gtk3::Frame->new();
    $crop_frame->set_border_width(5);
    $crop_frame->set_label_widget($crop_frame_label);
    $crop_frame->set_shadow_type('none');

    $crop_frame->add($cropping_bottom_vbox);

    return ($crop_frame, $crop_ok);
}

sub adjust_crop_values ($self) {
    return;
}

1;
