package Shutter::App::UI::Settings::Video;

use utf8;
use v5.40;
use feature 'try'; no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);
has _vbox => (is => 'rw');

sub BUILD ($self, $args) {
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;
    my $sm = $self->cli->{settings_manager};

    my $vbox_main = Gtk3::VBox->new(FALSE, 12);
    $vbox_main->set_border_width(5);

    # --- Recording Settings Frame ---
    my $frame_rec = Gtk3::Frame->new;
    my $frame_rec_label = Gtk3::Label->new;
    $frame_rec_label->set_markup("<b>" . $d->get("Recording Options") . "</b>");
    $frame_rec->set_label_widget($frame_rec_label);
    $frame_rec->set_shadow_type('none');
    
    my $vbox_rec = Gtk3::VBox->new(FALSE, 6);
    $vbox_rec->set_border_width(6);

    # FPS
    my $hbox_fps = Gtk3::HBox->new(FALSE, 6);
    $hbox_fps->pack_start(Gtk3::Label->new($d->get("Frames per Second:")), FALSE, FALSE, 0);
    my $fps_adj = Gtk3::Adjustment->new($sm->get_setting('video', 'fps') // 30, 1, 144, 1, 10, 0);
    my $spin_fps = Gtk3::SpinButton->new($fps_adj, 1, 0);
    $spin_fps->signal_connect('value-changed' => sub {
        $sm->set_setting('video', 'fps', $spin_fps->get_value);
    });
    $hbox_fps->pack_start($spin_fps, FALSE, FALSE, 0);
    $vbox_rec->pack_start($hbox_fps, FALSE, FALSE, 0);
    
    $frame_rec->add($vbox_rec);
    $vbox_main->pack_start($frame_rec, FALSE, FALSE, 3);

    # --- Audio Settings Frame ---
    my $frame_audio = Gtk3::Frame->new;
    my $frame_audio_label = Gtk3::Label->new;
    $frame_audio_label->set_markup("<b>" . $d->get("Audio Sources") . "</b>");
    $frame_audio->set_label_widget($frame_audio_label);
    $frame_audio->set_shadow_type('none');
    
    my $vbox_audio = Gtk3::VBox->new(FALSE, 6);
    $vbox_audio->set_border_width(6);

    # Desktop Audio
    my $chk_desktop = Gtk3::CheckButton->new_with_label($d->get("Record Desktop Audio (System Sounds)"));
    $chk_desktop->set_active($sm->get_setting('video', 'record_desktop') // 0);
    $chk_desktop->signal_connect('toggled' => sub {
        $sm->set_setting('video', 'record_desktop', $chk_desktop->get_active ? 1 : 0);
    });
    $vbox_audio->pack_start($chk_desktop, FALSE, FALSE, 0);

    # Mic Audio
    my $chk_mic = Gtk3::CheckButton->new_with_label($d->get("Record Microphone Audio"));
    $chk_mic->set_active($sm->get_setting('video', 'record_mic') // 0);
    $chk_mic->signal_connect('toggled' => sub {
        $sm->set_setting('video', 'record_mic', $chk_mic->get_active ? 1 : 0);
    });
    $vbox_audio->pack_start($chk_mic, FALSE, FALSE, 0);

    $frame_audio->add($vbox_audio);
    $vbox_main->pack_start($frame_audio, FALSE, FALSE, 3);

    $self->_vbox($vbox_main);
}

sub get_widget ($self) {
    return $self->_vbox;
}

sub save ($self) {
    # Auto-saved on change
}

1;
