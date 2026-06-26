###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2025 Shutter Team
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  Shutter is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
###################################################

package Shutter::App::Handlers::Dialogs_Plugin;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub dlg_plugin ($self, @file_to_plugin_keys) {
	my $cli     = $self->cli;
	my $d       = $cli->sc->gettext_object;
	my $window  = $cli->window;
	my $plugins = $cli->{_plugins} || {};
	my $shf     = $cli->shf;
	my $lp      = $cli->{_lp};
	my $sd      = $cli->sc->{_sd};

	my $plugin_dialog = Gtk3::Dialog->new($d->get("Choose a plugin"), $window, [qw/modal destroy-with-parent/]);
	$plugin_dialog->set_size_request(350, -1);
	$plugin_dialog->set_resizable(FALSE);

	#rename button
	my $run_btn = Gtk3::Button->new_with_mnemonic($d->get("_Run"));
	$run_btn->set_image(Gtk3::Image->new_from_stock('gtk-execute', 'button'));
	$run_btn->set_can_default(TRUE);

	$plugin_dialog->add_button('gtk-cancel', 'reject');
	$plugin_dialog->add_action_widget($run_btn, 'accept');

	$plugin_dialog->set_default_response('accept');

	my $model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String');

	#temp variables to restore the
	#recent plugin
	my $recent_time        = 0;
	my $iter_lastex_plugin = undef;
	foreach my $pkey (sort keys %$plugins) {

		if ($plugins->{$pkey}->{'binary'} ne "") {

			my $new_iter = $model->append;
			$model->set(
				$new_iter, 0, $plugins->{$pkey}->{'pixbuf_object'}, 1, $plugins->{$pkey}->{'name'}, 2, $plugins->{$pkey}->{'binary'}, 3,
				$plugins->{$pkey}->{'lang'}, 4, $plugins->{$pkey}->{'tooltip'}, 5, $pkey
			);

			#initialize $iter_lastex_plugin
			#with first new iter
			$iter_lastex_plugin = $new_iter
				unless defined $iter_lastex_plugin;

			#restore the recent plugin
			#($plugins->{$plugin_key}->{'recent'} is a timestamp)
			#
			#we keep the new_iter in mind
			if (defined $plugins->{$pkey}->{'recent'}
				&& $plugins->{$pkey}->{'recent'} > $recent_time)
			{
				$iter_lastex_plugin = $new_iter;
				$recent_time        = $plugins->{$pkey}->{'recent'};
			}

		} else {
			print "WARNING: Program $pkey is not configured properly, ignoring\n";
		}

	}

	my $plugin_label = Gtk3::Label->new($d->get("Plugin") . ":");
	my $plugin       = Gtk3::ComboBox->new_with_model($model);

	#plugin description
	my $plugin_descr      = Gtk3::TextBuffer->new;
	my $plugin_descr_view = Gtk3::TextView->new_with_buffer($plugin_descr);
	$plugin_descr_view->set_sensitive(FALSE);
	$plugin_descr_view->set_wrap_mode('word');
	my $textview_hbox = Gtk3::HBox->new(FALSE, 5);
	$textview_hbox->set_border_width(8);
	$textview_hbox->pack_start($plugin_descr_view, TRUE, TRUE, 0);

	my $plugin_descr_label = Gtk3::Label->new();
	$plugin_descr_label->set_markup("<b>" . $d->get("Description") . "</b>");
	my $plugin_descr_frame = Gtk3::Frame->new();
	$plugin_descr_frame->set_label_widget($plugin_descr_label);
	$plugin_descr_frame->set_shadow_type('none');
	$plugin_descr_frame->add($textview_hbox);

	#plugin image
	my $plugin_image = Gtk3::Image->new;

	#packing
	my $plugin_vbox1 = Gtk3::VBox->new(FALSE, 5);
	my $plugin_hbox1 = Gtk3::HBox->new(FALSE, 5);
	my $plugin_hbox2 = Gtk3::HBox->new(FALSE, 5);
	$plugin_hbox2->set_border_width(10);

	#what plugin is selected?
	my $plugin_pixbuf = undef;
	my $plugin_name   = undef;
	my $plugin_value  = undef;
	my $plugin_lang   = undef;
	my $plugin_tip    = undef;
	my $plugin_key    = undef;
	$plugin->signal_connect(
		'changed' => sub {
			my $model       = $plugin->get_model();
			my $plugin_iter = $plugin->get_active_iter();

			if ($plugin_iter) {
				$plugin_pixbuf = $model->get_value($plugin_iter, 0);
				$plugin_name   = $model->get_value($plugin_iter, 1);
				$plugin_value  = $model->get_value($plugin_iter, 2);
				$plugin_lang   = $model->get_value($plugin_iter, 3);
				$plugin_tip    = $model->get_value($plugin_iter, 4);
				$plugin_key    = $model->get_value($plugin_iter, 5);

				$plugin_descr->set_text($plugin_tip);
				if ($shf->file_exists($plugins->{$plugin_key}->{'pixbuf'})) {
					$plugin_image->set_from_pixbuf($lp->load($plugins->{$plugin_key}->{'pixbuf'}, 100, 100));
				}
			}
		});

	my $renderer_pix = Gtk3::CellRendererPixbuf->new;
	$plugin->pack_start($renderer_pix, FALSE);
	$plugin->add_attribute($renderer_pix, pixbuf => 0);
	my $renderer_text = Gtk3::CellRendererText->new;
	$plugin->pack_start($renderer_text, FALSE);
	$plugin->add_attribute($renderer_text, text => 1);

	#we try to activate the last executed plugin if that's possible
	$plugin->set_active_iter($iter_lastex_plugin);

	$plugin_hbox1->pack_start($plugin, TRUE, TRUE, 0);

	$plugin_hbox2->pack_start($plugin_image,       TRUE, TRUE, 0);
	$plugin_hbox2->pack_start($plugin_descr_frame, TRUE, TRUE, 0);

	$plugin_vbox1->pack_start($plugin_hbox1, FALSE, TRUE, 1);
	$plugin_vbox1->pack_start($plugin_hbox2, TRUE,  TRUE, 1);

	$plugin_dialog->get_child->add($plugin_vbox1);

	my $plugin_progress = Gtk3::ProgressBar->new;
	$plugin_progress->set_no_show_all(TRUE);
	$plugin_progress->set_ellipsize('middle');
	$plugin_progress->set_orientation('horizontal');
	$plugin_dialog->get_child->add($plugin_progress);

	$plugin_dialog->show_all;

	my $plugin_response = $plugin_dialog->run;

	if ($plugin_response eq 'accept') {

		#anything wrong with the selected plugin?
		unless ($plugin_value =~ /[a-zA-Z0-9]+/) {
			$sd->dlg_error_message($d->get("No plugin specified"), $d->get("Failed"));
			return FALSE;
		}

		#we save the last execution time
		#and try to preselect it when the plugin dialog is executed again
		$plugins->{$plugin_key}->{'recent'} = time;

		#disable buttons and combobox
		$plugin->set_sensitive(FALSE);
		foreach my $dialog_child ($plugin_dialog->get_child->get_children) {
			$dialog_child->set_sensitive(FALSE)
				if $dialog_child =~ /Button/;
		}

		#show the progress bar
		$plugin_progress->show;
		$plugin_progress->set_fraction(0);

		# Assuming fct_update_gui is available/called correctly.
		fct_update_gui() if defined &fct_update_gui;

		my $counter = 1;

		#call execute_plugin for each file to be processed
		foreach my $key (@file_to_plugin_keys) {

			#store data
			my $data = [$plugin_value, $plugin_name, $plugin_lang, $key, $plugin_dialog, $plugin_progress];

			# Assuming fct_execute_plugin is available/called correctly.
			fct_execute_plugin(undef, $data) if defined &fct_execute_plugin;

			#increase counter and update gui to show updated progress bar
			$counter++;
		}

		$plugin_dialog->destroy();
		return TRUE;
	} else {
		$plugin_dialog->destroy();
		return FALSE;
	}
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Dialogs_Plugin - Plugin dialog handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
