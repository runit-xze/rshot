package Shutter::Screenshot::Window::CaptureManager;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;
use Future;

requires qw(
	find_wm_window
	find_active_window
	find_region_for_window_type
	get_window_size
	get_pixbuf_from_drawable_async
	get_shape
	select_window
);

sub redo_capture_async ($self) {
	my $f      = Future->new;
	my $output = 3;

	if (defined $self->{_history}) {
		my ($last_drawable, $lxp, $lyp, $lwp, $lhp, $lregion, $wxid, $gxid) = $self->{_history}->get_last_capture;

		if (defined $gxid && defined $wxid) {

			#create windows
			my $gdk_window  = Gtk3::GdkX11::X11Window->foreign_new_for_display(Gtk3::Gdk::Display::get_default(), $gxid);
			my $wnck_window = Wnck::Window::get($wxid);

			if (defined $gdk_window && defined $wnck_window) {

				#store size
				my ($xp, $yp, $wp, $hp, $xc, $yc, $wc, $hc) = (0, 0, 0, 0, 0, 0, 0, 0);

				if ($self->{_mode} eq "section" || $self->{_mode} eq "tray_section") {

					($xp, $yp, $wp, $hp) = $gdk_window->get_geometry;
					($xp, $yp) = $gdk_window->get_origin;

					#find parent window
					my $pxid   = $self->find_wm_window($gxid);
					my $parent = Gtk3::GdkX11::X11Window->foreign_new_for_display(Gtk3::Gdk::Display::get_default(), $pxid);
					if (defined $parent && $parent) {

						#and focus parent window (maybe it is hidden)
						$parent->focus(Gtk3::get_current_event_time());
						Gtk3::Gdk::flush();
					}

				} elsif ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {

					#get_size of it
					($xc, $yc, $wc, $hc) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border}, TRUE);
					($xp, $yp, $wp, $hp) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border});

				}

				#focus selected window (maybe it is hidden)
				$gdk_window->focus(Gtk3::get_current_event_time());
				Gtk3::Gdk::flush();

				#A short timeout to give the server a chance to
				#redraw the area
				Glib::Timeout->add(
					$self->{_hide_time},
					sub {
						$self->get_pixbuf_from_drawable_async($self->{_root}, $xp, $yp, $wp, $hp)->then(
							sub {
								my ($output_new, $l_cropped, $r_cropped, $t_cropped, $b_cropped) = @_;

								#save return value to current $output variable
								#-> ugly but fastest and safest solution now
								$output = $output_new;

								if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
									if ($self->{_include_border}) {
										$output = $self->get_shape($gxid, $output, $l_cropped, $r_cropped, $t_cropped, $b_cropped);
									}
								}

								#restore window size when autoresizing was used
								if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
									if (defined $self->{_windowresize} && $self->{_windowresize}) {
										if ($wc != $wp || $hc != $hp) {
											if ($self->{_include_border}) {
												$wnck_window->set_geometry('current', [qw/width height/], $xc, $yc, $wc, $hc);
											} else {
												$gdk_window->resize($wc, $hc);
											}
										}
									}
								}

								$self->quit_eventh_only;
								$f->done($output);
								return Future->done();
							})->retain;
						return FALSE;
					});

			} else {
				warn "WARNING: Could not get window with id $gxid\n";
				$output = 4;
				$f->done($output);
			}

			#no xid
		} else {
			$self->get_pixbuf_from_drawable_async($self->{_history}->get_last_capture)->then(
				sub {
					my ($output_new) = @_;
					$output = $output_new;
					$f->done($output);
					return Future->done();
				})->retain;
		}

	} else {
		$f->done($output);
	}

	return $f;
}

sub _capture_noninteractive ($self, $f, $initevent) {

	my ($xp, $yp, $wp, $hp, $xc, $yc, $wc, $hc) = (0, 0, 0, 0, 0, 0, 0, 0);

	if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {

		#and select current parent window
		my ($wnck_window, $gdk_window) = $self->find_active_window;

		if (defined $wnck_window && $wnck_window && defined $gdk_window && $gdk_window) {

			#get_size of it
			($xc, $yc, $wc, $hc) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border}, TRUE);
			($xp, $yp, $wp, $hp) = $self->get_window_size($wnck_window, $gdk_window, $self->{_include_border});

			$self->{_c}{'cw'}{'window'}     = $wnck_window;
			$self->{_c}{'cw'}{'gdk_window'} = $gdk_window;
			$self->{_c}{'cw'}{'x'}          = $xp;
			$self->{_c}{'cw'}{'y'}          = $yp;
			$self->{_c}{'cw'}{'width'}      = $wp;
			$self->{_c}{'cw'}{'height'}     = $hp;
			$self->{_c}{'cw'}{'is_parent'}  = TRUE;

		}

	} elsif (($self->{_mode} eq "menu" || $self->{_mode} eq "tray_menu")) {

		#and select current menu
		$self->find_region_for_window_type($self->{_root}->get_xid, 'menu');

		#no window with type_hint eq 'menu' detected
		unless (defined $self->{_c}{'cw'}{'window_region'}) {
			if ($self->{_ignore_type}) {
				warn "WARNING: No window with type hint 'menu' detected -> window type hint will be ignored, because workaround is enabled\n";
				$self->find_region_for_window_type($self->{_root}->get_xid);
			} else {
				$f->done(2);
				return;
			}
		}

	} elsif (($self->{_mode} eq "tooltip" || $self->{_mode} eq "tray_tooltip")) {

		#and select current tooltip
		$self->find_region_for_window_type($self->{_root}->get_xid, 'tooltip');

		#no window with type_hint eq 'tooltip' detected
		unless (defined $self->{_c}{'cw'}{'window_region'}) {
			if ($self->{_ignore_type}) {
				warn "WARNING: No window with type hint 'tooltip' detected -> window type hint will be ignored, because workaround is enabled\n";
				$self->find_region_for_window_type($self->{_root}->get_xid);
			} else {
				$f->done(2);
				return;
			}
		}

		#looking for a section of a window?
		#keep current window in mind and search for children
	} elsif (($self->{_mode} eq "section" || $self->{_mode} eq "tray_section")) {

		#mark as selected parent window
		$self->{_c}{'ws'} = $self->{_root};

		#and select current subwindow
		$self->select_window($initevent);

	}

	$self->get_pixbuf_from_drawable_async($self->{_root}, $self->{_c}{'cw'}{'x'}, $self->{_c}{'cw'}{'y'}, $self->{_c}{'cw'}{'width'}, $self->{_c}{'cw'}{'height'}, $self->{_c}{'cw'}{'window_region'})
		->then(
		sub {
			my ($output_new, $l_cropped, $r_cropped, $t_cropped, $b_cropped) = @_;

			my $result = $output_new;

			#respect rounded corners of wm decorations
			#(metacity for example - does not work with compiz currently)
			#only if toplevel window was selected
			if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {
				if ($self->{_include_border}) {
					my $xid = $self->{_c}{'cw'}{'gdk_window'}->get_xid;

					#do not try this for child windows
					foreach my $win (@{$self->{_wnck_screen}->get_windows}) {
						if ($win->get_xid == $xid) {
							$result = $self->get_shape($xid, $result, $l_cropped, $r_cropped, $t_cropped, $b_cropped);
							last;
						}
					}
				}
			}

			#restore window size when autoresizing was used
			if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
				if (defined $self->{_windowresize} && $self->{_windowresize}) {
					if ($wc != $wp || $hc != $hp) {
						if ($self->{_include_border}) {
							$self->{_c}{'cw'}{'window'}->set_geometry('current', [qw/width height/], $xc, $yc, $wc, $hc);
						} else {
							$self->{_c}{'cw'}{'gdk_window'}->resize($wc, $hc);
						}
					}
				}
			}

			#set name of the captured window
			#e.g. for use in wildcards
			my $d = $self->{_sc}->gettext_object;

			if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {

				if ($result =~ /Gtk3/ && defined $self->{_c}{'cw'}{'window'}) {
					$self->{_action_name} = $self->{_c}{'cw'}{'window'}->get_name;
				}

			} elsif (($self->{_mode} eq "section" || $self->{_mode} eq "tray_section")) {

				if ($result =~ /Gtk3/ && defined $self->{_c}{'cw'}{'window'}) {
					$self->{_action_name} = $self->{_action_name} = $self->{_c}{'cw'}{'window'}->get_name;
				}

			} elsif (($self->{_mode} eq "menu" || $self->{_mode} eq "tray_menu")) {

				if ($result =~ /Gtk3/) {
					$self->{_action_name} = $d->get("Menu");
				}

			} elsif (($self->{_mode} eq "tooltip" || $self->{_mode} eq "tray_tooltip")) {

				if ($result =~ /Gtk3/) {
					$self->{_action_name} = $d->get("Tooltip");
				}

			}

			if (defined $self->{_c}{'cw'}{'window'} && $self->{_c}{'cw'}{'gdk_window'}) {

				#set history object
				$self->{_history} = Shutter::Screenshot::History->new(
					$self->{_sc},                       $self->{_root},                       $self->{_c}{'cw'}{'x'},
					$self->{_c}{'cw'}{'y'},             $self->{_c}{'cw'}{'width'},           $self->{_c}{'cw'}{'height'},
					$self->{_c}{'cw'}{'window_region'}, $self->{_c}{'cw'}{'window'}->get_xid, $self->{_c}{'cw'}{'gdk_window'}->get_xid
				);

			} else {

				#set history object
				$self->{_history} = Shutter::Screenshot::History->new(
					$self->{_sc}, $self->{_root},
					$self->{_c}{'cw'}{'x'},
					$self->{_c}{'cw'}{'y'},
					$self->{_c}{'cw'}{'width'},
					$self->{_c}{'cw'}{'height'},
					$self->{_c}{'cw'}{'window_region'},
				);

			}
			$f->done($result);
			return Future->done();
		})->retain;
	return;
}

sub _init_capture_state ($self) {

	$self->{_c}                     = ();
	$self->{_c}{'ws'}               = undef;
	$self->{_c}{'ws_init'}          = FALSE;
	$self->{_c}{'lw'}{'gdk_window'} = 0;

	$self->{_min_size}              = $self->{_root}->{w} * $self->{_root}->{h} * $self->{_dpi_scale} * $self->{_dpi_scale};
	$self->{_c}{'cw'}{'gdk_window'} = $self->{_root};
	$self->{_c}{'cw'}{'x'}          = $self->{_root}->{x};
	$self->{_c}{'cw'}{'y'}          = $self->{_root}->{y};
	$self->{_c}{'cw'}{'width'}      = $self->{_root}->{w};
	$self->{_c}{'cw'}{'height'}     = $self->{_root}->{h};

	my ($window_at_pointer, $initx, $inity, $mask) = $self->{_root}->get_pointer;

	my $initevent = Gtk3::Gdk::Event->new('motion-notify');
	$initevent->time(Gtk3::get_current_event_time());
	$initevent->window($self->{_root});
	$initevent->x($initx);
	$initevent->y($inity);

	return $initevent;
}

1;
