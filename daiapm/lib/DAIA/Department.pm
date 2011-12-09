package DAIA::Department;
#ABSTRACT: Information about a department in a L<DAIA::Institution>

use strict;
use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

$PROPERTIES{rdftype} = 'http://www.w3.org/ns/org#Organization';

1;

=head1 PROPERTIES AND METHODS

See L<DAIA::Entity> for a desciption of all properties and methods.
