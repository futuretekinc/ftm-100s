
package AppConfig::Args;
use strict;
use warnings;
use AppConfig::State;
our $VERSION = '1.65';



sub new {
    my $class = shift;
    my $state = shift;
    

    my $self = {
        STATE    => $state,                # AppConfig::State ref
        DEBUG    => $state->_debug(),      # store local copy of debug
        PEDANTIC => $state->_pedantic,     # and pedantic flags
    };

    bless $self, $class;
        
    # call parse() to parse any arg list passed 
    $self->parse(shift)
        if @_;

    return $self;
}



sub parse {
    my $self = shift;
    my $argv = shift || \@ARGV;
    my $warnings = 0;
    my ($arg, $nargs, $variable, $value);


    # take a local copy of the state to avoid much hash dereferencing
    my ($state, $debug, $pedantic) = @$self{ qw( STATE DEBUG PEDANTIC ) };

    # loop around arguments
    ARG: while (@$argv && $argv->[0] =~ /^-/) {
        $arg = shift(@$argv);

        # '--' indicates the end of the options
        last if $arg eq '--';

        # strip leading '-';
        ($variable = $arg) =~ s/^-(-)?//;

        # test for '--' prefix and push back any '=value' item
        if (defined $1) {
            ($variable, $value) = split(/=/, $variable);
            unshift(@$argv, $value) if defined $value;
        }

        # check the variable exists
        if ($state->_exists($variable)) {

            # see if it expects any mandatory arguments
            $nargs = $state->_argcount($variable);
            if ($nargs) {
                # check there's another arg and it's not another '-opt'
                if(defined($argv->[0])) {
                    $value = shift(@$argv);
                }
                else {
                    $state->_error("$arg expects an argument");
                    $warnings++;
                    last ARG if $pedantic;
                    next;
                }
            }
            else {
                # set a value of 1 if option doesn't expect an argument
                $value = 1;
            }

            # set the variable with the new value
            $state->set($variable, $value);
        }
        else {
            $state->_error("$arg: invalid option");
            $warnings++;
            last ARG if $pedantic;
        }
    }

    # return status
    return $warnings ? 0 : 1;
}



1;

__END__

