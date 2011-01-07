package DAIA::Response;

=head1 NAME

DAIA::Response - DAIA information root element

=cut

use strict;
use base 'DAIA::Object';
our $VERSION = '0.30';
use POSIX qw(strftime);

=head1 SYNOPSIS

  $r = response( # or DAIA::Response->new( 
      institution => $institution,
      message => [ $msg1, $msg2 ],
      document => [ $document ]
  );

  $r->institution( $institution );
  $institution = $r->institution;

  my $documents = $r->document;

  $r->timestamp;
  $r->version;

=head1 PROPERTIES

=over

=item document

a list of L<DAIA::Document> objects. You can get/set document(s) with 
the C<document> accessor, with C<addDocument>, and with C<provideDocument>.

=item institution

a L<DAIA::Institution> that grants or knows about the documents, 
items services and availabilities described in this response.

=item message

a list of L<DAIA::Message> objects. You can set message(s) with the 
C<message> accessor, with C<addMessage>, and with C<provideMessage>.

=item timestamp

date and time of the response information. It must match the pattern of
C<xs:dateTime> and is set to the current date and time on initialization.

=back

The additional read-only attribute B<version> gives the current version of
DAIA format.

=cut

our %PROPERTIES = (
    version => {
        default   => '0.5', 
        filter    => sub { '0.5' }
    },
    timestamp => {
        default   => sub { strftime("%Y-%m-%dT%H:%M:%SZ", gmtime); },
        filter    => sub { $_[0] }, # TODO: check format 
        predicate => $DAIA::Object::RDFNAMESPACE.'timestamp',
        rdftype   => 'http://www.w3c.org/2001/XMLSchema#dateTime'
    },
    message => $DAIA::Object::COMMON_PROPERTIES{message},
    institution => { 
        type => 'DAIA::Institution',
    },
    document => { 
        type => 'DAIA::Document',
        repeatable => 1
    },
);

1;

=head1 METHODS

DAIA::Response provides the default methods of L<DAIA::Object> and accessor 
methods for all of its properties. To serialize and send a HTTP response, you
can use the method C<serve>, which is accessible for all DAIA objects.

=head2 serve ( [ [ format => ] $format ] [ %options ] )

Serialize the response and send it to STDOUT with the appropriate HTTP headers.
This method is mostly used to serve DAIA::Response objects, but it is also 
available for other DAIA objects. See L<DAIA::Object/serve> for a description.

In most cases, a simple call of C<$response-E<gt>serve> will be the last
statement of a DAIA server implementation.

=head2 check_valid_id ( $id )

Check whether a valid identifier has been provided. If not, this methods 
appends an error message ("please provide a document id" or "document id
... is no valid URI") and returns undef.

=cut

sub check_valid_id {
    my $self = shift;
    my $id = shift; # TODO: take from CGI object, if not given

    if ( ! defined $id ) {
        $self->addMessage( "en" => "please provide a document id!", errno => 1 );
    } elsif ( ! DAIA::is_uri( $id ) ) {
        $id = " $id";
        $id = (substr($id,0,32) . '...') if (length($id) > 32);
        $self->addMessage( "en" => "document id$id is no valid URI!", errno => 2 );
    } else {
        return $id;
    }

    return undef;
}

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
