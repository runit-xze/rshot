package Shutter::Draw::Text;

use v5.40;
use feature 'try'; no warnings 'experimental::try';
use Moo;

use GooCanvas2;
use Glib qw/ TRUE FALSE /;

has app       => ( is => "ro", required => 1 );
has event     => ( is => "rw", lazy     => 1 );
has copy_item => ( is => "rw", lazy     => 1 );

has X         => ( is => "rw", default  => sub {0} );
has Y         => ( is => "rw", default  => sub {0} );
has width     => ( is => "rw", default  => sub {0} );
has height    => ( is => "rw", default  => sub {0} );

has stroke_color => ( is => "rw", lazy => 1, default => sub { shift->app->stroke_color } );
has line_width   => ( is => "rw", lazy => 1, default => sub { shift->app->line_width } );
has text_str     => ( is => "rw", lazy => 1, default => sub { shift->app->gettext->get('New text...') } );

sub setup ($self, $event, $copy_item) {
    $self->event($event);
    $self->copy_item($copy_item);

    $self->_check_event_and_copy_item;

    my $item = $self->_create_item;

    $self->app->current_new_item($item) unless $self->copy_item;
    $self->app->items->{$item} = $item;

    $self->app->items->{$item}{text} = GooCanvas2::CanvasText->new(
        parent                => $self->app->canvas->get_root_item,
        text                  => "<span font_desc='" . $self->app->font . "' >" . $self->text_str . "</span>",
        x                     => $item->get('x'),
        y                     => $item->get('y'),
        width                 => -1,
        anchor                => 'nw',
        'use-markup'          => TRUE,
        'fill-color-gdk-rgba' => $self->stroke_color,
        'line-width'          => $self->line_width,
    );

    # adjust parent rectangle
    my $tb = $self->app->items->{$item}{text}->get_bounds;
    my $w  = abs( $tb->x1 - $tb->x2 );
    my $h  = abs( $tb->y1 - $tb->y2 );

    if ( $self->copy_item ) {
        $self->app->items->{$item}->set(
            'x'          => $self->app->items->{$item}->get('x') + 20,
            'y'          => $self->app->items->{$item}->get('y') + 20,
            'width'      => $w,
            'height'     => $h,
            'visibility' => 'hidden',
        );
    } else {
        $self->app->items->{$item}->set(
            'x'          => $self->event->x - $w,
            'y'          => $self->event->y - $h,
            'width'      => $w,
            'height'     => $h,
            'visibility' => 'hidden',
        );
    }

    # update text
    $self->app->handle_embedded( 'hide', $item );

    # set type flag
    $self->app->items->{$item}{type} = 'text';
    $self->app->items->{$item}{uid}  = $self->app->uid;
    $self->app->uid( $self->app->uid + 1 );

    $self->app->items->{$item}{stroke_color} = $self->app->stroke_color;

    # create rectangles
    $self->app->handle_rects( 'create', $item );
    if ( $self->copy_item ) {
        $self->app->handle_embedded( 'update', $item );
        $self->app->handle_rects( 'hide', $item );
    }

    $self->app->setup_item_signals( $self->app->items->{$item}{text} );
    $self->app->setup_item_signals_extra( $self->app->items->{$item}{text} );

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
        $self->text_str( $self->app->items->{ $self->copy_item }{text}->get('text') );
        $self->line_width( $self->app->items->{ $self->copy_item }{text}->get('line-width') );
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
