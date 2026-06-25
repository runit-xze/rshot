package Shutter::Draw::ZoomControl;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;

requires qw(
    drawing_tool
);

sub zoom_in_cb ($self) {
    my $app = $self->drawing_tool;

    if ($app->{_current_mode_descr} ne "crop") {
        $app->{_canvas}->set_scale($app->{_canvas}->get_scale + 0.2);
    } else {
        $app->{_view}->zoom_in;
    }

    return TRUE;
}

sub zoom_out_cb ($self) {
    my $app = $self->drawing_tool;

    if ($app->{_current_mode_descr} ne "crop") {
        my $new_scale = $app->{_canvas}->get_scale - 0.2;
        if ($new_scale < 0.2) {
            $app->{_canvas}->set_scale(0.2);
        } else {
            $app->{_canvas}->set_scale($new_scale);
        }
    } else {
        $app->{_view}->zoom_out;
    }

    return TRUE;
}

sub zoom_normal_cb ($self) {
    my $app = $self->drawing_tool;

    if ($app->{_current_mode_descr} ne "crop") {
        $app->{_canvas}->set_scale(1);
    } else {
        $app->{_view}->set_zoom(1);
    }

    return TRUE;
}

1;
