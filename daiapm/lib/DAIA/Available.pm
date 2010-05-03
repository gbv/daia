package DAIA::Available;

=head1 NAME

DAIA::Available - Information about a service that is currently unavailable

=head1 DESCRIPTION

This class is derived from L<DAIA::Availability> - see that class for details.
In addition there is the property C<delay> that holds an XML Schema duration
value or the special value C<unknown>.  Obviously the C<status> property of
a C<DAIA::Unavailable> object is always C<1>.

=cut

use strict;
use base 'DAIA::Availability';
our $VERSION = '0.27';
use DateTime::Duration;
use DateTime::Format::Duration;

use base 'Exporter';
our @EXPORT_OK = qw(parse_duration normalize_duration);

=head1 PROPERTIES

=over

=item href

An URL to perform, register or reserve the service.

=item limitation

An array reference with limitations (L<DAIA::Limitation> objects).

=item message

An array reference with L<DAIA::Message> objects about this specific service.

=item delay

A delay as duration string (XML Schema C<xs:duration>). To get the
delay as L<DateTime::Duration> object, use the C<parse_duration>
function that can be exported on request.

=back

=cut

our %PROPERTIES = (
    %DAIA::Availability::PROPERTIES,
    delay => { 
        filter => sub {
            return 'unknown' if lc("$_[0]") eq 'unknown';
            return normalize_duration( $_[0] );
        }
    }
);

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

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
