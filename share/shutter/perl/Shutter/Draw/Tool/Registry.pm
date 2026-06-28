package Shutter::Draw::Tool::Registry;

use Moo;
use utf8;
use v5.40;

has _tools => (is => 'ro', default => sub { {} });

sub register_tool ($self, $name, $tool_class) {
	$self->_tools->{$name} = $tool_class;
	return;
}

sub get_tool ($self, $name) {
	return $self->_tools->{$name};
}

1;

__END__

=head1 NAME

Shutter::Draw::Tool::Registry - Registry for drawing tools

=head1 DESCRIPTION

Maintains a mapping of tool names to their respective classes.
