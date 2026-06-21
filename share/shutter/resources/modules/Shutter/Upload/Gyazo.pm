package Shutter::Upload::Gyazo;

use utf8;
use v5.40;
use Moo;
with 'Shutter::Upload::Role::Uploader';

sub upload {
    my ($self, $file) = @_;

    return (success => 0, error => "File not found") unless -e $file;

    require WebService::Gyazo::B;
    my $client = WebService::Gyazo::B->new();

    my %upload_result;
    eval {
        my $image = $client->uploadFile($file);
        if (!$client->isError) {
            my $url = $image->getImageUrl();
            %upload_result = (success => 1, url => $url);
        } else {
            %upload_result = (success => 0, error => $client->error());
        }
    };
    if ($@) {
        %upload_result = (success => 0, error => $@);
    }

    return %upload_result;
}

1;
