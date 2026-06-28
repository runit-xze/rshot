package Shutter::App::Core::FileSystemAPI;

use utf8;
use v5.40;
use Moo;
use Path::Tiny;
use File::Glob qw(bsd_glob);

sub slurp_utf8 {
    my ($self, $path) = @_;
    return path($path)->slurp_utf8;
}

sub lines_utf8 {
    my ($self, $path, $args) = @_;
    return path($path)->lines_utf8($args);
}

sub spew_utf8 {
    my ($self, $path, $content) = @_;
    return path($path)->spew_utf8($content);
}

sub remove {
    my ($self, $path) = @_;
    return CORE::unlink($path);
}

sub make_dir {
    my ($self, $path) = @_;
    return CORE::mkdir($path);
}

sub path_exists {
    my ($self, $path) = @_;
    return -e $path;
}

sub is_directory {
    my ($self, $path) = @_;
    return -d $path;
}

sub is_regular_file {
    my ($self, $path) = @_;
    return -f $path;
}

sub is_path_readable {
    my ($self, $path) = @_;
    return -r $path;
}

sub get_glob {
    my ($self, $pattern) = @_;
    return bsd_glob($pattern);
}

1;
