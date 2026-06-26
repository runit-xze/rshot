package Shutter::Draw::ContextMenuManager;

use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

sub ret_background_menu {
	my ($self, $item) = @_;
	my $app = $self->drawing_tool;

	my $menu_bg = Gtk3::Menu->new;

	#properties
	my $prop_item = Gtk3::ImageMenuItem->new($app->_d->get("Change Background Color..."));
	$prop_item->set_image(Gtk3::Image->new_from_stock('gtk-select-color', 'menu'));
	$prop_item->signal_connect(
		'activate' => sub {
			my $color_dialog = Gtk3::ColorChooserDialog->new($app->_d->get("Choose fill color"));

			#add reset button
			my $reset_btn = Gtk3::Button->new_with_mnemonic($app->_d->get("_Reset to Default"));
			$color_dialog->add_action_widget($reset_btn, 'reject');

			$color_dialog->set_rgba($app->_canvas_bg_rect->{fill_color});

			$color_dialog->show_all;

			#run dialog
			my $response = 'reject';
			while ($response eq 'reject') {
				$response = $color_dialog->run;
				if ($response eq 'ok') {

					#apply new color
					$app->_canvas_bg_rect->{fill_color} = $color_dialog->get_rgba;
					$app->_canvas_bg_rect->{fill_color}->alpha(1);
					$app->_canvas_bg_rect->set('fill-color-gdk-rgba', $app->_canvas_bg_rect->{fill_color});
					last;
				} elsif ($response eq 'reject') {
					$color_dialog->set_rgba(Gtk3::Gdk::RGBA::parse('gray'));
				} else {
					last;
				}
			}

			$color_dialog->destroy;

		});

	$menu_bg->append($prop_item);

	$menu_bg->show_all;

	return $menu_bg;
}

sub ret_item_menu {
	my ($self, $item, $parent, $key) = @_;
	my $app = $self->drawing_tool;

	my $menu_item = Gtk3::Menu->new;

	#raise
	my $raise_item = Gtk3::ImageMenuItem->new($app->_d->get("Raise"));
	$raise_item->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size($app->_dicons . '/draw-raise.png', Gtk3::IconSize->lookup('menu'))));
	$raise_item->signal_connect(
		'activate' => sub {
			if ($parent) {

				#add to undo stack
				$app->store_to_xdo_stack($parent, 'raise', 'undo');
				$parent->raise;
				$item->raise;
				$app->handle_rects('raise', $parent);
			} else {

				#add to undo stack
				$app->store_to_xdo_stack($item, 'raise', 'undo');
				$item->raise;
				$app->handle_rects('raise', $item);
			}
		});

	$menu_item->append($raise_item);

	#lower
	my $lower_item = Gtk3::ImageMenuItem->new($app->_d->get("Lower"));
	$lower_item->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size($app->_dicons . '/draw-lower.png', Gtk3::IconSize->lookup('menu'))));

	$lower_item->signal_connect(
		'activate' => sub {
			if ($parent) {

				#add to undo stack
				$app->store_to_xdo_stack($parent, 'lower', 'undo');
				$app->handle_rects('lower', $parent);
				$item->lower;
				$parent->lower;
			} else {

				#add to undo stack
				$app->store_to_xdo_stack($item, 'lower', 'undo');
				$app->handle_rects('lower', $item);
				$item->lower;
			}
			$app->_canvas_bg->lower;
			$app->_canvas_bg_rect->lower;
		});

	$menu_item->append($lower_item);

	$menu_item->append(Gtk3::SeparatorMenuItem->new);

	#copy item
	my $copy_item = Gtk3::ImageMenuItem->new_from_stock('gtk-copy');

	$copy_item->signal_connect(
		'activate' => sub {

			#clear clipboard
			$app->_clipboard->set_text("");
			$app->_cut               = FALSE;
			$app->_current_copy_item = $app->_current_item;
		});

	$menu_item->append($copy_item);

	#cut item
	my $cut_item = Gtk3::ImageMenuItem->new_from_stock('gtk-cut');

	$cut_item->signal_connect(
		'activate' => sub {

			#clear clipboard
			$app->_clipboard->set_text("");
			$app->_cut               = TRUE;
			$app->_current_copy_item = $app->_current_item;
			$app->clear_item_from_canvas($app->_current_copy_item);
		});

	$menu_item->append($cut_item);

	#paste item
	my $paste_item = Gtk3::ImageMenuItem->new_from_stock('gtk-paste');

	$paste_item->signal_connect(
		'activate' => sub {
			$app->paste_item($app->_current_copy_item, $app->_cut);
			$app->_cut = FALSE;
		});

	$menu_item->append($paste_item);

	#delete item
	my $remove_item = Gtk3::ImageMenuItem->new_from_stock('gtk-delete');

	$remove_item->signal_connect(
		'activate' => sub {
			$app->clear_item_from_canvas($item);
		});

	$menu_item->append($remove_item);

	$menu_item->append(Gtk3::SeparatorMenuItem->new);

	#add lock/unlock entry if item == background image
	if ($item == $app->_canvas_bg) {

		my $lock_item = undef;
		if (exists $app->_items->{$key} && $app->_items->{$key}{locked} == TRUE) {
			$lock_item = Gtk3::ImageMenuItem->new_with_label($app->_d->get("Unlock"));
			$lock_item->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size($app->_dicons . '/draw-unlocked.png', Gtk3::IconSize->lookup('menu'))));
		} elsif (exists $app->_items->{$key} && $app->_items->{$key}{locked} == FALSE) {
			$lock_item = Gtk3::ImageMenuItem->new_with_label($app->_d->get("Lock"));
			$lock_item->set_image(Gtk3::Image->new_from_pixbuf(Gtk3::Gdk::Pixbuf->new_from_file_at_size($app->_dicons . '/draw-locked.png', Gtk3::IconSize->lookup('menu'))));
		}

		#handler
		$lock_item->signal_connect(
			'activate' => sub {

				if (exists $app->_items->{$key} && $app->_items->{$key}{locked} == FALSE) {
					$app->_items->{$key}{locked} = TRUE;
					$app->deactivate_all;
				} elsif (exists $app->_items->{$key} && $app->_items->{$key}{locked} == TRUE) {
					$app->_items->{$key}{locked} = FALSE;
				}

			});

		$menu_item->append($lock_item);

		$menu_item->append(Gtk3::SeparatorMenuItem->new);
	}

	#properties
	my $prop_item = Gtk3::ImageMenuItem->new($app->_d->get("Edit Preferences..."));
	$prop_item->set_image(Gtk3::Image->new_from_stock('gtk-properties', 'menu'));

	#some items do not have properties, e.g. images or censor
	$prop_item->set_sensitive(FALSE) if $item->isa('GooCanvas2::CanvasImage') || !exists($app->_items->{$key}{stroke_color});

	$prop_item->signal_connect(
		'activate' => sub {

			$app->show_item_properties($item, $parent, $key);

		});

	$menu_item->append($prop_item);

	$menu_item->show_all;

	return $menu_item;
}

1;
