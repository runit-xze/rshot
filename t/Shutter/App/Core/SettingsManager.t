## no critic (Subroutines::RequireFinalReturn)
use Test2::V0;
use Shutter::App::Core::SettingsManager;
use File::Temp qw/tempdir/;
use lib 'share/shutter/resources/modules';
use XML::Simple;
use Data::Dumper;

# Mock SimpleDialogs
package Shutter::App::SimpleDialogs;
sub new               { bless {}, shift }
sub dlg_error_message { }

package main;

my $temp_dir = tempdir(CLEANUP => 1);
$ENV{HOME} = $temp_dir;

# Simple mock classes
{

	package MockLocale;
	sub new { bless {}, shift }
	sub get { shift; shift }

	package MockHelper;
	sub new         { my ($class, $fe) = @_; bless {fe => $fe}, $class }
	sub file_exists { shift->{fe} }

	package MockCommon;
	sub new                  { my ($class, $fe) = @_; bless {fe => $fe}, $class }
	sub get_gettext          { MockLocale->new }
	sub get_helper_functions { MockHelper->new(shift->{fe}) }
	sub get_mainwindow       { undef }
	sub get_version          { '0.0.1' }
	sub get_rev              { 'rev1' }
}

# Test saving/loading
mkdir "$temp_dir/.shutter";
my $sm_io = Shutter::App::Core::SettingsManager->new(_common => MockCommon->new(1));
$sm_io->set_setting('general', 'foo', 'bar');
ok($sm_io->save_settings(), 'Settings saved successfully');

my $sm2 = Shutter::App::Core::SettingsManager->new(_common => MockCommon->new(1));
$sm2->load_settings();
diag "Internal structure: " . Dumper($sm2->{_settings});

is($sm2->get_setting('general', 'foo'), 'bar', 'Setting loaded correctly from file');

done_testing;
