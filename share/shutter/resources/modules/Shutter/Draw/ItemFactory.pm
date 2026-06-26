package Shutter::Draw::ItemFactory;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;
use GooCanvas2;

has drawing_tool => (is => 'ro', required => 1);

sub _tool_setup {
	my ($mgr, $tool_name, @setup_args) = @_;
	my $dt         = $mgr->drawing_tool;
	my $tool_class = $dt->_canvas_manager->registry->get_tool($tool_name)
		or die "Unknown drawing tool: $tool_name";
	eval "require $tool_class; 1" or die "Could not load $tool_class: $@";
	return $tool_class->new(drawing_tool => $dt)->setup(@setup_args);
}

sub create_polyline {
	my $mgr         = shift;
	my $self        = $mgr->drawing_tool;
	my $ev          = shift;
	my $copy_item   = shift;
	my $highlighter = shift;

	require Shutter::Draw::Polyline;
	my $poly = Shutter::Draw::Polyline->new(app => $self);
	return $poly->setup($ev, $copy_item, $highlighter);
}

sub create_censor {
	my $mgr = shift;
	return $mgr->_tool_setup('censor', @_);
}

sub create_pixel_image {
	my $mgr = shift;
	return $mgr->_tool_setup('pixelize', @_);
}

sub create_image {
	my $mgr                  = shift;
	my $self                 = $mgr->drawing_tool;
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
			$x      = $ev->x - int($self->_current_pixbuf->get_width / 2);
			$y      = $ev->y - int($self->_current_pixbuf->get_height / 2);
			$width  = $self->_current_pixbuf->get_width;
			$height = $self->_current_pixbuf->get_height;
		} else {
			$x = $ev->x;
			$y = $ev->y;
		}

		#use source item coordinates
	} elsif ($copy_item) {
		$x      = $copy_item->get('x') + 20;
		$y      = $copy_item->get('y') + 20;
		$width  = $self->_items->{$copy_item}->get('width');
		$height = $self->_items->{$copy_item}->get('height');
	}

	my $item = GooCanvas2::CanvasRect->new(
		parent            => $self->_canvas->get_root_item,
		x                 => $x,
		y                 => $y,
		width             => $width,
		height            => $height,
		'fill-color-rgba' => 0,
		'line-dash'       => GooCanvas2::CanvasLineDash->newv([5, 5]),
		'line-width'      => 1,
		'stroke-color'    => 'gray',
	);

	$self->_current_new_item = $item unless ($copy_item);
	$self->_items->{$item} = $item;

	if ($ev) {
		$self->_items->{$item}{orig_pixbuf}          = $self->_current_pixbuf->copy;
		$self->_items->{$item}{orig_pixbuf_filename} = $self->_current_pixbuf_filename;
	} elsif ($copy_item) {
		$self->_items->{$item}{orig_pixbuf}          = $self->_items->{$copy_item}{orig_pixbuf}->copy;
		$self->_items->{$item}{orig_pixbuf_filename} = $self->_items->{$copy_item}{orig_pixbuf_filename};
	}

	$self->_items->{$item}{image} = GooCanvas2::CanvasImage->new(
		parent   => $self->_canvas->get_root_item,
		pixbuf   => $self->_items->{$item}{orig_pixbuf},
		x        => $item->get('x'),
		y        => $item->get('y'),
		'width'  => 2,
		'height' => 2,
	);

	#set type flag
	$self->_items->{$item}{type} = 'image';
	$self->_items->{$item}{uid}  = $self->_uid++;

	#create rectangles
	$self->handle_rects('create', $item);

	#show image directly when copy or dnd
	if ($copy_item || $force_orig_size_init) {
		$self->handle_embedded('update', $item);
	}

	$self->setup_item_signals($self->_items->{$item}{image});
	$self->setup_item_signals_extra($self->_items->{$item}{image});

	$self->setup_item_signals($self->_items->{$item});
	$self->setup_item_signals_extra($self->_items->{$item});

	if ($copy_item) {

		my $copy = $self->_lp->load($self->_items->{$item}{orig_pixbuf_filename}, $self->_items->{$item}->get('width'), $self->_items->{$item}->get('height'), FALSE, TRUE);

		$self->_items->{$item}{image}->set(
			'x'      => int $self->_items->{$item}->get('x'),
			'y'      => int $self->_items->{$item}->get('y'),
			'pixbuf' => $copy
		);

		$self->handle_rects('hide', $item);

	}

	return $item;
}

sub create_text {
	my $mgr = shift;
	return $mgr->_tool_setup('text', @_);
}

sub create_line {
	my $mgr = shift;
	return $mgr->_tool_setup('line', @_);
}

sub create_ellipse {
	my ($mgr, $ev, $copy_item, $numbered) = @_;
	if ($numbered) {
		return $mgr->_tool_setup('number', $ev, $copy_item);
	}
	return $mgr->_tool_setup('ellipse', $ev, $copy_item, $numbered);
}

sub create_rectangle {
	my $mgr = shift;
	return $mgr->_tool_setup('rect', @_);
}

# getters and setters

sub paste_item {
	my $mgr  = shift;
	my $self = $mgr->drawing_tool;
	my $item = shift;

	#cut instead of copy
	my $delete_after = shift;

	#import from system's clipboard
	if (my $image = $self->_clipboard->wait_for_image) {

		#backup current pixbuf and filename
		my $old_current  = $self->_current_pixbuf;
		my $old_filename = $self->_current_pixbuf_filename;

		#create tempfile
		my ($tmpfh, $tmpfilename) = tempfile(UNLINK => 1);

		#save pixbuf to tempfile and integrate it
		my $pixbuf_save = Shutter::Pixbuf::Save->new($self->_sc, $self->_drawing_window);
		if ($pixbuf_save->save_pixbuf_to_file($image, $tmpfilename, 'png')) {

			#set pixbuf vars
			$self->_current_pixbuf          = $image;
			$self->_current_pixbuf_filename = $tmpfilename;

			#construct an event and create a new image object
			my $initevent = Gtk3::Gdk::Event->new('motion-notify');
			$initevent->time(Gtk3::get_current_event_time());
			$initevent->window($self->_drawing_window->get_window);

			#calculate coordinates
			$initevent->x(int($self->_canvas_bg_rect->get('width') / 2));
			$initevent->y(int($self->_canvas_bg_rect->get('height') / 2));

			#new item
			my $nitem = $self->create_image($initevent, undef, TRUE);

			#add to undo stack
			$self->store_to_xdo_stack($nitem, 'create', 'undo');

			#restore saved values
			$self->_current_pixbuf          = $old_current;
			$self->_current_pixbuf_filename = $old_filename;

			#uncheck
			$self->_current_new_item  = undef;
			$self->_current_item      = undef;
			$self->_current_copy_item = undef;

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
		} elsif ($child->isa('GooCanvas2::CanvasPolyline') && exists $self->_items->{$item}{stroke_color}) {

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
		} elsif ($child->isa('GooCanvas2::CanvasImage') && exists $self->_items->{$item}{pixelize}) {

			#~ print "Creating Pixelize...\n";
			$new_item = $self->create_pixel_image(undef, $item);
		} elsif ($child->isa('GooCanvas2::CanvasImage')) {

			#~ print "Creating Image...\n";
			$new_item = $self->create_image(undef, $item);
		}

		#cut instead of copy
		if ($delete_after) {
			$self->clear_item_from_canvas($item);
			$self->_current_item      = undef;
			$self->_current_copy_item = undef;
		}

		#add to undo stack
		$self->store_to_xdo_stack($new_item, 'create', 'undo');

	}

	return TRUE;
}

sub get_opposite_rect {
	my $mgr    = shift;
	my $self   = $mgr->drawing_tool;
	my $rect   = shift;
	my $item   = shift;
	my $width  = shift;
	my $height = shift;

	foreach (keys %{$self->_items->{$item}}) {

		#fancy resizing using our little resize boxes
		if ($rect eq $self->_items->{$item}{$_}) {

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
	foreach (keys %{$self->_items}) {
		$parent = $self->_items->{$_} if exists $self->_items->{$_}{ellipse}  && $self->_items->{$_}{ellipse} == $item;
		$parent = $self->_items->{$_} if exists $self->_items->{$_}{text}     && $self->_items->{$_}{text} == $item;
		$parent = $self->_items->{$_} if exists $self->_items->{$_}{image}    && $self->_items->{$_}{image} == $item;
		$parent = $self->_items->{$_} if exists $self->_items->{$_}{pixelize} && $self->_items->{$_}{pixelize} == $item;
		$parent = $self->_items->{$_} if exists $self->_items->{$_}{line}     && $self->_items->{$_}{line} == $item;
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
	my $self   = shift;
	my $number = 0;
	foreach (keys %{$self->_items}) {

		my $item = $self->_items->{$_};

		#numbered shape
		if (   exists $self->_items->{$item}
			&& exists $self->_items->{$item}{type}
			&& $self->_items->{$item}{type} eq 'number'
			&& $self->_items->{$item}{text}->get('visibility') ne 'hidden')
		{
			$number = $self->_items->{$item}{text}{digit} if $self->_items->{$item}{text}{digit} > $number;
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
	$self->_canvas->render($cr, $bounds, 1);

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
	if (defined $item && exists $self->_items->{$item}) {
		$child = $self->_items->{$item}{text}     if exists $self->_items->{$item}{text};
		$child = $self->_items->{$item}{ellipse}  if exists $self->_items->{$item}{ellipse};
		$child = $self->_items->{$item}{image}    if exists $self->_items->{$item}{image};
		$child = $self->_items->{$item}{pixelize} if exists $self->_items->{$item}{pixelize};
		$child = $self->_items->{$item}{line}     if exists $self->_items->{$item}{line};
	}

	#~ #debug
	#~ if($child){
	#~ print "child: $child queried for item: $item\n";
	#~ }else{
	#~ print "no child found for item: $item\n";
	#~ }

	return $child;
}

# Factory methods for canvas item creation
sub create_bounding_rect {
	my ($mgr, $x, $y, $w, $h) = @_;
	return GooCanvas2::CanvasRect->new(
		parent            => $mgr->drawing_tool->canvas->get_root_item,
		x                 => $x,
		y                 => $y,
		width             => $w,
		height            => $h,
		'fill-color-rgba' => 0,
		'line-dash'       => GooCanvas2::CanvasLineDash->newv([5, 5]),
		'line-width'      => 1,
		'stroke-color'    => 'gray',
	);
}

sub create_rect_item {
	my ($mgr, $x, $y, $w, $h, $fill, $stroke, $line_width) = @_;
	return GooCanvas2::CanvasRect->new(
		parent                  => $mgr->drawing_tool->canvas->get_root_item,
		x                       => $x,
		y                       => $y,
		width                   => $w,
		height                  => $h,
		'fill-color-gdk-rgba'   => $fill,
		'stroke-color-gdk-rgba' => $stroke,
		'line-width'            => $line_width,
	);
}

sub create_ellipse_item {
	my ($mgr, $x, $y, $w, $h, $fill, $stroke, $line_width) = @_;
	return GooCanvas2::CanvasEllipse->new(
		parent                  => $mgr->drawing_tool->canvas->get_root_item,
		x                       => $x,
		y                       => $y,
		width                   => $w,
		height                  => $h,
		'fill-color-gdk-rgba'   => $fill,
		'stroke-color-gdk-rgba' => $stroke,
		'line-width'            => $line_width,
	);
}

sub create_text_label {
	my ($mgr, $x, $y, $text, $color, $line_width) = @_;
	return GooCanvas2::CanvasText->new(
		parent                => $mgr->drawing_tool->canvas->get_root_item,
		text                  => $text,
		x                     => $x,
		y                     => $y,
		width                 => -1,
		anchor                => 'center',
		'use-markup'          => TRUE,
		'fill-color-gdk-rgba' => $color,
		'line-width'          => $line_width,
	);
}

sub create_censor_polyline {
	my ($mgr, $stipple) = @_;
	return GooCanvas2::CanvasPolyline->new(
		parent          => $mgr->drawing_tool->canvas->get_root_item,
		'close-path'    => FALSE,
		'stroke-pixbuf' => $stipple,
		'line-width'    => 14,
		'line-cap'      => 'CAIRO_LINE_CAP_ROUND',
		'line-join'     => 'CAIRO_LINE_JOIN_ROUND',
	);
}

sub create_line_polyline {
	my ($mgr, $x, $y, $w, $h, $stroke, $line_width, $end_arrow, $start_arrow, $arrow_length, $arrow_width, $arrow_tip_length) = @_;
	return GooCanvas2::CanvasPolyline->new(
		parent                  => $mgr->drawing_tool->canvas->get_root_item,
		close_path              => FALSE,
		points                  => Shutter::Draw::Utils::points_to_canvas_points($x, $y, $x + $w, $y + $h),
		'stroke-color-gdk-rgba' => $stroke,
		'line-width'            => $line_width,
		'line-cap'              => 'CAIRO_LINE_CAP_ROUND',
		'line-join'             => 'CAIRO_LINE_JOIN_ROUND',
		'end-arrow'             => $end_arrow,
		'start-arrow'           => $start_arrow,
		'arrow-length'          => $arrow_length,
		'arrow-width'           => $arrow_width,
		'arrow-tip-length'      => $arrow_tip_length,
		visibility              => 'hidden',
	);
}

sub create_pixelize_image {
	my ($mgr, $x, $y, $pixbuf, $blank) = @_;
	$blank //= 1;
	if ($blank) {
		my $b = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, 2, 2);
		$b->fill(0x00000000);
		$pixbuf = $b;
	}
	return GooCanvas2::CanvasImage->new(
		parent => $mgr->drawing_tool->canvas->get_root_item,
		pixbuf => $pixbuf,
		x      => $x,
		y      => $y,
		width  => 2,
		height => 2,
	);
}

sub create_pen_polyline {
	my ($mgr, $stroke, $line_width) = @_;
	return GooCanvas2::CanvasPolyline->new(
		parent                  => $mgr->drawing_tool->canvas->get_root_item,
		'close-path'            => FALSE,
		'stroke-color-gdk-rgba' => $stroke,
		'line-width'            => $line_width,
		'line-cap'              => 'CAIRO_LINE_CAP_ROUND',
		'line-join'             => 'CAIRO_LINE_JOIN_ROUND',
	);
}

sub create_highlighter_polyline {
	my ($mgr) = @_;
	my $hl_color = Gtk3::Gdk::RGBA::parse('#FFFF00');
	$hl_color->alpha(0.5);
	return GooCanvas2::CanvasPolyline->new(
		parent                  => $mgr->drawing_tool->canvas->get_root_item,
		'close-path'            => FALSE,
		'stroke-color-gdk-rgba' => $hl_color,
		'line-width'            => 18,
		'fill-rule'             => 'CAIRO_FILL_RULE_EVEN_ODD',
		'line-cap'              => 'CAIRO_LINE_CAP_SQUARE',
		'line-join'             => 'CAIRO_LINE_JOIN_BEVEL',
	);
}

sub increase_uid {
	my $mgr = shift;
	my $dt  = $mgr->drawing_tool;
	$dt->increase_uid;
}

1;
