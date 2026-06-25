package Shutter::Draw::LegacyDelegators;

use v5.40;
use feature "try";
no warnings "experimental::try";
no warnings "experimental::args_array_with_signatures";

use Glib qw(TRUE FALSE);

sub load_settings {
	my $self = shift;
	return $self->{_settings_manager}->load_settings(@_);
}

sub save_settings {
	my $self = shift;
	return $self->{_settings_manager}->save_settings(@_);
}

sub import_from_dnd {
	my $self = shift;
	return $self->{_io_manager}->import_from_dnd(@_);
}

sub import_from_filesystem {
	my $self = shift;
	return $self->{_io_manager}->import_from_filesystem(@_);
}

sub import_from_utheme {
	my $self = shift;
	return $self->{_io_manager}->import_from_utheme(@_);
}

sub import_from_utheme_ctxt {
	my $self = shift;
	return $self->{_io_manager}->import_from_utheme_ctxt(@_);
}

sub import_from_session {
	my $self = shift;
	return $self->{_io_manager}->import_from_session(@_);
}

sub get_pixelated_pixbuf_from_canvas {
	my $self = shift;
	return $self->{_item_factory}->get_pixelated_pixbuf_from_canvas(@_);
}

sub export_to_file {
	my $self = shift;
	return $self->{_io_manager}->export_to_file(@_);
}

sub export_to_svg {
	my $self = shift;
	return $self->{_io_manager}->export_to_svg(@_);
}

sub export_to_ps {
	my $self = shift;
	return $self->{_io_manager}->export_to_ps(@_);
}

sub export_to_pdf {
	my $self = shift;
	return $self->{_io_manager}->export_to_pdf(@_);
}

sub save {
	my $self = shift;
	return $self->{_io_manager}->save(@_);
}

sub setup_item_signals {
	my ($self, $item) = @_;
	$item->signal_connect(
		'motion_notify_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_motion_notify($item, $target, $ev);
		});
	$item->signal_connect(
		'key_press_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_key_press($item, $target, $ev);
		});
	$item->signal_connect(
		'button_press_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_button_press($item, $target, $ev);
		});
	$item->signal_connect(
		'button_release_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_button_release($item, $target, $ev);
		});

	return TRUE;
}

sub setup_item_signals_extra {
	my ($self, $item) = @_;
	$item->signal_connect(
		'enter_notify_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_enter_notify($item, $target, $ev);
		});

	$item->signal_connect(
		'leave_notify_event',
		sub {
			my ($item, $target, $ev) = @_;
			$self->event_item_on_leave_notify($item, $target, $ev);
		});

	return TRUE;
}

sub event_item_on_motion_notify {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_motion_notify(@_);
}

sub get_opposite_rect {
	my $self = shift;
	return $self->{_item_factory}->get_opposite_rect(@_);
}

sub get_parent_item {
	my $self = shift;
	return $self->{_item_factory}->get_parent_item(@_);
}

sub get_highest_auto_digit {
	my $self = shift;
	return $self->{_item_factory}->get_highest_auto_digit(@_);
}

sub get_child_item {
	my $self = shift;
	return $self->{_item_factory}->get_child_item(@_);
}

sub abort_current_mode {
	my $self = shift;
	if ($self->{_current_item}) {
		$self->{_canvas}->pointer_ungrab($self->{_current_item}, Gtk3::get_current_event_time());
		$self->{_canvas}->keyboard_ungrab($self->{_current_item}, Gtk3::get_current_event_time());
	}

	#~ print "abort_current_mode\n";

	$self->set_drawing_action(1);

	return TRUE;
}

sub clear_item_from_canvas {
	my ($self, $item) = @_;

	#~ print "clear_item_from_canvas\n";
	$self->{_current_item}     = undef;
	$self->{_current_new_item} = undef;

	if ($item) {

		#maybe there is a parent item to delete?
		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		#get child
		my $child = $self->get_child_item($item);

		#only delete if not already deleted (hidden)
		return FALSE if ($child && $child->get('visibility') eq 'hidden');

		#~ print "1st passed\n";
		return FALSE if (!$child && $item->get('visibility') eq 'hidden');

		#~ print "2nd passed\n";

		$self->store_to_xdo_stack($item, 'delete', 'undo');
		$item->set('visibility' => 'hidden');
		$self->handle_rects('hide', $item);
		$self->handle_embedded('hide', $item);

	}

	return TRUE;
}

sub store_to_xdo_stack {
	my $self = shift;
	return $self->{_macro_manager}->store_to_xdo_stack(@_);
}

sub xdo_remove {
	my $self = shift;
	return $self->{_macro_manager}->xdo_remove(@_);
}

sub xdo {
	my $self = shift;
	return $self->{_macro_manager}->xdo(@_);
}

sub set_and_save_drawing_properties {
	my $self = shift;
	return $self->{_settings_manager}->set_and_save_drawing_properties(@_);
}

sub restore_fixed_properties {
	my $self = shift;
	return $self->{_settings_manager}->restore_fixed_properties(@_);
}

sub restore_drawing_properties {
	my $self = shift;
	return $self->{_settings_manager}->restore_drawing_properties(@_);
}

sub event_item_on_key_press {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_key_press(@_);
}

sub event_item_on_button_press {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_button_press(@_);
}

sub ret_background_menu {
	my $self = shift;
	return $self->{_context_menu_manager}->ret_background_menu(@_);
}

sub ret_item_menu {
	my $self = shift;
	return $self->{_context_menu_manager}->ret_item_menu(@_);
}

sub show_item_properties {
	my $self = shift;
	return $self->{_property_manager}->show_item_properties(@_);
}

sub apply_properties {
	my $self = shift;
	return $self->{_property_manager}->apply_properties(@_);
}

sub modify_text_in_properties {
	my $self = shift;
	return $self->{_property_manager}->modify_text_in_properties(@_);
}

sub move_all {
	my ($self, $x, $y) = @_;
	foreach (keys %{$self->{_items}}) {

		my $item = $self->{_items}{$_};

		#embedded item?
		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		#real shape
		if (exists $self->{_items}{$item}) {

			if ($item->isa('GooCanvas2::CanvasRect')) {

				$item->set(
					'x' => $item->get('x') - $x,
					'y' => $item->get('y') - $y,
				);

				my $child = $self->get_child_item($item);
				$child = $item unless $child;

				#it item is hidden, keep the status
				if ($child->get('visibility') eq 'hidden') {
					$self->handle_rects('hide', $item);
					$self->handle_embedded('hide', $item);
				} else {
					$self->handle_rects('update', $item);

					#pixelizer is treated differently
					if ($child && $child->isa('GooCanvas2::CanvasImage')) {
						my $parent = $self->get_parent_item($child);

						if (exists $self->{_items}{$parent}{pixelize}) {

							Glib::Idle->add(
								sub {
									$self->{_items}{$parent}{pixelize}->set(
										'x'      => int $self->{_items}{$parent}->get('x'),
										'y'      => int $self->{_items}{$parent}->get('y'),
										'width'  => $self->{_items}{$parent}->get('width'),
										'height' => $self->{_items}{$parent}->get('height'),
										'pixbuf' => $self->get_pixelated_pixbuf_from_canvas($self->{_items}{$parent}),
									);

									$self->handle_embedded('update', $parent, undef, undef, TRUE);

									#deactivate all after move
									$self->deactivate_all;

									return FALSE;
								});

						} else {

							$self->handle_embedded('update', $item);

						}

					} else {

						$self->handle_embedded('update', $item);

					}
				}

				#freehand line for example
			} else {

				$item->translate(-$x, -$y);

			}

		}
	}

	#deactivate all after move
	$self->deactivate_all;

	return TRUE;
}

sub deactivate_all {
	my $self = shift;
	my $exclude = shift || 0;

	#~ print "deactivate_all\n";

	foreach (keys %{$self->{_items}}) {

		my $item = $self->{_items}{$_};

		next if $item == $exclude;

		#embedded item?
		my $parent = $self->get_parent_item($item);
		$item = $parent if $parent;

		#real shape
		if (exists $self->{_items}{$item}) {
			$self->handle_rects('hide', $item);
		}

	}

	$self->{_current_item}     = undef;
	$self->{_current_new_item} = undef;

	return TRUE;
}

sub handle_embedded {
	my $self = shift;
	return $self->{_canvas_overlays}->handle_embedded(@_);
}

sub handle_bg_rects {
	my ($self, $action, $bg_rect) = @_;
	$bg_rect //= $self->{_canvas_bg_rect};
	return $self->{_canvas_overlays}->handle_bg_rects($action, $bg_rect);
}

sub handle_rects {
	my $self = shift;
	return $self->{_canvas_overlays}->handle_item_handles(@_);
}

sub event_item_on_button_release {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_button_release(@_);
}

sub event_item_on_enter_notify {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_enter_notify(@_);
}

sub event_item_on_leave_notify {
	my $self = shift;
	return $self->{_mouse_manager}->event_item_on_leave_notify(@_);
}

sub gen_thumbnail_on_idle {
	my ($self, $stock, $parent, $button, $no_init) = @_;
	my @menu_items = @_;

	my $shutter_hfunct = Shutter::App::HelperFunctions->new($self->{_sc});

	#generate thumbnails in an idle callback
	my $next_item = 0;
	Glib::Idle->add(
		sub {

			#get next item
			my $child = $menu_items[$next_item];

			#no valid item - stop the idle handler
			unless ($child) {
				$parent->set_image(Gtk3::Image->new_from_stock($stock, 'menu')) if $parent;
				return FALSE;
			}

			my $name = $child->{'name'};

			#no valid item - stop the idle handler
			unless ($name) {
				$parent->set_image(Gtk3::Image->new_from_stock($stock, 'menu')) if $parent;
				return FALSE;
			}

			#increment counter
			$next_item++;

			#create thumbnail
			my $small_image;
			eval {

				#if uri exists we generate a thumbnail
				#with Shutter::Pixbuf::Thumbnail
				if (exists $child->{'giofile'}) {
					my $thumb;
					unless ($child->{'no_thumbnail'}) {
						$thumb = $self->{_lp_ne}->load($shutter_hfunct->utf8_decode($child->{'giofile'}->get_path), Gtk3::IconSize->lookup('small-toolbar'));
					} else {
						$thumb = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, 5, 5);
						$thumb->fill(0x00000000);
					}

					$small_image = Gtk3::Image->new_from_pixbuf($thumb);
				} else {
					my $pixbuf = $self->{_lp_ne}->load($name, undef, undef, undef, TRUE);

					#16x16 is minimum size
					if ($pixbuf->get_width >= 16 && $pixbuf->get_height >= 16) {
						$small_image = Gtk3::Image->new_from_pixbuf($pixbuf->scale_simple(Gtk3::IconSize->lookup('menu'), 'bilinear'));
					}
				}
			};
			unless ($@) {
				if ($small_image) {
					$child->set_image($small_image);

					#init when toplevel
					unless ($no_init) {
						unless ($button->get_icon_widget) {
							$button->set_icon_widget(Gtk3::Image->new_from_pixbuf($small_image->get_pixbuf));
							$self->{_current_pixbuf_filename} = $name;
							$button->show_all;
						}
					}

					$child->signal_connect(
						'activate' => sub {
							$self->{_current_pixbuf_filename} = $name;
							$button->set_icon_widget(Gtk3::Image->new_from_pixbuf($small_image->get_pixbuf));
							$button->show_all;
							$self->{_canvas}->get_window->set_cursor($self->change_cursor_to_current_pixbuf);
						});
				} else {
					$child->destroy;
				}
			} else {
				$child->destroy;
			}

			return TRUE;
		});    #end idle callback

	return;
}

sub set_drawing_action {
	my ($self, $index) = @_;

	#~ print "set_drawing_action\n";
	my $item_index = 0;
	my $toolbar    = $self->{_uimanager}->get_widget("/ToolBarDrawing");
	for (my $i = 0 ; $i < $toolbar->get_n_items ; $i++) {
		my $item = $toolbar->get_nth_item($i);

		#skip separators
		#we only want to activate tools
		next if $item->isa('Gtk3::SeparatorToolItem');

		#add 1 to item index
		$item_index++;

		if ($item_index == $index) {
			if ($item->get_active) {
				$self->change_drawing_tool_cb($item_index * 10);
			} else {
				$item->set_active(TRUE);
			}
			last;
		}
	}

	return;
}

sub change_cursor_to_current_pixbuf {
	my $self = shift;

	#~ print "change_cursor_to_current_pixbuf\n";
	$self->{_current_mode_descr} = "image";

	my $cursor = undef;

	#load file
	$self->{_current_pixbuf} = $self->{_lp}->load($self->{_current_pixbuf_filename}, undef, undef, undef, TRUE);
	unless ($self->{_current_pixbuf}) {
		$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), Gtk3::Gdk::Pixbuf->new_from_file($self->{_dicons} . '/draw-image.svg'), Gtk3::IconSize->lookup('menu'));
	}

	#very big images usually don't work as a cursor (no error though??)
	my $pb_w = $self->{_current_pixbuf}->get_width;
	my $pb_h = $self->{_current_pixbuf}->get_height;

	if ($pb_w < 800 && $pb_h < 800) {
		eval {

			#maximum cursor size
			my ($cw, $ch) = Gtk3::Gdk::Display::get_default->get_maximal_cursor_size;

			#images smaller than max cursor size?
			# => don't scale to a bigger size
			if ($cw > $pb_w || $ch > $pb_w) {
				$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), $self->{_current_pixbuf}, int($pb_w / 2), int($pb_h / 2));
			} else {
				my $cpixbuf = $self->{_lp}->load($self->{_current_pixbuf_filename}, $cw, $ch, TRUE, TRUE);
				$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), $cpixbuf, int($cpixbuf->get_width / 2), int($cpixbuf->get_height / 2));
			}

		};
		if ($@) {
			my $response = $self->{_dialogs}->dlg_error_message(
				sprintf($self->{_d}->get("Error while opening image %s."), "'" . $self->{_current_pixbuf_filename} . "'"),
				$self->{_d}->get("There was an error opening the image."),
				undef, undef, undef, undef, undef, undef, $@
			);
			$self->abort_current_mode;
		}
	} else {
		$cursor = Gtk3::Gdk::Cursor->new_from_pixbuf(Gtk3::Gdk::Display::get_default(), Gtk3::Gdk::Pixbuf->new_from_file($self->{_dicons} . '/draw-image.svg'), Gtk3::IconSize->lookup('menu'));
	}

	return $cursor;
}

sub paste_item {
	my $self = shift;
	return $self->{_item_factory}->paste_item(@_);
}

sub create_polyline {
	my $self = shift;
	return $self->{_item_factory}->create_polyline(@_);
}

sub create_censor {
	my $self = shift;
	return $self->{_item_factory}->create_censor(@_);
}

sub create_pixel_image {
	my $self = shift;
	return $self->{_item_factory}->create_pixel_image(@_);
}

sub create_image {
	my $self = shift;
	return $self->{_item_factory}->create_image(@_);
}

sub create_text {
	my $self = shift;
	return $self->{_item_factory}->create_text(@_);
}

sub create_line {
	my $self = shift;
	return $self->{_item_factory}->create_line(@_);
}

sub create_ellipse {
	my $self = shift;
	return $self->{_item_factory}->create_ellipse(@_);
}

sub create_rectangle {
	my $self = shift;
	return $self->{_item_factory}->create_rectangle(@_);
}

1;
