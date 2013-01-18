#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling_override);
no warnings 'uninitialized';
#print '<<<check_jenkins_jobs>>>';
my ($port, $host) ;
# Parse command line arguments
GetOptions ('host=s'   => \$host, 'port=s' => \$port);
if( (!defined($host)) || (!defined($port))) {
        print "USAGE:perl $0 -host mbiradar2d -port 8080";
  	exit 1;
}

my @output = `perl "H:\\Mangesh\\check_jenkins_jobs.pl" -host $host -port $port`;
my $line;
my @out;
my $status = 0;
my $statustxt = 'OK';
my ($OK, $WARN, $CRIT) = 0;
foreach $line (@output) {
	my @values = split('~', $line);
	if($values[0] =~ /^CRITICAL/) {
		$status = 2;
		$statustxt = 'CRITICAL';
		$CRIT++;
	}
	elsif($values[0] =~ /^WARNING/) {
		if ($status == 0){
			$status = 1;
			$statustxt = 'WARNING';
			$WARN++;
		}
	}
	else {
		$OK++;
	}
	push(@out, "$values[0]-$values[1]: Description-$values[2]: Health score -$values[3]");
}

my @outtxt;
push(@outtxt, "$CRIT are CRITICAL") if ($CRIT);
push(@outtxt, "$WARN are WARNING") if ($CRIT);
push(@outtxt, "$OK are OK") if ($OK);
$outtxt[0] = "$statustxt - $outtxt[0]";
print join("\n", @out);
exit $status;