#!perl -Tw

use strict;
use Test::More qw( no_plan );
use DAIA;

my $content = "Hallo!";
my $lang = "de";

### without error code
my $err = DAIA::Error->new( content => $content, lang => $lang );
is_deeply( $err->struct, { errno => 0, content => $content, lang => $lang } );

my @constructors = (
  error( { content => $content, lang => $lang } ),
  error( content => $content, lang => $lang, errno => undef ),
  error( content => $content, lang => $lang, errno => 0 ),
  error( $lang => $content ),
  error( $content, lang => $lang ),   
  error( lang => $lang, content => $content ),
  error( $err ), # copy constructor
);

foreach my $e2 (@constructors) {
    is_deeply( $e2, $err, 'constructor without errno' );
}

### with error code
my $errno = -1;
my $e2 = DAIA::Error->new( content => $content, lang => $lang, errno => $errno );
is( $e2->errno, -1 );

$err = error( $lang => $content, errno => $errno );
is_deeply( $err, $e2 );

$err = error();
$err->content( $content );
$err->lang( $lang );
is_deeply( $err, $err );

$err->errno( -1  );
is_deeply( $err, $e2 );
is( $err->errno, -1 );

$err->errno( undef ); # remove
is_deeply( $err, $err );

$err = error( $errno, $lang => $content,  );
is_deeply( $err, $e2 );

is( $e2->content, $content );
is( $e2->lang, $lang );
is( $e2->errno, $errno );

#### explicit errors

@constructors = (
  error(),  DAIA::Error->new( errno => 0 ),
  error(7), DAIA::Error->new( errno => 7 ),
  error(2, 'foo' ), DAIA::Error->new( 'foo', errno => 2 ),
  error(2, 'es' => 'foo' ), DAIA::Error->new( 'es' => 'foo', errno => 2 ),
  error(3, 'foo', lang => 'fr' ), DAIA::Error->new( 'fr' => 'foo', errno => 3 ),
);
while (@constructors) {
    my $e = shift @constructors;
    my $m = shift @constructors;
    is_deeply( $e, $m, 'error(...)' );
}

my $item = item();
$item->addError( 9, 'bla' );

my @msgs = $item->error;
is_deeply( \@msgs, [error(9,'bla')], 'addError' );

# errno
$err = error( 'hej', errno => 7 );
is( $err->errno, 7, 'errno' );

# eval { $err->errno( 'x' ); };
# ok( $@, 'invalid errno' );

$err->errno( undef );
is_deeply( $err->struct, { errno => 0, content => 'hej', lang => 'en' } );
