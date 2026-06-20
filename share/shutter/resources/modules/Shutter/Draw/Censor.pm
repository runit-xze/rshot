package Shutter::Draw::Censor;

use v5.40;
use feature 'try'; no warnings 'experimental::try';
use Moo;

use GooCanvas2;
use Glib qw/ TRUE FALSE /;

has app       => ( is => "ro", required => 1 );
has event     => ( is => "rw", lazy     => 1 );
has copy_item => ( is => "rw", lazy     => 1 );

has points    => ( is => "rw", default => sub { [] } );
has transform => ( is => "rw" );

sub setup ($self, $event, $copy_item) {
    $self->event($event);
    $self->copy_item($copy_item);

    $self->_check_event_and_copy_item;

    my $item = $self->_create_item;

    $self->app->current_new_item($item) unless $self->copy_item;
    $self->app->items->{$item} = $item;

    # set type flag
    $self->app->items->{$item}{type} = 'censor';
    $self->app->items->{$item}{uid}  = $self->app->uid;
    $self->app->uid( $self->app->uid + 1 );

    # need at least 2 points
    push @{ $self->app->items->{$item}{'points'} }, @{ $self->points };
    $item->set( points => Shutter::Draw::Utils::points_to_canvas_points( @{ $self->app->items->{$item}{'points'} } ) );
    $item->set( transform => $self->transform ) if $self->transform;

    $self->app->setup_item_signals($item);
    $self->app->setup_item_signals_extra($item);

    return $item;
}

sub _check_event_and_copy_item ($self) {
    if ( $self->event ) {
        $self->points( [ $self->event->x, $self->event->y, $self->event->x, $self->event->y ] );
    } elsif ( $self->copy_item ) {
        my @pts;
        foreach ( @{ $self->app->items->{ $self->copy_item }{points} } ) {
            push @pts, $_ + 20;
        }
        $self->points( \@pts );
        $self->transform( $self->copy_item->get('transform') );
    }
}

sub _create_item ($self) {
    my $item = GooCanvas2::CanvasPolyline->new(
        'parent'        => $self->app->canvas->get_root_item,
        'close-path'    => FALSE,
        'stroke-pixbuf' => $self->app->stipple_pixbuf,
        'line-width'    => 14,
        'line-cap'      => 'CAIRO_LINE_CAP_ROUND',
        'line-join'     => 'CAIRO_LINE_JOIN_ROUND',
    );
    return $item;
}

1;
