
package Template::View;

use strict;
use warnings;
use base 'Template::Base';

our $VERSION  = 2.91;
our $DEBUG    = 0 unless defined $DEBUG;
our @BASEARGS = qw( context );
our $AUTOLOAD;
our $MAP = {
    HASH    => 'hash',
    ARRAY   => 'list',
    TEXT    => 'text',
    default => '',
};



sub _init {
    my ($self, $config) = @_;

    # move 'context' somewhere more private
    $self->{ _CONTEXT } = $self->{ context };
    delete $self->{ context };
    
    # generate table mapping object types to templates
    my $map = $config->{ map } || { };
    $map->{ default } = $config->{ default } unless defined $map->{ default };
    $self->{ map } = {
        %$MAP,
        %$map,
    };

    # local BLOCKs definition table
    $self->{ _BLOCKS } = $config->{ blocks } || { };
    
    # name of presentation method which printed objects might provide
    $self->{ method } = defined $config->{ method } 
                              ? $config->{ method } : 'present';
    
    # view is sealed by default preventing variable update after 
    # definition, however we don't actually seal a view until the 
    # END of the view definition
    my $sealed = $config->{ sealed };
    $sealed = 1 unless defined $sealed;
    $self->{ sealed } = $sealed ? 1 : 0;

    # copy remaining config items from $config or set defaults
    foreach my $arg (qw( base prefix suffix notfound silent )) {
        $self->{ $arg } = $config->{ $arg } || '';
    }

    # name of data item used by view()
    $self->{ item } = $config->{ item } || 'item';

    # map methods of form ${include_prefix}_foobar() to include('foobar')?
    $self->{ include_prefix } = $config->{ include_prefix } || 'include_';
    # what about mapping foobar() to include('foobar')?
    $self->{ include_naked  } = defined $config->{ include_naked } 
                                      ? $config->{ include_naked } : 1;

    # map methods of form ${view_prefix}_foobar() to include('foobar')?
    $self->{ view_prefix } = $config->{ view_prefix } || 'view_';
    # what about mapping foobar() to view('foobar')?
    $self->{ view_naked  } = $config->{ view_naked  } || 0;

    # the view is initially unsealed, allowing directives in the initial 
    # view template to create data items via the AUTOLOAD; once sealed via
    # call to seal(), the AUTOLOAD will not update any internal items.
    delete @$config{ qw( base method map default prefix suffix notfound item 
                         include_prefix include_naked silent sealed
                         view_prefix view_naked blocks ) };
    $config = { %{ $self->{ base }->{ data } }, %$config }
        if $self->{ base };
    $self->{ data   } = $config;
    $self->{ SEALED } = 0;

    return $self;
}



sub seal {
    my $self = shift;
    $self->{ SEALED } = $self->{ sealed };
}

sub unseal {
    my $self = shift;
    $self->{ SEALED } = 0;
}



sub clone {
    my $self   = shift;
    my $clone  = bless { %$self }, ref $self;
    my $config = ref $_[0] eq 'HASH' ? shift : { @_ };

    # merge maps
    $clone->{ map } = {
        %{ $self->{ map } },
        %{ $config->{ map } || { } },
    };

    # "map => { default=>'xxx' }" can be specified as "default => 'xxx'"
    $clone->{ map }->{ default } = $config->{ default }
        if defined $config->{ default };

    # update any remaining config items
    my @args = qw( base prefix suffix notfound item method include_prefix 
                   include_naked view_prefix view_naked );
    foreach my $arg (@args) {
        $clone->{ $arg } = $config->{ $arg } if defined $config->{ $arg };
    }
    push(@args, qw( default map ));
    delete @$config{ @args };

    # anything left is data
    my $data = $clone->{ data } = { %{ $self->{ data } } };
    @$data{ keys %$config } = values %$config;

    return $clone;
}



sub print {
    my $self = shift;

    # if final config hash is specified then create a clone and delegate to it
    # NOTE: potential problem when called print(\%data_hash1, \%data_hash2);
    if ((scalar @_ > 1) && (ref $_[-1] eq 'HASH')) {
        my $cfg = pop @_;
        my $clone = $self->clone($cfg)
            || return;
        return $clone->print(@_) 
            || $self->error($clone->error());
    }
    my ($item, $type, $template, $present);
    my $method = $self->{ method };
    my $map = $self->{ map };
    my $output = '';
    
    # print each argument
    foreach $item (@_) {
        my $newtype;
        
        if (! ($type = ref $item)) {
            # non-references are TEXT
            $type = 'TEXT';
            $template = $map->{ $type };
        }
        elsif (! defined ($template = $map->{ $type })) {
            # no specific map entry for object, maybe it implements a 
            # 'present' (or other) method?
            if ( $method && UNIVERSAL::can($item, $method) ) {
                $present = $item->$method($self);       ## call item method
                # undef returned indicates error, note that we expect 
                # $item to have called error() on the view
                return unless defined $present;
                $output .= $present;
                next;                                   ## NEXT
            }   
            elsif ( ref($item) eq 'HASH' 
                    && defined($newtype = $item->{$method})
                    && defined($template = $map->{"$method=>$newtype"})) {
            }
            elsif ( defined($newtype)
                    && defined($template = $map->{"$method=>*"}) ) {
                $template =~ s/\*/$newtype/;
            }    
            elsif (! ($template = $map->{ default }) ) {
                # default not defined, so construct template name from type
                ($template = $type) =~ s/\W+/_/g;
            }
        }
        $self->DEBUG("printing view '", $template || '', "', $item\n") if $DEBUG;
        $output .= $self->view($template, $item)
            if $template;
    }
    return $output;
}



sub view {
    my ($self, $template, $item) = splice(@_, 0, 3);
    my $vars = ref $_[0] eq 'HASH' ? shift : { @_ };
    $vars->{ $self->{ item } } = $item if defined $item;
    $self->include($template, $vars);
}



sub include {
    my ($self, $template, $vars) = @_;
    my $context = $self->{ _CONTEXT };

    $template = $self->template($template);

    $vars = { } unless ref $vars eq 'HASH';
    $vars->{ view } ||= $self;

    $context->include( $template, $vars );

}



sub template {
    my ($self, $name) = @_;
    my $context = $self->{ _CONTEXT };
    return $context->throw(Template::Constants::ERROR_VIEW,
                           "no view template specified")
        unless $name;

    my $notfound = $self->{ notfound };
    my $base = $self->{ base };
    my ($template, $block, $error);

    return $block
        if ($block = $self->{ _BLOCKS }->{ $name });
    
    # try the named template
    $template = $self->template_name($name);
    $self->DEBUG("looking for $template\n") if $DEBUG;
    eval { $template = $context->template($template) };

    # try asking the base view if not found
    if (($error = $@) && $base) {
        $self->DEBUG("asking base for $name\n") if $DEBUG;
        eval { $template = $base->template($name) };
    }

    # try the 'notfound' template (if defined) if that failed
    if (($error = $@) && $notfound) {
        unless ($template = $self->{ _BLOCKS }->{ $notfound }) {
            $notfound = $self->template_name($notfound);
            $self->DEBUG("not found, looking for $notfound\n") if $DEBUG;
            eval { $template = $context->template($notfound) };

            return $context->throw(Template::Constants::ERROR_VIEW, $error)
                if $@;  # return first error
        }
    }
    elsif ($error) {
        $self->DEBUG("no 'notfound'\n") 
            if $DEBUG;
        return $context->throw(Template::Constants::ERROR_VIEW, $error);
    }
    return $template;
}

    

sub template_name {
    my ($self, $template) = @_;
    $template = $self->{ prefix } . $template . $self->{ suffix }
        if $template;

    $self->DEBUG("template name: $template\n") if $DEBUG;
    return $template;
}



sub default {
    my $self = shift;
    return @_ ? ($self->{ map }->{ default } = shift) 
              :  $self->{ map }->{ default };
}




sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    if ($item =~ /^[\._]/) {
        return $self->{ _CONTEXT }->throw(Template::Constants::ERROR_VIEW,
                            "attempt to view private member: $item");
    }
    elsif (exists $self->{ $item }) {
        # update existing config item (e.g. 'prefix') if unsealed
        return $self->{ _CONTEXT }->throw(Template::Constants::ERROR_VIEW,
                            "cannot update config item in sealed view: $item")
            if @_ && $self->{ SEALED };
        $self->DEBUG("accessing item: $item\n") if $DEBUG;
        return @_ ? ($self->{ $item } = shift) : $self->{ $item };
    }
    elsif (exists $self->{ data }->{ $item }) {
        # get/update existing data item (must be unsealed to update)
        if (@_ && $self->{ SEALED }) {
            return $self->{ _CONTEXT }->throw(Template::Constants::ERROR_VIEW,
                                  "cannot update item in sealed view: $item")
                unless $self->{ silent };
            # ignore args if silent
            @_ = ();
        }
        $self->DEBUG(@_ ? "updating data item: $item <= $_[0]\n" 
                        : "returning data item: $item\n") if $DEBUG;
        return @_ ? ($self->{ data }->{ $item } = shift) 
                  :  $self->{ data }->{ $item };
    }
    elsif (@_ && ! $self->{ SEALED }) {
        # set data item if unsealed
        $self->DEBUG("setting unsealed data: $item => @_\n") if $DEBUG;
        $self->{ data }->{ $item } = shift;
    }
    elsif ($item =~ s/^$self->{ view_prefix }//) {
        $self->DEBUG("returning view($item)\n") if $DEBUG;
        return $self->view($item, @_);
    }
    elsif ($item =~ s/^$self->{ include_prefix }//) {
        $self->DEBUG("returning include($item)\n") if $DEBUG;
        return $self->include($item, @_);
    }
    elsif ($self->{ include_naked }) {
        $self->DEBUG("returning naked include($item)\n") if $DEBUG;
        return $self->include($item, @_);
    }
    elsif ($self->{ view_naked }) {
        $self->DEBUG("returning naked view($item)\n") if $DEBUG;
        return $self->view($item, @_);
    }
    else {
        return $self->{ _CONTEXT }->throw(Template::Constants::ERROR_VIEW,
                                         "no such view member: $item");
    }
}


1;


__END__






