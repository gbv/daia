package DAIA;

=head1 NAME

DAIA - Document Availability Information API in Perl

=cut

use strict;
our $VERSION = '0.27';

=head1 DESCRIPTION

The Document Availability Information API (DAIA) defines a data model with 
serializations in JSON and XML to encode information about the current 
availability of documents. See L<http://purl.org/NET/DAIA> for a detailed
specification. This package provides Perl classes and functions to easily
create and manage DAIA information. It can be used to implement DAIA servers,
clients, and other programs that handle availability information.

The DAIA information objects as decriped in the DAIA specification are
directly mapped to Perl packages. In addition a couple of functions can
be exported if you prefer to handle DAIA data without much object-orientation.

=head1 SYNOPSIS

=head2 DAIA client

  #!/usr/bin/perl
  use DAIA;

  $daia = DAIA::parse( $url );          # parse from URL
  $daia = DAIA::parse( file => $file ); # parse from File

  # parse from string
  use Encode; # if incoming data is unencoded UTF-8
  $data = Encode::decode_utf8( $data ); # skip this if $data is just Unicode
  $daia = DAIA::parse( data => $string );

This package also includes and installs the command line and CGI client
L<daia> to fetch, validate and convert DAIA data. See also the C<clients>
directory for an XML Schema of DAIA/XML and an XSLT script to transform it
to HTML.

=head2 DAIA server

First an example of a DAIA server as CGI script. You need to implement all
C<get_...> methods to return meaningful values. Some more hints how
to run a DAIA Server below under under L<#DAIA Server hints>.

  #!/usr/bin/perl
  use DAIA qw(is_uri);
  use CGI;
  use utf8; # if source code containts UTF-8

  my $r = response( institution => {
          href    => "http://example.com/homepage.of.institution",
          content => "Name of the Institution" 
  } );

  my $id = CGI->new->param('id');
  $r->addMessage("en" => "Not an URI: $id", errno => 1 ) unless is_uri($id);
  my @holdings = get_holding_information($id);  # YOU need to implement this!

  if ( @holdings ) {
      my $doc = document( id => $id, href => "http://example.com/docs/$id" );
      foreach my $h ( @holdings ) {
          my $item = item();

          my %sto = get_holding_storage( $h );
          $item->storage( id => $sto{id}, href => $sto{href}, $sto{name} );

          my $label = get_holding_label( $h );
          $item->label( $label );

          my $url = get_holding_url( $h );
          $item->href( $url );

          # add availability services
          my @services;

          if ( get_holding_is_here( $h ) ) {
              push @services, available('presentation'), available('loan');
          } elsif( get_holding_is_not_here( $h ) ) {
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

In order to get your script run as CGI, you may have to enable CGI with 
C<Options +ExecCGI> and C<AddHandler cgi-script .pl> in your Apache
configuration or C<.htaccess>. 

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

use base 'Exporter';
our %EXPORT_TAGS = (
    core => [qw(response document item available unavailable availability)],
    entities => [qw(institution department storage limitation)],
);
our @EXPORT_OK = qw(is_uri);
Exporter::export_ok_tags;
$EXPORT_TAGS{all} = [@EXPORT_OK, 'message', 'serve', 'error'];
Exporter::export_tags('all');

use Carp::Clan; # qw(^DAIA::);
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
use DAIA::Entity;
use DAIA::Institution;
use DAIA::Department;
use DAIA::Storage;
use DAIA::Limitation;

use Data::Validate::URI qw(is_uri);

=head1 EXPORTED FUNCTIONS

If you prefer function calls in favor of constructor calls, this package  
providesfunctions for each DAIA class constructor. The functions are named  
by the object that they create but in lowercase - for instance C<response> 
for the L<DAIA::Response> object. The functions can be exported in groups. 
To disable exporting of the functions include DAIA like this: 

  use DAIA qw();      # do not export any functions
  use DAIA qw(serve); # only export function 'serve'

By default all functions are exported (group :all) which adds 13 functions 
to the default namespace! Alternatively you can specify the following groups:

=over 4

=item :core

Includes the functions C<response> (L<DAIA::Response>),
C<document> (L<DAIA::Document>), 
C<item> (L<DAIA::Item>),
C<available> (L<DAIA::Available>), 
C<unavailable> (L<DAIA::Unavailable>), and
C<availability> (L<DAIA::Availability>)

=item :entities

Includes the functions C<institution> (L<DAIA::Institution>),
C<department> (L<DAIA::department>),
C<storage> (L<DAIA::Storage>), and
C<limitation> (L<DAIA::Limitation>)

=back

The functions C<message>, C<error> and C<serve> are also exported by default.
See L<DAIA::Message> for the parameters of C<message> or C<error>.

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
    my $errno = @_ ? shift : 0;
    return DAIA::Message->new( @_ ? (@_, errno => $errno) : (errno => $errno) );
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

=head1 ADDITIONAL FUNCTIONS

The following functions are not exportted but you can call both them as 
function and as method:

  DAIA->parse_xml( $xml );
  DAIA::parse_xml( $xml );

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

=head2 parse ( $from [ %parameters ] )

Parse DAIA/XML or DAIA/JSON from a file or string. You can specify the source
as filename, string, or L<IO::Handle> object as first parameter or with the
named C<from> parameter. Alternatively you can either pass a filename or URL with
parameter C<file> or a string with parameter C<data>. If the filename is an URL,
its content will be fetched via HTTP. The C<format> parameter (C<json> or C<xml>)
is required unless the format can be detected automatically the following way:

=over

=item *

A scalar starting with C<E<lt>> and ending with C<E<gt>> is parsed as DAIA/XML.

=item *

A scalar starting with C<{> and ending with C<}> is parsed as DAIA/JSON.

=item *

A scalar ending with C<.json> is parsed as DAIA/JSON.

=item *

A scalar ending with C<.xml> is is parsed as DAIA/XML.

=back

=cut

sub parse {
    shift if UNIVERSAL::isa( $_[0], __PACKAGE__ );
    my ($from, %param) = (@_ % 2) ? (@_) : (undef,@_);
    $from = $param{from} unless defined $from;
    $from = $param{data} unless defined $from;
    my $format = lc($param{format});
    my $file = $param{file};
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

        ($root, $value) = %$xml;
        $root =~ s/{[^}]+}//;
        $root = ucfirst($root);
        $root = 'Response' if $root eq 'Daia';

        _filter_xml( $value ); # filter out all non DAIA elements and namespaces

        # TODO: $value may contain multiple daia elements (wantarray?)!

    } elsif ( $format eq 'json' ) {
        eval { $value = JSON->new->decode($from); };
        croak $@ if $@;
        if ( (keys %$value) == 1 ) {
            my ($k => $v) = %$value;
            if (not $k =~ /^(timestamp|message|institution|document)$/ and ref($v) eq 'HASH') {
                ($root, $value) = (ucfirst($k), $v);
            }
        }
        delete $value->{schema} if $root eq 'Response'; # ignore schema attribute
    } else {
        croak "Unknown DAIA serialization format $format";
    }

    croak "DAIA serialization is empty (maybe you forgot the XML namespace?)" unless $value;
    my $object = eval 'DAIA::'.$root.'->new( $value )';  ##no critic
    croak $@ if $@;

    return $object;    
}

=head2 guess ( $string )

Guess serialization format (DAIA/JSON or DAIA/XML) and return C<json>, C<xml> 
or the empty string.

=cut

sub guess {
    my $data = shift;
    return '' unless $data;
    return 'xml' if $data =~ m{^\s*\<.*?\>\s*$}s;
    return 'json' if $data =~ m{^\s*\{.*?\}\s*$}s;
    return '';
}

=head2 is_uri ( $value )

Checks whether the value is a well-formed URI. This function is imported from
L<Data::Validate::URI> into the namespace of this package as C<DAIA::is_uri>
and can be exported into the default namespace on request.

=cut

#### internal methods (subject to be changed)

my $NSEXPDAIA = qr/{http:\/\/(ws.gbv.de|purl.org\/ontology)\/daia\/}(.*)/;

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
                    @$v = grep {ref($_)} @$v;
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

=head1 SEE ALSO

Please report bugs and feature requests via L<https://rt.cpan.org/Public/Dist/Display.html?Name=DAIA>.
The classes of this package are implemented using L<DAIA::Object> which is just another
Perl meta-class framework.

The current developer version of this package together with more DAIA
implementations in other programming languages is availabe in a project
at Sourceforge: L<http://sourceforge.net/projects/daia/>. Feel free to
contribute!

A specification of DAIA can be found at L<http://purl.org/NET/DAIA>.

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
