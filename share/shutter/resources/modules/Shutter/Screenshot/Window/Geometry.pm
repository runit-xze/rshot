package Shutter::Screenshot::Window::Geometry;
use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Moo::Role;
use IO::File;
use Shutter::App::HelperFunctions;
use Glib qw(TRUE FALSE);
use Gtk3;
use Cairo;

sub find_wm_window ($self, $xid) {

	do {
		my ($qroot, $qparent, @qkids) = $self->{_x11}->QueryTree($xid);
		return unless ($qroot || $qparent);
		return $xid if ($qroot == $qparent);
		$xid = $qparent;
	} while (TRUE);
}

sub get_shape ($self, $xid, $orig, $l_cropped, $r_cropped, $t_cropped, $b_cropped) {

	print "$l_cropped, $r_cropped, $t_cropped, $b_cropped cropped\n" if $self->{_sc}->get_debug;

	print "Calculating window shape\n" if $self->{_sc}->get_debug;

	#check if extenstion is available and use it
	my ($ordering, @r) = (undef, undef);
	if ($self->{_x11}{ext_shape}) {
		($ordering, @r) = $self->{_x11}->ShapeGetRectangles($self->find_wm_window($xid), 'Bounding');
	}

	my $manually_shaped = FALSE;

	#create shape manually when option is set and the shape was not detected automatically
	if (scalar @r <= 1 && defined $self->{_auto_shape} && $self->{_auto_shape}) {

		my $shf = Shutter::App::HelperFunctions->new($self->{_sc});

		my $shape_path = undef;
		$shape_path = $self->{_sc}->get_root . "/share/shutter/resources/conf/shape.conf" if $shf->file_exists($self->{_sc}->get_root . "/share/shutter/resources/conf/shape.conf");
		$shape_path = "$ENV{'HOME'}/.shutter/shape.conf" if $shf->file_exists("$ENV{'HOME'}/.shutter/shape.conf");

		if (defined $shape_path && $shape_path) {

			my @fregion;

			my $fh = IO::File->new;
			if ($fh->open("< $shape_path")) {
				while (my $line = <$fh>) {

					#skip on comments
					next if $line =~ /^#/;
					chomp($line);
					push @fregion, $line;
				}
				$fh->close;
			} else {
				print "Unable to open file $shape_path" if $self->{_sc}->get_debug;
				return $orig;
			}

			print "Window shape not detected - using $shape_path\n" if $self->{_sc}->get_debug;

			#remove current entry
			pop @r;

			my $width  = $orig->get_width;
			my $height = $orig->get_height;

			foreach my $line (@fregion) {
				$line =~ s/width/$width/;
				$line =~ s/height/$height/;
				$line =~ s/(\d+)-(\d+)/$1-$2/eg;
				my @temp = split(' ', $line);
				push @r, \@temp;
			}

			$manually_shaped = TRUE;

		} else {

			print "Unable to locate shape.conf\n" if $self->{_sc}->get_debug;

		}

		#do nothing if there are no
		#shape rectangles (or only one)
	} elsif (scalar @r <= 1) {
		return $orig;
	}

	#create a region from the bounding rectangles
	my $bregion = Cairo::Region->create;
	foreach my $r (@r) {
		my @rect = @{$r};

		next unless defined $rect[0];
		next unless defined $rect[1];
		next unless defined $rect[2];
		next unless defined $rect[3];

		unless ($manually_shaped) {

			#adjust rectangle if window is only partially visible
			if ($l_cropped) {
				$rect[2] -= $l_cropped - $rect[0];
				$rect[0] = 0;
			}
			if ($t_cropped) {
				$rect[3] -= $t_cropped - $rect[1];
				$rect[1] = 0;
			}
		}

		print "Current $rect[0],$rect[1],$rect[2],$rect[3]\n" if $self->{_sc}->get_debug;
		$bregion->union_rectangle({x=>$rect[0], y=>$rect[1], width=>$rect[2], height=>$rect[3]});
	}

	if (defined $orig) {

		#create target pixbuf with dimensions if selected/current window
		my $target = Gtk3::Gdk::Pixbuf->new($orig->get_colorspace, TRUE, 8, $orig->get_width, $orig->get_height);

		#whole pixbuf is transparent
		$target->fill(0x00000000);

		#copy all rectangles of bounding region to the target pixbuf
		my $len = $bregion->num_rectangles-1;
		for my $i (0..$len) {
			my $r = $bregion->get_rectangle($i);
			print $r->{x} . " " . $r->{y} . " " . $r->{width} . " " . $r->{height} . "\n" if $self->{_sc}->get_debug;

			next if ($r->{x} > $orig->get_width);
			next if ($r->{y} > $orig->get_height);

			$r->{width} = $orig->get_width - $r->{x}   if ($r->{x} + $r->{width} > $orig->get_width);
			$r->{height} = $orig->get_height - $r->{y} if ($r->{y} + $r->{height} > $orig->get_height);

			if ($r->{x} >= 0 && $r->{x} + $r->{width} <= $orig->get_width && $r->{y} >= 0 && $r->{y} + $r->{height} <= $orig->get_height) {
				$orig->copy_area($r->{x}, $r->{y}, $r->{width}, $r->{height}, $target, $r->{x}, $r->{y});
			} else {
				warn "WARNING: There was an error while calculating the window shape\n";
				return $orig;
			}
		}

		return $target;
	} else {
		return $bregion;
	}

}

sub get_window_size ($self, $wnck_window, $gdk_window, $border, $no_resize = undef) {

	#windowresize is active
	if ($self->{_mode} eq "window" || $self->{_mode} eq "tray_window" || $self->{_mode} eq "awindow" || $self->{_mode} eq "tray_awindow") {
		unless ($no_resize) {
			if (defined $self->{_windowresize} && $self->{_windowresize}) {

				#windows can usually not be resized when maximized
				if ($wnck_window->is_maximized) {
					$wnck_window->unmaximize;
				}

				$self->quit_eventh_only;

				Glib::Timeout->add(
					$self->{_hide_time},
					sub {
						Gtk3->main_quit;
						return FALSE;
					});
				Gtk3->main();

				my ($xc, $yc, $wc, $hc) = $self->get_window_size($wnck_window, $gdk_window, $border, TRUE);

				if (defined $self->{_windowresize_w} && $self->{_windowresize} > 0) {
					$wc = $self->{_windowresize_w};
				}

				if (defined $self->{_windowresize_h} && $self->{_windowresize_h} > 0) {
					$hc = $self->{_windowresize_h};
				}

				if ($border) {
					$wnck_window->set_geometry('current', [qw/width height/], $xc, $yc, $wc, $hc);
				} else {
					$gdk_window->resize($wc, $hc);
				}

				Glib::Timeout->add(
					$self->{_hide_time},
					sub {
						Gtk3->main_quit;
						return FALSE;
					});
				Gtk3->main();
			}
		}
	}

	#calculate size of the window
	my ($xp, $yp, $wp, $hp) = (0, 0, 0, 0);
	if ($border) {
		($xp, $yp, $wp, $hp) = $wnck_window->get_geometry;
	} else {
		($xp, $yp, $wp, $hp) = $gdk_window->get_geometry;
		($xp, $yp) = $gdk_window->get_origin;
	}

	return ($xp, $yp, $wp, $hp);
}
sub find_active_window ($self) {

	my $gdk_window = $self->{_gdk_screen}->get_active_window;

	if (defined $gdk_window) {
		my $wnck_window = Wnck::Window::get($gdk_window->get_xid);
		if (defined $wnck_window) {
			return ($wnck_window, $gdk_window);
		}
	}

	return FALSE;
}

sub find_region_for_window_type ($self, $xwindow, $type_hint = undef) {

	#XQueryTree - query window tree information
	my ($qroot, $qparent, @qkids) = $self->{_x11}->QueryTree($xwindow);

	foreach my $kid (reverse @qkids) {

		my $gdk_window = Gtk3::GdkX11::X11Window->foreign_new_for_display(Gtk3::Gdk::Display::get_default(), $kid);

		if (defined $gdk_window) {

			#check type_hint
			my $curr_type_hint = $gdk_window->get_type_hint;
			if (defined $type_hint) {
				next unless $curr_type_hint =~ /$type_hint/;
			}

			#XGetWindowAttributes, XGetGeometry, XWindowAttributes - get current
			#window attribute or geometry and current window attributes structure
			my @atts = $self->{_x11}->GetWindowAttributes($kid);
			return unless @atts;

			#window needs to be viewable
			return FALSE unless $atts[19] eq 'Viewable';

			#min size
			my ($xp, $yp, $wp, $hp, $depthp) = $gdk_window->get_geometry;
			($xp, $yp) = $gdk_window->get_origin;

			#~ print $xp, " - ", $yp, " - ", $wp, " - ", $hp, "\n";

			#create region
			my $sr = Cairo::Region->create({x=>$xp, y=>$yp, width=>$wp * $self->{_dpi_scale}, height=>$hp * $self->{_dpi_scale}});

			#init region
			unless (defined $self->{_c}{'cw'}{'window_region'}) {
				$self->{_c}{'cw'}{'window_region'} = Cairo::Region->create;
			}
			$self->{_c}{'cw'}{'window_region'}->union($sr);

			#store clipbox geometry
			#~ my $cbox = $self->{_c}{'cw'}{'window_region'}->get_clipbox;
			my $cbox = $self->get_clipbox($self->{_c}{'cw'}{'window_region'});

			$self->{_c}{'cw'}{'gdk_window'} = $gdk_window;
			$self->{_c}{'cw'}{'x'}          = $cbox->{x};
			$self->{_c}{'cw'}{'y'}          = $cbox->{y};
			$self->{_c}{'cw'}{'width'}      = $cbox->{width};
			$self->{_c}{'cw'}{'height'}     = $cbox->{height};
			$self->{_c}{'cw'}{'is_parent'}  = FALSE;

			#~ print $self->{_c}{'cw'}{'x'}, " - ",
			#~ $self->{_c}{'cw'}{'y'}, " - ",
			#~ $self->{_c}{'cw'}{'width'}, " - ",
			#~ $self->{_c}{'cw'}{'height'}, " \n ";
		}
	}

	return TRUE;
}

1;
