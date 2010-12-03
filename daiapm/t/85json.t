#!perl -Tw                                                                                                  

use strict;
use utf8;
use Test::More qw( no_plan );
use DAIA;

my $d;

# test error handling of DAIA::parse
eval { DAIA->parse( file => "notexist" ); };
like( $@, qr/Failed to open file notexist/ );

# TODO: this might not work on Windows
eval { DAIA->parse( file => "/dev/null" ); };
like( $@, qr/DAIA serialization is empty/ );

# TODO: more error handling

open FILE, "t/example.json";
binmode FILE, ':utf8';
my @files = (\*FILE,"t/example.json");
foreach my $file (@files) {
    my $d = DAIA::parse( $file );
    isa_ok( $d, 'DAIA::Response' );
    is( $d->institution->content, "贛語" );
}

my $s = storage('foo');
my $j1 = "{\n   \"content\" : \"foo\"\n}\n";
json_test( $s->json, $j1  );
my $j2 = "xy({\n   \"content\" : \"foo\"\n}\n);";
json_test( $s->json('xy'), $j2  );
$s = storage( 'foo', callback => 'xy' );
json_test( $s->json, $j2 );
json_test( $s->json(undef), $j1 );

# JSON seems to add different spaces, depending on the version
sub json_test {
  my @j = map { s/\s+/ /g; s/\n+$//; s/} /}/g; $_ } @_;
  is ($j[0], $j[1]);
}
