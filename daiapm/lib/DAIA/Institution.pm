package DAIA::Institution;
#ABSTRACT: Organization that may hold items and provide services

use strict;
use base 'DAIA::Entity';

our %PROPERTIES = %DAIA::Entity::PROPERTIES;

$PROPERTIES{rdftype} = 'http://www.w3.org/ns/org#Organization';

1;

=head1 PROPERTIES AND METHODS

See L<DAIA::Entity> for a desciption of all properties and methods.
