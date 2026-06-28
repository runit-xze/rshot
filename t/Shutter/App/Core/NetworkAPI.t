#!/usr/bin/env perl

use strict;
use warnings;
use utf8;
use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin/../../../../share/shutter/resources/modules";

require_ok('Shutter::App::Core::NetworkAPI');

subtest 'Object initialization' => sub {
    my $api = Shutter::App::Core::NetworkAPI->new;
    isa_ok($api, 'Shutter::App::Core::NetworkAPI');
    is($api->timeout, 30, 'Default timeout is 30');
    is($api->env_proxy, 1, 'Default env_proxy is 1');
    is($api->user_agent, 'rshot/1.0', 'Default user_agent is rshot/1.0');
    isa_ok($api->_ua, 'LWP::UserAgent');
};

done_testing();
