package Shutter::Draw::Blur;

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

sub setup ($self, $event, $copy_item) {
    $self->event($event);
    $self->copy_item($copy_item);

    $self->_check_event_and_copy_item;

    my $item = $self->_create_item;

    $self->app->current_new_item($item) unless $self->copy_item;
    $self->app->items->{$item} = $item;

    # blank pixbuf
    my $blank = Gtk3::Gdk::Pixbuf->new('rgb', TRUE, 8, 2, 2);
    $blank->fill(0x00000000);

    $self->app->items->{$item}{pixelize} = GooCanvas2::CanvasImage->new(
        parent => $self->app->canvas->get_root_item,
        pixbuf => $blank,
        x      => $item->get('x'),
        y      => $item->get('y'),
        width  => 2,
        height => 2,
    );

    # set type flag
    $self->app->items->{$item}{type} = 'pixelize';
    $self->app->items->{$item}{uid}  = $self->app->uid;
    $self->app->uid( $self->app->uid + 1 );

    # create rectangles
    $self->app->handle_rects('create', $item);

    if ( $self->copy_item ) {
        $self->app->items->{$item}{pixelize}->set(
            'x'      => int $item->get('x'),
            'y'      => int $item->get('y'),
            'width'  => $item->get('width'),
            'height' => $item->get('height'),
            'pixbuf' => $self->app->get_pixelated_pixbuf_from_canvas($item),
        );

        $self->app->handle_embedded('update', $item, undef, undef, TRUE);
    }

    $self->app->setup_item_signals($self->app->items->{$item}{pixelize});
    $self->app->setup_item_signals_extra($self->app->items->{$item}{pixelize});

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
