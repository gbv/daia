use strict;
use warnings;
package DAIA::Institution;
#ABSTRACT: Organization that may hold items and provide services

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://www.w3.org/ns/org#Organization' }

1;

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Institution is a subclass of.
