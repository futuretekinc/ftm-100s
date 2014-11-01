
package Template::Plugin::Iterator;

use strict;
use warnings;
use base 'Template::Plugin';
use Template::Iterator;

our $VERSION = 2.68;


sub new {
    my $class   = shift;
    my $context = shift;
    Template::Iterator->new(@_);
}

1;

__END__


