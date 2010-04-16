package DAIA::Availability;

=head1 NAME

DAIA::Availability - Abstract base class of availability information

=cut

use strict;
use base 'DAIA::Object';
our $VERSION = '0.26';
use Carp::Clan;
use Data::Validate::URI qw(is_uri);

=head1 DESCRIPTION

Availability in DAIA is modeled as a combination of service and status. The
availability B<status> is a boolean value - either something is available
or it is not. The B<service> must be one of C<presentation>, C<loan>,
C<interloan>, and C<openaccess> or a custom URI. Additionally you can specify
some details about the availability.

In general availability is encoded as an object of either L<DAIA::Available>
(status C<true>) or L<DAIA::Unavailable> (status C<false>). There are several
equivalent ways to define a given service as available:

  available( $service );
  available( service => $service ),
  DAIA::Available->new( $service );
  DAIA::Available->new( service => $service );

  availability( service => $service, status => 1 );
  availability( { service => $service, status => 1 } );
  availability( 1, service => $service );
  availability( $service => 1 );

Likewise there are several equivalent ways to define a service as unavailable:

  unavailable( $service );
  unavailable( service => $service ),
  DAIA::Unavailable->new( $service );
  DAIA::Unavailable->new( service => $service );

  availability( service => $service, status => 0 );
  availability( { service => $service, status => 0 } );
  availability( 0, service => $service );
  availability( $service => 0 );

=head1 PROPERTIES

=over

=item status

Either true L<DAIA::Available> or false L<DAIA::Unavailable>. Modifying
the status changes the object type:

  $a->status    # returns 0 or 1
  $a->status(0) # make $a a DAIA::Unavailable object
  $a->status(1) # make $a a DAIA::Available object

=item service

One of C<presentation>, C<loan>, C<interloan>, and C<openaccess> (highly
recommended) or a custom URI (use with care). The predefined URLs
C<http://purl.org/NET/DAIA/services/presentation>,
C<http://purl.org/NET/DAIA/services/loan>,
C<http://purl.org/NET/DAIA/services/interloan>, and
C<http://purl.org/NET/DAIA/services/openaccess> are converted to
their short form equivalent.

=item href

a link to perform, register or reserve the service

=item limitation

an array reference with limitations (L<DAIA::Limitation> objects) 
of the availability

=item message

an array reference with L<DAIA::Messages> about the specific
availability

=back

Depending on whether the availability's status is true (L<DAIA::Available>)
or false (L<DAIA::Unavailable>), the properties C<delay>, C<queue>, and 
C<expected> are also possible.

=cut

our %PROPERTIES = (
    service => {
        default => sub { croak 'DAIA::Availability->service is required'  },
        filter => sub {
            my $s = $_[0];
            return $s if $DAIA::Availability::SERVICES{$s};
            return $DAIA::Availability::SECIVRES{$s} if $DAIA::Availability::SECIVRES{$s};
            return $s if is_uri($s); return;
        }
    },
    href    => $DAIA::Object::COMMON_PROPERTIES{href},
    message => $DAIA::Object::COMMON_PROPERTIES{message},
    limitation => {
        type => 'DAIA::Limitation',
        repeatable => 1,
    }
);

#anyURI

our %SERVICES = (
    'presentation' => 'http://purl.org/NET/DAIA/services/presentation',
    'loan' => 'http://purl.org/NET/DAIA/services/loan',
    'interloan' => 'http://purl.org/NET/DAIA/services/interloan',
    'openaccess' => 'http://purl.org/NET/DAIA/services/openaccess',
);

our %SECIVRES = (
    map { $SERVICES{$_} => $_ } keys %SERVICES
);

=head1 CONSTRUCTOR

A new availability can be created with the constructors of DAIA::Availability,
L<DAIA::Available>, and L<DAIA::Unavailable> or with the shortcut functions
C<available>, C<unavailable>, and C<availability> which are exported in L<DAIA>.
You can also create a new availability object with the methods C<addAvailable>,
C<addUnavailable>, and C<addAvailability> of L<DAIA::Item>.

=cut

sub _buildargs {
    my $self = shift;
    my %args = ();
    
    if ( not (@_ % 2) ) { # even number
        %args = @_;
        if ( not defined $args{status} ) { # $service => $status
            foreach ( keys %DAIA::Availability::SERVICES ) {
                if ( defined $args{$_} ) {
                    $args{status} = $args{$_};
                    $args{service} = $_;
                    delete $args{$_};
                }
            }
        }
    } elsif ( @_ ) { # non empty, uneven number
        if ( @_ == 1 and UNIVERSAL::isa( $_[0], 'DAIA::Availability' ) ) {
            %args = %{ $_[0]->struct };
            $self = $_[0];
        } elsif ( $DAIA::Availability::SERVICES{$_[0]} or is_uri($_[0]) ) {
            %args = ( service => @_ );
        } else {
            croak( "could not parse parameters to " . ref($self) );
        }
    }
  
    if ( not defined $args{status} ) {
      if ( ref($self) eq 'DAIA::Available' ) {
          $args{status} = 1;
      } elsif ( ref($self) eq 'DAIA::Unavailable' ) {
          $args{status} = 0;
      }
    }

    return %args;
}

=head1 METHODS

DAIA::Item provides the default methods of L<DAIA::Object>, accessor 
methods for all of its properties and the following methods

=head2 addMessage ( $message | ... )

Add a specified or a new L<DAIA::Message>.

=head2 addLimitation ( $limitation | ... )

Add a specified or a new L<DAIA::Limitation>.

=head2 status ( [ 0 | 1 ] )

Get or set the availability status (true for L<DAIA::Available> and false 
for L<DAIA::Unavailable>). This method may change the type of the object:

  $avail = available( 'loan' ); # now $avail isa DAIA::Available
  $avail->status(0);            # now $avail isa DAIA::Unavailable

=cut

sub status {
    my $self = shift;
    my $class = ref($self);
    my $status;

    if ( @_ > 0 ) {
        $status = shift;
        if ( $status ) {
            if ( $class eq 'DAIA::Unavailable' ) {
                $self->expected( undef );
                $self->queue( undef );
            }
            bless $self, 'DAIA::Available';

        } else {
            if ( $class eq 'DAIA::Available' ) {
                $self->delay( undef );
            }
            bless $self, 'DAIA::Unavailable';
        }
    } else {
        $status = $class eq 'DAIA::Available';
    }

    return $status;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
