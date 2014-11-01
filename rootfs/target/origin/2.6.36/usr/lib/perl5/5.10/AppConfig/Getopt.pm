
package AppConfig::Getopt;
use strict;
use warnings;
use AppConfig::State;
use Getopt::Long 2.17;
our $VERSION = '1.65';



sub new {
    my $class = shift;
    my $state = shift;
    my $self = {
        STATE => $state,
   };

    bless $self, $class;
        
    # call parse() to parse any arg list passed 
    $self->parse(@_)
        if @_;

    return $self;
}



sub parse {
    my $self  = shift;
    my $state = $self->{ STATE };
    my (@config, $args, $getopt);
    
    local $" = ', ';

    # we trap $SIG{__WARN__} errors and patch them into AppConfig::State
    local $SIG{__WARN__} = sub {
        my $msg = shift;

        # AppConfig::State doesn't expect CR terminated error messages
        # and it uses printf, so we protect any embedded '%' chars 
        chomp($msg);
        $state->_error("%s", $msg);
    };
    
    # slurp all config items into @config
    push(@config, shift) while defined $_[0] && ! ref($_[0]);   

    # add debug status if appropriate (hmm...can't decide about this)

    # next parameter may be a reference to a list of args
    $args = shift;

    # copy any args explicitly specified into @ARGV
    @ARGV = @$args if defined $args;

    # we enclose in an eval block because constructor may die()
    eval {
        # configure Getopt::Long
        Getopt::Long::Configure(@config);

        # construct options list from AppConfig::State variables
        my @opts = $self->{ STATE   }->_getopt_state();

        # DEBUG
        if ($state->_debug()) {
            print STDERR "Calling GetOptions(@opts)\n";
            print STDERR "\@ARGV = (@ARGV)\n";
        };

        # call GetOptions() with specifications constructed from the state
        $getopt = GetOptions(@opts);
    };
    if ($@) {
        chomp($@);
        $state->_error("%s", $@);
        return 0;
    }

    # udpdate any args reference passed to include only that which is left 
    # in @ARGV
    @$args = @ARGV if defined $args;

    return $getopt;
}



package AppConfig::State;


sub _getopt_state {
    my $self = shift;
    my ($var, $spec, $args, $argcount, @specs);

    my $linkage = sub { $self->set(@_) };

    foreach $var (keys %{ $self->{ VARIABLE } }) {
        $spec  = join('|', $var, @{ $self->{ ALIASES }->{ $var } || [ ] });

        # an ARGS value is used, if specified
        unless (defined ($args = $self->{ ARGS }->{ $var })) {
            # otherwise, construct a basic one from ARGCOUNT
            ARGCOUNT: {
                last ARGCOUNT unless 
                    defined ($argcount = $self->{ ARGCOUNT }->{ $var });

                $args = "=s",  last ARGCOUNT if $argcount eq ARGCOUNT_ONE;
                $args = "=s@", last ARGCOUNT if $argcount eq ARGCOUNT_LIST;
                $args = "=s%", last ARGCOUNT if $argcount eq ARGCOUNT_HASH;
                $args = "!";
            }
        }
        $spec .= $args if defined $args;

        push(@specs, $spec, $linkage);
    }

    return @specs;
}



1;

__END__

