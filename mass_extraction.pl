#!/usr/bin/env perl
use strict;
use warnings;
use File::Slurp;

my $dt_file = 'share/shutter/resources/modules/Shutter/Draw/DrawingTool.pm';
my $dt = read_file($dt_file);

my %managers = (
    'MouseManager' => [qw/
        event_item_on_motion_notify
        event_item_on_key_press
        event_item_on_button_press
        event_item_on_button_release
        event_item_on_enter_notify
        event_item_on_leave_notify
    /],
    'ItemFactory' => [qw/
        create_polyline create_censor create_pixel_image create_image
        create_text create_line create_ellipse create_rectangle
        paste_item get_opposite_rect get_parent_item get_highest_auto_digit
        get_pixelated_pixbuf_from_canvas get_child_item
    /],
    'MacroManager' => [qw/
        store_to_xdo_stack xdo_remove xdo
    /],
    'UIManager' => [qw/
        setup_right_vbox_c adjust_crop_values push_tool_help_to_statusbar
        show_status_message change_drawing_tool_cb zoom_in_cb zoom_out_cb
        zoom_normal_cb adjust_rulers update_warning_text setup_uimanager
        ret_background_menu ret_item_menu get_item_key
        abort_current_mode clear_item_from_canvas move_all deactivate_all
        change_cursor_to_current_pixbuf set_drawing_action
    /],
);

my $manager_init = '';

for my $mgr (keys %managers) {
    my $pkg = "Shutter::Draw::$mgr";
    my $file = "share/shutter/resources/modules/Shutter/Draw/$mgr.pm";
    
    my $code = <<EOF;
package $pkg;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;

has drawing_tool => (is => 'ro', required => 1);

EOF

    my @methods = @{$managers{$mgr}};
    
    for my $method (@methods) {
        # Extract body
        if ($dt =~ s/^sub $method \{.*?\n(?=^sub |^1;)//ms) {
            my $body = $&;
            
            # Change $self->{...} to $self->drawing_tool->... is too hard automatically,
            # but we can rely on AUTOLOAD if we just swap $self with $dt and do $dt->foo
            # Actually, simpler: in the extracted body, do `my $self = shift->drawing_tool;`
            # and keep all `$self->{_foo}` working by letting DrawingTool handle it!
            # Wait, if we redefine $self as drawing_tool, then $self is DrawingTool.
            $body =~ s/my \$self\s*=\s*shift;/my \$mgr = shift;\n\tmy \$self = \$mgr->drawing_tool;/;
            $body =~ s/my \(\$self, /my \(\$mgr, /;
            $body =~ s/\$self = \$mgr->drawing_tool;/\$self = \$mgr->drawing_tool; # INJECTED/ if $body =~ /my \(\$mgr, /;
            
            # If it uses my ($self, ...), inject $self
            if ($body =~ /my \(\$mgr, (.*?)\) = \@_;/) {
                my $vars = $1;
                $body =~ s/my \(\$mgr, (.*?)\) = \@_;/my \(\$mgr, $vars\) = \@_;\n\tmy \$self = \$mgr->drawing_tool;/;
            }

            $code .= $body . "\n";
            
            # Replace with delegation
            $dt .= "sub $method { shift->{_$mgr}->$method(\@_) }\n";
        } elsif ($dt =~ s/^sub $method \{.*//ms) { # EOF case
            my $body = $&;
            $body =~ s/my \$self\s*=\s*shift;/my \$mgr = shift;\n\tmy \$self = \$mgr->drawing_tool;/;
            $code .= $body . "\n";
            $dt .= "sub $method { shift->{_$mgr}->$method(\@_) }\n";
        }
    }
    
    $code .= "\n1;\n";
    #write_file($file, $code);
    
    $manager_init .= "\n\trequire $pkg;\n\t\$self->{_$mgr} = $pkg->new(drawing_tool => \$self);";
}

# Inject init into new()
$dt =~ s/(sub new \{.+?)(return \$self;)/$1$manager_init\n\n\t$2/s;

write_file($dt_file, $dt);
print "Mass extraction complete!\n";
