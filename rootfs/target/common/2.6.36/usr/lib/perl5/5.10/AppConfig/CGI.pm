
package AppConfig::CGI;
use strict;
use warnings;
use AppConfig::State;
our $VERSION = '1.65';



sub new {
    my $class = shift;
    my $state = shift;
    my $self  = {
        STATE    => $state,                # AppConfig::State ref
        DEBUG    => $state->_debug(),      # store local copy of debug
        PEDANTIC => $state->_pedantic,     # and pedantic flags
    };
    bless $self, $class;
        
    # call parse(@_) to parse any arg list passed 
    $self->parse(@_)
        if @_;

    return $self;
}



sub parse {
    my $self     = shift;
    my $query    = shift;
    my $warnings = 0;
    my ($variable, $value, $nargs);
    

    # take a local copy of the state to avoid much hash dereferencing
    my ($state, $debug, $pedantic) = @$self{ qw( STATE DEBUG PEDANTIC ) };

    # get the cgi query if not defined
    $query = $ENV{ QUERY_STRING }
        unless defined $query;

    # no query to process
    return 1 unless defined $query;

    # we want to install a custom error handler into the AppConfig::State 
    # which appends filename and line info to error messages and then 
    # calls the previous handler;  we start by taking a copy of the 
    # current handler..
    my $errhandler = $state->_ehandler();

    # install a closure as a new error handler
    $state->_ehandler(
        sub {
            # modify the error message 
            my $format  = shift;
            $format =~ s/</&lt;/g;
            $format =~ s/>/&gt;/g;
            $format  = "<p>\n<b>[ AppConfig::CGI error: </b>$format<b> ] </b>\n<p>\n";
            # send error to stdout for delivery to web client
            printf($format, @_);
        }
    );


    PARAM: foreach (split('&', $query)) {

        # extract parameter and value from query token
        ($variable, $value) = map { _unescape($_) } split('=');

        # check an argument was provided if one was expected
        if ($nargs = $state->_argcount($variable)) {
            unless (defined $value) {
                $state->_error("$variable expects an argument");
                $warnings++;
                last PARAM if $pedantic;
                next;
            }
        }
        # default an undefined value to 1 if ARGCOUNT_NONE
        else {
            $value = 1 unless defined $value;
        }

        # set the variable, noting any error
        unless ($state->set($variable, $value)) {
            $warnings++;
            last PARAM if $pedantic;
        }
    }

    # restore original error handler
    $state->_ehandler($errhandler);

    # return $warnings => 0, $success => 1
    return $warnings ? 0 : 1;
}




sub _unescape {
    my($todecode) = @_;
    $todecode =~ tr/+/ /;       # pluses become spaces
    $todecode =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $todecode;
}





1;

__END__


