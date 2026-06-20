package Shutter::Draw::Arrow;

use v5.40;
use feature 'try'; no warnings 'experimental::try';
use Moo;

use GooCanvas2;
use Glib qw/ TRUE FALSE /;

has app         => ( is => "ro", required => 1 );
has event       => ( is => "rw", lazy     => 1 );
has copy_item   => ( is => "rw", lazy     => 1 );
has end_arrow   => ( is => "rw" );
has start_arrow => ( is => "rw" );

has X            => ( is => "rw", default => sub {0} );
has Y            => ( is => "rw", default => sub {0} );
has width        => ( is => "rw", default => sub {0} );
has height       => ( is => "rw", default => sub {0} );
has mirrored_w   => ( is => "rw", default => sub {0} );
has mirrored_h   => ( is => "rw", default => sub {0} );

has arrow_width      => ( is => "rw", default => sub {4} );
has arrow_length     => ( is => "rw", default => sub {5} );
has arrow_tip_length => ( is => "rw", default => sub {4} );

has stroke_color => ( is => "rw", lazy => 1, default => sub { shift->app->stroke_color } );
has line_width   => ( is => "rw", lazy => 1, default => sub { shift->app->line_width } );

sub setup ($self, $event, $copy_item, $end_arrow, $start_arrow) {
    $self->event($event);
    $self->copy_item($copy_item);
    $self->end_arrow($end_arrow);
    $self->start_arrow($start_arrow);

    $self->_check_event_and_copy_item;

    my $item = $self->_create_item;

    $self->app->current_new_item($item) unless $self->copy_item;
    $self->app->items->{$item} = $item;

    $self->app->items->{$item}{line} = GooCanvas2::CanvasPolyline->new(
        parent     => $self->app->canvas->get_root_item,
        close_path => FALSE,
        points     => Shutter::Draw::Utils::points_to_canvas_points(
            $item->get('x'),
            $item->get('y'),
            $item->get('x') + $item->get('width'),
            $item->get('y') + $item->get('height'),
        ),
        'stroke-color-gdk-rgba' => $self->stroke_color,
        'line-width'            => $self->line_width,
        'line-cap'              => 'CAIRO_LINE_CAP_ROUND',
        'line-join'             => 'CAIRO_LINE_JOIN_ROUND',
        'end-arrow'             => $self->end_arrow,
        'start-arrow'           => $self->start_arrow,
        'arrow-length'          => $self->arrow_length,
        'arrow-width'           => $self->arrow_width,
        'arrow-tip-length'      => $self->arrow_tip_length,
        'visibility'            => 'hidden',
    );

    if ( defined $self->end_arrow || defined $self->start_arrow ) {
        # save arrow specific properties
        $self->app->items->{$item}{end_arrow}        = $self->app->items->{$item}{line}->get('end-arrow');
        $self->app->items->{$item}{start_arrow}      = $self->app->items->{$item}{line}->get('start-arrow');
        $self->app->items->{$item}{arrow_width}      = $self->app->items->{$item}{line}->get('arrow-width');
        $self->app->items->{$item}{arrow_length}     = $self->app->items->{$item}{line}->get('arrow-length');
        $self->app->items->{$item}{arrow_tip_length} = $self->app->items->{$item}{line}->get('arrow-tip-length');
    }

    # set type flag
    $self->app->items->{$item}{type} = 'line';
    $self->app->items->{$item}{uid}  = $self->app->uid;
    $self->app->uid( $self->app->uid + 1 );

    $self->app->items->{$item}{mirrored_w} = $self->mirrored_w;
    $self->app->items->{$item}{mirrored_h} = $self->mirrored_h;

    $self->app->items->{$item}{stroke_color} = $self->app->stroke_color;

    # create rectangles
    $self->app->handle_rects( 'create', $item );
    if ( $self->copy_item ) {
        $self->app->handle_embedded( 'update', $item );
        $self->app->handle_rects( 'hide', $item );
    }

    $self->app->setup_item_signals( $self->app->items->{$item}{line} );
    $self->app->setup_item_signals_extra( $self->app->items->{$item}{line} );

    $self->app->setup_item_signals($item);
    $self->app->setup_item_signals_extra($item);

    return $item;
}

sub _check_event_and_copy_item ($self) {
    if ( $self->event ) {
        $self->X( $self->event->x );
        $self->Y( $self->event->y );
    } elsif ( $self->copy_item ) {
        $self->X( $self->copy_item->get('x') + 20 );
        $self->Y( $self->copy_item->get('y') + 20 );
        $self->width( $self->copy_item->get('width') );
        $self->height( $self->copy_item->get('height') );

        $self->stroke_color( $self->app->items->{ $self->copy_item }{stroke_color} );
        $self->line_width( $self->app->items->{ $self->copy_item }{line}->get('line-width') );
        $self->mirrored_w( $self->app->items->{ $self->copy_item }{mirrored_w} );
        $self->mirrored_h( $self->app->items->{ $self->copy_item }{mirrored_h} );

        # arrow specific properties
        $self->end_arrow( $self->app->items->{ $self->copy_item }{end_arrow} );
        $self->start_arrow( $self->app->items->{ $self->copy_item }{start_arrow} );
        $self->arrow_width( $self->app->items->{ $self->copy_item }{arrow_width} );
        $self->arrow_length( $self->app->items->{ $self->copy_item }{arrow_length} );
        $self->arrow_tip_length( $self->app->items->{ $self->copy_item }{arrow_tip_length} );
    }
}

sub _create_item ($self) {
    my $item = GooCanvas2::CanvasRect->new(
        'parent'          => $self->app->canvas->get_root_item,
        'x'               => $self->X,
        'y'               => $self->Y,
        'width'           => $self->width,
        'height'          => $self->height,
        'fill-color-rgba' => 0,
        'line-dash'       => GooCanvas2::CanvasLineDash->newv( [ 5, 5 ] ),
        'line-width'      => 1,
        'stroke-color'    => 'gray',
    );
    return $item;
}

1;
