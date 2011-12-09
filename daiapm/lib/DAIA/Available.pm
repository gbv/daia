package DAIA::Available;
#ABSTRACT: Information about a service that is currently unavailable

=head1 DESCRIPTION

This class is derived from L<DAIA::Availability> - see that class for details.
In addition there is the property C<delay> that holds an XML Schema duration
value or the special value C<unknown>.  Obviously the C<status> property of
a C<DAIA::Unavailable> object is always C<1>.

=cut

use strict;
use base 'DAIA::Availability';

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
            return DAIA::Availability::normalize_duration( $_[0] );
        },
        predicate => $DAIA::Object::RDFNAMESPACE.'delay',
    }
);

1;

=head1 AUTHOR

Jakob Voss C<< <jakob.voss@gbv.de> >>

=head1 LICENSE

Copyright (C) 2009-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.8 or, at
your option, any later version of Perl 5 you may have available.
