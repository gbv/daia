#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA qw(parse guess);

my $d = parse( file => 't/example.xml' );
isa_ok( $d, 'DAIA::Response' );

my $xml  = $d->xml( header => 1 );
my $json = $d->json; 

is( guess($xml), 'xml', 'guessed DAIA/XML' );
is( guess($json), 'json', 'guessed DAIA/JSON' );

is( DAIA->guess($xml), 'xml', 'guessed DAIA/XML' );

__END__
use Data::Dumper;

$d = parse( file => 't/example.json' );
my $p = Dumper( $d->rdfhash ) . "\n";
$p =~ s/\t|        /  /gm;
print $p;

__END__

# This seems not to work:

no warnings 'redefine';
*LWP::Simple::get = sub ($) { return $json; };
$d = parse( "http://example.com" );
isa_ok( $d, 'DAIA::Response' );

