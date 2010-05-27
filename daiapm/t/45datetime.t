#!perl -Tw

use strict;
use warnings;
use Test::More qw( no_plan );

use DAIA::Availability qw(parse_duration normalize_duration date_or_datetime);

### date_or_datetime

my @dt1 = qw(2002-09-24 );
# ADD: 2002-09-24-06:00 2002-09-24+06:00

is( date_or_datetime($_), $_ ) for (@dt1);

my %dt2=(
  '2002-09-24Z'=>'2002-09-24',
  '2002-05-30T09:30:10.5'=>'2002-05-30T09:30:10'
);
# TODO: Timezones

is( date_or_datetime($_), $dt2{$_} ) for (keys %dt2);

1;