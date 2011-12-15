use strict;
use warnings;
package DAIA::Response;
#ABSTRACT: DAIA information root element

use base 'DAIA::Object';

use POSIX qw(strftime);

our %PROPERTIES = (
    version => {
        default   => '0.5', 
        filter    => sub { '0.5' }
    },
    timestamp => {
        default   => sub { strftime("%Y-%m-%dT%H:%M:%SZ", gmtime); },
        filter    => sub { $_[0] }, # TODO: check format 
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

sub rdfhash {
    my $self = shift;

    my $me = {
        'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [{
            type => 'uri', value => 'http://purl.org/ontology/daia/Response'
        }]
    };
    $me->{'http://purl.org/ontology/daia/timestamp'} = [{
            type => 'literal', value => $self->{timestamp},
            datatype => 'http://www.w3c.org/2001/XMLSchema#dateTime'
    }];# if $self->{timestamp};

    $me->{'http://purl.org/dc/terms/description'} = [
        map { $_->rdfhash } @{$self->{message}}
    ] if $self->{message};

    my $rdf = { $self->rdfuri => $me };
    my $inst = $self->{institution};
    my @doc  = @{$self->{document}} if $self->{document};

    my @see = grep { defined $_ } $inst, @doc;
    foreach my $s (@see) {
        my $r = $s->rdfhash; # TODO: pass (institution => $inst->rdfuri)
        $rdf->{$_} = $r->{$_} for keys %$r;
    }

    $me->{'http://www.w3.org/2000/01/rdf-schema#seeAlso'} = [
        map { { type => 'uri', value => $_->rdfuri } } @see
    ] if @see;

    foreach my $doc (@doc) {
        $rdf->{ $doc->rdfuri }->{'http://purl.org/ontology/daia/collectedBy'} = [{
            type => "uri", value => $inst->rdfuri
        }];
    }

    # TODO: add connections
    # department <- subOrgOf / parOf institution
    # service <- providedBy institution
    
    # # item <- heldBy
    # TODO: if no inst given, try to use department instead
    if ($self->document and $self->institution) {
        my @items = map { $_->item ? @{$_->{item}} : () } @{$self->{document}};
        my $by = $self->{institution}->rdfuri;
        $by = { value => $by, type => ($by =~ /^_:/) ? 'bnode' : 'uri' };
        foreach my $item (@items) {
            $rdf->{ $item->rdfuri }->{'http://purl.org/ontology/daia/heldBy'} ||= [$by];
        }
    }

    # delete $rdf->{ $self->rdfuri };

    return $rdf;
}

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

1;

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
