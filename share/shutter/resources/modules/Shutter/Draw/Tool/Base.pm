package Shutter::Draw::Tool::Base;

use Moo::Role;
use utf8;
use v5.40;

requires 'draw';
requires 'on_click';
requires 'on_drag';

requires 'drawing_tool';

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Base - Base role for drawing tools

=head1 DESCRIPTION

Defines the interface required for all drawing tools in Shutter.
