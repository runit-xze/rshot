package Shutter::Draw::Rectangle;

use v5.40;
use feature 'try'; no warnings 'experimental::try';
use Moo;

use GooCanvas2;
use Glib qw/ TRUE FALSE /;

use constant POSITION_INDENT => 20;

has app       => ( is => "ro", required => 1 );
has event     => ( is => "rw", lazy     => 1 );
has copy_item => ( is => "rw", lazy     => 1 );

has X         => ( is => "rw", default  => sub {0} );
has Y         => ( is => "rw", default  => sub {0} );
has width     => ( is => "rw", default  => sub {0} );
has height    => ( is => "rw", default  => sub {0} );

has stroke_color => ( is => "rw", lazy => 1, default => sub { shift->app->stroke_color } );
has fill_color   => ( is => "rw", lazy => 1, default => sub { shift->app->fill_color } );
has line_width   => ( is => "rw", lazy => 1, default => sub { shift->app->line_width } );

sub setup ($self, $event, $copy_item) {

    $self->event($event);
    $self->copy_item($copy_item);

    $self->_check_event_and_copy_item;

    my $item = $self->_create_item;

    $self->app->current_new_item($item) unless $self->copy_item;
    $self->app->items->{$item} = $item;

    # set type flag
    $self->app->items->{$item}{type} = 'rectangle';
    $self->app->items->{$item}{uid}  = $self->app->uid;
    $self->app->uid($self->app->uid + 1);

    $self->app->items->{$item}{fill_color}   = $self->fill_color;
    $self->app->items->{$item}{stroke_color} = $self->stroke_color;

    # create rectangles
    $self->app->handle_rects( 'create', $item );

    $self->app->setup_item_signals($item);
    $self->app->setup_item_signals_extra($item);

    return $item;
}

sub _check_event_and_copy_item ($self) {
    if ( $self->event ) {
        $self->X( $self->event->x );
        $self->Y( $self->event->y );
    } elsif ( $self->copy_item ) {
        $self->X( $self->copy_item->get('x') + POSITION_INDENT );
        $self->Y( $self->copy_item->get('y') + POSITION_INDENT );

        $self->width( $self->copy_item->get('width') );
        $self->height( $self->copy_item->get('height') );

        $self->stroke_color( $self->app->items->{ $self->copy_item }->{stroke_color} );
        $self->fill_color( $self->app->items->{ $self->copy_item }->{fill_color} );
        $self->line_width( $self->copy_item->get('line-width') );
    }
}

sub _create_item ($self) {
    my $item = GooCanvas2::CanvasRect->new(
        'parent'                => $self->app->canvas->get_root_item,
        'x'                     => $self->X,
        'y'                     => $self->Y,
        'width'                 => $self->width,
        'height'                => $self->height,
        'fill-color-gdk-rgba'   => $self->fill_color,
        'stroke-color-gdk-rgba' => $self->stroke_color,
        'line-width'            => $self->line_width,
    );
    return $item;
}

1;
