#!/usr/bin/env perl
use strict;
use warnings;
use v5.40;
use Gtk3 -init;

use lib 'share/shutter/resources/modules';
use Shutter::App::CLI;
use Shutter::Draw::DrawingTool;

package MockSC;
sub new { bless {}, shift }
sub get_root { "/home/ashley/shutter" }
sub get_profile_to_start_with { "default" }
sub get_rusf { "/tmp" }
sub get_mainwindow { $main::main_window }
sub get_main_window { $main::main_window }
sub get_debug { 1 }
sub get_gettext { bless {}, 'MockLocale' }
package MockLocale;
sub get { return $_[1]; }

package main;
our $main_window = Gtk3::Window->new('toplevel');
$main_window->signal_connect(destroy => sub { Gtk3->main_quit });

my $sc = MockSC->new();
my $dt = Shutter::Draw::DrawingTool->new($sc);

eval {
    $dt->show("/home/ashley/Pictures/Selection_090.png", $main_window);
};
if ($@) {
    print "Error opening DrawingTool: $@\n";
} else {
    print "DrawingTool show() finished without exception.\n";
}

Glib::Timeout->add(500, sub { Gtk3->main_quit; 0; });
Gtk3->main;
