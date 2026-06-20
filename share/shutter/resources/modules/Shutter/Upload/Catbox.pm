package Shutter::Upload::Catbox;

use utf8;
use v5.40;
use Moo;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST);

has userhash => (is => 'rw', default => sub { '' });

sub upload {
    my ($self, $file) = @_;

    return (success => 0, error => "File not found") unless -e $file;

    my $ua = LWP::UserAgent->new(timeout => 30);
    $ua->agent("rshot/1.0");

    my @content = (
        reqtype      => 'fileupload',
        fileToUpload => [$file],
    );

    if (my $uh = $self->userhash) {
        push @content, (userhash => $uh);
    }

    my $response = $ua->request(POST 'https://catbox.moe/user/api.php',
        Content_Type => 'form-data',
        Content      => \@content
    );

    if ($response->is_success) {
        my $url = $response->decoded_content;
        return (success => 1, url => $url);
    } else {
        return (success => 0, error => $response->status_line);
    }
}

1;
