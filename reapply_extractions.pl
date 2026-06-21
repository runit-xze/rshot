#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

# Instantiate managers in new()
# We look for $self->{_uimanager} = ... or similar, and add our managers
my $manager_init = <<'EOF';

	require Shutter::Draw::PropertyManager;
	$self->{_property_manager} = Shutter::Draw::PropertyManager->new(drawing_tool => $self);

	require Shutter::Draw::IOManager;
	$self->{_io_manager} = Shutter::Draw::IOManager->new(drawing_tool => $self);

	require Shutter::Draw::SettingsManager;
	$self->{_settings_manager} = Shutter::Draw::SettingsManager->new(drawing_tool => $self);
EOF

$dt =~ s/(sub new \{.+?)(return \$self;)/$1$manager_init\n\n\t$2/s;

# Replace Phase 2 Methods
my %phase2 = (
    show_item_properties => 'sub show_item_properties { shift->{_property_manager}->show_item_properties(@_) }',
    apply_properties => 'sub apply_properties { shift->{_property_manager}->apply_properties(@_) }',
    modify_text_in_properties => 'sub modify_text_in_properties { shift->{_property_manager}->modify_text_in_properties(@_) }',
);

# Replace Phase 3 Methods
my %phase3 = (
    export_to_file => 'sub export_to_file { shift->{_io_manager}->export_to_file(@_) }',
    export_to_svg => 'sub export_to_svg { shift->{_io_manager}->export_to_svg(@_) }',
    export_to_ps => 'sub export_to_ps { shift->{_io_manager}->export_to_ps(@_) }',
    export_to_pdf => 'sub export_to_pdf { shift->{_io_manager}->export_to_pdf(@_) }',
    save => 'sub save { shift->{_io_manager}->save(@_) }',
    import_from_dnd => 'sub import_from_dnd { shift->{_io_manager}->import_from_dnd(@_) }',
    import_from_filesystem => 'sub import_from_filesystem { shift->{_io_manager}->import_from_filesystem(@_) }',
    import_from_utheme => 'sub import_from_utheme { shift->{_io_manager}->import_from_utheme(@_) }',
    import_from_utheme_ctxt => 'sub import_from_utheme_ctxt { shift->{_io_manager}->import_from_utheme_ctxt(@_) }',
    import_from_session => 'sub import_from_session { shift->{_io_manager}->import_from_session(@_) }',
);

# Replace Phase 5 Methods
my %phase5 = (
    load_settings => 'sub load_settings { shift->{_settings_manager}->load_settings(@_) }',
    save_settings => 'sub save_settings { shift->{_settings_manager}->save_settings(@_) }',
    set_and_save_drawing_properties => 'sub set_and_save_drawing_properties { shift->{_settings_manager}->set_and_save_drawing_properties(@_) }',
    restore_fixed_properties => 'sub restore_fixed_properties { shift->{_settings_manager}->restore_fixed_properties(@_) }',
    restore_drawing_properties => 'sub restore_drawing_properties { shift->{_settings_manager}->restore_drawing_properties(@_) }',
);

my %all_methods = (%phase2, %phase3, %phase5);

for my $method (keys %all_methods) {
    # Match sub name { ... } ensuring we handle nested braces.
    # A simple regex for nested braces is tricky, so we'll just match until `\nsub `
    # Or better yet, we can replace everything between `sub method {` and the next `^sub `
    
    my $replacement = $all_methods{$method};
    
    # We use a lazy match to the next \nsub 
    if ($dt =~ s/^sub $method \{.*?\n(?=^sub )/$replacement\n\n/ms) {
        print "Replaced $method\n";
    } else {
        # If it's the very last sub, it might not match \nsub 
        if ($dt =~ s/^sub $method \{.*//ms) {
            $dt .= "$replacement\n";
            print "Replaced $method (last)\n";
        } else {
            print "Failed to replace $method\n";
        }
    }
}

write_file($dt_file, $dt);
print "Done applying extractions!\n";
