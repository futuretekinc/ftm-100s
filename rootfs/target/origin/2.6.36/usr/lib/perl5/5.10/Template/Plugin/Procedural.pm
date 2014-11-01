
package Template::Plugin::Procedural;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 1.17;
our $DEBUG   = 0 unless defined $DEBUG;
our $AUTOLOAD;


sub load {
    my ($class, $context) = @_;

    # create a proxy namespace that will be used for objects
    my $proxy = "Template::Plugin::" . $class;

    # okay, in our proxy create the autoload routine that will
    # call the right method in the real class
    no strict "refs";
    *{ $proxy . "::AUTOLOAD" } = sub {
        # work out what the method is called
        $AUTOLOAD =~ s!^.*::!!;

        print STDERR "Calling '$AUTOLOAD' in '$class'\n"
            if $DEBUG;

        # look up the sub for that method (but in a OO way)
        my $uboat = $class->can($AUTOLOAD);

        # if it existed call it as a subroutine, not as a method
        if ($uboat) {
            shift @_;
            return $uboat->(@_);
        }

        print STDERR "Eeek, no such method '$AUTOLOAD'\n"
            if $DEBUG;

        return "";
    };

    # create a simple new method that simply returns a blessed
    # scalar as the object.
    *{ $proxy . "::new" } = sub {
        my $this;
        return bless \$this, $_[0];
    };

    return $proxy;
}

1;

__END__


