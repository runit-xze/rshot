package Shutter::App::UI::Settings::Plugins;

use utf8;
use v5.40;
use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has cli   => (is => 'ro', required => 1);
has _vbox => (is => 'rw');

sub BUILD ($self, $args) {
	my $sc = $self->cli->sc;
	my $d  = $sc->gettext_object;
	my $sm = $self->cli->{settings_manager};

	my $vbox_main = Gtk3::VBox->new(FALSE, 12);
	$vbox_main->set_border_width(5);

	# --- Plugins Frame ---
	my $plugins_frame       = Gtk3::Frame->new;
	my $plugins_frame_label = Gtk3::Label->new;
	$plugins_frame_label->set_markup("<b>" . $d->get("Plugins") . "</b>");
	$plugins_frame->set_label_widget($plugins_frame_label);
	$plugins_frame->set_shadow_type('none');

	my $plugins_vbox = Gtk3::VBox->new(FALSE, 6);
	$plugins_vbox->set_border_width(6);

	my $info_label = Gtk3::Label->new($d->get("Enabled Shutter Plugins"));
	$info_label->set_halign('start');
	$plugins_vbox->pack_start($info_label, FALSE, FALSE, 0);

	# Create a simple list view for plugins
	my $list_store = Gtk3::ListStore->new('Glib::String', 'Glib::String', 'Glib::String');
	my $tree_view  = Gtk3::TreeView->new_with_model($list_store);

	my $renderer = Gtk3::CellRendererText->new;
	my $col_name = Gtk3::TreeViewColumn->new_with_attributes($d->get("Plugin Name"), $renderer, text => 0);
	my $col_cat  = Gtk3::TreeViewColumn->new_with_attributes($d->get("Category"),    $renderer, text => 1);
	my $col_desc = Gtk3::TreeViewColumn->new_with_attributes($d->get("Description"), $renderer, text => 2);

	$tree_view->append_column($col_name);
	$tree_view->append_column($col_cat);
	$tree_view->append_column($col_desc);

	my $sw = Gtk3::ScrolledWindow->new;
	$sw->set_policy('automatic', 'automatic');
	$sw->set_min_content_height(200);
	$sw->add($tree_view);

	$plugins_vbox->pack_start($sw, TRUE, TRUE, 0);

	# Populate plugins from settings
	my $plugins_ref = $sm->get_setting('plugins', 'name');
	if ($plugins_ref && ref($plugins_ref) eq 'ARRAY') {

		# XML::Simple parses multiple plugins as an array under some structures
		# We will attempt to list them.
		foreach my $p (@$plugins_ref) {
			my $iter = $list_store->append;
			$list_store->set($iter, 0, $p // 'Unknown', 1, 'Effect', 2, 'Loaded from settings');
		}
	} else {

		# Fallback to manual parsing if we have direct access to plugins hash
		my $settings = $sm->_settings;
		if (exists $settings->{plugins} && ref($settings->{plugins}) eq 'ARRAY') {
			foreach my $p (@{$settings->{plugins}}) {
				my $iter = $list_store->append;
				$list_store->set($iter, 0, $p->{name_plugin} // 'Unknown', 1, $p->{category} // '', 2, $p->{tooltip} // '');
			}
		} elsif (exists $settings->{plugins} && ref($settings->{plugins}) eq 'HASH') {
			my $p    = $settings->{plugins};
			my $iter = $list_store->append;
			$list_store->set($iter, 0, $p->{name_plugin} // 'Unknown', 1, $p->{category} // '', 2, $p->{tooltip} // '');
		}
	}

	$plugins_frame->add($plugins_vbox);
	$vbox_main->pack_start($plugins_frame, TRUE, TRUE, 3);

	$self->_vbox($vbox_main);
	return;
}

sub get_widget ($self) {
	return $self->_vbox;
}

sub save ($self) {

	# Plugins are read-only in this UI for now, enabled via scanning
}

1;
