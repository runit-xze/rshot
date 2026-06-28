###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
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
#  You should have received a copy of the GNU General Public License
#  along with Shutter; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
#
###################################################

package Shutter::App::HelperFunctions;

use Moo;
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Gtk3;
use Log::Any;
use Shutter::App::SimpleDialogs;

use Glib qw/TRUE FALSE/;

my $log = Log::Any->get_logger;

has _common => (
	is       => 'rwp',
	required => 1,
);
has _dialogs => (
	is       => 'rwp',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build__dialogs',
);
has _d => (
	is       => 'rwp',
	init_arg => undef,
	lazy     => 1,
	builder  => '_build__d',
);

sub _build__dialogs ($self) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	my $current_window = $self->_common->main_window;
	return Shutter::App::SimpleDialogs->new($current_window);
}

sub _build__d ($self) {    ## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
	return $self->_common->gettext_object;
}

sub BUILDARGS ($class, @args) {
	return {_common => $args[0]};
}

sub xdg_open ($self, $dialog, $link, $user_data) {
	eval {
		my $uri = $link;
		$uri = "file://$uri" unless $uri =~ m{^[a-zA-Z]+://};
		Gtk3::show_uri_on_window(undef, $uri, Gtk3::Gdk::CURRENT_TIME);
	};
	if ($@) {
		my $response = $self->_dialogs->dlg_error_message(
			sprintf($self->_d->get("Error while executing %s."),        "'xdg-open'"),
			sprintf($self->_d->get("There was an error executing %s."), "'xdg-open'"),
			undef, undef, undef, undef, undef, undef, $@
		);
	}
	return;
}

sub xdg_open_mail ($self, $dialog, $mail, @user_data) {

	my @cmd = 'xdg-email';
	push @cmd, $mail if $mail;
	require Shutter::App::Core::SecureSystemCommandAPI;
	my $res = Shutter::App::Core::SecureSystemCommandAPI->new->run_async(@cmd, @user_data);

	if (!$res) {
		my $response = $self->_dialogs->dlg_error_message(
			sprintf($self->_d->get("Error while executing %s."),        "'xdg-email'"),
			sprintf($self->_d->get("There was an error executing %s."), "'xdg-email'"),
			undef, undef, undef, undef, undef, undef, sprintf($self->_d->get("Exit Code: %d."), 1));
	}
	return;
}

sub nautilus_sendto ($self, $user_data) {
	require Shutter::App::Core::SecureSystemCommandAPI;
	my $res = Shutter::App::Core::SecureSystemCommandAPI->new->run_async('nautilus-sendto', $user_data);

	if (!$res) {
		my $response = $self->_dialogs->dlg_error_message(
			sprintf($self->_d->get("Error while executing %s."),        "'nautilus-sendto'"),
			sprintf($self->_d->get("There was an error executing %s."), "'nautilus-sendto'"),
			undef, undef, undef, undef, undef, undef, sprintf($self->_d->get("Exit Code: %d."), 1));
	}
	return;
}

sub file_exists ($self, $filename) {
	return FALSE unless $filename;
	$filename = $self->switch_home_in_file($filename);
	return TRUE if (-f $filename && -r $filename);
	return FALSE;
}

sub folder_exists ($self, $folder) {
	return FALSE unless $folder;
	$folder = $self->switch_home_in_file($folder);
	return TRUE if (-d $folder && -r $folder);
	return FALSE;
}

sub uri_exists ($self, $filename) {
	return FALSE unless $filename;
	$filename = $self->switch_home_in_file($filename);
	my $new_giofile = Glib::IO::File::new_for_uri($filename);
	return TRUE if $new_giofile->query_exists;
	return FALSE;
}

sub file_executable ($self, $filename) {
	return FALSE unless $filename;
	$filename = $self->switch_home_in_file($filename);
	return TRUE if (-x $filename);
	return FALSE;
}

sub switch_home_in_file ($self, $filename) {
	$filename =~ s/^~/$ENV{ HOME }/;
	return $filename;
}

sub utf8_decode ($self, $string) {

	utf8::decode $string;

	return $string;
}

sub escape_string ($self, $string) {
	return $string;
}

sub unescape_string ($self, $string) {
	return $string;
}

sub unescape_string_for_display ($self, $string) {
	return $string;
}

sub escape_path_string ($self, $string) {
	return $string;
}

sub usage ($self) {

	print "shutter [options]\n";
	print "Available options:\n\n"
		. "Capture:\n"
		. "--select (starts Shutter in selection mode)\n"
		. "--full (starts Shutter and takes a full screen screenshot directly)\n"
		. "--window (starts Shutter in window selection mode)\n"
		. "--awindow (capture the active window)\n"
		. "--section (starts Shutter in section selection mode)\n"
		. "--menu (starts Shutter in menu selection mode)\n"
		. "--tooltip (starts Shutter in tooltip selection mode)\n"
		. "--web (starts Shutter in web capture mode)\n\n"
		.

		"Application:\n"
		. "--min_at_startup (starts Shutter minimized to tray)\n"
		. "--clear_cache (clears cache, e.g. installed plugins, at startup)\n"
		. "--debug (prints a lot of debugging information to STDOUT)\n"
		. "--disable_systray (disable systray icon)\n"
		. "--version (displays version information)\n"
		. "--help (displays this help)\n";

	return TRUE;
}

sub icon_size ($self, $size) {
	my @result = Glib::Object::Introspection->invoke('Gtk', undef, 'icon_size_lookup', Glib::Object::Introspection->convert_sv_to_enum('Gtk3::IconSize', $size));
	my $one    = shift @result;
	die "icon_size($size)=$one, @result" if $one != 1;
	return @result;
}

sub accel ($self, $str) {
	return Glib::Object::Introspection->invoke('Gtk', undef, 'accelerator_parse', $str);
}

sub format_bytes ($self, $bytes) {
	return "0 B" unless $bytes;
	my @units = qw(B kB MB GB TB PB);
	my $i     = 0;
	while ($bytes >= 1000 && $i < @units - 1) {
		$bytes /= 1000;
		$i++;
	}
	return sprintf($bytes == int($bytes) ? "%d %s" : "%.1f %s", $bytes, $units[$i]);
}

sub validate_filename ($self, $myfilename, $myfilename_hint) {
	my @invalid_codes = (47, 92);
	$myfilename->signal_connect(
		'key-press-event' => sub {
			shift;
			my $event = shift;

			my $input = Gtk3::Gdk::keyval_to_unicode($event->keyval);

			if (grep { $input == $_ } @invalid_codes) {
				my $char = chr($input);
				$char = '&amp;' if $char eq '&';
				$myfilename_hint->set_markup("<span size='small'>" . sprintf($self->_d->get("Reserved character %s is not allowed to be in a filename."), "'" . $char . "'") . "</span>");
				return TRUE;
			} else {
				$myfilename_hint->set_markup("<span size='small'></span>");
				return FALSE;
			}
		});
	return;
}

sub get_program_model ($self) {
	my $model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::Scalar');
	my $sc    = $self->_common;
	my $d     = $self->_d;

	my $goocanvas = TRUE;

	if ($goocanvas) {
		my $icon_pixbuf = undef;
		my $icon        = 'shutter';
		if ($sc->icontheme->has_icon($icon)) {
			my ($iw, $ih) = $self->icon_size('menu');
			eval { $icon_pixbuf = $sc->icontheme->load_icon($icon, $ih, 'generic-fallback'); };
			if ($@) {
				$log->warn("Could not load icon $icon: $@");
				$icon_pixbuf = undef;
			}
		}
		$model->set($model->append, 0, $icon_pixbuf, 1, $d->get("Built-in Editor"), 2, 'shutter-built-in');
	}

	my $apps = Glib::IO::AppInfo::get_recommended_for_type('image/png');

	return $model unless defined $apps && scalar @$apps;

	foreach my $app (@$apps) {

		next if $app->get_id eq 'shutter.desktop';

		my $app_name = $self->utf8_decode($app->get_display_name);

		my $icon_pixbuf = undef;
		my $icon        = $app->get_icon;
		if ($icon) {
			my ($iw, $ih) = $self->icon_size('menu');
			eval {
				my $icon_info = $sc->icontheme->choose_icon($icon->get_names, $ih, []);
				$icon_pixbuf = $icon_info->load_icon if $icon_info;
			};
			if ($@) {
				$log->warn("Could not load icon for $app_name: $@");
				$icon_pixbuf = undef;
			}
		}
		$model->set($model->append, 0, $icon_pixbuf, 1, $app_name, 2, $app);
	}

	return $model;
}

sub check_installed_programs ($self, $progname) {

	if ($progname) {
		my $model         = $progname->get_model();
		my $progname_iter = $progname->get_active_iter();

		my $progname_value;
		if (defined $progname_iter) {
			$progname_value = $model->get_value($progname_iter, 1);
		}

		$model = $self->get_program_model();
		$progname->set_model($model);

		if ($progname_value) {
			$model->foreach(sub { $self->fct_iter_programs(@_, $progname_value, $progname) });
		} else {
			$progname->set_active(0);
		}

		if ($progname->get_active == -1) {
			$progname->set_active(0);
		}
	}

	return TRUE;
}

sub fct_iter_programs ($self, $model, $path, $iter, $data, $progname_widget) {
	my $program = $model->get_value($iter, 1);

	if ($program eq $data) {
		$progname_widget->set_active_iter($iter);
		return TRUE;
	}

	return FALSE;
}

sub load_plugin_tree ($self, $plugins, $lp) {
	my $effects_model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String');
	my $shutter_root  = $self->_common->shutter_root;

	foreach my $pkey (sort keys %$plugins) {
		if ($plugins->{$pkey}->{'binary'}) {
			unless ($plugins->{$pkey}->{'pixbuf'} || $plugins->{$pkey}->{'pixbuf_object'}) {
				$plugins->{$pkey}->{'pixbuf'} = $plugins->{$pkey}->{'binary'} . ".png"
					if ($self->file_exists($plugins->{$pkey}->{'binary'} . ".png"));
				$plugins->{$pkey}->{'pixbuf'} = $plugins->{$pkey}->{'binary'} . ".svg"
					if ($self->file_exists($plugins->{$pkey}->{'binary'} . ".svg"));

				if ($self->file_exists($plugins->{$pkey}->{'pixbuf'})) {
					$plugins->{$pkey}->{'pixbuf_object'} = $lp->load($plugins->{$pkey}->{'pixbuf'}, ($self->icon_size('menu'))[1]);
				} else {
					$plugins->{$pkey}->{'pixbuf'}        = "$shutter_root/share/shutter/resources/icons/executable.svg";
					$plugins->{$pkey}->{'pixbuf_object'} = $lp->load($plugins->{$pkey}->{'pixbuf'}, ($self->icon_size('menu'))[1]);
				}
			}

			$effects_model->set(
				$effects_model->append,         0, $plugins->{$pkey}->{'pixbuf_object'}, 1, $plugins->{$pkey}->{'name'},   2, $plugins->{$pkey}->{'category'}, 3,
				$plugins->{$pkey}->{'tooltip'}, 4, $plugins->{$pkey}->{'lang'},          5, $plugins->{$pkey}->{'binary'}, 6, $pkey,
			);
		} else {
			$log->warn("Plugin $pkey is not configured properly, ignoring");
			delete $plugins->{$pkey};
		}
	}

	return $effects_model;
}

sub load_accounts_tree ($self, $accounts) {
	my $accounts_model = Gtk3::ListStore->new(
		'Glib::String', 'Glib::String', 'Glib::String',  'Glib::String',  'Glib::String', 'Glib::String', 'Glib::String', 'Glib::String',
		'Glib::String', 'Glib::String', 'Glib::Boolean', 'Glib::Boolean', 'Glib::Boolean'
	);

	foreach (keys %$accounts) {
		my $hidden_text = "";
		for (my $i = 1 ; $i <= length($accounts->{$_}->{'password'} // "") ; $i++) {
			$hidden_text .= '*';
		}
		$accounts_model->set(
			$accounts_model->append,            0, $accounts->{$_}->{'host'},         1,  $accounts->{$_}->{'username'},                  2,
			$hidden_text,                       3, $accounts->{$_}->{'not_used_yet'}, 4,  $accounts->{$_}->{'register_color'},            5,
			$accounts->{$_}->{'register_text'}, 6, $accounts->{$_}->{'module'},       7,  $accounts->{$_}->{'path'},                      8,
			$accounts->{$_}->{'folder'},        9, $accounts->{$_}->{'description'},  10, $accounts->{$_}->{'supports_anonymous_upload'}, 11,
			$accounts->{$_}->{'supports_authorized_upload'}, 12, $accounts->{$_}->{'supports_oauth_upload'},
		);
	}

	return $accounts_model;
}

sub ncmp ($self, $a, $b) {
	my @a_chunks = split /(\d+)/, $a;
	my @b_chunks = split /(\d+)/, $b;
	while (@a_chunks && @b_chunks) {
		my $a_c = shift @a_chunks;
		my $b_c = shift @b_chunks;
		next if $a_c eq $b_c;
		if ($a_c =~ /^\d+$/ && $b_c =~ /^\d+$/) {
			return $a_c <=> $b_c;
		} else {
			return lc($a_c) cmp lc($b_c) || $a_c cmp $b_c;
		}
	}
	return @a_chunks <=> @b_chunks;
}

sub nsort ($self, @list) {
	return sort { $self->ncmp($a, $b) } @list;
}

1;
