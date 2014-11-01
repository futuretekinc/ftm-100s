
package Template::Plugin::Filter;

use strict;
use warnings;
use base 'Template::Plugin';
use Scalar::Util 'weaken';


our $VERSION = 1.38;
our $DYNAMIC = 0 unless defined $DYNAMIC;


sub new {
    my ($class, $context, @args) = @_;
    my $config = @args && ref $args[-1] eq 'HASH' ? pop(@args) : { };

    # look for $DYNAMIC
    my $dynamic;
    {
        no strict 'refs';
        $dynamic = ${"$class\::DYNAMIC"};
    }
    $dynamic = $DYNAMIC unless defined $dynamic;

    my $self = bless {
        _CONTEXT => $context,
        _DYNAMIC => $dynamic,
        _ARGS    => \@args,
        _CONFIG  => $config,
    }, $class;

    return $self->init($config)
        || $class->error($self->error());
}


sub init {
    my ($self, $config) = @_;
    return $self;
}


sub factory {
    my $self = shift;
    my $this = $self;
    
    # This causes problems: https://rt.cpan.org/Ticket/Display.html?id=46691
    # If the plugin is loaded twice in different templates (one INCLUDEd into
    # another) then the filter gets garbage collected when the inner template 
    # ends (at least, I think that's what's happening).  So I'm going to take
    # the "suck it and see" approach, comment it out, and wait for someone to
    # complain that this module is leaking memory.  
    
    # weaken($this);

    if ($self->{ _DYNAMIC }) {
        return $self->{ _DYNAMIC_FILTER } ||= [ sub {
            my ($context, @args) = @_;
            my $config = ref $args[-1] eq 'HASH' ? pop(@args) : { };

            return sub {
                $this->filter(shift, \@args, $config);
            };
        }, 1 ];
    }
    else {
        return $self->{ _STATIC_FILTER } ||= sub {
            $this->filter(shift);
        };
    }
}

sub filter {
    my ($self, $text, $args, $config) = @_;
    return $text;
}


sub merge_config {
    my ($self, $newcfg) = @_;
    my $owncfg = $self->{ _CONFIG };
    return $owncfg unless $newcfg;
    return { %$owncfg, %$newcfg };
}


sub merge_args {
    my ($self, $newargs) = @_;
    my $ownargs = $self->{ _ARGS };
    return $ownargs unless $newargs;
    return [ @$ownargs, @$newargs ];
}


sub install_filter {
    my ($self, $name) = @_;
    $self->{ _CONTEXT }->define_filter( $name => $self->factory );
    return $self;
}



1;

__END__


