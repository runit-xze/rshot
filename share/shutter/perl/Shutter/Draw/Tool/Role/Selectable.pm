package Shutter::Draw::Tool::Role::Selectable;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;

sub handle_item_selection_events {
	my ($self, $item, $target, $ev) = @_;
	my $dt = $self->drawing_tool;

	$dt->{_canvas}->pointer_ungrab($item, $ev->time);
	$dt->{_canvas}->keyboard_ungrab($item, $ev->time);

	#determine key for item hash
	if (my $child = $dt->get_child_item($item)) {
		$item = $child;
	}
	my $parent = $dt->get_parent_item($item);
	my $key    = $dt->get_item_key($item, $parent);

	#real shape
	if (defined $key && exists $dt->{_items}{$key}) {
		if ($ev->type eq '2button-press' && $ev->button == 1 && !$self->can('on_drag_creation_points') && !$self->can('is_text_tool')) {

			#some items do not have properties, e.g. images or censor
			return FALSE if $item->isa('GooCanvas2::CanvasImage') || !exists($dt->{_items}{$key}{stroke_color});

			$dt->show_item_properties($item, $parent, $key);

		} elsif ($ev->type eq 'button-press' && $ev->button == 3) {

			my $item_menu = $dt->ret_item_menu($item, $parent, $key);

			$item_menu->popup(
				undef,    # parent menu shell
				undef,    # parent menu item
				undef,    # menu pos func
				undef,    # data
				$ev->button,
				$ev->time
			);
		}

	} else {

		#background rectangle
		if ($item == $dt->{_canvas_bg_rect}) {
			my $bg_menu = $dt->ret_background_menu($item);

			$bg_menu->popup(
				undef,    # parent menu shell
				undef,    # parent menu item
				undef,    # menu pos func
				undef,    # data
				$ev->button,
				$ev->time
			);
		}
	}

	#canvas idle now
	$dt->{_busy} = FALSE;

	return TRUE;
}

1;
