#!perl -Tw                                                                                                  

use strict;
use utf8;
use Test::More qw( no_plan );
use IO::File;
use DAIA;

# Support XML Schema Validating
my $schemafile = "clients/daia.xsd";
my $validate = sub { };
eval { require XML::LibXML; };
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


my $item = item();

like( $item->xml( xmlns => 1 ), qr/<item xmlns="http:\/\/ws.gbv.de\/daia\/"\s*\/>/, "xlmns" );
like( $item->xml( xmlns => 1 ), qr/<item xmlns="http:\/\/ws.gbv.de\/daia\/"\s*\/>/, "xlmns" );

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
is ( $item->xml, $data, 'xml example' );

$validate->( $item->xml( xmlns => 1) );

my $object;
# use Data::Dumper;

$object = DAIA::parse_xml( $data );
is_deeply( $object, $item, 'parsed xml' );

$object = DAIA->parse_xml( "<message lang='de' xmlns='http://ws.gbv.de/daia/'>Hallo</message>" );
is_deeply( $object, message( 'de' => 'Hallo' ), 'ignore xmlns' );

$object = DAIA::parse_xml( "<d:message lang='de' xmlns:d='http://ws.gbv.de/daia/'>Hallo</d:message>", xmlns => 1 );
is_deeply( $object, message( 'de' => 'Hallo' ), 'use xmlns' );

$object = DAIA->parse_xml( "<message lang='de'>Hallo</message>" );
isa_ok( $object, "DAIA::Message" );

$object = eval { DAIA::parse_xml( "<message><foo /></message>" ); };
ok( $@, "detect errors in XML" );

$object = DAIA->parse_xml("<item label='&gt;' />");
is_deeply( $object->struct, { label => ">" }, "label attribute (undocumented)" );

# TODO: add more examples (read and write), including edge cases and errors


my $fromjson = DAIA::parse("t/example.json");

open FILE, "t/example.xml";
my @files = ("t/example.xml", \*FILE, IO::File->new("t/example2.xml"));
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
<item>
  <message lang="en">hi</message>
  <label>&quot;</label>
  <department>foo</department>
  <available service="loan">
    <message lang="en">&gt;</message>
    <limitation>&lt;</limitation>
  </available>
</item>