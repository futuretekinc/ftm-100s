
package AppConfig::File;
use strict;
use warnings;
use AppConfig;
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

    # call parse(@_) to parse any files specified as further params
    $self->parse(@_) if @_;

    return $self;
}



sub parse {
    my $self     = shift;
    my $warnings = 0;
    my $prefix;           # [block] defines $prefix
    my $file;
    my $flag;

    # take a local copy of the state to avoid much hash dereferencing
    my ($state, $debug, $pedantic) = @$self{ qw( STATE DEBUG PEDANTIC ) };

    # we want to install a custom error handler into the AppConfig::State 
    # which appends filename and line info to error messages and then 
    # calls the previous handler;  we start by taking a copy of the 
    # current handler..
    my $errhandler = $state->_ehandler();

    # ...and if it doesn't exist, we craft a default handler
    $errhandler = sub { warn(sprintf(shift, @_), "\n") }
        unless defined $errhandler;

    # install a closure as a new error handler
    $state->_ehandler(
        sub {
            # modify the error message 
            my $format  = shift;
               $format .= ref $file 
                          ? " at line $."
                          : " at $file line $.";

            # chain call to prevous handler
            &$errhandler($format, @_);
        }
    );

    # trawl through all files passed as params
    FILE: while ($file = shift) {

        # local/lexical vars ensure opened files get closed
        my $handle;
        local *FH;

        # if the file is a reference, we assume it's a file handle, if
        # not, we assume it's a filename and attempt to open it
        $handle = $file;
        if (ref($file)) {
            $handle = $file;

            # DEBUG
            print STDERR "reading from file handle: $file\n" if $debug;
        }
        else {
            # open and read config file
            open(FH, $file) or do {
                # restore original error handler and report error
                $state->_ehandler($errhandler);
                $state->_error("$file: $!");

                return undef;
            };
            $handle = \*FH;

            # DEBUG
            print STDERR "reading file: $file\n" if $debug;
        }

        # initialise $prefix to nothing (no [block])
        $prefix = '';

        while (<$handle>) {
            chomp;

            # Throw away everything from an unescaped # to EOL
            s/(^|\s+)#.*/$1/;

            # add next line if there is one and this is a continuation
            if (s/\\$// && !eof($handle)) {
                $_ .= <$handle>;
                redo;
            }

            # Convert \# -> #
            s/\\#/#/g;

            # ignore blank lines
            next if /^\s*$/;

            # strip leading and trailing whitespace
            s/^\s+//;
            s/\s+$//;

            # look for a [block] to set $prefix
            if (/^\[([^\]]+)\]$/) {
                $prefix = $1;
                print STDERR "Entering [$prefix] block\n" if $debug;
                next;
            }

            # split line up by whitespace (\s+) or "equals" (\s*=\s*)
            if (/^([^\s=]+)(?:(?:(?:\s*=\s*)|\s+)(.*))?/) {
                my ($variable, $value) = ($1, $2);

                if (defined $value) {
                    # here document
                    if ($value =~ /^([^\s=]+\s*=)?\s*<<(['"]?)(\S+)\2$/) { # '<<XX' or 'hashkey =<<XX'
                        my $boundary = "$3\n";
                        $value = defined($1) ? $1 : '';
                        while (<$handle>) {
                            last if $_ eq $boundary;
                            $value .= $_;
                        };
                        $value =~ s/[\r\n]$//;
                    } else {
                        # strip any quoting from the variable value
                        $value =~ s/^(['"])(.*)\1$/$2/;
                    };
                };

                # strip any leading '+/-' from the variable
                $variable =~ s/^([\-+]?)//;
                $flag = $1;

                # $variable gets any $prefix 
                $variable = $prefix . '_' . $variable
                    if length $prefix;

                # if the variable doesn't exist, we call set() to give 
                # AppConfig::State a chance to auto-create it
                unless ($state->_exists($variable) 
                            || $state->set($variable, 1)) {
                    $warnings++;
                    last FILE if $pedantic;
                    next;
                }       

                my $nargs = $state->_argcount($variable);

                # variables prefixed '-' are reset to their default values
                if ($flag eq '-') {
                    $state->_default($variable);
                    next;
                }
                # those prefixed '+' get set to 1
                elsif ($flag eq '+') {
                    $value = 1 unless defined $value;
                }

                # determine if any extra arguments were expected
                if ($nargs) {
                    if (defined $value && length $value) {
                        # expand any embedded variables, ~uids or
                        # environment variables, testing the return value
                        # for errors;  we pass in any variable-specific
                        # EXPAND value 
                        unless ($self->_expand(\$value, 
                                $state->_expand($variable), $prefix)) {
                            print STDERR "expansion of [$value] failed\n" 
                                if $debug;
                            $warnings++;
                            last FILE if $pedantic;
                        }
                    }
                    else {
                        $state->_error("$variable expects an argument");
                        $warnings++;
                        last FILE if $pedantic;
                        next;
                    }
                }
                # $nargs = 0
                else {
                    # default value to 1 unless it is explicitly defined
                    # as '0' or "off"
                    if (defined $value) {
                        # "off" => 0
                        $value = 0 if $value =~ /off/i;
                        # any value => 1
                        $value = 1 if $value;
                    }
                    else {
                        # assume 1 unless explicitly defined off/0
                        $value = 1;
                    }
                    print STDERR "$variable => $value (no expansion)\n"
                        if $debug;
                }
           
                # set the variable, noting any failure from set()
                unless ($state->set($variable, $value)) {
                    $warnings++;
                    last FILE if $pedantic;
                }
            }
            else {
                $state->_error("parse error");
                $warnings++;
            }
        }
    }

    # restore original error handler
    $state->_ehandler($errhandler);
    
    # return $warnings => 0, $success => 1
    return $warnings ? 0 : 1;
}





sub _expand {
    my ($self, $value, $expand, $prefix) = @_;
    my $warnings = 0;
    my ($sys, $var, $val);


    # ensure prefix contains something (nothing!) valid for length()
    $prefix = "" unless defined $prefix;

    # take a local copy of the state to avoid much hash dereferencing
    my ($state, $debug, $pedantic) = @$self{ qw( STATE DEBUG PEDANTIC ) };

    # bail out if there's nothing to do
    return 1 unless $expand && defined($$value);

    # create an AppConfig::Sys instance, or re-use a previous one, 
    # to handle platform dependant functions: getpwnam(), getpwuid()
    unless ($sys = $self->{ SYS }) {
        require AppConfig::Sys;
        $sys = $self->{ SYS } = AppConfig::Sys->new();
    }

    print STDERR "Expansion of [$$value] " if $debug;

    EXPAND: {

        # 
        # EXPAND_VAR
        # expand $(var) and $var as AppConfig::State variables
        #
        if ($expand & AppConfig::EXPAND_VAR) {

            $$value =~ s{
                (?<!\\)\$ (?: \((\w+)\) | (\w+) ) # $2 => $(var) | $3 => $var

            } {
                # embedded variable name will be one of $2 or $3
                $var = defined $1 ? $1 : $2;

                # expand the variable if defined
                if ($state->_exists($var)) {
                    $val = $state->get($var);
                }
                elsif (length $prefix 
                        && $state->_exists($prefix . '_' . $var)) {
                    print STDERR "(\$$var => \$${prefix}_$var) "
                        if $debug;
                    $var = $prefix . '_' . $var;
                    $val = $state->get($var);
                }
                else {
                    # raise a warning if EXPAND_WARN set
                    if ($expand & AppConfig::EXPAND_WARN) {
                        $state->_error("$var: no such variable");
                        $warnings++;
                    }

                    # replace variable with nothing
                    $val = '';
                }

                # $val gets substituted back into the $value string
                $val;
            }gex;

            $$value =~ s/\\\$/\$/g;

            # bail out now if we need to
            last EXPAND if $warnings && $pedantic;
        }


        #
        # EXPAND_UID
        # expand ~uid as home directory (for $< if uid not specified)
        #
        if ($expand & AppConfig::EXPAND_UID) {
            $$value =~ s{
                ~(\w+)?                    # $1 => username (optional)
            } {
                $val = undef;

                # embedded user name may be in $1
                if (defined ($var = $1)) {
                    # try and get user's home directory
                    if ($sys->can_getpwnam()) {
                        $val = ($sys->getpwnam($var))[7];
                    }
                } else {
                    # determine home directory 
                    $val = $ENV{ HOME };
                }

                # catch-all for undefined $dir
                unless (defined $val) {
                    # raise a warning if EXPAND_WARN set
                    if ($expand & AppConfig::EXPAND_WARN) {
                        $state->_error("cannot determine home directory%s",
                            defined $var ? " for $var" : "");
                        $warnings++;
                    }

                    # replace variable with nothing
                    $val = '';
                }

                # $val gets substituted back into the $value string
                $val;
            }gex;

            # bail out now if we need to
            last EXPAND if $warnings && $pedantic;
        }


        #
        # EXPAND_ENV
        # expand ${VAR} as environment variables
        #
        if ($expand & AppConfig::EXPAND_ENV) {

            $$value =~ s{ 
                ( \$ \{ (\w+) \} )
            } {
                $var = $2;

                # expand the variable if defined
                if (exists $ENV{ $var }) {
                    $val = $ENV{ $var };
                } elsif ( $var eq 'HOME' ) {
                    # In the special case of HOME, if not set
                    # use the internal version
                    $val = $self->{ HOME };
                } else {
                    # raise a warning if EXPAND_WARN set
                    if ($expand & AppConfig::EXPAND_WARN) {
                        $state->_error("$var: no such environment variable");
                        $warnings++;
                    }

                    # replace variable with nothing
                    $val = '';
                }
                # $val gets substituted back into the $value string
                $val;
            }gex;

            # bail out now if we need to
            last EXPAND if $warnings && $pedantic;
        }
    }

    print STDERR "=> [$$value] (EXPAND = $expand)\n" if $debug;

    # return status 
    return $warnings ? 0 : 1;
}




sub _dump {
    my $self = shift;

    foreach my $key (keys %$self) {
        printf("%-10s => %s\n", $key, 
                defined($self->{ $key }) ? $self->{ $key } : "<undef>");
    }       
} 



1;

__END__

