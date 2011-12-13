use strict;
use warnings;
package DAIA::Document;
#ABSTRACT: Information about a single document

use base 'DAIA::Object';
use Carp 'croak';

our %PROPERTIES = (
    id      => { 
        filter => $DAIA::Object::COMMON_PROPERTIES{id}->{filter},
        default => sub { croak 'DAIA::Document->id is required' }
    },
    href    => $DAIA::Object::COMMON_PROPERTIES{href},
    message => $DAIA::Object::COMMON_PROPERTIES{message},
    error   => $DAIA::Object::COMMON_PROPERTIES{error},
    item    => { 
        type      => 'DAIA::Item', repeatable => 1,
    }
);

sub rdftype { 'http://purl.org/ontology/bibo/Document' }

sub rdfhash {
    my $self = shift;

    my $me = { 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
        type => 'uri', value => $self->rdftype
    }] };

    $me->{'http://xmlns.com/foaf/0.1/page'} = [{
        value => $self->{href}, type => "uri"
    }] if $self->{href};

    $me->{'http://purl.org/dc/terms/description'} = [
        map { $_->rdfhash } @{$self->{message}}
    ] if $self->{message};

    $me->{'http://purl.org/dc/terms/description'} = [
        map { $_->rdfhash } @{$self->{error}}
    ] if $self->{error};

    my $rdf = { };
    if ($self->{item}) {
        foreach my $item (@{$self->{item}}) {
            my $r = $item->rdfhash;
            $rdf->{$_} = $r->{$_} for keys %$r;
        }
        # TODO: exemplar / partial / broader
        # daia:extractOf / daia:partOf
        $me->{'http://purl.org/ontology/daia/exemplar'} = [ map {
            my $iri = $_->rdfuri;
            { value => $iri, type => ($iri =~ /^_:/) ? 'bnode' : 'uri' }
        } @{$self->{item}} ];
    }
    
    $rdf->{ $self->rdfuri } = $me;

    return $rdf;
}
 
1;

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

=head1 METHODS

DAIA::Document provides the default methods of L<DAIA::Object>, accessor 
methods for all of its properties and the following appender methods:

=head2 addMessage ( $message | ... )

Add a specified or a new L<DAIA::Message>.

=head2 addItem ( $item | %properties )

Add a specified or a new L<DAIA::Item>.
