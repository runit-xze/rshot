package Shutter::Draw::IOManager;

use v5.40;
use utf8;
use Moo;
use Glib qw/TRUE FALSE/;

use Shutter::Draw::IO::SaveExport;
use Shutter::Draw::IO::LoadImport;

has drawing_tool => (
    is => 'ro',
    required => 1,
);

with qw(
    Shutter::Draw::IO::SaveExport
    Shutter::Draw::IO::LoadImport
);

1;
