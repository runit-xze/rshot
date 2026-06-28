package Shutter::Draw::Tool::ModeManager;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;

use constant {
	MODE_SELECT      => 10,
	MODE_FREEHAND    => 20,
	MODE_HIGHLIGHTER => 30,
	MODE_LINE        => 40,
	MODE_ARROW       => 50,
	MODE_RECT        => 60,
	MODE_ELLIPSE     => 70,
	MODE_TEXT        => 80,
	MODE_CENSOR      => 90,
	MODE_PIXELIZE    => 100,
	MODE_NUMBER      => 110,
	MODE_CROP        => 120,
};

requires qw(
	drawing_tool
);

sub add_radio_actions ($self, $entries) {
	$self->{_actiongroup_tools}->add_radio_actions($entries, MODE_SELECT, sub { my ($action, $current, $manager) = @_; $manager->change_drawing_tool_cb($action) }, $self);
	return;
}

sub change_drawing_tool_cb ($self, $action) {
	my $app = $self->drawing_tool;

	eval { $app->_current_mode($action->get_current_value); };
	if ($@) {
		$app->_current_mode($action);
	}

	my $cursor = Gtk3::Gdk::Cursor->new('left-ptr');

	if (   $app->_current_mode != $app->_last_mode
		&& $app->_current_mode != MODE_SELECT
		&& $app->_current_mode != MODE_HIGHLIGHTER
		&& $app->_current_mode != MODE_CENSOR
		&& $app->_current_mode != MODE_PIXELIZE
		&& $app->_current_mode != MODE_CROP)
	{
		$app->restore_drawing_properties;
	}

	if ($app->_current_mode != MODE_CROP) {
		$app->_table->show_all;
		$app->_bhbox->show_all;
		$app->_drawing_inner_vbox->show_all;
		$app->_drawing_inner_vbox_c->hide;
	}

	$app->_fill_color_w->set_sensitive(TRUE);
	$app->_stroke_color_w->set_sensitive(TRUE);
	$app->_line_spin_w->set_sensitive(TRUE);
	$app->_font_btn_w->set_sensitive(TRUE);

	if ($app->_current_mode == MODE_SELECT) {
		$app->_current_mode_descr("select");
	} elsif ($app->_current_mode == MODE_FREEHAND) {
		$app->_current_mode_descr("freehand");
		$app->_fill_color_w->set_sensitive(FALSE);
		$app->_font_btn_w->set_sensitive(FALSE);
	} elsif ($app->_current_mode == MODE_HIGHLIGHTER) {
		$app->_current_mode_descr("highlighter");
		$cursor = Gtk3::Gdk::Cursor->new('dotbox');
		$app->_fill_color_w->set_sensitive(FALSE);
		$app->_font_btn_w->set_sensitive(FALSE);
		$app->restore_fixed_properties($app->_current_mode_descr);
	} elsif ($app->_current_mode == MODE_LINE) {
		$app->_current_mode_descr("line");
		$app->_fill_color_w->set_sensitive(FALSE);
		$app->_font_btn_w->set_sensitive(FALSE);
	} elsif ($app->_current_mode == MODE_ARROW) {
		$app->_current_mode_descr("arrow");
		$app->_fill_color_w->set_sensitive(FALSE);
		$app->_font_btn_w->set_sensitive(FALSE);
	} elsif ($app->_current_mode == MODE_RECT) {
		$app->_current_mode_descr("rect");
		$app->_font_btn_w->set_sensitive(FALSE);
	} elsif ($app->_current_mode == MODE_ELLIPSE) {
		$app->_current_mode_descr("ellipse");
		$app->_font_btn_w->set_sensitive(FALSE);
	} elsif ($app->_current_mode == MODE_TEXT) {
		$app->_current_mode_descr("text");
		$app->_fill_color_w->set_sensitive(FALSE);
		$app->_line_spin_w->set_sensitive(FALSE);
	} elsif ($app->_current_mode == MODE_CENSOR) {
		$app->_current_mode_descr("censor");
		$app->_fill_color_w->set_sensitive(FALSE);
		$app->_stroke_color_w->set_sensitive(FALSE);
		$app->_line_spin_w->set_sensitive(FALSE);
		$app->_font_btn_w->set_sensitive(FALSE);
		$app->restore_fixed_properties($app->_current_mode_descr);
	} elsif ($app->_current_mode == MODE_PIXELIZE) {
		$app->_current_mode_descr("pixelize");
		$app->_fill_color_w->set_sensitive(FALSE);
		$app->_stroke_color_w->set_sensitive(FALSE);
		$app->_line_spin_w->set_sensitive(FALSE);
		$app->_font_btn_w->set_sensitive(FALSE);
	} elsif ($app->_current_mode == MODE_NUMBER) {
		$app->_current_mode_descr("number");
	} elsif ($app->_current_mode == MODE_CROP) {
		$app->_current_mode_descr("crop");
		$app->_view->set_pixbuf($app->save(TRUE));
		$app->_view->set_zoom(1);
		my $color_string = $app->_canvas_bg_rect->{fill_color}->to_string;
		$app->_view_css_provider_alpha->load_from_data("
            GtkImageView {
                background-color: $color_string;
            }
        ");
		$cursor = Gtk3::Gdk::Cursor->new('crosshair');
		$app->_drawing_inner_vbox_c->show_all;
		$app->_table->hide;
		$app->_bhbox->hide;
	}

	if (defined $app->_current_item) {
		if ($app->_current_mode_descr ne "select" || $app->_last_mode == MODE_CROP) {
			$app->deactivate_all;
		}
	}

	$app->_last_mode($app->_current_mode);

	if (defined $app->_canvas && $app->_current_mode != MODE_CROP) {
		$app->_canvas->get_window->set_cursor($cursor);
	}

	if (defined $app->_canvas && $app->_current_mode == MODE_CROP) {
		$app->_view->get_window->set_cursor($cursor);
	}

	$app->_canvas_manager->set_tool($app->_current_mode_descr);
	return;
}

1;
