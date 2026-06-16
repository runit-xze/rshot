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

package Shutter::App::Handlers::Init;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

	sub fct_check_valid_mime_type {
		my $mime_type = shift;

		foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
			foreach my $mtype (@{$format->get_mime_types}) {
				return TRUE if $mtype eq $mime_type;
				last;
			}
		}

		return FALSE;
	}

	sub fct_drop_handler {
		my ($widget, $context, $x, $y, $selection, $info, $time) = @_;
		my $type = $selection->get_target->name;
		return unless $type eq 'text/uri-list';
		my $data = $selection->get_data;
		$data = join('', map { chr } @$data);

		my @files = grep defined($_), split /[\r\n]+/, $data;

		my @valid_files;
		my @sxcu_files;
		foreach my $file (@files) {
			my $giofile = Glib::IO::File::new_for_uri($file);
			my $path = $giofile->get_path;
			if ($path && $path =~ /\.sxcu$/i) {
				push @sxcu_files, $path;
			} else {
				my ($mime_type) = Glib::Object::Introspection->invoke('Gio', undef, 'content_type_guess', $path);
				$mime_type =~ s/image\/x\-apple\-ios\-png/image\/png/;    #FIXME
				if ($mime_type && fct_check_valid_mime_type($mime_type)) {
					push @valid_files, $file;
				}
			}
		}

		if (@sxcu_files) {
			my $uploaders_dir = $ENV{'HOME'} . '/.shutter/uploaders';
			mkdir $uploaders_dir unless -d $uploaders_dir;
			use File::Copy;
			my $imported = 0;
			foreach my $sxcu (@sxcu_files) {
				use File::Basename;
				my $name = basename($sxcu);
				if (copy($sxcu, "$uploaders_dir/$name")) {
					$imported++;
				}
			}
			fct_show_status_message(3, sprintf($d->nget("Imported %d ShareX custom uploader", "Imported %d ShareX custom uploaders", $imported), $imported));
			
			# Re-init upload plugins to load the new ones!
			fct_init_upload_plugins();
		}

		#open all valid files
		if (@valid_files) {
			fct_open_files(@valid_files);
			Gtk3::drag_finish($context, 1, 0, $time);
			return TRUE;
		} else {
			Gtk3::drag_finish($context, 0, 0, $time);
			return FALSE;
		}
	}

	sub fct_is_uri_in_session {
		my $giofile = shift;
		my $jump    = shift;

		return FALSE unless $giofile;

		foreach my $key (keys %session_screens) {
			if (exists $session_screens{$key}->{'giofile'}) {
				if ($giofile->equal($session_screens{$key}->{'giofile'})) {
					if (exists $session_screens{$key}->{'tab_child'}) {
						if ($jump) {
							$notebook->set_current_page($notebook->page_num($session_screens{$key}->{'tab_child'}));
						}
						return TRUE;
					}
				}
			}
		}

		return FALSE;
	}

	sub fct_load_accounts {
		my ($profilename) = @_;

		#accounts file
		my $accountsfile = "$ENV{ HOME }/.shutter/accounts.xml";
		$accountsfile = "$ENV{ HOME }/.shutter/profiles/$profilename\_accounts.xml"
			if (defined $profilename);

		if ($shf->file_exists($accountsfile)) {
			my $accounts_xml = undef;
			eval { $accounts_xml = XMLin(IO::File->new($accountsfile)) };
			if ($@) {
				$sd->dlg_error_message($@, $d->get("Account-settings could not be restored!"));
				unlink $accountsfile;
			} else {
				foreach (keys %{$accounts_xml}) {

					#check if plugin still exists
					if ($shf->file_exists($accounts_xml->{$_}->{path})) {

						#clear cache
						if (!$sc->get_clear_cache) {
							$accounts{$_}->{path}                       = $accounts_xml->{$_}->{path};
							$accounts{$_}->{module}                     = $accounts_xml->{$_}->{module};
							$accounts{$_}->{host}                       = $accounts_xml->{$_}->{host};
							$accounts{$_}->{folder}                     = $accounts_xml->{$_}->{folder};
							$accounts{$_}->{description}                = $accounts_xml->{$_}->{description};
							$accounts{$_}->{register_color}             = "blue";
							$accounts{$_}->{register_text}              = $accounts_xml->{$_}->{register_text};
							$accounts{$_}->{supports_anonymous_upload}  = $accounts_xml->{$_}->{supports_anonymous_upload};
							$accounts{$_}->{supports_authorized_upload} = $accounts_xml->{$_}->{supports_authorized_upload};
							$accounts{$_}->{supports_oauth_upload}      = $accounts_xml->{$_}->{supports_oauth_upload};

							utf8::decode $accounts{$_}->{'host'};
						}
						$accounts{$_}->{username} = $accounts_xml->{$_}->{username};
						$accounts{$_}->{password} = $accounts_xml->{$_}->{password};

						utf8::decode $accounts{$_}->{'username'};
						utf8::decode $accounts{$_}->{'password'};
					}
				}
			}
		}

		return TRUE;
	}

	sub fct_load_accounts_tree {

		$accounts_model = Gtk3::ListStore->new(
			'Glib::String', 'Glib::String', 'Glib::String',  'Glib::String',  'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String',
			'Glib::String', 'Glib::String', 'Glib::Boolean', 'Glib::Boolean', 'Glib::Boolean'
		);

		foreach (keys %accounts) {
			my $hidden_text = "";
			for (my $i = 1 ; $i <= length($accounts{$_}->{'password'}) ; $i++) {
				$hidden_text .= '*';
			}
			$accounts_model->set(
				$accounts_model->append,                       0,  $accounts{$_}->{'host'},         1,  $accounts{$_}->{'username'},                  2,
				$hidden_text,                                  3,  $accounts{$_}->{'not_used_yet'}, 4,  $accounts{$_}->{'register_color'},            5,
				$accounts{$_}->{'register_text'},              6,  $accounts{$_}->{'module'},       7,  $accounts{$_}->{'path'},                      8,
				$accounts{$_}->{'folder'},                     9,  $accounts{$_}->{'description'},  10, $accounts{$_}->{'supports_anonymous_upload'}, 11,
				$accounts{$_}->{'supports_authorized_upload'}, 12, $accounts{$_}->{'supports_oauth_upload'},
			);
		}

		return TRUE;
	}

	sub fct_load_plugin_tree {

		my $effects_model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String',);
		foreach my $pkey (sort keys %plugins) {
			if ($plugins{$pkey}->{'binary'}) {

				#we need to update the pixbuf of the plugins again in some cases
				#
				#pixbufs are not cached and therefore not checked at startup if
				#the cached plugin is not in the plugin path
				#(maybe changed the installation dir)
				unless ($plugins{$pkey}->{'pixbuf'}
					|| $plugins{$pkey}->{'pixbuf_object'})
				{
					$plugins{$pkey}->{'pixbuf'} = $plugins{$pkey}->{'binary'} . ".png"
						if ($shf->file_exists($plugins{$pkey}->{'binary'} . ".png"));
					$plugins{$pkey}->{'pixbuf'} = $plugins{$pkey}->{'binary'} . ".svg"
						if ($shf->file_exists($plugins{$pkey}->{'binary'} . ".svg"));

					if ($shf->file_exists($plugins{$pkey}->{'pixbuf'})) {
						$plugins{$pkey}->{'pixbuf_object'} = $lp->load($plugins{$pkey}->{'pixbuf'}, $shf->icon_size('menu'));
					} else {
						$plugins{$pkey}->{'pixbuf'}        = "$shutter_root/share/shutter/resources/icons/executable.svg";
						$plugins{$pkey}->{'pixbuf_object'} = $lp->load($plugins{$pkey}->{'pixbuf'}, $shf->icon_size('menu'));
					}
				}

				$effects_model->set(
					$effects_model->append,       0, $plugins{$pkey}->{'pixbuf_object'}, 1, $plugins{$pkey}->{'name'},   2, $plugins{$pkey}->{'category'}, 3,
					$plugins{$pkey}->{'tooltip'}, 4, $plugins{$pkey}->{'lang'},          5, $plugins{$pkey}->{'binary'}, 6, $pkey,
				);
			} else {
				print "\nWARNING: Plugin $pkey is not configured properly, ignoring\n";
				delete $plugins{$pkey};
			}
		}

		return $effects_model;
	}

	sub fct_load_session {

		#session file
		my $sessionfile = "$ENV{ HOME }/.shutter/session.xml";

		eval {
			my $session_xml = XMLin(IO::File->new($sessionfile))
				if $shf->file_exists($sessionfile);

			return FALSE if scalar(keys %{$session_xml}) < 1;

			#activate throbber
			my ($throbber, $sep) = fct_toggle_status_throbber($status);

			#how many files have to be loaded
			#store this value in the session hash
			$session_start_screen{'first_page'}->{'num_session_files'} = scalar(keys %{$session_xml});

			#local counter
			#is passed to several subroutines to indicate the correct index
			my $count = 0;
			foreach my $key (sort keys %{$session_xml}) {

				#increment counter
				$count++;

				#refresh gui
				fct_update_gui();

				#do the real work
				my $new_giofile = Glib::IO::File::new_for_path(${$session_xml}{$key}{'filename'});
				if (fct_integrate_screenshot_in_notebook($new_giofile, undef, undef, $count)) {
					fct_show_status_message(1, $shf->utf8_decode($new_giofile->get_path) . " " . $d->get("opened"));
				} else {
					fct_show_status_message(1, sprintf($d->get("Error while opening image %s."), "'" . $new_giofile->get_basename . "'"));
				}

			}

			#clear the value after loading the files
			$session_start_screen{'first_page'}->{'num_session_files'} = undef;

			#de-activate the throbber
			fct_toggle_status_throbber($status, $throbber, $sep);

		};
		if ($@) {
			$sd->dlg_error_message($@, $d->get("Session could not be restored!"));
			unlink $sessionfile;
		}

		return TRUE;
	}

	sub fct_open_files {
		my (@new_files) = @_;

		return FALSE if scalar(@new_files) < 1;

		my ($throbber, $sep) = fct_toggle_status_throbber($status);

		foreach my $file (@new_files) {

			my $new_giofile = Glib::IO::File::new_for_uri($shf->utf8_decode(unescape_string($file)));
			next if fct_is_uri_in_session($new_giofile, TRUE);

			#refresh gui
			fct_update_gui();

			#do the real work
			if (fct_integrate_screenshot_in_notebook($new_giofile)) {
				fct_show_status_message(1, $shf->utf8_decode($new_giofile->get_path) . " " . $d->get("opened"));
			} else {
				fct_show_status_message(1, sprintf($d->get("Error while opening image %s."), "'" . $shf->utf8_decode($new_giofile->get_basename) . "'"));
			}
		}

		fct_toggle_status_throbber($status, $throbber, $sep);

		return TRUE;
	}

	sub fct_set_model_accounts {
		my $accounts_tree = $_[0];

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
				$accounts{$model->get_value($iter, 6)}->{'username'} = $new_text;

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

				$accounts{$model->get_value($iter, 6)}->{'password'} = $new_text;    #save entered password to the hash
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

	sub fct_set_model_plugins {
		my $effects_tree = $_[0];

		#~ my @columns = $effects_tree->get_columns;
		#~ foreach (@columns) {
		#~ $effects_tree->remove_column($_);
		#~ }

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

	sub fct_toggle_status_throbber {
		my $status   = shift;
		my $throbber = shift;
		my $sep      = shift;
		return FALSE unless $status;

		if (defined $throbber && defined $sep) {
			$throbber->destroy;
			$throbber = undef;
			$sep->destroy;
			$sep = undef;
		} else {

			#don't show more than one
			foreach my $child ($status->get_children) {
				if ($child->get_name eq 'throbber') {
					return FALSE;
				}
			}
			$throbber = Gtk3::Image->new_from_file("$shutter_root/share/shutter/resources/icons/throbber_16x16.gif");
			$throbber->set_name('throbber');
			$sep = Gtk3::HSeparator->new;
			$status->pack_start($sep, FALSE, FALSE, 3);
			$status->pack_end($throbber, FALSE, FALSE, 0);
		}

		$status->show_all;

		return ($throbber, $sep);
	}


1;
