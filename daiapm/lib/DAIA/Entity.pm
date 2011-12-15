use strict;
use warnings;
package DAIA::Entity;
#ABSTRACT: Abstract base class of Department, Institution, Storage, and Limitation

use Data::Validate::URI qw(is_uri is_web_uri);
use base 'DAIA::Object';

our %PROPERTIES = (
    content => { 
        default => '', 
        filter => sub { defined $_[0] ? "$_[0]" : "" },
    },
    href => {
        filter => sub { my $v = "$_[0]"; $v =~ s/^\s+|\s$//g; is_web_uri($v) ? $v : undef; },
    },
    id => {
        filter => sub { my $v = "$_[0]"; $v =~ s/^\s+|\s$//g; is_uri($v) ? $v : undef; }
    }
);

sub _buildargs { 
    shift;
    return @_ % 2 ? (content => @_) : @_;
}

sub rdfhash {
    my $self = shift;

    # plain literal
    return { type => 'literal', value => $self->{content} } 
        unless $self->{id} or $self->{href};

    my $me = { 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
        type => 'uri', value => $self->rdftype
    }] } if $self->rdftype ;

    $me->{'http://www.w3.org/2000/01/rdf-schema#label'} = [{
        value => $self->{content}, type => 'literal'
    }] if $self->{content};

    $me->{'http://xmlns.com/foaf/0.1/page'} = [{
        value => $self->{href}, type => 'uri'
    }] if $self->{href};
    
    return { $self->rdfuri => $me };
}

1;

=head1 PROPERTIES

=over

=item id

A persistent identifier for the entity (optional). This must be an URI 
(C<xs:anyURI>) and it is mapped to the object's resource URI in RDF.

=item content

A simple name describing the entity. In RDF this is mapped to the Dublin Core 
property 'title' (L<http://purl.org/dc/terms/title>). The empty string, that 
is the default, is treated equal to a non-existing content element.

=item href

An URL linking to the entity (optional). In RDF this is mapped to the FAOF
property 'page' (L<http://xmlns.com/foaf/0.1/page>).

=back
