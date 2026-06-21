use strict;
use warnings;

{
    package MockCanvasRect;
    sub new { bless {}, shift }
    sub isa {
        my ($self, $type) = @_;
        return 1 if $type eq 'GooCanvas2::CanvasRect';
        return $self->UNIVERSAL::isa($type);
    }
}

my $item = MockCanvasRect->new;
if ($item->isa('GooCanvas2::CanvasRect')) {
    print "Mock works!\n";
}
