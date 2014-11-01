
package Template::Plugin;

use strict;
use warnings;
use base 'Template::Base';

our $VERSION = 2.70;
our $DEBUG   = 0 unless defined $DEBUG;
our $ERROR   = '';
our $AUTOLOAD;




sub load {
    return $_[0];
}



sub new {
    my $class = shift;
    bless {
    }, $class;
}

sub old_new {
    my ($class, $context, $delclass, @params) = @_;
    my ($delegate, $delmod);

    return $class->error("no context passed to $class constructor\n")
        unless defined $context;

    if (ref $delclass) {
        # $delclass contains a reference to a delegate object
        $delegate = $delclass;
    }
    else {
        # delclass is the name of a module to load and instantiate
        ($delmod = $delclass) =~ s|::|/|g;

        eval {
            require "$delmod.pm";
            $delegate = $delclass->new(@params)
                || die "failed to instantiate $delclass object\n";
        };
        return $class->error($@) if $@;
    }

    bless {
        _CONTEXT  => $context, 
        _DELEGATE => $delegate,
        _PARAMS   => \@params,
    }, $class;
}



sub fail {
    my $class = shift;
    my ($pkg, $file, $line) = caller();
    warn "Template::Plugin::fail() is deprecated at $file line $line.  Please use error()\n";
    $class->error(@_);
}




sub OLD_AUTOLOAD {
    my $self     = shift;
    my $method   = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    if (ref $self eq 'HASH') {
        my $delegate = $self->{ _DELEGATE } || return;
        return $delegate->$method(@_);
    }
    my ($pkg, $file, $line) = caller();
    return undef;
}


1;

__END__


