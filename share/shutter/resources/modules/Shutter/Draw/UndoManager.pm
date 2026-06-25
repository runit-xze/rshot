package Shutter::Draw::UndoManager;

use utf8;
use v5.40;
use Moo;
use Glib qw/TRUE FALSE/;

has 'undo_stack' => (is => 'rw', default => sub { [] });
has 'redo_stack' => (is => 'rw', default => sub { [] });
has 'uimanager'  => (is => 'ro');

# Store action info; $do_info must be built externally (requires DrawingTool's _items hash)
sub store_action {
	my ($self, $do_info, $stack, $source) = @_;
    return FALSE unless $do_info && $do_info->{item};

    # Reset redo stack unless source is 'ui'
    unless ($source && $source eq 'ui') {
        @{$self->redo_stack} = ();
    }

    if ($stack eq 'undo') {
        push @{$self->undo_stack}, $do_info;
    } elsif ($stack eq 'redo') {
        push @{$self->redo_stack}, $do_info;
    }

    $self->update_ui_sensitivity;

    return TRUE;
}

# Remove all actions for an item from the specified stack
sub remove_item {
	my ($self, $stack, $item) = @_;
    my @indices;
    my $counter = 0;

    my $target_ref = ($stack eq 'undo') ? $self->undo_stack : $self->redo_stack;

    foreach my $do (@$target_ref) {
        push @indices, $counter if $item == $do->{'item'};
        $counter++;
    }

    foreach my $index (reverse @indices) {
        splice(@$target_ref, $index, 1);
    }

    $self->update_ui_sensitivity;
    return TRUE;
}

# Get the reverse action for undo/redo
sub get_reverse_action {
	my ($self, $action) = @_;
    return 'delete_xdo' if $action eq 'create';
    return 'create_xdo' if $action eq 'delete';
    return 'lower_xdo'  if $action eq 'raise';
    return 'raise_xdo'  if $action eq 'lower';
    return 'modify';
}

# Update UI widget sensitivity based on stack state
sub update_ui_sensitivity {
	my $self = shift;
    return TRUE unless $self->uimanager;

    my $ui = $self->uimanager;
    my $undo_count = scalar @{$self->undo_stack};
    my $redo_count = scalar @{$self->redo_stack};

    $ui->get_widget("/MenuBar/Edit/Undo")->set_sensitive($undo_count)
        if $ui->get_widget("/MenuBar/Edit/Undo");
    $ui->get_widget("/MenuBar/Edit/Redo")->set_sensitive($redo_count)
        if $ui->get_widget("/MenuBar/Edit/Redo");
    $ui->get_widget("/ToolBar/Undo")->set_sensitive($undo_count)
        if $ui->get_widget("/ToolBar/Undo");
    $ui->get_widget("/ToolBar/Redo")->set_sensitive($redo_count)
        if $ui->get_widget("/ToolBar/Redo");

    return TRUE;
}

# Get and pop from appropriate stack (used by xdo in DrawingTool)
sub pop_stack {
	my ($self, $stack) = @_;
    if ($stack eq 'undo') {
        return pop @{$self->undo_stack};
    } elsif ($stack eq 'redo') {
        return pop @{$self->redo_stack};
    }
    return undef;
}

1;

__END__

=head1 NAME

Shutter::Draw::UndoManager - Manages undo/redo operations for the drawing canvas

=head1 DESCRIPTION

Handles the undo stack, redo stack, and UI sensitivity updates for drawing operations.
