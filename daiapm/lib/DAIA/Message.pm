package DAIA::Message;

=head1 NAME

DAIA::Message - An optional information text or error message

=cut

use strict;
use base 'DAIA::Object';
our $VERSION = '0.25';

=head1 DESCRIPTION

Messages can occurr as property of L<DAIA::Response>, L<DAIA::Document>,
L<DAIA::Item>, and L<DAIA::Availability> objects.

=head1 PROPERTIES

=over

=item content

The message as plain Unicode string. The default value
is the empty string.

=item lang

A mandatory RFC 3066 language code. The default value is defined in 
C<$DAIA::Message::DEFAULT_LANG> and set to C<'en'>.

=item errno

An integer value error code. By default a message has no error code.

=back

The C<message> function is a shortcut for the DAIA::Message constructor:

  $msg = DAIA::Message->new( ... );
  $msg = message( ... );

The constructor understands several abbreviated ways to define a message:

  $msg = message( $content [, lang => $lang ] [, errno => $errno ] )
  $msg = message( $lang => $content [, errno => $errno ] )
  $msg = message( $lang => $content [, $errno ] )

The value C<undef> as error code is ignored on construction. You can undefine
an error code by explicitely setting it to C<undef>.

  $msg->errno( undef );

To set or get all messages of an object, you use the C<messages> accessor.
You can pass an array reference or an array:

  $messages = $document->message;  # returns an array reference

  $document->message( [ $msg1, $msg2 ] );
  $document->message( [ $msg ] );
  $document->message( $msg1, $msg2);
  $document->message( $msg );

To append a message you can use the C<add> or the C<addMessage> method:

  $document->add( $msg );         # $msg must be a DAIA::Message
  $document->addMessage( ... );   # ... is passed to message constructor

  $document += $msg;              # same as $document->add( $msg );

=cut

our $DEFAULT_LANG = 'en';

our %PROPERTIES = (
    content => { 
        default => '', 
        filter => sub { "$_[0]" }  # stringify everything
    },
    lang => { 
        default => sub { $DEFAULT_LANG },
        filter => sub { 
            is_language_tag("$_[0]") ? lc("$_[0]") : undef;
        },
    },
    errno => {                                           
        filter => sub { 
            $_[0] =~ m/^-?\d+$/ ? $_[0] : undef  
        } 
    },
);

# called by the constructor
sub _buildargs {
    my $self = shift;
    if ( @_ % 2 ) {  # content as first parameter
        my ($content, %p) = @_;
        if ( @_ == 3 and not defined $PROPERTIES{$_[1]} ) {
            return ( lang => $_[0], content => $_[1], errno => $_[2] );
        } else {
            return ( content => $content, %p );
        }
    } elsif ( defined $_[0] and not defined $PROPERTIES{$_[0]} and is_language_tag($_[0]) ) {
        my ($lang, $content, %p) = @_;
        return ( lang => $lang, content => $content, %p );
    } else {
        return @_;
    }

    return @_;
}

=head1 FUNCTIONS

=head2 is_language_tag ( $tag )

Returns whether $tag is a formally valid language tag. The regular expression
follows XML Schema type C<xs:language> instead of RFC 3066. For true RFC 3066 
support have a look at L<I18N::LangTags>.

=cut

sub is_language_tag {
    my($tag) = lc($_[0]);
    return $tag =~ /^[a-z]{1,8}(-[a-z0-9]{1,8})*$/;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
