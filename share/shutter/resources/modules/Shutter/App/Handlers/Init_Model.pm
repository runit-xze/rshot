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

package Shutter::App::Handlers::Init_Model;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_set_model_accounts ($self, $accounts_tree, $accounts_model) {
	my $cli      = $self->cli;
	my $d        = $cli->sc->get_gettext;
	my $accounts = $cli->{_accounts};

	my @columns = $accounts_tree->get_columns;
	foreach my $col (@columns) {
		$accounts_tree->remove_column($col);
	}

	$accounts_tree->set_tooltip_column(9);

	#name
	my $tv_clmn_name_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_name_text->set_title($d->get("Host"));
	my $renderer_name_accounts = Gtk3::CellRendererText->new;
	$tv_clmn_name_text->pack_start($renderer_name_accounts, FALSE);
	$tv_clmn_name_text->set_attributes($renderer_name_accounts, text => 6);
	$accounts_tree->append_column($tv_clmn_name_text);

	#username
	my $tv_clmn_username_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_username_text->set_max_width(100);
	$tv_clmn_username_text->set_title($d->get("Username"));
	my $renderer_username_accounts = Gtk3::CellRendererText->new;
	$tv_clmn_username_text->pack_start($renderer_username_accounts, FALSE);
	$tv_clmn_username_text->set_attributes(
		$renderer_username_accounts,
		text      => 1,
		editable  => 11,
		sensitive => 11
	);
	$renderer_username_accounts->signal_connect(
		'edited' => sub {
			my ($cell, $text_path, $new_text, $model) = @_;
			my $path = Gtk3::TreePath->new_from_string($text_path);
			my $iter = $model->get_iter($path);

			#save entered username to the hash
			$accounts->{$model->get_value($iter, 6)}->{'username'} = $new_text;

			$model->set($iter, 1, $new_text);
		},
		$accounts_model
	);

	$accounts_tree->append_column($tv_clmn_username_text);

	#password
	my $tv_clmn_password_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_password_text->set_max_width(100);
	$tv_clmn_password_text->set_title($d->get("Password"));
	my $renderer_password_accounts = Gtk3::CellRendererText->new;
	$tv_clmn_password_text->pack_start($renderer_password_accounts, FALSE);
	$tv_clmn_password_text->set_attributes(
		$renderer_password_accounts,
		text      => 2,
		editable  => 11,
		sensitive => 11
	);
	$renderer_password_accounts->signal_connect(
		'edited' => sub {
			my ($cell, $text_path, $new_text, $model) = @_;
			my $path        = Gtk3::TreePath->new_from_string($text_path);
			my $iter        = $model->get_iter($path);
			my $hidden_text = "";

			for (my $i = 1 ; $i <= length($new_text) ; $i++) {
				$hidden_text .= '*';
			}

			$accounts->{$model->get_value($iter, 6)}->{'password'} = $new_text;    #save entered password to the hash
			$model->set($iter, 2, $hidden_text);
		},
		$accounts_model
	);

	$accounts_tree->append_column($tv_clmn_password_text);

	#upload features
	my $tv_clmn_f1_toggle = Gtk3::TreeViewColumn->new;
	$tv_clmn_f1_toggle->set_title($d->get("Anonymous Upload"));
	my $f1_toggle = Gtk3::CellRendererToggle->new();
	$tv_clmn_f1_toggle->pack_start($f1_toggle, FALSE);
	$tv_clmn_f1_toggle->set_attributes($f1_toggle, active => 10);
	$accounts_tree->append_column($tv_clmn_f1_toggle);

	my $tv_clmn_f2_toggle = Gtk3::TreeViewColumn->new;
	$tv_clmn_f2_toggle->set_title($d->get("Authorized Upload"));
	my $f2_toggle = Gtk3::CellRendererToggle->new();
	$tv_clmn_f2_toggle->pack_start($f2_toggle, FALSE);
	$tv_clmn_f2_toggle->set_attributes($f2_toggle, active => 11);
	$accounts_tree->append_column($tv_clmn_f2_toggle);

	my $tv_clmn_f3_toggle = Gtk3::TreeViewColumn->new;
	$tv_clmn_f3_toggle->set_title($d->get("OAuth Upload"));
	my $f3_toggle = Gtk3::CellRendererToggle->new();
	$tv_clmn_f3_toggle->pack_start($f3_toggle, FALSE);
	$tv_clmn_f3_toggle->set_attributes($f3_toggle, active => 12);
	$accounts_tree->append_column($tv_clmn_f3_toggle);

	#description
	#tooltip column (show as columns when needed)
	my $tv_clmn_descr_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_descr_text->set_resizable(TRUE);
	$tv_clmn_descr_text->set_title($d->get("Description"));
	my $renderer_descr_effects = Gtk3::CellRendererText->new;
	$tv_clmn_descr_text->pack_start($renderer_descr_effects, FALSE);
	$tv_clmn_descr_text->set_attributes($renderer_descr_effects, text => 9);
	$accounts_tree->append_column($tv_clmn_descr_text);

	#register
	my $tv_clmn_pix_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_pix_text->set_title($d->get("Register"));
	my $ren_text = Gtk3::CellRendererText->new();
	$tv_clmn_pix_text->pack_start($ren_text, FALSE);
	$tv_clmn_pix_text->set_attributes($ren_text, 'text', 5, 'foreground', 4);
	$accounts_tree->append_column($tv_clmn_pix_text);

	return TRUE;
}

sub fct_set_model_plugins ($self, $effects_tree) {
	my $cli = $self->cli;
	my $d   = $cli->sc->get_gettext;

	#tooltip
	$effects_tree->set_tooltip_column(3);

	my $tv_clmn_pix_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_pix_text->set_resizable(TRUE);
	$tv_clmn_pix_text->set_title($d->get("Icon"));
	my $renderer_pix_effects = Gtk3::CellRendererPixbuf->new;
	$tv_clmn_pix_text->pack_start($renderer_pix_effects, FALSE);
	$tv_clmn_pix_text->set_attributes($renderer_pix_effects, pixbuf => 0);
	$effects_tree->append_column($tv_clmn_pix_text);

	#name
	my $tv_clmn_text_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_text_text->set_resizable(TRUE);
	$tv_clmn_text_text->set_title($d->get("Name"));
	my $renderer_text_effects = Gtk3::CellRendererText->new;
	$tv_clmn_text_text->pack_start($renderer_text_effects, FALSE);
	$tv_clmn_text_text->set_attributes($renderer_text_effects, text => 1);

	$effects_tree->append_column($tv_clmn_text_text);

	#category
	my $tv_clmn_category_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_category_text->set_resizable(TRUE);
	$tv_clmn_category_text->set_title($d->get("Category"));
	my $renderer_category_effects = Gtk3::CellRendererText->new;
	$tv_clmn_category_text->pack_start($renderer_category_effects, FALSE);
	$tv_clmn_category_text->set_attributes($renderer_category_effects, text => 2);
	$effects_tree->append_column($tv_clmn_category_text);

	my $tv_clmn_descr_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_descr_text->set_resizable(TRUE);
	$tv_clmn_descr_text->set_title($d->get("Description"));
	my $renderer_descr_effects = Gtk3::CellRendererText->new;
	$tv_clmn_descr_text->pack_start($renderer_descr_effects, FALSE);
	$tv_clmn_descr_text->set_attributes($renderer_descr_effects, text => 3);
	$effects_tree->append_column($tv_clmn_descr_text);

	#language
	my $tv_clmn_lang_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_lang_text->set_resizable(TRUE);
	$tv_clmn_lang_text->set_title($d->get("Language"));
	my $renderer_lang_effects = Gtk3::CellRendererText->new;
	$tv_clmn_lang_text->pack_start($renderer_lang_effects, FALSE);
	$tv_clmn_lang_text->set_attributes($renderer_lang_effects, text => 4);
	$effects_tree->append_column($tv_clmn_lang_text);

	#path
	my $tv_clmn_path_text = Gtk3::TreeViewColumn->new;
	$tv_clmn_path_text->set_resizable(TRUE);
	$tv_clmn_path_text->set_title($d->get("Path"));
	my $renderer_path_effects = Gtk3::CellRendererText->new;
	$tv_clmn_path_text->pack_start($renderer_path_effects, FALSE);
	$tv_clmn_path_text->set_attributes($renderer_path_effects, text => 5);
	$effects_tree->append_column($tv_clmn_path_text);

	return TRUE;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Init_Model - Initialization model handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
