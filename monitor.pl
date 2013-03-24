#!/usr/bin/env perl
# $Id$
#
# Script to obtain the temperature read from the arduino device attached to the named
# device below. Intended to be run by nagios and hence it takes the optional arguments
# -w N and -c N where -w is warning level and -c is critical level. Script does this:
#
# if -c specified and temp is above it, it will output a critical temperature message and exit with 2
# else if -w specified and temp is above it, it will output a warning temperature message and exit
#   with 1
# else it outputs the temperature
#
# if -d dir specified it overrides the above and writes the file YYYY_MM_DD.log to the dir
# specified with -d with localtime(), temp
#
# -v verbose
# -s device - defaults to /dev/ttyACM0 (you can omit the /dev/
#
use strict;
use warnings;
use Getopt::Std;
use File::Spec;

my $device = '/dev/ttyACM0';    # device arduino attached to

my %opts;

getopts('vw:c:d:s:', \%opts);

if ($opts{s})  {
    if ($opts{s} !~ /\//) {
        $device = "/dev/$opts{s}";
    } else {
        $device = $opts{s};
    }
}

use Device::SerialPort qw( :STAT 0.19);

my $port = Device::SerialPort->new($device);

if( ! defined($port) ) {
        die("Can't open $device: $^E\n");
}

my $output = select(STDOUT);
$|++;

#$port->initialize(); Win32::SerialPort had this but Device::SerialPort does not

# the following are necessary and the baud rate must be set in the arduino script too:
$port->baudrate(115200);
$port->parity('none');
$port->databits(8);
$port->stopbits(1);

# not sure how many of these are not the defaults:
$port->stty_ignbrk(1);
$port->stty_icrnl(0);
$port->stty_opost(0);
$port->stty_inlcr(0);
$port->stty_isig(1);
$port->stty_icanon(0);
$port->stty_echo(0);
$port->stty_echoe(0);
$port->stty_echok(0);
$port->stty_echoctl(0);
$port->stty_echoke(0);

$port->write_settings() or die "write settings";
$port->are_match("\n");

$port->write("t\n");            # send msg to arduino asking for temperature

# there is something funny which happens if we start writing to the serial
# port too quickly - sometimes you don't get a response. A sleep 2 here fixes
# that but it also slows down the script. A better way is that if we get nothing back
# from the arduino we send another request for the temperature - see the write below:
#
my $temp;
while (1) {
    my $char = $port->lookfor();
    if ($char eq '') {
        #print "no input found\n";
        # got nothing, sometimes happens, ask again
        $port->write("t\n");
    } elsif (!defined($char)) {
        die "error";
    } else {
        $char =~ s/\xd//g;
        # very occassionally we get duff stuff back
        # check the returned temp looks right and if not have another go
        if ($char =~ /^\d{1,2}\.\d\d$/) {
            $temp = $char;
            last;
        } else {
            if ($opts{v}) {
                print "Got: ", join(",", map {ord($_)} split //,$char), "\n";
            }
            $port->write("t\n"); # have another go
        }
    }
};

$port->close();

if ($opts{d}) {
    my @lt = localtime();
    my $filename = sprintf('%4d_%02d_%02d.log', $lt[5] + 1900, $lt[4]+1, $lt[3]);
    my $path = File::Spec->catfile($opts{d}, $filename);
    open (my $fh, ">>", $path) or die "Failed to open $path for append - $!";
    print $fh time(), ",$temp\n";
    close $fh;
    print time(), ",$temp\n" if $opts{v};
} elsif ($opts{c} && $temp > $opts{c}) {
    print "Critical temperature $temp\n";
    exit 2;
} elsif ($opts{w} && $temp > $opts{w}) {
    print "Warning temperature $temp\n";
    exit 1;
} else {
    print "Temperature $temp\n";
}
exit 0;
