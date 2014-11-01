
package AppConfig::State;
use strict;
use warnings;

our $VERSION = '1.65';
our $DEBUG   = 0;
our $AUTOLOAD;

use AppConfig ':argcount';

my %METHVARS;
   @METHVARS{ qw( EXPAND ARGS ARGCOUNT ) } = ();

my %METHFLAGS;
   @METHFLAGS{ qw( PEDANTIC ) } = ();

my @GLOBAL_OK = qw( DEFAULT EXPAND VALIDATE ACTION ARGS ARGCOUNT );



sub new {
    my $class = shift;
    
    my $self = {
        # internal hash arrays to store variable specification information
        VARIABLE   => { },     # variable values
        DEFAULT    => { },     # default values
        ALIAS      => { },     # known aliases  ALIAS => VARIABLE
        ALIASES    => { },     # reverse alias lookup VARIABLE => ALIASES
        ARGCOUNT   => { },     # arguments expected
        ARGS       => { },     # specific argument pattern (AppConfig::Getopt)
        EXPAND     => { },     # variable expansion (AppConfig::File)
        VALIDATE   => { },     # validation regexen or functions
        ACTION     => { },     # callback functions for when variable is set
        GLOBAL     => { },     # default global settings for new variables
        
        # other internal data
        CREATE     => 0,       # auto-create variables when set
        CASE       => 0,       # case sensitivity flag (1 = sensitive)
        PEDANTIC   => 0,       # return immediately on parse warnings
        EHANDLER   => undef,   # error handler (let's hope we don't need it!)
        ERROR      => '',      # error message
    };

    bless $self, $class;
        
    # configure if first param is a config hash ref
    $self->_configure(shift)
        if ref($_[0]) eq 'HASH';

    # call define(@_) to handle any variables definitions
    $self->define(@_)
        if @_;

    return $self;
}



sub define {
    my $self = shift;
    my ($var, $args, $count, $opt, $val, $cfg, @names);

    while (@_) {
        $var = shift;
        $cfg = ref($_[0]) eq 'HASH' ? shift : { };

        # variable may be specified in compact format, 'foo|bar=i@'
        if ($var =~ s/(.+?)([!+=:].*)/$1/) {

            # anything coming after the name|alias list is the ARGS
            $cfg->{ ARGS } = $2
                if length $2;
        }

        # examine any ARGS option
        if (defined ($args = $cfg->{ ARGS })) {
          ARGGCOUNT: {
              $count = ARGCOUNT_NONE, last if $args =~ /^!/;
              $count = ARGCOUNT_LIST, last if $args =~ /@/;
              $count = ARGCOUNT_HASH, last if $args =~ /%/;
              $count = ARGCOUNT_ONE;
          }
            $cfg->{ ARGCOUNT } = $count;
        }

        # split aliases out
        @names = split(/\|/, $var);
        $var = shift @names;
        $cfg->{ ALIAS } = [ @names ] if @names;

        # variable name gets folded to lower unless CASE sensitive
        $var = lc $var unless $self->{ CASE };

        # activate $variable (so it does 'exist()') 
        $self->{ VARIABLE }->{ $var } = undef;

        # merge GLOBAL and variable-specific configurations
        $cfg = { %{ $self->{ GLOBAL } }, %$cfg };

        # examine each variable configuration parameter
        while (($opt, $val) = each %$cfg) {
            $opt = uc $opt;
            
            # DEFAULT, VALIDATE, EXPAND, ARGS and ARGCOUNT are stored as 
            # they are;
            $opt =~ /^DEFAULT|VALIDATE|EXPAND|ARGS|ARGCOUNT$/ && do {
                $self->{ $opt }->{ $var } = $val;
                next;
            };
            
            # CMDARG has been deprecated
            $opt eq 'CMDARG' && do {
                $self->_error("CMDARG has been deprecated.  "
                              . "Please use an ALIAS if required.");
                next;
            };
            
            # ACTION should be a code ref
            $opt eq 'ACTION' && do {
                unless (ref($val) eq 'CODE') {
                    $self->_error("'$opt' value is not a code reference");
                    next;
                };
                
                # store code ref, forcing keyword to upper case
                $self->{ ACTION }->{ $var } = $val;
                
                next;
            };
            
            # ALIAS creates alias links to the variable name
            $opt eq 'ALIAS' && do {
                
                # coerce $val to an array if not already so
                $val = [ split(/\|/, $val) ]
                    unless ref($val) eq 'ARRAY';
                
                # fold to lower case unless CASE sensitivity set
                unless ($self->{ CASE }) {
                    @$val = map { lc } @$val;
                }
                
                # store list of aliases...
                $self->{ ALIASES }->{ $var } = $val;
                
                # ...and create ALIAS => VARIABLE lookup hash entries
                foreach my $a (@$val) {
                    $self->{ ALIAS }->{ $a } = $var;
                }
                
                next;
            };
            
            # default 
            $self->_error("$opt is not a valid configuration item");
        }
        
        # set variable to default value
        $self->_default($var);
        
        # DEBUG: dump new variable definition
        if ($DEBUG) {
            print STDERR "Variable defined:\n";
            $self->_dump_var($var);
        }
    }
}



sub get {
    my $self     = shift;
    my $variable = shift;
    my $negate   = 0;
    my $value;

    # _varname returns variable name after aliasing and case conversion
    # $negate indicates if the name got converted from "no<var>" to "<var>"
    $variable = $self->_varname($variable, \$negate);

    # check the variable has been defined
    unless (exists($self->{ VARIABLE }->{ $variable })) {
        $self->_error("$variable: no such variable");
        return undef;
    }

    # DEBUG
    print STDERR "$self->get($variable) => ", 
           defined $self->{ VARIABLE }->{ $variable }
                  ? $self->{ VARIABLE }->{ $variable }
                  : "<undef>",
          "\n"
          if $DEBUG;

    # return variable value, possibly negated if the name was "no<var>"
    $value = $self->{ VARIABLE }->{ $variable };

    return $negate ? !$value : $value;
}



sub set {
    my $self     = shift;
    my $variable = shift;
    my $value    = shift;
    my $negate   = 0;
    my $create;

    # _varname returns variable name after aliasing and case conversion
    # $negate indicates if the name got converted from "no<var>" to "<var>"
    $variable = $self->_varname($variable, \$negate);

    # check the variable exists
    if (exists($self->{ VARIABLE }->{ $variable })) {
        # variable found, so apply any value negation
        $value = $value ? 0 : 1 if $negate;
    }
    else {
        # auto-create variable if CREATE is 1 or a pattern matching 
        # the variable name (real name, not an alias)
        $create = $self->{ CREATE };
        if (defined $create
            && ($create eq '1' || $variable =~ /$create/)) {
            $self->define($variable);
            
            print STDERR "Auto-created $variable\n" if $DEBUG;
        }
        else {
            $self->_error("$variable: no such variable");
            return 0;
        }
    }
    
    # call the validate($variable, $value) method to perform any validation
    unless ($self->_validate($variable, $value)) {
        $self->_error("$variable: invalid value: $value");
        return 0;
    }
    
    # DEBUG
    print STDERR "$self->set($variable, ", 
    defined $value
        ? $value
        : "<undef>",
        ")\n"
        if $DEBUG;
    

    # set the variable value depending on its ARGCOUNT
    my $argcount = $self->{ ARGCOUNT }->{ $variable };
    $argcount = AppConfig::ARGCOUNT_ONE unless defined $argcount;

    if ($argcount eq AppConfig::ARGCOUNT_LIST) {
        # push value onto the end of the list
        push(@{ $self->{ VARIABLE }->{ $variable } }, $value);
    }
    elsif ($argcount eq AppConfig::ARGCOUNT_HASH) {
        # insert "<key>=<value>" data into hash 
        my ($k, $v) = split(/\s*=\s*/, $value, 2);
        # strip quoting
        $v =~ s/^(['"])(.*)\1$/$2/ if defined $v;
        $self->{ VARIABLE }->{ $variable }->{ $k } = $v;
    }
    else {
        # set simple variable
        $self->{ VARIABLE }->{ $variable } = $value;
    }


    # call any ACTION function bound to this variable
    return &{ $self->{ ACTION }->{ $variable } }($self, $variable, $value)
        if (exists($self->{ ACTION }->{ $variable }));

    # ...or just return 1 (ok)
    return 1;
}



sub varlist {
    my $self     = shift;
    my $criteria = shift;
    my $strip    = shift;

    $criteria = "" unless defined $criteria;

    # extract relevant keys and slice out corresponding values
    my @keys = grep(/$criteria/, keys %{ $self->{ VARIABLE } });
    my @vals = @{ $self->{ VARIABLE } }{ @keys };
    my %set;

    # clean off the $criteria part if $strip is set
    @keys = map { s/$criteria//; $_ } @keys if $strip;

    # slice values into the target hash 
    @set{ @keys } = @vals;
    return %set;
}

    

sub AUTOLOAD {
    my $self = shift;
    my ($variable, $attrib);


    # splat the leading package name
    ($variable = $AUTOLOAD) =~ s/.*:://;

    # ignore destructor
    $variable eq 'DESTROY' && return;


    # per-variable attributes and internal flags listed as keys in 
    # %METHFLAGS and %METHVARS respectively can be accessed by a 
    # method matching the attribute or flag name in lower case with 
    # a leading underscore_
    if (($attrib = $variable) =~ s/_//g) {
        $attrib = uc $attrib;
        
        if (exists $METHFLAGS{ $attrib }) {
            return $self->{ $attrib };
        }

        if (exists $METHVARS{ $attrib }) {
            # next parameter should be variable name
            $variable = shift;
            $variable = $self->_varname($variable);
            
            # check we've got a valid variable
            
            # return attribute
            return $self->{ $attrib }->{ $variable };
        }
    }
    
    # set a new value if a parameter was supplied or return the old one
    return defined($_[0])
           ? $self->set($variable, shift)
           : $self->get($variable);
}





sub _configure {
    my $self = shift;
    my $cfg  = shift || return;

    # construct a regex to match values which are ok to be found in GLOBAL
    my $global_ok = join('|', @GLOBAL_OK);

    foreach my $opt (keys %$cfg) {

        # GLOBAL must be a hash ref
        $opt =~ /^GLOBALS?$/i && do {
            unless (ref($cfg->{ $opt }) eq 'HASH') {
                $self->_error("\U$opt\E parameter is not a hash ref");
                next;
            }

            # we check each option is ok to be in GLOBAL, but we don't do 
            # any error checking on the values they contain (but should?).
            foreach my $global ( keys %{ $cfg->{ $opt } } )  {

                # continue if the attribute is ok to be GLOBAL 
                next if ($global =~ /(^$global_ok$)/io);
                         
                $self->_error( "\U$global\E parameter cannot be GLOBAL");
            }
            $self->{ GLOBAL } = $cfg->{ $opt };
            next;
        };
            
        # CASE, CREATE and PEDANTIC are stored as they are
        $opt =~ /^CASE|CREATE|PEDANTIC$/i && do {
            $self->{ uc $opt } = $cfg->{ $opt };
            next;
        };

        # ERROR triggers $self->_ehandler()
        $opt =~ /^ERROR$/i && do {
            $self->_ehandler($cfg->{ $opt });
            next;
        };

        # DEBUG triggers $self->_debug()
        $opt =~ /^DEBUG$/i && do {
            $self->_debug($cfg->{ $opt });
            next;
        };
            
        # warn about invalid options
        $self->_error("\U$opt\E is not a valid configuration option");
    }
}



sub _varname {
    my $self     = shift;
    my $variable = shift;
    my $negated  = shift;

    # convert to lower case if case insensitive
    $variable = $self->{ CASE } ? $variable : lc $variable;

    # get the actual name if this is an alias
    $variable = $self->{ ALIAS }->{ $variable }
        if (exists($self->{ ALIAS }->{ $variable }));

    # if the variable doesn't exist, we can try to chop off a leading 
    # "no" and see if the remainder matches an ARGCOUNT_ZERO variable
    unless (exists($self->{ VARIABLE }->{ $variable })) {
        # see if the variable is specified as "no<var>"
        if ($variable =~ /^no(.*)/) {
            # see if the real variable (minus "no") exists and it
            # has an ARGOUNT of ARGCOUNT_NONE (or no ARGCOUNT at all)
            my $novar = $self->_varname($1);
            if (exists($self->{ VARIABLE }->{ $novar })
                && ! $self->{ ARGCOUNT }->{ $novar }) {
                # set variable name and negate value 
                $variable = $novar;
                $$negated = ! $$negated if defined $negated;
            }
        }
    }
    
    # return the variable name
    $variable;
}



sub _default {
    my $self     = shift;
    my $variable = shift;

    # _varname returns variable name after aliasing and case conversion
    $variable = $self->_varname($variable);

    # check the variable exists
    if (exists($self->{ VARIABLE }->{ $variable })) {
        # set variable value to the default scalar, an empty list or empty
        # hash array, depending on its ARGCOUNT value
        my $argcount = $self->{ ARGCOUNT }->{ $variable };
        $argcount = AppConfig::ARGCOUNT_ONE unless defined $argcount;
        
        if ($argcount == AppConfig::ARGCOUNT_NONE) {
            return $self->{ VARIABLE }->{ $variable } 
                 = $self->{ DEFAULT }->{ $variable } || 0;
        }
        elsif ($argcount == AppConfig::ARGCOUNT_LIST) {
            my $deflist = $self->{ DEFAULT }->{ $variable };
            return $self->{ VARIABLE }->{ $variable } = 
                [ ref $deflist eq 'ARRAY' ? @$deflist : ( ) ];
            
        }
        elsif ($argcount == AppConfig::ARGCOUNT_HASH) {
            my $defhash = $self->{ DEFAULT }->{ $variable };
            return $self->{ VARIABLE }->{ $variable } = 
            { ref $defhash eq 'HASH' ? %$defhash : () };
        }
        else {
            return $self->{ VARIABLE }->{ $variable } 
                 = $self->{ DEFAULT }->{ $variable };
        }
    }
    else {
        $self->_error("$variable: no such variable");
        return 0;
    }
}



sub _exists {
    my $self     = shift;
    my $variable = shift;


    # _varname returns variable name after aliasing and case conversion
    $variable = $self->_varname($variable);

    # check the variable has been defined
    return exists($self->{ VARIABLE }->{ $variable });
}



sub _validate {
    my $self     = shift;
    my $variable = shift;
    my $value    = shift;
    my $validator;


    # _varname returns variable name after aliasing and case conversion
    $variable = $self->_varname($variable);

    # return OK unless there is a validation function
    return 1 unless defined($validator = $self->{ VALIDATE }->{ $variable });

    #
    # the validation performed is based on the validator type;
    #
    #   CODE ref: code executed, returning 1 (ok) or 0 (failed)
    #   SCALAR  : a regex which should match the value
    #

    # CODE ref
    ref($validator) eq 'CODE' && do {
        # run the validation function and return the result
        return &$validator($variable, $value);
    };

    # non-ref (i.e. scalar)
    ref($validator) || do {
        # not a ref - assume it's a regex
        return $value =~ /$validator/;
    };
    
    # validation failed
    return 0;
}



sub _error {
    my $self   = shift;
    my $format = shift;

    # user defined error handler?
    if (ref($self->{ EHANDLER }) eq 'CODE') {
        &{ $self->{ EHANDLER } }($format, @_);
    }
    else {
        warn(sprintf("$format\n", @_));
    }
}



sub _ehandler {
    my $self    = shift;
    my $handler = shift;

    # save previous value
    my $previous = $self->{ EHANDLER };

    # update internal reference if a new handler vas provide
    if (defined $handler) {
        # check this is a code reference
        if (ref($handler) eq 'CODE') {
            $self->{ EHANDLER } = $handler;
            
            # DEBUG
            print STDERR "installed new ERROR handler: $handler\n" if $DEBUG;
        }
        else {
            $self->_error("ERROR handler parameter is not a code ref");
        }
    }
   
    return $previous;
}



sub _debug {
    # object reference may not be present if called as a package function
    my $self   = shift if ref($_[0]);
    my $newval = shift;

    # save previous value
    my $oldval = $DEBUG;

    # update $DEBUG if a new value was provided
    $DEBUG = $newval if defined $newval;

    # return previous value
    $oldval;
}



sub _dump_var {
    my $self   = shift;
    my $var    = shift;

    return unless defined $var;

    # $var may be an alias, so we resolve the real variable name
    my $real = $self->_varname($var);
    if ($var eq $real) {
        print STDERR "$var\n";
    }
    else {
        print STDERR "$real  ('$var' is an alias)\n";
        $var = $real;
    }

    # for some bizarre reason, the variable VALUE is stored in VARIABLE
    # (it made sense at some point in time)
    printf STDERR "    VALUE        => %s\n", 
                defined($self->{ VARIABLE }->{ $var }) 
                    ? $self->{ VARIABLE }->{ $var } 
                    : "<undef>";

    # the rest of the values can be read straight out of their hashes
    foreach my $param (qw( DEFAULT ARGCOUNT VALIDATE ACTION EXPAND )) {
        printf STDERR "    %-12s => %s\n", $param, 
                defined($self->{ $param }->{ $var }) 
                    ? $self->{ $param }->{ $var } 
                    : "<undef>";
    }

    # summarise all known aliases for this variable
    print STDERR "    ALIASES      => ", 
            join(", ", @{ $self->{ ALIASES }->{ $var } }), "\n"
            if defined $self->{ ALIASES }->{ $var };
} 



sub _dump {
    my $self = shift;
    my $var;

    print STDERR "=" x 71, "\n";
    print STDERR 
        "Status of AppConfig::State (version $VERSION) object:\n\t$self\n";

    
    print STDERR "- " x 36, "\nINTERNAL STATE:\n";
    foreach (qw( CREATE CASE PEDANTIC EHANDLER ERROR )) {
        printf STDERR "    %-12s => %s\n", $_, 
                defined($self->{ $_ }) ? $self->{ $_ } : "<undef>";
    }       

    print STDERR "- " x 36, "\nVARIABLES:\n";
    foreach $var (keys %{ $self->{ VARIABLE } }) {
        $self->_dump_var($var);
    }

    print STDERR "- " x 36, "\n", "ALIASES:\n";
    foreach $var (keys %{ $self->{ ALIAS } }) {
        printf("    %-12s => %s\n", $var, $self->{ ALIAS }->{ $var });
    }
    print STDERR "=" x 72, "\n";
} 



1;

__END__

