use strict;
use warnings;
package YAML::Tag;

our $VERSION = '0.77';

use overload '""' => sub { ${$_[0]} };

sub new {
    my ($class, $self) = @_;
    bless \$self, $class
}

sub short {
    ${$_[0]}
}

sub canonical {
    ${$_[0]}
}

1;

__END__

