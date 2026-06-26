package Shutter::Screenshot::Window::Selector;
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Moo::Role;
use Glib qw(TRUE FALSE);
use Gtk3;
use Pango;

sub update_highlighter ($self) {

	if (defined $self->{_c}{'cw'}{'gdk_window'} && defined $self->{_c}{'cw'}{'window'}) {

		#and show highlighter window at current cursor position
		$self->{_highlighter}->show_all;
		$self->{_highlighter}->queue_draw;

		Gtk3::Gdk::keyboard_grab($self->{_highlighter}->get_window, 0, Gtk3::get_current_event_time());

		#save last window objects
		$self->{_c}{'lw'}{'window'}     = $self->{_c}{'cw'}{'window'};
		$self->{_c}{'lw'}{'gdk_window'} = $self->{_c}{'cw'}{'gdk_window'};

	}
	return;
}

sub find_current_parent_window ($self, $event, $active_workspace) {

	#get all toplevel windows
	my @wnck_windows = @{$self->{_wnck_screen}->get_windows_stacked};

	#show user-visible windows only when selecting a window
	if (defined $self->{_show_visible} && $self->{_show_visible}) {
		@wnck_windows = reverse @wnck_windows;
	}

	foreach my $cwdow (@wnck_windows) {

		my $drawable = Gtk3::GdkX11::X11Window->foreign_new_for_display(Gtk3::Gdk::Display::get_default(), $cwdow->get_xid);
		if (defined $drawable) {

			#do not detect shutter window when it is hidden
			if ($self->{_main_gtk_window}->get_window && $self->{_is_hidden}) {
				next if ($cwdow->get_xid == $self->{_main_gtk_window}->get_window->get_xid);
			}

			my ($xp, $yp, $wp, $hp) = $self->get_window_size($cwdow, $drawable, $self->{_include_border}, TRUE);

			my $wr = Cairo::Region->create({
				x      => $xp,
				y      => $yp,
				width  => $wp,
				height => $hp,
			});

			if (   $cwdow->is_visible_on_workspace($active_workspace)
				&& $wr->contains_point($event->x * $self->{_dpi_scale}, $event->y * $self->{_dpi_scale})
				&& $wp * $hp <= $self->{_min_size})
			{

				$self->{_c}{'cw'}{'window'}     = $cwdow;
				$self->{_c}{'cw'}{'gdk_window'} = $drawable;
				$self->{_c}{'cw'}{'x'}          = $xp;
				$self->{_c}{'cw'}{'y'}          = $yp;
				$self->{_c}{'cw'}{'width'}      = $wp;
				$self->{_c}{'cw'}{'height'}     = $hp;
				$self->{_c}{'cw'}{'is_parent'}  = TRUE;
				$self->{_min_size}              = $wp * $hp;

				#show user-visible windows only when selecting a window
				if (defined $self->{_show_visible} && $self->{_show_visible}) {
					last;
				}

			}    #size and geometry check

		}    #not defined gdk::window

	}    #end if toplevel window loop

	return TRUE;
}

sub find_current_child_window ($self, $event, $xwindow, $xparent, $depth = undef, $limit = undef, $type_hint = undef) {

	#reparenting depth and recursion limit
	$depth = 0 unless defined $depth;
	$limit = 0 unless defined $limit;
	if ($depth > $limit) {
		return TRUE;
	}

	my ($qroot, $qparent, @qkids);
	unless (defined $self->{_c}{'cw'}{$xwindow} && scalar @{$self->{_c}{'cw'}{$xwindow}}) {

		#query all child windows of xwindow
		($qroot, $qparent, @qkids) = $self->{_x11}->QueryTree($xwindow);

		#and save them, so we don't have to query them again
		@{$self->{_c}{'cw'}{$xwindow}} = @qkids;

	} else {

		#we can use the cached children information
		@qkids = @{$self->{_c}{'cw'}{$xwindow}};

	}

	foreach my $kid (reverse @qkids) {

		my $gdk_window = Gtk3::GdkX11::X11Window->foreign_new_for_display(Gtk3::Gdk::Display::get_default(), $kid);
		if (defined $gdk_window) {

			#window needs to be viewable and visible
			next unless $gdk_window->is_visible;
			next unless $gdk_window->is_viewable;

			#check type_hint
			if (defined $type_hint) {
				my $curr_type_hint = $gdk_window->get_type_hint;
				next unless $curr_type_hint =~ /$type_hint/;
			}

			#~ print $curr_type_hint, " - passed \n";

			#min size
			my ($xp, $yp, $wp, $hp, $depthp) = $gdk_window->get_geometry;
			($xp, $yp) = $gdk_window->get_origin;
			next if ($wp * $hp < 4);

			my $sr = Cairo::Region->create({x => $xp, y => $yp, width => $wp, height => $hp});

			if ($sr->contains_point($event->x, $event->y) && $wp * $hp <= $self->{_min_size}) {

				$self->{_c}{'cw'}{'gdk_window'} = $gdk_window;
				$self->{_c}{'cw'}{'x'}          = $xp;
				$self->{_c}{'cw'}{'y'}          = $yp;
				$self->{_c}{'cw'}{'width'}      = $wp;
				$self->{_c}{'cw'}{'height'}     = $hp;
				$self->{_c}{'cw'}{'is_parent'}  = FALSE;
				$self->{_min_size}              = $wp * $hp;

				#~ print $self->{_c}{'cw'}{'x'}, " - ",
				#~ $self->{_c}{'cw'}{'y'}, " - ",
				#~ $self->{_c}{'cw'}{'width'}, " - ",
				#~ $self->{_c}{'cw'}{'height'}, " \n " if $self->{_sc}->get_debug;

				#check next depth
				unless ($gdk_window->get_xid == $xwindow) {
					$self->find_current_child_window($event, $gdk_window->get_xid, $xparent, $depth++, $limit, $type_hint);
				} else {
					last;
				}

				#~ last;

			}
		}
	}

	return TRUE;
}

sub select_window ($self, $event, $active_workspace, $depth = undef, $limit = undef, $type_hint = undef) {

	#root window size is minimum at startup
	$self->{_min_size} = $self->{_root}->{w} * $self->{_root}->{h} * $self->{_dpi_scale} * $self->{_dpi_scale};

	#if there is no window already selected
	unless ($self->{_c}{'ws'}) {

		$self->find_current_parent_window($event, $active_workspace);

		#parent window selected/no grab, search for children now
	} elsif (($self->{_mode} eq "section" || $self->{_mode} eq "tray_section") && $self->{_c}{'ws'}) {

		$self->find_current_child_window($event, $self->{_c}{'ws'}->get_xid, $self->{_c}{'ws'}->get_xid, $depth, $limit, $type_hint);
	}

	#draw highlighter if needed
	if (   (Gtk3::Gdk::pointer_is_grabbed() && ($self->{_c}{'lw'}{'gdk_window'} ne $self->{_c}{'cw'}{'gdk_window'}))
		|| (Gtk3::Gdk::pointer_is_grabbed() && $self->{_c}{'ws_init'}))
	{
		$self->update_highlighter();

		#reset flag
		$self->{_c}{'ws_init'} = FALSE;
	}

	return TRUE;
}

1;
