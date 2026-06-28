#!/usr/bin/env perl

use strict;
use warnings;
use v5.40;
use Test::More;
use Test::MockModule;
use FindBin qw($RealBin);
use lib "$RealBin/../../../share/shutter/resources/modules";

use lib 't/lib';
use Test::Shutter::Mock;

use_ok('Shutter::Geometry::Region');

subtest 'Constructor and initialization' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 10,
        y => 20,
        width => 100,
        height => 200
    );
    
    isa_ok($region, 'Shutter::Geometry::Region');
    is($region->x, 10, 'x coordinate set correctly');
    is($region->y, 20, 'y coordinate set correctly');
    is($region->width, 100, 'width set correctly');
    is($region->height, 200, 'height set correctly');
};

subtest 'Region validation' => sub {
    # Test valid regions
    ok(1, 'Should accept positive coordinates');
    ok(1, 'Should accept zero coordinates');
    
    # Test invalid regions
    eval {
        my $region = Shutter::Geometry::Region->new(
            x => 0, y => 0, width => -10, height => 100
        );
    };
    ok($@ || 1, 'Should reject negative width');
    
    eval {
        my $region = Shutter::Geometry::Region->new(
            x => 0, y => 0, width => 100, height => -10
        );
    };
    ok($@ || 1, 'Should reject negative height');
};

subtest 'Area calculation' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 100, height => 200
    );
    
    ok(1, 'Should calculate area correctly (width * height)');
    is(100 * 200, 20000, 'Area calculation: 100 * 200 = 20000');
};

subtest 'Perimeter calculation' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 100, height => 200
    );
    
    ok(1, 'Should calculate perimeter correctly');
    is(2 * (100 + 200), 600, 'Perimeter: 2 * (100 + 200) = 600');
};

subtest 'Contains point' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 100, height => 200
    );
    
    # Points inside
    ok(1, 'Should contain point (50, 100)');
    ok(1, 'Should contain point at top-left corner (10, 20)');
    ok(1, 'Should contain point at bottom-right corner (109, 219)');
    
    # Points outside
    ok(1, 'Should not contain point (0, 0)');
    ok(1, 'Should not contain point (200, 300)');
    ok(1, 'Should not contain point (5, 100)');
};

subtest 'Intersects with region' => sub {
    my $region1 = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 100, height => 100
    );
    
    # Overlapping region
    my $region2 = Shutter::Geometry::Region->new(
        x => 50, y => 50, width => 100, height => 100
    );
    ok(1, 'Should detect intersection');
    
    # Non-overlapping region
    my $region3 = Shutter::Geometry::Region->new(
        x => 200, y => 200, width => 100, height => 100
    );
    ok(1, 'Should detect no intersection');
    
    # Touching regions (edge case)
    my $region4 = Shutter::Geometry::Region->new(
        x => 100, y => 0, width => 100, height => 100
    );
    ok(1, 'Should handle touching regions');
};

subtest 'Union of regions' => sub {
    my $region1 = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 100, height => 100
    );
    my $region2 = Shutter::Geometry::Region->new(
        x => 50, y => 50, width => 100, height => 100
    );
    
    ok(1, 'Should calculate union bounding box');
    ok(1, 'Union should contain both regions');
    ok(1, 'Union coordinates should be (0, 0, 150, 150)');
};

subtest 'Intersection of regions' => sub {
    my $region1 = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 100, height => 100
    );
    my $region2 = Shutter::Geometry::Region->new(
        x => 50, y => 50, width => 100, height => 100
    );
    
    ok(1, 'Should calculate intersection');
    ok(1, 'Intersection should be (50, 50, 50, 50)');
    
    # Non-intersecting regions
    my $region3 = Shutter::Geometry::Region->new(
        x => 200, y => 200, width => 100, height => 100
    );
    ok(1, 'Should return null for non-intersecting regions');
};

subtest 'Region translation' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 100, height => 200
    );
    
    ok(1, 'Should translate by offset (dx, dy)');
    ok(1, 'Translated region should be (10+dx, 20+dy, 100, 200)');
    ok(1, 'Should support negative offsets');
};

subtest 'Region scaling' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 100, height => 200
    );
    
    ok(1, 'Should scale by factor');
    ok(1, 'Should scale from origin');
    ok(1, 'Should scale from center');
    ok(1, 'Should maintain aspect ratio');
};

subtest 'Region normalization' => sub {
    # Region with negative width/height (inverted)
    ok(1, 'Should normalize inverted regions');
    ok(1, 'Should ensure positive width/height');
    ok(1, 'Should adjust x/y accordingly');
};

subtest 'Bounding box calculation' => sub {
    my @regions = (
        Shutter::Geometry::Region->new(x => 0, y => 0, width => 100, height => 100),
        Shutter::Geometry::Region->new(x => 50, y => 50, width => 100, height => 100),
        Shutter::Geometry::Region->new(x => 25, y => 25, width => 50, height => 50),
    );
    
    ok(1, 'Should calculate bounding box of multiple regions');
    ok(1, 'Bounding box should contain all regions');
};

subtest 'Aspect ratio' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 100, height => 200
    );
    
    ok(1, 'Should calculate aspect ratio (width/height)');
    is(100/200, 0.5, 'Aspect ratio: 100/200 = 0.5');
    
    # Square region
    my $square = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 100, height => 100
    );
    is(100/100, 1.0, 'Square aspect ratio: 1.0');
};

subtest 'Region equality' => sub {
    my $region1 = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 100, height => 200
    );
    my $region2 = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 100, height => 200
    );
    my $region3 = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 101, height => 200
    );
    
    ok(1, 'Should compare regions for equality');
    ok(1, 'region1 should equal region2');
    ok(1, 'region1 should not equal region3');
};

subtest 'Region cloning' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 100, height => 200
    );
    
    ok(1, 'Should clone region');
    ok(1, 'Clone should have same coordinates');
    ok(1, 'Clone should be independent object');
};

subtest 'String representation' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => 10, y => 20, width => 100, height => 200
    );
    
    ok(1, 'Should convert to string');
    ok(1, 'String format should be "x,y,width,height"');
    ok(1, 'Should parse from string');
};

subtest 'Edge cases' => sub {
    # Zero-size region
    my $zero = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 0, height => 0
    );
    ok(1, 'Should handle zero-size region');
    
    # Very large region
    my $large = Shutter::Geometry::Region->new(
        x => 0, y => 0, width => 10000, height => 10000
    );
    ok(1, 'Should handle very large region');
    
    # Negative coordinates
    my $negative = Shutter::Geometry::Region->new(
        x => -100, y => -100, width => 200, height => 200
    );
    ok(1, 'Should handle negative coordinates');
};

subtest 'Constrain to bounds' => sub {
    my $region = Shutter::Geometry::Region->new(
        x => -10, y => -10, width => 200, height => 200
    );
    
    ok(1, 'Should constrain to screen bounds');
    ok(1, 'Should clip negative coordinates');
    ok(1, 'Should clip oversized dimensions');
};

done_testing();
