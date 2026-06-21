package Shutter::Screenshot::Selector::ZoomOverlay;

use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Glib qw(TRUE FALSE);
use Cairo;

has app => (
    is       => 'ro',
    required => 1,
);

sub draw ($self, $cr, $mouse_x, $mouse_y) {
    my $app = $self->app;
    return unless $app->{_zoom_active};

    my $root = $app->{_root};
    return unless defined $root; # e.g. Wayland unsupported gracefully

    my $scale = $app->{_dpi_scale} || 1;

    # The zoom window dimensions
    my $zoom_w = 200 * $scale;
    my $zoom_h = 200 * $scale;
    my $magnification = 5; # 5x zoom

    # The source region to grab from root
    my $src_w = int($zoom_w / $magnification);
    my $src_h = int($zoom_h / $magnification);
    
    my $src_x = int($mouse_x) - int($src_w / 2);
    my $src_y = int($mouse_y) - int($src_h / 2);

    # Ensure we don't grab out of bounds
    my ($root_x, $root_y, $root_w, $root_h) = ($root->{x}, $root->{y}, $root->{w}, $root->{h});
    if ($src_x < $root_x) { $src_x = $root_x; }
    if ($src_y < $root_y) { $src_y = $root_y; }
    if ($src_x + $src_w > $root_x + $root_w) { $src_x = $root_x + $root_w - $src_w; }
    if ($src_y + $src_h > $root_y + $root_h) { $src_y = $root_y + $root_h - $src_h; }

    # Grab tiny region from root window
    my $pixbuf;
    try {
        $pixbuf = Gtk3::Gdk::pixbuf_get_from_window($root, $src_x, $src_y, $src_w, $src_h);
    } catch ($e) {
        return; # fallback if grab fails
    }
    return unless $pixbuf;

    # Scale the pixbuf
    my $scaled_pixbuf = $pixbuf->scale_simple($zoom_w, $zoom_h, 'nearest');

    # Determine where to draw the zoom window so it doesn't overlap the cursor too annoyingly
    my $draw_x = $mouse_x + 20 * $scale;
    my $draw_y = $mouse_y + 20 * $scale;
    
    # Keep it on screen
    if ($draw_x + $zoom_w > $root_x + $root_w) { $draw_x = $mouse_x - $zoom_w - 20 * $scale; }
    if ($draw_y + $zoom_h > $root_y + $root_h) { $draw_y = $mouse_y - $zoom_h - 20 * $scale; }

    $cr->save;

    # White border
    $cr->set_source_rgba(1, 1, 1, 1);
    $cr->rectangle($draw_x - 1, $draw_y - 1, $zoom_w + 2, $zoom_h + 2);
    $cr->fill;

    # The zoomed image
    Gtk3::Gdk::cairo_set_source_pixbuf($cr, $scaled_pixbuf, $draw_x, $draw_y);
    $cr->rectangle($draw_x, $draw_y, $zoom_w, $zoom_h);
    $cr->fill;

    # Crosshair in the middle
    $cr->set_source_rgba(1, 0, 0, 0.7);
    $cr->set_line_width(1);
    $cr->move_to($draw_x + $zoom_w / 2, $draw_y);
    $cr->line_to($draw_x + $zoom_w / 2, $draw_y + $zoom_h);
    $cr->move_to($draw_x, $draw_y + $zoom_h / 2);
    $cr->line_to($draw_x + $zoom_w, $draw_y + $zoom_h / 2);
    $cr->stroke;

    $cr->restore;
}

1;
