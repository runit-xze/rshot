package Shutter::App::Core::SecureSystemCommandAPI;

use utf8;
use v5.40;
use Moo;
use IPC::Run3;
use Log::Any;
use POSIX ();

my $log = Log::Any->get_logger;

=head1 NAME

Shutter::App::Core::SecureSystemCommandAPI - A secure, shell-agnostic command runner

=head1 DESCRIPTION

This module replaces unsafe C<system("...")> and backtick operator calls with
secure array-based invocations. It prevents CWE-78 (OS Command Injection) by bypassing
the shell completely.

=head1 METHODS

=head2 capture(@cmd)

Runs C<@cmd> synchronously and captures C<stdout>, C<stderr>, and C<exit_code>.
Returns a HashRef containing the results.

=head2 run_async(@cmd)

Runs C<@cmd> asynchronously using a double-fork daemonize pattern.

=cut

sub capture ($self, @cmd) {
	my $stdout = '';
	my $stderr = '';

	$log->debug("Running secure command: " . join(' ', @cmd));

	# run3 takes an arrayref to bypass the shell securely
	my $eval_ok = eval { run3(\@cmd, \undef, \$stdout, \$stderr); 1 };
	if (!$eval_ok) {
		$log->error("Command execution failed: $@");
		return {
			success   => 0,
			stdout    => $stdout,
			stderr    => $stderr,
			exit_code => -1,
			error     => $@,
		};
	}

	my $exit_code = $? >> 8;
	return {
		success   => ($exit_code == 0 ? 1 : 0),
		stdout    => $stdout,
		stderr    => $stderr,
		exit_code => $exit_code,
	};
}

sub run_async ($self, @cmd) {
	$log->debug("Running secure async command: " . join(' ', @cmd));

	if (my $pid = fork()) {

		# Parent: wait for intermediate child
		waitpid($pid, 0);
		return 1;
	}
	elsif (defined $pid) {

		# Intermediate child
		fork() && POSIX::_exit(0);

		# Grandchild (daemonized)
		if ($^O ne 'MSWin32') {
			POSIX::setsid();
		}

		# Close standard file descriptors to detach completely
		open STDIN,  '<', '/dev/null' or POSIX::_exit(1);    ## no critic (InputOutput::RequireCheckedOpen, InputOutput::ProhibitTwoArgOpen)
		open STDOUT, '>', '/dev/null' or POSIX::_exit(1);    ## no critic (InputOutput::RequireCheckedOpen, InputOutput::ProhibitTwoArgOpen)
		open STDERR, '>', '/dev/null' or POSIX::_exit(1);    ## no critic (InputOutput::RequireCheckedOpen, InputOutput::ProhibitTwoArgOpen)

		# Execute the command securely
		exec(@cmd) or POSIX::_exit(1);
	}
	else {
		$log->error("Could not fork for async execution: $!");
		return 0;
	}
}

1;
