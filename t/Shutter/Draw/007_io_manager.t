## no critic (Modules::ProhibitMultiplePackages, Subroutines::RequireFinalReturn, Modules::RequireExplicitPackage, Modules::RequireFilenameMatchesPackage, Modules::RequireEndWithOne, NamingConventions::ProhibitAmbiguousNames, Subroutines::ProhibitBuiltinHomonyms, ValuesAndExpressions::ProhibitConstantPragma, ErrorHandling::RequireCheckingReturnValueOfEval, Subroutines::RequireArgUnpacking, TestingAndDebugging::RequireTestLabels)
use strict;
use warnings;

use lib 't/lib';
use Test::Shutter::Mock;
use Glib qw/TRUE FALSE/;

use Test2::V0;
use Test2::Mock;

ok(eval { require Shutter::Draw::IOManager; 1 }, "Loaded IOManager") or diag $@;

{

	package MockDrawingToolIO;
	use Moo;

	has _d             => (is => 'rw', default => sub { bless {}, 'MockGettextIO' });
	has drawing_window => (is => 'rw', default => sub { Gtk3::Window->new('toplevel') });

	sub gettext { shift->_d }

	has sc         => (is => 'rw', default => sub { bless {}, 'MockSC' });
	has _sc        => (is => 'rw', default => sub { bless {}, 'MockSC' });
	has filename   => (is => 'rw', default => sub { '/tmp/test.png' });
	has is_unsaved => (is => 'rw', default => sub { 1 });
	has mimetype   => (is => 'rw', default => sub { 'image/png' });
	has filetype   => (is => 'rw', default => sub { 'png' });
	has shf        => (is => 'rw', default => sub { bless {}, 'MockSHF' });
	has dialogs    => (is => 'rw', default => sub { bless {}, 'MockDialogs' });
	has lp_ne      => (is => 'rw', default => sub { bless {}, 'MockPixbufLoader' });
	has lp         => (is => 'rw', default => sub { bless {}, 'MockPixbufLoader' });

	sub deactivate_all  { 1 }
	sub handle_bg_rects { 1 }

	has canvas_bg_rect => (is => 'rw', default => sub { bless {fill_color => Gtk3::Gdk::RGBA->new(1, 1, 1, 1)}, 'MockCanvasRectIO' });
	has canvas => (is => 'rw', default => sub { bless {}, 'MockCanvas' });

	sub current_pixbuf                  { 1 }
	sub current_pixbuf_filename         { 1 }
	sub check_valid_mime_type           { 1 }
	sub create_image                    { 1 }
	sub abort_current_mode              { 1 }
	sub current_new_item                { 1 }
	sub import_hash                     { return {} }
	sub _import_hash                    { return {} }
	sub _filename                       { return 'test' }
	sub _shf                            { return bless {}, 'MockSHF' }
	sub dicons                          { '/tmp' }
	sub icons                           { '/tmp' }
	sub change_cursor_to_current_pixbuf { 1 }
	sub gen_thumbnail_on_idle           { 1 }
}

{

	package MockGettextIO;
	sub get { $_[1] }
}
{

	package MockSC;
	sub shutter_root { '/tmp' }
	sub rusf { undef }
}
{

	package MockSHF;
	sub utf8_decode { $_[1] }
	sub nsort       { sort @_ }
	sub file_exists { 0 }
}
{

	package MockDialogs;
	sub dlg_warning_message { 40 }
}
{

	package MockPixbufLoader;
	sub load { 1 }
}
{

	package MockCanvasRectIO;
	sub set        { 1 }
	sub get        { 100 }
	sub get_bounds { 1 }
}
{

	package MockCanvas;
	sub render { 1 }
}
{

	package MockSurface;
	sub write_to_png_stream { my ($self, $cb) = @_; $cb->(undef, 'mockdata'); 1 }
}
{

	package MockLoader;
	sub write      { 1 }
	sub close      { 1 }
	sub get_pixbuf { 'mock_pixbuf' }
}

{

	package Shutter::App::Directories;
	sub get_home_dir { '/tmp' }
}
{

	package Shutter::App::HelperFunctions;
	sub new           { bless {}, shift }
	sub folder_exists { 1 }
	sub file_exists   { 0 }
}
{

	package Shutter::Pixbuf::Save;
	sub new                 { bless {}, shift }
	sub save_pixbuf_to_file { 1 }
}

subtest 'IOManager creation' => sub {
	my $dt = MockDrawingToolIO->new;
	$dt->{_sc} = $dt->sc;
	my $iom = Shutter::Draw::IOManager->new(drawing_tool => $dt);

	ok(defined $iom, 'IOManager instantiated');
};

subtest 'save to memory' => sub {
	my $dt = MockDrawingToolIO->new;
	$dt->{_sc} = $dt->sc;
	my $iom = Shutter::Draw::IOManager->new(drawing_tool => $dt);

	my $surface_mock = mock 'Cairo::ImageSurface' => (
		override => [
			create => sub { bless {}, 'MockSurface' },
		]);
	my $context_mock = mock 'Cairo::Context' => (
		override => [
			create => sub { bless {}, 'MockContext' },
		]);
	my $loader_mock = mock 'Gtk3::Gdk::PixbufLoader' => (
		override => [
			new => sub { bless {}, 'MockLoader' },
		]);

	my $res = $iom->save(1, '/tmp/test.png', 'png');
	is($res, 'mock_pixbuf', 'save to memory returns pixbuf');
};

subtest 'save to file (png)' => sub {
	my $dt  = MockDrawingToolIO->new;
	my $iom = Shutter::Draw::IOManager->new(drawing_tool => $dt);

	my $surface_mock = mock 'Cairo::ImageSurface' => (
		override => [
			create => sub { bless {}, 'MockSurface' },
		]);
	my $context_mock = mock 'Cairo::Context' => (
		override => [
			create => sub { bless {}, 'MockContext' },
		]);
	my $loader_mock = mock 'Gtk3::Gdk::PixbufLoader' => (
		override => [
			new => sub { bless {}, 'MockLoader' },
		]);
	my $dialog_mock = mock 'Gtk3::MessageDialog' => (
		override => [
			run => sub { 20 },
		]);
	my $pixbuf_save_mock = mock 'Shutter::Pixbuf::Save' => (
		override => [
			new                 => sub { bless {}, shift },
			save_pixbuf_to_file => sub { 1 },
		]);

	my $res = $iom->save(0, '/tmp/test.png', 'png');
	is($res, 1, 'save to file returns success');
};

subtest 'import_from_filesystem mock' => sub {
	my $dt  = MockDrawingToolIO->new;
	my $iom = Shutter::Draw::IOManager->new(drawing_tool => $dt);

	my $button_mock = bless {}, 'MockButton';
	my $res         = $iom->import_from_filesystem($button_mock);
	ok($res->isa('Gtk3::Menu'), 'Returns a Gtk3::Menu');
};

{

	package MockButton;
	sub show_all { 1 }
}

done_testing;
