#!/usr/bin/perl

$| = 1;

use Term::ProgressBar;
use Time::HiRes qw/usleep/;

my $number_of_entries = 10;
my $progress = Term::ProgressBar->new ({count => $number_of_entries ,name => 'Sending',ETA=>'linear'});

for(1..$number_of_entries)
{
    sleep(5);
    $progress->update($_);
    $progress->message("\rSent $_ of $number_of_entries");
}
