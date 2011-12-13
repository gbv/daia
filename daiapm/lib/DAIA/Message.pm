package DAIA::Message;
#ABSTRACT: An optional information text

use strict;
use base 'DAIA::Object';

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

This property is always C<undef> no matter what you set it to.

=back

The C<message> function is a shortcut for the DAIA::Message constructor:

  $msg = DAIA::Message->new( ... );
  $msg = message( ... );

The constructor understands several abbreviated ways to define a message:

  $msg = message( $content [, lang => $lang ] )
  $msg = message( $lang => $content )
  $msg = message( $lang => $content )

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
        default => undef,
        fixed   => undef,
    }
);

# called by the constructor
sub _buildargs {
    my $self = shift;
    if ( @_ % 2 ) {  # content as first parameter
        my ($content, %p) = @_;
        if ( @_ == 3 and not defined $PROPERTIES{$_[1]} ) {
            return ( lang => $_[0], content => $_[1] );
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

sub rdfhash {
    my $self = shift;
    my $rdf = { type => 'literal', value => $self->{content} };
    $rdf->{lang} = $self->{lang} if $self->{lang};
    return $rdf;
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
