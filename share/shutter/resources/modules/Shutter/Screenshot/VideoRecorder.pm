package Shutter::Screenshot::VideoRecorder;

use utf8;
use v5.40;
use feature 'try'; no warnings 'experimental::try';

use Moo;
use Glib qw/TRUE FALSE/;
use Gtk3;
use File::Temp qw/tempdir/;
use POSIX ":sys_wait_h";

has '_common'   => (is => 'ro', required => 1);
has 'region'    => (is => 'rw', required => 1);  # { x, y, w, h }
has 'fps'       => (is => 'ro', default  => sub { 30 });
has 'duration'  => (is => 'ro', default  => sub { 0 });
has 'output'    => (is => 'ro', required => 1);  # .mp4 path
has 'on_done'   => (is => 'ro', required => 1);

has '_pid'      => (is => 'rw');
has '_running'  => (is => 'rw', default  => sub { FALSE });

has 'cli'       => (is => 'ro'); # Add cli to get settings manager

sub start ($self) {
    return if $self->_running;
    
    $self->_running(TRUE);

    my $r = $self->region;
    my $display = $ENV{DISPLAY} // ':0.0';
    
    my $w = $r->{w};
    my $h = $r->{h};
    $w -= $w % 2;
    $h -= $h % 2;
    
    # Adjust display offset
    my $input = sprintf("%s+%d,%d", $display, $r->{x}, $r->{y});
    my $size = sprintf("%dx%d", $w, $h);
    
    my @cmd = (
        'ffmpeg',
        '-y',
        '-video_size', $size,
        '-framerate', $self->fps,
        '-f', 'x11grab',
        '-i', $input
    );
    
    my $sm;
    if ($self->cli) {
        $sm = $self->cli->{settings_manager};
    }
    
    my $rec_desktop = $sm ? ($sm->get_setting('video', 'record_desktop') // 0) : 0;
    my $rec_mic = $sm ? ($sm->get_setting('video', 'record_mic') // 0) : 0;
    
    if ($rec_desktop || $rec_mic) {
        # Check pulse default sources/sinks
        my $pulse_sink = `pactl info 2>/dev/null | grep 'Default Sink' | cut -d' ' -f3`;
        chomp $pulse_sink;
        my $pulse_src = `pactl info 2>/dev/null | grep 'Default Source' | cut -d' ' -f3`;
        chomp $pulse_src;
        
        my $a_idx = 1;
        my $mix_filter = "";
        
        if ($rec_desktop && $pulse_sink) {
            push @cmd, ('-f', 'pulse', '-i', $pulse_sink . ".monitor");
            $mix_filter .= "[$a_idx:a]";
            $a_idx++;
        }
        
        if ($rec_mic && $pulse_src) {
            push @cmd, ('-f', 'pulse', '-i', $pulse_src);
            $mix_filter .= "[$a_idx:a]";
            $a_idx++;
        }
        
        if ($a_idx > 2) {
            # Both were added, mix them
            push @cmd, ('-filter_complex', $mix_filter . "amix=inputs=2[a]", '-map', '0:v', '-map', '[a]');
        } else {
            # Only one was added, just map it
            push @cmd, ('-map', '0:v', '-map', '1:a');
        }
    }
    
    push @cmd, (
        '-c:v', 'libx264',
        '-preset', 'ultrafast',
        '-crf', '18',
        '-pix_fmt', 'yuv420p',
        $self->output
    );
    
    my $pid = fork();
    if (!defined $pid) {
        $self->_running(FALSE);
        $self->on_done->(undef);
        return;
    }
    
    if ($pid == 0) {
        open STDOUT, '>', '/dev/null';
        open STDERR, '>', '/dev/null';
        exec(@cmd);
        exit(1);
    }
    
    $self->_pid($pid);
}

sub stop ($self) {
    return unless $self->_running;
    $self->_running(FALSE);
    
    my $pid = $self->_pid;
    if ($pid) {
        kill('INT', $pid);
        waitpid($pid, 0);
    }
    
    if (-f $self->output) {
        $self->on_done->($self->output);
    } else {
        $self->on_done->(undef);
    }
}

sub get_mode ($self) { 'video_select' }
sub get_error_text ($self) { 'Failed to record Video.' }

1;

