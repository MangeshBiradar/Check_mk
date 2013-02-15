#!/usr/bin/perl

use strict;
use warnings;

use LWP::UserAgent;
use XML::LibXML;
use POSIX;
no warnings 'uninitialized';

print "<<<jenkins>>>\n";

my $host = 'localhost';
my $win_port = '8080';
my $apache_api_url = '/jenkins';
my $protocol = 'http';
my $api_url = '/api/xml?tree=jobs[name,description,color,healthReport[score,description],lastSuccessfulBuild[number],lastBuild[number]]';

my $winstone_url = $protocol . "://" . $host . ":" . $win_port . $api_url ;
my $apache_url = $protocol . "://" . $host . $apache_api_url . $api_url ;

my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
my $response1 = $ua->get($winstone_url);
my $response2 = $ua->get($apache_url);

if ($response1->is_success) {
	one($response1);
}
elsif ($response2->is_success) {
	one($response2);
}
else {
	print ("URL_Not_Found\n");
}

sub one {
	my $response = shift;
	my $default_warn = 80;
	my $default_crit = 40;
	my $content = $response->decoded_content;
    my $parser = XML::LibXML->new();
	my $xmldoc = $parser->parse_string($response->decoded_content( charset => 'none' ));
	for my $job ($xmldoc->findnodes('/hudson/job')) {
		my $job_desc = $job->findvalue('description/text()');
		my $job_name = $job->findvalue('name/text()');
		my $job_color = $job->findvalue('color/text()');
		my $health_desc = $job->findvalue('healthReport/description/text()');
		# my @health_score  = $job->getElementsByTagName('score');
		# my $health_score = $job->findvalue('healthReport/score/text()');
		my $last_success_build = $job->findvalue('lastSuccessfulBuild/number/text()');
		my $last_build = $job->findvalue('lastBuild/number/text()');
		my @health_scores;
		my $health_score;
		if($last_success_build || $last_build) {
			@health_scores  = $job->getElementsByTagName('score');
			my $no_of_scores = scalar(@health_scores);
		
			if ($no_of_scores == 2) {
				my $first = $health_scores[0]->getFirstChild->getData;
				my $second = $health_scores[1]->getFirstChild->getData;
				$health_score = (($first + $second)/$no_of_scores);
				$health_score = ceil($health_score);
			}
			else {
				$health_score = $health_scores[0]->getFirstChild->getData;
			}
			
		}
		$health_desc =~ s/ /_/g;
		$job_name =~ s/ /_/g;
		
		if ($job_color =~ /\w+\_anime/) {
			$last_build = $last_build - 1;
		}
		if(( $job_desc =~ /\{MONITOR:NO\}/ ) || ($job_color eq 'disabled')) {
			 print("$job_name Disabled\n");
		}
		elsif(!$last_success_build || !$last_build) {
			print("$job_name job_not_ran_yet\n");
		}
		else {
			if($last_success_build eq $last_build) {
				print("$job_name 0 0 $health_score $health_desc\n");
			}
			else {
				if($job_desc =~ /\{WARN:(\d*)\sCRITICAL:(\d*)\}/ ) {
					my $warn = $1;
					my $crit = $2;
					print("$job_name $warn $crit $health_score $health_desc\n");
				}
				else {
					print("$job_name $default_warn $default_crit $health_score $health_desc\n");
				}
			}
		}
					
	}
}



