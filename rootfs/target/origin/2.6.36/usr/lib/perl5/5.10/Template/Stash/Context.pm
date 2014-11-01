
package Template::Stash::Context;

use strict;
use warnings;
use base 'Template::Stash';

our $VERSION = 1.63;
our $DEBUG   = 0 unless defined $DEBUG;




our $ROOT_OPS = { 
    %$Template::Stash::ROOT_OPS,
    defined $ROOT_OPS ? %$ROOT_OPS : (),
};

our $SCALAR_OPS = { 
    %$Template::Stash::SCALAR_OPS,
    'array' => sub { return [$_[0]] },
    defined $SCALAR_OPS ? %$SCALAR_OPS : (),
};

our $LIST_OPS = { 
    %$Template::Stash::LIST_OPS,
    'array' => sub { return $_[0] },
    defined $LIST_OPS ? %$LIST_OPS : (),
};
                    
our $HASH_OPS = { 
    %$Template::Stash::HASH_OPS,
    defined $HASH_OPS ? %$HASH_OPS : (),
};
 




sub new {
    my $class  = shift;
    my $params = ref $_[0] eq 'HASH' ? shift(@_) : { @_ };

    my $self   = {
        global  => { },
        %$params,
        %$ROOT_OPS,
        '_PARENT' => undef,
        '_CLASS'  => $class,
    };

    bless $self, $class;
}




sub clone {
    my ($self, $params) = @_;
    $params ||= { };

    # look out for magical 'import' argument which imports another hash
    my $import = $params->{ import };
    if (defined $import && UNIVERSAL::isa($import, 'HASH')) {
        delete $params->{ import };
    }
    else {
        undef $import;
    }

    my $clone = bless { 
        %$self,                 # copy all parent members
        %$params,               # copy all new data
        '_PARENT' => $self,     # link to parent
    }, ref $self;
    
    # perform hash import if defined
    &{ $HASH_OPS->{ import }}($clone, $import)
        if defined $import;

    return $clone;
}

        

sub declone {
    my $self = shift;
    $self->{ _PARENT } || $self;
}



sub get {
    my ($self, $ident, $args) = @_;
    my ($root, $result);
    $root = $self;

    if (ref $ident eq 'ARRAY'
        || ($ident =~ /\./) 
        && ($ident = [ map { s/\(.*$//; ($_, 0) } split(/\./, $ident) ])) {
        my $size = $#$ident;

        # if $ident is a list reference, then we evaluate each item in the 
        # identifier against the previous result, using the root stash 
        # ($self) as the first implicit 'result'...

        foreach (my $i = 0; $i <= $size; $i += 2) {
            if ( $i + 2 <= $size && ($ident->[$i+2] eq "scalar"
                                    || $ident->[$i+2] eq "ref") ) {
                $result = $self->_dotop($root, @$ident[$i, $i+1], 0,
                                        $ident->[$i+2]);
                $i += 2;
            } else {
                $result = $self->_dotop($root, @$ident[$i, $i+1]);
            }
            last unless defined $result;
            $root = $result;
        }
    }
    else {
        $result = $self->_dotop($root, $ident, $args);
    }

    return defined $result 
        ? $result 
        : $self->undefined($ident, $args);
}



sub set {
    my ($self, $ident, $value, $default) = @_;
    my ($root, $result, $error);

    $root = $self;

    ELEMENT: {
        if (ref $ident eq 'ARRAY'
            || ($ident =~ /\./) 
            && ($ident = [ map { s/\(.*$//; ($_, 0) }
                           split(/\./, $ident) ])) {

            # a compound identifier may contain multiple elements (e.g. 
            # foo.bar.baz) and we must first resolve all but the last, 
            # using _dotop() with the $lvalue flag set which will create 
            # intermediate hashes if necessary...
            my $size = $#$ident;
            foreach (my $i = 0; $i < $size - 2; $i += 2) {
                $result = $self->_dotop($root, @$ident[$i, $i+1], 1);
                last ELEMENT unless defined $result;
                $root = $result;
            }

            # then we call _assign() to assign the value to the last element
            $result = $self->_assign($root, @$ident[$size-1, $size], 
                                     $value, $default);
        }
        else {
            $result = $self->_assign($root, $ident, 0, $value, $default);
        }
    }

    return defined $result ? $result : '';
}



sub getref {
    my ($self, $ident, $args) = @_;
    my ($root, $item, $result);
    $root = $self;

    if (ref $ident eq 'ARRAY') {
        my $size = $#$ident;

        foreach (my $i = 0; $i <= $size; $i += 2) {
            ($item, $args) = @$ident[$i, $i + 1]; 
            last if $i >= $size - 2;  # don't evaluate last node
            last unless defined 
                ($root = $self->_dotop($root, $item, $args));
        }
    }
    else {
        $item = $ident;
    }

    if (defined $root) {
        return sub { my @args = (@{$args||[]}, @_);
                     $self->_dotop($root, $item, \@args);
                 }
    }
    else {
        return sub { '' };
    }
}





sub update {
    my ($self, $params) = @_;

    # look out for magical 'import' argument to import another hash
    my $import = $params->{ import };
    if (defined $import && UNIVERSAL::isa($import, 'HASH')) {
        @$self{ keys %$import } = values %$import;
        delete $params->{ import };
    }

    @$self{ keys %$params } = values %$params;
}




sub _dotop {
    my ($self, $root, $item, $args, $lvalue, $nextItem) = @_;
    my $rootref = ref $root;
    my ($value, @result, $ret, $retVal);
    $nextItem ||= "";
    my $scalarContext = 1 if ( $nextItem eq "scalar" );
    my $returnRef = 1     if ( $nextItem eq "ref" );

    $args ||= [ ];
    $lvalue ||= 0;


    # return undef without an error if either side of the dot is unviable
    # or if an attempt is made to access a private member, starting _ or .
    return undef
        unless defined($root) and defined($item) and $item !~ /^[\._]/;

    if (ref(\$root) eq "SCALAR" && !$lvalue &&
            (($value = $LIST_OPS->{ $item }) || $item =~ /^-?\d+$/) ) {
        #
        # Promote scalar to one element list, to be processed below.
        #
        $rootref = 'ARRAY';
        $root = [$root];
    }
    if ($rootref eq $self->{_CLASS} || $rootref eq 'HASH') {

        # if $root is a regular HASH or a Template::Stash kinda HASH (the 
        # *real* root of everything).  We first lookup the named key 
        # in the hash, or create an empty hash in its place if undefined
        # and the $lvalue flag is set.  Otherwise, we check the HASH_OPS
        # pseudo-methods table, calling the code if found, or return undef.

        if (defined($value = $root->{ $item })) {
            ($ret, $retVal, @result) = _dotop_return($value, $args, $returnRef,
                                                     $scalarContext);
            return $retVal if ( $ret );                     ## RETURN
        }
        elsif ($lvalue) {
            # we create an intermediate hash if this is an lvalue
            return $root->{ $item } = { };                  ## RETURN
        }
        elsif ($value = $HASH_OPS->{ $item }) {
            @result = &$value($root, @$args);               ## @result
        }
        elsif (ref $item eq 'ARRAY') {
            # hash slice
            return [@$root{@$item}];                       ## RETURN
        }
        elsif ($value = $SCALAR_OPS->{ $item }) {
            #
            # Apply scalar ops to every hash element, in place.
            #
            foreach my $key ( keys %$root ) {
                $root->{$key} = &$value($root->{$key}, @$args);
            }
        }
    }
    elsif ($rootref eq 'ARRAY') {

        # if root is an ARRAY then we check for a LIST_OPS pseudo-method 
        # (except for l-values for which it doesn't make any sense)
        # or return the numerical index into the array, or undef

        if (($value = $LIST_OPS->{ $item }) && ! $lvalue) {
            @result = &$value($root, @$args);               ## @result
        }
        elsif (($value = $SCALAR_OPS->{ $item }) && ! $lvalue) {
            #
            # Apply scalar ops to every array element, in place.
            #
            for ( my $i = 0 ; $i < @$root ; $i++ ) {
                $root->[$i] = &$value($root->[$i], @$args); ## @result
            }
        }
        elsif ($item =~ /^-?\d+$/) {
            $value = $root->[$item];
            ($ret, $retVal, @result) = _dotop_return($value, $args, $returnRef,
                                                     $scalarContext);
            return $retVal if ( $ret );                     ## RETURN
        }
        elsif (ref $item eq 'ARRAY' ) {
            # array slice
            return [@$root[@$item]];                        ## RETURN
        }
    }

    # NOTE: we do the can-can because UNIVSERAL::isa($something, 'UNIVERSAL')
    # doesn't appear to work with CGI, returning true for the first call
    # and false for all subsequent calls. 

    elsif (ref($root) && UNIVERSAL::can($root, 'can')) {

        # if $root is a blessed reference (i.e. inherits from the 
        # UNIVERSAL object base class) then we call the item as a method.
        # If that fails then we try to fallback on HASH behaviour if 
        # possible.
        return ref $root->can($item) if ( $returnRef );       ## RETURN
        eval {
            @result = $scalarContext ? scalar $root->$item(@$args)
                                     : $root->$item(@$args);  ## @result
        };

        if ($@) {
            # failed to call object method, so try some fallbacks
            if (UNIVERSAL::isa($root, 'HASH')
                    && defined($value = $root->{ $item })) {
                ($ret, $retVal, @result) = _dotop_return($value, $args,
                                                    $returnRef, $scalarContext);
                return $retVal if ( $ret );                     ## RETURN
            }
            elsif (UNIVERSAL::isa($root, 'ARRAY') 
                   && ($value = $LIST_OPS->{ $item })) {
                @result = &$value($root, @$args);
            }
            else {
                @result = (undef, $@);
            }
        }
    }
    elsif (($value = $SCALAR_OPS->{ $item }) && ! $lvalue) {

        # at this point, it doesn't look like we've got a reference to
        # anything we know about, so we try the SCALAR_OPS pseudo-methods
        # table (but not for l-values)

        @result = &$value($root, @$args);                   ## @result
    }
    elsif ($self->{ _DEBUG }) {
        die "don't know how to access [ $root ].$item\n";   ## DIE
    }
    else {
        @result = ();
    }

    # fold multiple return items into a list unless first item is undef
    if (defined $result[0]) {
        return ref(@result > 1 ? [ @result ] : $result[0])
                                            if ( $returnRef );  ## RETURN
        if ( $scalarContext ) {
            return scalar @result if ( @result > 1 );           ## RETURN
            return scalar(@{$result[0]}) if ( ref $result[0] eq "ARRAY" );
            return scalar(%{$result[0]}) if ( ref $result[0] eq "HASH" );
            return $result[0];                                  ## RETURN
        } else {
            return @result > 1 ? [ @result ] : $result[0];      ## RETURN
        }
    }
    elsif (defined $result[1]) {
        die $result[1];                                     ## DIE
    }
    elsif ($self->{ _DEBUG }) {
        die "$item is undefined\n";                         ## DIE
    }

    return undef;
}


sub _dotop_return
{
    my($value, $args, $returnRef, $scalarContext) = @_;
    my(@result);

    return (1, ref $value) if ( $returnRef );                     ## RETURN
    if ( $scalarContext ) {
        return (1, scalar(@$value)) if ref $value eq 'ARRAY';     ## RETURN
        return (1, scalar(%$value)) if ref $value eq 'HASH';      ## RETURN
        return (1, scalar($value))  unless ref $value eq 'CODE';  ## RETURN;
        @result = scalar &$value(@$args)                          ## @result;
    } else {
        return (1, $value) unless ref $value eq 'CODE';           ## RETURN
        @result = &$value(@$args);                                ## @result
    }
    return (0, undef, @result);
}



sub _assign {
    my ($self, $root, $item, $args, $value, $default) = @_;
    my $rootref = ref $root;
    my $result;
    $args ||= [ ];
    $default ||= 0;


    # return undef without an error if either side of the dot is unviable
    # or if an attempt is made to update a private member, starting _ or .
    return undef                                                ## RETURN
        unless $root and defined $item and $item !~ /^[\._]/;
    
    if ($rootref eq 'HASH' || $rootref eq $self->{_CLASS}) {
        # if the root is a hash we set the named key
        return ($root->{ $item } = $value)                      ## RETURN
            unless $default && $root->{ $item };
    }
    elsif ($rootref eq 'ARRAY' && $item =~ /^-?\d+$/) {
            # or set a list item by index number
            return ($root->[$item] = $value)                    ## RETURN
                unless $default && $root->{ $item };
    }
    elsif (UNIVERSAL::isa($root, 'UNIVERSAL')) {
        # try to call the item as a method of an object
        return $root->$item(@$args, $value);                    ## RETURN
    }
    else {
        die "don't know how to assign to [$root].[$item]\n";    ## DIE
    }

    return undef;
}



sub _dump {
    my $self   = shift;
    my $indent = shift || 1;
    my $buffer = '    ';
    my $pad    = $buffer x $indent;
    my $text   = '';
    local $" = ', ';

    my ($key, $value);


    return $text . "...excessive recursion, terminating\n"
        if $indent > 32;

    foreach $key (keys %$self) {

        $value = $self->{ $key };
        $value = '<undef>' unless defined $value;

        if (ref($value) eq 'ARRAY') {
            $value = "$value [@$value]";
        }
        $text .= sprintf("$pad%-8s => $value\n", $key);
        next if $key =~ /^\./;
        if (UNIVERSAL::isa($value, 'HASH')) {
            $text .= _dump($value, $indent + 1);
        }
    }
    $text;
}


1;

__END__


