
package Template::Stash;

use strict;
use warnings;
use Template::VMethods;
use Template::Exception;
use Scalar::Util qw( blessed reftype );

our $VERSION    = 2.91;
our $DEBUG      = 0 unless defined $DEBUG;
our $PRIVATE    = qr/^[_.]/;
our $UNDEF_TYPE = 'var.undef';
our $UNDEF_INFO = 'undefined variable: %s';

*dotop = \&_dotop;



our $ROOT_OPS = defined $ROOT_OPS 
    ? { %{$Template::VMethods::ROOT_VMETHODS}, %$ROOT_OPS }
    : $Template::VMethods::ROOT_VMETHODS;

our $SCALAR_OPS = defined $SCALAR_OPS 
    ? { %{$Template::VMethods::TEXT_VMETHODS}, %$SCALAR_OPS }
    : $Template::VMethods::TEXT_VMETHODS;

our $HASH_OPS = defined $HASH_OPS 
    ? { %{$Template::VMethods::HASH_VMETHODS}, %$HASH_OPS }
    : $Template::VMethods::HASH_VMETHODS;

our $LIST_OPS = defined $LIST_OPS 
    ? { %{$Template::VMethods::LIST_VMETHODS}, %$LIST_OPS }
    : $Template::VMethods::LIST_VMETHODS;



sub define_vmethod {
    my ($class, $type, $name, $sub) = @_;
    my $op;
    $type = lc $type;

    if ($type =~ /^scalar|item$/) {
        $op = $SCALAR_OPS;
    }
    elsif ($type eq 'hash') {
        $op = $HASH_OPS;
    }
    elsif ($type =~ /^list|array$/) {
        $op = $LIST_OPS;
    }
    else {
        die "invalid vmethod type: $type\n";
    }

    $op->{ $name } = $sub;

    return 1;
}




sub new {
    my $class  = shift;
    my $params = ref $_[0] eq 'HASH' ? shift(@_) : { @_ };

    my $self   = {
        global  => { },
        %$params,
        %$ROOT_OPS,
        '_PARENT' => undef,
    };

    bless $self, $class;
}




sub clone {
    my ($self, $params) = @_;
    $params ||= { };

    # look out for magical 'import' argument which imports another hash
    my $import = $params->{ import };
    if (defined $import && ref $import eq 'HASH') {
        delete $params->{ import };
    }
    else {
        undef $import;
    }

    my $clone = bless { 
        %$self,         # copy all parent members
        %$params,       # copy all new data
        '_PARENT' => $self,     # link to parent
    }, ref $self;
    
    # perform hash import if defined
    &{ $HASH_OPS->{ import } }($clone, $import)
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
            $result = $self->_dotop($root, @$ident[$i, $i+1]);
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
    if (defined $import && ref $import eq 'HASH') {
        @$self{ keys %$import } = values %$import;
        delete $params->{ import };
    }

    @$self{ keys %$params } = values %$params;
}



sub undefined {
    my ($self, $ident, $args) = @_;

    if ($self->{ _STRICT }) {
        # Sorry, but we can't provide a sensible source file and line without
        # re-designing the whole architecure of TT (see TT3)
        die Template::Exception->new(
            $UNDEF_TYPE, 
            sprintf(
                $UNDEF_INFO, 
                $self->_reconstruct_ident($ident)
            )
        ) if $self->{ _STRICT };
    }
    else {
        # There was a time when I thought this was a good idea. But it's not.
        return '';
    }
}

sub _reconstruct_ident {
    my ($self, $ident) = @_;
    my ($name, $args, @output);
    my @input = ref $ident eq 'ARRAY' ? @$ident : ($ident);

    while (@input) {
        $name = shift @input;
        $args = shift @input || 0;
        $name .= '(' . join(', ', map { /^\d+$/ ? $_ : "'$_'" } @$args) . ')'
            if $args && ref $args eq 'ARRAY';
        push(@output, $name);
    }
    
    return join('.', @output);
}




sub _dotop {
    my ($self, $root, $item, $args, $lvalue) = @_;
    my $rootref = ref $root;
    my $atroot  = (blessed $root && $root->isa(ref $self));
    my ($value, @result);

    $args ||= [ ];
    $lvalue ||= 0;


    # return undef without an error if either side of the dot is unviable
    return undef unless defined($root) and defined($item);

    # or if an attempt is made to access a private member, starting _ or .
    return undef if $PRIVATE && $item =~ /$PRIVATE/;

    if ($atroot || $rootref eq 'HASH') {
        # if $root is a regular HASH or a Template::Stash kinda HASH (the 
        # *real* root of everything).  We first lookup the named key 
        # in the hash, or create an empty hash in its place if undefined
        # and the $lvalue flag is set.  Otherwise, we check the HASH_OPS
        # pseudo-methods table, calling the code if found, or return undef.
        
        if (defined($value = $root->{ $item })) {
            return $value unless ref $value eq 'CODE';      ## RETURN
            @result = &$value(@$args);                      ## @result
        }
        elsif ($lvalue) {
            # we create an intermediate hash if this is an lvalue
            return $root->{ $item } = { };                  ## RETURN
        }
        # ugly hack: only allow import vmeth to be called on root stash
        elsif (($value = $HASH_OPS->{ $item })
               && ! $atroot || $item eq 'import') {
            @result = &$value($root, @$args);               ## @result
        }
        elsif ( ref $item eq 'ARRAY' ) {
            # hash slice
            return [@$root{@$item}];                        ## RETURN
        }
    }
    elsif ($rootref eq 'ARRAY') {    
        # if root is an ARRAY then we check for a LIST_OPS pseudo-method 
        # or return the numerical index into the array, or undef
        if ($value = $LIST_OPS->{ $item }) {
            @result = &$value($root, @$args);               ## @result
        }
        elsif ($item =~ /^-?\d+$/) {
            $value = $root->[$item];
            return $value unless ref $value eq 'CODE';      ## RETURN
            @result = &$value(@$args);                      ## @result
        }
        elsif ( ref $item eq 'ARRAY' ) {
            # array slice
            return [@$root[@$item]];                        ## RETURN
        }
    }
    
    # NOTE: we do the can-can because UNIVSERAL::isa($something, 'UNIVERSAL')
    # doesn't appear to work with CGI, returning true for the first call
    # and false for all subsequent calls. 
    
    # UPDATE: that doesn't appear to be the case any more
    
    elsif (blessed($root) && $root->can('can')) {

        # if $root is a blessed reference (i.e. inherits from the 
        # UNIVERSAL object base class) then we call the item as a method.
        # If that fails then we try to fallback on HASH behaviour if 
        # possible.
        eval { @result = $root->$item(@$args); };       
        
        if ($@) {
            # temporary hack - required to propogate errors thrown
            # by views; if $@ is a ref (e.g. Template::Exception
            # object then we assume it's a real error that needs
            # real throwing

            my $class = ref($root) || $root;
            die $@ if ref($@) || ($@ !~ /Can't locate object method "\Q$item\E" via package "\Q$class\E"/);

            # failed to call object method, so try some fallbacks
            if (reftype $root eq 'HASH') {
                if( defined($value = $root->{ $item })) {
                    return $value unless ref $value eq 'CODE';      ## RETURN
                    @result = &$value(@$args);
                }
                elsif ($value = $HASH_OPS->{ $item }) {
                    @result = &$value($root, @$args);
                }
                elsif ($value = $LIST_OPS->{ $item }) {
                    @result = &$value([$root], @$args);
                }
            }
            elsif (reftype $root eq 'ARRAY') {
                if( $value = $LIST_OPS->{ $item }) {
                   @result = &$value($root, @$args);
                }
                elsif( $item =~ /^-?\d+$/ ) {
                   $value = $root->[$item];
                   return $value unless ref $value eq 'CODE';      ## RETURN
                   @result = &$value(@$args);                      ## @result
                }
                elsif ( ref $item eq 'ARRAY' ) {
                    # array slice
                    return [@$root[@$item]];                        ## RETURN
                }
            }
            elsif ($value = $SCALAR_OPS->{ $item }) {
                @result = &$value($root, @$args);
            }
            elsif ($value = $LIST_OPS->{ $item }) {
                @result = &$value([$root], @$args);
            }
            elsif ($self->{ _DEBUG }) {
                @result = (undef, $@);
            }
        }
    }
    elsif (($value = $SCALAR_OPS->{ $item }) && ! $lvalue) {
        # at this point, it doesn't look like we've got a reference to
        # anything we know about, so we try the SCALAR_OPS pseudo-methods
        # table (but not for l-values)
        @result = &$value($root, @$args);           ## @result
    }
    elsif (($value = $LIST_OPS->{ $item }) && ! $lvalue) {
        # last-ditch: can we promote a scalar to a one-element
        # list and apply a LIST_OPS virtual method?
        @result = &$value([$root], @$args);
    }
    elsif ($self->{ _DEBUG }) {
        die "don't know how to access [ $root ].$item\n";   ## DIE
    }
    else {
        @result = ();
    }

    # fold multiple return items into a list unless first item is undef
    if (defined $result[0]) {
        return                              ## RETURN
        scalar @result > 1 ? [ @result ] : $result[0];
    }
    elsif (defined $result[1]) {
        die $result[1];                     ## DIE
    }
    elsif ($self->{ _DEBUG }) {
        die "$item is undefined\n";         ## DIE
    }

    return undef;
}



sub _assign {
    my ($self, $root, $item, $args, $value, $default) = @_;
    my $rootref = ref $root;
    my $atroot  = ($root eq $self);
    my $result;
    $args ||= [ ];
    $default ||= 0;

    # return undef without an error if either side of the dot is unviable
    return undef unless $root and defined $item;

    # or if an attempt is made to update a private member, starting _ or .
    return undef if $PRIVATE && $item =~ /$PRIVATE/;
    
    if ($rootref eq 'HASH' || $atroot) {
        # if the root is a hash we set the named key
        return ($root->{ $item } = $value)          ## RETURN
            unless $default && $root->{ $item };
    }
    elsif ($rootref eq 'ARRAY' && $item =~ /^-?\d+$/) {
        # or set a list item by index number
        return ($root->[$item] = $value)            ## RETURN
            unless $default && $root->{ $item };
    }
    elsif (blessed($root)) {
        # try to call the item as a method of an object
        
        return $root->$item(@$args, $value)         ## RETURN
            unless $default && $root->$item();
        
    }
    else {
        die "don't know how to assign to [$root].[$item]\n";    ## DIE
    }

    return undef;
}



sub _dump {
    my $self   = shift;
    return "[Template::Stash] " . $self->_dump_frame(2);
}

sub _dump_frame {
    my ($self, $indent) = @_;
    $indent ||= 1;
    my $buffer = '    ';
    my $pad    = $buffer x $indent;
    my $text   = "{\n";
    local $" = ', ';

    my ($key, $value);

    return $text . "...excessive recursion, terminating\n"
        if $indent > 32;
    
    foreach $key (keys %$self) {
        $value = $self->{ $key };
        $value = '<undef>' unless defined $value;
        next if $key =~ /^\./;
        if (ref($value) eq 'ARRAY') {
            $value = '[ ' . join(', ', map { defined $_ ? $_ : '<undef>' }
                                 @$value) . ' ]';
        }
        elsif (ref $value eq 'HASH') {
            $value = _dump_frame($value, $indent + 1);
        }
        
        $text .= sprintf("$pad%-16s => $value\n", $key);
    }
    $text .= $buffer x ($indent - 1) . '}';
    return $text;
}


1;

__END__


