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

package Shutter::Screenshot::Workspace;

#modules
#--------------------------------------
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Shutter::Screenshot::Main;
use Shutter::Screenshot::History;
use Data::Dumper;
use Moo;
extends 'Shutter::Screenshot::Main';

use Glib qw/TRUE FALSE/;
use Future;
use Future::Utils qw(repeat);

#--------------------------------------

has '_selected_workspace'   => (is => 'rw');
has '_vpx'                  => (is => 'rw');
has '_vpy'                  => (is => 'rw');
has '_current_monitor_only' => (is => 'rw');

sub workspaces_async ($self) {

	my $d = $self->{_sc}->gettext_object;

	my $active_workspace = $self->{_wnck_screen}->get_active_workspace;

	#valid workspace?
	return Future->done(TRUE) unless $active_workspace;

	my $active_vpx = $active_workspace->get_viewport_x;
	my $active_vpy = $active_workspace->get_viewport_y;

	#create shutter region object
	my $sr = Shutter::Geometry::Region->new();

	my $wspaces_region = Cairo::Region->create;
	my @pixbuf_array;
	my @rects_array;
	my $row    = 0;
	my $column = 0;
	my $height = 0;
	my $width  = 0;

	# Prepare a flat list of coordinates/workspaces to capture
	my @tasks;
	foreach my $space (@{$self->{_workspaces}}) {
		next unless defined $space;

		if ($self->{_wm_manager_name} =~ /compiz/i) {
			my $n_viewports_column = int($space->get_width / $self->{_wnck_screen}->get_width);
			my $n_viewports_rows   = int($space->get_height / $self->{_wnck_screen}->get_height);
			for (my $j = 0 ; $j < $n_viewports_rows ; $j++) {
				for (my $i = 0 ; $i < $n_viewports_column ; $i++) {
					push @tasks,
						{
						type  => 'compiz',
						space => $space,
						vp    => [$i * $self->{_wnck_screen}->get_width, $j * $self->{_wnck_screen}->get_height]};
				}
			}
		} else {
			push @tasks, {type => 'normal', space => $space};
		}
	}

	my $f = repeat {
		my $task  = shift;
		my $space = $task->{space};

		if ($task->{type} eq 'compiz') {
			$self->{_vpx}                = $task->{vp}[0];
			$self->{_vpy}                = $task->{vp}[1];
			$self->{_selected_workspace} = undef;
		} else {
			$self->{_selected_workspace} = $space->get_number;
		}

		$self->workspace_async(TRUE, TRUE)->then(
			sub {
				my $pixbuf = shift;

				if ($task->{type} eq 'compiz') {
					my $rect = {x => $width, y => $height, width => $pixbuf->get_width, height => $pixbuf->get_height};
					$wspaces_region->union_rectangle($rect);
					push @pixbuf_array, $pixbuf;
					push @rects_array,  $rect;

					$width += $pixbuf->get_width;

					# Wait, row tracking in compiz from original code:
					# It resets width and advances height inside the inner loop logic.
					# To simulate this correctly:
					my $n_viewports_column = int($space->get_width / $self->{_wnck_screen}->get_width);
					if (@pixbuf_array % $n_viewports_column == 0) {
						$height = $sr->get_clipbox($wspaces_region)->{height};
						$width  = 0;
					}
				} else {
					if ($column < $space->get_layout_column) {
						$width += $pixbuf->get_width;
					} elsif ($column > $space->get_layout_column) {
						$width = 0;
					}
					$column = $space->get_layout_column;

					$height = $sr->get_clipbox($wspaces_region)->{height} if ($row != $space->get_layout_row);
					$row    = $space->get_layout_row;

					my $rect = {x => $width, y => $height, width => $pixbuf->get_width, height => $pixbuf->get_height};
					$wspaces_region->union_rectangle($rect);
					push @pixbuf_array, $pixbuf;
					push @rects_array,  $rect;
				}
				return Future->done();
			});
	}
	foreach => \@tasks;

	return $f->then(
		sub {
			my $output = undef;
			if ($wspaces_region->num_rectangles) {
				$output = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, $sr->get_clipbox($wspaces_region)->{width}, $sr->get_clipbox($wspaces_region)->{height});
				$output->fill(0x00000000);

				my $rect_counter = 0;
				foreach my $pix (@pixbuf_array) {
					$pix->copy_area(0, 0, $pix->get_width, $pix->get_height, $output, $rects_array[$rect_counter]->{x}, $rects_array[$rect_counter]->{y});
					$rect_counter++;
				}
			}

			$self->{_selected_workspace} = 'all';
			$self->{_history}            = Shutter::Screenshot::History->new($self->{_sc});

			if ($output && $output =~ /Gtk3/) {
				$self->{_action_name} = $d->get("Workspaces");
			}

			if ($self->{_wm_manager_name} =~ /compiz/i) {
				$self->{_wnck_screen}->move_viewport($active_vpx, $active_vpy);
			} else {
				$active_workspace->activate(Gtk3::get_current_event_time());
			}

			return Future->done($output);
		});
}

sub workspace_async ($self, $no_active_check = undef, $no_finishing = undef) {

	my $wrksp_changed    = FALSE;
	my $active_workspace = $self->{_wnck_screen}->get_active_workspace;

	#valid workspace?
	return Future->done(TRUE) unless $active_workspace;

	my $active_vpx = $active_workspace->get_viewport_x;
	my $active_vpy = $active_workspace->get_viewport_y;

	#metacity etc
	if (defined $self->{_selected_workspace}) {
		foreach my $space (@{$self->{_workspaces}}) {
			next unless defined $space;
			if ($self->{_selected_workspace} == $space->get_number
				&& ($no_active_check || $self->{_selected_workspace} != $active_workspace->get_number))
			{
				$space->activate(Gtk3::get_current_event_time());
				$wrksp_changed = TRUE;
			}
		}
	} else {
		if (defined $self->{_vpx} && defined $self->{_vpy}) {
			$self->{_wnck_screen}->move_viewport($self->{_vpx}, $self->{_vpy});
			$wrksp_changed = TRUE;
		}
	}

	if ($self->{_delay} < 2 && $wrksp_changed) {
		$self->{_delay} = 1;
	}

	my $f;
	if ($self->{_current_monitor_only} || $self->{_gdk_screen}->get_n_monitors <= 1) {
		$f = $self->get_pixbuf_from_drawable_async($self->get_root_and_current_monitor_geometry);
	} elsif ($self->{_gdk_screen}->get_n_monitors > 1) {
		$f = $self->get_pixbuf_from_drawable_async($self->get_root_and_geometry, $self->get_monitor_region);
	} else {
		$f = Future->done();
	}

	return $f->then(
		sub {
			my ($output) = @_;

			unless ($no_finishing) {
				$self->{_history} = Shutter::Screenshot::History->new($self->{_sc});
				if ($output && $output =~ /Gtk3/) {
					$self->{_action_name} = $self->{_wnck_screen}->get_active_workspace->get_name;
				}
				if ($self->{_selected_workspace}) {
					$active_workspace->activate(Gtk3::get_current_event_time()) if $wrksp_changed;
				} else {
					$self->{_wnck_screen}->move_viewport($active_vpx, $active_vpy);
				}
			}
			return Future->done($output);
		});
}

sub redo_capture_async ($self) {
	if (defined $self->{_history} && $self->{_selected_workspace} eq 'all') {
		return $self->workspaces_async();
	} elsif (defined $self->{_history}) {
		return $self->workspace_async();
	}
	return Future->done(3);
}

sub get_history ($self) {
	return $self->{_history};
}

sub get_error_text ($self) {
	return $self->{_error_text};
}

sub get_action_name ($self) {
	return $self->{_action_name};
}

1;
