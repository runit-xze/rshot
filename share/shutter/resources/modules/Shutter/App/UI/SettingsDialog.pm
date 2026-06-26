###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2020-2021 Google LLC, contributed by Alexey Sokolov <sokolov@google.com>
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

package Shutter::App::UI::SettingsDialog;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib                    qw/TRUE FALSE/;
use Shutter::App::Constants qw/SHUTTER_NAME/;
use Shutter::App::UI::Settings::Main;
use Shutter::App::UI::Settings::Behavior;
use Shutter::App::UI::Settings::Capture;
use Shutter::App::UI::Settings::Upload;
use Shutter::App::UI::Settings::Plugins;
use Shutter::App::UI::Settings::ShareX;
use Shutter::App::UI::Settings::Video;

has 'cli'           => (is => 'ro', required => 1);
has '_dialog'       => (is => 'rw');
has '_profiles_box' => (is => 'rw');
has '_tabs'         => (is => 'rw', default => sub { [] });

sub create_settings_dialog ($self, $window) {
	my $sc = $self->cli->sc;
	my $d  = $sc->gettext_object;

	my $dialog = Gtk3::Dialog->new(SHUTTER_NAME . " - " . $d->get("Preferences"), $window, [qw/modal destroy-with-parent/], 'gtk-close' => 'close');

	my $notebook = Gtk3::Notebook->new;
	$notebook->set_tab_pos('left');
	$notebook->set_border_width(6);

	# Main Tab
	my $tab_main = Shutter::App::UI::Settings::Main->new(cli => $self->cli);
	$notebook->append_page($tab_main->get_widget, Gtk3::Label->new($d->get("Main")));
	push @{$self->_tabs}, $tab_main;

	# Behavior Tab
	my $tab_behavior = Shutter::App::UI::Settings::Behavior->new(cli => $self->cli);
	$notebook->append_page($tab_behavior->get_widget, Gtk3::Label->new($d->get("Behavior")));
	push @{$self->_tabs}, $tab_behavior;

	# Capture Tab
	my $tab_capture = Shutter::App::UI::Settings::Capture->new(cli => $self->cli);
	$notebook->append_page($tab_capture->get_widget, Gtk3::Label->new($d->get("Capture")));
	push @{$self->_tabs}, $tab_capture;

	# Upload Tab
	my $tab_upload = Shutter::App::UI::Settings::Upload->new(cli => $self->cli);
	$notebook->append_page($tab_upload->get_widget, Gtk3::Label->new($d->get("Upload")));
	push @{$self->_tabs}, $tab_upload;

	# Video Tab
	my $tab_video = Shutter::App::UI::Settings::Video->new(cli => $self->cli);
	$notebook->append_page($tab_video->get_widget, Gtk3::Label->new($d->get("Video")));
	push @{$self->_tabs}, $tab_video;

	# Plugins Tab
	my $tab_plugins = Shutter::App::UI::Settings::Plugins->new(cli => $self->cli);
	$notebook->append_page($tab_plugins->get_widget, Gtk3::Label->new($d->get("Plugins")));
	push @{$self->_tabs}, $tab_plugins;

	# ShareX Tab
	my $tab_sharex = Shutter::App::UI::Settings::ShareX->new(cli => $self->cli);
	$notebook->append_page($tab_sharex->get_widget, Gtk3::Label->new($d->get("ShareX")));
	push @{$self->_tabs}, $tab_sharex;

	# Workflow Tab
	my $workflow_vbox = Gtk3::VBox->new(FALSE, 6);
	$workflow_vbox->pack_start($self->cli->workflow->get_workflow_widget, TRUE, TRUE, 0);
	$workflow_vbox->set_border_width(12);

	my $workflow_label = Gtk3::Label->new($d->get("Workflow"));
	$notebook->append_page($workflow_vbox, $workflow_label);
	push @{$self->_tabs}, $self->cli->workflow;

	$dialog->get_content_area->add($notebook);
	$dialog->set_default_size(600, 450);

	$self->_dialog($dialog);
	return $dialog;
}

sub save ($self) {
	foreach my $tab (@{$self->_tabs}) {
		$tab->save          if $tab->can('save');
		$tab->save_settings if $tab->can('save_settings');
	}
	$self->cli->{settings_manager}->save_settings;
	return;
}

sub show ($self) {
	$self->_dialog->show_all   if $self->_dialog;
	return $self->_dialog->run if $self->_dialog;
	return;
}

sub hide ($self) {
	$self->_dialog->hide() if $self->_dialog;
	return;
}

1;
