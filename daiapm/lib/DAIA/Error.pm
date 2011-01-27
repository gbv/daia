package DAIA::Error;

=head1 NAME

DAIA::Error - An error message

=cut

use strict;
use base 'DAIA::Message';
our $VERSION = '0.30';

=head1 DESCRIPTION

Error messages are special kind of L<DAIA::Message> objects, that have
an error number (C<errno>). Error numbers are integer values. If you set
the error number some non-number or C<undef>, the error message becomes
a normal message object.

=head1 SYNOPSIS

  $err = error() # errno = 0
  $err = error( $errno [, $lang => $content ] ) 
  $err = error( $errno, $content [, lang => $lang ] )
  $err = error( $content [, lang => $lang ], errno => $errno )
  $err = error( $lang => $content, errno => $errno )
  $err = error( $lang => $content, $errno )

  $err->errno( 42 );

=head PROPERTIES

=over

=item content

The message as Unicode string. This may also be the empty string.

=item lang

The language of the error message string.

=item errno

An integer value error code. The default value is zero.

=back

=cut

our %PROPERTIES = (
    %DAIA::Message::PROPERTIES,
    content => { 
        default => '', 
        filter => sub { "$_[0]" },  # stringify everything
        predicate => 'http://purl.org/dc/terms/description',
        rdflang => 'lang'
    },
    errno => { 
        default => 0,
        filter => sub { 
            $_[0] =~ m/^-?\d+$/ ? $_[0] : 0  
        }, 
        rdftype => 'http://www.w3c.org/2001/XMLSchema#integer',
        predicate => 'http://purl.org/dc/terms/identifier'
    },
);

# called by the constructor
sub _buildargs {
    my $self = shift;

    my $errno = shift if (@_ and $_[0] =~ /^-?\d+$/);

    my %args; # = (DAIA::Message::_buildargs( undef, @_ ));
    if ( @_ % 2 ) {  # content as first parameter
        my ($content, %p) = @_;
        if ( @_ == 3 and not defined $PROPERTIES{$_[1]} ) {
            %args = ( lang => $_[0], content => $_[1] );
        } else {
            %args = ( content => $content, %p );
        }
    } elsif ( defined $_[0] and not defined $PROPERTIES{$_[0]} 
              and DAIA::Message::is_language_tag($_[0]) ) {
        my ($lang, $content, %p) = @_;
        %args = ( lang => $lang, content => $content, %p );
    } else {
        %args = @_;
    }

    $args{errno} = $errno if defined $errno;

    return (%args);
}

=head1
sub rdfhash {
    my $self = shift;
    my $rdf = { 'http://www.w3.org/1999/02/22-rdf-syntax-ns#type' => [ {
        'value' => $DAIA::Object::RDFNAMESPACE.'Error', 'type' => 'uri' }
    ], 'dct:identifier' => [ {
         value => $self->errno, type => 'literal'
    ] } };
    'dct:description'
    

    return { $self->rdfuri => $rdf };
}
=cut

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
