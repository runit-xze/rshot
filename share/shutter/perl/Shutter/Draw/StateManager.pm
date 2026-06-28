package Shutter::Draw::StateManager;
use Moo;
use utf8;
use v5.40;
use Glib           qw/TRUE FALSE/;
use File::Basename qw/fileparse/;

use Shutter::App::Core::FileSystemAPI;
has drawing_tool => (is => 'ro', required => 1);

sub quit {
	my ($mgr, $show_warning) = @_;
	my $self = $mgr->drawing_tool;

	my ($name, $folder, $type) = fileparse($self->_filename, qr/\.[^.]*/);

	#save settings to a file in the shutter folder
	#is there already a .shutter folder?
	Shutter::App::Core::FileSystemAPI->new->make_dir("$ENV{ 'HOME' }/.shutter")
		unless (Shutter::App::Core::FileSystemAPI->new->is_directory("$ENV{ 'HOME' }/.shutter"));

	if ($show_warning && (defined $self->_undo && scalar(@{$self->_undo}) > 0)) {

		#warn the user if there are any unsaved changes
		my $warn_dialog = Gtk3::MessageDialog->new($self->_drawing_window, [qw/modal destroy-with-parent/], 'other', 'none', undef);

		#set question text
		$warn_dialog->set('text' => sprintf($self->_d->get("Save the changes to image %s before closing?"), "'$name$type'"));

		#set text...
		$self->update_warning_text($warn_dialog);

		#...and update it
		my $id = Glib::Timeout->add(
			1000,
			sub {
				$self->update_warning_text($warn_dialog);
				return TRUE;
			});

		$warn_dialog->set('image' => Gtk3::Image->new_from_stock('gtk-save', 'dialog'));

		$warn_dialog->set('title' => $self->_d->get("Close") . " " . $name . $type);

		#don't save button
		my $dsave_btn = Gtk3::Button->new_with_mnemonic($self->_d->get("Do_n't save"));
		$dsave_btn->set_image(Gtk3::Image->new_from_stock('gtk-delete', 'button'));

		#cancel button
		my $cancel_btn = Gtk3::Button->new_from_stock('gtk-cancel');
		$cancel_btn->set_can_default(TRUE);

		#save button
		my $save_btn = Gtk3::Button->new_from_stock('gtk-save');

		$warn_dialog->add_action_widget($dsave_btn,  10);
		$warn_dialog->add_action_widget($cancel_btn, 20);
		$warn_dialog->add_action_widget($save_btn,   30);

		$warn_dialog->set_default_response(20);

		$warn_dialog->get_child->show_all;
		my $response = $warn_dialog->run;
		Glib::Source->remove($id);
		if ($response == 20) {
			$warn_dialog->destroy;
			return TRUE;
		} elsif ($response == 30) {
			$self->save();
		}

		$self->_drawing_window->hide if $self->_drawing_window;
		$warn_dialog->hide;
		$warn_dialog->destroy;

	}

	$self->save_settings;

	if ($self->_selector_handler) {
		$self->_selector->signal_handler_disconnect($self->_selector_handler);
	}

	$self->_drawing_window->hide if $self->_drawing_window;

	$self->_drawing_window->destroy if $self->_drawing_window;

	#remove statusbar timer
	#Glib::Source->remove($self->_drawing_statusbar->{statusbar_timer}) if defined $self->_drawing_statusbar->{statusbar_timer};

	#delete hash entries to avoid any
	#possible circularity
	#
	#this would lead to a memory leak
	foreach (keys %{$self}) {
		delete $self->{$_};
	}

	Gtk3->main_quit();

	return FALSE;
}

sub update_warning_text {
	my ($mgr, $warn_dialog) = @_;
	my $self = $mgr->drawing_tool;

	my $minutes = int((time - $self->_start_time) / 60);
	$minutes = 1 if $minutes == 0;

	my $txt = $self->_d->nget("If you don't save the image, changes from the last minute will be lost", "If you don't save the image, changes from the last %d minutes will be lost", $minutes);

	$txt = sprintf($txt, $minutes) if $minutes > 1;

	$warn_dialog->set('secondary-text' => "$txt.");

	return TRUE;
}

sub push_tool_help_to_statusbar {
	my ($mgr, $x, $y, $action) = @_;
	my $self = $mgr->drawing_tool;

	#init $action if not defined
	$action = 'none' unless defined $action;

	#current event coordinates
	my $status_text = int($x) . " x " . int($y);

	if ($self->_current_mode == 10) {

		if ($action eq 'resize') {
			$status_text .= " " . $self->_d->get("Click-Drag to scale (try Control to scale uniformly)");
		} elsif ($action eq 'canvas_resize') {
			$status_text .= " " . $self->_d->get("Click-Drag to resize the canvas");
		}

	} elsif ($self->_current_mode == 20 || $self->_current_mode == 30) {

		$status_text .= " " . $self->_d->get("Click to paint (try Control or Shift for a straight line)");

	} elsif ($self->_current_mode == 40) {

		$status_text .= " " . $self->_d->get("Click-Drag to create a new straight line");

	} elsif ($self->_current_mode == 50) {

		$status_text .= " " . $self->_d->get("Click-Drag to create a new arrow");

	} elsif ($self->_current_mode == 60) {

		$status_text .= " " . $self->_d->get("Click-Drag to create a new rectangle");

	} elsif ($self->_current_mode == 70) {

		$status_text .= " " . $self->_d->get("Click-Drag to create a new ellipse");

	} elsif ($self->_current_mode == 80) {

		$status_text .= " " . $self->_d->get("Click-Drag to add a new text area");

	} elsif ($self->_current_mode == 90) {

		$status_text .= " " . $self->_d->get("Click to censor (try Control or Shift for a straight line)");

	} elsif ($self->_current_mode == 100) {

		$status_text .= " " . $self->_d->get("Click-Drag to create a pixelized region");

	} elsif ($self->_current_mode == 110) {

		$status_text .= " " . $self->_d->get("Click to add an auto-increment shape");

	} elsif ($self->_current_mode == 120) {

		#nothing to do here....

	}

	#update statusbar
	$self->show_status_message(1, $status_text);

	return TRUE;

}

sub show_status_message {
	my $mgr          = shift;
	my $self         = $mgr->drawing_tool;
	my $index        = shift;
	my $status_text  = shift;
	my $status_image = shift;                #this is a stock-id

	#~ #remove old message and timer
	#~ $self->_drawing_statusbar->pop($index);
	#~ Glib::Source->remove ($self->_drawing_statusbar->{statusbar_timer}) if defined $self->_drawing_statusbar->{statusbar_timer};

	#new message and image
	if (defined $status_image) {
		$self->_drawing_statusbar_image->set_from_stock($status_image, 'menu');
	} else {
		$self->_drawing_statusbar_image->clear;
	}
	$self->_drawing_statusbar->push($index, $status_text);

	#~ #...and remove it
	#~ $self->_drawing_statusbar->{statusbar_timer} = Glib::Timeout->add(
	#~ 3000,
	#~ sub {
	#~ $self->_drawing_statusbar->pop($index) if defined $self->_drawing_statusbar;
	#~ return FALSE;
	#~ }
	#~ );

	return TRUE;
}
1;
