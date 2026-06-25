package Shutter::App::UI::Settings::Behavior;

use utf8;
use v5.40;
use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

has _vbox => (is => 'rw');
has _close_at_close => (is => 'rw');
has _autohide => (is => 'rw');
has _notify_agent => (is => 'rw');
has _thumbnail => (is => 'rw');

sub BUILD ($self, $args) {
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;
    my $sm = $self->cli->{settings_manager};

    my $vbox_main = Gtk3::VBox->new(FALSE, 12);
    $vbox_main->set_border_width(5);

    # --- Window Frame ---
    my $win_frame = Gtk3::Frame->new;
    my $win_frame_label = Gtk3::Label->new;
    $win_frame_label->set_markup("<b>" . $d->get("Window") . "</b>");
    $win_frame->set_label_widget($win_frame_label);
    $win_frame->set_shadow_type('none');
    
    my $win_vbox = Gtk3::VBox->new(FALSE, 0);
    
    my $close_at_close = Gtk3::CheckButton->new_with_label($d->get("Hide window on close"));
    $close_at_close->set_active($sm->get_setting('general', 'close_at_close') // TRUE);
    $win_vbox->pack_start($close_at_close, FALSE, TRUE, 3);
    
    my $autohide = Gtk3::CheckButton->new_with_label($d->get("Hide main window when taking a screenshot"));
    $autohide->set_active($sm->get_setting('general', 'autohide') // TRUE);
    $win_vbox->pack_start($autohide, FALSE, TRUE, 3);
    
    $win_frame->add($win_vbox);
    $vbox_main->pack_start($win_frame, FALSE, TRUE, 3);

    # --- Notifications Frame ---
    my $notif_frame = Gtk3::Frame->new;
    my $notif_frame_label = Gtk3::Label->new;
    $notif_frame_label->set_markup("<b>" . $d->get("Notifications") . "</b>");
    $notif_frame->set_label_widget($notif_frame_label);
    $notif_frame->set_shadow_type('none');
    
    my $notif_vbox = Gtk3::VBox->new(FALSE, 0);
    
    my $notify_agent = Gtk3::CheckButton->new_with_label($d->get("Enable desktop notifications"));
    $notify_agent->set_active($sm->get_setting('general', 'notify_agent') // TRUE);
    $notif_vbox->pack_start($notify_agent, FALSE, TRUE, 3);
    
    $notif_frame->add($notif_vbox);
    $vbox_main->pack_start($notif_frame, FALSE, TRUE, 3);

    # --- Thumbnail Frame ---
    my $thumb_frame = Gtk3::Frame->new;
    my $thumb_frame_label = Gtk3::Label->new;
    $thumb_frame_label->set_markup("<b>" . $d->get("Thumbnail") . "</b>");
    $thumb_frame->set_label_widget($thumb_frame_label);
    $thumb_frame->set_shadow_type('none');
    
    my $thumb_vbox = Gtk3::VBox->new(FALSE, 0);
    
    my $thumb_box = Gtk3::HBox->new(FALSE, 0);
    my $thumb_label = Gtk3::Label->new($d->get("Thumbnail size") . ":");
    my $thumbnail = Gtk3::SpinButton->new_with_range(10, 200, 10);
    $thumbnail->set_value($sm->get_setting('general', 'thumbnail') // 50);
    my $thumb_vlabel = Gtk3::Label->new($d->get("pixels"));
    
    $thumb_box->pack_start($thumb_label, FALSE, FALSE, 12);
    $thumb_box->pack_start($thumbnail, FALSE, FALSE, 0);
    $thumb_box->pack_start($thumb_vlabel, FALSE, FALSE, 5);
    $thumb_vbox->pack_start($thumb_box, TRUE, TRUE, 3);
    
    $thumb_frame->add($thumb_vbox);
    $vbox_main->pack_start($thumb_frame, FALSE, TRUE, 3);

    $self->_vbox($vbox_main);
    $self->_close_at_close($close_at_close);
    $self->_autohide($autohide);
    $self->_notify_agent($notify_agent);
    $self->_thumbnail($thumbnail);
    return;
}

sub get_widget ($self) {
    return $self->_vbox;
}

sub save ($self) {
    my $sm = $self->cli->{settings_manager};
    $sm->set_setting('general', 'close_at_close', $self->_close_at_close->get_active);
    $sm->set_setting('general', 'autohide', $self->_autohide->get_active);
    $sm->set_setting('general', 'notify_agent', $self->_notify_agent->get_active);
    $sm->set_setting('general', 'thumbnail', $self->_thumbnail->get_value);
    return;
}

1;
