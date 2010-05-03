package DAIA::Document;

=head1 NAME

DAIA::Document - Information about a single document

=cut

use strict;
use base 'DAIA::Object';
our $VERSION = '0.27';
use Carp qw(croak);

=head1 PROPERTIES

=over

=item message

=item id

The unique identifier of this document. Must be an URI.

=item href

An optional link to the document or to additional information.
Must be an URI but should be an URL.

=item message

An optional list of L<DAIA::Message> objects. You can set message(s) with
the C<message> accessor, with C<addMessage>, and with C<provideMessage>.

=item item

An optional list of L<DAIA::Item> objects with instances/copies/holdings 
of this document.

=back

=cut

our %PROPERTIES = (
    id      => { 
        filter => $DAIA::Object::COMMON_PROPERTIES{id}->{filter},
        default => sub { croak 'DAIA::Document->id is required' }
    },
    href    => $DAIA::Object::COMMON_PROPERTIES{href},
    message => $DAIA::Object::COMMON_PROPERTIES{message},
    item    => { type => 'DAIA::Item', repeatable => 1 }
);

1;

=head1 METHODS

DAIA::Document provides the default methods of L<DAIA::Object>, accessor 
methods for all of its properties and the following appender methods:

=head2 addMessage ( $message | ... )

Add a specified or a new L<DAIA::Message>.

=head2 addItem ( $item | %properties )

Add a specified or a new L<DAIA::Item>.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
