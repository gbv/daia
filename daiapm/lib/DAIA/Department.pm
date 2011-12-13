use strict;
use warnings;
package DAIA::Department;
#ABSTRACT: Information about a department in a L<DAIA::Institution>

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://www.w3.org/ns/org#Organization' }

1;

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Department is a subclass of.
