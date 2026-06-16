use 5.010;
use strict;
use warnings;

use Gtk3;
use Test::More tests => 7;
use Glib qw/ TRUE FALSE /;
use File::Temp qw/ tempdir /;

require Test::Window;
require_ok("Shutter::App::Common");
require_ok("Shutter::App::HelperFunctions");

subtest "Create helper functions object" => sub {
    plan skip_all => "no env TEST_APP_SHUTTER_PATH found" unless $ENV{TEST_APP_SHUTTER_PATH};

    my $w = Test::Window::simple_window();
    my $sc = Shutter::App::Common->new(
        shutter_root => $ENV{TEST_APP_SHUTTER_PATH},
        main_window  => $w,
        appname      => "shutter",
        version      => 0.99,
        rev          => 1234,
        pid          => $$
    );

    my $shf = Shutter::App::HelperFunctions->new($sc);
    ok( defined $shf, "Object defined" );
    isa_ok( $shf, "Shutter::App::HelperFunctions" );
};

subtest "format_bytes" => sub {
    my $shf = bless {}, "Shutter::App::HelperFunctions";
    is( $shf->format_bytes(0), "0 B", "0 B" );
    is( $shf->format_bytes(1000), "1 kB", "1000 B -> 1 kB" );
    is( $shf->format_bytes(1024), "1.0 kB", "1024 B -> 1.0 kB" );
    is( $shf->format_bytes(1000000), "1 MB", "1.0 MB" );
};

subtest "switch_home_in_file" => sub {
    my $shf = bless {}, "Shutter::App::HelperFunctions";
    local $ENV{HOME} = "/home/user";
    is( $shf->switch_home_in_file("~/foo"), "/home/user/foo", "home switched" );
    is( $shf->switch_home_in_file("/etc/foo"), "/etc/foo", "nothing switched" );
};

subtest "ncmp" => sub {
    my $shf = bless {}, "Shutter::App::HelperFunctions";
    is( $shf->ncmp("a1", "a2"), -1, "a1 < a2" );
    is( $shf->ncmp("a10", "a2"), 1, "a10 > a2 (numerical)" );
    is( $shf->ncmp("a", "A"), 1, "a > A (case sensitive)" );
};

subtest "nsort" => sub {
    my $shf = bless {}, "Shutter::App::HelperFunctions";
    my @list = qw(img10.png img2.png img1.png);
    my @sorted = $shf->nsort(@list);
    is_deeply( \@sorted, [qw(img1.png img2.png img10.png)], "nsort works" );
};

done_testing();
