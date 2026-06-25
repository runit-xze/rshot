package Shutter::Draw::Tool::Role::Resizable;

use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;

sub handle_resizing {
	my ($self, $item, $target, $ev) = @_;
	my $dt = $self->drawing_tool;

	$dt->{_current_mode_descr} = "resize";

	#canvas resizing shape
	if ($dt->{_canvas_bg_rect}{'right-side'} == $item) {
		my $new_width = $dt->{_canvas_bg_rect}->get('width') + ($ev->x - $item->{res_x});
		unless ($new_width < 0) {
			$dt->{_canvas_bg_rect}->set('width' => $new_width,);
			$dt->handle_bg_rects('update');
		}
	} elsif ($dt->{_canvas_bg_rect}{'bottom-side'} == $item) {
		my $new_height = $dt->{_canvas_bg_rect}->get('height') + ($ev->y - $item->{res_y});
		unless ($new_height < 0) {
			$dt->{_canvas_bg_rect}->set('height' => $new_height,);
			$dt->handle_bg_rects('update');
		}
	} elsif ($dt->{_canvas_bg_rect}{'bottom-right-corner'} == $item) {
		my $new_width  = $dt->{_canvas_bg_rect}->get('width') + ($ev->x - $item->{res_x});
		my $new_height = $dt->{_canvas_bg_rect}->get('height') + ($ev->y - $item->{res_y});
		unless ($new_width < 0 || $new_height < 0) {
			$dt->{_canvas_bg_rect}->set('width' => $new_width, 'height' => $new_height,);
			$dt->handle_bg_rects('update');
		}

	#item resizing shape
	} else {
		my $curr_item = $dt->{_current_item};
		return FALSE unless $curr_item;

		my $ratio = 1;
		$ratio = $dt->{_items}{$curr_item}->get('width') / $dt->{_items}{$curr_item}->get('height') if $dt->{_items}{$curr_item}->get('height') != 0;

		my $new_x      = 0;
		my $new_y      = 0;
		my $new_width  = 0;
		my $new_height = 0;

		foreach (keys %{$dt->{_items}{$curr_item}}) {
			next unless $_ =~ m/(corner|side)/;

			if ($dt->{_items}{$curr_item}{$_} == $item) {
				if ($_ eq 'bottom-side') {
					$new_x = $dt->{_items}{$curr_item}->get('x');
					$new_y = $dt->{_items}{$curr_item}->get('y');
					$new_width  = $dt->{_items}{$curr_item}->get('width');
					$new_height = $dt->{_items}{$curr_item}->get('height') + ($ev->y - $item->{res_y});
					last;
				} elsif ($_ eq 'bottom-right-corner') {
					$new_x = $dt->{_items}{$curr_item}->get('x');
					$new_y = $dt->{_items}{$curr_item}->get('y');
					if ($ev->state >= 'control-mask') {
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($ev->y - $item->{res_y}) * $ratio;
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($ev->y - $item->{res_y});
					} else {
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($ev->x - $item->{res_x});
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($ev->y - $item->{res_y});
					}
					last;
				} elsif ($_ eq 'top-left-corner') {
					if ($ev->state >= 'control-mask') {
						$new_x      = $dt->{_items}{$curr_item}->get('x') + ($ev->y - $item->{res_y}) * $ratio;
						$new_y      = $dt->{_items}{$curr_item}->get('y') + ($ev->y - $item->{res_y});
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($dt->{_items}{$curr_item}->get('x') - $new_x);
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($dt->{_items}{$curr_item}->get('y') - $new_y);
					} else {
						$new_x      = $dt->{_items}{$curr_item}->get('x') + $ev->x - $item->{res_x};
						$new_y      = $dt->{_items}{$curr_item}->get('y') + $ev->y - $item->{res_y};
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($dt->{_items}{$curr_item}->get('x') - $new_x);
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($dt->{_items}{$curr_item}->get('y') - $new_y);
					}
					last;
				} elsif ($_ eq 'top-side') {
					$new_x = $dt->{_items}{$curr_item}->get('x');
					$new_y = $dt->{_items}{$curr_item}->get('y') + $ev->y - $item->{res_y};
					$new_width  = $dt->{_items}{$curr_item}->get('width');
					$new_height = $dt->{_items}{$curr_item}->get('height') + ($dt->{_items}{$curr_item}->get('y') - $new_y);
					last;
				} elsif ($_ eq 'top-right-corner') {
					if ($ev->state >= 'control-mask') {
						$new_x      = $dt->{_items}{$curr_item}->get('x');
						$new_y      = $dt->{_items}{$curr_item}->get('y') - ($ev->x - $item->{res_x}) / $ratio;
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($ev->x - $item->{res_x});
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($dt->{_items}{$curr_item}->get('y') - $new_y);
					} else {
						$new_x      = $dt->{_items}{$curr_item}->get('x');
						$new_y      = $dt->{_items}{$curr_item}->get('y') + $ev->y - $item->{res_y};
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($ev->x - $item->{res_x});
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($dt->{_items}{$curr_item}->get('y') - $new_y);
					}
					last;
				} elsif ($_ eq 'right-side') {
					$new_x = $dt->{_items}{$curr_item}->get('x');
					$new_y = $dt->{_items}{$curr_item}->get('y');
					$new_width  = $dt->{_items}{$curr_item}->get('width') + ($ev->x - $item->{res_x});
					$new_height = $dt->{_items}{$curr_item}->get('height');
					last;
				} elsif ($_ eq 'left-side') {
					$new_x = $dt->{_items}{$curr_item}->get('x') + $ev->x - $item->{res_x};
					$new_y = $dt->{_items}{$curr_item}->get('y');
					$new_width  = $dt->{_items}{$curr_item}->get('width') + ($dt->{_items}{$curr_item}->get('x') - $new_x);
					$new_height = $dt->{_items}{$curr_item}->get('height');
					last;
				} elsif ($_ eq 'bottom-left-corner') {
					if ($ev->state >= 'control-mask') {
						$new_x      = $dt->{_items}{$curr_item}->get('x') - ($ev->y - $item->{res_y}) * $ratio;
						$new_y      = $dt->{_items}{$curr_item}->get('y');
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($dt->{_items}{$curr_item}->get('x') - $new_x);
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($ev->y - $item->{res_y});
					} else {
						$new_x      = $dt->{_items}{$curr_item}->get('x') + $ev->x - $item->{res_x};
						$new_y      = $dt->{_items}{$curr_item}->get('y');
						$new_width  = $dt->{_items}{$curr_item}->get('width') + ($dt->{_items}{$curr_item}->get('x') - $new_x);
						$new_height = $dt->{_items}{$curr_item}->get('height') + ($ev->y - $item->{res_y});
					}
					last;
				}
			}
		}

		if (defined $new_width && $new_width >= 0 && defined $new_height && $new_height >= 0) {
			$dt->{_items}{$curr_item}->set(
				'x'      => $new_x,
				'y'      => $new_y,
				'width'  => $new_width,
				'height' => $new_height,
			);

			$item->{res_x} = $ev->x;
			$item->{res_y} = $ev->y;

			$dt->handle_rects('update', $curr_item);
			$dt->handle_embedded('update', $curr_item);
		}
	}

	return TRUE;
}

sub start_resizing {
	my ($self, $item, $ev) = @_;
	$item->{res_x}    = $ev->x;
	$item->{res_y}    = $ev->y;
	$item->{resizing} = TRUE;
	return;
}

sub stop_resizing {
	my ($self, $item) = @_;
	$item->{resizing}       = FALSE if exists $item->{resizing};
	$item->{resizing_start} = FALSE if exists $item->{resizing_start};
	return;
}

1;
