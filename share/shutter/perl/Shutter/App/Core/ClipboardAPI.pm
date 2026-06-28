package Shutter::App::Core::ClipboardAPI;

use utf8;
use v5.40;
use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has _gtk_clipboard => (
    is      => 'lazy',
    default => sub {
        my ($self) = @_;
        return Gtk3::Clipboard::get(Gtk3::Gdk::Atom::intern("CLIPBOARD", FALSE));
    },
);

sub set_text {
    my ($self, $text) = @_;
    return unless defined $text;
    $self->_gtk_clipboard->set_text($text);
    return;
}

sub set_image {
    my ($self, $pixbuf) = @_;
    return unless defined $pixbuf;
    $self->_gtk_clipboard->set_image($pixbuf);
    return;
}

sub wait_for_image {
    my ($self) = @_;
    return $self->_gtk_clipboard->wait_for_image;
}

sub wait_for_text {
    my ($self) = @_;
    return $self->_gtk_clipboard->wait_for_text;
}

1;
