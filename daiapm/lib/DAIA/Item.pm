package DAIA::Item;

=head1 NAME

DAIA::Item - Holds information about an item of a L<DAIA::Document>

=cut

use strict;
use base 'DAIA::Object';
our $VERSION = '0.30';

use DAIA;
use JSON;

=head1 PROPERTIES

=over 

=item id

The unique identifier of this item (optional). Must be an URI if given.

=item href

A link to the item or to additional information about it.

=item message

An optional list of L<DAIA::Message> objects. You can set message(s) with
the C<message> accessor, with C<addMessage>, and with C<provideMessage>.

=item fragment

Whether the item only contains a part of the document.
B<this property will likely be renamed>.

=item label

A label that helps to identify and/or find the item (signature etc.).

=item department

A L<DAIA::Department> object with an administrative sub-entitity of the
institution that is connected to this item (for instance the holding
library branch).

=item storage

A L<DAIA::Storage> object with the physical location of the item (stacks, floor etc.).

=item available

An optional list of L<DAIA::Available> objects with available services that can
be performed with this item.

=item unavailable

An optional list of L<DAIA::Unavailable> objects with unavailable services 
that can (currently or in general) not be performed with this item.

=cut

our %PROPERTIES = (
    rdftype     => 'http://purl.org/vocab/frbr/core#Item',
    id          => $DAIA::Object::COMMON_PROPERTIES{id},
    href        => $DAIA::Object::COMMON_PROPERTIES{href},
    message     => $DAIA::Object::COMMON_PROPERTIES{message},
    error       => $DAIA::Object::COMMON_PROPERTIES{error},
    fragment    => { # xs:boolean
        filter => sub {
            return unless defined $_[0];
            return ($_[0] and not lc($_[0]) eq 'false') ? $JSON::true : $JSON::false;
            return;
        }
    },
    label       => {
        default => '',
        filter => sub { # label can be specified as array or as element
            my $v = (ref($_[0]) eq 'ARRAY') ? $_[0]->[0] : $_[0]; 
            return "$v";
        },
        predicate => $DAIA::Object::RDFNAMESPACE.'label'
    },
    department  => { type => 'DAIA::Department' },
    storage     => { type => 'DAIA::Storage' },
    available   => { type => 'DAIA::Available', repeatable => 1 },
    unavailable => { type => 'DAIA::Unavailable', repeatable => 1 },
);

=head1 METHODS

=head2 Standard methods

DAIA::Item provides the L<standard methods|DAIA/"DAIA OBJECTS"> and accessor
methods for its properties as listed above.

=head2 Additional appender methods

=over

=item C<< addMessage ( $message | ... ) >>

Add a given or a new L<DAIA::Message>.

=item C<< addAvailable ( $available | ... ) >>

Add a given or a new L<DAIA::Available>.

=item C<< addUnavailable ( $unavailable | ... ) >>

Add a given or a new L<DAIA::Unavailable>.

=item C<< addAvailability ( $availability | ... ) >>

Add a given or a new L<DAIA::Availability>.

=item C<< addService ( $availability | ... ) >>

Add a given or a new L<DAIA::Availability> (alias for addAvailability).

=back

=cut

sub addAvailability {
    my $self = shift;
    return $self unless @_ > 0;
    return $self->add(
        UNIVERSAL::isa( $_[0], 'DAIA::Availability' ) 
          ? $_[0] 
          : DAIA::Availability->new( @_ )
    );
}

*addService = *addAvailability;

=head2 Additional query methods

=over

=item C<< services ( [ @services ] ) >>

Returns a (possibly empty) hash of services mapped to lists
of L<DAIA::Availability> objects for the given services. If
you provide a list of wanted services (each specified by its 
URI or by its short name), you only get those services.

=back

=cut

sub services {
    my $self = shift;

    my %wanted = map { $_ => 1 }
                 map { $DAIA::Availability::SECIVRES{$_} ? 
                       $DAIA::Availability::SECIVRES{$_} : $_ } @_;

    my %services;
    foreach my $a ( ($self->available, $self->unavailable) ) {
        my $s = $a->service;
        next if %wanted and not $wanted{$s};
        if ( $services{$s} ) {
            push @{ $services{$s} }, $a;
        } else {
            $services{$s} = [ $a ];
        }
    }

    return %services;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
