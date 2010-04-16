#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA;

ok( DAIA::is_uri("my:foo"), 'is_uri (1)' );
ok( !DAIA::is_uri("123"), 'is_uri (0)' );

my $daia = response;
isa_ok( $daia, 'DAIA::Response' );

my $doc = document( id => 'my:123' );

my $d1 = response( $daia );
is_deeply( $d1, $daia, 'copy constructor' );


#### test method DAIA::Object::serve
my $item = item();
my $out;

use CGI;
my $cgi = new CGI;
my %p = ( to => \$out, header => 0, exitif => sub { return 0; } );

test_serve(
  [ [], qr/<item/, 'default format is XML' ],
  [ ['xml'], qr/<item/, 'serialized as XML' ],
  [ [$cgi], qr/<item/, 'default format is XML' ],
  [ ['format' => 'xml'], qr/<item/, 'serialized as XML' ],
  [ ['json'], qr/{/, 'serialized as JSON' ],
  [ ['format' => 'json'], qr/{/, 'serialized as JSON' ],
);

$cgi->param('format','json');
test_serve( [ [$cgi], qr/^\s*{/, 'format set to JSON' ] );
$cgi->param('callback','foo');
test_serve( [ [$cgi], qr/^foo\(\s*{/, 'format set to JSON with callback' ] );
test_serve( [ ['json', callback => 'bar'], qr/^bar\(\s*{/, 'format set to JSON with callback' ] );

# TODO: test 'xslt', 'to', 'exitif' etc.

sub test_serve {
    foreach my $test (@_) {
        $out = "";
        my @arg = @{$test->[0]};
        push @arg, %p;
        $item->serve( @arg );
        like( $out, $test->[1], $test->[2] );
    }
}
