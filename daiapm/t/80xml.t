#!perl -Tw                                                                                                  

use strict;
use utf8;
use Test::More qw( no_plan );
use IO::File;
use DAIA;

# Support XML Schema Validating
my $schemafile = "t/daia.xsd";
my $validate = sub { };
eval "use XML::LibXML";
if ($@) {
    diag("XML::LibXML not installed - validating will be skipped: $@");
} else {
    my $parser = XML::LibXML->new;
    my $schema = eval { XML::LibXML::Schema->new( location => $schemafile ); };
    if ($@) {
        diag("Could not load XML Schema $schemafile - validating will be skipped: $@");
    } else {
        $validate = sub {
            my $doc = $parser->parse_string( $_[0] );
            eval { $schema->validate($doc) };
            is( $@, '', "XML valid against XML Schema" );
        }
    }
}


#### internal methods
use XML::Simple qw(XMLin);

my $from = "<foo xmlns='htpp://example.com'><bar/></foo>";
my $xml = eval { XMLin( $from, KeepRoot => 1, NSExpand => 1, KeyAttr => [ ] ); };
is_deeply( DAIA::daia_xml_roots($xml), {}, 'internal: daia_xml_roots');
$from = "<foo xmlns='htpp://example.com'><b>" .
        "<institution xmlns='http://purl.org/ontology/daia/'/></b></foo>";
$xml = eval { XMLin( $from, KeepRoot => 1, NSExpand => 1, KeyAttr => [ ] ); };
is_deeply( DAIA::daia_xml_roots($xml), {
  '{http://purl.org/ontology/daia/}institution' => {                                                   
    'xmlns' => 'http://purl.org/ontology/daia/' } }
, 'internal: daia_xml_roots');

$from = "<institution>I1</institution>";
$from = "<x:foo xmlns:x='htpp://example.com' xmlns='http://purl.org/ontology/daia/'>$from</x:foo>";
$xml = eval { XMLin( $from, KeepRoot => 1, NSExpand => 1, KeyAttr => [ ] ); };
is_deeply( DAIA::daia_xml_roots($xml), {
  '{http://purl.org/ontology/daia/}institution' => 'I1' }, 'internal: daia_xml_roots');

#### public methods
my $item = item();
my $itemqr = qr/<item xmlns="http:\/\/ws.gbv.de\/daia\/"\s*\/>/;

like( $item->xml( xmlns => 1 ), $itemqr, "xlmns" );
like( item( format => 'json', xmlns => 1 )->xml, $itemqr, "xlmns (hidden property)" );

is( message("en" => "hi")->xml, '<message lang="en">hi</message>', 'message' );

$item = item( 
  label => "\"",
  message => [ message("hi") ],
  department => { content => "foo" },
  available => [
    available('loan',  limitation => '<', message => '>',)
  ]
);
my $data = join("",<DATA>);
chomp $data;
is ( $item->xml( xmlns => 1 ), $data, 'xml example' );

$validate->( $item->xml( xmlns => 1 ) );

my $object;
# use Data::Dumper;

$object = DAIA::parse_xml( $data );
is_deeply( $object, $item, 'parsed xml' );

my %tests = (
    'parse message' => [
        "<message lang='de'>Hallo</message>"
         => message( 'de' => 'Hallo' )
    ],
    'ignore xmlns' => [
        "<message lang='de' xmlns='http://ws.gbv.de/daia/'>Hallo</message>" 
        => message( 'de' => 'Hallo' )
    ],
    'use xmlns' => [
        "<d:message lang='de' xmlns:d='http://ws.gbv.de/daia/'>Hallo</d:message>"
        => message( 'de' => 'Hallo' )
    ],
    "label" => [
        "<item><label>&gt;</label></item>"
        => item( label => ">" )
    ],
    "label attribute (undocumented)" => [
        "<item label='&gt;' />"
        => item( label => ">" )
    ],
    "empty label" => [
        "<item><label></label></item>"
        => item( )
    ],
);

while (my ($message, $list) = each(%tests)) {
    my $object = DAIA->parse_xml($list->[0]);
    is_deeply( $object, $list->[1], $message );
}


$object = eval { DAIA::parse_xml( "<message><foo /></message>" ); };
ok( $@, "detect errors in XML" );


my $msg = new DAIA::Message("hi");
$xml = "";
$msg->serve( pi => 'foo bar', to => \$xml );
like( $xml, qr/<\?foo\sbar\?>/, 'pi' );

$msg->serve( pi => [ 'foo', 'bar' ], to => \$xml );
my @pis = grep { $_ =~ /<\?(foo|bar|xml.*)\?>/;} split("\n", $xml);
is( scalar @pis, 3, 'pis' );

$msg->serve( pi => [ 'foo', '<?bar?>' ], to => \$xml, xslt => 'http://example.com', xmlheader => 0 );
@pis = grep { $_ =~ /<\?(foo|bar|xml.*)\?>/;} split("\n", $xml);
is( scalar @pis, 3, 'pis with xslt' );


# parse multiple
my $from1 = '<department>D</department><institution id="i:1">I1</institution><institution>I2</institution>';
$from = "<x:foo xmlns:x='htpp://example.com' xmlns='http://purl.org/ontology/daia/'>$from1</x:foo>";

my @objs = DAIA::parse($from);
@objs = sort map { $_->xml } @objs;
is( join('',@objs), $from1, "parsed multiple in XML" );

is( DAIA::parse($from), undef, "parsed multiple in XML unexpected" );

# TODO: add more examples (read and write), including edge cases and errors

my $fromjson = DAIA::parse("t/example.json");

open FILE, "t/example.xml";
my @files = ("t/example.xml", \*FILE, IO::File->new("t/example2.xml"), "t/foreign.xml");
foreach my $file (@files) {
    my $d = DAIA::parse( $file );
    isa_ok( $d, 'DAIA::Response' );
    is( $d->institution->content, "贛語" );
    is_deeply( $d->struct, $fromjson->struct );
}


#print $object->xml( xmlns => 1, xslt => 'daia.xsl', header => 1 ) . "\n";

eval { DAIA->parse( data => '{}', format => 'xml' ); };
like( $@, qr/XML is not well-formed/ );

__DATA__
<item xmlns="http://ws.gbv.de/daia/">
  <message lang="en">hi</message>
  <label>&quot;</label>
  <department>foo</department>
  <available service="loan">
    <message lang="en">&gt;</message>
    <limitation>&lt;</limitation>
  </available>
</item>
