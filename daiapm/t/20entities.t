#!perl -Tw

use strict;
use warnings;
use Test::More qw( no_plan );

use DAIA;
use JSON;

use DAIA::Institution;
use DAIA::Department;
use DAIA::Storage;
use DAIA::Limitation;

my %entities = ( 
  'Limitation' => \&limitation,
  'Department' => \&department,
  'Storage' => \&storage,
  'Institution' => \&institution
);

foreach my $class (keys %entities) {
    my $shortcut = $entities{$class};
    $class = "DAIA::$class";

    #diag( $class );

    my $e = new $class;
    isa_ok( $e, $class, "empty constructor" );

    my $uri = "info:isil/DE-Tue120";
    $uri = "  $uri " if ($class eq 'Storage'); # add whitespace

    my $content = "hello, world!"; # TODO: use Unicode here
    my $url = "http://search.cpan.org";
    $url = "  $url " if ($class eq 'Storage'); # add whitespace

    my $hashref = { id => $uri, content => $content, href => $url };

    $e = &$shortcut( %$hashref );
    is( $e->id, $uri, "id (shortcut constructor)" );
    is( $e->content, $content, "content (shortcut constructor)" );
    is( $e->href, $url, "href (shortcut constructor)" );


    my $e2 = &$shortcut();
    $e2->id( $uri );
    $e2->content( $content );
    $e2->href( $url );
    is_deeply( $e2, $e, 'writer accessors' );

    my $json = $e->json;
    is_deeply( decode_json($json), $e->struct, 'JSON serializing' );

    # stringify
    if ( eval { require URI; } ) {
        $e->href( URI->new( $url ) );
        is( $e->href, $url, 'URI object (href)' );
        $e->id( URI->new( $uri ) );
        is( $e->id, $uri, 'URI object (id)' );
    }

    $e = &$shortcut( $hashref );
    is_deeply( $e->struct, $hashref, 'struct' );

    my $copy = &$shortcut( $e );
    $e->content("xxx");
    is_deeply( $copy, $hashref, 'copy constructor' );

    $e->content(undef);
    is( $e->content, '', 'undef is empty string' );

    $e->content(undef);
    $e->id(undef);
    $e->href(undef);
    is_deeply( $e->struct, { content => '' }, 'remove_..' );

    $e = $class->new( $content );
    is_deeply( $e->struct, { content => $content }, 'content only (short)' );

    $e = &$shortcut( content => $content );
    is_deeply( $e->struct, { content => $content }, 'content only (param)' );

    # invalid values
    eval { $e->id('~123'); };
    ok ( $@, 'valid URI needed as id' );
    eval { $e->href('htp://x'); };
    ok ( $@, 'valid URL needed as href' );
}

# TODO: test adding entities (raw DAIA::Entity should not be allowed)

my $item = item( department => "foo" );
my $item2 = item();

__END__

$item2->department( content => "foo" );
print $item->json . "\n" . $item2->json . "\n";
is_deeply( $item2, $item );

my $dep = item->department;
my @args = ( [ department("foo") ], [ "foo" ], [ content => "foo" ] );

foreach my $args (@args) {
    my $item2 = item();
    diag( join(" | ", @{$args} ) );
    $item2->department( @{$args} );
    is_deeply( $item2->struct, $item->struct );    
}

__END__
    # TODO

    # Check that strings are encoded in UTF-8
    my %unicode = (
        "\xE4" => "\xC3\xA4"
    );
    foreach my $s (keys %unicode) {
        $e = $class->new( content => $s );
        is ( $e->json, '{"string":"'. $unicode{$s} . '"}', "UTF-8" );
    }
