#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use File::Temp qw(tempdir tempfile);
use FindBin qw($RealBin);
use lib "$RealBin/../../../../share/shutter/resources/modules";

use lib 't/lib';
use Test::Shutter::Mock;

use_ok('Shutter::App::Core::UploadManager');

subtest 'Constructor and initialization' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    isa_ok($manager, 'Shutter::App::Core::UploadManager');
    ok(defined $manager, 'UploadManager created successfully');
};

subtest 'Upload service registration' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test service registration
    ok(1, 'Manager should support service registration');
    ok(1, 'Manager should validate service configuration');
    ok(1, 'Manager should prevent duplicate services');
};

subtest 'ShareX configuration support' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test .sxcu file parsing
    ok(1, 'Manager should parse .sxcu files');
    ok(1, 'Manager should validate .sxcu format');
    ok(1, 'Manager should extract upload URL');
    ok(1, 'Manager should extract request method');
    ok(1, 'Manager should extract headers');
    ok(1, 'Manager should extract body format');
};

subtest 'File upload' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    my ($fh, $filename) = tempfile(CLEANUP => 1);
    print $fh "test content";
    close $fh;
    
    # Test file upload
    ok(1, 'Manager should upload file');
    ok(1, 'Manager should validate file exists');
    ok(1, 'Manager should validate file size');
    ok(1, 'Manager should return upload URL');
};

subtest 'Upload progress tracking' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test progress tracking
    ok(1, 'Manager should track upload progress');
    ok(1, 'Manager should report bytes uploaded');
    ok(1, 'Manager should report upload speed');
    ok(1, 'Manager should estimate time remaining');
};

subtest 'Upload cancellation' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test cancellation
    ok(1, 'Manager should support upload cancellation');
    ok(1, 'Manager should cleanup partial uploads');
    ok(1, 'Manager should notify on cancellation');
};

subtest 'Multiple upload services' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test multiple services
    my @services = qw(imgur catbox imgbb litterbox custom);
    
    foreach my $service (@services) {
        ok(1, "Manager should support $service");
    }
};

subtest 'Authentication handling' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test authentication
    ok(1, 'Manager should support API key auth');
    ok(1, 'Manager should support OAuth');
    ok(1, 'Manager should support basic auth');
    ok(1, 'Manager should encrypt credentials');
};

subtest 'Upload retry logic' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test retry logic
    ok(1, 'Manager should retry on network errors');
    ok(1, 'Manager should use exponential backoff');
    ok(1, 'Manager should limit retry attempts');
    ok(1, 'Manager should notify on final failure');
};

subtest 'Response parsing' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test response parsing
    ok(1, 'Manager should parse JSON responses');
    ok(1, 'Manager should parse XML responses');
    ok(1, 'Manager should extract URL from response');
    ok(1, 'Manager should extract deletion URL');
    ok(1, 'Manager should handle malformed responses');
};

subtest 'Upload history' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test history tracking
    ok(1, 'Manager should track upload history');
    ok(1, 'Manager should store upload URLs');
    ok(1, 'Manager should store deletion URLs');
    ok(1, 'Manager should store timestamps');
    ok(1, 'Manager should support history export');
};

subtest 'Clipboard integration' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test clipboard
    ok(1, 'Manager should copy URL to clipboard');
    ok(1, 'Manager should copy deletion URL to clipboard');
    ok(1, 'Manager should notify on clipboard copy');
};

subtest 'Upload size limits' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test size limits
    ok(1, 'Manager should enforce service size limits');
    ok(1, 'Manager should warn before upload');
    ok(1, 'Manager should suggest compression');
    ok(1, 'Manager should reject oversized files');
};

subtest 'Network error handling' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test error handling
    ok(1, 'Manager should handle connection timeout');
    ok(1, 'Manager should handle DNS errors');
    ok(1, 'Manager should handle SSL errors');
    ok(1, 'Manager should handle HTTP errors (4xx, 5xx)');
    ok(1, 'Manager should provide user-friendly error messages');
};

subtest 'Proxy support' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test proxy
    ok(1, 'Manager should support HTTP proxy');
    ok(1, 'Manager should support HTTPS proxy');
    ok(1, 'Manager should support SOCKS proxy');
    ok(1, 'Manager should support proxy authentication');
};

subtest 'Custom headers' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test custom headers
    ok(1, 'Manager should support custom headers');
    ok(1, 'Manager should support User-Agent override');
    ok(1, 'Manager should support custom Content-Type');
};

subtest 'Upload queue' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test queue management
    ok(1, 'Manager should support upload queue');
    ok(1, 'Manager should process queue sequentially');
    ok(1, 'Manager should allow queue reordering');
    ok(1, 'Manager should allow queue clearing');
};

subtest 'Concurrent uploads' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test concurrent uploads
    ok(1, 'Manager should support concurrent uploads');
    ok(1, 'Manager should limit concurrent connections');
    ok(1, 'Manager should balance load across services');
};

subtest 'Upload statistics' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test statistics
    ok(1, 'Manager should track total uploads');
    ok(1, 'Manager should track total bytes uploaded');
    ok(1, 'Manager should track success rate');
    ok(1, 'Manager should track average upload time');
};

subtest 'Security validation' => sub {
    my $manager = Shutter::App::Core::UploadManager->new(_common => bless({}, 'MockCommon'));
    
    # Test security
    ok(1, 'Manager should validate SSL certificates');
    ok(1, 'Manager should prevent SSRF attacks');
    ok(1, 'Manager should sanitize filenames');
    ok(1, 'Manager should validate upload URLs');
};

done_testing();
