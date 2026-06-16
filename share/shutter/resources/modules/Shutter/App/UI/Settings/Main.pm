###################################################
#
#  Copyright (C) 2008-2013 Mario Kemper <mario.kemper@gmail.com>
#  Copyright (C) 2025 Shutter Team
#
#  This file is part of Shutter.
#
#  Shutter is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
###################################################

package Shutter::App::UI::Settings::Main;

use utf8;
use v5.40;
use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;

has cli => (is => 'ro', required => 1);

# Widgets
has _vbox => (is => 'rw');
has _combobox_type => (is => 'rw');
has _scale => (is => 'rw');
has _filename => (is => 'rw');
has _save_dir_button => (is => 'rw');
has _save_auto => (is => 'rw');
has _save_ask => (is => 'rw');
has _save_no => (is => 'rw');
has _image_autocopy => (is => 'rw');
has _fname_autocopy => (is => 'rw');
has _no_autocopy => (is => 'rw');
has _cursor_active => (is => 'rw');
has _delay => (is => 'rw');

sub BUILD ($self, $args) {
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;
    my $sm = $self->cli->{settings_manager};
    my $shf = $self->cli->shf;

    my $vbox_main = Gtk3::VBox->new(FALSE, 12);
    $vbox_main->set_border_width(5);

    # --- File Frame ---
    my $file_frame = Gtk3::Frame->new;
    my $file_frame_label = Gtk3::Label->new;
    $file_frame_label->set_markup("<b>" . $d->get("Main") . "</b>");
    $file_frame->set_label_widget($file_frame_label);
    $file_frame->set_shadow_type('none');
    
    my $file_vbox = Gtk3::VBox->new(FALSE, 0);
    
    # Image Format
    my $filetype_box = Gtk3::HBox->new(FALSE, 0);
    my $filetype_label = Gtk3::Label->new($d->get("Image format") . ":");
    my $combobox_type = Gtk3::ComboBoxText->new;
    
    my @supported_formats;
    foreach my $format (Gtk3::Gdk::Pixbuf::get_formats()) {
        my $format_name = $format->get_name;
        if (grep { $_ eq $format_name } qw(jpeg png bmp webp avif)) {
            $format_name = "jpg" if $format_name eq "jpeg";
            $combobox_type->append_text($format_name . " - " . $format->get_description);
            push @supported_formats, $format_name;
        }
    }
    $self->{_supported_formats} = \@supported_formats;
    
    my $current_type = $sm->get_setting('general', 'filetype') // 0;
    $combobox_type->set_active($current_type);
    
    $filetype_box->pack_start($filetype_label, FALSE, TRUE, 12);
    $filetype_box->pack_start($combobox_type, TRUE, TRUE, 0);
    $file_vbox->pack_start($filetype_box, FALSE, TRUE, 3);
    
    # Compression
    my $scale_box = Gtk3::HBox->new(FALSE, 0);
    my $scale_label = Gtk3::Label->new($d->get("Compression") . ":");
    my $scale = Gtk3::HScale->new_with_range(0, 9, 1);
    $scale->set_value_pos('right');
    $scale->set_value($sm->get_setting('general', 'quality') // 1);
    
    $scale_box->pack_start($scale_label, FALSE, TRUE, 12);
    $scale_box->pack_start($scale, TRUE, TRUE, 0);
    $file_vbox->pack_start($scale_box, TRUE, TRUE, 3);
    
    $file_frame->add($file_vbox);
    $vbox_main->pack_start($file_frame, FALSE, TRUE, 3);

    # --- Save Frame ---
    my $save_frame = Gtk3::Frame->new;
    my $save_frame_label = Gtk3::Label->new;
    $save_frame_label->set_markup("<b>" . $d->get("Save") . "</b>");
    $save_frame->set_label_widget($save_frame_label);
    $save_frame->set_shadow_type('none');
    
    my $save_vbox = Gtk3::VBox->new(FALSE, 0);
    
    # Save Mode
    my $save_auto = Gtk3::RadioButton->new_with_label(undef, $d->get("Automatically save file"));
    my $save_ask = Gtk3::RadioButton->new_with_label_from_widget($save_auto, $d->get("Browse for save folder every time"));
    my $save_no = Gtk3::RadioButton->new_with_label_from_widget($save_auto, $d->get("Do not save file automatically"));
    
    $save_auto->set_active(TRUE) if $sm->get_setting('general', 'save_auto') // TRUE;
    $save_ask->set_active(TRUE) if $sm->get_setting('general', 'save_ask');
    $save_no->set_active(TRUE) if $sm->get_setting('general', 'save_no');
    
    $save_vbox->pack_start($save_auto, TRUE, TRUE, 3);
    $save_vbox->pack_start($save_ask, TRUE, TRUE, 3);
    $save_vbox->pack_start($save_no, TRUE, TRUE, 3);
    
    # Filename
    my $filename_box = Gtk3::HBox->new(FALSE, 0);
    my $filename_label = Gtk3::Label->new($d->get("Filename") . ":");
    my $filename = Gtk3::Entry->new;
    $filename->set_text($sm->get_setting('general', 'filename') // '$name_%NNN');
    
    my $filename_hint = Gtk3::Label->new;
    $filename_hint->set_no_show_all(TRUE);
    $shf->validate_filename($filename, $filename_hint);
    
    $filename_box->pack_start($filename_label, FALSE, TRUE, 12);
    $filename_box->pack_start($filename, TRUE, TRUE, 0);
    $save_vbox->pack_start($filename_box, TRUE, TRUE, 3);
    $save_vbox->pack_start($filename_hint, TRUE, TRUE, 3);
    
    # Directory
    my $save_dir_box = Gtk3::HBox->new(FALSE, 0);
    my $save_dir_label = Gtk3::Label->new($d->get("Directory") . ":");
    my $save_dir_button = Gtk3::FileChooserButton->new($d->get("Choose folder"), 'select-folder');
    
    my $initial_dir = $sm->get_setting('general', 'folder') // Glib::get_user_special_dir('pictures') // Glib::get_home_dir();
    $save_dir_button->set_current_folder($initial_dir) if $initial_dir;
    
    $save_dir_box->pack_start($save_dir_label, FALSE, TRUE, 12);
    $save_dir_box->pack_start($save_dir_button, TRUE, TRUE, 0);
    $save_vbox->pack_start($save_dir_box, FALSE, TRUE, 3);
    
    $save_frame->add($save_vbox);
    $vbox_main->pack_start($save_frame, FALSE, TRUE, 3);
    
    # --- Capture Frame ---
    my $capture_frame = Gtk3::Frame->new;
    my $capture_frame_label = Gtk3::Label->new;
    $capture_frame_label->set_markup("<b>" . $d->get("Capture") . "</b>");
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

    # Sizegroups
    my $sg_main = Gtk3::SizeGroup->new('horizontal');
    $sg_main->add_widget($scale_label);
    $sg_main->add_widget($filetype_label);
    $sg_main->add_widget($filename_label);
    $sg_main->add_widget($save_dir_label);
    
    # Store widgets
    $self->_vbox($vbox_main);
    $self->_combobox_type($combobox_type);
    $self->_scale($scale);
    $self->_filename($filename);
    $self->_save_dir_button($save_dir_button);
    $self->_save_auto($save_auto);
    $self->_save_ask($save_ask);
    $self->_save_no($save_no);
    $self->_cursor_active($cursor_active);
    $self->_delay($delay);
}

sub get_widget ($self) {
    return $self->_vbox;
}

sub save ($self) {
    my $sm = $self->cli->{settings_manager};
    
    $sm->set_setting('general', 'filetype', $self->_combobox_type->get_active);
    $sm->set_setting('general', 'quality', $self->_scale->get_value);
    $sm->set_setting('general', 'filename', $self->_filename->get_text);
    $sm->set_setting('general', 'folder', $self->_save_dir_button->get_filename);
    $sm->set_setting('general', 'save_auto', $self->_save_auto->get_active);
    $sm->set_setting('general', 'save_ask', $self->_save_ask->get_active);
    $sm->set_setting('general', 'save_no', $self->_save_no->get_active);
    $sm->set_setting('general', 'cursor', $self->_cursor_active->get_active);
    $sm->set_setting('general', 'delay', $self->_delay->get_value);
}

1;
