#!perl -Tw   

use strict;
use utf8;
use Test::More;
use DAIA;

my %NS = (
  rdfs    => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
  daia    => 'http://purl.org/ontology/daia/',
  dcterms => 'http://purl.org/dc/terms/',
  frbr    => 'http://purl.org/vocab/frbr/core#',
);
sub iri {
    my $uri = shift;
    if ($uri =~ /^([a-z0-9]+):(.+)$/) {
        $uri = ($NS{$1} . $2) if $NS{$1};
    }
    return $uri;
}
sub irihash { return { value => iri(shift), type => 'uri' } }
sub literal { return { value => shift, type => 'literal' } }

sub pdump { eval {
    use Data::Dumper;
    my $s = Dumper(shift);
    $s =~ s/    / /g;
    print $s."\n";
} }

#my $a = unavailable(expected=>'2010-02-13');
#pdump($a->rdfhash);

# Item, with URI
my $item = item( id => 'my:id' );
my $item_rdf = { 'my:id' => {  iri('rdfs:type') => [ irihash('frbr:Item') ] } }; 
is_deeply( $item->rdfhash, $item_rdf, 'empty item as rdf' );

# Response without institution
my $daia = DAIA::Response->new();
$daia->document(id =>'x:y');
ok( $daia->rdfhash->{'x:y'}, "response with document" );

done_testing;
__END__

# Storage, without URI
my $storage = storage('foo');
my $rdf = $storage->rdfhash;
my $blank;
is( scalar keys %$rdf, 1 );
($blank,$rdf) = each(%$rdf);
like( $blank, qr/^_:storage\d+$/ );

my $storage_rdf = { 
   iri('rdfs:type') => [ irihash('daia:Storage') ],
   iri('dcterms:title') => [ literal("foo") ], 
};
is_deeply( $rdf, $storage_rdf, 'storage as rdf' );

# institution and department should work like storage
# TODO: limitation should be different with extended limitations

$item->add( $storage );

my ($k,$v) = each(%$storage_rdf);
$item_rdf->{$blank} = $storage_rdf;
$item_rdf->{"my:id"}->{"unknown:storage"} = [ irihash($blank) ];

# is_deeply( $item->rdfhash, $item_rdf, 'deep item as rdf' );

my $response = response();
my $doc = document( id => 'my:doc1' );
$item = item( id => 'my:id' );
$item->addMessage( en => 'Hi!' );
$item->department( 'dep' );
$doc->addItem( $item );
$response->addDocument( $doc );
$response->institution( 'foo' );
pdump( $response->rdfhash );

__END__
use Data::Dumper;
my $d = DAIA::parse( "t/example.json" );
isa_ok( $d, 'DAIA::Response' );
#is( $d->institution->content, "贛語" );

