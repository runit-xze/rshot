###################################################
#
#  Copyright (C) 2024 Shutter Project
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
###################################################

package Shutter::App::PinToScreen;

use utf8;
use v5.40;
use feature 'try'; no warnings 'experimental::try';
use Glib qw/TRUE FALSE/;
use Gtk3;

# Creates a floating, always-on-top overlay window that pins a pixbuf to the screen.
# The window is borderless, click-through-able via opacity toggle, and draggable.
# Close via the 'X' titlebar button or pressing Escape.

sub new ($class) {
    my $self = { _windows => [] };
    bless $self, $class;
    return $self;
}

# Pin a pixbuf to the screen.  Returns the created Gtk3::Window.
sub pin ($self, $pixbuf, $sc) {
    return unless defined $pixbuf;

    my $win = Gtk3::Window->new('toplevel');
    $win->set_title('Pinned Screenshot');
    $win->set_decorated(TRUE);           # keep title bar for drag/close
    $win->set_keep_above(TRUE);
    $win->set_skip_taskbar_hint(TRUE);
    $win->set_skip_pager_hint(TRUE);
    $win->set_resizable(TRUE);
    $win->set_opacity(0.95);

    # Try to set a nice compact window type hint
    $win->set_type_hint('utility');

    my $img = Gtk3::Image->new_from_pixbuf($pixbuf);

    # Wrap in a scrolled window so large captures can be panned
    my $sw = Gtk3::ScrolledWindow->new;
    $sw->set_policy('automatic', 'automatic');
    $sw->add_with_viewport($img);

    # Shrink the window to fit the pixbuf (max 800x600)
    my $w = $pixbuf->get_width;
    my $h = $pixbuf->get_height;
    my $max_w = 800; my $max_h = 600;
    $w = $max_w if $w > $max_w;
    $h = $max_h if $h > $max_h;
    $win->set_default_size($w, $h);

    # Toolbar with opacity slider and close button
    my $toolbar_box = Gtk3::HBox->new(FALSE, 4);
    my $opacity_label = Gtk3::Label->new('Opacity:');
    my $opacity_scale = Gtk3::Scale->new_with_range('horizontal', 20, 100, 5);
    $opacity_scale->set_value(95);
    $opacity_scale->set_draw_value(FALSE);
    $opacity_scale->set_size_request(100, -1);
    $opacity_scale->signal_connect('value-changed' => sub {
        $win->set_opacity($opacity_scale->get_value / 100);
    });

    my $close_btn = Gtk3::Button->new_with_label('Close');
    $close_btn->signal_connect('clicked' => sub { $win->destroy });

    $toolbar_box->pack_start($opacity_label,  FALSE, FALSE, 4);
    $toolbar_box->pack_start($opacity_scale,  TRUE,  TRUE,  0);
    $toolbar_box->pack_start($close_btn,      FALSE, FALSE, 4);

    my $vbox = Gtk3::VBox->new(FALSE, 0);
    $vbox->pack_start($toolbar_box, FALSE, FALSE, 2);
    $vbox->pack_start($sw, TRUE, TRUE, 0);

    $win->add($vbox);

    # Escape key closes the pin window
    $win->signal_connect('key-press-event' => sub {
        my ($widget, $event) = @_;
        if ($event->keyval == Gtk3::Gdk::KEY_Escape) {
            $win->destroy;
            return TRUE;
        }
        return FALSE;
    });

    # Track all open pin windows so we can close them all if needed
    push @{$self->{_windows}}, $win;
    $win->signal_connect('destroy' => sub {
        $self->{_windows} = [grep { $_ != $win } @{$self->{_windows}}];
    });

    $win->show_all;
    return $win;
}

# Close all currently pinned windows
sub unpin_all ($self) {
    for my $w (@{$self->{_windows}}) {
        $w->destroy if Gtk3::widget_get_visible($w) // FALSE;
    }
    $self->{_windows} = [];
}

sub has_pinned_windows ($self) {
    return scalar @{$self->{_windows}} > 0;
}

1;
