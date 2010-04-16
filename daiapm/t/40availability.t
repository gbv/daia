#!perl -Tw

use strict;
use Test::More qw( no_plan );

use DAIA;
use Data::Dumper;

use DAIA::Available;
use DAIA::Unavailable;

my $a;
my $service = 'loan'; 

my $avail = DAIA::Available->new( service => $service );
isa_ok( $avail, 'DAIA::Available' );
is( $avail->service, $service, 'service' );

$avail->status(0);
isa_ok( $avail, 'DAIA::Unavailable' );

$avail->status(1);
isa_ok( $avail, 'DAIA::Available' );

my $status = 1;
my @avail_constructors = (
  available( service => $service ),
  available( $avail ), # copy
  available( $service ),
  availability( $avail ), # copy
  # availability( $status, service => $service ),
  availability( status => $status, service => $service ),
  availability( { status => $status, service => $service } ),
  availability( $service => $status ),
);

foreach my $a ( @avail_constructors ) {
    is( ref($a), 'DAIA::Available' );
    is_deeply( $a->struct, { service => $service } );
}

$status = 0;
my $url = "http://example.com";
my $unavail = DAIA::Unavailable->new( service => $service, href => $url );
is( ref($unavail), 'DAIA::Unavailable' );

# href
is( $unavail->href, $url, 'href' );
$url = "https://example.org";
$unavail->href( $url );
is( $unavail->href, $url, 'href' );

my $unavail2 = availability($unavail);

# status
ok( $avail->status, 'status(1)' );
ok( ! $unavail->status, 'status(0)' );

$avail->status(0);
ok( ! $avail->status, 'status changed(0)' );
isa_ok( $avail, 'DAIA::Unavailable' );

$unavail->status(1);
ok( $unavail->status, 'status changed(1)' );
isa_ok( $unavail, 'DAIA::Available' );


my @unavail_constructors = (
  unavailable( service => $service, href => $url ),
  unavailable( $unavail2 ), # copy
  unavailable( $service, href => $url ),
  availability( $unavail2 ), # copy
  availability( status => $status, service => $service, href => $url ),
  availability( $service => $status, href => $url ),
  availability( { status => $status, service => $service, href => $url } ),
  # availability( $status, service => $service, href => $url ),
  # availability( { $service => $status, href => $url } ) # TODO: not implemented yet
);

foreach my $a ( @unavail_constructors ) {
    isa_ok( $a, 'DAIA::Unavailable' );
    is_deeply( $a->struct, $unavail2->struct );
}

# 
$a = available('http://purl.org/NET/DAIA/services/loan');
is( $a->service, 'loan' );

# status is mandatory
eval { DAIA::Availability->new( service => 'loan' ); };
ok( $@, 'DAIA::Availability is abstract' );
my $x = eval { availability( 'loan' ); };
ok( $@, 'Availability status is mandatory' );

# queue
$a = $unavail2;
is( $a->queue, undef, 'queue' );
$a->queue(0);
is( $a->queue, 0, 'queue' );
$a->queue(12);
is( $a->queue, 12, 'queue' );
eval { $a->queue( -1 ); };
ok( $@, 'invalid queue' );
$a->queue(undef);
is( $a->queue, undef, 'queue' );


# TODO: test messages and limitations

my $limit = new DAIA::Limitation( "only for special customers" );
$avail->limitation( [ $limit ] );


$a = available( 'loan', limitation => "bad" );
is_deeply( $a->struct, { service => 'loan', 'limitation' => [ { content => 'bad' } ] } );


# delay
$a = available('loan');
is( $a->delay, undef, 'delay undef' );

use DateTime::Duration;

my %delays = (
  'UnKnown' => 'unknown',
  'P1Y2M3DT10H30M' => 'P1Y2M3DT10H30M',
  '-P120D' => '-P120D',
  'P0M' => 'P0D',
);

foreach my $d (keys %delays) {
  $a->delay( $d );
  is( $a->delay, $delays{$d} );
}

my $d = DateTime::Duration->new( weeks => 1, days => 2, hours => 25 );
$a->delay( $d );
is( $a->delay, 'P10DT1H' );

$a->delay( undef );
is( $a->delay, undef );


# expected
$a = unavailable('loan');

my %exps = (
    '2008-09-12' => '2008-09-12',
    '200009' => undef,
    '2009-07-01T24:03:00' => undef,
    '2009-07-01T23:03:00' => '2009-07-01T23:03:00',
    '2009-07-01T00:00:00' => '2009-07-01',
);

foreach my $e (keys %exps) {
    eval { $a->expected( $e ); };
    if ( defined $exps{$e} ) {
        ok( ! $@, 'parsed ' . $e ) and
            is( $a->expected, $exps{$e} );
    } else {
        ok( $@, 'invalid date(time)' );
    }
}

# TODO: test Duration as expected

$a = unavailable('loan');
$a->expected('P5D');
#print $a->expected . "\n";


