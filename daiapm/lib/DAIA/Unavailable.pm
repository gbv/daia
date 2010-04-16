package DAIA::Unavailable;

=head1 NAME

DAIA::Unavailable - Information about a service that is currently unavailable

=head1 DESCRIPTION

This class is derived from L<DAIA::Availability> - see that class for details.
In addition there are the properties C<expected> and C<queue>. Obviously the
C<status> property of a C<DAIA::Unavailable> object is always C<0>.

=cut

use strict;
use base 'DAIA::Availability';
our $VERSION = '0.25';
use DateTime::Format::ISO8601;
use DAIA::Available qw(parse_duration);

=head1 PROPERTIES

=over

=item href

=item limitation

=item message

=item queue

The number of waiting requests for this service as non-negative integer value.
Note that the value C<0> is also allowed but in practise there is litte 
difference between no queue and a queue of length zero.

=item expected

An optional time period until the service will be available again. The property
is given as ISO time period string (as XML Schema subset xs:date or xs:dateTime)
or the special value "unknown". If no period (nor "unknown") is given, the service 
probably won't be available in the future.

=back

=cut

our %PROPERTIES = (
    %DAIA::Availability::PROPERTIES,
    queue => { 
        filter => sub { return $_[0] =~ /^[0-9]+$/ ? $_[0] : undef }
    },
    expected => { 
        filter => sub {
            return 'unknown' if lc("$_[0]") eq 'unknown';
            my $exp = $_[0];
            if ( $exp =~ /^P/ or UNIVERSAL::isa( $exp, 'DateTime::Duration' ) ) {
                my $span = parse_duration( $exp );
                my $now = DateTime->from_epoch( epoch => time() );
                $exp = $now->add_duration( $span );
            }
            return normalize_date( $exp );
        }
    },
);

=head1 FUNCTIONS

=head2 normalize_date ( $date-or-datetime )

Returns a canonical xs:date or xs:dateTime value or undef. Can can pass a 
L<DateTime> object or a string that will be parsed with the parse_datetime
method of L<DateTime::Format::ISO8601>.

=cut

sub normalize_date {
    my $dt = $_[0];
    if ( not UNIVERSAL::isa( $dt, 'DateTime' ) ) {
        # parse_datetime
        $dt = DateTime::Format::ISO8601->parse_datetime( $dt );
    }
    $dt->set_time_zone('floating');

    my $date = $dt->strftime("%FT%T");
    $dt =~ s/T00:00:00$//; # remove time part if zero
    return $dt;
}

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
