use strict;
use warnings;
package DAIA::Object;
#ABSTRACT: Abstract base class of all DAIA classes

use strict;
use Carp::Clan;
use CGI; # TODO: allow other kind of CGI
use Data::Validate::URI qw(is_uri is_web_uri);
use IO::Scalar;
use Scalar::Util qw(refaddr);
use UNIVERSAL 'isa';
use JSON;

our $AUTOLOAD;
our @HIDDEN_PROPERTIES = 
    qw(to format xmlns cgi header xmlheader xslt pi callback exitif noutf8);

=head1 DESCRIPTION

This package implements just another Perl meta-class framework. Just
ignore it unless you have a clue what "meta-class framework" could 
mean. Some concepts are borrowed from the mighty L<Moose> object system
but this framework is much smaller. Maybe you should better have a look 
at Moose and stop reading now.

In a nutshell C<DAIA::Object> handles all method calls via AUTOLOAD.
Each derived package must provide a C<%PROPERTIES> hash that defines
an object's attributes. Each property is defined by a hash that must
either contain a C<type> value pointing to a class name (typed property),
or a C<filter> value containing a plain value, or a filter method 
(untyped property).

=head1 METHDOS

=head2 new ( ..attributes... )

Constructs a new DAIA object of the derived type. Unknown properties are 
ignored. In addition the following special properties are stored as hidden
properties, that will not be copied to other objects, but only used for 
serializing the object: C<to>, C<format>, C<cgi>, C<header>, C<xmlheader>, 
C<xmlns>, C<xslt>, C<pi>, C<callback>, C<exitif>.

=cut

sub new {
    my $class = shift;
    my $self = bless { }, $class;

    my %hash;
    if ( @_ == 1 and ref($_[0]) eq 'HASH' ) {
        %hash = %{$_[0]};
    } elsif ( @_ == 1 and ref($_[0]) eq $class ) {
        %hash = %{$_[0]->struct}; # copy constructor
    } else {
        %hash = $self->_buildargs(@_);
    }

    # abstract class handling
    if ( $class eq 'DAIA::Availability' ) {
        croak "Availability status missing" unless exists $hash{status};
        $self->status( $hash{status} );
        delete $hash{status};
        $class = ref($self);
    }

    my %hidden;
    foreach ( @HIDDEN_PROPERTIES ) {
        next unless exists $hash{$_};
        $hidden{$_} = $hash{$_};
        delete $hash{$_};
    }
    $self->{_hidden} = \%hidden if %hidden;

    no strict 'refs'; ##no critic
    my $PROPERTIES = \%{$class."::PROPERTIES"};
    foreach my $property (keys %{$PROPERTIES}) {
        $self->$property( undef ) unless exists $hash{$property};
    }

    foreach my $property (keys %hash) {
        $self->$property( $hash{$property} );
    }

    #use Data::Dumper; print Dumper($self)."\n";
    return $self;
}

=head2 add ( ... )

Adds typed properties to an object.

=cut

sub add {
    my $self = shift;

    #print "APPEND: " . ref($self) . "\n";

    foreach my $value (@_) {
        next unless defined $value; # ignore undefined values

        #print "- " . ref($value) . "\n";

        croak "Cannot add $value to " . ref($self) 
            unless ref($value) =~ /^DAIA::([A-Z][a-z]+)$/;
        my $property = lc($1);
    
        #no strict 'refs';
        #my $PROPERTIES = \%{$class."::PROPERTIES"};
        
        # repeatable
        if ( ref($self->{$property}) eq 'ARRAY' ) {
            push @{$self->{$property}}, $value;
        } else {
            $self->$property( $value );
        }
    }
}

=head2 Serialization methods

A DAIA object can be serialized by the following methods:

=head3 xml ( [ xmlns => 0|1 ] [ xslt => $xslt ] [ header => 0|1 ] [ pi => $pi ] )

Returns the object in DAIA/XML. With the C<xmlns> as parameter you can 
specify that a namespace declaration is added (disabled by default 
unless you enable xslt or header). With C<xslt> you can add an XSLT 
processing instruction and with C<pi> any other processing instructions.
If you enable C<header>, an XML-header is prepended.

All TODO

=cut

sub xml {
    my ($self, %param) = @_;
    $self->_hidden_prop( \%param );

    my $xmlns = $param{xmlns} || ($param{xslt} or $param{header});
    my $pi = $param{pi} || [ ];
    $pi = [$pi] unless isa($pi,'ARRAY');

    push @$pi, 'xml-stylesheet type="text/xsl" href="' . xml_escape_value($param{xslt}) . '"'
        if $param{xslt};
    @$pi = map { $_ =~ /^<\?.*\?>$/ ? "$_\n" : "<?$_?>\n" } @$pi;

    my $name = lc(ref($self)); 
    $name =~ s/^daia:://;
    $name = 'daia' if $name eq 'response';

    my $struct = $self->struct;
    $struct->{xmlns} = "http://ws.gbv.de/daia/" if $xmlns;
    my $xml = xml_write( $name, $struct, 0 );
    delete $struct->{xmlns} if $xmlns;

    $xml = join('', @$pi ) . $xml;
    $xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n$xml" if $param{header};

    return $xml;
}

=head3 struct ( [ $json ] )

Returns the object as unblessed Perl data structure. If you specify a true parameter,
only boolean values will be kept as blessed C<JSON::Boolean> objects (see L<JSON>).
The C<label> property will only be included unless it is not the empty string.

=cut

sub struct {
    my ($self, $json) = @_;
    my $struct = { };
    foreach my $property (keys %$self) {
        next unless $property =~ /^[a-z]+$/;
        if (ref $self->{$property} eq 'ARRAY') {
            $struct->{$property} = [ map { $_->struct($json) } @{$self->{$property}} ];
        } elsif ( UNIVERSAL::isa( $self->{$property}, "DAIA::Object" ) ) {
            $struct->{$property} = $self->{$property}->struct;
        } elsif ( UNIVERSAL::isa( $self->{$property}, 'JSON::Boolean' ) and not $json ) {
            $struct->{$property} = $self->{$property} ? 'true' : 'false';
        } elsif( $property eq 'label' and $self->{$property} eq '' ) {
            # ignore empty string label
        } else {
            $struct->{$property} = $self->{$property};
        }
    }
    return $struct;
}

=head3 json ( [ $callback ] )

Returns the object in DAIA/JSON, optionally wrapped by a JavaScript callback 
function call. Invalid callback names are ignored without warning. The hidden
property C<callback> is used if no callback parameter is provided, use C<undef>
to fully disable the callback.

=cut

sub json {
    my ($self, $callback) = @_;
    $callback = $self->{_hidden}->{callback} 
        if @_ < 2 and $self->{_hidden} and exists $self->{_hidden}->{callback};
    my $json = JSON->new->pretty->encode( $self->struct(1) );
    if ( defined $callback and $callback =~ /^[a-z][a-z0-9._\[\]]*$/i ) {
        return "$callback($json);"
    } else {
        return $json;
    }
}

=head3 rdfhash 

Returns the object as hashref representing an RDF structure. This hashref 
structure is compatible with RDF/JSON and with the ARC2 library for PHP
You can directly pass it the method C<add_hashref> of L<RDF::Trine::Model>.

=cut

sub rdfhash {
    return { };
}

=head2 serve

Serialize the object and send it to STDOUT with the appropriate HTTP headers.
See L<DAIA/"DAIA OBJECTS"> for details.

=cut

sub serve {
    my $self = shift;
    my $first = shift if @_ % 2;
    my (%attr) = @_;
    $self->_hidden_prop( \%attr );

    if ( UNIVERSAL::isa( $first,'CGI' ) ) {
        $attr{cgi} = $first;
    } elsif (defined $first) {
        $attr{format} = $first;
    }
    if (not exists $attr{'format'}) {
        $attr{cgi} = CGI->new unless $attr{cgi};
        $attr{format} = $attr{'cgi'}->param('format');
    }
    $attr{exitif} = 0 unless exists $attr{exitif};

    my $format = lc($attr{format});
    my $header = defined $attr{header} ? $attr{header} : 1;
    my $xslt = $attr{xslt};
    my $pi = $attr{pi};
    my $xmlheader = defined $attr{xmlheader} ? $attr{xmlheader} : 1;
    my $to = $attr{to} || \*STDOUT;
    if ( ref($to) eq 'SCALAR' ) {
        $$to = "";
        $to = IO::Scalar->new( $to );
    }
    #_enable_utf8_layer($to); # TODO: this does not work
    if (! $attr{noutf8} ) {
        eval{ binmode $to, ':encoding(UTF-8)'  };
    }

    if ( defined $format and $format eq 'json' ) {
        print $to CGI::header( '-type' => "application/javascript; charset=utf-8" ) if $header;
        if (not exists $attr{callback}) {
            $attr{cgi} = CGI->new unless $attr{cgi};
            $attr{callback} = $attr{cgi}->param('callback');
        }
        print $to $self->json( $attr{callback} );
    } else {
        print $to CGI::header( -type => "application/xml; charset=utf-8" ) if $header;
        my $xml = $self->xml( xmlns => 1, header => 1, xslt => $xslt, pi => $pi, header => $xmlheader );
        print $to $xml."\n";
    }

    $attr{'exitif'} = $attr{'exitif'}() if ref($attr{'exitif'}) eq 'CODE';
    exit if $attr{'exitif'};
}

=head2 rdfuri

Returns the URI of this object, which is either an URI (the C<id> property),
or a blank node identifier, that starts with "C<_:>".

=cut

sub rdfuri {
     my $self = shift;
     return $self->{id} if $self->{id};
     my $id = lc(ref($self)).refaddr($self);
     $id =~ s/.*::/_:/;
     return $id;
}

sub rdftype { }

=head1 INTERNAL METHODS

The following methods are only used internally; don't directly
call or modify them unless you want to damage data integrity or 
to fix a bug!

=cut

=head2 AUTOLOAD

Called if an unknown method is called. Almost all method calls go through
this magic method. Thanks, AUTOLOAD, thanks Perl.

=cut

sub AUTOLOAD {
    my $self = shift;
    my $class = ref($self) or croak "$self is not an object";

    my $method = $AUTOLOAD;
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';   

    my $property = $method;
    $property = lc($2) if $property =~ /^(add|provide)([A-Z][a-z]+)$/;

    no strict 'refs'; ##no critic
    my $PROPERTIES = \%{$class."::PROPERTIES"};

    croak "Method $class->$method ($property) does not exist"
        unless exists $PROPERTIES->{$property};

    my $opt = $PROPERTIES->{$property};

    if ( $method =~ /^add/ ) {
        croak "$class->$property is not repeatable or has no type"
            unless $opt->{repeatable} and $opt->{type};
        my $value = $_[0];
        if ( not UNIVERSAL::isa( $_[0], $opt->{type} ) ) {
          $value = eval $opt->{type}."->new( \@_ )"; ##no critic
          croak $@ if $@;
        }
        return $self->add( $value );
    } elsif( $method =~ /^provide/ ) { # set only if not set
        if ( defined $self->{$property} ) {
            # getter
            return $opt->{repeatable} ? @{$self->{$property} || []} : $self->{$property}
        } else {
            return eval "\$self->$property(\@_)";  ##no critic
        }
    }

    # called as getter
    return $opt->{repeatable} ? @{$self->{$property} || []} : $self->{$property}
        if ( @_ == 0 );

    my $value = $_[0];

    # called as clearer (may imply setting the default value)
    if (not defined $value or (ref($value) eq 'ARRAY' and @{$value} == 0)) {
        if ( exists $opt->{default} ) {
            $value = ref($opt->{default}) eq 'CODE' 
                   ? $opt->{default}() : $opt->{default};
        } 
        if ( defined $value ) {  
            $self->{$property} = $value;
        } else {
            delete $self->{$property} if exists $self->{$property};
        }
        return;
    }

    if ( $opt->{type} ) {
        # set one or more typed values

        # arguments must be either an array ref or a list of types or a simple list
        my @args;

        if ( ref($_[0]) eq 'ARRAY' ) {
            croak "too many arguments" if @_ > 1;
            @args = @{$_[0]};
        } elsif ( UNIVERSAL::isa( $_[0], $opt->{type} ) ) {
            # treat ( $obj, ... ) as ( [ $obj, ... ] )
            @args = @_;
        } else {
            @args = ( [ @_ ] ); # one element
        }

        croak "$class->$property is not repeatable"
            if ( @args > 1 and not $opt->{repeatable});

        my @values = map {
            my $v;
            if ( ref($_) eq 'ARRAY' ) {
                $v = eval $opt->{type}.'->new( @{$_} )';  ##no critic
                croak $@ if $@;
            } elsif ( UNIVERSAL::isa( $_, $opt->{type} ) ) {
                $v = $_;
            } else {
                $v = eval $opt->{type}.'->new( $_ )';  ##no critic
                croak $@ if $@;
            }
            $v;
        } @args;

        $self->{$property} = $opt->{repeatable} ? \@values : $values[0];

    } else { 
        # set an untyped value (never repeatable, stringified unless filtered)
        if( $opt->{fixed} ) {
            $value = $opt->{fixed};
        } elsif( $opt->{filter} ) {
            $value = $opt->{filter}( @_ );
            croak "$class->$property did not pass value constraint: " . join(',',@_)
                unless defined $value;
        } else {
            $value = "$value";
        }

        $self->{$property} = $value;
    }

    $self; # if called as setter, return the object for chaining
}

=head2 xml_write ( $roottag, $content, $level )

Simple, adopted XML::Simple::XMLOut replacement with support of element order 
and special treatment of C<label> elements.

=cut

sub xml_write {
    my ($name, $struct, $level) = @_;

    my $indent = ('  ' x $level);
    my $tag = "$indent<$name";

    my $content = '';
    if (defined $struct->{content}) {
        $content = $struct->{content};
        delete $struct->{content};
    }

    my @attr = grep { ! ref($struct->{$_}) and $_ ne 'label' } keys %$struct;
    @attr = map { "$_=\"".xml_escape_value($struct->{$_}).'"' } @attr;
    $tag .= " " . join(" ", @attr) if @attr;

    # get the right order
    my @order = qw(message institution document label department storage available unavailable);
    my @children = grep { defined $struct->{$_} } @order;
    my %has = map { $_ => 1 } @children;
    # append additional children
    push @children, grep { ref($struct->{$_}) and not $has{$_} } keys %$struct;

    my @lines;
    if (@children) {
        push @lines, "$tag>";
        foreach my $k (@children) {
            $k =~ s/^\d//;
            if ( $k eq 'label' ) {
                push @lines, "$indent  <label>".xml_escape_value($struct->{label})."</label>";
            } elsif ( ref($struct->{$k}) eq 'HASH' ) {
                push @lines, xml_write($k, $struct->{$k}, $level+1);
            } elsif ( ref($struct->{$k}) eq 'ARRAY' ) {
                foreach my $v (@{$struct->{$k}}) {
                    push @lines, xml_write($k, $v, $level+1);
                }
            }
        }
        push @lines, "$indent</$name>";
    } else {
        if ( $content ne '' ) {
          push @lines, "$tag>" . xml_escape_value($content) . "</$name>";
        } else {
          push @lines, "$tag />";
        }
    }
    
    return join("\n", @lines);
}

=head2 xml_escape_value ( $string )

Escape special XML characters.

=cut

sub xml_escape_value {
    my($data) = @_;
    return '' unless defined($data);
    $data =~ s/&/&amp;/sg;
    $data =~ s/</&lt;/sg;
    $data =~ s/>/&gt;/sg;
    $data =~ s/"/&quot;/sg;
    return $data;
}

=head2 _buildargs

Returns a property-value hash of constructor parameters.

=cut

sub _buildargs {
    shift; 
    croak "uneven parameter list" if (@_ % 2);
    @_; 
};

=head2 _hidden_prop ( $hashref )

Enrich a hash with hidden properties.

=cut

sub _hidden_prop {
    my $self = shift;
    return unless $self->{_hidden};

    my $hashref = shift;
    foreach ( @HIDDEN_PROPERTIES ) {
        next if exists $hashref->{$_} or not exists $self->{_hidden}->{$_};
        $hashref->{$_} = $self->{_hidden}->{$_};
    }
}

=head2 _enable_utf8_layer

Enable :encoding(UTF-8) layer for a given filehandle unless it or some
other encoding has already been enabled.

=cut

sub _enable_utf8_layer {
    my $fh = shift;
    return unless eval{ can($fh, 'binmode'); };
    foreach my $layer ( PerlIO::get_layers( $fh ) ) {
        return if $layer =~ /^encoding|^utf8/;
    }
    binmode $fh, ':encoding(UTF-8)';
}


our %COMMON_PROPERTIES =( 
    id => {
        filter => sub { my $v = "$_[0]"; $v =~ s/^\s+|\s$//g; is_uri($v) ? $v : undef; }
    },
#    href => {
#        filter => sub { my $v = "$_[0]"; $v =~ s/^\s+|\s$//g; is_web_uri($v) ? $v : undef; }
#    },
    href => { 
        filter => sub { my $v = "$_[0]"; is_web_uri($v) ? $v : undef; },
        predicate => 'http://xmlns.com/foaf/0.1/page',
        rdftype => 'resource'
    },
    message => { 
        type => 'DAIA::Message',
        repeatable => 1,
        predicate => 'http://purl.org/dc/terms/description',
    },
);

1;
