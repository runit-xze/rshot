package Shutter::App::UI::Settings::Upload;

use utf8;
use v5.40;
use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

has _vbox => (is => 'rw');
has _catbox_userhash => (is => 'rw');

sub BUILD ($self, $args) {
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;
    my $sm = $self->cli->{settings_manager};

    my $vbox_main = Gtk3::VBox->new(FALSE, 12);
    $vbox_main->set_border_width(5);

    # --- Catbox Frame ---
    my $catbox_frame = Gtk3::Frame->new;
    my $catbox_frame_label = Gtk3::Label->new;
    $catbox_frame_label->set_markup("<b>" . $d->get("Catbox.moe Configuration") . "</b>");
    $catbox_frame->set_label_widget($catbox_frame_label);
    $catbox_frame->set_shadow_type('none');
    
    my $catbox_vbox = Gtk3::VBox->new(FALSE, 0);
    
    # Grid for Catbox details
    my $grid = Gtk3::Grid->new;
    $grid->set_row_spacing(6);
    $grid->set_column_spacing(12);
    
    # Userhash
    my $hash_label = Gtk3::Label->new($d->get("Userhash (optional)") . ":");
    $hash_label->set_halign('start');
    my $catbox_userhash = Gtk3::Entry->new;
    $catbox_userhash->set_text($sm->get_setting('general', 'catbox_userhash') // '');
    $catbox_userhash->set_hexpand(TRUE);
    
    $grid->attach($hash_label, 0, 0, 1, 1);
    $grid->attach($catbox_userhash, 1, 0, 1, 1);
    
    $catbox_vbox->pack_start($grid, TRUE, TRUE, 3);
    
    $catbox_frame->add($catbox_vbox);
    $vbox_main->pack_start($catbox_frame, FALSE, TRUE, 3);

    $self->_vbox($vbox_main);
    $self->_catbox_userhash($catbox_userhash);
    return;
}

sub get_widget ($self) {
    return $self->_vbox;
}

sub save ($self) {
    my $sm = $self->cli->{settings_manager};
    $sm->set_setting('general', 'catbox_userhash', $self->_catbox_userhash->get_text);
    return;
}

1;
