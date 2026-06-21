package Shutter::Draw::ItemFactory;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

sub create_polyline {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev        = shift;
	my $copy_item = shift;
	my $highlighter = shift;

	require Shutter::Draw::Polyline;
	my $poly = Shutter::Draw::Polyline->new( app => $self );
	return $poly->setup($ev, $copy_item, $highlighter);
}


sub create_censor {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev        = shift;
	my $copy_item = shift;

	require Shutter::Draw::Censor;
	my $censor = Shutter::Draw::Censor->new( app => $self );
	return $censor->setup($ev, $copy_item);
}


sub create_pixel_image {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev        = shift;
	my $copy_item = shift;

	require Shutter::Draw::Blur;
	my $blur = Shutter::Draw::Blur->new( app => $self );
	return $blur->setup($ev, $copy_item);
}


sub create_image {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev                   = shift;
	my $copy_item            = shift;
	my $force_orig_size_init = shift;

	my ($x, $y, $width, $height) = (0, 0, 0, 0);

	#use event coordinates
	if ($ev) {

		#we create the new image item
		#and use the original image size
		#dnd for example
		if ($force_orig_size_init) {
			$x = $ev->x - int($self->{_current_pixbuf}->get_width / 2);
			$y = $ev->y - int($self->{_current_pixbuf}->get_height / 2);
			$width = $self->{_current_pixbuf}->get_width;
			$height = $self->{_current_pixbuf}->get_height;
		} else {
			$x = $ev->x;
			$y = $ev->y;
		}

		#use source item coordinates
	} elsif ($copy_item) {
		$x = $copy_item->get('x') + 20;
		$y = $copy_item->get('y') + 20;
		$width = $self->{_items}{$copy_item}->get('width');
		$height = $self->{_items}{$copy_item}->get('height');
	}

	my $item    = GooCanvas2::CanvasRect->new(
		parent=>$self->{_canvas}->get_root_item, x=>$x, y=>$y, width=>$width, height=>$height,
		'fill-color-rgba' => 0,
		'line-dash'    => GooCanvas2::CanvasLineDash->newv([5, 5]),
		'line-width'   => 1,
		'stroke-color' => 'gray',
	);

	$self->{_current_new_item} = $item unless ($copy_item);
	$self->{_items}{$item} = $item;

	if ($ev) {
		$self->{_items}{$item}{orig_pixbuf}          = $self->{_current_pixbuf}->copy;
		$self->{_items}{$item}{orig_pixbuf_filename} = $self->{_current_pixbuf_filename};
	} elsif ($copy_item) {
		$self->{_items}{$item}{orig_pixbuf}          = $self->{_items}{$copy_item}{orig_pixbuf}->copy;
		$self->{_items}{$item}{orig_pixbuf_filename} = $self->{_items}{$copy_item}{orig_pixbuf_filename};
	}

	$self->{_items}{$item}{image} = GooCanvas2::CanvasImage->new(
		parent=>$self->{_canvas}->get_root_item,
		pixbuf=>$self->{_items}{$item}{orig_pixbuf},
		x=>$item->get('x'),
		y=>$item->get('y'),
		'width'  => 2,
		'height' => 2,
	);

	#set type flag
	$self->{_items}{$item}{type} = 'image';
	$self->{_items}{$item}{uid}  = $self->{_uid}++;

	#create rectangles
	$self->handle_rects('create', $item);

	#show image directly when copy or dnd
	if ($copy_item || $force_orig_size_init) {
		$self->handle_embedded('update', $item);
	}

	$self->setup_item_signals($self->{_items}{$item}{image});
	$self->setup_item_signals_extra($self->{_items}{$item}{image});

	$self->setup_item_signals($self->{_items}{$item});
	$self->setup_item_signals_extra($self->{_items}{$item});

	if ($copy_item) {

		my $copy = $self->{_lp}->load($self->{_items}{$item}{orig_pixbuf_filename}, $self->{_items}{$item}->get('width'), $self->{_items}{$item}->get('height'), FALSE, TRUE);

		$self->{_items}{$item}{image}->set(
			'x'      => int $self->{_items}{$item}->get('x'),
			'y'      => int $self->{_items}{$item}->get('y'),
			'pixbuf' => $copy
		);

		$self->handle_rects('hide', $item);

	}

	return $item;
}


sub create_text {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev        = shift;
	my $copy_item = shift;

	require Shutter::Draw::Text;
	my $text = Shutter::Draw::Text->new( app => $self );
	return $text->setup($ev, $copy_item);
}


sub create_line {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev          = shift;
	my $copy_item   = shift;
	my $end_arrow   = shift;
	my $start_arrow = shift;

	require Shutter::Draw::Arrow;
	my $arrow = Shutter::Draw::Arrow->new( app => $self );
	return $arrow->setup($ev, $copy_item, $end_arrow, $start_arrow);
}


sub create_ellipse {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev        = shift;
	my $copy_item = shift;
	my $numbered  = shift;

	require Shutter::Draw::Ellipse;
	my $ellipse = Shutter::Draw::Ellipse->new( app => $self );
	return $ellipse->setup($ev, $copy_item, $numbered);
}


sub create_rectangle {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $ev        = shift;
	my $copy_item = shift;

	require Shutter::Draw::Rectangle;
	my $rect = Shutter::Draw::Rectangle->new( app => $self );
	return $rect->setup($ev, $copy_item);
}


# getters and setters


sub paste_item {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $item = shift;

	#cut instead of copy
	my $delete_after = shift;

	#import from system's clipboard
	if (my $image = $self->{_clipboard}->wait_for_image) {

		#backup current pixbuf and filename
		my $old_current  = $self->{_current_pixbuf};
		my $old_filename = $self->{_current_pixbuf_filename};

		#create tempfile
		my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);

		#save pixbuf to tempfile and integrate it
		my $pixbuf_save = Shutter::Pixbuf::Save->new($self->{_sc}, $self->{_drawing_window});
		if ($pixbuf_save->save_pixbuf_to_file($image, $tmpfilename, 'png')) {

			#set pixbuf vars
			$self->{_current_pixbuf}          = $image;
			$self->{_current_pixbuf_filename} = $tmpfilename;

			#construct an event and create a new image object
			my $initevent = Gtk3::Gdk::Event->new('motion-notify');
			$initevent->time(Gtk3::get_current_event_time());
			$initevent->window($self->{_drawing_window}->get_window);

			#calculate coordinates
			$initevent->x(int($self->{_canvas_bg_rect}->get('width') / 2));
			$initevent->y(int($self->{_canvas_bg_rect}->get('height') / 2));

			#new item
			my $nitem = $self->create_image($initevent, undef, TRUE);

			#add to undo stack
			$self->store_to_xdo_stack($nitem, 'create', 'undo');

			#restore saved values
			$self->{_current_pixbuf}          = $old_current;
			$self->{_current_pixbuf_filename} = $old_filename;

			#uncheck
			$self->{_current_new_item}  = undef;
			$self->{_current_item}      = undef;
			$self->{_current_copy_item} = undef;

		}

		#import from DrawingTool's clipboard
	} elsif (defined $item) {

		my $child = $self->get_child_item($item);

		my $new_item = undef;
		if ($item->isa('GooCanvas2::CanvasRect') && !$child) {

			#~ print "Creating Rectangle...\n";
			$new_item = $self->create_rectangle(undef, $item);
		} elsif ($item->isa('GooCanvas2::CanvasPolyline') && !$child) {

			#~ print "Creating Polyline...\n";
			$new_item = $self->create_polyline(undef, $item);
		} elsif ($child->isa('GooCanvas2::CanvasPolyline') && exists $self->{_items}{$item}{stroke_color}) {

			#~ print "Creating Line...\n";
			$new_item = $self->create_line(undef, $item);
		} elsif ($child->isa('GooCanvas2::CanvasPolyline')) {

			#~ print "Creating Censor...\n";
			$new_item = $self->create_censor(undef, $item);
		} elsif ($child->isa('GooCanvas2::CanvasEllipse')) {

			#~ print "Creating Ellipse...\n";
			$new_item = $self->create_ellipse(undef, $item);
		} elsif ($child->isa('GooCanvas2::CanvasText')) {

			#~ print "Creating Text...\n";
			$new_item = $self->create_text(undef, $item);
		} elsif ($child->isa('GooCanvas2::CanvasImage') && exists $self->{_items}{$item}{pixelize}) {

			#~ print "Creating Pixelize...\n";
			$new_item = $self->create_pixel_image(undef, $item);
		} elsif ($child->isa('GooCanvas2::CanvasImage')) {

			#~ print "Creating Image...\n";
			$new_item = $self->create_image(undef, $item);
		}

		#cut instead of copy
		if ($delete_after) {
			$self->clear_item_from_canvas($item);
			$self->{_current_item}      = undef;
			$self->{_current_copy_item} = undef;
		}

		#add to undo stack
		$self->store_to_xdo_stack($new_item, 'create', 'undo');

	}

	return TRUE;
}


sub get_opposite_rect {
	my $mgr = shift;
	my $self = $mgr->drawing_tool;
	my $rect   = shift;
	my $item   = shift;
	my $width  = shift;
	my $height = shift;

	foreach (keys %{$self->{_items}{$item}}) {

		#fancy resizing using our little resize boxes
		if ($rect eq $self->{_items}{$item}{$_}) {

			if ($_ eq 'top-left-corner') {

				return 'bottom-right-corner' if $width < 0 && $height < 0;
				return 'top-right-corner'    if $width < 0;
				return 'bottom-left-corner'  if $height < 0;

			} elsif ($_ eq 'top-side') {

				return 'bottom-side';

			} elsif ($_ eq 'top-right-corner') {

				return 'bottom-left-corner'  if $width < 0 && $height < 0;
				return 'top-left-corner'     if $width < 0;
				return 'bottom-right-corner' if $height < 0;

			} elsif ($_ eq 'left-side') {

				return 'right-side';

			} elsif ($_ eq 'right-side') {

				return 'left-side';

			} elsif ($_ eq 'bottom-left-corner') {

				return 'top-right-corner'    if $width < 0 && $height < 0;
				return 'bottom-right-corner' if $width < 0;
				return 'top-left-corner'     if $height < 0;

			} elsif ($_ eq 'bottom-side') {

				return 'top-side';

			} elsif ($_ eq 'bottom-right-corner') {

				return 'top-left-corner'    if $width < 0 && $height < 0;
				return 'bottom-left-corner' if $width < 0;
				return 'top-right-corner'   if $height < 0;

			}
		}
	}

	return FALSE;
}


sub get_parent_item {
	my ($mgr, $item) = @_;
	my $self = $mgr->drawing_tool;

	return FALSE unless $item;

	my $parent = undef;
	foreach (keys %{$self->{_items}}) {
		$parent = $self->{_items}{$_} if exists $self->{_items}{$_}{ellipse}  && $self->{_items}{$_}{ellipse} == $item;
		$parent = $self->{_items}{$_} if exists $self->{_items}{$_}{text}     && $self->{_items}{$_}{text} == $item;
		$parent = $self->{_items}{$_} if exists $self->{_items}{$_}{image}    && $self->{_items}{$_}{image} == $item;
		$parent = $self->{_items}{$_} if exists $self->{_items}{$_}{pixelize} && $self->{_items}{$_}{pixelize} == $item;
		$parent = $self->{_items}{$_} if exists $self->{_items}{$_}{line}     && $self->{_items}{$_}{line} == $item;
		if (defined $parent) {
			last;
		}
	}

	#~ #debug
	#~ if($parent){
	#~ print "parent: $parent queried for item: $item\n";
	#~ }else{
	#~ print "no parent found for item: $item\n";
	#~ }

	return $parent;
}


sub get_highest_auto_digit {
	my ($self) = @_;

	my $number = 0;
	foreach (keys %{$self->{_items}}) {

		my $item = $self->{_items}{$_};

		#numbered shape
		if (   exists $self->{_items}{$item}
			&& exists $self->{_items}{$item}{type}
			&& $self->{_items}{$item}{type} eq 'number'
			&& $self->{_items}{$item}{text}->get('visibility') ne 'hidden')
		{
			$number = $self->{_items}{$item}{text}{digit} if $self->{_items}{$item}{text}{digit} > $number;
		}

	}

	return $number;
}


sub get_pixelated_pixbuf_from_canvas {
	my ($mgr, $item) = @_;
	my $self = $mgr->drawing_tool;

	my $bounds = $item->get_bounds;
	my $sw     = $item->get('width');
	my $sh     = $item->get('height');

	#create surface and cairo context
	my $surface = Cairo::ImageSurface->create('rgb24', $bounds->x1 + $sw, $bounds->y1 + $sh);
	my $cr      = Cairo::Context->create($surface);

	#hide rects and image
	$self->handle_rects('hide', $item);
	$self->handle_embedded('hide', $item);

	#render the content and load it via Gtk3::Gdk::PixbufLoader
	$self->{_canvas}->render($cr, $bounds, 1);

	#show rects again
	$self->handle_rects('update', $item);

	#~ print "start loader\n";
	my $loader = Gtk3::Gdk::PixbufLoader->new;
	$surface->write_to_png_stream(
		sub {
			my ($closure, $data) = @_;
			$loader->write([map ord, split //, $data]);
			return TRUE;
		});
	$loader->close;

	#create vars
	my ($pixbuf, $target) = (undef, undef);

	#error icon
	my $error = Gtk3::Widget::render_icon(Gtk3::Invisible->new, "gtk-dialog-error", 'menu');

	eval {

		$pixbuf = $loader->get_pixbuf;

		#create target pixbuf
		$target = Gtk3::Gdk::Pixbuf->new($pixbuf->get_colorspace, TRUE, 8, $sw, $sh);

	};
	unless ($@) {

		#maybe rect is only partially on canvas
		my ($sx, $sy) = ($bounds->x1, $bounds->y1);
		my ($dx, $dy) = (0, 0);
		if ($bounds->x1 < 0) {
			$sx = 0;
			$dx = abs $bounds->x1;
			$sw += $bounds->x1;
		}
		if ($bounds->y1 < 0) {
			$sy = 0;
			$dy = abs $bounds->y1;
			$sh += $bounds->y1;
		}

		#valid pixbuf?
		if ($pixbuf) {

			#copy area
			$pixbuf->copy_area($sx, $sy, $sw, $sh, $target, $dx, $dy);

			if ($target->get_width > 10 && $target->get_height > 10) {

				eval {

					#pixelate the pixbuf - simply scale it down and scale it up afterwards
					$target = $target->scale_simple($target->get_width * 0.1, $target->get_height * 0.1, 'tiles');
					$target = $target->scale_simple($item->get('width'),      $item->get('height'),      'tiles');

				};
				unless ($@) {

					return $target;

				}

			} elsif ($target->get_width > 5 && $target->get_height > 5) {

				eval {

					#pixelate the pixbuf - simply scale it down and scale it up afterwards
					$target = $target->scale_simple($target->get_width * 0.2, $target->get_height * 0.2, 'tiles');
					$target = $target->scale_simple($item->get('width'),      $item->get('height'),      'tiles');

				};
				unless ($@) {

					return $target;

				}

			}

		}

	}

	return $error;

}


sub get_child_item {
	my ($mgr, $item) = @_;
	my $self = $mgr->drawing_tool;

	return FALSE unless $item;

	my $child = undef;

	#notice (special shapes like numbered ellipse do deliver ellipse here => NOT text!)
	#therefore the order matters
	if (defined $item && exists $self->{_items}{$item}) {
		$child = $self->{_items}{$item}{text}     if exists $self->{_items}{$item}{text};
		$child = $self->{_items}{$item}{ellipse}  if exists $self->{_items}{$item}{ellipse};
		$child = $self->{_items}{$item}{image}    if exists $self->{_items}{$item}{image};
		$child = $self->{_items}{$item}{pixelize} if exists $self->{_items}{$item}{pixelize};
		$child = $self->{_items}{$item}{line}     if exists $self->{_items}{$item}{line};
	}

	#~ #debug
	#~ if($child){
	#~ print "child: $child queried for item: $item\n";
	#~ }else{
	#~ print "no child found for item: $item\n";
	#~ }

	return $child;
}



1;
