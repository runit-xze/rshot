package Shutter::Draw::SettingsManager;

use v5.40;
use utf8;
use Moo;
use XML::Simple;
use IO::File;
use Glib qw(TRUE FALSE);
use Gtk3;
use Pango;

has drawing_tool => (
	is       => 'ro',
	required => 1,
);

sub load_settings {
	my $self = shift;
	my $dt   = $self->drawing_tool;

	my $shutter_hfunct = Shutter::App::HelperFunctions->new($dt->_sc);

	#settings file
	my $settingsfile = "$ENV{ HOME }/.shutter/drawingtool.xml";

	my $settings_xml;
	if ($shutter_hfunct->file_exists($settingsfile)) {
		eval {
			$settings_xml = XMLin(IO::File->new($settingsfile));

			#restore window state when maximized
			if (exists $settings_xml->{'drawing'}->{'state'} && defined $settings_xml->{'drawing'}->{'state'} && $settings_xml->{'drawing'}->{'state'} eq 'maximized') {
				$dt->drawing_window->maximize;
			}

			#window size and position
			if ($settings_xml->{'drawing'}->{'x'} && $settings_xml->{'drawing'}->{'y'}) {
				$dt->drawing_window->move($settings_xml->{'drawing'}->{'x'}, $settings_xml->{'drawing'}->{'y'});
			}

			if ($settings_xml->{'drawing'}->{'width'} && $settings_xml->{'drawing'}->{'height'}) {
				$dt->drawing_window->resize($settings_xml->{'drawing'}->{'width'}, $settings_xml->{'drawing'}->{'height'});
			}

			#current mode
			if ($settings_xml->{'drawing'}->{'mode'}) {
				$dt->current_mode($settings_xml->{'drawing'}->{'mode'});
			}

			#autoscroll
			my $autoscroll_toggle = $dt->uimanager->get_widget("/MenuBar/Edit/Autoscroll");
			$autoscroll_toggle->set_active($settings_xml->{'drawing'}->{'autoscroll'});

			#drawing colors
			my $fill = Gtk3::Gdk::RGBA::parse($settings_xml->{'drawing'}->{'fill_color'}) // Gtk3::Gdk::RGBA::parse('black');
			$fill->alpha($settings_xml->{'drawing'}->{'fill_color_alpha'});
			$dt->fill_color($fill);

			my $stroke = Gtk3::Gdk::RGBA::parse($settings_xml->{'drawing'}->{'stroke_color'}) // Gtk3::Gdk::RGBA::parse('black');
			$stroke->alpha($settings_xml->{'drawing'}->{'stroke_color_alpha'});
			$dt->stroke_color($stroke);

			#line_width
			$dt->line_width($settings_xml->{'drawing'}->{'line_width'});

			#font
			$dt->font($settings_xml->{'drawing'}->{'font'});

		};
		if ($@) {
			warn "ERROR: Settings of DrawingTool could not be restored: $@ - ignoring\n";
		}
	}
	return TRUE;
}

sub save_settings {
	my $self = shift;
	my $dt   = $self->drawing_tool;

	#to avoid saving the properties of the highlighter
	#this does not make any sense
	$self->restore_drawing_properties;

	#settings file
	my $settingsfile = "$ENV{ HOME }/.shutter/drawingtool.xml";

	#hash to store settings
	my %settings;

	#window size and position
	if (defined $dt->drawing_window->get_window) {
		if ($dt->drawing_window->get_window->get_state eq 'GDK_WINDOW_STATE_MAXIMIZED') {
			$settings{'drawing'}->{'state'} = 'maximized';
		}
	}

	my ($w, $h) = $dt->drawing_window->get_size;
	my ($x, $y) = $dt->drawing_window->get_position;
	$settings{'drawing'}->{'x'}      = $x;
	$settings{'drawing'}->{'y'}      = $y;
	$settings{'drawing'}->{'width'}  = $w;
	$settings{'drawing'}->{'height'} = $h;

	#current action
	#but don't save the crop tool as last action
	#as it would be confusing to open the drawing tool
	#with crop tool enabled
	if ($dt->current_mode_descr ne "crop") {
		$settings{'drawing'}->{'mode'} = $dt->current_mode;
	} else {
		$settings{'drawing'}->{'mode'} = 10;
	}

	#autoscroll
	my $autoscroll_toggle = $dt->uimanager->get_widget("/MenuBar/Edit/Autoscroll");
	$settings{'drawing'}->{'autoscroll'} = $autoscroll_toggle->get_active();

	#drawing colors
	$settings{'drawing'}->{'fill_color'}         = sprintf("#%04x%04x%04x", $dt->fill_color->red * 65535, $dt->fill_color->green * 65535, $dt->fill_color->blue * 65535);
	$settings{'drawing'}->{'fill_color_alpha'}   = $dt->fill_color->alpha;
	$settings{'drawing'}->{'stroke_color'}       = sprintf("#%04x%04x%04x", $dt->stroke_color->red * 65535, $dt->stroke_color->green * 65535, $dt->stroke_color->blue * 65535);
	$settings{'drawing'}->{'stroke_color_alpha'} = $dt->stroke_color->alpha;

	#line_width
	$settings{'drawing'}->{'line_width'} = $dt->line_width;

	#font
	$settings{'drawing'}->{'font'} = $dt->font;

	eval {

		#save to file
		require Path::Tiny;
		Path::Tiny::path($settingsfile)->spew_utf8(XMLout(\%settings));

	};
	if ($@) {
		warn "ERROR: Settings of DrawingTool could not be saved: $@ - ignoring\n";
	}

	return TRUE;
}

sub set_and_save_drawing_properties {
	my ($self, $item, $save_only) = @_;
	my $dt = $self->drawing_tool;

	return FALSE unless $item;

	#determine key for item hash
	if (my $child = $dt->get_child_item($item)) {
		$item = $child;
	}
	my $parent = $dt->get_parent_item($item);
	my $key    = $dt->get_item_key($item, $parent);

	return FALSE unless $key;

	#we do not remember the properties for some tools
	#and don't remember them when just selecting items with the cursor
	if (   $dt->items->{$key}{type} ne "highlighter"
		&& $dt->items->{$key}{type} ne "censor"
		&& $dt->items->{$key}{type} ne "image"
		&& $dt->items->{$key}{type} ne "pixelize"
		&& $dt->current_mode != 10)
	{

		#remember drawing colors, line width and font settings
		#maybe we have to restore them
		$dt->_last_fill_color($dt->fill_color_w->get_rgba);
		$dt->_last_stroke_color($dt->stroke_color_w->get_rgba);
		$dt->_last_line_width($dt->line_spin_w->get_value);
		$dt->_last_font($dt->font_btn_w->get_font_name);

		#remember the last mode as well
		$dt->_last_mode($dt->current_mode);

	}

	return TRUE if $save_only;

	#block 'value-change' handlers for widgets
	#so we do not apply the changes twice
	$dt->line_spin_w->signal_handler_block($dt->line_spin_wh);
	$dt->stroke_color_w->signal_handler_block($dt->stroke_color_wh);
	$dt->fill_color_w->signal_handler_block($dt->fill_color_wh);
	$dt->font_btn_w->signal_handler_block($dt->font_btn_wh);

	if (   $item->isa('GooCanvas2::CanvasRect')
		|| $item->isa('GooCanvas2::CanvasEllipse')
		|| $item->isa('GooCanvas2::CanvasPolyline'))
	{

		#line width
		$dt->line_spin_w->set_value($item->get('line-width'));

		#stroke color
		#some items, e.g. censor tool, do not have a color - skip them
		if ($dt->items->{$key}{stroke_color}) {
			$dt->stroke_color_w->set_rgba($dt->items->{$key}{stroke_color});
		}

		if ($item->isa('GooCanvas2::CanvasRect') || $item->isa('GooCanvas2::CanvasEllipse')) {

			#fill color
			$dt->fill_color_w->set_rgba($dt->items->{$key}{fill_color});

			#numbered shapes
			if (exists($dt->items->{$key}{text})) {

				#determine font description from string
				my ($ret, $attr_list, $text_raw, $accel_char) = Pango::parse_markup($dt->items->{$key}{text}->get('text'), -1, 0);
				my $font_desc = Pango::FontDescription->new();
				$attr_list->get_iterator->get_font($font_desc);

				#apply current font settings to button
				$dt->font_btn_w->set_font_name($font_desc ? $font_desc->to_string : $dt->font);

			}
		}

	} elsif ($item->isa('GooCanvas2::CanvasText')) {

		#determine font description from string
		my ($ret, $attr_list, $text_raw, $accel_char) = Pango::parse_markup($item->get('text'), -1, 0);
		my $font_desc = Pango::FontDescription->new();
		$attr_list->get_iterator->get_font($font_desc);

		#font color
		$dt->stroke_color_w->set_rgba($dt->items->{$key}{stroke_color});

		#apply current font settings to button
		$dt->font_btn_w->set_font_name($font_desc ? $font_desc->to_string : $dt->font);

	}

	#update global values
	$dt->line_width($dt->line_spin_w->get_value);
	$dt->stroke_color($dt->stroke_color_w->get_rgba);
	$dt->fill_color($dt->fill_color_w->get_rgba);
	my $font_descr = Pango::FontDescription->from_string($dt->font_btn_w->get_font_name);
	$dt->font($dt->font_btn_w->get_font_name);

	#unblock 'value-change' handlers for widgets
	$dt->line_spin_w->signal_handler_unblock($dt->line_spin_wh);
	$dt->stroke_color_w->signal_handler_unblock($dt->stroke_color_wh);
	$dt->fill_color_w->signal_handler_unblock($dt->fill_color_wh);
	$dt->font_btn_w->signal_handler_unblock($dt->font_btn_wh);
	return;

}

sub restore_fixed_properties {
	my ($self, $mode) = @_;
	my $dt = $self->drawing_tool;

	#block 'value-change' handlers for widgets
	#so we do not apply the changes twice
	$dt->line_spin_w->signal_handler_block($dt->line_spin_wh);
	$dt->stroke_color_w->signal_handler_block($dt->stroke_color_wh);
	$dt->fill_color_w->signal_handler_block($dt->fill_color_wh);
	$dt->font_btn_w->signal_handler_block($dt->font_btn_wh);

	if ($mode eq "highlighter") {

		#highlighter
		my $fill_color = Gtk3::Gdk::RGBA::parse('#00000000ffff');
		$fill_color->alpha(0.234683756771191);
		$dt->fill_color_w->set_rgba($fill_color);
		my $stroke_color = Gtk3::Gdk::RGBA::parse('#ffffffff0000');
		$stroke_color->alpha(0.499992370489052);
		$dt->stroke_color_w->set_rgba($stroke_color);
		$dt->line_spin_w->set_value(18);
	} elsif ($mode eq "censor") {

		#censor
		$dt->line_spin_w->set_value(14);
	}

	#update global values
	$dt->line_width($dt->line_spin_w->get_value);
	$dt->stroke_color($dt->stroke_color_w->get_rgba);
	$dt->fill_color($dt->fill_color_w->get_rgba);

	#unblock 'value-change' handlers for widgets
	$dt->line_spin_w->signal_handler_unblock($dt->line_spin_wh);
	$dt->stroke_color_w->signal_handler_unblock($dt->stroke_color_wh);
	$dt->fill_color_w->signal_handler_unblock($dt->fill_color_wh);
	$dt->font_btn_w->signal_handler_unblock($dt->font_btn_wh);
	return;

}

sub restore_drawing_properties {
	my $self = shift;
	my $dt   = $self->drawing_tool;

	#saved properties available?
	return FALSE unless defined $dt->_last_fill_color;

	#anything done until now?
	return FALSE unless defined $dt->_last_mode;

	#block 'value-change' handlers for widgets
	#so we do not apply the changes twice
	$dt->line_spin_w->signal_handler_block($dt->line_spin_wh);
	$dt->stroke_color_w->signal_handler_block($dt->stroke_color_wh);
	$dt->fill_color_w->signal_handler_block($dt->fill_color_wh);
	$dt->font_btn_w->signal_handler_block($dt->font_btn_wh);

	#restore them
	$dt->fill_color_w->set_rgba($dt->_last_fill_color);
	$dt->stroke_color_w->set_rgba($dt->_last_stroke_color);
	$dt->line_spin_w->set_value($dt->_last_line_width);
	$dt->font_btn_w->set_font_name($dt->_last_font);

	#update global values
	$dt->line_width($dt->line_spin_w->get_value);
	$dt->stroke_color($dt->stroke_color_w->get_rgba);
	$dt->fill_color($dt->fill_color_w->get_rgba);
	my $font_name  = $dt->font_btn_w->get_font_name // 'Sans 10';
	my $font_descr = Pango::FontDescription->from_string($font_name);
	$dt->font($font_name);

	#unblock 'value-change' handlers for widgets
	$dt->line_spin_w->signal_handler_unblock($dt->line_spin_wh);
	$dt->stroke_color_w->signal_handler_unblock($dt->stroke_color_wh);
	$dt->fill_color_w->signal_handler_unblock($dt->fill_color_wh);
	$dt->font_btn_w->signal_handler_unblock($dt->font_btn_wh);
	return;

}

1;
