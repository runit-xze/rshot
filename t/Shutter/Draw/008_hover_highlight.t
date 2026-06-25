use strict;
use warnings;

use Test2::V0;
use Test2::Mock;

{
    package MockDrawingToolHH;
    use Moo;

    has _busy => (is => 'rw', default => sub { 0 });
    has _items => (is => 'rw', default => sub { {} });
    has _canvas_bg_rect => (is => 'rw', default => sub { {} });
    has _style_bg => (is => 'rw', default => sub { 'rgba(0,0,0,1)' });

    sub get_parent_item { undef }
}

{
    package MockCanvasItem;
    use Moo;
    has fill_color => (is => 'rw', default => '');
    has fill_color_gdk_rgba => (is => 'rw', default => '');
    has _isa_type => (is => 'rw', required => 1);

    sub isa {
        my ($self, $type) = @_;
        return 1 if $type eq $self->_isa_type;
        return $self->UNIVERSAL::isa($type);
    }

    sub set {
        my ($self, %args) = @_;
        $self->fill_color($args{'fill-color'}) if exists $args{'fill-color'};
        $self->fill_color_gdk_rgba($args{'fill-color-gdk-rgba'}) if exists $args{'fill-color-gdk-rgba'};
    }
}

{
    package MockConsumerHH;
    use Moo;
    has drawing_tool => (is => 'rw', required => 1);
    with 'Shutter::Draw::Tool::Role::HoverHighlight';
}

subtest 'on_enter_notify returns TRUE' => sub {
    my $dt = MockDrawingToolHH->new;
    my $consumer = MockConsumerHH->new(drawing_tool => $dt);
    my $item = MockCanvasItem->new(_isa_type => 'GooCanvas2::CanvasRect');

    my $result = $consumer->on_enter_notify($item, undef, undef);
    is($result, 1, 'returns TRUE');
};

subtest 'on_enter_notify highlights resize handles' => sub {
    my $dt = MockDrawingToolHH->new;
    $dt->_canvas_bg_rect({'right-side' => bless({}, 'MockCanvasItem'), 'bottom-side' => bless({}, 'MockCanvasItem'), 'bottom-right-corner' => bless({}, 'MockCanvasItem')});
    my $handle = MockCanvasItem->new(_isa_type => 'GooCanvas2::CanvasRect');
    $dt->_canvas_bg_rect->{'bottom-right-corner'} = $handle;

    my $consumer = MockConsumerHH->new(drawing_tool => $dt);
    $consumer->on_enter_notify($handle, undef, undef);
    is($handle->fill_color, 'red', 'resize handle set to red');
};

subtest 'on_leave_notify restores style on resize handles' => sub {
    my $dt = MockDrawingToolHH->new;
    $dt->_style_bg('rgba(128,128,128,1)');
    my $handle = MockCanvasItem->new(_isa_type => 'GooCanvas2::CanvasRect');
    $dt->_canvas_bg_rect({'bottom-right-corner' => $handle});

    my $consumer = MockConsumerHH->new(drawing_tool => $dt);
    $consumer->on_leave_notify($handle, undef, undef);
    is($handle->fill_color_gdk_rgba, 'rgba(128,128,128,1)', 'resize handle restored to style_bg');
};

subtest 'both methods return early when busy' => sub {
    my $dt = MockDrawingToolHH->new;
    $dt->_busy(1);
    my $consumer = MockConsumerHH->new(drawing_tool => $dt);
    my $item = MockCanvasItem->new(_isa_type => 'GooCanvas2::CanvasRect');

    my $enter = $consumer->on_enter_notify($item, undef, undef);
    is($enter, 1, 'enter returns TRUE when busy');

    my $leave = $consumer->on_leave_notify($item, undef, undef);
    is($leave, 1, 'leave returns TRUE when busy');
};

subtest 'items with on_drag_creation_points are skipped' => sub {
    {
        package MockItemWithDrag;
        use Moo;
        sub isa { 1 }
        sub set { 1 }
        sub on_drag_creation_points { 1 }
    }

    my $dt = MockDrawingToolHH->new;
    my $consumer = MockConsumerHH->new(drawing_tool => $dt);
    my $item = MockItemWithDrag->new;

    my $enter = $consumer->on_enter_notify($item, undef, undef);
    is($enter, 1, 'enter returns TRUE without changes');

    my $leave = $consumer->on_leave_notify($item, undef, undef);
    is($leave, 1, 'leave returns TRUE without changes');
};

done_testing;
