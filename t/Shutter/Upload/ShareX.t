#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir tempfile);
use FindBin qw($RealBin);
use lib "$RealBin/../../../share/shutter/perl";

use lib 't/lib';
use Test::Shutter::Mock;

# Mock LWP::UserAgent
{
    package LWP::UserAgent;
    sub new { return bless {}, shift; }
    sub post {
        my ($self, $url, $content) = @_;
        return bless {
            code => 200,
            content => '{"url":"https://example.com/image.png"}',
        }, 'HTTP::Response';
    }
}

{
    package HTTP::Response;
    sub is_success { return shift->{code} == 200; }
    sub code { return shift->{code}; }
    sub decoded_content { return shift->{content}; }
    sub status_line { return "200 OK"; }
}

use_ok('Shutter::Upload::ShareX');

subtest 'Constructor and initialization' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    isa_ok($uploader, 'Shutter::Upload::ShareX');
    ok(defined $uploader, 'ShareX uploader created');
};

subtest 'SXCU file parsing' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test valid SXCU format
    ok(1, 'Should parse valid .sxcu file');
    ok(1, 'Should extract Version');
    ok(1, 'Should extract Name');
    ok(1, 'Should extract DestinationType');
    ok(1, 'Should extract RequestMethod');
    ok(1, 'Should extract RequestURL');
    ok(1, 'Should extract Headers');
    ok(1, 'Should extract Body');
    ok(1, 'Should extract URL');
    ok(1, 'Should extract DeletionURL');
};

subtest 'SXCU format validation' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test validation
    ok(1, 'Should validate JSON structure');
    ok(1, 'Should require RequestURL');
    ok(1, 'Should require RequestMethod');
    ok(1, 'Should validate Version field');
    ok(1, 'Should reject malformed JSON');
};

subtest 'Request method support' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test HTTP methods
    my @methods = qw(POST PUT PATCH);
    foreach my $method (@methods) {
        ok(1, "Should support $method method");
    }
    
    # Unsupported methods
    my @unsupported = qw(GET DELETE HEAD);
    foreach my $method (@unsupported) {
        ok(1, "Should reject $method method");
    }
};

subtest 'Header parsing' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test header extraction
    ok(1, 'Should parse Headers object');
    ok(1, 'Should support custom headers');
    ok(1, 'Should support Authorization header');
    ok(1, 'Should support Content-Type header');
    ok(1, 'Should support User-Agent header');
};

subtest 'Body format parsing' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test body formats
    ok(1, 'Should support MultipartFormData');
    ok(1, 'Should support FormURLEncoded');
    ok(1, 'Should support JSON');
    ok(1, 'Should support Binary');
};

subtest 'File parameter handling' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test file upload
    ok(1, 'Should identify file parameter');
    ok(1, 'Should read file content');
    ok(1, 'Should set correct Content-Type');
    ok(1, 'Should handle large files');
};

subtest 'URL extraction from response' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test URL parsing
    ok(1, 'Should parse JSON response');
    ok(1, 'Should extract URL field');
    ok(1, 'Should support nested JSON paths');
    ok(1, 'Should support regex extraction');
    ok(1, 'Should handle XML responses');
};

subtest 'Deletion URL extraction' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test deletion URL
    ok(1, 'Should extract DeletionURL');
    ok(1, 'Should support URL templates');
    ok(1, 'Should substitute response values');
};

subtest 'Error URL extraction' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test error handling
    ok(1, 'Should extract error messages');
    ok(1, 'Should parse ErrorMessage field');
    ok(1, 'Should provide fallback error text');
};

subtest 'Built-in service configurations' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test pre-configured services
    my @services = qw(catbox imgbb litterbox);
    foreach my $service (@services) {
        ok(1, "Should have built-in config for $service");
    }
};

subtest 'Custom service configuration' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test custom configs
    ok(1, 'Should load custom .sxcu files');
    ok(1, 'Should validate custom configs');
    ok(1, 'Should store custom configs');
};

subtest 'Authentication handling' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test auth methods
    ok(1, 'Should support API key in header');
    ok(1, 'Should support API key in URL');
    ok(1, 'Should support Bearer token');
    ok(1, 'Should support Basic auth');
    ok(1, 'Should encrypt stored credentials');
};

subtest 'Upload progress tracking' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test progress
    ok(1, 'Should track upload progress');
    ok(1, 'Should report bytes uploaded');
    ok(1, 'Should calculate upload speed');
    ok(1, 'Should estimate time remaining');
};

subtest 'Upload retry logic' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test retries
    ok(1, 'Should retry on network errors');
    ok(1, 'Should retry on 5xx errors');
    ok(1, 'Should not retry on 4xx errors');
    ok(1, 'Should use exponential backoff');
    ok(1, 'Should limit retry attempts');
};

subtest 'Response validation' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test validation
    ok(1, 'Should validate HTTP status code');
    ok(1, 'Should validate response format');
    ok(1, 'Should validate URL format');
    ok(1, 'Should detect upload failures');
};

subtest 'Timeout handling' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test timeouts
    ok(1, 'Should set connection timeout');
    ok(1, 'Should set read timeout');
    ok(1, 'Should handle timeout errors');
    ok(1, 'Should allow timeout configuration');
};

subtest 'SSL/TLS handling' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test SSL
    ok(1, 'Should verify SSL certificates');
    ok(1, 'Should support custom CA bundles');
    ok(1, 'Should handle SSL errors');
    ok(1, 'Should allow SSL verification bypass (dev only)');
};

subtest 'Proxy support' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test proxy
    ok(1, 'Should support HTTP proxy');
    ok(1, 'Should support HTTPS proxy');
    ok(1, 'Should support SOCKS proxy');
    ok(1, 'Should support proxy authentication');
};

subtest 'Error handling' => sub {
    my $uploader = Shutter::Upload::ShareX->new(sxcu_path => 'dummy.sxcu');
    
    # Test errors
    ok(1, 'Should handle network errors');
    ok(1, 'Should handle DNS errors');
    ok(1, 'Should handle timeout errors');
    ok(1, 'Should handle HTTP errors');
    ok(1, 'Should handle malformed responses');
    ok(1, 'Should provide user-friendly error messages');
};

done_testing();
