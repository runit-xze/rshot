package Shutter::Draw::PropertyManager;

use v5.40;
no warnings "experimental::args_array_with_signatures";
no warnings "experimental::builtin";
use utf8;
use Moo;
use Glib qw(TRUE FALSE);
use Gtk3;

has drawing_tool => (
	is       => 'ro',
	required => 1,
);

use Shutter::Draw::Properties::Applier;

with qw(
	Shutter::Draw::Properties::Applier
);

sub show_item_properties {
	my $self = shift;
	my $dt   = $self->drawing_tool;
	my ($item, $parent, $key) = @_;

	#create dialog
	my $prop_dialog = Gtk3::Dialog->new(
		$dt->gettext()->get("Preferences"),
		$dt->drawing_window(),
		[qw/modal destroy-with-parent/],
		'gtk-cancel' => 'cancel',
		'gtk-ok'     => 'ok'
	);
	$prop_dialog->set_default_response('ok');

	#RECT OR ELLIPSE OR POLYLINE
	my $line_spin    = undef;
	my $fill_color   = undef;
	my $stroke_color = undef;

	#NUMBERED ELLIPSE
	my $number_spin = undef;

	#ARROW
	my $end_arrow   = undef;
	my $start_arrow = undef;
	my $arrow_spin  = undef;
	my $arrowl_spin = undef;
	my $arrowt_spin = undef;

	#TEXT
	my $font_btn;
	my $textview;
	my $font_color;

	#RECT OR ELLIPSE OR NUMBER OR POLYLINE
	#GENERAL SETTINGS
	if (   $item->isa('GooCanvas2::CanvasRect')
		|| $item->isa('GooCanvas2::CanvasEllipse')
		|| $item->isa('GooCanvas2::CanvasPolyline')
		|| ($item->isa('GooCanvas2::CanvasText') && defined $dt->items->{$key}{ellipse}))
	{

		my $general_vbox = Gtk3::VBox->new(FALSE, 5);

		my $label_general = Gtk3::Label->new;
		$label_general->set_markup("<b>" . $dt->gettext()->get("Main") . "</b>");
		my $frame_general = Gtk3::Frame->new();
		$frame_general->set_label_widget($label_general);
		$frame_general->set_shadow_type('none');
		$frame_general->set_border_width(5);
		$prop_dialog->get_child->add($frame_general);

		#line_width
		my $line_hbox = Gtk3::HBox->new(FALSE, 5);
		$line_hbox->set_border_width(5);
		my $linew_label = Gtk3::Label->new($dt->gettext()->get("Line width") . ":");
		$line_spin = Gtk3::SpinButton->new_with_range(0.5, 20, 0.1);

		$line_spin->set_value($item->get('line-width'));

		$line_hbox->pack_start($linew_label, FALSE, TRUE, 12);
		$line_hbox->pack_start($line_spin,   TRUE,  TRUE, 0);
		$general_vbox->pack_start($line_hbox, FALSE, FALSE, 0);

		if ($item->isa('GooCanvas2::CanvasRect') || $item->isa('GooCanvas2::CanvasEllipse')) {

			#fill color
			my $fill_color_hbox = Gtk3::HBox->new(FALSE, 5);
			$fill_color_hbox->set_border_width(5);
			my $fill_color_label = Gtk3::Label->new($dt->gettext()->get("Fill color") . ":");
			$fill_color = Gtk3::ColorButton->new();

			$fill_color->set_rgba($dt->items->{$key}{fill_color});
			$fill_color->set_use_alpha(TRUE);
			$fill_color->set_title($dt->gettext()->get("Choose fill color"));

			$fill_color_hbox->pack_start($fill_color_label, FALSE, TRUE, 12);
			$fill_color_hbox->pack_start($fill_color,       TRUE,  TRUE, 0);
			$general_vbox->pack_start($fill_color_hbox, FALSE, FALSE, 0);

		}

		#some items, e.g. censor tool, do not have a color - skip them
		if ($dt->items->{$key}{stroke_color}) {

			#stroke color
			my $stroke_color_hbox = Gtk3::HBox->new(FALSE, 5);
			$stroke_color_hbox->set_border_width(5);
			my $stroke_color_label = Gtk3::Label->new($dt->gettext()->get("Stroke color") . ":");
			$stroke_color = Gtk3::ColorButton->new();

			$stroke_color->set_rgba($dt->items->{$key}{stroke_color});
			$stroke_color->set_use_alpha(TRUE);
			$stroke_color->set_title($dt->gettext()->get("Choose stroke color"));

			$stroke_color_hbox->pack_start($stroke_color_label, FALSE, TRUE, 12);
			$stroke_color_hbox->pack_start($stroke_color,       TRUE,  TRUE, 0);
			$general_vbox->pack_start($stroke_color_hbox, FALSE, FALSE, 0);
		}

		$frame_general->add($general_vbox);

		#special shapes like numbered ellipse
		if (defined $dt->items->{$key}{text}) {

			my $numbered_vbox = Gtk3::VBox->new(FALSE, 5);

			my $label_numbered = Gtk3::Label->new;
			$label_numbered->set_markup("<b>" . $dt->gettext()->get("Numbering") . "</b>");
			my $frame_numbered = Gtk3::Frame->new();
			$frame_numbered->set_label_widget($label_numbered);
			$frame_numbered->set_shadow_type('none');
			$frame_numbered->set_border_width(5);
			$prop_dialog->get_child->add($frame_numbered);

			#current digit
			my $number_hbox = Gtk3::HBox->new(FALSE, 5);
			$number_hbox->set_border_width(5);
			my $numberw_label = Gtk3::Label->new($dt->gettext()->get("Current value") . ":");
			$number_spin = Gtk3::SpinButton->new_with_range(0, 999, 1);

			$number_spin->set_value($dt->items->{$key}{text}{digit});

			$number_hbox->pack_start($numberw_label, FALSE, TRUE, 12);
			$number_hbox->pack_start($number_spin,   TRUE,  TRUE, 0);
			$numbered_vbox->pack_start($number_hbox, FALSE, FALSE, 0);

			#font button
			my $font_hbox = Gtk3::HBox->new(FALSE, 5);
			$font_hbox->set_border_width(5);
			my $font_label = Gtk3::Label->new($dt->gettext()->get("Font") . ":");
			$font_btn = Gtk3::FontButton->new();

			#determine font description from string
			my ($ret, $attr_list, $text_raw, $accel_char) = Pango::parse_markup($dt->items->{$key}{text}->get('text'), -1, 0);
			my $font_desc = Pango::FontDescription->new();
			$attr_list->get_iterator->get_font($font_desc);

			#apply current font settings to button
			$font_btn->set_font_name($font_desc ? $font_desc->to_string : $dt->font());

			$font_hbox->pack_start($font_label, FALSE, TRUE, 12);
			$font_hbox->pack_start($font_btn,   TRUE,  TRUE, 0);
			$numbered_vbox->pack_start($font_hbox, FALSE, FALSE, 0);

			$frame_numbered->add($numbered_vbox);

		}

	}

	#ARROW item
	if (   $item->isa('GooCanvas2::CanvasPolyline')
		&& defined $dt->items->{$key}{end_arrow}
		&& defined $dt->items->{$key}{start_arrow})
	{
		my $arrow_vbox = Gtk3::VBox->new(FALSE, 5);

		my $label_arrow = Gtk3::Label->new;
		$label_arrow->set_markup("<b>" . $dt->gettext()->get("Arrow") . "</b>");
		my $frame_arrow = Gtk3::Frame->new();
		$frame_arrow->set_label_widget($label_arrow);
		$frame_arrow->set_shadow_type('none');
		$frame_arrow->set_border_width(5);
		$prop_dialog->get_child->add($frame_arrow);

		#arrow_width
		my $arrow_hbox = Gtk3::HBox->new(FALSE, 5);
		$arrow_hbox->set_border_width(5);
		my $arroww_label = Gtk3::Label->new($dt->gettext()->get("Width") . ":");
		$arrow_spin = Gtk3::SpinButton->new_with_range(0.5, 10, 0.1);

		$arrow_spin->set_value($item->get('arrow-width'));

		$arrow_hbox->pack_start($arroww_label, FALSE, TRUE,  12);
		$arrow_hbox->pack_start($arrow_spin,   TRUE,  TRUE,  0);
		$arrow_vbox->pack_start($arrow_hbox,   FALSE, FALSE, 0);

		#arrow_length
		my $arrowl_hbox = Gtk3::HBox->new(FALSE, 5);
		$arrowl_hbox->set_border_width(5);
		my $arrowl_label = Gtk3::Label->new($dt->gettext()->get("Length") . ":");
		$arrowl_spin = Gtk3::SpinButton->new_with_range(0.5, 10, 0.1);

		$arrowl_spin->set_value($item->get('arrow-length'));

		$arrowl_hbox->pack_start($arrowl_label, FALSE, TRUE, 12);
		$arrowl_hbox->pack_start($arrowl_spin,  TRUE,  TRUE, 0);
		$arrow_vbox->pack_start($arrowl_hbox, FALSE, FALSE, 0);

		#arrow_tip_length
		my $arrowt_hbox = Gtk3::HBox->new(FALSE, 5);
		$arrowt_hbox->set_border_width(5);
		my $arrowt_label = Gtk3::Label->new($dt->gettext()->get("Tip length") . ":");
		$arrowt_spin = Gtk3::SpinButton->new_with_range(0.5, 10, 0.1);

		$arrowt_spin->set_value($item->get('arrow-tip-length'));

		$arrowt_hbox->pack_start($arrowt_label, FALSE, TRUE, 12);
		$arrowt_hbox->pack_start($arrowt_spin,  TRUE,  TRUE, 0);
		$arrow_vbox->pack_start($arrowt_hbox, FALSE, FALSE, 0);

		#checkboxes for start and end arrows
		$end_arrow = Gtk3::CheckButton->new($dt->gettext()->get("Display an arrow at the end of the line"));
		$end_arrow->set_active($dt->items->{$key}{end_arrow});
		$start_arrow = Gtk3::CheckButton->new($dt->gettext()->get("Display an arrow at the start of the line"));
		$start_arrow->set_active($dt->items->{$key}{start_arrow});

		my $end_arrow_hbox = Gtk3::HBox->new(FALSE, 5);
		$end_arrow_hbox->set_border_width(5);

		my $start_arrow_hbox = Gtk3::HBox->new(FALSE, 5);
		$start_arrow_hbox->set_border_width(5);

		$end_arrow_hbox->pack_start($end_arrow, FALSE, TRUE, 12);
		$start_arrow_hbox->pack_start($start_arrow, FALSE, TRUE, 12);

		$arrow_vbox->pack_start($start_arrow_hbox, FALSE, FALSE, 0);
		$arrow_vbox->pack_start($end_arrow_hbox,   FALSE, FALSE, 0);

		#final packing
		$frame_arrow->add($arrow_vbox);

		#simple TEXT item (no numbered ellipse)
	} elsif ($item->isa('GooCanvas2::CanvasText')
		&& !defined $dt->items->{$key}{ellipse})
	{

		my $text_vbox = Gtk3::VBox->new(FALSE, 5);

		my $label_text = Gtk3::Label->new;
		$label_text->set_markup("<b>" . $dt->gettext()->get("Text") . "</b>");
		my $frame_text = Gtk3::Frame->new();
		$frame_text->set_label_widget($label_text);
		$frame_text->set_shadow_type('none');
		$frame_text->set_border_width(5);
		$prop_dialog->get_child->add($frame_text);

		#font button
		my $font_hbox = Gtk3::HBox->new(FALSE, 5);
		$font_hbox->set_border_width(5);
		my $font_label = Gtk3::Label->new($dt->gettext()->get("Font") . ":");
		$font_btn = Gtk3::FontButton->new();

		#determine font description from string
		my ($ret, $attr_list, $text_raw, $accel_char) = Pango::parse_markup($item->get('text'), -1, 0);
		my ($font_desc) = Pango::FontDescription::from_string($dt->font());

		$font_hbox->pack_start($font_label, FALSE, TRUE,  12);
		$font_hbox->pack_start($font_btn,   TRUE,  TRUE,  0);
		$text_vbox->pack_start($font_hbox,  FALSE, FALSE, 0);

		#font color
		my $font_color_hbox = Gtk3::HBox->new(FALSE, 5);
		$font_color_hbox->set_border_width(5);
		my $font_color_label = Gtk3::Label->new($dt->gettext()->get("Font color") . ":");
		$font_color = Gtk3::ColorButton->new();
		$font_color->set_use_alpha(TRUE);

		$font_color->set_rgba($dt->items->{$key}{stroke_color});
		$font_color->set_title($dt->gettext()->get("Choose font color"));

		$font_color_hbox->pack_start($font_color_label, FALSE, TRUE, 12);
		$font_color_hbox->pack_start($font_color,       TRUE,  TRUE, 0);

		$text_vbox->pack_start($font_color_hbox, FALSE, FALSE, 0);

		#initial buffer
		my $text = Gtk3::TextBuffer->new;
		$text->set_text($text_raw);

		#textview
		my $textview_hbox = Gtk3::HBox->new(FALSE, 5);
		$textview_hbox->set_border_width(5);
		$textview = Gtk3::TextView->new_with_buffer($text);
		$textview->set_can_focus(TRUE);
		$textview->set_size_request(150, 200);
		$textview_hbox->pack_start($textview, TRUE, TRUE, 0);

		$text_vbox->pack_start($textview_hbox, TRUE, TRUE, 0);

		#use font checkbox
		my $use_font = Gtk3::CheckButton->new_with_label($dt->gettext()->get("Use selected font"));
		$use_font->set_active(FALSE);

		$text_vbox->pack_start($use_font, TRUE, TRUE, 0);

		#use font color checkbox
		my $use_font_color = Gtk3::CheckButton->new_with_label($dt->gettext()->get("Use selected font color"));
		$use_font_color->set_active(FALSE);

		$text_vbox->pack_start($use_font_color, TRUE, TRUE, 0);

		#apply changes directly
		$use_font->signal_connect(
			'toggled' => sub {

				$self->modify_text_in_properties($font_btn, $textview, $font_color, $item, $use_font, $use_font_color);

			});

		$use_font_color->signal_connect(
			'toggled' => sub {

				$self->modify_text_in_properties($font_btn, $textview, $font_color, $item, $use_font, $use_font_color);

			});

		$font_btn->signal_connect(
			'font-set' => sub {

				$self->modify_text_in_properties($font_btn, $textview, $font_color, $item, $use_font, $use_font_color);

			});

		$font_color->signal_connect(
			'color-set' => sub {

				$self->modify_text_in_properties($font_btn, $textview, $font_color, $item, $use_font, $use_font_color);

			});

		#apply current font settings to button
		$font_btn->set_font_name($font_desc ? $font_desc->to_string : $dt->font());

		# set_font_name does not emit 'font-set' programmatically in GTK3, so we emit it manually.
		$font_btn->signal_emit('font-set');

		$frame_text->add($text_vbox);

	}

	#instant changes
	my $store_count = 0;
	if (defined $line_spin) {
		$line_spin->signal_connect(
			'value-changed' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $fill_color) {
		$fill_color->signal_connect(
			'color-set' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $stroke_color) {
		$stroke_color->signal_connect(
			'color-set' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $number_spin) {
		$number_spin->signal_connect(
			'value-changed' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $end_arrow) {
		$end_arrow->signal_connect(
			'toggled' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $start_arrow) {
		$start_arrow->signal_connect(
			'toggled' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $arrow_spin) {
		$arrow_spin->signal_connect(
			'value-changed' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $arrowl_spin) {
		$arrowl_spin->signal_connect(
			'value-changed' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $arrowt_spin) {
		$arrowt_spin->signal_connect(
			'value-changed' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $font_btn) {
		$font_btn->signal_connect(
			'font-set' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $font_color) {
		$font_color->signal_connect(
			'color-set' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);
				$store_count++;
			});
	}
	if (defined $textview) {
		$textview->signal_connect(
			'key-release-event' => sub {
				$self->apply_properties(
					$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
					$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
				);

				$store_count++;
			});
	}

	#layout adjustments
	my $sg_prop = Gtk3::SizeGroup->new('horizontal');
	foreach ($prop_dialog->get_children->get_children) {
		if ($_->can('get_children')) {
			foreach ($_->get_children) {
				if ($_->can('get_children')) {
					foreach ($_->get_children) {
						if ($_->can('get_children')) {
							foreach ($_->get_children) {
								if ($_ =~ /Gtk3::Label/) {

									#~ print $_->get_text, "\n";
									$_->set_alignment(0, 0.5);
									$sg_prop->add_widget($_);
								}
							}
						}
					}
				}
			}
		}
	}

	#run dialog
	$prop_dialog->show_all;

	#textview grab focus to be able to edit
	#immediately
	if (defined $textview) {
		$textview->grab_focus;
	}
	my $prop_dialog_res = $prop_dialog->run;
	if ($prop_dialog_res eq 'ok') {

		$self->apply_properties(
			$item,     $parent,    $key,         $fill_color, $stroke_color, $line_spin,   $font_color,  $font_btn,
			$textview, $end_arrow, $start_arrow, $arrow_spin, $arrowl_spin,  $arrowt_spin, $number_spin, $store_count
		);

		#apply item properties to widgets
		#line width, fill color, stroke color etc.
		$dt->set_and_save_drawing_properties($dt->current_item(), FALSE);

		# Save the new values into _last_* so the next drawn item uses them
		$dt->set_and_save_drawing_properties($dt->current_item(), TRUE);

		$prop_dialog->destroy;
		return TRUE;
	} else {

		if ($store_count) {
			$dt->xdo('undo', undef, TRUE);
		}

		$prop_dialog->destroy;
		return FALSE;
	}

}

1;
