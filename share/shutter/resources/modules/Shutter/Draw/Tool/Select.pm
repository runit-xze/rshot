package Shutter::Draw::Tool::Select;
use Moo;
use utf8;
use v5.40;
use Glib qw/TRUE FALSE/;
with 'Shutter::Draw::Tool::Base';
has drawing_tool => (is => 'ro', required => 1);

1;
