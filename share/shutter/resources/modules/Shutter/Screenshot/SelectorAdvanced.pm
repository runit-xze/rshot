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

package Shutter::Screenshot::SelectorAdvanced;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Shutter::Screenshot::Main;
use Shutter::Screenshot::History;
use Shutter::Screenshot::Selector::ZoomOverlay;
use Shutter::Screenshot::Selector::SelectionModel;
use Shutter::Screenshot::Selector::InputManager;

use Data::Dumper;
use Gtk3;
use Pango;
use Cairo;
use parent 'Shutter::Screenshot::Main';

#Glib
use Glib qw/TRUE FALSE/;

#--------------------------------------

sub new ($class, $sc, $include_cursor, $delay, $notify_timeout, $zoom_active, $hide_time, $show_help, $init_x, $init_y, $init_w, $init_h, $confirmation_necessary) {

	#call constructor of super class (shutter_common, include_cursor, delay, notify_timeout)
	my $self = $class->SUPER::new($sc, $include_cursor, $delay, $notify_timeout);

	$self->{_zoom_active} = $zoom_active;
	$self->{_hide_time}   = $hide_time;    #a short timeout to give the server a chance to redraw the area that was obscured
	$self->{_show_help}   = $show_help;    #hide help text?

	#initial selection size
	$self->{_init_x} = $init_x;
	$self->{_init_y} = $init_y;
	$self->{_init_w} = $init_w;
	$self->{_init_h} = $init_h;
	$self->{_confirmation_necessary} = $confirmation_necessary;

	$self->{_dpi_scale} = Gtk3::Window->new('toplevel')->get('scale-factor');

	$self->{_selection} = { x => $init_x || 0, y => $init_y || 0, width => $init_w || 0, height => $init_h || 0 };
	$self->{_drag_start} = undef;

	$self->{_draw_area} = Gtk3::DrawingArea->new();
	$self->{_draw_area}->set_events(['button-press-mask', 'button-release-mask', 'pointer-motion-mask', 'key-press-mask']);

	bless $self, $class;
	$self->{_mouse_x} = $init_x;
	$self->{_mouse_y} = $init_y;
	$self->{_zoom_overlay} = Shutter::Screenshot::Selector::ZoomOverlay->new(app => $self);

	$self->{_model} = Shutter::Screenshot::Selector::SelectionModel->new(
		max_w => $self->{_root}->{w},
		max_h => $self->{_root}->{h},
		on_changed => sub ($model) {
			$self->{_selection} = $model->get_hash;
			$self->{_draw_area}->queue_draw if $self->{_draw_area};
			$self->adjust_prop_values if $self->can('adjust_prop_values');
		}
	);
	$self->{_input} = Shutter::Screenshot::Selector::InputManager->new(app => $self, model => $self->{_model});

	return $self;
}

sub select_advanced ($self) {

	#return value
	my $output = 5;

	my $d = $self->{_sc}->get_gettext;

	#window to manipulate the selection
	$self->{_prop_window} = $self->select_dialog();
	$self->{_prop_active} = FALSE;

	#window that contains the drawing area
	$self->{_select_window} = Gtk3::Window->new('popup');
	$self->{_select_window}->set_type_hint('splashscreen');
	$self->{_select_window}->set_can_focus(TRUE);
	$self->{_select_window}->set_accept_focus(TRUE);
	$self->{_select_window}->set_modal(TRUE);
	$self->{_select_window}->set_decorated(FALSE);
	$self->{_select_window}->set_skip_taskbar_hint(TRUE);
	$self->{_select_window}->set_skip_pager_hint(TRUE);
	$self->{_select_window}->set_keep_above(TRUE);
	
	my $screen = $self->{_select_window}->get_screen;
	my $visual = $screen->get_rgba_visual;
	$self->{_select_window}->set_visual($visual) if defined $visual;
	$self->{_select_window}->set_app_paintable(TRUE);

	$self->{_select_window}->add($self->{_draw_area});
	$self->{_select_window}->set_default_size($self->{_root}->{w}, $self->{_root}->{h});
	$self->{_select_window}->resize($self->{_root}->{w}, $self->{_root}->{h});
	$self->{_select_window}->move($self->{_root}->{x}, $self->{_root}->{y});
	$self->{_select_window}->show_all;
	$self->{_select_window}->present;

	if ($self->{_show_help} && ($self->{_init_w} < 1 || $self->{_init_h} < 1)) {
		$self->{_selector_init} = TRUE;
	} else {
		$self->{_selector_init} = FALSE;
	}

	$self->{_draw_area}->signal_connect('button-press-event' => sub {
		my ($widget, $event) = @_;
		if ($event->button == 1) {
			if ($self->{_selector_init}) {
				$self->{_selector_init} = FALSE;
			}
			if ($event->type eq '2button-press' || (defined $self->{_dclick} && $event->time - $self->{_dclick} <= 500)) {
				$self->{_dclick} = $event->time;
				$self->{_select_window}->hide;
				$self->{_prop_window}->hide;
				Glib::Timeout->add($self->{_hide_time}, sub { Gtk3->main_quit; return FALSE; });
				Gtk3->main();
				$output = $self->take_screenshot($self->{_selection});
				$self->quit;
				return TRUE;
			}
			$self->{_dclick} = $event->time;
			$self->{_drag_start} = { x => $event->x, y => $event->y };
			$self->{_selection} = { x => int($event->x), y => int($event->y), width => 0, height => 0 };
			$widget->queue_draw;
		}
		return TRUE;
	});

	$self->{_draw_area}->signal_connect('motion-notify-event' => sub {
		my ($widget, $event) = @_;
		
		$self->{_mouse_x} = $event->x;
		$self->{_mouse_y} = $event->y;
		
		if ($self->{_zoom_active}) {
			$widget->queue_draw;
		}
		
		if ($self->{_drag_start}) {
			my $sx = $self->{_drag_start}->{x};
			my $sy = $self->{_drag_start}->{y};
			my $ex = $event->x;
			my $ey = $event->y;
			
			my $x = int($sx < $ex ? $sx : $ex);
			my $y = int($sy < $ey ? $sy : $ey);
			my $w = int(abs($ex - $sx));
			my $h = int(abs($ey - $sy));
			
			$self->{_model}->set_rect($x, $y, $w, $h);
		}
		return TRUE;
	});

	$self->{_draw_area}->signal_connect('button-release-event' => sub {
		my ($widget, $event) = @_;
		if ($event->button == 1 && $self->{_drag_start}) {
			$self->{_drag_start} = undef;
			if (not $self->{_confirmation_necessary}) {
				$self->{_select_window}->hide;
				$self->{_prop_window}->hide;
				Glib::Timeout->add($self->{_hide_time}, sub { Gtk3->main_quit; return FALSE; });
				Gtk3->main();
				$self->{_final_output} = $self->take_screenshot($self->{_selection});
				$self->quit;
			}
		} elsif ($event->button == 3) {
			if ($self->{_prop_active}) {
				Gtk3::Gdk::keyboard_ungrab(Gtk3::get_current_event_time());
				$self->{_prop_window}->hide;
				$self->{_prop_active} = FALSE;
				Gtk3::Gdk::keyboard_grab($self->{_select_window}->get_window, 0, Gtk3::get_current_event_time());
			} else {
				Gtk3::Gdk::keyboard_ungrab(Gtk3::get_current_event_time());
				my ($window_at_pointer, $x, $y, $mask) = $self->{_root}->get_pointer;
				$self->{_prop_window}->move($x, $y);
				$self->{_prop_window}->show_all;
				$self->{_prop_active} = TRUE;
				Gtk3::Gdk::keyboard_grab($self->{_prop_window}->get_window, 0, Gtk3::get_current_event_time());
			}
		}
		return TRUE;
	});

	$self->{_draw_area}->signal_connect('draw' => sub {
		my ($widget, $cr) = @_;
		
		# Fill with semi-transparent black
		$cr->set_source_rgba(0, 0, 0, 0.4);
		$cr->set_operator('source');
		$cr->paint;
		
		# Clear the selection area
		my $s = $self->{_selection};
		if ($s && $s->{width} > 0 && $s->{height} > 0) {
			$cr->rectangle($s->{x}, $s->{y}, $s->{width}, $s->{height});
			$cr->set_operator('clear');
			$cr->fill;
			
			# Draw a border
			$cr->rectangle($s->{x}, $s->{y}, $s->{width}, $s->{height});
			$cr->set_operator('over');
			$cr->set_source_rgba(1, 1, 1, 0.8);
			$cr->set_line_width(1);
			$cr->stroke;
		}

		if (defined $self->{_mouse_x} && defined $self->{_mouse_y}) {
			$self->{_zoom_overlay}->draw($cr, $self->{_mouse_x}, $self->{_mouse_y});
		}

		if ($self->{_show_help} && $self->{_selector_init}) {
			my $mon1 = $self->get_current_monitor;
			my $style     = $self->{_sc}->get_mainwindow->get_style_context;
			my $sel_bg    = Gtk3::Gdk::RGBA::parse('#131313');
			my $font_fam  = $style->get_font('normal')->get_family;
			my $font_size = $style->get_font('normal')->get_size * $self->{_dpi_scale} / Pango::SCALE;
			
			my $layout = Pango::Cairo::create_layout($cr);
			$layout->set_width(int($mon1->{width} * $self->{_dpi_scale} / 2) * Pango::SCALE);
			$layout->set_alignment('left');
			$layout->set_wrap('word');
			
			my $size1 = int($font_size * 2.0);
			my $size2 = int($font_size * 1.5);
			my $size3 = int($font_size * 1.0);
			my $text1 = $d->get("Draw a rectangular area using the mouse.");
			my $text2 = $d->get("To take a screenshot, double-click or press the Enter key.\nPress Esc to abort.");
			my $text3 =
				  $d->get("<b>shift/right-click</b> → selection dialog on/off") . "\n"
				. $d->get("<b>cursor keys</b> → move cursor") . "\n"
				. $d->get("<b>cursor keys + alt</b> → move selection") . "\n"
				. $d->get("<b>cursor keys + ctrl</b> → resize selection");
			$layout->set_markup(
"<span font_desc=\"$font_fam $size1\" foreground=\"#FFFFFF\">$text1</span>\n<span font_desc=\"$font_fam $size2\" foreground=\"#FFFFFF\">$text2</span>\n\n<span font_desc=\"$font_fam $size3\" foreground=\"#FFFFFF\">$text3</span>"
			);

			$cr->set_operator('over');
			$cr->set_source_rgba($sel_bg->red, $sel_bg->green, $sel_bg->blue, 0.85);

			my ($lw, $lh) = $layout->get_pixel_size;
			my $w = $lw + $size1 * 2;
			my $h = $lh + $size1 * 2;
			my $x = int(($mon1->{width}*$self->{_dpi_scale} - $w) / 2) + $mon1->{x};
			my $y = int(($mon1->{height}*$self->{_dpi_scale} - $h) / 2) + $mon1->{y};
			my $r = 20*$self->{_dpi_scale};

			$cr->move_to($x + $r, $y);
			$cr->line_to($x + $w - $r, $y);
			$cr->curve_to($x + $w, $y, $x + $w, $y, $x + $w, $y + $r);
			$cr->line_to($x + $w, $y + $h - $r);
			$cr->curve_to($x + $w, $y + $h, $x + $w, $y + $h, $x + $w - $r, $y + $h);
			$cr->line_to($x + $r, $y + $h);
			$cr->curve_to($x, $y + $h, $x, $y + $h, $x, $y + $h - $r);
			$cr->line_to($x, $y + $r);
			$cr->curve_to($x, $y, $x, $y, $x + $r, $y);
			$cr->fill;

			$cr->move_to($x + $size1, $y + $size1);
			Pango::Cairo::show_layout($cr, $layout);
		}
		
		return FALSE;
	});

	$self->{_key_handler} = $self->{_select_window}->signal_connect(
		'key-press-event' => sub {
			my ($window, $event) = @_;
			return FALSE unless defined $event;

			my ($window_at_pointer, $x, $y, $mask) = $self->{_root}->get_pointer;
			return $self->{_input}->handle_key_press($event, $x, $y);
		});

	my $status = Gtk3::Gdk::keyboard_grab($self->{_select_window}->get_window, 0, Gtk3::get_current_event_time());

	Gtk3->main();

	return $self->{_final_output} // $output;
}

sub adjust_prop_values ($self) {

	$self->{_x_spin_w}->signal_handler_block($self->{_x_spin_w_handler});
	$self->{_y_spin_w}->signal_handler_block($self->{_y_spin_w_handler});
	$self->{_width_spin_w}->signal_handler_block($self->{_width_spin_w_handler});
	$self->{_height_spin_w}->signal_handler_block($self->{_height_spin_w_handler});

	my $s = $self->{_selection};

	if ($s) {
		$self->{_x_spin_w}->set_value($s->{x});
		$self->{_x_spin_w}->set_range(0, $self->{_root}->{w} - $s->{width});

		$self->{_y_spin_w}->set_value($s->{y});
		$self->{_y_spin_w}->set_range(0, $self->{_root}->{h} - $s->{height});

		$self->{_width_spin_w}->set_value($s->{width});
		$self->{_width_spin_w}->set_range(0, $self->{_root}->{w} - $s->{x});

		$self->{_height_spin_w}->set_value($s->{height});
		$self->{_height_spin_w}->set_range(0, $self->{_root}->{h} - $s->{y});
	}

	$self->{_x_spin_w}->signal_handler_unblock($self->{_x_spin_w_handler});
	$self->{_y_spin_w}->signal_handler_unblock($self->{_y_spin_w_handler});
	$self->{_width_spin_w}->signal_handler_unblock($self->{_width_spin_w_handler});
	$self->{_height_spin_w}->signal_handler_unblock($self->{_height_spin_w_handler});

	return TRUE;

}

sub select_dialog ($self) {

	my $d = $self->{_sc}->get_gettext;

	my $s = $self->{_selection};

	my $sx = 0;
	my $sy = 0;
	my $sw = 0;
	my $sh = 0;

	if (defined $s) {
		$sx = $s->{x};
		$sy = $s->{y};
		$sw = $s->{width};
		$sh = $s->{height};
	}

	my $value_callback = sub {
		$self->{_selection} = {
			x => $self->{_x_spin_w}->get_value, 
			y => $self->{_y_spin_w}->get_value, 
			width => $self->{_width_spin_w}->get_value, 
			height => $self->{_height_spin_w}->get_value
		};
		$self->{_draw_area}->queue_draw;
	};

	#X
	my $xw_label = Gtk3::Label->new($d->get("X") . ":");
	$self->{_x_spin_w} = Gtk3::SpinButton->new_with_range(0, $self->{_root}->{w}, 1);
	$self->{_x_spin_w}->set_value($sx);
	$self->{_x_spin_w_handler} = $self->{_x_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $xw_hbox = Gtk3::Box->new('horizontal', 5);
	$xw_hbox->pack_start($xw_label,          FALSE, FALSE, 5);
	$xw_hbox->pack_start($self->{_x_spin_w}, FALSE, FALSE, 5);

	#y
	my $yw_label = Gtk3::Label->new($d->get("Y") . ":");
	$self->{_y_spin_w} = Gtk3::SpinButton->new_with_range(0, $self->{_root}->{h}, 1);
	$self->{_y_spin_w}->set_value($sy);
	$self->{_y_spin_w_handler} = $self->{_y_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $yw_hbox = Gtk3::Box->new('horizontal', 5);
	$yw_hbox->pack_start($yw_label,          FALSE, FALSE, 5);
	$yw_hbox->pack_start($self->{_y_spin_w}, FALSE, FALSE, 5);

	#width
	my $widthw_label = Gtk3::Label->new($d->get("Width") . ":");
	$self->{_width_spin_w} = Gtk3::SpinButton->new_with_range(0, $self->{_root}->{w}, 1);
	$self->{_width_spin_w}->set_value($sw);
	$self->{_width_spin_w_handler} = $self->{_width_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $ww_hbox = Gtk3::Box->new('horizontal', 5);
	$ww_hbox->pack_start($widthw_label,          FALSE, FALSE, 5);
	$ww_hbox->pack_start($self->{_width_spin_w}, FALSE, FALSE, 5);

	#height
	my $heightw_label = Gtk3::Label->new($d->get("Height") . ":");
	$self->{_height_spin_w} = Gtk3::SpinButton->new_with_range(0, $self->{_root}->{h}, 1);
	$self->{_height_spin_w}->set_value($sh);
	$self->{_height_spin_w_handler} = $self->{_height_spin_w}->signal_connect(
		'value-changed' => $value_callback);

	my $hw_hbox = Gtk3::Box->new('horizontal', 5);
	$hw_hbox->pack_start($heightw_label,          FALSE, FALSE, 5);
	$hw_hbox->pack_start($self->{_height_spin_w}, FALSE, FALSE, 5);

	my $prop_dialog = Gtk3::Window->new('toplevel');
	$prop_dialog->set_modal(TRUE);
	$prop_dialog->set_decorated(FALSE);
	$prop_dialog->set_skip_taskbar_hint(TRUE);
	$prop_dialog->set_skip_pager_hint(TRUE);
	$prop_dialog->set_keep_above(TRUE);
	$prop_dialog->set_accept_focus(TRUE);
	$prop_dialog->set_resizable(FALSE);

	$prop_dialog->signal_connect(
		'key-press-event' => sub {
			my $window = shift;
			my $event  = shift;

			if ($event->keyval == Gtk3::Gdk::keyval_from_name('Shift_L') || $event->keyval == Gtk3::Gdk::keyval_from_name('Shift_R')) {

				if ($self->{_prop_active}) {
					Gtk3::Gdk::keyboard_ungrab(Gtk3::get_current_event_time());
					$self->{_prop_window}->hide;
					$self->{_prop_active} = FALSE;
					Gtk3::Gdk::keyboard_grab($self->{_select_window}->get_window, 0, Gtk3::get_current_event_time());
				} else {
					Gtk3::Gdk::keyboard_ungrab(Gtk3::get_current_event_time());
					my ($window_at_pointer, $x, $y, $mask) = $self->{_root}->get_pointer;
					$self->{_prop_window}->move($x, $y);
					$self->{_prop_window}->show_all;
					$self->{_prop_active} = TRUE;
					Gtk3::Gdk::keyboard_grab($self->{_prop_window}->get_window, 0, Gtk3::get_current_event_time());
				}

			} elsif ($event->keyval == Gtk3::Gdk::keyval_from_name('Escape')) {
				$self->quit;
			}
		});

	my $hide_btn = Gtk3::Button->new_with_mnemonic($d->get("_Hide"));
	$hide_btn->set_image(Gtk3::Image->new_from_stock('gtk-close', 'button'));
	$hide_btn->set_can_default(TRUE);
	$hide_btn->signal_connect(
		'clicked' => sub {
			Gtk3::Gdk::keyboard_ungrab(Gtk3::get_current_event_time());
			$prop_dialog->hide;
			$self->{_prop_active} = FALSE;
			Gtk3::Gdk::keyboard_grab($self->{_select_window}->get_window, 0, Gtk3::get_current_event_time());
		});

	$xw_label->set_alignment(0, 0.5);
	$yw_label->set_alignment(0, 0.5);
	$widthw_label->set_alignment(0, 0.5);
	$heightw_label->set_alignment(0, 0.5);

	my $sg_main = Gtk3::SizeGroup->new('horizontal');
	$sg_main->add_widget($xw_label);
	$sg_main->add_widget($yw_label);
	$sg_main->add_widget($widthw_label);
	$sg_main->add_widget($heightw_label);

	my $vbox = Gtk3::Box->new('vertical', 5);
	$vbox->pack_start($xw_hbox,  FALSE, FALSE, 3);
	$vbox->pack_start($yw_hbox,  FALSE, FALSE, 3);
	$vbox->pack_start($ww_hbox,  FALSE, FALSE, 3);
	$vbox->pack_start($hw_hbox,  FALSE, FALSE, 3);
	$vbox->pack_start($hide_btn, FALSE, FALSE, 3);

	my $frame_label = Gtk3::Label->new;
	$frame_label->set_markup("<b>" . $d->get("Selection") . "</b>");

	my $frame = Gtk3::Frame->new();
	$frame->set_border_width(5);
	$frame->set_label_widget($frame_label);
	$frame->set_shadow_type('none');

	$frame->add($vbox);

	$prop_dialog->add($frame);

	$prop_dialog->realize;
	$prop_dialog->set_transient_for($self->{_select_window});
	$prop_dialog->get_window->set_override_redirect(TRUE);

	return $prop_dialog;
}

sub take_screenshot ($self, $s) {

	my $d = $self->{_sc}->get_gettext;

	my $output;

	if ($s && $s->{width} > 0 && $s->{height} > 0) {
		($output) = $self->get_pixbuf_from_drawable($self->{_root}, $s->{x}, $s->{y}, $s->{width}, $s->{height});
	} else {
		$output = 0;
	}

	if ($output =~ /Gtk3/) {
		$self->{_action_name} = $d->get("Selection");
	}

	if ($s && $s->{width} > 0 && $s->{height} > 0) {
		$self->{_history} = Shutter::Screenshot::History->new($self->{_sc}, $self->{_root}, $s->{x}, $s->{y}, $s->{width}, $s->{height});
	}

	return $output;
}

sub redo_capture ($self) {
	my $output = 3;
	if (defined $self->{_history}) {
		($output) = $self->get_pixbuf_from_drawable($self->{_history}->get_last_capture);
	}
	return $output;
}

sub get_history ($self) {
	return $self->{_history};
}

sub get_error_text ($self) {
	return $self->{_error_text};
}

sub get_action_name ($self) {
	return $self->{_action_name};
}

sub quit ($self) {

	$self->ungrab_pointer_and_keyboard(FALSE, FALSE, TRUE);
	$self->clean;
}

sub clean ($self) {

	$self->{_select_window}->destroy if $self->{_select_window};
	$self->{_prop_window}->destroy if $self->{_prop_window};
}

1;
