package Shutter::Upload::ShareX;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';
use Moo;
with 'Shutter::Upload::Role::Uploader';

use MIME::Base64;
use JSON::MaybeXS;
use Glib     qw/TRUE FALSE/;
use IPC::Cmd qw(can_run);
use URI::Escape;
use File::Temp;
use Gtk3;

has sxcu_path       => (is => 'ro', required => 1);
has debug           => (is => 'ro', default  => sub { 0 });
has main_gtk_window => (is => 'ro');
has _sxcu           => (is => 'rw');

sub BUILD ($self, $args) {
	my $json = JSON::MaybeXS->new;
	eval {
		require Shutter::App::Core::FileSystemAPI;
		my $json_text = Shutter::App::Core::FileSystemAPI->new->slurp_utf8($self->sxcu_path);
		$self->_sxcu($json->decode($json_text));
	};
	if ($@) {
		print "Error parsing .sxcu file: $@\n" if $self->debug;
	}
	return;
}

sub upload ($self, $upload_filename) {
	return (success => 0, error => "File not found")      unless Shutter::App::Core::FileSystemAPI->new->path_exists($upload_filename);
	return (success => 0, error => "Failed to load sxcu") unless $self->_sxcu;

	require Shutter::App::Core::NetworkAPI;
	my $api = Shutter::App::Core::NetworkAPI->new(timeout => 20, env_proxy => 1);

	my %upload_result;

	eval {
		my %form_data;

		# Build arguments
		if (exists $self->_sxcu->{Arguments}) {
			foreach my $k (keys %{$self->_sxcu->{Arguments}}) {
				$form_data{$k} = $self->_sxcu->{Arguments}->{$k};
			}
		}

		# Add file
		my $file_form_name = $self->_sxcu->{FileFormName} || 'file';
		$form_data{$file_form_name} = [$upload_filename];

		# Headers
		my %headers;
		if (exists $self->_sxcu->{Headers}) {
			foreach my $k (keys %{$self->_sxcu->{Headers}}) {
				$headers{$k} = $self->_sxcu->{Headers}->{$k};
			}
		}

		my $rsp = $api->post_form($self->_sxcu->{RequestURL}, [%form_data], \%headers);

		if ($rsp->is_success) {
			my $content = $rsp->decoded_content || $rsp->content;

			my $final_url = $content;

			if (exists $self->_sxcu->{URL}) {
				my $regex = $self->_sxcu->{URL};
				if ($regex =~ /^\$json:(.+)\$$/) {
					my $jpath    = $1;
					my $json_obj = JSON::MaybeXS->new->decode($content);
					my @parts    = split(/\./, $jpath);
					my $curr     = $json_obj;
					foreach my $p (@parts) {
						if (ref($curr) eq 'HASH' && exists $curr->{$p}) {
							$curr = $curr->{$p};
						} else {
							$curr = undef;
							last;
						}
					}
					if (defined $curr && !ref($curr)) {
						$final_url = $curr;
					}
				} elsif ($content =~ /$regex/) {
					$final_url = $1 || $content;
				}
			}

			# Clean up url
			$final_url =~ s/^\s+|\s+$//g;

			# --- After Upload Actions ---
			my $after = $self->_sxcu->{AfterUpload} // {};

			# URL Shortening via TinyURL
			if ($after->{shorten_url} && $final_url =~ m{^https?://}) {
				try {
					my $shorten_api = Shutter::App::Core::NetworkAPI->new(timeout => 10, env_proxy => 1);
					my $shorten_rsp = $shorten_api->get('https://tinyurl.com/api-create.php?url=' . URI::Escape::uri_escape($final_url));
					if ($shorten_rsp->is_success) {
						my $short = $shorten_rsp->decoded_content;
						$short =~ s/\s+//g;
						$final_url = $short if $short =~ m{^https?://};
					}
				} catch ($e) {
					print "URL shortening failed: $e\n" if $self->debug;
				}
			}

			# QR Code display via qrencode (if available and requested)
			if ($after->{show_qr} && can_run('qrencode')) {
				my $tmpfile = File::Temp::tempnam('/tmp', 'shutter_qr_') . '.png';
				require Shutter::App::Core::SecureSystemCommandAPI;
				Shutter::App::Core::SecureSystemCommandAPI->new->capture('qrencode', '-o', $tmpfile, '-s', '5', $final_url);
				if (Shutter::App::Core::FileSystemAPI->new->is_regular_file($tmpfile)) {
					$self->_show_qr_dialog($tmpfile, $final_url);
					Shutter::App::Core::FileSystemAPI->new->remove($tmpfile);
				}
			}

			%upload_result = (success => 1, url => $final_url);
		} else {
			%upload_result = (success => 0, error => "Upload failed: " . $rsp->status_line . "\n" . $rsp->content);
		}
	};
	if ($@) {
		%upload_result = (success => 0, error => $@);
	}

	return %upload_result;
}

sub _show_qr_dialog ($self, $qr_path, $url) {
	return unless Shutter::App::Core::FileSystemAPI->new->is_regular_file($qr_path);
	return unless $self->main_gtk_window;

	my $dialog = Gtk3::Dialog->new('Upload Complete - QR Code', $self->main_gtk_window, [qw/destroy-with-parent/], 'gtk-ok' => 'accept');
	$dialog->set_default_size(320, 400);

	my $vbox = $dialog->get_content_area;

	my $url_label = Gtk3::Label->new('');
	$url_label->set_markup("<b>Upload URL:</b>");
	$url_label->set_alignment(0, 0.5);
	$vbox->pack_start($url_label, FALSE, FALSE, 4);

	my $url_entry = Gtk3::Entry->new;
	$url_entry->set_text($url);
	$url_entry->set_editable(FALSE);
	$vbox->pack_start($url_entry, FALSE, FALSE, 2);

	my $qr_label = Gtk3::Label->new('Scan to open on another device:');
	$qr_label->set_alignment(0, 0.5);
	$vbox->pack_start($qr_label, FALSE, FALSE, 4);

	try {
		my $pixbuf = Gtk3::Gdk::Pixbuf->new_from_file($qr_path);
		my $img    = Gtk3::Image->new_from_pixbuf($pixbuf);
		$vbox->pack_start($img, TRUE, TRUE, 0);
	} catch ($e) {
		$vbox->pack_start(Gtk3::Label->new('(Could not load QR image)'), FALSE, FALSE, 0);
	}

	$dialog->show_all;
	$dialog->run;
	$dialog->destroy;
	return;
}

1;
