package Shutter::App::Core::WidgetStub;

use utf8;
use v5.40;
use Moo;

sub get_active      { return $_[0]->{val} }
sub get_value       { return $_[0]->{val} }
sub get_text        { return $_[0]->{val} }
sub get_active_text { return $_[0]->{val} }

sub _widget_stub ($val) {
	return bless {val => $val}, 'Shutter::App::Core::WidgetStub';
}

1;
