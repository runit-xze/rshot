package Shutter::Draw::IOManager;

use v5.40;
use utf8;
use Moo;

use Shutter::Draw::IO::SaveExport;
use Shutter::Draw::IO::LoadImport;

with qw(
    Shutter::Draw::IO::SaveExport
    Shutter::Draw::IO::LoadImport
);

has drawing_tool => (
    is => 'ro',
    required => 1,
);

1;
