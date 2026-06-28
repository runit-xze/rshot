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

package Shutter::App::Handlers::Menu_Ret_Upload;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3 '-init';
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

sub fct_ret_profile_menu ($self, $combobox_settings_profiles, $current_profiles_ref, $menu_profile) {
	my $cli                  = $self->cli;
	my $current_profile_indx = $cli->{_current_profile_indx};

	$menu_profile = Gtk3::Menu->new unless defined $menu_profile;
	foreach my $child ($menu_profile->get_children) {
		$child->destroy;
	}

	my $group = undef;
	foreach my $profile (@{$current_profiles_ref}) {
		my $profile_item = Gtk3::RadioMenuItem->new_with_label($group, $profile);
		$profile_item->set_active(TRUE)
			if $profile eq $combobox_settings_profiles->get_active_text;
		$profile_item->signal_connect(
			'toggled' => sub {
				my $widget = shift;
				return TRUE unless $widget->get_active;

				for (my $i = 0 ; $i < scalar @{$current_profiles_ref} ; $i++) {
					$combobox_settings_profiles->set_active($i);
					$cli->{_current_profile_indx} = $i;
					if ($profile eq $combobox_settings_profiles->get_active_text) {
						$cli->handlers->get('Menu')->evt_apply_profile($widget, $combobox_settings_profiles, $current_profiles_ref);
						last;
					}
				}
			});
		$group = $profile_item unless $group;
		$menu_profile->append($profile_item);
	}

	$menu_profile->show_all;
	return $menu_profile;
}

sub fct_ret_web_menu ($self) {
	my $cli          = $self->cli;
	my $d            = $cli->sc->gettext_object;
	my $settings_xml = $cli->{_settings_xml};

	my $menu_web = Gtk3::Menu->new;

	my $timeout0 = Gtk3::RadioMenuItem->new_with_label(undef,     $d->get("Wait indefinitely"));
	my $timeout1 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d second", "Wait max %d seconds", 10), 10));
	my $timeout2 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d second", "Wait max %d seconds", 10), 30));
	my $timeout3 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d minute", "Wait max %d minutes", 1),  1));
	my $timeout4 = Gtk3::RadioMenuItem->new_with_label($timeout0, sprintf($d->nget("Wait max %d minute", "Wait max %d minutes", 2),  2));

	$timeout0->set_name("timeout0");
	$timeout1->set_name("timeout10");
	$timeout2->set_name("timeout30");
	$timeout3->set_name("timeout60");
	$timeout4->set_name("timeout120");

	$timeout0->set_tooltip_text($d->get("Shutter will wait indefinitely for the screenshot to capture"));
	$timeout1->set_tooltip_text(
		sprintf(
			$d->nget(
				"Shutter will wait up to %d second for the screenshot to capture before aborting the process if it's taking too long",
				"Shutter will wait up to %d seconds for the screenshot to capture before aborting the process if it's taking too long",
				10
			),
			10
		));
	$timeout2->set_tooltip_text(
		sprintf(
			$d->nget(
				"Shutter will wait up to %d second for the screenshot to capture before aborting the process if it's taking too long",
				"Shutter will wait up to %d seconds for the screenshot to capture before aborting the process if it's taking too long",
				30
			),
			30
		));
	$timeout3->set_tooltip_text(
		sprintf(
			$d->nget(
				"Shutter will wait up to %d minute for the screenshot to capture before aborting the process if it's taking too long",
				"Shutter will wait up to %d minutes for the screenshot to capture before aborting the process if it's taking too long",
				1
			),
			1
		));
	$timeout4->set_tooltip_text(
		sprintf(
			$d->nget(
				"Shutter will wait up to %d minute for the screenshot to capture before aborting the process if it's taking too long",
				"Shutter will wait up to %d minutes for the screenshot to capture before aborting the process if it's taking too long",
				2
			),
			2
		));

	$timeout2->set_active(TRUE);
	$menu_web->append($timeout0);
	$menu_web->append($timeout1);
	$menu_web->append($timeout2);
	$menu_web->append($timeout3);
	$menu_web->append($timeout4);

	if (defined $settings_xml && defined $settings_xml->{'general'}->{'web_timeout'}) {

		#determining timeout
		my @timeouts = $menu_web->get_children;
		my $timeout  = undef;
		foreach my $to (@timeouts) {
			$timeout = $to->get_name;
			$timeout =~ /([0-9]+)/;
			$timeout = $1;
			if ($settings_xml->{'general'}->{'web_timeout'} == $timeout) {
				$to->set_active(TRUE);
			}
		}
	}
	$menu_web->show_all;
	return $menu_web;
}

1;

__END__

=head1 NAME

Shutter::App::Handlers::Menu_Ret_Upload - Upload menu return handlers

=head1 DESCRIPTION

Extracted from bin/shutter.
Migrated to use the CLI object for state access instead of package globals.

=cut
