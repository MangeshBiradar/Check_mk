#!/usr/bin/perl

# watchdir:

use strict;
use warnings;

# global variables
my $interval = 6;    # time (in seconds) between checks

# If no command-line argument, use the current directory
my $dirname = "G:/Temp";
my $myContents;

die "$dirname is not a directory\n" unless -d $dirname;

sub get_dir_entries($)
{
    my ($dirname) = @_;

    my %entries = ();
    opendir(DIR, $dirname) or die "can't opendir $dirname: $!\n";
    while (defined(my $filename = readdir(DIR)))
    {
        next if $filename =~ /^\.\.?$/;     # skip . and ..
        $entries{$filename} = 1;
    }
    closedir(DIR);

    return \%entries;
}

sub diff_hash_keys($$)
{
    my ($ref_hashA, $ref_hashB) = @_;

    my %hashA = %$ref_hashA;
    my %hashB = %$ref_hashB;
    my @A_not_B = ();
    my @B_not_A = ();

    foreach (keys %hashA)
    {
        push(@A_not_B, $_) unless exists $hashB{$_};
    }
    foreach (keys %hashB)
    {
        push(@B_not_A, $_) unless exists $hashA{$_};
    }

    return (\@A_not_B, \@B_not_A);
}

#Main Function are here.
#***********************

MAIN
{
    $| = 1; # enable autoflushing of output so this works better when piped
    my $prev = undef;
    while (1)
    {
        my $date = localtime();
        my $curr = get_dir_entries($dirname);
        if (defined($prev))
        {
            my ($added, $removed) = diff_hash_keys($curr, $prev);
            foreach (sort @$added)
            {
                print "$date: Added file $_\n";

  	print $dirname . "/" . $_;

		open(inputFile, "+< $dirname" . "/" . $_) or die "dfsfjs dfjsdfdsl";

		while(<inputFile>)
		{
			chomp;
			$myContents = $myContents . $_;
		}
		my $ReplaceText = $myContents;
		$ReplaceText = ~s/sometext/sometext/gi;
			
		close(inputFile);
		
            }
            foreach (sort @$removed)
            {
                print "$date: Removed file $_\n";
            }
            #if (@$added || @$removed)
            #{
             #   print "\a\a\a\a"; # make a beep
            #}
        }
        $prev = $curr;

        sleep $interval;
    }
}

the above code will thrown me the errors when i p
