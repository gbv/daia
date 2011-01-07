package DAIA::Entity;

=head1 NAME

DAIA::Entity - Abstract base class of Department, Institution, Storage, and Limitation

=cut

use strict;
use Data::Validate::URI qw(is_uri is_web_uri);
use base 'DAIA::Object';
our $VERSION = '0.30';

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

=cut

our %PROPERTIES = (
    content => { 
        default => '', 
        filter => sub { defined $_[0] ? "$_[0]" : "" },
        predicate => 'http://purl.org/dc/terms/title'
    },
    href => {
        filter => sub { my $v = "$_[0]"; $v =~ s/^\s+|\s$//g; is_web_uri($v) ? $v : undef; },
        predicate => 'http://xmlns.com/foaf/0.1/page'
    },
    id => {
        filter => sub { my $v = "$_[0]"; $v =~ s/^\s+|\s$//g; is_uri($v) ? $v : undef; }
    }
);

sub _buildargs { 
    shift;
    return @_ % 2 ? (content => @_) : @_;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.

