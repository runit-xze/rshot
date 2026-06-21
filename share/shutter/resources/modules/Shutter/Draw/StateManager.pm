package Shutter::Draw::StateManager;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

sub quit ($mgr, $show_warning) {
	my $self = $mgr->drawing_tool;

	my ($name, $folder, $type) = fileparse($self->{_filename}, qr/\.[^.]*/);

	#save settings to a file in the shutter folder
	#is there already a .shutter folder?
	mkdir("$ENV{ 'HOME' }/.shutter")
		unless (-d "$ENV{ 'HOME' }/.shutter");

	if ($show_warning && (defined $self->{_undo} && scalar(@{$self->{_undo}}) > 0)) {

		#warn the user if there are any unsaved changes
		my $warn_dialog = Gtk3::MessageDialog->new($self->{_drawing_window}, [qw/modal destroy-with-parent/], 'other', 'none', undef);

		#set question text
		$warn_dialog->set('text' => sprintf($self->{_d}->get("Save the changes to image %s before closing?"), "'$name$type'"));

		#set text...
		$self->update_warning_text($warn_dialog);

		#...and update it
		my $id = Glib::Timeout->add(
			1000,
			sub {
				$self->update_warning_text($warn_dialog);
				return TRUE;
			});

		$warn_dialog->set('image' => Gtk3::Image->new_from_stock('gtk-save', 'dialog'));

		$warn_dialog->set('title' => $self->{_d}->get("Close") . " " . $name . $type);

		#don't save button
		my $dsave_btn = Gtk3::Button->new_with_mnemonic($self->{_d}->get("Do_n't save"));
		$dsave_btn->set_image(Gtk3::Image->new_from_stock('gtk-delete', 'button'));

		#cancel button
		my $cancel_btn = Gtk3::Button->new_from_stock('gtk-cancel');
		$cancel_btn->set_can_default(TRUE);

		#save button
		my $save_btn = Gtk3::Button->new_from_stock('gtk-save');

		$warn_dialog->add_action_widget($dsave_btn,  10);
		$warn_dialog->add_action_widget($cancel_btn, 20);
		$warn_dialog->add_action_widget($save_btn,   30);

		$warn_dialog->set_default_response(20);

		$warn_dialog->get_child->show_all;
		my $response = $warn_dialog->run;
		Glib::Source->remove($id);
		if ($response == 20) {
			$warn_dialog->destroy;
			return TRUE;
		} elsif ($response == 30) {
			$self->save();
		}

		$self->{_drawing_window}->hide if $self->{_drawing_window};
		$warn_dialog->hide;
		$warn_dialog->destroy;

	}

	$self->save_settings;

	if ($self->{_selector_handler}) {
		$self->{_selector}->signal_handler_disconnect($self->{_selector_handler});
	}

	$self->{_drawing_window}->hide if $self->{_drawing_window};

	$self->{_drawing_window}->destroy if $self->{_drawing_window};

	#remove statusbar timer
	#Glib::Source->remove($self->{_drawing_statusbar}->{statusbar_timer}) if defined $self->{_drawing_statusbar}->{statusbar_timer};

	#delete hash entries to avoid any
	#possible circularity
	#
	#this would lead to a memory leak
	foreach (keys %{$self}) {
		delete $self->{$_};
	}

	Gtk3->main_quit();

	return FALSE;
}

sub update_warning_text ($mgr, $warn_dialog) {
	my $self = $mgr->drawing_tool;

	my $minutes = int((time - $self->{_start_time}) / 60);
	$minutes = 1 if $minutes == 0;

	my $txt = $self->{_d}->nget(
		"If you don't save the image, changes from the last minute will be lost",
		"If you don't save the image, changes from the last %d minutes will be lost",
		$minutes
	);

	$txt = sprintf($txt, $minutes) if $minutes > 1;

	$warn_dialog->set(
		'secondary-text' => "$txt."
	);

	return TRUE;
}

sub abort_current_mode ($mgr) {
	my $self = $mgr->drawing_tool;

	if ($self->{_current_item}) {
		$self->{_canvas}->pointer_ungrab($self->{_current_item}, Gtk3::get_current_event_time());
		$self->{_canvas}->keyboard_ungrab($self->{_current_item}, Gtk3::get_current_event_time());
	}

	#~ print "abort_current_mode\n";

	$self->set_drawing_action(1);

	return TRUE;
}

sub clear_item_from_canvas ($mgr, $item) {
	my $self = $mgr->drawing_tool;

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

sub move_all ($mgr, $x, $y) {
	my $self = $mgr->drawing_tool;

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

sub deactivate_all ($mgr) {
	my $self = $mgr->drawing_tool;
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

sub gen_thumbnail_on_idle ($mgr) {
	my $self = $mgr->drawing_tool;
	my $stock      = shift;
	my $parent     = shift;
	my $button     = shift;
	my $no_init    = shift;
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

}

sub set_drawing_action ($mgr) {
	my $self = $mgr->drawing_tool;
	my $index = shift;

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

}

sub change_cursor_to_current_pixbuf ($mgr) {
	my $self = $mgr->drawing_tool;

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

sub setup_item_signals ($mgr, $item) {
	my $self = $mgr->drawing_tool;

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

sub push_tool_help_to_statusbar ($mgr, $x, $y, $action) {
	my $self = $mgr->drawing_tool;

	#init $action if not defined
	$action = 'none' unless defined $action;

	#current event coordinates
	my $status_text = int($x) . " x " . int($y);

	if ($self->{_current_mode} == 10) {

		if ($action eq 'resize') {
			$status_text .= " " . $self->{_d}->get("Click-Drag to scale (try Control to scale uniformly)");
		} elsif ($action eq 'canvas_resize') {
			$status_text .= " " . $self->{_d}->get("Click-Drag to resize the canvas");
		}

	} elsif ($self->{_current_mode} == 20 || $self->{_current_mode} == 30) {

		$status_text .= " " . $self->{_d}->get("Click to paint (try Control or Shift for a straight line)");

	} elsif ($self->{_current_mode} == 40) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new straight line");

	} elsif ($self->{_current_mode} == 50) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new arrow");

	} elsif ($self->{_current_mode} == 60) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new rectangle");

	} elsif ($self->{_current_mode} == 70) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a new ellipse");

	} elsif ($self->{_current_mode} == 80) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to add a new text area");

	} elsif ($self->{_current_mode} == 90) {

		$status_text .= " " . $self->{_d}->get("Click to censor (try Control or Shift for a straight line)");

	} elsif ($self->{_current_mode} == 100) {

		$status_text .= " " . $self->{_d}->get("Click-Drag to create a pixelized region");

	} elsif ($self->{_current_mode} == 110) {

		$status_text .= " " . $self->{_d}->get("Click to add an auto-increment shape");

	} elsif ($self->{_current_mode} == 120) {

		#nothing to do here....

	}

	#update statusbar
	$self->show_status_message(1, $status_text);

	return TRUE;

}

sub show_status_message ($mgr) {
	my $self = $mgr->drawing_tool;
	my $index        = shift;
	my $status_text  = shift;
	my $status_image = shift;    #this is a stock-id

	#~ #remove old message and timer
	#~ $self->{_drawing_statusbar}->pop($index);
	#~ Glib::Source->remove ($self->{_drawing_statusbar}->{statusbar_timer}) if defined $self->{_drawing_statusbar}->{statusbar_timer};

	#new message and image
	if (defined $status_image) {
		$self->{_drawing_statusbar_image}->set_from_stock($status_image, 'menu');
	} else {
		$self->{_drawing_statusbar_image}->clear;
	}
	$self->{_drawing_statusbar}->push($index, $status_text);

	#~ #...and remove it
	#~ $self->{_drawing_statusbar}->{statusbar_timer} = Glib::Timeout->add(
	#~ 3000,
	#~ sub {
	#~ $self->{_drawing_statusbar}->pop($index) if defined $self->{_drawing_statusbar};
	#~ return FALSE;
	#~ }
	#~ );

	return TRUE;
}
1;
