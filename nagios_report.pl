#!/usr/bin/perl
use strict ;

use Nagios::Report ;

my $x = Nagios::Report->new(
                            # Data source
                q<local_cgi localhost nagiosadmin>,
                            # Report period
                [ qw(24x7) ],
                            # Time period
                'last7days',
                            # Service report
                1,
                            # Pre-filter 
                sub { my %F = @_; my $u = $F{PERCENT_TOTAL_TIME_OK}; $u =~ s/%//; $u < 100 }
               )
  or die "Can't construct Nagios::Report object." ;

$x->mkreport(
        [
        qw(
            HOST_NAME
            PERCENT_TOTAL_TIME_OK
            DOWN
            UP
            OUTAGE
          )
        ],

        sub { my %F = @_; my $u = $F{PERCENT_TOTAL_TIME_OK}; $u =~ s/%//; $u < 100 },

        undef,

        undef,

        1,

) ;

$x->debug_dump() ;