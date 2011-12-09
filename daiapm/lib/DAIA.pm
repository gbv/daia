package DAIA;
#ABSTRACT: Document Availability Information API

use strict;

=head1 DESCRIPTION

The Document Availability Information API (DAIA) defines a model of information
about the current availability of documents, for instance in a library. DAIA
includes a specification of serializations in JSON, XML, and RDF. More details
can be found in the DAIA specification at L<http://purl.org/NET/DAIA> and at
the developer repository at L<http://daia.sourceforge.net/>.

This package provides Perl classes and functions to easily create and manage
DAIA information in any form. It can be used to quickly implement DAIA servers,
clients, and other programs that handle availability information of documents.

The most important concepts of the DAIA model are:

=over 4

=item B<documents>

These abstract works or editions are implemented as objects of class
L<DAIA::Document>.

=item B<items>

These particular copies of documents (physical or digital) are
implemented as objects of class L<DAIA::Item>.

=item B<services> and C<availability status>

A service is something that can be provided with an item. A particular
service has a particular availability status, that is implemented as
object of class L<DAIA::Available> or L<DAIA::Unavailable>.

=item B<availability status>

A boolean value and a service that indicates I<for what> an item is 
available or not available. Implemented as L<DAIA::Availability> with 
the subclasses L<DAIA::Available> and L<DAIA::Unavailable>.

=item B<responses>

A response contains information about the availability of documents at 
a given point in time, optionally at some specific institution. It is
implemented as object of class L<DAIA::Response>.

=back

Additional L<DAIA objects|/"DAIA OBJECTS"> include B<institutions>
(L<DAIA::Institution>), B<departments> (L<DAIA::Department>), 
storages (L<DAIA::Storage>), messages (L<DAIA::Message>), and 
errors (L<DAIA::Message>). All these objects provide standard methods
for creation, modification, and serialization. This package also
L<exports functions|/"FUNCTIONS"> as shorthand for object constructors,
for instance the following two result in the same:

  item( id => $id );
  DAIA::Item->new( id => $id );

=head1 SYNOPSIS

This package includes and installs the client program C<daia> to fetch,
validate and convert DAIA data (both command line and CGI). See also the
C<clients> directory for an XML Schema of DAIA/XML and an XSLT script to 
transform DAIA/XML to HTML.

=head2 A DAIA client

  use DAIA;  # or: use DAIA qw(parse);

  $daia = DAIA::parse( $url );
  $daia = DAIA::parse( file => $file );
  $daia = DAIA::parse( data => $string ); # $string must be Unicode

=head2 A DAIA server

  use DAIA;

  use CGI;
  my $id = CGI->new->param('id');

  my $r = response( institution => {
      href    => "http://example.com/your-institution's-homepage",
      content => "Your institution's name" 
  } );

  $r->addMessage("en" => "Not an URI: $id", errno => 1 )
      unless DAIA::is_uri($id);

  my @holdings = get_holding_information($id);      # your custom method

  if ( @holdings ) {
      my $doc = document( id => $id, href => "http://example.com/docs/$id" );
      foreach my $h ( @holdings ) {
          my $item = item();

          my %stor = get_holding_storage( $h );     # your custom method
          $item->storage( id => $stor{id}, href => $stor{href}, $stor{name} );

          $item->label( get_holding_label( $h ) );  # your custom method
          $item->href( get_holding_url( $h ) );     # your custom method

          # add availability services
          my @services;

          if ( get_holding_is_here( $h ) ) {          # your custom method
              push @services, available('presentation'), available('loan');
          } elsif( get_holding_is_not_here( $h ) ) {  # your custom method
              push @services, # expected to be back in 5 days
              unavailable( 'presentation', expected => 'P5D' ),
              unavailable( 'loan', expected => 'P5D' );
          } else {
             #  more cases (depending on the complexity of you application)
          }
          $item->add( @services );
      }
      $r->document( $doc );
  } else {
      $r->addMessage( "en" => "No holding information found for id $id" );
  }

  $r->serve( xslt => "http://path.to/daia.xsl" );

To run your script as CGI, you may have to enable CGI with C<Options +ExecCGI>
and C<AddHandler cgi-script .pl> in your Apache configuration or in C<.htaccess>.
Some more hints are L<listed below|/"DAIA Server hints">.

=cut

use base 'Exporter';
our %EXPORT_TAGS = (
    core => [qw(response document item available unavailable availability)],
    entities => [qw(institution department storage limitation)],
);
our @EXPORT_OK = qw(is_uri parse guess);
Exporter::export_ok_tags;
$EXPORT_TAGS{all} = [@EXPORT_OK, 'message', 'serve', 'error'];
Exporter::export_tags('all');

use Carp; # use Carp::Clan; # qw(^DAIA::);
use IO::File;
use LWP::Simple qw(get);
use XML::Simple; # only for parsing (may be changed)

use DAIA::Response;
use DAIA::Document;
use DAIA::Item;
use DAIA::Availability;
use DAIA::Available;
use DAIA::Unavailable;
use DAIA::Message;
use DAIA::Error;
use DAIA::Entity;
use DAIA::Institution;
use DAIA::Department;
use DAIA::Storage;
use DAIA::Limitation;

use Data::Validate::URI qw(is_uri);

=head1 FUNCTIONS

By default constructor functions are exported for all objects.
To disable exporting, include DAIA like this:

  use DAIA qw();       # do not export any functions
  use DAIA qw(serve);  # only export function 'serve'
  use DAIA qw(:core);  # only export core functions

You can select two groups, both are exported by default:

=over 4

=item C<:core>

C<response>, C<document>, C<item>, C<available>, C<unavailable>, 
C<availability>

=item C<:entities>

C<institution>, C<department>, C<storage>, C<limitation>

=back

Additional functions are C<message> and C<error> as object constructors,
and C<serve>. The other functions below are not exported by default.
You can call them as method or as function, for instance:

  DAIA->parse_xml( $xml );
  DAIA::parse_xml( $xml );

=cut

sub response     { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Response->new( @_ ) }
sub document     { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Document->new( @_ ) }
sub item         { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Item->new( @_ ) }
sub available    { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Available->new( @_ ) }
sub unavailable  { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Unavailable->new( @_ ) }
sub availability { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Availability->new( @_ ) }
sub message      { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Message->new( @_ ) }
sub institution  { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Institution->new( @_ ) }
sub department   { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Department->new( @_ ) }
sub storage      { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Storage->new( @_ ) }
sub limitation   { local $Carp::CarpLevel = $Carp::CarpLevel + 1; return DAIA::Limitation->new( @_ ) }

sub error { 
    local $Carp::CarpLevel = $Carp::CarpLevel + 1; 
    #my $errno = @_ ? shift : 0;
    #return DAIA::Message->new( @_ ? (@_, errno => $errno) : (errno => $errno) );
    return DAIA::Error->new( @_ );
}

=head2 serve( [ [ format => ] $format ] [ %options ] )

Calls the method method C<serve> of L<DAIA::Response> or another DAIA object
to serialize and send a response to STDOUT with appropriate HTTP headers. 
You can call it this way:

  serve( $response, @additionlArgs );  # as function
  $response->serve( @additionlArgs );  # as method

=cut

sub serve {
    local $Carp::CarpLevel = $Carp::CarpLevel + 1; 
    shift->serve( @_ );
}

=head2 parse ( $from [ %parameters ] )

Parse DAIA/XML or DAIA/JSON from a file or string. You can specify the source
as filename, string, or L<IO::Handle> object as first parameter or with the
named C<from> parameter. Alternatively you can either pass a filename or URL with
parameter C<file> or a string with parameter C<data>. If C<from> or C<file> is an
URL, its content will be fetched via HTTP. The C<format> parameter (C<json> or C<xml>)
is required unless the format can be detected automatically the following way:

=over

=item *

A scalar starting with C<E<lt>> and ending with C<E<gt>> is parsed as DAIA/XML.

=item *

A scalar starting with C<{> and ending with C<}> is parsed as DAIA/JSON.

=item *

A scalar ending with C<.xml> is is parsed as DAIA/XML file.

=item *

A scalar ending with C<.json> is parsed as DAIA/JSON file.

=item *

A scalar starting with C<http://> or C<https://> is used to fetch data via HTTP.
The resulting data is interpreted again as DAIA/XML or DAIA/JSON.

=back

Normally this function or method returns a single DAIA object. When parsing 
DAIA/XML it may also return a list of objects. It is recommended to always
expect a list unless you are absolutely sure that the result of parsing will
be a single DAIA object.

=cut

sub parse {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ($from, %param) = (@_ % 2) ? (@_) : (undef,@_);
    $from = $param{from} unless defined $from;
    $from = $param{data} unless defined $from;
    my $format = lc($param{format});
    my $file = $param{file};
    $file = $from if defined $from and $from =~ /^http(s)?:\/\//;
    if (not defined $file and defined $from and not defined $param{data}) {
        if( ref($from) eq 'GLOB' or UNIVERSAL::isa($from, 'IO::Handle')) {
            $file = $from;
        } elsif( $from eq '-' ) {
            $file = \*STDIN;
        } elsif( $from =~ /\.(xml|json)$/ ) {
            $file = $from ;
            $format = $1 unless $format;
        }
    }
    if ( $file ) {
        if ( $file =~ /^http(s)?:\/\// ) {
            $from = get($file) or croak "Failed to fetch $file via HTTP"; 
        } else {
            if ( ! (ref($file) eq 'GLOB' or UNIVERSAL::isa( $file, 'IO::Handle') ) ) {
                $file = do { IO::File->new($file, '<:utf8') or croak("Failed to open file $file") };
            }
            # Enable :utf8 layer unless it or some other encoding has already been enabled
            # foreach my $layer ( PerlIO::get_layers( $file ) ) {
            #    return if $layer =~ /^encoding|^utf8/;
            #}
            binmode $file, ':utf8';
            $from = do { local $/; <$file> };
        }
        croak "DAIA serialization is empty" unless $from;
    }

    croak "Missing source to parse from " unless defined $from;

    $format = guess($from) unless $format;

    my $value;
    my @objects;
    my $root = 'Response';

    if ( $format eq 'xml' ) {
        # do not look for filename (security!)
        if (defined $param{data} and guess($from) ne 'xml') {
            croak("XML is not well-formed (<...>)");
        }

        if (guess($from) eq 'xml') {
            utf8::encode($from);;
            #print "IS UTF8?". utf8::is_utf8($from) . "\n";
        }

        my $xml = eval { XMLin( $from, KeepRoot => 1, NSExpand => 1, KeyAttr => [ ] ); };
        $xml = daia_xml_roots($xml);

        croak $@ if $@;
        croak "XML does not contain DAIA elements" unless $xml;

        while (my ($root,$value) = each(%$xml)) {
            $root =~ s/{[^}]+}//;
            $root = ucfirst($root);
            $root = 'Response' if $root eq 'Daia';

            _filter_xml( $value ); # filter out all non DAIA elements and namespaces

            $value = [ $value ] unless ref($value) eq 'ARRAY';

            foreach my $v (@$value) {
                # TODO: croak of $root is not known!
                my $object = eval 'DAIA::'.$root.'->new( $v )';  ##no critic
                croak $@ if $@;
                push @objects, $object;
            }
        }

    } elsif ( $format eq 'json' ) {
        eval { $value = JSON->new->decode($from); };
        croak $@ if $@;

        if ( (keys %$value) == 1 ) {
            my ($k => $v) = %$value;
            if (not $k =~ /^(timestamp|message|institution|document)$/ and ref($v) eq 'HASH') {
                ($root, $value) = (ucfirst($k), $v);
            }
        }

        # outdated variants
        $root = "Response" if $root eq 'Daia';
        delete $value->{'xmlns:xsi'};

        delete $value->{schema} if $root eq 'Response'; # ignore schema attribute

        croak "JSON does not contain DAIA elements" unless $value;
        push @objects, eval('DAIA::'.$root.'->new( $value )');  ##no critic
        croak $@ if $@;

    } else {
        croak "Unknown DAIA serialization format $format";
    }

    return if not wantarray and @objects > 1;
    return wantarray ? @objects : $objects[0];
}

=head2 parse_xml( $xml )

Parse DAIA/XML from a file or string. The first parameter must be a 
filename, a string of XML, or a L<IO::Handle> object.

Parsing is more lax then the specification so it silently ignores 
elements and attributes in foreign namespaces. Returns either a DAIA 
object or croaks on uncoverable errors.

=cut

sub parse_xml {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    DAIA::parse( shift, format => 'xml', @_ );
}

=head2 parse_json( $json )

Parse DAIA/JSON from a file or string. The first parameter must be a 
filename, a string of XML, or a L<IO::Handle> object.

=cut

sub parse_json {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );    
    DAIA::parse( shift, format => 'json' );
}

=head2 guess ( $string )

Guess serialization format (DAIA/JSON or DAIA/XML) and return C<json>, C<xml> 
or the empty string.

=cut

sub guess {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );    
    my $data = shift;
    return '' unless $data;
    return 'xml' if $data =~ m{^\s*\<.*?\>\s*$}s;
    return 'json' if $data =~ m{^\s*\{.*?\}\s*$}s;
    return '';
}

=head2 is_uri ( $value )

Checks whether the value is a well-formed URI. This function is imported from
L<Data::Validate::URI> into the namespace of this package as C<DAIA::is_uri>.
On request the function can be exported into the default namespace.

=head1 DAIA OBJECTS

All objects (documents, items, availability status, institutions, departments,
limitations, storages, messages, errors) are implemented as subclass of
L<DAIA::Object>, which is just another Perl meta-class framework.
All objects have the following methods:

=head2 item

Constructs a new object.

=head2 add

Adds typed properties.

=head2 xml, struct, json, rdfhash

Returns several serialization forms.

=head2 serve ( [ [ format => ] $format | [ cgi => $CGI ] ] [ %more_options ] )

Serialize the object and send it to STDOUT (or to another stream) with the 
appropriate HTTP headers. This method is available for all DAIA objects but
mostly used to serve a L<DAIA::Response>. The serialized object must already
be encoded in UTF-8 (but it can contain Unicode strings).

The serialization format can be specified with the first parameter as
C<format> string (C<json> or C<xml>) or C<cgi> object. If no format is
given, it is searched for in the L<CGI> query parameters. The default 
format is C<xml>. Other possible options are:

=over

=item header

Print HTTP headers (default). Use C<header =E<gt> 0> to disable headers.

=head xmlheader

Print the XML header of XML format is used. Enabled by default.

=item xslt

Add a link to the given XSLT stylesheet if XML format is used.

=item pi

Add one or more processing instructions if XML format is used.

=item callback

Add this JavaScript callback function in JSON format. If no callback
function is specified, it is searched for in the CGI query parameters.
You can disable callback support by setting C<callback =E<gt> undef>.

=item to

Serialize to a given stream (L<IO::Handle>, GLOB, or string reference)
instead of STDOUT. You may also want to set C<exitif> if you use
this option.

=item exitif

By setting this method to a true value you make it to exit the program.
you provide a method, the method is called and the script exits if only
if the return value is true.

=back

=cut

#### internal methods (subject to be changed)

my $NSEXPDAIA    = qr/{http:\/\/(ws.gbv.de|purl.org\/ontology)\/daia\/}(.*)/;

# =head1 daia_xml_roots ( $xml )
#
# This internal method is passed a hash reference as parsed by L<XML::Simple>
# and traverses the XML tree to find the first DAIA element(s). It is needed
# if DAIA/XML is wrapped in other XML structures.
#
# =cut

sub daia_xml_roots {
    my $xml = shift; # hash reference
    my $out = { };

    return { } unless UNIVERSAL::isa($xml,'HASH');

    foreach my $key (keys %$xml) {
        my $value = $xml->{$key};

        if ( $key =~ /^{([^}]*)}(.*)/ and !($key =~ $NSEXPDAIA) ) {
            # non DAIA element
            my $children = UNIVERSAL::isa($value,'ARRAY') ? $value : [ $value ];
            @$children = grep {defined $_} map { daia_xml_roots($_) } @$children;
            foreach my $n (@$children) {
                while ( my ($k,$v) = each(%{$n}) ) {
                    next if $k =~ /^xmlns/;
                    $v = [$v] unless UNIVERSAL::isa($v,'ARRAY');
                    if ($out->{$k}) {
                        push @$v, (UNIVERSAL::isa($out->{$k},'ARRAY') ? 
                                @{$out->{$k}} : $out->{$k});
                    }
                    # filter out scalars
                    @$v = grep {ref($_)} @$v unless $k =~ $NSEXPDAIA;
                    if (@$v) {
                        $out->{$k} = (@$v > 1 ? $v : $v->[0]); 
                    }
                }
            }
        } else { # DAIA element or element without namespace
            $out->{$key} = $value;
        }
    }

    return $out;
}

# filter out non DAIA XML elements and 'xmlns' attributes
sub _filter_xml { 
    my $xml = shift;
    map { _filter_xml($_) } @$xml if ref($xml) eq 'ARRAY';
    return unless ref($xml) eq 'HASH';

    my (@del,%add);
    foreach my $key (keys %$xml) {
        if ($key =~ /^{([^}]*)}(.*)/) {
            my $local = $2;
            if ($1 =~ /^http:\/\/(ws.gbv.de|purl.org\/ontology)\/daia\/$/) {
                $xml->{$local} = $xml->{$key};
            }
            push @del, $key;
        } elsif ($key =~ /^xmlns/ or $key =~ /:/) {
            push @del, $key;
        }
    }

    # remove non-daia elements
    foreach (@del) { delete $xml->{$_}; }

    # recurse
    map { _filter_xml($xml->{$_}) } keys %$xml;
}

1;

=head1 DAIA Server hints

DAIA server scripts can be tested on command line by providing HTTP
parameters as C<key=value> pairs.

It is recommended to run a DAIA server via L<mod_perl> or FastCGI so
it does not need to be compiled each time it is run. For mod_perl you
simply put your script in a directory which C<PerlResponseHandler> has
been set for (for instance to L<Apache::Registry> or L<ModPerl::PerlRun>).

For FastCGI you need to install L<FCGI> and set the CGI handler to
L<AddHandler fcgid-script .pl> in C<.htaccess>. Your DAIA server must
consist of an initialization section and a response loop:

    #!/usr/bin/perl
    use DAIA;
    use CGI::Fast;
    
    # ...initialization section, which is executed only once ...
    
    while (my $q = new CGI::Fast) { # response loop
        my $id = $q->param('id');

        # ... create response ...

        $response->serve( cgi => $q, exitif => 0 );
    }

The C<serve> methods needs a C<cgi> or C<format> parameter and it is
been told not to exit the script. It is recommended to check every
given timespan whether the script has been modified and restart in
this case:

    #!/usr/bin/perl
    use DAIA;
    use CGI::Fast;
    
    my $started = time;
    my $thisscript = $0;
    my $lastmod = (stat($thisscript))[9] # mtime;
    
    sub restart {
        return 0 if time - $started < 10; # check every 10 seconds
            return 1 if (stat($thisscript))[9] > $lastmod;
    }
    
    while (my $q = new CGI::Fast) { # response loop

        # ... create response ...

        $response->serve( $q, exitif => \&restart } );
    }

=cut
