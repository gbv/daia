package DAIA::Availability;

=head1 NAME

DAIA::Availability - Abstract base class of availability information

=cut

use strict;
use base 'DAIA::Object';
our $VERSION = '0.30';
use Carp::Clan;
use Data::Validate::URI qw(is_uri);
use DateTime::Duration;
use DateTime::Format::Duration;

use DateTime;
use base 'Exporter';
our @EXPORT_OK = qw(parse_duration normalize_duration date_or_datetime);

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
recommended) or a custom URI (use with care). The predefined URLs with
prefix C<http://purl.org/ontology/daia/Service/> are converted to their 
short form equivalent.

=item href

An URL to perform, register or reserve the service.

=item limitation

An array reference with limitations (L<DAIA::Limitation> objects).

=item message

An array reference with L<DAIA::Message> objects about this specific service.

=back

Depending on whether the availability's status is true (available)
or false (unavailable), the properties C<delay>, C<queue>, and 
C<expected> are also possible.

=cut

our %PROPERTIES = (
    service => {
        # default => sub { croak 'DAIA::Availability->service is required'  },
        default => sub { undef }, # TODO: configure whether mandatory
        filter => sub {
            my $s = $_[0];
            return $s if $DAIA::Availability::SERVICES{$s};
            return $DAIA::Availability::SECIVRES{$s} if $DAIA::Availability::SECIVRES{$s};
            return $s if is_uri($s); return;
        }
    },
    href    => $DAIA::Object::COMMON_PROPERTIES{href},
    message => $DAIA::Object::COMMON_PROPERTIES{message},
    error   => $DAIA::Object::COMMON_PROPERTIES{error},
    limitation => {
        type => 'DAIA::Limitation',
        repeatable => 1,
        predicate  => $DAIA::Object::RDFNAMESPACE.'limitedBy'
    }
);

# known services
our %SERVICES = (
    'presentation' => $DAIA::Object::RDFNAMESPACE.'Service/Presentation',
    'loan'         => $DAIA::Object::RDFNAMESPACE.'Service/Loan',
    'interloan'    => $DAIA::Object::RDFNAMESPACE.'Service/Interloan',
    'openaccess'   => $DAIA::Object::RDFNAMESPACE.'Service/Openaccess',
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

=head1 FUNCTIONS

This package implements a duration parsing method based on
code from L<DateTime::Format::Duration::XSD> by Smal D A.

=head2 parse_duration ( $string )

Parses a XML Schema xs:duration string and returns
a L<DateTime::Duration> object or undef.

=cut

sub parse_duration {
    return $_[0] if UNIVERSAL::isa( $_[0], 'DateTime::Duration' );
    my $duration = "$_[0]";

    my ($neg, $year, $mounth, $day, $hour, $min, $sec, $fsec);
    if ($duration =~ /^(-)?
                      P
                      ((\d+)Y)?
                      ((\d+)M)?
                      ((\d+)D)?
                      (
                      T
                      ((\d+)H)?
                      ((\d+)M)?
                      (((\d+)(\.(\d+))?)S)?
                      )?
                    $/x) {
        ($neg, $year, $mounth, $day, $hour, $min, $sec, $fsec) =
        ($1,   $3,    $5,      $7,   $10,   $12,  $15,  $17);
        return unless (grep {defined} ($year, $mounth, $day, $hour, $min, $sec));
    } else {
        return;
    }
    $duration = DateTime::Duration->new(
      years   => $year || 0,
      months  => $mounth || 0,
      days    => $day || 0,
      hours   => $hour || 0,
      minutes => $min || 0,
      seconds => $sec || 0,
      nanoseconds => ($fsec ? "0.$fsec" * 1E9  : 0),
    );
    $duration = $duration->inverse if $neg;
    return $duration;
}

=head2 normalize_duration ( $string-or-duration-object )

Returns a normalized duration (according to XML Schema xs:duration).
You can pass a duration string or a L<DateTime::Duration> object.
Returns undef on failure.

=cut

sub normalize_duration {
    my $duration = $_[0];
    $duration = parse_duration( $duration )
        unless UNIVERSAL::isa( $duration, 'DateTime::Duration' );
    return unless defined $duration;

    return "P0D" if $duration->is_zero;

    # TODO: replace this
    my $fmt = DateTime::Format::Duration->new(
          pattern => '%PP%YY%mM%dDT%HH%MM%S.%NS',
          normalize => 1,
    );

    my %d = $fmt->normalize( $duration );
    if (exists $d{seconds} or exists $d{nanoseconds}) {
        $d{seconds} = ($d{seconds} || 0)
                    + (exists $d{nanoseconds} ? $d{nanoseconds} / 1E9 : 0);
    }
    my $str = $d{negative} ? "-P" : "P";
    $str .= "$d{years}Y" if exists $d{years} and $d{years} > 0;
    $str .= "$d{months}M" if exists $d{months} and $d{months} > 0;
    $str .= "$d{days}D" if exists $d{days} and $d{days} > 0;
    $str .= "T" if grep {exists $d{$_} and $d{$_} > 0} qw(hours minutes seconds);
    $str .= "$d{hours}H" if exists $d{hours} and $d{hours} > 0;
    $str .= "$d{minutes}M" if exists $d{minutes} and $d{minutes} > 0;
    $str .= "$d{seconds}S" if exists $d{seconds} and $d{seconds} > 0;

    return $str;
}

=head2 date_or_datetime ( $date_or_datetime )

Returns a canonical xs:date or xs:dateTime value or undef. You can pass a 
L<DateTime> object or a string as defined in section 3.2.7.1 of the XML Schema
Datatypes specification. Fractions of seconds are ignored.

=cut

sub date_or_datetime {
    my $dt = $_[0];
    if ( not UNIVERSAL::isa( $dt, 'DateTime' ) ) {
        return unless 
            $dt =~ /^(-?\d\d\d\d+-\d\d-\d\d)(T\d\d:\d\d:\d\d(\.\d+)?)?([+-]\d\d:\d\d|Z)?$/;
        my ($date,$time,$tz) = ($1,$2,$4);
        $date =~ /(-?\d\d\d\d+)-(\d\d)-(\d\d)/;
        my %p = (year=>$1,month=>$2,day=>$3);
        if ($time) {
            $time =~ /T(\d\d):(\d\d):(\d\d)(\.\d+)?/;
            ($p{hour},$p{minute},$p{second})=($1,$2,$3);
        }
        if ($tz) {
            $tz =~ s/://; $tz =~ s/Z/UTC/;
            $p{time_zone} = $tz;
        }
        $dt = eval { DateTime->new(%p) } || return;
    }
    $dt->set_time_zone('floating');

    my $date = $dt->strftime("%FT%T");
    $dt =~ s/T00:00:00$//; # remove time part if is zero
    return $dt;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
