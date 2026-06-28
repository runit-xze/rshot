###################################################
#
#  Copyright (C) 2024 Shutter Project
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
###################################################

package Shutter::App::AfterCapturePipeline;

use Moo;
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Glib qw/TRUE FALSE/;
use Gtk3;
use JSON::MaybeXS;
use Log::Any;

my $log = Log::Any->get_logger;

my %STEP_TYPES = (
	save_to_disk   => 'Save to Disk',
	open_in_editor => 'Open in Editor',
	copy_image     => 'Copy Image to Clipboard',
	copy_filename  => 'Copy Filename to Clipboard',
	upload_sxcu    => 'Upload (ShareX Custom Uploader)',
	copy_link      => 'Copy Upload Link to Clipboard',
	pin_to_screen  => 'Pin to Screen',
	run_command    => 'Run Command',
);

my @STEP_ORDER = qw(
	save_to_disk open_in_editor copy_image copy_filename
	upload_sxcu copy_link pin_to_screen run_command
);

has _sc => (
	is       => 'rwp',
	required => 1,
);
has _d => (
	is       => 'rwp',
	required => 1,
);
has _main_gtk_window => (
	is       => 'rwp',
	required => 1,
);
has _steps => (
	is       => 'rwp',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build__steps',
);

sub _build__steps ($self) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return [];
}

sub BUILDARGS ($class, @args) {
	return {_sc => $args[0], _d => $args[1], _main_gtk_window => $args[2]};
}

sub load_from_json ($self, $json_str) {
	return unless $json_str && length($json_str) > 2;
	try {
		my $data = JSON::MaybeXS->new->decode($json_str);
		$self->_set__steps($data) if ref $data eq 'ARRAY';
	} catch ($e) {
		$log->warn("failed to parse steps JSON: $e");
		$self->_set__steps([]);
	}
	return;
}

sub to_json ($self) {
	return JSON::MaybeXS->new->encode($self->_steps // []);
}

sub get_steps ($self) {
	return @{$self->_steps};
}

sub set_steps ($self, @steps) {
	$self->_set__steps(\@steps);
	return;
}

sub execute ($self, $context) {
	my $d = $self->_d;

	for my $step (@{$self->_steps}) {
		my $type = $step->{type} // '';

		if ($type eq 'save_to_disk') {

		} elsif ($type eq 'open_in_editor') {
			$context->{editor_cb}->($context->{filename})
				if ref $context->{editor_cb} eq 'CODE';

		} elsif ($type eq 'copy_image') {
			if (defined $context->{clipboard} && defined $context->{pixbuf}) {
				$context->{clipboard}->set_image($context->{pixbuf});
			}

		} elsif ($type eq 'copy_filename') {
			if (defined $context->{clipboard} && defined $context->{filename}) {
				$context->{clipboard}->set_text($context->{filename});
			}

		} elsif ($type eq 'upload_sxcu') {
			$context->{upload_cb}->($context->{filename}, $step->{sxcu_path} // '')
				if ref $context->{upload_cb} eq 'CODE';

		} elsif ($type eq 'copy_link') {
			if (defined $context->{clipboard} && defined $context->{upload_link}) {
				$context->{clipboard}->set_text($context->{upload_link});
			}

		} elsif ($type eq 'pin_to_screen') {
			$context->{pin_cb}->($context->{pixbuf})
				if ref $context->{pin_cb} eq 'CODE' && defined $context->{pixbuf};

		} elsif ($type eq 'run_command') {
			my $cmd = $step->{command} // '';
			$cmd =~ s/\$f/$context->{filename}/g if $context->{filename};
			if ($cmd) {
				require Text::ParseWords;
				require Shutter::App::Core::SecureSystemCommandAPI;
				my @args = Text::ParseWords::shellwords($cmd);
				Shutter::App::Core::SecureSystemCommandAPI->new->run_async(@args) if @args;
			}
		}
	}
	return;
}

sub build_config_widget ($self) {
	my $d = $self->_d;

	my $vbox = Gtk3::VBox->new(FALSE, 6);

	my $header = Gtk3::Label->new('');
	$header->set_markup('<b>After Capture Task Pipeline</b>');
	$header->set_alignment(0, 0.5);
	$vbox->pack_start($header, FALSE, FALSE, 4);

	my $desc = Gtk3::Label->new("Define a sequence of actions to execute automatically after each screenshot.");
	$desc->set_line_wrap(TRUE);
	$desc->set_alignment(0, 0.5);
	$vbox->pack_start($desc, FALSE, FALSE, 0);

	my $store = Gtk3::ListStore->new('Glib::Boolean', 'Glib::String', 'Glib::String', 'Glib::String');

	for my $step (@{$self->_steps}) {
		my $type    = $step->{type}      // '';
		my $label   = $STEP_TYPES{$type} // $type;
		my $extra   = $step->{command}   // $step->{sxcu_path} // '';
		my $enabled = $step->{enabled}   // TRUE;
		my $iter    = $store->append;
		$store->set($iter, 0 => $enabled, 1 => $type, 2 => $label, 3 => $extra);
	}

	my $tv = Gtk3::TreeView->new($store);
	$tv->set_reorderable(TRUE);

	my $toggle_renderer = Gtk3::CellRendererToggle->new;
	$toggle_renderer->set_activatable(TRUE);
	$toggle_renderer->signal_connect(
		'toggled' => sub {
			my ($cell, $path_str) = @_;
			my $iter = $store->get_iter(Gtk3::TreePath->new_from_string($path_str));
			my $val  = $store->get_value($iter, 0);
			$store->set($iter, 0 => !$val);
		});
	my $col_enabled = Gtk3::TreeViewColumn->new_with_attributes('On', $toggle_renderer, active => 0);
	$tv->append_column($col_enabled);

	my $text_renderer = Gtk3::CellRendererText->new;
	my $col_step      = Gtk3::TreeViewColumn->new_with_attributes('Step', $text_renderer, text => 2);
	$col_step->set_expand(TRUE);
	$tv->append_column($col_step);

	my $extra_renderer = Gtk3::CellRendererText->new;
	$extra_renderer->set_property('editable', TRUE);
	$extra_renderer->signal_connect(
		'edited' => sub {
			my ($cell, $path_str, $new_text) = @_;
			my $iter = $store->get_iter(Gtk3::TreePath->new_from_string($path_str));
			$store->set($iter, 3 => $new_text);
		});
	my $col_extra = Gtk3::TreeViewColumn->new_with_attributes('Details', $extra_renderer, text => 3);
	$col_extra->set_expand(TRUE);
	$tv->append_column($col_extra);

	my $sw = Gtk3::ScrolledWindow->new;
	$sw->set_policy('automatic', 'automatic');
	$sw->set_size_request(-1, 180);
	$sw->add($tv);
	$vbox->pack_start($sw, TRUE, TRUE, 4);

	my $btn_box = Gtk3::HBox->new(FALSE, 4);

	my $step_combo = Gtk3::ComboBoxText->new;
	for my $key (@STEP_ORDER) {
		$step_combo->append_text($STEP_TYPES{$key});
	}
	$step_combo->set_active(0);
	$btn_box->pack_start($step_combo, TRUE, TRUE, 0);

	my $add_btn = Gtk3::Button->new_with_label('Add');
	$add_btn->signal_connect(
		'clicked' => sub {
			my $idx   = $step_combo->get_active;
			my $key   = $STEP_ORDER[$idx];
			my $label = $STEP_TYPES{$key};
			my $iter  = $store->append;
			$store->set($iter, 0 => TRUE, 1 => $key, 2 => $label, 3 => '');
		});
	$btn_box->pack_start($add_btn, FALSE, FALSE, 0);

	my $remove_btn = Gtk3::Button->new_with_label('Remove');
	$remove_btn->signal_connect(
		'clicked' => sub {
			my $sel = $tv->get_selection;
			my (undef, $iter) = $sel->get_selected;
			$store->remove($iter) if $iter;
		});
	$btn_box->pack_start($remove_btn, FALSE, FALSE, 0);

	my $up_btn = Gtk3::Button->new_with_label("\x{e2}\x{86}\x{91}");
	$up_btn->signal_connect(
		'clicked' => sub {
			my $sel = $tv->get_selection;
			my (undef, $iter) = $sel->get_selected;
			return unless $iter;
			my $path = $store->get_path($iter);
			if ($path->prev) {
				my $prev_iter = $store->get_iter($path);
				$store->swap($iter, $prev_iter) if $prev_iter;
			}
		});
	$btn_box->pack_start($up_btn, FALSE, FALSE, 0);

	my $down_btn = Gtk3::Button->new_with_label("\x{e2}\x{86}\x{93}");
	$down_btn->signal_connect(
		'clicked' => sub {
			my $sel = $tv->get_selection;
			my (undef, $iter) = $sel->get_selected;
			return unless $iter;
			my $next_iter = $store->iter_next($iter) // do { return };
			$store->swap($iter, $next_iter);
		});
	$btn_box->pack_start($down_btn, FALSE, FALSE, 0);

	$vbox->pack_start($btn_box, FALSE, FALSE, 0);

	$vbox->{_get_steps_from_store} = sub {
		my @steps;
		my $iter = $store->get_iter_first;
		while ($iter) {
			my $enabled = $store->get_value($iter, 0);
			my $type    = $store->get_value($iter, 1);
			my $extra   = $store->get_value($iter, 3);
			my %step    = (type => $type, enabled => $enabled ? JSON::MaybeXS::true() : JSON::MaybeXS::false());
			if ($type eq 'run_command') {
				$step{command} = $extra;
			} elsif ($type eq 'upload_sxcu') {
				$step{sxcu_path} = $extra;
			}
			push @steps, \%step;
			$iter = $store->iter_next($iter);
		}
		return @steps;
	};

	return ($vbox, $vbox->{_get_steps_from_store});
}

1;
