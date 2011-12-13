use strict;
use warnings;
package DAIA::Limitation;
#ABSTRACT: Information about specific limitations of availability

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://www.w3.org/ns/org#Organization' }

1;

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Limitation is a subclass of.
