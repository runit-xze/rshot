package Shutter::App::UI::Settings::Capture;

use utf8;
use v5.40;
use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

has _vbox => (is => 'rw');
has _cursor_active => (is => 'rw');
has _delay => (is => 'rw');
has _gif_fps => (is => 'rw');
has _gif_max_duration => (is => 'rw');
has _gif_countdown => (is => 'rw');
has _gif_cursor => (is => 'rw');

sub BUILD ($self, $args) {
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;
    my $sm = $self->cli->{settings_manager};

    my $vbox_main = Gtk3::VBox->new(FALSE, 12);
    $vbox_main->set_border_width(5);

    # --- Capture Frame ---
    my $capture_frame = Gtk3::Frame->new;
    my $capture_frame_label = Gtk3::Label->new;
    $capture_frame_label->set_markup("<b>" . $d->get("Standard Capture") . "</b>");
    $capture_frame->set_label_widget($capture_frame_label);
    $capture_frame->set_shadow_type('none');
    
    my $capture_vbox = Gtk3::VBox->new(FALSE, 0);
    
    my $cursor_active = Gtk3::CheckButton->new_with_label($d->get("Include cursor when taking a screenshot"));
    $cursor_active->set_active($sm->get_setting('general', 'cursor') // FALSE);
    $capture_vbox->pack_start($cursor_active, FALSE, TRUE, 3);
    
    my $delay_box = Gtk3::HBox->new(FALSE, 0);
    my $delay_label = Gtk3::Label->new($d->get("Capture after a delay of"));
    my $delay = Gtk3::SpinButton->new_with_range(0, 99, 1);
    $delay->set_value($sm->get_setting('general', 'delay') // 0);
    my $delay_vlabel = Gtk3::Label->new($d->get("seconds"));
    
    $delay_box->pack_start($delay_label, FALSE, FALSE, 12);
    $delay_box->pack_start($delay, FALSE, FALSE, 0);
    $delay_box->pack_start($delay_vlabel, FALSE, FALSE, 5);
    $capture_vbox->pack_start($delay_box, TRUE, TRUE, 3);
    
    $capture_frame->add($capture_vbox);
    $vbox_main->pack_start($capture_frame, FALSE, TRUE, 3);

    # --- GIF Frame ---
    my $gif_frame = Gtk3::Frame->new;
    my $gif_frame_label = Gtk3::Label->new;
    $gif_frame_label->set_markup("<b>" . $d->get("GIF Recording") . "</b>");
    $gif_frame->set_label_widget($gif_frame_label);
    $gif_frame->set_shadow_type('none');
    
    my $gif_vbox = Gtk3::VBox->new(FALSE, 0);
    
    # FPS
    my $gif_fps_box = Gtk3::HBox->new(FALSE, 0);
    my $gif_fps_label = Gtk3::Label->new($d->get("Frames per second (FPS)") . ":");
    my $gif_fps = Gtk3::SpinButton->new_with_range(1, 30, 1);
    $gif_fps->set_value($sm->get_setting('gif', 'fps') // 10);
    $gif_fps_box->pack_start($gif_fps_label, FALSE, FALSE, 12);
    $gif_fps_box->pack_start($gif_fps, FALSE, FALSE, 0);
    $gif_vbox->pack_start($gif_fps_box, TRUE, TRUE, 3);
    
    # Duration
    my $gif_duration_box = Gtk3::HBox->new(FALSE, 0);
    my $gif_duration_label = Gtk3::Label->new($d->get("Max duration (0 for unlimited)") . ":");
    my $gif_duration = Gtk3::SpinButton->new_with_range(0, 300, 1);
    $gif_duration->set_value($sm->get_setting('gif', 'max_duration') // 30);
    my $gif_duration_vlabel = Gtk3::Label->new($d->get("seconds"));
    $gif_duration_box->pack_start($gif_duration_label, FALSE, FALSE, 12);
    $gif_duration_box->pack_start($gif_duration, FALSE, FALSE, 0);
    $gif_duration_box->pack_start($gif_duration_vlabel, FALSE, FALSE, 5);
    $gif_vbox->pack_start($gif_duration_box, TRUE, TRUE, 3);
    
    # Countdown
    my $gif_countdown_box = Gtk3::HBox->new(FALSE, 0);
    my $gif_countdown_label = Gtk3::Label->new($d->get("Start countdown") . ":");
    my $gif_countdown = Gtk3::SpinButton->new_with_range(0, 5, 1);
    $gif_countdown->set_value($sm->get_setting('gif', 'countdown') // 3);
    my $gif_countdown_vlabel = Gtk3::Label->new($d->get("seconds"));
    $gif_countdown_box->pack_start($gif_countdown_label, FALSE, FALSE, 12);
    $gif_countdown_box->pack_start($gif_countdown, FALSE, FALSE, 0);
    $gif_countdown_box->pack_start($gif_countdown_vlabel, FALSE, FALSE, 5);
    $gif_vbox->pack_start($gif_countdown_box, TRUE, TRUE, 3);
    
    # Cursor
    my $gif_cursor = Gtk3::CheckButton->new_with_label($d->get("Include cursor in recording"));
    $gif_cursor->set_active($sm->get_setting('gif', 'cursor') // 1);
    $gif_vbox->pack_start($gif_cursor, FALSE, TRUE, 3);
    
    $gif_frame->add($gif_vbox);
    $vbox_main->pack_start($gif_frame, FALSE, TRUE, 3);

    $self->_vbox($vbox_main);
    $self->_cursor_active($cursor_active);
    $self->_delay($delay);
    $self->_gif_fps($gif_fps);
    $self->_gif_max_duration($gif_duration);
    $self->_gif_countdown($gif_countdown);
    $self->_gif_cursor($gif_cursor);
}

sub get_widget ($self) {
    return $self->_vbox;
}

sub save ($self) {
    my $sm = $self->cli->{settings_manager};
    $sm->set_setting('general', 'cursor', $self->_cursor_active->get_active);
    $sm->set_setting('general', 'delay', $self->_delay->get_value);
    
    $sm->set_setting('gif', 'fps', $self->_gif_fps->get_value);
    $sm->set_setting('gif', 'max_duration', $self->_gif_max_duration->get_value);
    $sm->set_setting('gif', 'countdown', $self->_gif_countdown->get_value);
    $sm->set_setting('gif', 'cursor', $self->_gif_cursor->get_active);
}

1;
