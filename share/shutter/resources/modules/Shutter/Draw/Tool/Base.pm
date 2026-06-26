package Shutter::Draw::Tool::Base;

use Moo::Role;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has 'drawing_tool' => (is => 'ro', required => 1);
with 'Shutter::Draw::Tool::Role::Resizable';
with 'Shutter::Draw::Tool::Role::Movable';
with 'Shutter::Draw::Tool::Role::Selectable';
with 'Shutter::Draw::Tool::Role::HoverHighlight';
with 'Shutter::Draw::Tool::Role::Autoscroll';

sub on_motion_notify ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;

	$dt->adjust_rulers($ev, $item);

	#autoscroll if enabled
	#as does not work when using the censor tool -> deactivate it
	$self->_handle_autoscroll($item, $ev);

	#move
	if ($item->{dragging} && ($ev->state >= 'button1-mask' || $ev->state >= 'button2-mask')) {
		$self->handle_moving($item, $target, $ev) if $self->can('handle_moving');

		#freehand line
	} elsif ($self->can('on_drag_creation_points') && $ev->state >= 'button1-mask') {
		$self->on_drag_creation_points($dt->{_current_new_item} || $item, $target, $ev);

		#new item is already on the canvas with small initial size
		#drawing is like resizing, so set up for resizing
	} elsif ($self->can('on_drag_creation_shape') && $ev->state >= 'button1-mask' && !$item->{resizing}) {
		return FALSE unless $self->on_drag_creation_shape($dt->{_current_new_item} || $item, $target, $ev);
	} elsif ($item->{resizing} && $ev->state >= 'button1-mask') {
		$self->handle_resizing($item, $target, $ev) if $self->can('handle_resizing');

	} else {

		if ($item->isa('GooCanvas2::CanvasRect')) {

			#embedded item?
			my $parent = $dt->get_parent_item($item);
			$item = $parent if $parent;

			#shape or canvas background (resizeable rectangle)
			if (exists $dt->{_items}{$item} or $item == $dt->{_canvas_bg_rect}) {
				$dt->push_tool_help_to_statusbar(int($ev->x), int($ev->y));

				#canvas resizing shape
			} elsif ($dt->{_canvas_bg_rect}{'right-side'} == $item
				|| $dt->{_canvas_bg_rect}{'bottom-side'} == $item
				|| $dt->{_canvas_bg_rect}{'bottom-right-corner'} == $item)
			{
				$dt->push_tool_help_to_statusbar(int($ev->x), int($ev->y), 'canvas_resize');

				#resizing shape
			} else {

				$dt->push_tool_help_to_statusbar(int($ev->x), int($ev->y), 'resize');
			}
		} else {
			$dt->push_tool_help_to_statusbar(int($ev->x), int($ev->y));
		}

	}

	return TRUE;
}

sub on_key_press ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;

	if ($dt->{_current_item}) {

		#current item
		my $curr_item = $dt->{_current_item};

		if (exists $dt->{_items}{$curr_item}) {

			#construct an motion-notify event
			my $mevent = Gtk3::Gdk::Event->new('motion-notify');
			$mevent->state('button2-mask');
			$mevent->time(Gtk3::get_current_event_time());
			$mevent->window($dt->{_drawing_window}->get_window);

			#get current x, y values
			my $old_x = $dt->{_items}{$curr_item}->get('x');
			my $old_y = $dt->{_items}{$curr_item}->get('y');

			#set item flags
			$curr_item->{drag_x}         = $old_x;
			$curr_item->{drag_y}         = $old_y;
			$curr_item->{dragging}       = TRUE;
			$curr_item->{dragging_start} = TRUE;

			#move with arrow keys
			if ($ev->keyval == Gtk3::Gdk::keyval_from_name('Up')) {

				#~ print $ev->keyval," $old_x,$old_y-up\n";
				$mevent->x($old_x);
				$mevent->y($old_y - 1);
			} elsif ($ev->keyval == Gtk3::Gdk::keyval_from_name('Down')) {

				#~ print $ev->keyval," $old_x,$old_y-down\n";
				$mevent->x($old_x);
				$mevent->y($old_y + 1);
			} elsif ($ev->keyval == Gtk3::Gdk::keyval_from_name('Left')) {

				#~ print $ev->keyval," $old_x,$old_y-left\n";
				$mevent->x($old_x - 1);
				$mevent->y($old_y);
			} elsif ($ev->keyval == Gtk3::Gdk::keyval_from_name('Right')) {

				#~ print $ev->keyval," $old_x,$old_y-right\n";
				$mevent->x($old_x + 1);
				$mevent->y($old_y);
			} else {
				return FALSE;
			}

			#finally call motion-notify handler
			$self->on_motion_notify($curr_item, $target, $mevent);

		}

	}

	return TRUE;
}

sub on_button_press ($self, $item, $target, $ev, $select) {
	my $dt = $self->drawing_tool;

	#~ print "button-press\n";

	#canvas is busy now...
	$dt->{_busy} = TRUE;

	my $cursor = Gtk3::Gdk::Cursor->new('left-ptr');

	#activate item
	#if it is not activated yet
	# => single click
	if ($ev->type eq 'button-press' && ($dt->{_current_mode_descr} eq "select" || $select || $ev->button == 2 || $ev->button == 3)) {

		#embedded item?
		my $parent = $dt->get_parent_item($item);
		$item = $parent if $parent;

		#real shape
		if (exists $dt->{_items}{$item}) {

			unless (defined $dt->{_current_item} && $item == $dt->{_current_item}) {

				unless ($dt->{_current_mode_descr} eq "number" || $dt->{_current_mode_descr} eq "text") {

					unless ($dt->{_items}{$item}{locked}) {

						#deactivate last item
						my $last_item = $dt->{_current_item};
						if (defined $last_item) {

							#~ print "deactivated item: $last_item\n";
							$dt->{_canvas}->pointer_ungrab($last_item, $ev->time);
							$dt->{_canvas}->keyboard_ungrab($last_item, $ev->time);
							$dt->handle_rects('hide', $last_item);
						}

						#mark as active item
						$dt->{_current_item}     = $item;
						$dt->{_current_new_item} = undef;

						$dt->handle_rects('update', $dt->{_current_item});

						#apply item properties to widgets
						#line width, fill color, stroke color etc.
						$dt->set_and_save_drawing_properties($dt->{_current_item}, FALSE);

						#~ print "activated item: $item\n";

					} else {

						$dt->deactivate_all;

						#~ print "deactivate because $item is locked\n";

					}

				} else {

					$dt->deactivate_all($dt->{_current_item});

					#~ print "deactivate because $item is text or number\n";

				}

			} else {

				#~ print "no activate because $item is already current item\n";

			}

			#no item selected, deactivate all items
		} elsif ($item == $dt->{_canvas_bg_rect}) {

			$dt->deactivate_all;

			#~ print "deactivate because $item is background rectangle\n";

		} else {

			#~ print "no activate because $item does not exist\n";

		}
	} else {

		#~ print "no activate action\n";

	}

	#left mouse click to drag, resize, create or delelte items
	if ($ev->type eq 'button-press' && ($ev->button == 1 || $ev->button == 2)) {

		#MOVE
		if ($dt->{_current_mode_descr} eq "select" || $ev->button == 2) {

			#don't_move the bounding rectangle or the bg_image
			return TRUE if $item == $dt->{_canvas_bg_rect};

			#don't move locked item
			return TRUE if (exists $dt->{_items}{$item} && $dt->{_items}{$item}{locked});

			if ($item->isa('GooCanvas2::CanvasRect')) {

				#real shape => move
				if (exists $dt->{_items}{$item}) {
					$item->{drag_x}         = $ev->x;
					$item->{drag_y}         = $ev->y;
					$item->{dragging}       = TRUE;
					$item->{dragging_start} = TRUE;

					$cursor = Gtk3::Gdk::Cursor->new('fleur');

					#resizing shape => resize
				} else {
					$item->{res_x}    = $ev->x;
					$item->{res_y}    = $ev->y;
					$item->{resizing} = TRUE;

					$cursor = undef;

					#resizing the canvas_bg_rect
					if (   $dt->{_canvas_bg_rect}{'right-side'} == $item
						|| $dt->{_canvas_bg_rect}{'bottom-side'} == $item
						|| $dt->{_canvas_bg_rect}{'bottom-right-corner'} == $item)
					{

						#add to undo stack
						$dt->store_to_xdo_stack($dt->{_canvas_bg_rect}, 'modify', 'undo');

						#other resizing rectangles
					} else {

						#add to undo stack
						$dt->store_to_xdo_stack($dt->{_current_item}, 'modify', 'undo');

					}

					#restore style pattern
					$item->set('fill-color-gdk-rgba' => $dt->{_style_bg});

				}

				#no rectangle, e.g. polyline
			} else {

				#no rect, just move it ...
				$item->{drag_x}         = $ev->x;
				$item->{drag_y}         = $ev->y;
				$item->{dragging}       = TRUE;
				$item->{dragging_start} = TRUE;

				#add to undo stack
				#~ $dt->store_to_xdo_stack($dt->{_current_item} , 'modify', 'undo');

				$cursor = undef;

			}

			#~ print "grab keyboard and pointer focus for $item\n";

			#grab keyboard and pointer focus
			eval { $dt->{_canvas}->pointer_grab($item, ['pointer-motion-mask', 'button-release-mask'], $cursor, $ev->time); };
			if ($@) {

				# workaround for https://gitlab.gnome.org/GNOME/goocanvas/-/merge_requests/8
				$dt->{_canvas}->pointer_grab($item, ['pointer-motion-mask', 'button-release-mask'], Gtk3::Gdk::Cursor->new('left-ptr'), $ev->time);
			}
			$dt->{_canvas}->grab_focus($item);

			#current mode not equal 'select' and no polyline
		} elsif ($ev->button == 1) {

			#resizing shape => resize (no real shape)
			#no polyline modes
			if (   $item->isa('GooCanvas2::CanvasRect')
				&& !exists $dt->{_items}{$item}
				&& $item != $dt->{_canvas_bg_rect}
				&& $dt->{_current_mode_descr} ne "freehand"
				&& $dt->{_current_mode_descr} ne "highlighter"
				&& $dt->{_current_mode_descr} ne "censor")
			{

				$item->{res_x}    = $ev->x;
				$item->{res_y}    = $ev->y;
				$item->{resizing} = TRUE;

				$cursor = undef;

				#resizing the canvas_bg_rect
				if (   $dt->{_canvas_bg_rect}{'right-side'} == $item
					|| $dt->{_canvas_bg_rect}{'bottom-side'} == $item
					|| $dt->{_canvas_bg_rect}{'bottom-right-corner'} == $item)
				{

					#add to undo stack
					$dt->store_to_xdo_stack($dt->{_canvas_bg_rect}, 'modify', 'undo');

					#other resizing rectangles
				} else {

					#add to undo stack
					$dt->store_to_xdo_stack($dt->{_current_item}, 'modify', 'undo');

				}

				#restore style pattern
				$item->set('fill-color-gdk-rgba' => $dt->{_style_bg});

				#~ print "grab keyboard and pointer focus for $item\n";

				#grab keyboard and pointer focus
				$dt->acquire_focus($item, $ev, $cursor);

				#create new item
			} else {

				#freehand
				if ($self->can('on_click_creation')) {
					$self->on_click_creation($item, $target, $ev);
				}

				#grab keyboard focus
				if (my $nitem = $dt->{_current_new_item}) {
					$dt->handle_rects('update', $nitem);

					#~ print "grab keyboard focus for new item $nitem\n";
					$dt->{_canvas}->grab_focus($nitem);
				}

			}

		}

		#right click => show context menu, double-click => show properties directly
	} elsif ($ev->type eq '2button-press' || $ev->button == 3) {
		$self->handle_item_selection_events($item, $target, $ev) if $self->can('handle_item_selection_events');
	}

	return TRUE;
}

sub on_button_release ($self, $item, $target, $ev) {
	my $dt = $self->drawing_tool;

	$dt->release_focus($item, $ev);

	#canvas is idle now...
	$dt->{_busy} = FALSE;

	#we handle some minimum sizes here if the new items are too small
	#maybe the user just wanted to place an rect or an object on the canvas
	#and clicked on it without describing an rectangular area
	my $nitem = $dt->{_current_new_item};

	if ($nitem) {

		#apply item properties to widgets
		#line width, fill color, stroke color etc.
		$dt->set_and_save_drawing_properties($nitem, FALSE);

		#flag if item has to be deleted directly
		my $deleted = FALSE;

		#set minimum sizes
		if ($nitem->isa('GooCanvas2::CanvasRect')) {

			#real shape
			if (exists $dt->{_items}{$nitem}) {

				#images
				if (exists $dt->{_items}{$nitem}{image}) {

					$dt->{_items}{$nitem}->set(
						'x'      => $ev->x - int($dt->{_items}{$nitem}{orig_pixbuf}->get_width / 2),
						'y'      => $ev->y - int($dt->{_items}{$nitem}{orig_pixbuf}->get_height / 2),
						'width'  => $dt->{_items}{$nitem}{orig_pixbuf}->get_width,
						'height' => $dt->{_items}{$nitem}{orig_pixbuf}->get_height,
					);

					#texts
				} elsif (exists $dt->{_items}{$nitem}{text}) {

					if ($dt->{_items}{$nitem}{type} eq 'text') {

						#clear text
						$dt->{_items}{$nitem}{text}->set('text' => "<span font_desc='" . $dt->{_font} . "' ></span>");

						#adjust parent rectangle
						my $tb = $dt->{_items}{$nitem}{text}->get_bounds;

						$nitem->set(
							'x'      => $ev->x,
							'y'      => $ev->y - int(abs($tb->y1 - $tb->y2) / 2),
							'width'  => abs($tb->x1 - $tb->x2),
							'height' => abs($tb->y1 - $tb->y2),
						);

						#show property dialog directly
						Glib::Idle->add(
							sub {
								unless ($dt->show_item_properties($dt->{_items}{$nitem}{text}, $nitem, $nitem)) {
									if (my $nint = $dt->{_canvas}->get_root_item->find_child($nitem)) {

										#delete canvas objects
										$dt->{_canvas}->get_root_item->remove_child($nint);
										$dt->handle_rects('delete', $nitem);
										$dt->handle_embedded('delete', $nitem);

										#delete from hash
										delete $dt->{_items}{$nitem};

										#delete all xdo emtries for this object
										$dt->xdo_remove('undo', $nitem);
										$dt->xdo_remove('redo', $nitem);
										$dt->deactivate_all;
									}
								}
								return FALSE;
							});

					} elsif ($dt->{_items}{$nitem}{type} eq 'number') {

						$dt->{_items}{$nitem}->set(
							'x'      => $ev->x - int($dt->{_items}{$nitem}->get('width') / 2),
							'y'      => $ev->y - int($dt->{_items}{$nitem}->get('height') / 2),
							'width'  => $dt->{_items}{$nitem}->get('width'),
							'height' => $dt->{_items}{$nitem}->get('height'),
						);

					}

					#all other objects
				} else {

					#delete
					if (my $nint = $dt->{_canvas}->get_root_item->find_child($nitem)) {

						#delete from canvas
						$dt->{_canvas}->get_root_item->remove_child($nint);

						#mark as deleted
						$deleted = TRUE;

						#~ print "item $nitem marked as deleted at ",$ev->x,", ",$ev->y,"\n";

					}

				}

				#~ print "new item created: $item\n";

			}

		}

		if ($deleted) {

			#delete child objects and resizing rectangles
			$dt->handle_rects('delete', $nitem);
			$dt->handle_embedded('delete', $nitem);

			#delete from hash
			delete $dt->{_items}{$nitem};

			#~ print "item $nitem deleted at ",$ev->x,", ",$ev->y,"\n";

			#deactivate all
			$dt->deactivate_all;

			if (my $oitem = $dt->{_canvas}->get_item_at($ev->x_root, $ev->y_root, TRUE)) {

				#~ print "item $oitem found at ",$ev->x,", ",$ev->y,"\n";

				#turn into a button-press-event
				my $initevent = Gtk3::Gdk::Event->new('button-press');
				$initevent->time(Gtk3::get_current_event_time());
				$initevent->window($dt->{_drawing_window}->get_window);
				$initevent->x($ev->x);
				$initevent->y($ev->y);
				$self->on_button_press($oitem, undef, $initevent, TRUE);
				$self->on_button_release($oitem, undef, $initevent);

				return FALSE;

			}
		} else {

			$dt->deactivate_all($nitem);

			#mark as active item
			$dt->{_current_item} = $nitem;

			$dt->handle_rects('update', $nitem);
			$dt->handle_embedded('update', $nitem);

			#add to undo stack
			$dt->store_to_xdo_stack($nitem, 'create', 'undo');

		}

		#no new item
		#existing item selected
	} else {

		#cleanup
		#it may happen that items are created
		#but resize mode is not activated immediately
		#those items would not be visible on the canvas
		#we delete them  here
		my $citem = $dt->{_current_item};
		if ($citem && $citem->isa('GooCanvas2::CanvasRect')) {
			if (exists $dt->{_items}{$citem}) {
				if ($dt->{_items}{$citem}->get('visibility') eq 'hidden') {
					if (my $nint = $dt->{_canvas}->get_root_item->find_child($citem)) {

						$dt->xdo('undo', undef, TRUE);

						#delete from canvas
						$dt->{_canvas}->get_root_item->remove_child($nint);

						#delete child objects and resizing rectangles
						$dt->handle_rects('delete', $citem);
						$dt->handle_embedded('delete', $citem);

						#delete from hash
						delete $dt->{_items}{$citem};

					}
				}
			}

		}

		#apply item properties to widgets
		#line width, fill color, stroke color etc.
		$dt->set_and_save_drawing_properties($citem, FALSE);
	}

	#uncheck previous active item
	$dt->{_current_new_item} = undef;

	#unset action flags
	$item->{dragging}       = FALSE if exists $item->{dragging};
	$item->{dragging_start} = FALSE if exists $item->{dragging_start};
	$item->{resizing}       = FALSE if exists $item->{resizing};

	#because of performance reason we load the current image new from file when
	#the current action is over => button-release
	#when resizing or moving the image we just scale the current image with low quality settings
	#see handle_embedded
	my $child = $dt->get_child_item($dt->{_current_item});

	if ($child && $child->isa('GooCanvas2::CanvasImage')) {
		my $parent = $dt->get_parent_item($child);

		if (exists $dt->{_items}{$parent}{pixelize}) {

			$dt->{_items}{$parent}{pixelize}->set(
				'x'      => int $dt->{_items}{$parent}->get('x'),
				'y'      => int $dt->{_items}{$parent}->get('y'),
				'width'  => $dt->{_items}{$parent}->get('width'),
				'height' => $dt->{_items}{$parent}->get('height'),
				'pixbuf' => $dt->get_pixelated_pixbuf_from_canvas($dt->{_items}{$parent}),
			);

			$dt->handle_embedded('update', $parent, undef, undef, TRUE);

		} else {

			my $copy = $dt->{_lp}->load($dt->{_items}{$parent}{orig_pixbuf_filename}, $dt->{_items}{$parent}->get('width'), $dt->{_items}{$parent}->get('height'), FALSE, TRUE);
			if ($copy) {
				$dt->{_items}{$parent}{image}->set(
					'x'      => int $dt->{_items}{$parent}->get('x'),
					'y'      => int $dt->{_items}{$parent}->get('y'),
					'width'  => $dt->{_items}{$parent}->get('width'),
					'height' => $dt->{_items}{$parent}->get('height'),
					'pixbuf' => $copy,
				);

				$dt->handle_embedded('update', $parent, undef, undef, TRUE);

			} else {

				#Try to load it with default width and height (Bug #975247)
				$dt->{_items}{$parent}->set(
					'x'      => $ev->x - int($dt->{_items}{$parent}{orig_pixbuf}->get_width / 2),
					'y'      => $ev->y - int($dt->{_items}{$parent}{orig_pixbuf}->get_height / 2),
					'width'  => $dt->{_items}{$parent}{orig_pixbuf}->get_width,
					'height' => $dt->{_items}{$parent}{orig_pixbuf}->get_height,
				);

				#mark as active item
				$dt->{_current_item} = $parent;

				$dt->handle_rects('update', $parent);
				$dt->handle_embedded('update', $parent, undef, undef, TRUE);

				#~ $dt->abort_current_mode;
			}

		}

	}

	$dt->set_drawing_action(int($dt->{_current_mode} / 10));

	return TRUE;
}

1;
