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

# TODO: more tests