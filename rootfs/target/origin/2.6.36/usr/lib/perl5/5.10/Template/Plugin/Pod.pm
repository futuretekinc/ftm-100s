
package Template::Plugin::Pod;

use strict;
use warnings;
use base 'Template::Plugin';
use Pod::POM;


our $VERSION = 2.69;


sub new {
    my $class = shift;
    my $context = shift;

    Pod::POM->new(@_);
}


1;

__END__


