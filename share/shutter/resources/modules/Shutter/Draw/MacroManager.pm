package Shutter::Draw::MacroManager;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

sub store_to_xdo_stack ($mgr, $item, $action, $xdo, $opt1, $source) {

	#opt1 is currently only used when cropping the image
	#it stores the selection
	my $self = $mgr->drawing_tool;

	return FALSE unless $item;

	#~ print "xdo - $item\n";

	my %do_info = ();

	#general properties for ellipse, rectangle, image, text
	if ($item->isa('GooCanvas2::CanvasRect') && $item != $self->{_canvas_bg_rect}) {

		my $stroke_color = $self->{_items}{$item}{stroke_color};
		my $fill_color   = $self->{_items}{$item}{fill_color};
		my $line_width     = $self->{_items}{$item}->get('line-width');

		#line
		my $mirrored_w   = undef;
		my $mirrored_h   = undef;
		my $end_arrow    = undef;
		my $start_arrow  = undef;
		my $arrow_width  = undef;
		my $arrow_length = undef;
		my $tip_length   = undef;

		#text
		my $text = undef;

		#numbered ellipse
		my $digit = undef;

		if (exists $self->{_items}{$item}{ellipse}) {

			$line_width = $self->{_items}{$item}{ellipse}->get('line-width');

			#numbered ellipse
			if (exists $self->{_items}{$item}{text}) {
				$text  = $self->{_items}{$item}{text}->get('text');
				$digit = $self->{_items}{$item}{text}{digit};
			}

		} elsif (exists $self->{_items}{$item}{text}) {

			$text = $self->{_items}{$item}{text}->get('text');

		} elsif (exists $self->{_items}{$item}{image}) {

		} elsif (exists $self->{_items}{$item}{line}) {

			#line width
			$line_width = $self->{_items}{$item}{line}->get('line-width');

			#arrow properties
			$end_arrow    = $self->{_items}{$item}{line}->get('end-arrow');
			$start_arrow  = $self->{_items}{$item}{line}->get('start-arrow');
			$arrow_width  = $self->{_items}{$item}{line}->get('arrow-width');
			$arrow_length = $self->{_items}{$item}{line}->get('arrow-length');
			$tip_length   = $self->{_items}{$item}{line}->get('arrow-tip-length');

			#mirror flag
			$mirrored_w = $self->{_items}{$item}{mirrored_w};
			$mirrored_h = $self->{_items}{$item}{mirrored_h};

		}

		#item props
		%do_info = (
			'item'               => $self->{_items}{$item},
			'action'             => $action,
			'x'                  => $self->{_items}{$item}->get('x'),
			'y'                  => $self->{_items}{$item}->get('y'),
			'width'              => $self->{_items}{$item}->get('width'),
			'height'             => $self->{_items}{$item}->get('height'),
			'stroke_color'       => $self->{_items}{$item}{stroke_color},
			'fill_color'         => $self->{_items}{$item}{fill_color},
			'line-width'         => $line_width,
			'mirrored_w'         => $mirrored_w,
			'mirrored_h'         => $mirrored_h,
			'end-arrow'          => $end_arrow,
			'start-arrow'        => $start_arrow,
			'arrow-length'       => $arrow_length,
			'arrow-width'        => $arrow_width,
			'arrow-tip-length'   => $tip_length,
			'text'               => $text,
			'digit'              => $digit,
			'opt1'               => $opt1,
		);

	} elsif ($item->isa('GooCanvas2::CanvasImage') && $item == $self->{_canvas_bg}) {

		#canvas_bg_image and bg_rect properties
		%do_info = (
			'item'           => $self->{_canvas_bg},
			'action'         => $action,
			'drawing_pixbuf' => $self->{_drawing_pixbuf},
			'x'              => $self->{_canvas_bg_rect}->get('x'),
			'y'              => $self->{_canvas_bg_rect}->get('y'),
			'width'          => $self->{_canvas_bg_rect}->get('width'),
			'height'         => $self->{_canvas_bg_rect}->get('height'),
			'opt1'           => $opt1,
		);

	} elsif ($item->isa('GooCanvas2::CanvasRect') && $item == $self->{_canvas_bg_rect}) {

		#canvas_bg_rect properties
		%do_info = (
			'item'   => $self->{_canvas_bg_rect},
			'action' => $action,
			'x'      => $self->{_canvas_bg_rect}->get('x'),
			'y'      => $self->{_canvas_bg_rect}->get('y'),
			'width'  => $self->{_canvas_bg_rect}->get('width'),
			'height' => $self->{_canvas_bg_rect}->get('height'),
			'opt1'   => $opt1,
		);

		#polyline specific properties to hash
	} elsif ($item->isa('GooCanvas2::CanvasPolyline')) {

		my $transform      = $self->{_items}{$item}->get('transform');
		my $line_width     = $self->{_items}{$item}->get('line-width');
		my $points         = $self->{_items}{$item}->get('points');

		%do_info = (
			'item'           => $self->{_items}{$item},
			'action'         => $action,
			'points'         => $points,
			'stroke_color'   => $self->{_items}{$item}{stroke_color},
			'line-width'     => $line_width,
			'transform'      => $transform,
			'opt1'           => $opt1,
		);

	}

	#reset redo
	if (defined $source && $source eq 'ui') {

		#~ print "no clear\n";
	} else {
		while (defined $self->{_redo} && scalar @{$self->{_redo}} > 0) {
			shift @{$self->{_redo}};
		}
	}

	if ($xdo eq 'undo') {
		push @{$self->{_undo}}, \%do_info;
	} elsif ($xdo eq 'redo') {
		push @{$self->{_redo}}, \%do_info;
	}

	#disable undo/redo actions
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Undo")->set_sensitive(scalar @{$self->{_undo}}) if defined $self->{_undo};
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Redo")->set_sensitive(scalar @{$self->{_redo}}) if defined $self->{_redo};

	$self->{_uimanager}->get_widget("/ToolBar/Undo")->set_sensitive(scalar @{$self->{_undo}}) if defined $self->{_undo};
	$self->{_uimanager}->get_widget("/ToolBar/Redo")->set_sensitive(scalar @{$self->{_redo}}) if defined $self->{_redo};

	return TRUE;
}


sub xdo_remove ($mgr) {
	my $self = $mgr->drawing_tool;
	my $xdo  = shift;
	my $item = shift;

	my @indices;
	my $counter = 0;
	if ($xdo eq 'undo') {
		foreach my $do (@{$self->{_undo}}) {
			push @indices, $counter if $item == $do->{'item'};
			$counter++;
		}

		#delete from array
		foreach my $index (@indices) {
			splice(@{$self->{_undo}}, $index, 1);
		}
	} elsif ($xdo eq 'redo') {
		foreach my $do (@{$self->{_redo}}) {
			push @indices, $counter if $item == $do->{'item'};
			$counter++;
		}

		#delete from array
		foreach my $index (@indices) {
			splice(@{$self->{_redo}}, $index, 1);
		}
	}

	#disable undo/redo actions
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Undo")->set_sensitive(scalar @{$self->{_undo}}) if defined $self->{_undo};
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Redo")->set_sensitive(scalar @{$self->{_redo}}) if defined $self->{_redo};

	$self->{_uimanager}->get_widget("/ToolBar/Undo")->set_sensitive(scalar @{$self->{_undo}}) if defined $self->{_undo};
	$self->{_uimanager}->get_widget("/ToolBar/Redo")->set_sensitive(scalar @{$self->{_redo}}) if defined $self->{_redo};

	return TRUE;
}


sub xdo ($mgr) {
	my $self = $mgr->drawing_tool;
	my $xdo           = shift;
	my $source        = shift;
	my $block_reverse = shift;

	my $do = undef;
	if ($xdo eq 'undo') {
		$do = pop @{$self->{_undo}};
	} elsif ($xdo eq 'redo') {
		$do = pop @{$self->{_redo}};
	}

	my $item   = $do->{'item'};
	my $action = $do->{'action'};
	my $opt1   = $do->{'opt1'};

	return FALSE unless $item;
	return FALSE unless $action;

	if ($item->isa('GooCanvas2::CanvasImage') && $item == $self->{_canvas_bg}) {
		$opt1->{x} = $do->{'opt1'}->{x} * -1;
		$opt1->{y} = $do->{'opt1'}->{y} * -1;
	}

	#create reverse action
	my $reverse_action = 'modify';
	if ($action eq 'raise') {
		$reverse_action = 'lower_xdo';
	} elsif ($action eq 'raise_xdo') {
		$reverse_action = 'lower_xdo';
	} elsif ($action eq 'lower') {
		$reverse_action = 'raise_xdo';
	} elsif ($action eq 'lower_xdo') {
		$reverse_action = 'raise_xdo';
	} elsif ($action eq 'create') {
		$reverse_action = 'delete_xdo';
	} elsif ($action eq 'delete') {
		$reverse_action = 'create_xdo';
	} elsif ($action eq 'create_xdo') {
		$reverse_action = 'delete_xdo';
	} elsif ($action eq 'delete_xdo') {
		$reverse_action = 'create_xdo';
	}

	#undo or redo?
	unless ($block_reverse) {
		if ($xdo eq 'undo') {

			#store to redo stack
			$self->store_to_xdo_stack($item, $reverse_action, 'redo', $opt1, $source);
		} elsif ($xdo eq 'redo') {

			#store to undo stack
			$self->store_to_xdo_stack($item, $reverse_action, 'undo', $opt1, $source);
		}
	}

	#finally undo the last event
	if ($action eq 'modify') {

		if ($item->isa('GooCanvas2::CanvasRect') && $item != $self->{_canvas_bg_rect}) {

			$self->{_items}{$item}->set(
				'x'      => $do->{'x'},
				'y'      => $do->{'y'},
				'width'  => $do->{'width'},
				'height' => $do->{'height'},
			);

			if (exists $self->{_items}{$item}{ellipse}) {

				$self->{_items}{$item}{ellipse}->set(
					'fill-color-gdk-rgba'   => $do->{'fill_color'},
					'stroke-color-gdk-rgba' => $do->{'stroke_color'},
					'line-width'     => $do->{'line-width'},
				);

				#numbered ellipse
				if (exists $self->{_items}{$item}{text}) {
					$self->{_items}{$item}{text}->set(
						'text'         => $do->{'text'},
						'fill-color-gdk-rgba' => $do->{'stroke_color'},
					);
					$self->{_items}{$item}{text}{digit} = $do->{'digit'};
				}

				#restore color and opacity as well
				$self->{_items}{$item}{fill_color}         = $do->{'fill_color'};
				$self->{_items}{$item}{stroke_color}       = $do->{'stroke_color'};

			} elsif (exists $self->{_items}{$item}{text}) {

				$self->{_items}{$item}{text}->set(
					'text'         => $do->{'text'},
					'fill-color-gdk-rgba' => $do->{'stroke_color'},
				);

				#restore color and opacity as well
				$self->{_items}{$item}{stroke_color}       = $do->{'stroke_color'};

			} elsif (exists $self->{_items}{$item}{pixelize}) {

				$self->{_items}{$item}{pixelize}->set(
					'x'      => int $self->{_items}{$item}->get('x'),
					'y'      => int $self->{_items}{$item}->get('y'),
					'width'  => $self->{_items}{$item}->get('width'),
					'height' => $self->{_items}{$item}->get('height'),
					'pixbuf' => $self->get_pixelated_pixbuf_from_canvas($self->{_items}{$item}),
				);

			} elsif (exists $self->{_items}{$item}{image}) {

				#~ print "xdo image\n";

				my $copy = $self->{_lp}->load($self->{_items}{$item}{orig_pixbuf_filename}, $self->{_items}{$item}->get('width'), $self->{_items}{$item}->get('height'), FALSE, TRUE);
				if ($copy) {
					$self->{_items}{$item}{image}->set(
						'x'      => int $self->{_items}{$item}->get('x'),
						'y'      => int $self->{_items}{$item}->get('y'),
						'width'  => $self->{_items}{$item}->get('width'),
						'height' => $self->{_items}{$item}->get('height'),
						'pixbuf' => $copy
					);
				}

			} elsif (exists $self->{_items}{$item}{line}) {

				#save arrow specific properties
				$self->{_items}{$item}{end_arrow}        = $do->{'end-arrow'};
				$self->{_items}{$item}{start_arrow}      = $do->{'start-arrow'};
				$self->{_items}{$item}{arrow_width}      = $do->{'arrow-width'};
				$self->{_items}{$item}{arrow_length}     = $do->{'arrow-length'};
				$self->{_items}{$item}{arrow_tip_length} = $do->{'arrow-tip-length'};

				$self->{_items}{$item}{line}->set(
					'fill-color-gdk-rgba'   => $do->{'fill_color'},
					'stroke-color-gdk-rgba' => $do->{'stroke_color'},
					'line-width'       => $do->{'line-width'},
					'end-arrow'        => $self->{_items}{$item}{end_arrow},
					'start-arrow'      => $self->{_items}{$item}{start_arrow},
					'arrow-length'     => $self->{_items}{$item}{arrow_length},
					'arrow-width'      => $self->{_items}{$item}{arrow_width},
					'arrow-tip-length' => $self->{_items}{$item}{arrow_tip_length},
				);

				$self->{_items}{$item}{mirrored_w} = $do->{'mirrored_w'} if exists $do->{'mirrored_w'};
				$self->{_items}{$item}{mirrored_h} = $do->{'mirrored_h'} if exists $do->{'mirrored_h'};

				#restore color and opacity as well
				$self->{_items}{$item}{stroke_color}       = $do->{'stroke_color'};

			} else {

				$self->{_items}{$item}->set(
					'fill-color-gdk-rgba'   => $do->{'fill_color'},
					'stroke-color-gdk-rgba' => $do->{'stroke_color'},
					'line-width'     => $do->{'line-width'},
				);

				#restore color and opacity as well
				$self->{_items}{$item}{fill_color}         = $do->{'fill_color'};
				$self->{_items}{$item}{stroke_color}       = $do->{'stroke_color'};

			}

		} elsif ($item->isa('GooCanvas2::CanvasImage') && $item == $self->{_canvas_bg}) {

			#~ print "xdo canvas_bg\n";

			my $new_w = $do->{'drawing_pixbuf'}->get_width;
			my $new_h = $do->{'drawing_pixbuf'}->get_height;

			#update canvas and show the new pixbuf
			$self->{_canvas_bg}->set('pixbuf' => $do->{'drawing_pixbuf'});

			#save new pixbuf in var
			$self->{_drawing_pixbuf} = $do->{'drawing_pixbuf'}->copy;

			#update bounds and bg_rects
			$self->{_canvas_bg_rect}->set(
				'x'      => $do->{'x'},
				'y'      => $do->{'y'},
				'width'  => $do->{'width'},
				'height' => $do->{'height'},
			);

			#we need to move the shapes
			$self->move_all($opt1->{x}, $opt1->{y});

		} elsif ($item->isa('GooCanvas2::CanvasRect') && $item == $self->{_canvas_bg_rect}) {

			#~ print "xdo canvas_bg_rect\n";

			$self->{_canvas_bg_rect}->set(
				'x'      => $do->{'x'},
				'y'      => $do->{'y'},
				'width'  => $do->{'width'},
				'height' => $do->{'height'},
			);

			#polyline specific properties
		} elsif ($item->isa('GooCanvas2::CanvasPolyline')) {

			#if pattern exists
			#e.g. censor tool does not have a pattern
			if ($do->{'stroke-pattern'}) {

				$self->{_items}{$item}->set(
					'stroke-color-gdk-rgba' => $do->{'stroke_color'},
					'line-width'     => $do->{'line-width'},
					'points'         => $do->{'points'},
					'transform'      => $do->{'transform'},
				);

				$self->{_items}{$item}{stroke_color}       = $do->{'stroke_color'};

			} else {

				$self->{_items}{$item}->set(
					'line-width' => $do->{'line-width'},
					'points'     => $do->{'points'},
					'transform'  => $do->{'transform'},
				);
			}

		}

		#handle resize rectangles and embedded objects
		if ($item == $self->{_canvas_bg}) {

			$self->handle_bg_rects('update', $self->{_canvas_bg_rect});

		} elsif ($item == $self->{_canvas_bg_rect}) {

			$self->handle_bg_rects('update', $self->{_canvas_bg_rect});

		} else {

			$self->handle_rects('update', $self->{_items}{$item});
			$self->handle_embedded('update', $self->{_items}{$item}, undef, undef, TRUE);

			#apply item properties to widgets
			#line width, fill color, stroke color etc.
			$self->set_and_save_drawing_properties($self->{_current_item}, FALSE);

		}

		#adjust stack order
		$self->{_canvas_bg}->lower;
		$self->{_canvas_bg_rect}->lower;
		$self->handle_bg_rects('raise');

	} elsif ($action eq 'raise' || $action eq 'raise_xdo') {

		my $child = $self->get_child_item($item);
		if ($child) {
			$self->handle_rects('lower', $item);
			$child->lower;
			$item->lower;
		} else {
			$self->handle_rects('lower', $item);
			$item->lower;
		}
		$self->{_canvas_bg}->lower;
		$self->{_canvas_bg_rect}->lower;

	} elsif ($action eq 'lower' || $action eq 'lower_xdo') {

		my $child = $self->get_child_item($item);
		if ($child) {
			$child->raise;
			$item->raise;
			$self->handle_rects('raise', $item);
		} else {
			$item->raise;
			$self->handle_rects('raise', $item);
		}

	} elsif ($action eq 'delete' || $action eq 'delete_xdo') {

		#mark as current
		$self->{_current_item}     = $item;
		$self->{_current_new_item} = undef;

		$self->{_items}{$item}->set('visibility' => 'visible');
		$self->handle_rects('update', $self->{_items}{$item});
		$self->handle_embedded('update', $self->{_items}{$item}, undef, undef, TRUE);

	} elsif ($action eq 'create' || $action eq 'create_xdo') {

		$self->{_items}{$item}->set('visibility' => 'hidden');
		$self->handle_rects('hide', $self->{_items}{$item});
		$self->handle_embedded('hide', $self->{_items}{$item});

	}

	#disable undo/redo actions
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Undo")->set_sensitive(scalar @{$self->{_undo}}) if defined $self->{_undo};
	$self->{_uimanager}->get_widget("/MenuBar/Edit/Redo")->set_sensitive(scalar @{$self->{_redo}}) if defined $self->{_redo};

	$self->{_uimanager}->get_widget("/ToolBar/Undo")->set_sensitive(scalar @{$self->{_undo}}) if defined $self->{_undo};
	$self->{_uimanager}->get_widget("/ToolBar/Redo")->set_sensitive(scalar @{$self->{_redo}}) if defined $self->{_redo};

	$self->deactivate_all;

	return TRUE;
}



1;
