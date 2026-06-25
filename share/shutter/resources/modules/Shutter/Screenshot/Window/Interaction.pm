package Shutter::Screenshot::Window::Interaction;

use utf8;
use v5.40;
use Moo::Role;
use Glib qw/TRUE FALSE/;
use Gtk3;
use Future;

requires qw(
    select_window
    get_window_size
    get_pixbuf_from_drawable_async
    get_shape
    quit
    quit_eventh_only
);

sub _capture_interactive ($self, $f, $active_workspace, $initevent) {

	$self->select_window($initevent, $active_workspace);

	Gtk3::Gdk::Event::handler_set(
		sub {
			my ($event, $data) = @_;
			return FALSE unless defined $event;

			#KEY-PRESS
			if ($event->type eq 'key-press') {
				next unless defined $event->keyval;

				if ($event->keyval == Gtk3::Gdk::keyval_from_name('Escape')) {

					#destroy highlighter window
					$self->{_highlighter}->destroy;

					$self->quit;

					$f->done(5);
				}

				#BUTTON-PRESS
			} elsif ($event->type eq 'button-press') {
				print "Type: " . $event->type . "\n"
					if (defined $event && $self->{_sc}->get_debug);

				#user selects window or section
				$self->select_window($event, $active_workspace);

				#BUTTON-RELEASE
			} elsif ($event->type eq 'button-release') {
				print "Type: " . $event->type . "\n" if (defined $event && $self->{_sc}->get_debug);

				my ($xp, $yp, $wp, $hp, $xc, $yc, $wc, $hc) = (0, 0, 0, 0, 0, 0, 0, 0);

				if (defined $self->{_c}{'lw'} && $self->{_c}{'lw'}{'gdk_window'}) {

					#size (we need to do this again because of autoresizing)
					if (($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow")) {
						($xc, $yc, $wc, $hc) = $self->get_window_size($self->{_c}{'lw'}{'window'}, $self->{_c}{'lw'}{'gdk_window'}, $self->{_include_border}, TRUE);
						($xp, $yp, $wp, $hp) = $self->get_window_size($self->{_c}{'lw'}{'window'}, $self->{_c}{'lw'}{'gdk_window'}, $self->{_include_border});

						$self->{_c}{'cw'}{'x'}      = $xp;
						$self->{_c}{'cw'}{'y'}      = $yp;
						$self->{_c}{'cw'}{'width'}  = $wp;
						$self->{_c}{'cw'}{'height'} = $hp;
					}

					#focus selected window (maybe it is hidden)
					$self->{_c}{'lw'}{'gdk_window'}->focus($event->time);
					Gtk3::Gdk::flush();

					#something went wrong here, no window on screen detected
				} else {

					$self->quit;
					$f->done(0);
					return FALSE;

				}

				#looking for a section of a window?
				#keep current window in mind and search for children
				if (($self->{_mode} eq "section" || $self->{_mode} eq "tray_section")
					&& !$self->{_c}{'ws'})
				{

					#mark as selected parent window
					$self->{_c}{'ws'}      = $self->{_c}{'cw'}{'gdk_window'};
					$self->{_c}{'ws_init'} = TRUE;

					#and select current subwindow
					$self->select_window($event);

					#we don't take the screenshot yet
					return TRUE;
				}

				#stop event handler
				$self->quit_eventh_only;

				#destroy highlighter window
				$self->{_highlighter}->destroy;

				#A short timeout to give the server a chance to
				#redraw the area
				Glib::Timeout->add($self->{_hide_time}, sub {
					$self->get_pixbuf_from_drawable_async($self->{_root}, $self->{_c}{'cw'}{'x'} / $self->{_dpi_scale}, $self->{_c}{'cw'}{'y'} / $self->{_dpi_scale}, $self->{_c}{'cw'}{'width'} / $self->{_dpi_scale}, $self->{_c}{'cw'}{'height'} / $self->{_dpi_scale}, undef)->then(sub {
							my ($output_new, $l_cropped, $r_cropped, $t_cropped, $b_cropped) = @_;

				my $result = $output_new;

				#respect rounded corners of wm decorations (metacity for example - does not work with compiz currently)
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

				#restore window size when autoresizing was used
				if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
					if (defined $self->{_windowresize} && $self->{_windowresize}) {
						if ($wc != $wp || $hc != $hp) {
							if ($self->{_include_border}) {
								$self->{_c}{'lw'}{'window'}->set_geometry('current', [qw/width height/], $xc, $yc, $wc, $hc);
							} else {
								$self->{_c}{'lw'}{'gdk_window'}->resize($wc, $hc);
							}
						}
					}
				}

				#set name of the captured window
				#e.g. for use in wildcards
				if ($result =~ /Gtk3/ && defined $self->{_c}{'cw'}{'window'}) {
					$self->{_action_name} = $self->{_c}{'cw'}{'window'}->get_name;
				}

				#set history object
				$self->{_history} = Shutter::Screenshot::History->new(
					$self->{_sc},           $self->{_root},                       $self->{_c}{'cw'}{'x'},
					$self->{_c}{'cw'}{'y'}, $self->{_c}{'cw'}{'width'},           $self->{_c}{'cw'}{'height'},
					undef,                  $self->{_c}{'cw'}{'window'}->get_xid, $self->{_c}{'cw'}{'gdk_window'}->get_xid
				);

				$self->quit;
						$f->done($result);
							return Future->done();
						})->retain;
						return FALSE;
					});

					#MOTION-NOTIFY
				} elsif ($event->type eq 'motion-notify') {
					print "Type: " . $event->type . "\n"
						if (defined $event && $self->{_sc}->get_debug);

					#user selects window or section
					$self->select_window($event, $active_workspace);

				} else {
					Gtk3::main_do_event($event);
				}
			});
}

1;
