package DAIA::Document;
#ABSTRACT: Information about a single document

use strict;
use base 'DAIA::Object';
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
    rdftype => 'http://purl.org/ontology/bibo/Document',
    href    => $DAIA::Object::COMMON_PROPERTIES{href},
    message => $DAIA::Object::COMMON_PROPERTIES{message},
    error   => $DAIA::Object::COMMON_PROPERTIES{error},
    item    => { 
        type      => 'DAIA::Item', repeatable => 1,
        predicate => $DAIA::Object::RDFNAMESPACE.'exemplar', # TODO: also allow broader/narrower
    }
);

1;

=head1 METHODS

DAIA::Document provides the default methods of L<DAIA::Object>, accessor 
methods for all of its properties and the following appender methods:

=head2 addMessage ( $message | ... )

Add a specified or a new L<DAIA::Message>.

=head2 addItem ( $item | %properties )

Add a specified or a new L<DAIA::Item>.
