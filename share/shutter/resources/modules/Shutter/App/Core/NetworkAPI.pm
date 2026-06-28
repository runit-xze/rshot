package Shutter::App::Core::NetworkAPI;

use strict;
use warnings;
use utf8;
use Moo;
use LWP::UserAgent;
use HTTP::Request::Common qw(POST GET);

has user_agent => (
    is => 'rw',
    default => 'rshot/1.0',
);

has timeout => (
    is => 'rw',
    default => 30,
);

has env_proxy => (
    is => 'rw',
    default => 1,
);

has _ua => (
    is      => 'lazy',
    default => sub {
        my ($self) = @_;
        my $ua = LWP::UserAgent->new(
            timeout   => $self->timeout,
            env_proxy => $self->env_proxy,
        );
        $ua->agent($self->user_agent);
        return $ua;
    },
);

sub get {
    my ($self, $url, %headers) = @_;
    my $req = GET $url;
    for my $k (keys %headers) {
        $req->header($k => $headers{$k});
    }
    return $self->_ua->request($req);
}

sub post_form {
    my ($self, $url, $form_data, $headers) = @_;
    $headers //= {};
    
    my @params = ($url, 'Content_Type' => 'form-data', 'Content' => $form_data);
    my $req = POST(@params);
    
    for my $k (keys %$headers) {
        $req->header($k => $headers->{$k});
    }
    
    return $self->_ua->request($req);
}

1;
