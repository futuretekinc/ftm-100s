
package Template::Plugin::Assert;
use base 'Template::Plugin';
use strict;
use warnings;
use Template::Exception;

our $VERSION   = 1.00;
our $MONAD     = 'Template::Monad::Assert';
our $EXCEPTION = 'Template::Exception';
our $AUTOLOAD;

sub load {
    my $class   = shift;
    my $context = shift;
    my $stash   = $context->stash;
    my $vmethod = sub {
        $MONAD->new($stash, shift);
    };

    # define .assert vmethods for hash and list objects
    $context->define_vmethod( hash => assert => $vmethod );
    $context->define_vmethod( list => assert => $vmethod );

    return $class;
}

sub new {
    my ($class, $context, @args) = @_;
    # create an assert plugin object which will handle simple variable
    # lookups.
    return bless { _CONTEXT => $context }, $class;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';
    
    # lookup the named values
    my $stash = $self->{ _CONTEXT }->stash;
    my $value = $stash->dotop($stash, $item, \@args);

    if (! defined $value) {
        die $EXCEPTION->new( assert => "undefined value for $item" );
    }
    return $value;
}


package Template::Monad::Assert;

our $EXCEPTION = 'Template::Exception';
our $AUTOLOAD;

sub new {
    my ($class, $stash, $this) = @_;
    bless [$stash, $this], $class;
}

sub AUTOLOAD {
    my ($self, @args) = @_;
    my ($stash, $this) = @$self;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    my $value = $stash->dotop($stash, $item, \@args);

    if (! defined $value) {
        die $EXCEPTION->new( assert => "undefined value for $item" );
    }
    return $value;
}

1;

__END__


