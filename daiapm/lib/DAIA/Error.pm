use strict;
use warnings;
package DAIA::Error;
#ABSTRACT: An error message

use base 'DAIA::Message';

=head1 DESCRIPTION

Error messages are special kind of L<DAIA::Message> objects, that have
an error number (C<errno>). Error numbers are integer values. If you set
the error number some non-number or C<undef>, the error message becomes
a normal message object. In DAIA/RDF error messages end up as normal
literal messages.

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
    errno => { 
        default => 0,
        filter => sub { 
            $_[0] =~ m/^-?\d+$/ ? $_[0] : 0  
        }, 
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

1;
