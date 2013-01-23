#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use XML::Twig;
use HTTP::Request;
no warnings 'uninitialized';

print "<<<jenkins>>>\n";

sub main {
	my $host = 'localhost';
	my $win_port = '8080';
	my $apache_api_url = '/jenkins';
	my $protocol = 'http';
	my $api_url = '/api/xml';
	my $job_name;
	my $win_job_url;
	my $apache_job_url;
	my $win_apache_flag = 0;
	my $win_apache_job_flag = 0;
	my @jobs;
	my @health;
	my @job_names;
	my @description;
	my @disabled;
	
	my $winstone_url = $protocol . "://" . $host . ":" . $win_port . $api_url ;
	my $apache_url = $protocol . "://" . $host . $apache_api_url . $api_url ;
	#print "$winstone_url\n";
	#print "$apache_url\n";
	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	$ua->env_proxy;
	my $response1 = $ua->get($winstone_url);
	my $response2 = $ua->get($apache_url);
	if ($response1->is_success) {
		$win_apache_flag = 1;
		my $content = $response1->decoded_content;  # or whatever
		XML::Twig->new( twig_roots => { 'job/name' => sub { push @jobs, $_->text; } }) ->parseurl( $winstone_url);
		#foreach my $job (@jobs) {
		#	print "$job\n";
		#}
	}
	elsif ($response2->is_success) {
		$win_apache_flag = 1;
		my $content = $response2->decoded_content;  # or whatever
		XML::Twig->new( twig_roots => { 'job/name' => sub { push @jobs, $_->text; } }) ->parseurl( $apache_url);
		#foreach my $job (@jobs) {
		#	print "$job\n";
		#}
	}
	else {
		print "Url not found \n";
		exit 0;
	}
	
	if($win_apache_flag) {
		foreach $job_name (@jobs) {
			@health = ();
			@job_names = ();
			@description = ();
			@disabled = ();
			$win_job_url = $protocol . "://" . $host . ":" . $win_port . "/" . "job" . "/" . $job_name . $api_url ;
			$apache_job_url = $protocol . "://" . $host . $apache_api_url . "/" . "job" . "/" . $job_name . $api_url ;
			#print "$win_job_url\n";
			#print "$apache_job_url\n";
			my $response3 = $ua->get($win_job_url);
			my $response4 = $ua->get($apache_job_url);
			if ($response3->is_success) {
				$win_apache_job_flag = 1;
				#$win_job_url = $protocol . "://" . $host . ":" . $port . "/" . "job" . "/" . $job_name . $api_url ;
				XML::Twig->new( twig_roots => { 'freeStyleProject/name' => sub { push @job_names, $_->text}, 'freeStyleProject/color' => sub { push @disabled, $_->text}, 'healthReport/description' => sub { push @description, $_->text},'healthReport/score' => sub { push @health, $_->text; }}) ->parseurl( $win_job_url);
			}
			elsif ($response4->is_success) {
				$win_apache_job_flag = 1;
				#$apache_job_url = $protocol . "://" . $host . $apache_url . "/" . "job" . $job_name . $api_url ;
				XML::Twig->new( twig_roots => { 'freeStyleProject/name' => sub { push @job_names, $_->text}, 'freeStyleProject/color' => sub { push @disabled, $_->text}, 'healthReport/description' => sub { push @description, $_->text},'healthReport/score' => sub { push @health, $_->text; }}) ->parseurl( $apache_job_url);
			}
			else {
				print "Url not found \n";
				exit 0;
			}
			if ($win_apache_job_flag) {
				#print "OK, @job_names has Health score @health\n";
				#print @job_names, "\n";
				#print @health, "\n";
				#print @description, "\n";
				my $is_health = scalar(@health);
				my $is_job = scalar(@job_names);
				my $is_desc = scalar(@description);
				my $is_disabled = scalar(@disabled);
				if ($disabled[0] ne 'disabled') {
					my $result;
					if ($is_health != 0	&& $is_job != 0) {
						#print "Score::$value\n";
						#print "Name::$job_value\n";
						my $itr = 0;
						my $sum = 0;
						while ($itr < @health) {
							$sum = $sum + $health[$itr];
							$itr = $itr + 1;
						}
						$result = $sum/$is_health;
						print "@job_names @description $result\n";
					}
					else {
						if ($is_job !=0) {
							print "@job_names @description 0\n";
						}
						#else {
						#	print "No_Name @description 0\n";
						#}
					}
				}
				else {
					print "@job_names @description 100\n";
				}
			}
		}
	}
}

	
	
main();
