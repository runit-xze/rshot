package Shutter::Screenshot::Window::Highlighter;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;
use Pango;
use Cairo;

sub setup_highlighter ($self) {
	my $compos = $self->{_main_gtk_window}->get_screen->is_composited;

	$self->{_highlighter} = Gtk3::Window->new('popup');
	if ($compos) {
		my $screen = $self->{_main_gtk_window}->get_screen;
		$self->{_highlighter}->set_visual(
			Gtk3::Gdk::Screen::get_rgba_visual($screen)
				|| Gtk3::Gdb::Screen::get_system_visual($screen)
		);
	}

	$self->{_highlighter}->set_app_paintable(TRUE);
	$self->{_highlighter}->set_decorated(FALSE);
	$self->{_highlighter}->set_skip_taskbar_hint(TRUE);
	$self->{_highlighter}->set_skip_pager_hint(TRUE);
	$self->{_highlighter}->set_keep_above(TRUE);
	$self->{_highlighter}->set_accept_focus(FALSE);

	my $style     = $self->{_main_gtk_window}->get_style_context;
	my $sel_bg    = $style->get_background_color('selected');
	my $font_fam  = $style->get_font('normal')->get_family;
	my $font_size = $style->get_font('normal')->get_size / Pango::SCALE;

	$self->get_current_monitor;

	$self->{_highlighter_expose} = $self->{_highlighter}->signal_connect(
		'draw' => sub {
			return FALSE unless $self->{_highlighter}->get_window;

			$self->{_highlighter}->get_window->move_resize(
				$self->{_c}{'cw'}{'x'} / $self->{_dpi_scale} - 3,
				$self->{_c}{'cw'}{'y'} / $self->{_dpi_scale} - 3,
				$self->{_c}{'cw'}{'width'} / $self->{_dpi_scale} + 6,
				$self->{_c}{'cw'}{'height'} / $self->{_dpi_scale} + 6,
			);

			print $self->{_c}{'cw'}{'window'}->get_name, "\n" if $self->{_sc}->get_debug;

			my $text = Glib::Markup::escape_text($self->{_c}{'cw'}{'window'}->get_name);
			utf8::decode $text;

			my $sec_text = "\n" . $self->{_c}{'cw'}{'width'} . "x" . $self->{_c}{'cw'}{'height'};

			my ($w, $h) = $self->{_highlighter}->get_size;
			my $icon    = $self->{_c}{'cw'}{'window'}->get_icon;
			my $cr      = $_[1];

			my $layout = Pango::Cairo::create_layout($cr);
			$layout->set_width(($w - $icon->get_width - $font_size * 3) * Pango::SCALE);
			$layout->set_alignment('left');
			$layout->set_wrap('char');

			if ($self->{_c}{'ws'}) {
				my $xwindow = $self->{_c}{'ws'}->get_xid;
				if (scalar @{$self->{_c}{'cw'}{$xwindow}} <= 1) {
					$icon = Gtk3::Widget::render_icon(Gtk3::Invisible->new, "gtk-dialog-error", 'dialog');

					my $d = $self->{_sc}->get_gettext;
					$text     = $d->get("No subwindow detected");
					$sec_text = "\n" . $d->get("Maybe this window is using client-side windows (or similar).\nShutter is not yet able to query the tree information of such windows.");

					$layout->set_wrap('word-char');
				}
			}

			$layout->set_markup(
				"<span font_desc=\"$font_fam $font_size\" weight=\"bold\" foreground=\"#FFFFFF\">$text</span><span font_desc=\"$font_fam $font_size\" foreground=\"#FFFFFF\">$sec_text</span>"
			);

			my ($lw, $lh) = $layout->get_pixel_size;
			$lw += $icon->get_width;
			$lh = $icon->get_height if $icon->get_height > $lh;

			my $wi = $lw + $font_size * 3;
			my $hi = $lh + $font_size * 2;
			my $xi = int(($w - $wi) / 2);
			my $yi = int(($h - $hi) / 2);
			my $ri = 20;

			if ($compos) {
				$cr->set_operator('source');
				$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.3);
				$cr->paint;

				if ($self->{_c}{'cw'}{'is_parent'}) {
					$cr->set_operator('over');
					$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.75);
					$cr->set_line_width(6);
					$cr->rectangle(0, 0, $w, $h);
					$cr->stroke;

					if ($lw <= $w && $lh <= $h) {
						$cr->move_to($xi + $ri, $yi);
						$cr->line_to($xi + $wi - $ri, $yi);
						$cr->curve_to($xi + $wi, $yi, $xi + $wi, $yi, $xi + $wi, $yi + $ri);
						$cr->line_to($xi + $wi, $yi + $hi - $ri);
						$cr->curve_to($xi + $wi, $yi + $hi, $xi + $wi, $yi + $hi, $xi + $wi - $ri, $yi + $hi);
						$cr->line_to($xi + $ri, $yi + $hi);
						$cr->curve_to($xi, $yi + $hi, $xi, $yi + $hi, $xi, $yi + $hi - $ri);
						$cr->line_to($xi, $yi + $ri);
						$cr->curve_to($xi, $yi, $xi, $yi, $xi + $ri, $yi);
						$cr->fill;

						Gtk3::Gdk::cairo_set_source_pixbuf($cr, $icon, $xi + $font_size, $yi + $font_size);
						$cr->paint;

						$cr->move_to($xi + $font_size * 2 + $icon->get_width, $yi + $font_size);
						Pango::Cairo::show_layout($cr, $layout);
					}
				} else {
					$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.75);
					$cr->set_line_width(6);
					$cr->rectangle(0, 0, $w, $h);
					$cr->stroke;
				}
			} else {
				$cr->set_operator('over');
				$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.75);
				$cr->paint;

				if ($self->{_c}{'cw'}{'is_parent'} && $lw <= $w && $lh <= $h) {
					Gtk3::Gdk::cairo_set_source_pixbuf($cr, $icon, $xi + $font_size, $yi + $font_size);
					$cr->paint;

					$cr->move_to($xi + $font_size * 2 + $icon->get_width, $yi + $font_size);
					Pango::Cairo::show_layout($cr, $layout);
				}

				my $shape_region1 = Cairo::Region->create({ x => 0, y => 0, width => $w, height => $h });
				my $shape_region2 = Cairo::Region->create({ x => 3, y => 3, width => $w - 6, height => $h - 6 });
				my $shape_region3 = Cairo::Region->create({ x => $xi, y => $yi, width => $wi, height => $hi });

				if ($self->{_c}{'cw'}{'is_parent'} && $lw <= $w && $lh <= $h) {
					$shape_region2->subtract($shape_region3);
				}

				$shape_region1->subtract($shape_region2);
				$self->{_highlighter}->get_window->shape_combine_region($shape_region1, 0, 0);
			}

			return TRUE;
		}
	);
}

1;
