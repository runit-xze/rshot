package Shutter::Upload::Catbox;

use utf8;
use v5.40;
use Moo;
with 'Shutter::Upload::Role::Uploader';
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);

has userhash => (is => 'rw', default => sub { '' });

sub upload ($self, $file) {
	return (success => 0, error => "File not found") unless -e $file;

	require Shutter::App::Core::NetworkAPI;
	my $api = Shutter::App::Core::NetworkAPI->new(timeout => 30);

	my @content = (
		reqtype      => 'fileupload',
		fileToUpload => [$file],
	);

	if (my $uh = $self->userhash) {
		push @content, (userhash => $uh);
	}

	my $response = $api->post_form('https://catbox.moe/user/api.php', \@content);

	if ($response->is_success) {
		my $url = $response->decoded_content;
		return (success => 1, url => $url);
	} else {
		return (success => 0, error => $response->status_line);
	}
}

1;
