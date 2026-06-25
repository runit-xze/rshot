#!/usr/bin/env perl
use strict;
use warnings;
use Gtk3 -init;

eval {
    my $model = Gtk3::ListStore->new('Gtk3::Gdk::Pixbuf', 'Glib::String', 'Glib::String');
    print "Model: $model\n";
    my $view = Gtk3::IconView->new_with_model($model);
    print "View: $view\n";
};
if ($@) {
    print "Error: $@\n";
}
