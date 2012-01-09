#!perl -Tw                                                                                                  

use strict;
use Test::More qw( no_plan );
use DAIA;

my $item = item();
isa_ok( $item, 'DAIA::Item' );

### storage
is( $item->storage, undef );

$item->storage( storage() );
is_deeply( $item->struct, { storage => { content => "" } } );

$item->storage(undef);
is( $item->storage, undef );

$item->storage('baz', 'id' => 'my:id');

my @s = ( ['foo'], ['id' => 'my:id'],
          [ 'baz', 'id' => 'my:id' ],
          [ {content=>'foo',href=>'http://example.com'} ] 
        );
foreach (@s) {
    my $storage = storage( @{$_} );
    $item->storage( @{$_} );
    is_deeply( item( storage => $storage ), $item );
}


$item->add( storage('hey' ) );
is_deeply( $item->struct, { storage => { content => "hey" } } );

$item->storage( undef );
is_deeply( $item->struct, { } );

$item->addMessage( 'hey' );
is_deeply( $item->struct, { message => [ { content => "hey", lang => "en" } ] } );

## department
## ...TODO...

# multiple messages
#my $m = message('x');
my @mm = ( 
    [ { lang => 'en', content => 'hey' }, { lang => 'en', content => 'ho' } ],
    [ message('x'), { lang => 'fr', content => 'y' } ],
);
foreach my $m (@mm) {
    $item->message( $m );
    my @msg = $item->message; @msg = map { $_->struct } @msg;
    is_deeply( \@msg, $m, 'multiple messages' );
}
$item->message( message('hey'), 'ho' );
my @msg = $item->message; @msg = map { $_->struct } @msg;
is_deeply( \@msg, $mm[0], 'multiple messages' );

# part
$item = item();
ok( $item !~ /part/m, 'no part by default' );
foreach my $p (qw(broader narrower)) {
    $item->part($p);
    is( $item->part, $p, "part=$p" );
    like( $item->json, qr/{\s*"part"\s*:\s*"$p"\s*}/m );
    like( $item->xml, qr/<item\s+part\s*=\s*"$p"\s*\/>/m );
}
$item->part(undef);
ok( $item !~ /part/m, 'part unset' );

# label
$item->label( "hi" );
is( $item->label, "hi" );
$item->label( "" );
is( $item->label, "" );
$item->label( undef );
is( $item->label, "" );
$item->label( "foo" );
is( $item->label, "foo", "label" );
$item->label( [ "bar" ] );
is( $item->label, "bar", "label" );


# Services
$item = item();

test_services( { $item->services } );
$item->addAvailable( "loan" );
test_services( { $item->services }, loan => 1 );
$item->addService( "loan" => 1 );
test_services( { $item->services }, loan => 2 );
$item->addAvailable( "http://purl.org/ontology/daia/Service/Presentation" );
test_services( { $item->services }, loan => 2, presentation => 1 );

test_services( { $item->services("http://purl.org/ontology/daia/Service/Presentation") }, presentation => 1 );
test_services( { $item->services("foo","presentation") }, presentation => 1 );
test_services( { $item->services("foo","presentation","loan") }, loan => 2, presentation => 1 );

# check kinds and number of availabilities (->services)
sub test_services {
    my $s = shift;
    my %p = @_;
    my %c = map { $_ => scalar @{$s->{$_}} } keys %$s;
    is_deeply( \%c, \%p );
}

# put item to response
my $d = DAIA::Response->new;
$d->item( $item );
is_deeply( $d->item, $item );

