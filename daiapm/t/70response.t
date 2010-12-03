#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA;

ok( DAIA::is_uri("my:foo"), 'is_uri (1)' );
ok( !DAIA::is_uri("123"), 'is_uri (0)' );

my $daia = response;
isa_ok( $daia, 'DAIA::Response' );

my $d1 = response( $daia );
is_deeply( $d1, $daia, 'copy constructor' );

is( $daia->version, '0.5' );
ok( $daia->timestamp, 'timestamp initialized' );

my $doc = document( id => 'my:123' );
$daia->document( $doc );
is_deeply( $daia->document, $doc );

my $inst = institution( 'foo' );
$daia->institution( $inst );
is_deeply( $daia->institution, $inst );

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

sub test_serve {
    foreach my $test (@_) {
        $out = "";
        my @arg = @{$test->[0]};
        push @arg, %p;
        $item->serve( @arg );
        like( $out, $test->[1], $test->[2] );
        my $out1 = $out; $out = '';

        unless ( @arg % 2 ) {
use Data::Dumper; print Dumper(\@arg)."\n";
            $item = item( @arg );
            $item->serve;
            is( $out, $out1, 'serve with hidden parameters' );
        }
    }
}
