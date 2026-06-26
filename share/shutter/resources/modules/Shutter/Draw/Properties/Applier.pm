package Shutter::Draw::Properties::Applier;

use v5.40;
no warnings "experimental::args_array_with_signatures";
no warnings "experimental::builtin";
use utf8;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;

requires qw(
	drawing_tool
);

sub apply_properties {
	my $self = shift;
	my $dt   = $self->drawing_tool;
	my (

		#item related infos
		$item,
		$parent,
		$key,

		#general properties
		$fill_color,
		$stroke_color,
		$line_spin,

		#only text
		$font_color,
		$font_btn,
		$textview,

		#only arrow
		$end_arrow,
		$start_arrow,
		$arrow_spin,
		$arrowl_spin,
		$arrowt_spin,

		#only numbered shapes
		$number_spin,

		#DO NOT STORE THE CHANGES (UNDO/REDO)
		$dont_store

	) = @_;

	#remember drawing colors, line width and font settings
	#maybe we have to restore them
	if (   $dt->items->{$key}{type} ne "highlighter"
		&& $dt->items->{$key}{type} ne "censor")
	{

		$dt->_last_fill_color($dt->fill_color_w->get_rgba);
		$dt->_last_stroke_color($dt->stroke_color_w->get_rgba);
		$dt->_last_line_width($dt->line_spin_w->get_value);
		$dt->_last_font($dt->font_btn_w->get_font_name);
		$dt->_last_mode($dt->current_mode);

	}

	#add to undo stack
	unless ($dont_store) {
		$dt->store_to_xdo_stack($dt->current_item(), 'modify', 'undo');
	}

	#apply rect or ellipse options
	if ($item->isa('GooCanvas2::CanvasRect') || $item->isa('GooCanvas2::CanvasEllipse')) {

		$item->set(
			'line-width'            => $line_spin->get_value,
			'fill-color-gdk-rgba'   => $fill_color->get_rgba,
			'stroke-color-gdk-rgba' => $stroke_color->get_rgba,
		);

		#special shapes like numbered ellipse (digit changed)
		if (defined $dt->items->{$key}{text}) {

			#determine new or current digit
			my $digit = undef;
			if (defined $number_spin) {
				$digit = $number_spin->get_value;
			} else {
				$digit = $dt->items->{$key}{text}{digit};
			}

			my $fill_color_local = undef;
			if (defined $font_color) {
				$fill_color_local = $font_color->get_rgba;
			} elsif (defined $stroke_color) {
				$fill_color_local = $stroke_color->get_rgba;
			}

			my $font_descr = Pango::FontDescription::from_string($font_btn->get_font_name);
			$dt->items->{$key}{text}->set(
				'text'                => "<span font_desc=' " . $font_btn->get_font_name . " ' >" . $digit . "</span>",
				'fill-color-gdk-rgba' => $fill_color_local,
			);

			#adjust parent rectangle
			my $tb = $dt->items->{$key}{text}->get_bounds;

			#keep ratio = 1
			my $qs = abs($tb->x1 - $tb->x2);
			$qs = abs($tb->y1 - $tb->y2) if abs($tb->y1 - $tb->y2) > abs($tb->x1 - $tb->x2);

			#add line width of parent ellipse
			$qs += $dt->items->{$key}{ellipse}->get('line-width') + 5;

			$parent->set(
				'width'  => $qs,
				'height' => $qs,
			);

			#save digit in hash as well (only item properties dialog)
			if (defined $number_spin) {
				$dt->items->{$key}{text}{digit} = $digit;
			}

			$dt->handle_rects('update', $parent);
			$dt->handle_embedded('update', $parent);

		}

		#save color and opacity as well
		$dt->items->{$key}{fill_color}   = $fill_color->get_rgba;
		$dt->items->{$key}{stroke_color} = $stroke_color->get_rgba;
	}

	#apply polyline options (arrow)
	if (   $item->isa('GooCanvas2::CanvasPolyline')
		&& defined $dt->items->{$key}{end_arrow}
		&& defined $dt->items->{$key}{start_arrow})
	{

		#these values are only available in the item menu
		if (   defined $arrowl_spin
			&& defined $arrow_spin
			&& defined $arrowt_spin
			&& defined $end_arrow
			&& defined $start_arrow)
		{
			$item->set(
				'line-width'            => $line_spin->get_value,
				'stroke-color-gdk-rgba' => $stroke_color->get_rgba,
				'end-arrow'             => $end_arrow->get_active,
				'start-arrow'           => $start_arrow->get_active,
				'arrow-length'          => $arrowl_spin->get_value,
				'arrow-width'           => $arrow_spin->get_value,
				'arrow-tip-length'      => $arrowt_spin->get_value,
			);

		} else {
			$item->set(
				'line-width'            => $line_spin->get_value,
				'stroke-color-gdk-rgba' => $stroke_color->get_rgba,
				'end-arrow'             => $dt->items->{$key}{line}->get('end-arrow'),
				'start-arrow'           => $dt->items->{$key}{line}->get('start-arrow'),
			);
		}

		#save color and opacity as well
		$dt->items->{$key}{stroke_color} = $stroke_color->get_rgba;

		#save arrow specific properties
		$dt->items->{$key}{end_arrow}        = $dt->items->{$key}{line}->get('end-arrow');
		$dt->items->{$key}{start_arrow}      = $dt->items->{$key}{line}->get('start-arrow');
		$dt->items->{$key}{arrow_width}      = $dt->items->{$key}{line}->get('arrow-width');
		$dt->items->{$key}{arrow_length}     = $dt->items->{$key}{line}->get('arrow-length');
		$dt->items->{$key}{arrow_tip_length} = $dt->items->{$key}{line}->get('arrow-tip-length');

		#apply polyline options (freehand, highlighter)
	} elsif ($item->isa('GooCanvas2::CanvasPolyline')
		&& defined $dt->items->{$key}{stroke_color})
	{
		$item->set(
			'line-width'            => $line_spin->get_value,
			'stroke-color-gdk-rgba' => $stroke_color->get_rgba,
		);

		#save color and opacity as well
		$dt->items->{$key}{stroke_color} = $stroke_color->get_rgba;
	}

	#apply text options
	if ($item->isa('GooCanvas2::CanvasText')) {
		my $font_descr = Pango::FontDescription::from_string($font_btn->get_font_name);

		my $new_text = undef;
		if ($textview) {
			$new_text = $textview->get_buffer->get_text($textview->get_buffer->get_start_iter, $textview->get_buffer->get_end_iter, FALSE)
				|| " ";
		} else {

			#determine font description and text from string
			my ($ret, $attr_list, $text_raw, $accel_char) = Pango::parse_markup($item->get('text'), -1, 0);
			$new_text = $text_raw;
		}

		$item->set(
			'text'                => "<span font_desc=' " . $font_btn->get_font_name . " ' >" . Glib::Markup::escape_text($new_text) . "</span>",
			'width'               => -1,
			'use-markup'          => TRUE,
			'fill-color-gdk-rgba' => $font_color->get_rgba,
		);

		#adjust parent rectangle
		my $tb = $item->get_bounds;
		$parent->set(
			'width'  => abs($tb->x1 - $tb->x2),
			'height' => abs($tb->y1 - $tb->y2),
		);

		$dt->handle_rects('update', $parent);
		$dt->handle_embedded('update', $parent);

		#save color and opacity as well
		$dt->items->{$key}{stroke_color} = $font_color->get_rgba;

	}
	return;

}

sub modify_text_in_properties ($self, $font_btn, $textview, $font_color, $item, $use_font, $use_font_color) {
	my $font_descr = Pango::FontDescription::from_string($font_btn->get_font_name);
	my $texttag    = Gtk3::TextTag->new;

	if ($use_font->get_active && $use_font_color->get_active) {
		$texttag->set('font-desc' => $font_descr, 'foreground-rgba' => $font_color->get_rgba);
	} elsif ($use_font->get_active) {
		$texttag->set('font-desc' => $font_descr);
	} elsif ($use_font_color->get_active) {
		$texttag->set('foreground-rgba' => $font_color->get_rgba);
	}

	my $texttagtable = Gtk3::TextTagTable->new;
	$texttagtable->add($texttag);
	my $text = Gtk3::TextBuffer->new($texttagtable);
	$text->signal_connect(
		'changed' => sub {
			$text->apply_tag($texttag, $text->get_start_iter, $text->get_end_iter);
		});

	$text->set_text($textview->get_buffer->get_text($textview->get_buffer->get_start_iter, $textview->get_buffer->get_end_iter, FALSE));
	$text->apply_tag($texttag, $text->get_start_iter, $text->get_end_iter);
	$textview->set_buffer($text);

	return TRUE;
}

1;
