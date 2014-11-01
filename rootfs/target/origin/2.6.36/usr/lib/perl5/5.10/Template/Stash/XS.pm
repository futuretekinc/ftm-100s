
package Template::Stash::XS;

use strict;
use warnings;
use Template;
use Template::Stash;

our $AUTOLOAD;

BEGIN {
    require DynaLoader;
    @Template::Stash::XS::ISA = qw( DynaLoader Template::Stash );

    eval {
        bootstrap Template::Stash::XS $Template::VERSION;
    };
    if ($@) {
        die "Couldn't load Template::Stash::XS $Template::VERSION:\n\n$@\n";
    }
}

sub DESTROY {
    # no op
    1;
}



sub AUTOLOAD {
    my ($self, @args) = @_;
    my @c             = caller(0);
    my $auto	    = $AUTOLOAD;

    $auto =~ s/.*:://;
    $self =~ s/=.*//;

    die "Can't locate object method \"$auto\"" .
        " via package \"$self\" at $c[1] line $c[2]\n";
}

1;

__END__

