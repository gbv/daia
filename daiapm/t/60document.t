#!perl -Tw                                                                                                  

use strict;
use Test::More qw( no_plan );
use DAIA;

my $doc = eval "document()";
ok( ! $doc, 'DAIA::Document->id needed' );

$doc = document( id => 'my:123' );
isa_ok( $doc, 'DAIA::Document' );

# this is also tested in 30messages.t :
$doc->message( [ message('hi' ) ] );
$doc->add( message('ho') );
my @msgs = $doc->message;
is( scalar @msgs, 2, 'message and add' );

# TODO: attributes: item, href, id
# TODO: copy constructor, struct, json setting etc.
