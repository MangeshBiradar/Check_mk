#!/usr/bin/perl

use strict;
use warnings;
use HTML::TagParser;
use List::MoreUtils qw(uniq);
use LWP::Simple;
use Getopt::Long qw(:config no_ignore_case bundling_override);

# Get url as a command line argument

my $url = ();
my $html;
my @list;
my @submissions;
my $elem;
my $tagname;
my $attr;
my $text;
my @unique_submissions;
my $sub_id;
my $website_content;
my $error;
my $sample_url ;

# Sample url for printing on console in usage()
$sample_url = 'http://hostname/jenkins/job/Test-Job/493/changes';

sub main {
        # Parse command line arguments
        GetOptions ('url=s'   => \$url);

        if (!defined($url)) {
                no_url("-url must be specified\n");
        }

        # get HTML content of $url into variable $website_content
        $website_content = get($url);

        # Parse $website_content for html tag <a>
        # Ex. <a href="http://app-host/cgi-bin/login/login.pl?rm=sd&amp;id=mangesh_23">mangesh_23</a>
        $html = HTML::TagParser->new($website_content);
        @list = $html->getElementsByTagName( "a" );

        foreach $elem ( @list ) {
                $tagname = $elem->tagName;
                $attr = $elem->attributes;
                $text = $elem->innerText;

                # Regular expression to find charecter+_digits+
                if( $text =~ /^\w+\_\d+$/ ) {
                        # Push submission ID's to array
                        push @submissions, $text;
                }
        }

        # Find unique submissions
        @unique_submissions = uniq @submissions;

        # print each unique submission
        foreach $sub_id (@unique_submissions) {
                print "$sub_id \n";
        }
}

# Explains usage of this script (how to call it effectively)
sub usage
{
print <<EOU;
Usage:
        perl $0 -url <url>
Example:
        perl $0 -url $sample_url
EOU
}

# Print error message and proper usage instructions: don't run the rest of the script
sub no_url {
        $error = shift ;
        print "\nERROR: $error" ;
        usage();
        exit 1;
}

# Execution starts here

#############
main();
#############
