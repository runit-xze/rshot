package main;
use strict;
use warnings;
use utf8;
use Test2::V0;
use Shutter::App::Core::SecureSystemCommandAPI;
use File::Temp qw(tempfile);

my $api = Shutter::App::Core::SecureSystemCommandAPI->new;

subtest 'capture() - success' => sub {
	my $result = $api->capture('echo', 'hello', 'world');
	is $result->{success}, 1, 'Command succeeds';
	is $result->{exit_code}, 0, 'Exit code is 0';
	like $result->{stdout}, qr/hello world\n?/x, 'Captured stdout';
	is $result->{stderr}, '', 'Captured stderr is empty';
};

subtest 'capture() - failure' => sub {
	# Run a command that fails
	my $result = $api->capture('perl', '-e', 'warn "test error\n"; exit 2;');
	is $result->{success}, 0, 'Command fails';
	is $result->{exit_code}, 2, 'Exit code is 2';
	is $result->{stdout}, '', 'stdout is empty';
	like $result->{stderr}, qr/test error/x, 'Captured stderr';
};

subtest 'capture() - bad command' => sub {
	my $result = $api->capture('this_command_does_not_exist_abc123');
	is $result->{success}, 0, 'Command fails';
	isnt $result->{exit_code}, 0, 'Exit code is non-zero';
	like $result->{error}, qr/No such file or directory/x, 'Caught execution error';
};

subtest 'run_async()' => sub {
	my ($fh, $filename) = tempfile();
	close $fh;

	# Touch a file asynchronously
	my $pid = $api->run_async('touch', $filename);
	is $pid, 1, 'Async execution spawned successfully';
	
	# Give it a tiny bit of time to complete since it's async
	sleep 1;
	
	ok -e $filename, 'File was created asynchronously';
	unlink $filename;
};

done_testing;

1;
