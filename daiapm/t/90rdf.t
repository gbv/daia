#!perl -Tw   

use strict;
use utf8;
use Test::More qw( no_plan );
use DAIA;

my %NS = (
  'rdfs' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  'daia' => 'http://purl.org/ontology/daia/',
  'dct'  => 'http://purl.org/dc/terms/',
);
sub iri {
    my $uri = shift;
    if ($uri =~ /^([a-z0-9]+):(.+)$/) {
        $uri = ($NS{$1} . $2) if $NS{$1};
    }
    return $uri;
}
sub irihash { return { value => iri(shift), type => 'uri' }; }
sub literal {
    my ($s,%o) = shift;
    $o{value} = $s;
    $o{type} = 'literal';
    return \%o;
}

# Item, with URI
my $item = item( id => 'my:id' );
is_deeply( $item->rdfhash, { 
  'my:id' => {  iri('rdfs:type') => [ irihash('daia:Item') ] } } 
);

# Storage, without URI
my $s = storage('foo');
my $rdf = $s->rdfhash;
my $blank;
is( scalar keys %$rdf, 1 );
($blank,$rdf) = each(%$rdf);
like( $blank, qr/^_:storage\d+$/ );

is_deeply( $rdf, { 
   iri('rdfs:type') => [ irihash('daia:Storage') ],
   iri('dct:title') => [ literal("foo") ], 
});

# use Data::Dumper;
#print Dumper($rdf);

my $d = DAIA::parse( "t/example.json" );
isa_ok( $d, 'DAIA::Response' );
#is( $d->institution->content, "贛語" );
#print Dumper($d->rdfhash);

