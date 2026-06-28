package Shutter::Draw::CanvasOverlays;

## no critic (NamingConventions::ProhibitAmbiguousNames)

use utf8;
use v5.40;
use Moo;
use Glib qw/TRUE FALSE/;
use GooCanvas2;

has 'canvas'        => (is => 'ro', required => 1);
has 'items'         => (is => 'ro', required => 1);
has 'setup_signals' => (is => 'ro', required => 1);
has 'style_bg'      => (is => 'ro', required => 1);

# Handle canvas background resize handles (3 handles)
sub handle_bg_rects {
	my ($self, $action, $bg_rect) = @_;
	my $x      = $bg_rect->get('x');
	my $y      = $bg_rect->get('y');
	my $width  = $bg_rect->get('width');
	my $height = $bg_rect->get('height');

	my $middle_h = $x + $width / 2;
	my $middle_v = $y + $height / 2;
	my $bottom   = $y + $height;
	my $right    = $x + $width;

	if ($action eq 'create') {

		# Create right-side, bottom-side, and bottom-right-corner handles
		$self->_create_bg_handle($bg_rect, 'bottom-side',         $middle_h, $bottom);
		$self->_create_bg_handle($bg_rect, 'bottom-right-corner', $right,    $bottom);
		$self->_create_bg_handle($bg_rect, 'right-side',          $right,    $middle_v);

	} elsif ($action eq 'hide' || $action eq 'show') {
		my $visibility = ($action eq 'hide') ? 'hidden' : 'visible';
		foreach (keys %$bg_rect) {
			if ($bg_rect->{$_}->can('set')) {
				$bg_rect->{$_}->set('visibility' => $visibility);
			}
		}

	} elsif ($action eq 'update') {
		$self->canvas->set_bounds(0, 0, $width, $height);
		$bg_rect->{'bottom-side'}->set('x' => $middle_h - 8, 'y' => $bottom - 8);
		$bg_rect->{'bottom-right-corner'}->set('x' => $right - 8, 'y' => $bottom - 8);
		$bg_rect->{'right-side'}->set('x' => $right - 8, 'y' => $middle_v - 8);
		$self->handle_bg_rects('raise', $bg_rect);

	} elsif ($action eq 'raise') {
		$bg_rect->{'bottom-side'}->raise;
		$bg_rect->{'bottom-right-corner'}->raise;
		$bg_rect->{'right-side'}->raise;
	}
	return;
}

# Handle item resize handles (8 handles)
sub handle_item_handles {
	my ($self, $action, $item) = @_;
	return FALSE unless $item && exists $self->items->{$item};

	my $x      = $self->items->{$item}->get('x');
	my $y      = $self->items->{$item}->get('y');
	my $width  = $self->items->{$item}->get('width');
	my $height = $self->items->{$item}->get('height');

	my $middle_h = $x + $width / 2;
	my $middle_v = $y + $height / 2;

	if ($action eq 'create') {
		$self->_create_item_handles($item, $x, $y, $width, $height, $middle_h, $middle_v);

	} elsif ($action eq 'delete') {
		$self->_delete_item_handles($item);

	} elsif ($action eq 'update' || $action eq 'hide') {
		my $visibility = ($action eq 'hide') ? 'hidden' : 'visible';
		$self->_update_item_handle_positions($item, $x, $y, $width, $height, $visibility);

	} elsif ($action eq 'raise') {
		$self->_raise_item_handles($item);

	} elsif ($action eq 'lower') {
		$self->_lower_item_handles($item);
	}

	return TRUE;
}

# Handle embedded items within parent rect
sub handle_embedded {    ## no critic (Subroutines::ProhibitManyArgs)
	my ($self, $action, $item, $new_width, $new_height, $force_show) = @_;
	return FALSE unless ($item && exists $self->items->{$item});

	if ($action eq 'update') {
		$self->_update_embedded($self->items->{$item}, $force_show);
	} elsif ($action eq 'delete') {
		$self->_delete_embedded($self->items->{$item});
	} elsif ($action eq 'hide') {
		$self->_hide_embedded($self->items->{$item});
	} elsif ($action eq 'mirror') {
		$self->_mirror_line($self->items->{$item}, $new_width, $new_height);
	}

	return TRUE;
}

# Private methods

sub _create_bg_handle {
	my ($self, $bg_rect, $name, $x, $y) = @_;
	$bg_rect->{$name} = $self->_make_handle_rect($x, $y);
	$self->setup_signals->($bg_rect->{$name});
	return;
}

sub _make_handle_rect {
	my ($self, $x, $y) = @_;

	# Must be overridden or injected with style_bg
	return GooCanvas2::CanvasRect->new(
		parent                => $self->canvas->get_root_item,
		x                     => $x,
		y                     => $y,
		width                 => 8,
		height                => 8,
		'fill-color-gdk-rgba' => $self->{style_bg},
		'line-width'          => 1,
	);
}

sub _create_item_handles {    ## no critic (Subroutines::ProhibitManyArgs)
	my ($self, $item, $x, $y, $width, $height, $middle_h, $middle_v) = @_;

	# Create all 8 handles
	$self->items->{$item}{'top-side'}            = $self->_make_handle_rect($middle_h, $y);
	$self->items->{$item}{'top-left-corner'}     = $self->_make_corner_handle($x - 8,      $y - 8);
	$self->items->{$item}{'top-right-corner'}    = $self->_make_corner_handle($x + $width, $y - 8);
	$self->items->{$item}{'bottom-side'}         = $self->_make_handle_rect($middle_h, $y + $height);
	$self->items->{$item}{'bottom-left-corner'}  = $self->_make_corner_handle($x - 8,      $y + $height);
	$self->items->{$item}{'bottom-right-corner'} = $self->_make_corner_handle($x + $width, $y + $height);
	$self->items->{$item}{'left-side'}           = $self->_make_handle_rect($x - 8,      $middle_v);
	$self->items->{$item}{'right-side'}          = $self->_make_handle_rect($x + $width, $middle_v);

	# Setup signals for all handles
	$self->_setup_all_handle_signals($self->items->{$item});
	return;
}

sub _make_corner_handle {
	my ($self, $x, $y) = @_;
	return GooCanvas2::CanvasRect->new(
		parent                => $self->canvas->get_root_item,
		x                     => $x,
		y                     => $y,
		width                 => 8,
		height                => 8,
		'fill-color-gdk-rgba' => $self->{style_bg},
		'visibility'          => 'hidden',
		'line-width'          => 0.5,
		'radius-x'            => 8,
		'radius-y'            => 8,
	);
}

sub _setup_all_handle_signals {
	my ($self, $item_hash) = @_;
	my @handles = qw(
		top-side top-left-corner top-right-corner
		bottom-side bottom-left-corner bottom-right-corner
		left-side right-side
	);

	for my $handle (@handles) {
		$self->setup_signals->($item_hash->{$handle});
	}
	return;
}

sub _delete_item_handles {
	my ($self, $item) = @_;
	my @handles = qw(
		top-side top-left-corner top-right-corner
		bottom-side bottom-left-corner bottom-right-corner
		left-side right-side
	);

	for my $handle (@handles) {
		if (my $nint = $self->canvas->get_root_item->find_child($self->items->{$item}{$handle})) {
			$self->canvas->get_root_item->remove_child($nint);
		}
	}
	return;
}

sub _update_item_handle_positions {    ## no critic (Subroutines::ProhibitManyArgs)
	my ($self, $item, $x, $y, $width, $height, $visibility) = @_;
	my $middle_h = $x + $width / 2;
	my $middle_v = $y + $height / 2;
	my $bottom   = $y + $height;
	my $top      = $y;
	my $left     = $x;
	my $right    = $x + $width;

	# Update embedded visibility
	if (exists $self->items->{$item}{ellipse}) {
		$self->items->{$item}->set('visibility' => $visibility);
	}
	if (exists $self->items->{$item}{text}) {
		$self->items->{$item}->set('visibility' => $visibility);
	}
	if (exists $self->items->{$item}{pixelize}) {
		$self->items->{$item}->set('visibility' => $visibility);
	}
	if (exists $self->items->{$item}{image}) {
		$self->items->{$item}->set('visibility' => $visibility);
	}
	if (exists $self->items->{$item}{line}) {
		$self->items->{$item}->set('visibility' => $visibility);
	}

	return FALSE unless defined $self->items->{$item}{'top-side'};

	$self->items->{$item}{'top-side'}->set('x' => $middle_h - 4, 'y' => $top - 8, 'visibility' => $visibility);
	$self->items->{$item}{'top-left-corner'}->set('x' => $left - 8, 'y' => $top - 8, 'visibility' => $visibility);
	$self->items->{$item}{'top-right-corner'}->set('x' => $right, 'y' => $top - 8, 'visibility' => $visibility);
	$self->items->{$item}{'bottom-side'}->set('x' => $middle_h - 4, 'y' => $bottom, 'visibility' => $visibility);
	$self->items->{$item}{'bottom-left-corner'}->set('x' => $left - 8, 'y' => $bottom, 'visibility' => $visibility);
	$self->items->{$item}{'bottom-right-corner'}->set('x' => $right, 'y' => $bottom, 'visibility' => $visibility);
	$self->items->{$item}{'left-side'}->set('x' => $left - 8, 'y' => $middle_v - 4, 'visibility' => $visibility);
	$self->items->{$item}{'right-side'}->set('x' => $right, 'y' => $middle_v - 4, 'visibility' => $visibility);
	return;
}

sub _raise_item_handles {
	my ($self, $item) = @_;
	my @handles = qw(
		top-side top-left-corner top-right-corner
		bottom-side bottom-left-corner bottom-right-corner
		left-side right-side
	);

	for my $handle (@handles) {
		$self->items->{$item}{$handle}->raise;
	}
	return;
}

sub _lower_item_handles {
	my ($self, $item) = @_;
	my @handles = qw(
		top-side top-left-corner top-right-corner
		bottom-side bottom-left-corner bottom-right-corner
		left-side right-side
	);

	for my $handle (@handles) {
		$self->items->{$item}{$handle}->lower;
	}
	return;
}

require Shutter::Draw::Utils;

sub _update_embedded {
	my ($self, $item_hash, $force_show) = @_;
	my $visibility = 'visible';

	#embedded ellipse
	if (exists $item_hash->{ellipse}) {

		$item_hash->{ellipse}->set(
			'center-x' => $item_hash->get('x') + $item_hash->get('width') / 2,
			'center-y' => $item_hash->get('y') + $item_hash->get('height') / 2,
		);
		$item_hash->{ellipse}->set(
			'radius-x'   => $item_hash->get('x') + $item_hash->get('width') - $item_hash->{ellipse}->get('center-x'),
			'radius-y'   => $item_hash->get('y') + $item_hash->get('height') - $item_hash->{ellipse}->get('center-y'),
			'visibility' => $visibility,
		);

		#numbered ellipse
		if (exists $item_hash->{text}) {
			$item_hash->{text}->set(
				'x'          => $item_hash->{ellipse}->get('center-x'),
				'y'          => $item_hash->{ellipse}->get('center-y'),
				'visibility' => $visibility,
			);
		}

	} elsif (exists $item_hash->{text}) {
		$item_hash->{text}->set(
			'x'          => $item_hash->get('x'),
			'y'          => $item_hash->get('y'),
			'width'      => $item_hash->get('width'),
			'visibility' => $visibility,
		);
	} elsif (exists $item_hash->{line}) {

		#handle possible arrows properly
		#arrow is always and end-arrow
		if ($item_hash->{mirrored_w} < 0 && $item_hash->{mirrored_h} < 0) {
			$item_hash->{line}->set(
				'points' => Shutter::Draw::Utils::points_to_canvas_points(
					$item_hash->get('x') + $item_hash->get('width'),
					$item_hash->get('y') + $item_hash->get('height'),
					$item_hash->get('x'),
					$item_hash->get('y')
				),
				'visibility' => $visibility
			);
		} elsif ($item_hash->{mirrored_w} < 0) {
			$item_hash->{line}->set(
				'points' => Shutter::Draw::Utils::points_to_canvas_points(
					$item_hash->get('x') + $item_hash->get('width'),
					$item_hash->get('y'),
					$item_hash->get('x'),
					$item_hash->get('y') + $item_hash->get('height')
				),
				'visibility' => $visibility
			);
		} elsif ($item_hash->{mirrored_h} < 0) {
			$item_hash->{line}->set(
				'points' => Shutter::Draw::Utils::points_to_canvas_points(
					$item_hash->get('x'),
					$item_hash->get('y') + $item_hash->get('height'),
					$item_hash->get('x') + $item_hash->get('width'),
					$item_hash->get('y')
				),
				'visibility' => $visibility
			);
		} else {
			$item_hash->{line}->set(
				'points' => Shutter::Draw::Utils::points_to_canvas_points(
					$item_hash->get('x'),
					$item_hash->get('y'),
					$item_hash->get('x') + $item_hash->get('width'),
					$item_hash->get('y') + $item_hash->get('height')
				),
				'visibility' => $visibility
			);
		}

	} elsif (exists $item_hash->{pixelize}) {

		if ($force_show) {
			$item_hash->{pixelize}->set('visibility' => $visibility,);
		} else {
			$item_hash->{pixelize}->set('visibility' => 'hidden',);
		}

	} elsif (exists $item_hash->{image}) {

		if ($item_hash->get('width') == $item_hash->{image}->get('width') && $item_hash->get('height') == $item_hash->{image}->get('height')) {

			$item_hash->{image}->set(
				'x'          => int $item_hash->get('x'),
				'y'          => int $item_hash->get('y'),
				'visibility' => $visibility,
			);

		} else {

			#be careful when resizing images
			#don't do anything when width or height are too small
			if ($item_hash->get('width') > 5 && $item_hash->get('height') > 5) {
				$item_hash->{image}->set(
					'x'          => int $item_hash->get('x'),
					'y'          => int $item_hash->get('y'),
					'width'      => $item_hash->get('width'),
					'height'     => $item_hash->get('height'),
					'pixbuf'     => $item_hash->{orig_pixbuf}->scale_simple($item_hash->get('width'), $item_hash->get('height'), 'nearest'),
					'visibility' => $visibility,
				);
			} else {
				$item_hash->{image}->set(
					'x'          => int $item_hash->get('x'),
					'y'          => int $item_hash->get('y'),
					'width'      => $item_hash->get('width'),
					'height'     => $item_hash->get('height'),
					'visibility' => $visibility,
				);
			}

		}

	}
	return;

}

sub _delete_embedded {
	my ($self, $item_hash) = @_;

	#ellipse
	if (exists $item_hash->{ellipse}) {
		if (my $nint = $self->canvas->get_root_item->find_child($item_hash->{ellipse})) {
			$self->canvas->get_root_item->remove_child($nint);
		}
	}

	#text
	if (exists $item_hash->{text}) {
		if (my $nint = $self->canvas->get_root_item->find_child($item_hash->{text})) {
			$self->canvas->get_root_item->remove_child($nint);
		}
	}

	#pixelize
	if (exists $item_hash->{pixelize}) {
		if (my $nint = $self->canvas->get_root_item->find_child($item_hash->{pixelize})) {
			$self->canvas->get_root_item->remove_child($nint);
		}
	}

	#image
	if (exists $item_hash->{image}) {
		if (my $nint = $self->canvas->get_root_item->find_child($item_hash->{image})) {
			$self->canvas->get_root_item->remove_child($nint);
		}
	}

	#line
	if (exists $item_hash->{line}) {
		if (my $nint = $self->canvas->get_root_item->find_child($item_hash->{line})) {
			$self->canvas->get_root_item->remove_child($nint);
		}
	}

	return;

}

sub _hide_embedded {
	my ($self, $item_hash) = @_;
	my $visibility = 'hidden';

	#ellipse => hide rectangle as well
	if (exists $item_hash->{ellipse}) {
		$item_hash->{ellipse}->set('visibility' => $visibility);
	}

	#text => hide rectangle as well
	if (exists $item_hash->{text}) {
		$item_hash->{text}->set('visibility' => $visibility);
	}

	#pixelize => hide rectangle as well
	if (exists $item_hash->{pixelize}) {
		$item_hash->{pixelize}->set('visibility' => $visibility);
	}

	#image => hide rectangle as well
	if (exists $item_hash->{image}) {
		$item_hash->{image}->set('visibility' => $visibility);
	}

	#line => hide rectangle as well
	if (exists $item_hash->{line}) {
		$item_hash->{line}->set('visibility' => $visibility);
	}

	return;

}

sub _mirror_line {
	my ($self, $item_hash, $new_width, $new_height) = @_;
	if (exists $item_hash->{line}) {

		#width
		if ($new_width < 0 && $item_hash->{mirrored_w} >= 0) {
			$item_hash->{mirrored_w} = $new_width;
		} elsif ($new_width < 0 && $item_hash->{mirrored_w} < 0) {
			$item_hash->{mirrored_w} = 0;
		}

		#height
		if ($new_height < 0 && $item_hash->{mirrored_h} >= 0) {
			$item_hash->{mirrored_h} = $new_height;
		} elsif ($new_height < 0 && $item_hash->{mirrored_h} < 0) {
			$item_hash->{mirrored_h} = 0;
		}
	}
	return;

}

1;

__END__

=head1 NAME

Shutter::Draw::CanvasOverlays - Manages resize handles and embedded items

=head1 DESCRIPTION

Handles creation, update, and deletion of resize handles and embedded child items
on the drawing canvas.
