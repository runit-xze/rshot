use strict;
use warnings;

use Gtk3 '-init';
use Pango;
use Glib qw/TRUE FALSE/;

use Test2::V0;
use Test2::Mock;

ok(eval { require Shutter::Draw::PropertyManager; 1 }, "Loaded PropertyManager") or diag $@;

{
    package MockDrawingTool;
    use Moo;

    has _d => (is => 'rw', default => sub { bless {}, 'MockGettext' });
    has drawing_window => (is => 'rw', default => sub { Gtk3::Window->new('toplevel') });
    has items => (is => 'rw', default => sub { {} });
    has font => (is => 'rw', default => sub { "Sans 10" });
    
    sub gettext { shift->_d }
    sub set_and_save_drawing_properties { 1 }
    sub xdo { 1 }
    
    sub current_item { undef }
    sub current_mode { 'pointer' }
    
    my $_last_fill_color;
    sub last_fill_color : lvalue { $_last_fill_color }
    my $_last_stroke_color;
    sub last_stroke_color : lvalue { $_last_stroke_color }
    my $_last_line_width;
    sub last_line_width : lvalue { $_last_line_width }
    my $_last_font;
    sub last_font : lvalue { $_last_font }
    my $_last_mode;
    sub last_mode : lvalue { $_last_mode }
    
    sub fill_color_w { bless {}, 'MockColorW' }
    sub stroke_color_w { bless {}, 'MockColorW' }
    sub line_spin_w { bless {}, 'MockSpinW' }
    sub font_btn_w { bless {}, 'MockFontW' }
    
    sub store_to_xdo_stack { 1 }
    sub handle_rects { 1 }
    sub handle_embedded { 1 }
}

{
    package MockGettext;
    sub get { return $_[1]; }
}

{
    package MockColorW;
    sub get_rgba { return Gtk3::Gdk::RGBA->new(1, 0, 0, 1) }
}
{
    package MockSpinW;
    sub get_value { return 1 }
}
{
    package MockFontW;
    sub get_font_name { return "Sans 10" }
}

{
    package MockCanvasRect;
    sub new { bless {}, shift }
    sub isa {
        my ($self, $type) = @_;
        return 1 if $type eq 'GooCanvas2::CanvasRect';
        return $self->UNIVERSAL::isa($type);
    }
    sub get { return 1; }
    sub set { 1 }
    sub get_bounds { bless {}, 'MockBounds' }
}

{
    package MockBounds;
    sub x1 { 0 }
    sub x2 { 10 }
    sub y1 { 0 }
    sub y2 { 10 }
}

{
    package MockColor;
    sub get_rgba { 'rgba_val' }
}

{
    package MockSpin;
    sub get_value { 5 }
}

{
    package MockItemWithProps;
    sub new {
        my ($class, $props_ref) = @_;
        bless { props_ref => $props_ref }, $class;
    }
    sub isa {
        my ($self, $type) = @_;
        return 1 if $type eq 'GooCanvas2::CanvasRect';
        return $self->UNIVERSAL::isa($type);
    }
    sub get { return 1; }
    sub set {
        my ($self, %args) = @_;
        for my $k (keys %args) {
            $self->{props_ref}->{$k} = $args{$k};
        }
    }
}

subtest 'PropertyManager creation' => sub {
    my $dt = MockDrawingTool->new;
    my $pm = Shutter::Draw::PropertyManager->new(drawing_tool => $dt);
    
    ok(defined $pm, 'PropertyManager instantiated');
    is($pm->drawing_tool, $dt, 'drawing_tool attribute works');
};

subtest 'apply_properties for Rect' => sub {
    my $dt = MockDrawingTool->new;
    $dt->items->{'testkey'} = { type => 'rect' };
    my $pm = Shutter::Draw::PropertyManager->new(drawing_tool => $dt);
    
    my %set_props;
    my $item = MockItemWithProps->new(\%set_props);

    my $mock_color = bless {}, 'MockColor';
    my $mock_spin  = bless {}, 'MockSpin';
    
    $pm->apply_properties(
        $item, undef, 'testkey',
        $mock_color, $mock_color, $mock_spin,
        undef, undef, undef,
        undef, undef, undef, undef, undef, undef,
        1
    );
    
    is($set_props{'line-width'}, 5, 'Line width is updated');
    is($set_props{'fill-color-gdk-rgba'}, 'rgba_val', 'Fill color is updated');
    is($set_props{'stroke-color-gdk-rgba'}, 'rgba_val', 'Stroke color is updated');
};

subtest 'show_item_properties runs without error' => sub {
    my $dt = MockDrawingTool->new;
    $dt->items->{'testkey'} = { type => 'rect', fill_color => Gtk3::Gdk::RGBA->new(1,0,0,1), stroke_color => Gtk3::Gdk::RGBA->new(0,1,0,1) };
    my $pm = Shutter::Draw::PropertyManager->new(drawing_tool => $dt);
    
    my $item = MockCanvasRect->new;
    
    my $dialog_mock = mock 'Gtk3::Dialog' => (
        override => [
            run => sub { return 'ok'; }
        ],
    );
    
    my $res = $pm->show_item_properties($item, undef, 'testkey');
    ok($res, 'show_item_properties returned true');
};

done_testing;
