
package Template::Plugin::Scalar;
use base 'Template::Plugin';
use strict;
use warnings;
use Template::Exception;
use Scalar::Util qw();

our $VERSION   = 1.00;
our $MONAD     = 'Template::Monad::Scalar';
our $EXCEPTION = 'Template::Exception';
our $AUTOLOAD;

sub load {
    my $class   = shift;
    my $context = shift;

    # define .scalar vmethods for hash and list objects
    $context->define_vmethod( hash => scalar => \&scalar_monad );
    $context->define_vmethod( list => scalar => \&scalar_monad );

    return $class;
}

sub scalar_monad {
    # create a .scalar monad which wraps the hash- or list-based object
    # and delegates any method calls back to it, calling them in scalar 
    # context, e.g. foo.scalar.bar becomes $MONAD->new($foo)->bar and 
    # the monad calls $foo->bar in scalar context
    $MONAD->new(shift);
}

sub new {
    my ($class, $context, @args) = @_;
    # create a scalar plugin object which will lookup a variable subroutine
    # and call it.  e.g. scalar.foo results in a call to foo() in scalar context
    my $self = bless {
        _CONTEXT => $context,
    }, $class;
    return $self;
}

sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';
    
    # lookup the named values
    my $stash = $self->{ _CONTEXT }->stash;
    my $value = $stash->{ $item };

    if (! defined $value) {
        die $EXCEPTION->new( scalar => "undefined value for scalar call: $item" );
    }
    elsif (ref $value eq 'CODE') {
        $value = $value->(@_);
    }
    return $value;
}


package Template::Monad::Scalar;

our $EXCEPTION = 'Template::Exception';
our $AUTOLOAD;

sub new {
    my ($class, $this) = @_;
    bless \$this, $class;
}

sub AUTOLOAD {
    my $self = shift;
    my $this = $$self;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    my $method;
    if (Scalar::Util::blessed($this)) {
        # lookup the method...
        $method = $this->can($item);
    }
    else {
        die $EXCEPTION->new( scalar => "invalid object method: $item" );
    }

    # ...and call it in scalar context
    my $result = $method->($this, @_);

    return $result;
}

1;

__END__


