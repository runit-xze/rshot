use strict;
use warnings;

use Test2::V0;
use Test2::Mock;

use constant BUTTON1_MASK => 256;
use constant BUTTON2_MASK => 512;

{
    package MockDrawingToolAS;
    use Moo;

    has _current_mode_descr => (is => 'rw', default => '');
    has _autoscroll => (is => 'rw', default => 1);
    has _canvas => (is => 'rw');
    has _scrolled_window => (is => 'rw');
}

{
    package MockCanvasAS;
    use Moo;

    has scroll_x => (is => 'rw', default => 0);
    has scroll_y => (is => 'rw', default => 0);

    sub get_scale { 1 }
    sub get_window { bless {}, 'MockWindowAS' }
    sub scroll_to {
        my ($self, $x, $y) = @_;
        $self->scroll_x($x);
        $self->scroll_y($y);
    }
}

{ package MockWindowAS; sub get_geometry { (0, 0, 500, 400, 24) } }

{
    package MockScrolledWindowAS;
    use Moo;

    sub get_hadjustment { bless {}, 'MockAdjustmentAS' }
    sub get_vadjustment { bless {}, 'MockAdjustmentAS' }
}

{ package MockAdjustmentAS; sub get_value { 0 } }

{
    package MockEventAS;
    use Moo;
    has state => (is => 'rw', default => 0);
    has x => (is => 'rw', default => 0);
    has y => (is => 'rw', default => 0);
}

{
    package MockConsumerAS;
    use Moo;
    has drawing_tool => (is => 'rw', required => 1);
    with 'Shutter::Draw::Tool::Role::Autoscroll';
}

subtest 'returns early when mode is censor' => sub {
    my $dt = MockDrawingToolAS->new;
    $dt->_current_mode_descr('censor');
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 10, y => 10);

    my $result = $consumer->_handle_autoscroll(undef, $ev);
    is($result, undef, 'returns undef');
};

subtest 'returns early when autoscroll is false' => sub {
    my $dt = MockDrawingToolAS->new;
    $dt->_autoscroll(0);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 10, y => 10);

    my $result = $consumer->_handle_autoscroll(undef, $ev);
    is($result, undef, 'returns undef');
};

subtest 'does not scroll when inside bounds' => sub {
    my $dt = MockDrawingToolAS->new;
    my $canvas = MockCanvasAS->new;
    $dt->_canvas($canvas);
    $dt->_scrolled_window(MockScrolledWindowAS->new);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => 0, x => 10, y => 10);

    $consumer->_handle_autoscroll(undef, $ev);
    is($canvas->scroll_x, 0, 'x unchanged');
    is($canvas->scroll_y, 0, 'y unchanged');
};

subtest 'scrolls right when near right edge' => sub {
    my $dt = MockDrawingToolAS->new;
    my $canvas = MockCanvasAS->new;
    $dt->_canvas($canvas);
    $dt->_scrolled_window(MockScrolledWindowAS->new);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 450, y => 200);

    $consumer->_handle_autoscroll(undef, $ev);
    is($canvas->scroll_x, 10, 'scrolled right by 10');
    is($canvas->scroll_y, 0, 'y unchanged');
};

subtest 'scrolls down when near bottom edge' => sub {
    my $dt = MockDrawingToolAS->new;
    my $canvas = MockCanvasAS->new;
    $dt->_canvas($canvas);
    $dt->_scrolled_window(MockScrolledWindowAS->new);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 200, y => 350);

    $consumer->_handle_autoscroll(undef, $ev);
    is($canvas->scroll_x, 0, 'x unchanged');
    is($canvas->scroll_y, 10, 'scrolled down by 10');
};

subtest 'scrolls diagonally when near bottom-right corner' => sub {
    my $dt = MockDrawingToolAS->new;
    my $canvas = MockCanvasAS->new;
    $dt->_canvas($canvas);
    $dt->_scrolled_window(MockScrolledWindowAS->new);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 450, y => 350);

    $consumer->_handle_autoscroll(undef, $ev);
    is($canvas->scroll_x, 10, 'scrolled right by 10');
    is($canvas->scroll_y, 10, 'scrolled down by 10');
};

subtest 'scrolls left when near left edge' => sub {
    my $dt = MockDrawingToolAS->new;
    my $canvas = MockCanvasAS->new;
    $dt->_canvas($canvas);
    $dt->_scrolled_window(MockScrolledWindowAS->new);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 50, y => 200);

    $consumer->_handle_autoscroll(undef, $ev);
    is($canvas->scroll_x, -10, 'scrolled left by 10');
    is($canvas->scroll_y, 0, 'y unchanged');
};

subtest 'scrolls up when near top edge' => sub {
    my $dt = MockDrawingToolAS->new;
    my $canvas = MockCanvasAS->new;
    $dt->_canvas($canvas);
    $dt->_scrolled_window(MockScrolledWindowAS->new);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 200, y => 50);

    $consumer->_handle_autoscroll(undef, $ev);
    is($canvas->scroll_x, 0, 'x unchanged');
    is($canvas->scroll_y, -10, 'scrolled up by 10');
};

subtest 'scrolls diagonally when near top-left corner' => sub {
    my $dt = MockDrawingToolAS->new;
    my $canvas = MockCanvasAS->new;
    $dt->_canvas($canvas);
    $dt->_scrolled_window(MockScrolledWindowAS->new);
    my $consumer = MockConsumerAS->new(drawing_tool => $dt);
    my $ev = MockEventAS->new(state => BUTTON1_MASK, x => 50, y => 50);

    $consumer->_handle_autoscroll(undef, $ev);
    is($canvas->scroll_x, -10, 'scrolled left by 10');
    is($canvas->scroll_y, -10, 'scrolled up by 10');
};

done_testing;
