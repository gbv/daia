use strict;
use warnings;
package DAIA::Storage;
#ABSTRACT: Information about the place where an item is stored

use base 'DAIA::Entity';
our %PROPERTIES = %DAIA::Entity::PROPERTIES;

sub rdftype { 'http://purl.org/ontology/daia/Storage' }

1;

=head1 DESCRIPTION

See L<DAIA::Entity> which DAIA::Storage is a subclass of.
