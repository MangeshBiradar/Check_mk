#!/usr/bin/perl
use strict;
use LWP::UserAgent;
use JSON;
#
# Check Hudson job status using the JSON API
#
# (c) 2009 Robin Bramley, Opsera Ltd.
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved. This file is offered as-is,
# without any warranty.
#
# Nagios return values
# OK = 0
# WARNING = 1
# CRITICAL = 2
# UNKNOWN = 3

my $retStr = "Unknown - plugin error";
my @alertStrs = ("OK", "WARNING", "CRITICAL", "UNKNOWN");
my $exitCode = 3;
my $numArgs = $#ARGV + 1;

# check arguments
if ( $numArgs != 2 && $numArgs != 4 ) {
	print "Usage: check_hudson_job url jobname [username password]\n";
	exit $exitCode;
}
my $jobName = $ARGV[1];
my $ua = LWP::UserAgent->new;
my $req = HTTP::Request->new( GET => $ARGV[0] );

# perform basic auth if necessary
if ( $numArgs == 4 ) {
	$req->authorization_basic( $ARGV[2], $ARGV[3] );
}
# make request to Hudson
my $res = $ua->request($req);

# if we have a HTTP 200 OK response
if ( $res->is_success ) {
	my $json = new JSON;
	# get content
	my $obj = $json->decode( $res->content );

	# loop counter
	my $n = 0;
	# loop through the jobs (this depends on 'overall' read permission
	# AND 'jobs' read permission in a secure Hudson config)
	while ( $obj->{'jobs'}[$n] ) {
		# is this the job we're looking for?
		if ( $obj->{'jobs'}[$n]->{name} eq $jobName ) {
			$retStr = "$obj->{'jobs'}[$n]->{name} = $obj->{'jobs'}[$n]->{color}";
			if ( $obj->{'jobs'}[$n]->{color} eq "blue" ) {
				$exitCode = 0;
			}
			elsif ( $obj->{'jobs'}[$n]->{color} eq "red" ) {
				$exitCode = 2;
			}
			last;
		}
	$n++;
	}
}
else {
	$retStr = $res->status_line;
	$exitCode = 1;
}
print $alertStrs[$exitCode] . " - $retStr\n";
exit $exitCode;
