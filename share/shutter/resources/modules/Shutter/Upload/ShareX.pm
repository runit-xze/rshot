package ShareX;

use utf8;
use v5.40;
use feature 'try'; no warnings 'experimental::try';
use MIME::Base64;
use JSON::MaybeXS;
use LWP::UserAgent;
use HTTP::Request::Common;
use Glib qw/TRUE FALSE/;

use Shutter::Upload::Shared;
our @ISA = qw(Shutter::Upload::Shared);

sub new ($class, $sxcu_path, $debug_cparam, $shutter_root, $gettext_object, $main_gtk_window, $ua) {
	my $self = $class->SUPER::new($sxcu_path, $debug_cparam, $shutter_root, $gettext_object, $main_gtk_window, $ua);

	# We use the _host property (from SUPER) to store the sxcu path
	$self->{_sxcu_path} = $sxcu_path;
	
	bless $self, $class;
	return $self;
}

sub init ($self, $username) {
	my $json = JSON::MaybeXS->new;
	eval {
		open(my $fh, '<', $self->{_sxcu_path}) or die "Cannot open $self->{_sxcu_path}";
		my $json_text = do { local $/; <$fh> };
		close($fh);
		$self->{_sxcu} = $json->decode($json_text);
	};
	if ($@) {
		print "Error parsing .sxcu file: $@\n" if $self->{_debug_cparam};
		return FALSE;
	}

	# Find any $PROMPT:xxx$ arguments and ask the user for them
	my %prompts;
	if (exists $self->{_sxcu}->{Arguments}) {
		foreach my $key (keys %{$self->{_sxcu}->{Arguments}}) {
			if ($self->{_sxcu}->{Arguments}->{$key} =~ /^\$PROMPT:(.+?)\$$/) {
				$prompts{$key} = $1;
			}
		}
	}
	
	if (keys %prompts > 0) {
		my $config_file = $ENV{'HOME'} . '/.shutter/sxcu_' . ($self->{_sxcu}->{Name} || 'custom') . '.conf';
		my $saved_config = {};
		if (-f $config_file) {
			eval {
				open(my $fh, '<', $config_file);
				my $txt = do { local $/; <$fh> };
				close($fh);
				$saved_config = $json->decode($txt);
			};
		}
	
		my $dialog = Gtk3::Dialog->new("Configuration - " . ($self->{_sxcu}->{Name} || "Custom Uploader"),
			$self->{_main_gtk_window}, [qw/modal destroy-with-parent/],
			'gtk-cancel' => 'cancel',
			'gtk-apply'  => 'apply'
		);
		my $vbox = $dialog->get_content_area;
		
		my %entries;
		foreach my $k (keys %prompts) {
			my $label = Gtk3::Label->new($prompts{$k});
			my $entry = Gtk3::Entry->new;
			$entry->set_text($saved_config->{$k}) if exists $saved_config->{$k};
			my $hbox = Gtk3::HBox->new(FALSE, 5);
			$hbox->pack_start($label, FALSE, FALSE, 0);
			$hbox->pack_start($entry, TRUE, TRUE, 0);
			$vbox->pack_start($hbox, FALSE, FALSE, 5);
			$entries{$k} = $entry;
		}
		
		$dialog->show_all;
		my $response = $dialog->run;
		if ($response eq 'apply') {
			foreach my $k (keys %prompts) {
				my $val = $entries{$k}->get_text;
				$self->{_sxcu}->{Arguments}->{$k} = $val;
				$saved_config->{$k} = $val;
			}
			# Save preferences
			eval {
				open(my $fh, '>', $config_file);
				print $fh $json->encode($saved_config);
				close($fh);
			};
			$dialog->destroy;
			return TRUE;
		} else {
			$dialog->destroy;
			return FALSE;
		}
	}

	return TRUE;
}

sub upload ($self, $upload_filename, $username, $password) {
	$self->{_filename} = $upload_filename;
	$self->{_username} = $username;
	$self->{_password} = $password;

	my $client = LWP::UserAgent->new(
		'timeout'    => 20,
		'keep_alive' => 10,
		'env_proxy'  => 1,
	);

	eval {
		my %form_data;
		
		# Build arguments
		if (exists $self->{_sxcu}->{Arguments}) {
			foreach my $k (keys %{$self->{_sxcu}->{Arguments}}) {
				$form_data{$k} = $self->{_sxcu}->{Arguments}->{$k};
			}
		}

		# Add file
		my $file_form_name = $self->{_sxcu}->{FileFormName} || 'file';
		$form_data{$file_form_name} = [$upload_filename];
		
		my @params = ($self->{_sxcu}->{RequestURL}, 'Content_Type' => 'form-data', 'Content' => [%form_data]);
		my $req = HTTP::Request::Common::POST(@params);
		
		# Headers
		if (exists $self->{_sxcu}->{Headers}) {
			foreach my $k (keys %{$self->{_sxcu}->{Headers}}) {
				$req->header($k => $self->{_sxcu}->{Headers}->{$k});
			}
		}
		
		my $rsp = $client->request($req);

		if ($rsp->is_success) {
			my $content = $rsp->decoded_content || $rsp->content;
			
			# Very basic extraction: ShareX supports regex or json paths.
			# If it's catbox/litterbox, the response IS the URL.
			# If it's JSON, ShareX usually parses it using $URL$ regex.
			# For now, if the response looks like a URL, use it directly.
			# If a Regex is specified in .sxcu (URL property), use that.
			my $final_url = $content;
			
			if (exists $self->{_sxcu}->{URL}) {
				my $regex = $self->{_sxcu}->{URL};
				# Basic ShareX extraction syntax replacement.
				# Example: $json:url$ -> we'd need a JSON parser.
				# For this sprint, we'll implement simple regex support if the URL isn't just text.
				if ($regex =~ /^\$json:(.+)\$$/) {
					my $jpath = $1;
					my $json_obj = JSON::MaybeXS->new->decode($content);
					my @parts = split(/\./, $jpath);
					my $curr = $json_obj;
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
			
			$self->{_links}{'status'} = 200;
			$self->{_links}{'direct_link'} = $final_url;
			$self->{_links}{'post_link'} = $final_url;
		} else {
			$self->{_links}{'status'} = "Upload failed: " . $rsp->status_line . "\n" . $rsp->content;
		}
	};
	if ($@) {
		$self->{_links}{'status'} = $@;
	}

	return %{$self->{_links}};
}

1;
