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

sub pdump { eval {
    use Data::Dumper;
    my $s = Dumper(shift);
    $s =~ s/    / /g;
    print $s."\n";
} }

#my $error = error();
#my $a = unavailable(expected=>'2010-02-13');
#pdump($a->rdfhash);

# Item, with URI
my $item = item( id => 'my:id' );
my $item_rdf = { 'my:id' => {  iri('rdfs:type') => [ irihash('daia:Item') ] } }; 
is_deeply( $item->rdfhash, $item_rdf, 'empty item as rdf' );

# Storage, without URI
my $storage = storage('foo');
my $rdf = $storage->rdfhash;
my $blank;
is( scalar keys %$rdf, 1 );
($blank,$rdf) = each(%$rdf);
like( $blank, qr/^_:storage\d+$/ );

my $storage_rdf = { 
   iri('rdfs:type') => [ irihash('daia:Storage') ],
   iri('dct:title') => [ literal("foo") ], 
};
is_deeply( $rdf, $storage_rdf, 'storage as rdf' );

# institution and department should work like storage
# TODO: limitation should be different with extended limitations

$item->add( $storage );

my ($k,$v) = each(%$storage_rdf);
$item_rdf->{$blank} = $storage_rdf;
$item_rdf->{"my:id"}->{"unknown:storage"} = [ irihash($blank) ];

is_deeply( $item->rdfhash, $item_rdf, 'deep item as rdf' );

__END__
use Data::Dumper;
my $d = DAIA::parse( "t/example.json" );
isa_ok( $d, 'DAIA::Response' );
#is( $d->institution->content, "贛語" );

