###################################################
#
#  Copyright (C) 2025 Shutter Team
#
#  This file is part of Shutter.
#
###################################################

package Shutter::App::UI::Settings::ShareX;

use utf8;
use v5.40;
use feature 'try';
no warnings 'experimental::try';

use Moo;
use Gtk3;
use Glib qw/TRUE FALSE/;
use File::Copy;
use File::Basename;
use File::Path qw(make_path);
use JSON;

has cli => (is => 'ro', required => 1);

# Widgets
has _vbox => (is => 'rw');
has _liststore => (is => 'rw');
has _treeview => (is => 'rw');
has _uploaders_dir => (is => 'rw', default => sub { $ENV{'HOME'} . "/.shutter/uploaders" });

sub BUILD ($self, $args) {
    my $sc = $self->cli->sc;
    my $d = $sc->get_gettext;

    make_path($self->_uploaders_dir) unless -d $self->_uploaders_dir;

    my $vbox_main = Gtk3::VBox->new(FALSE, 12);
    $vbox_main->set_border_width(5);

    # --- Uploaders Frame ---
    my $frame = Gtk3::Frame->new;
    my $frame_label = Gtk3::Label->new;
    $frame_label->set_markup("<b>" . $d->get("ShareX Custom Uploaders (.sxcu)") . "</b>");
    $frame->set_label_widget($frame_label);
    $frame->set_shadow_type('none');
    
    my $vbox = Gtk3::VBox->new(FALSE, 6);
    $vbox->set_border_width(6);

    # ListStore: Name, Filename, Type, FullPath
    my $liststore = Gtk3::ListStore->new('Glib::String', 'Glib::String', 'Glib::String', 'Glib::String');
    $self->_liststore($liststore);

    my $treeview = Gtk3::TreeView->new_with_model($liststore);
    $self->_treeview($treeview);
    
    $treeview->get_selection->signal_connect(changed => sub { $self->_on_selection_changed() });

    my $renderer = Gtk3::CellRendererText->new;
    my $column1 = Gtk3::TreeViewColumn->new_with_attributes($d->get("Name"), $renderer, text => 0);
    $treeview->append_column($column1);

    my $column2 = Gtk3::TreeViewColumn->new_with_attributes($d->get("Filename"), $renderer, text => 1);
    $treeview->append_column($column2);

    my $column3 = Gtk3::TreeViewColumn->new_with_attributes($d->get("Type"), $renderer, text => 2);
    $treeview->append_column($column3);

    my $scrolled = Gtk3::ScrolledWindow->new;
    $scrolled->set_policy('automatic', 'automatic');
    $scrolled->add($treeview);
    $scrolled->set_size_request(-1, 200);
    $vbox->pack_start($scrolled, TRUE, TRUE, 0);

    # Buttons
    my $hbox_buttons = Gtk3::HBox->new(FALSE, 6);
    
    my $btn_add = Gtk3::Button->new_with_label($d->get("Add..."));
    $btn_add->signal_connect(clicked => sub { $self->_add_uploader() });
    
    my $btn_delete = Gtk3::Button->new_with_label($d->get("Delete"));
    $btn_delete->set_sensitive(FALSE); # disabled by default until selected
    $self->{_btn_delete} = $btn_delete;
    $btn_delete->signal_connect(clicked => sub { $self->_delete_uploader() });
    
    my $btn_view = Gtk3::Button->new_with_label($d->get("View in Folder"));
    $btn_view->signal_connect(clicked => sub { $self->_view_folder() });

    $hbox_buttons->pack_start($btn_add, FALSE, FALSE, 0);
    $hbox_buttons->pack_start($btn_delete, FALSE, FALSE, 0);
    $hbox_buttons->pack_start($btn_view, FALSE, FALSE, 0);
    
    $vbox->pack_start($hbox_buttons, FALSE, FALSE, 0);

    $frame->add($vbox);
    $vbox_main->pack_start($frame, TRUE, TRUE, 3);

    $self->_vbox($vbox_main);
    
    $self->_refresh_list();
}

sub get_widget ($self) {
    return $self->_vbox;
}

sub _on_selection_changed ($self) {
    my $selection = $self->_treeview->get_selection;
    my ($model, $iter) = $selection->get_selected;
    if ($iter) {
        my $type = $model->get_value($iter, 2);
        $self->{_btn_delete}->set_sensitive($type eq 'Custom' ? TRUE : FALSE);
    } else {
        $self->{_btn_delete}->set_sensitive(FALSE);
    }
}

sub _refresh_list ($self) {
    $self->_liststore->clear;
    
    my $shutter_root = $self->cli->shutter_root;
    my $system_dir = "$shutter_root/share/shutter/resources/system/uploaders";
    
    my @sxcus = (
        map { { path => $_, type => 'System' } } glob("$system_dir/*.sxcu")
    );
    push @sxcus, map { { path => $_, type => 'Custom' } } glob($self->_uploaders_dir . "/*.sxcu");

    my $json = JSON->new->allow_nonref;
    foreach my $item (@sxcus) {
        my $file = $item->{path};
        my $type = $item->{type};
        my $basename = basename($file);
        my $name = $basename;
        if (open(my $fh, '<', $file)) {
            local $/ = undef;
            my $content = <$fh>;
            close($fh);
            try {
                my $data = $json->decode($content);
                $name = $data->{Name} if $data->{Name};
            } catch ($e) {
                print "Error parsing $file: $e\n";
            }
        }
        my $iter = $self->_liststore->append;
        $self->_liststore->set($iter, 0 => $name, 1 => $basename, 2 => $type, 3 => $file);
    }
    
    $self->_on_selection_changed();
}

sub _add_uploader ($self) {
    my $sc = $self->cli->sc;
    my $dialog = Gtk3::FileChooserDialog->new(
        "Select ShareX Uploader",
        undef,
        'open',
        'gtk-cancel' => 'cancel',
        'gtk-open'   => 'accept'
    );
    
    my $filter = Gtk3::FileFilter->new;
    $filter->set_name("ShareX Custom Uploaders (*.sxcu)");
    $filter->add_pattern("*.sxcu");
    $dialog->add_filter($filter);
    
    if ($dialog->run eq 'accept') {
        my $file = $dialog->get_filename;
        my $basename = basename($file);
        my $dest = $self->_uploaders_dir . "/" . $basename;
        copy($file, $dest);
        $self->_refresh_list();
    }
    $dialog->destroy;
}

sub _delete_uploader ($self) {
    my $selection = $self->_treeview->get_selection;
    my ($model, $iter) = $selection->get_selected;
    if ($iter) {
        my $path = $model->get_value($iter, 3);
        my $type = $model->get_value($iter, 2);
        if ($type eq 'Custom') {
            unlink($path) if -e $path;
            $self->_refresh_list();
        }
    }
}

sub _view_folder ($self) {
    my $uri = "file://" . $self->_uploaders_dir;
    eval { Gtk3::show_uri_on_window(undef, $uri, Gtk3::Gdk::CURRENT_TIME); };
}

sub save ($self) {
    # nothing to save, it manipulates the files directly
}

1;
