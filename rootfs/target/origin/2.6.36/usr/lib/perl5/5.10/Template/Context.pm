
package Template::Context;

use strict;
use warnings;
use base 'Template::Base';

use Template::Base;
use Template::Config;
use Template::Constants;
use Template::Exception;
use Scalar::Util 'blessed';

use constant DOCUMENT         => 'Template::Document';
use constant EXCEPTION        => 'Template::Exception';
use constant BADGER_EXCEPTION => 'Badger::Exception';

our $VERSION = 2.98;
our $DEBUG   = 0 unless defined $DEBUG;
our $DEBUG_FORMAT = "\n## \$file line \$line : [% \$text %] ##\n";
our $VIEW_CLASS   = 'Template::View';
our $AUTOLOAD;



sub template {
    my ($self, $name) = @_;
    my ($prefix, $blocks, $defblocks, $provider, $template, $error);
    my ($shortname, $blockname, $providers);

    $self->debug("template($name)") if $self->{ DEBUG };

    # references to Template::Document (or sub-class) objects objects, or
    # CODE references are assumed to be pre-compiled templates and are
    # returned intact
    return $name
        if (blessed($name) && $name->isa(DOCUMENT))
        || ref($name) eq 'CODE';

    $shortname = $name;

    unless (ref $name) {
        
        $self->debug("looking for block [$name]") if $self->{ DEBUG };

        # we first look in the BLOCKS hash for a BLOCK that may have 
        # been imported from a template (via PROCESS)
        return $template
            if ($template = $self->{ BLOCKS }->{ $name });
        
        # then we iterate through the BLKSTACK list to see if any of the
        # Template::Documents we're visiting define this BLOCK
        foreach $blocks (@{ $self->{ BLKSTACK } }) {
            return $template
                if $blocks && ($template = $blocks->{ $name });
        }
        
        # now it's time to ask the providers, so we look to see if any 
        # prefix is specified to indicate the desired provider set.
        if ($^O eq 'MSWin32') {
            # let C:/foo through
            $prefix = $1 if $shortname =~ s/^(\w{2,})://o;
        }
        else {
            $prefix = $1 if $shortname =~ s/^(\w+)://;
        }
        
        if (defined $prefix) {
            $providers = $self->{ PREFIX_MAP }->{ $prefix } 
            || return $self->throw( Template::Constants::ERROR_FILE,
                                    "no providers for template prefix '$prefix'");
        }
    }
    $providers = $self->{ PREFIX_MAP }->{ default }
        || $self->{ LOAD_TEMPLATES }
            unless $providers;


    # Finally we try the regular template providers which will 
    # handle references to files, text, etc., as well as templates
    # reference by name.  If

    $blockname = '';
    while ($shortname) {
        $self->debug("asking providers for [$shortname] [$blockname]") 
            if $self->{ DEBUG };

        foreach my $provider (@$providers) {
            ($template, $error) = $provider->fetch($shortname, $prefix);
            if ($error) {
                if ($error == Template::Constants::STATUS_ERROR) {
                    # $template contains exception object
                    if (blessed($template) && $template->isa(EXCEPTION)
                        && $template->type eq Template::Constants::ERROR_FILE) {
                        $self->throw($template);
                    }
                    else {
                        $self->throw( Template::Constants::ERROR_FILE, $template );
                    }
                }
                # DECLINE is ok, carry on
            }
            elsif (length $blockname) {
                return $template 
                    if $template = $template->blocks->{ $blockname };
            }
            else {
                return $template;
            }
        }
        
        last if ref $shortname || ! $self->{ EXPOSE_BLOCKS };
        $shortname =~ s{/([^/]+)$}{} || last;
        $blockname = length $blockname ? "$1/$blockname" : $1;
    }
        
    $self->throw(Template::Constants::ERROR_FILE, "$name: not found");
}



sub plugin {
    my ($self, $name, $args) = @_;
    my ($provider, $plugin, $error);
    
    $self->debug("plugin($name, ", defined $args ? @$args : '[ ]', ')')
        if $self->{ DEBUG };
    
    # request the named plugin from each of the LOAD_PLUGINS providers in turn
    foreach my $provider (@{ $self->{ LOAD_PLUGINS } }) {
        ($plugin, $error) = $provider->fetch($name, $args, $self);
        return $plugin unless $error;
        if ($error == Template::Constants::STATUS_ERROR) {
            $self->throw($plugin) if ref $plugin;
            $self->throw(Template::Constants::ERROR_PLUGIN, $plugin);
        }
    }
    
    $self->throw(Template::Constants::ERROR_PLUGIN, "$name: plugin not found");
}



sub filter {
    my ($self, $name, $args, $alias) = @_;
    my ($provider, $filter, $error);
    
    $self->debug("filter($name, ", 
                 defined $args  ? @$args : '[ ]', 
                 defined $alias ? $alias : '<no alias>', ')')
        if $self->{ DEBUG };
    
    # use any cached version of the filter if no params provided
    return $filter 
        if ! $args && ! ref $name
            && ($filter = $self->{ FILTER_CACHE }->{ $name });
    
    # request the named filter from each of the FILTERS providers in turn
    foreach my $provider (@{ $self->{ LOAD_FILTERS } }) {
        ($filter, $error) = $provider->fetch($name, $args, $self);
        last unless $error;
        if ($error == Template::Constants::STATUS_ERROR) {
            $self->throw($filter) if ref $filter;
            $self->throw(Template::Constants::ERROR_FILTER, $filter);
        }
        # return $self->error($filter)
        #    if $error == &Template::Constants::STATUS_ERROR;
    }
    
    return $self->error("$name: filter not found")
        unless $filter;
    
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # commented out by abw on 19 Nov 2001 to fix problem with xmlstyle
    # plugin which may re-define a filter by calling define_filter()
    # multiple times.  With the automatic aliasing/caching below, any
    # new filter definition isn't seen.  Don't think this will cause
    # any problems as filters explicitly supplied with aliases will
    # still work as expected.
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # alias defaults to name if undefined
    # $alias = $name
    #     unless defined($alias) or ref($name) or $args;

    # cache FILTER if alias is valid
    $self->{ FILTER_CACHE }->{ $alias } = $filter
        if $alias;

    return $filter;
}



sub view {
    my $self = shift;
    require Template::View;
    return $VIEW_CLASS->new($self, @_)
        || $self->throw(&Template::Constants::ERROR_VIEW, 
                        $VIEW_CLASS->error);
}



sub process {
    my ($self, $template, $params, $localize) = @_;
    my ($trim, $blocks) = @$self{ qw( TRIM BLOCKS ) };
    my (@compiled, $name, $compiled);
    my ($stash, $component, $tblocks, $error, $tmpout);
    my $output = '';
    
    $template = [ $template ] unless ref $template eq 'ARRAY';
    
    $self->debug("process([ ", join(', '), @$template, ' ], ', 
                 defined $params ? $params : '<no params>', ', ', 
                 $localize ? '<localized>' : '<unlocalized>', ')')
        if $self->{ DEBUG };
    
    # fetch compiled template for each name specified
    foreach $name (@$template) {
        push(@compiled, $self->template($name));
    }

    if ($localize) {
        # localise the variable stash with any parameters passed
        $stash = $self->{ STASH } = $self->{ STASH }->clone($params);
    } else {
        # update stash with any new parameters passed
        $self->{ STASH }->update($params);
        $stash = $self->{ STASH };
    }

    eval {
        # save current component
        eval { $component = $stash->get('component') };

        foreach $name (@$template) {
            $compiled = shift @compiled;
            my $element = ref $compiled eq 'CODE' 
                ? { (name => (ref $name ? '' : $name), modtime => time()) }
                : $compiled;

            if (blessed($component) && $component->isa(DOCUMENT)) {
                $element->{ caller } = $component->{ name };
                $element->{ callers } = $component->{ callers } || [];
                push(@{$element->{ callers }}, $element->{ caller });
            }

            $stash->set('component', $element);
            
            unless ($localize) {
                # merge any local blocks defined in the Template::Document
                # into our local BLOCKS cache
                @$blocks{ keys %$tblocks } = values %$tblocks
                    if (blessed($compiled) && $compiled->isa(DOCUMENT))
                    && ($tblocks = $compiled->blocks);
            }
            
            if (ref $compiled eq 'CODE') {
                $tmpout = &$compiled($self);
            }
            elsif (ref $compiled) {
                $tmpout = $compiled->process($self);
            }
            else {
                $self->throw('file', 
                             "invalid template reference: $compiled");
            }
            
            if ($trim) {
                for ($tmpout) {
                    s/^\s+//;
                    s/\s+$//;
                }
            }
            $output .= $tmpout;

            # pop last item from callers.  
            # NOTE - this will not be called if template throws an 
            # error.  The whole issue of caller and callers should be 
            # revisited to try and avoid putting this info directly into
            # the component data structure.  Perhaps use a local element
            # instead?

            pop(@{$element->{ callers }})
                if (blessed($component) && $component->isa(DOCUMENT));
        }
        $stash->set('component', $component);
    };
    $error = $@;
    
    if ($localize) {
        # ensure stash is delocalised before dying
        $self->{ STASH } = $self->{ STASH }->declone();
    }
    
    $self->throw(ref $error 
                 ? $error : (Template::Constants::ERROR_FILE, $error))
        if $error;
    
    return $output;
}



sub include {
    my ($self, $template, $params) = @_;
    return $self->process($template, $params, 'localize me!');
}


sub insert {
    my ($self, $file) = @_;
    my ($prefix, $providers, $text, $error);
    my $output = '';

    my $files = ref $file eq 'ARRAY' ? $file : [ $file ];

    $self->debug("insert([ ", join(', '), @$files, " ])") 
        if $self->{ DEBUG };


    FILE: foreach $file (@$files) {
        my $name = $file;

        if ($^O eq 'MSWin32') {
            # let C:/foo through
            $prefix = $1 if $name =~ s/^(\w{2,})://o;
        }
        else {
            $prefix = $1 if $name =~ s/^(\w+)://;
        }

        if (defined $prefix) {
            $providers = $self->{ PREFIX_MAP }->{ $prefix } 
                || return $self->throw(Template::Constants::ERROR_FILE,
                    "no providers for file prefix '$prefix'");
        }
        else {
            $providers = $self->{ PREFIX_MAP }->{ default }
                || $self->{ LOAD_TEMPLATES };
        }

        foreach my $provider (@$providers) {
            ($text, $error) = $provider->load($name, $prefix);
            next FILE unless $error;
            if ($error == Template::Constants::STATUS_ERROR) {
                $self->throw($text) if ref $text;
                $self->throw(Template::Constants::ERROR_FILE, $text);
            }
        }
        $self->throw(Template::Constants::ERROR_FILE, "$file: not found");
    }
    continue {
        $output .= $text;
    }
    return $output;
}



sub throw {
    my ($self, $error, $info, $output) = @_;
    local $" = ', ';

    # die! die! die!
    if (blessed($error) && $error->isa(EXCEPTION)) {
        die $error;
    }
    elsif (blessed($error) && $error->isa(BADGER_EXCEPTION)) {
        # convert a Badger::Exception to a Template::Exception so that
        # things continue to work during the transition to Badger
        die EXCEPTION->new($error->type, $error->info);
    }
    elsif (defined $info) {
        die (EXCEPTION->new($error, $info, $output));
    }
    else {
        $error ||= '';
        die (EXCEPTION->new('undef', $error, $output));
    }

    # not reached
}



sub catch {
    my ($self, $error, $output) = @_;

    if ( blessed($error) 
      && ( $error->isa(EXCEPTION) || $error->isa(BADGER_EXCEPTION) ) ) {
        $error->text($output) if $output;
        return $error;
    }
    else {
        return EXCEPTION->new('undef', $error, $output);
    }
}



sub localise {
    my $self = shift;
    $self->{ STASH } = $self->{ STASH }->clone(@_);
}

sub delocalise {
    my $self = shift;
    $self->{ STASH } = $self->{ STASH }->declone();
}



sub visit {
    my ($self, $document, $blocks) = @_;
    unshift(@{ $self->{ BLKSTACK } }, $blocks)
}



sub leave {
    my $self = shift;
    shift(@{ $self->{ BLKSTACK } });
}



sub define_block {
    my ($self, $name, $block) = @_;
    $block = $self->template(\$block)
    || return undef
        unless ref $block;
    $self->{ BLOCKS }->{ $name } = $block;
}



sub define_filter {
    my ($self, $name, $filter, $is_dynamic) = @_;
    my ($result, $error);
    $filter = [ $filter, 1 ] if $is_dynamic;

    foreach my $provider (@{ $self->{ LOAD_FILTERS } }) {
    ($result, $error) = $provider->store($name, $filter);
    return 1 unless $error;
    $self->throw(&Template::Constants::ERROR_FILTER, $result)
        if $error == &Template::Constants::STATUS_ERROR;
    }
    $self->throw(&Template::Constants::ERROR_FILTER, 
         "FILTER providers declined to store filter $name");
}

sub define_view {
    my ($self, $name, $params) = @_;
    my $base;

    if (defined $params->{ base }) {
        my $base = $self->{ STASH }->get($params->{ base });

        return $self->throw(
            &Template::Constants::ERROR_VIEW, 
            "view base is not defined: $params->{ base }"
        ) unless $base;

        return $self->throw(
            &Template::Constants::ERROR_VIEW, 
            "view base is not a $VIEW_CLASS object: $params->{ base } => $base"
        ) unless blessed($base) && $base->isa($VIEW_CLASS);
        
        $params->{ base } = $base;
    }
    my $view = $self->view($params);
    $view->seal();
    $self->{ STASH }->set($name, $view);
}

sub define_views {
    my ($self, $views) = @_;
    
    # a list reference is better because the order is deterministic (and so
    # allows an earlier VIEW to be the base for a later VIEW), but we'll 
    # accept a hash reference and assume that the user knows the order of
    # processing is undefined
    $views = [ %$views ] 
        if ref $views eq 'HASH';
    
    # make of copy so we don't destroy the original list reference
    my @items = @$views;
    my ($name, $view);
    
    while (@items) {
        $self->define_view(splice(@items, 0, 2));
    }
}



sub reset {
    my ($self, $blocks) = @_;
    $self->{ BLKSTACK } = [ ];
    $self->{ BLOCKS   } = { %{ $self->{ INIT_BLOCKS } } };
}



sub stash {
    return $_[0]->{ STASH };
}


sub define_vmethod {
    my $self = shift;
    $self->stash->define_vmethod(@_);
}



sub debugging {
    my $self = shift;
    my $hash = ref $_[-1] eq 'HASH' ? pop : { };
    my @args = @_;

    if (@args) {
    if ($args[0] =~ /^on|1$/i) {
        $self->{ DEBUG_DIRS } = 1;
        shift(@args);
    }
    elsif ($args[0] =~ /^off|0$/i) {
        $self->{ DEBUG_DIRS } = 0;
        shift(@args);
    }
    }

    if (@args) {
    if ($args[0] =~ /^msg$/i) {
            return unless $self->{ DEBUG_DIRS };
        my $format = $self->{ DEBUG_FORMAT };
        $format = $DEBUG_FORMAT unless defined $format;
        $format =~ s/\$(\w+)/$hash->{ $1 }/ge;
        return $format;
    }
    elsif ($args[0] =~ /^format$/i) {
        $self->{ DEBUG_FORMAT } = $args[1];
    }
    # else ignore
    }

    return '';
}



sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;
    my $result;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    warn "no such context method/member: $method\n"
    unless defined ($result = $self->{ uc $method });

    return $result;
}



sub DESTROY {
    my $self = shift;
    undef $self->{ STASH };
}





sub _init {
    my ($self, $config) = @_;
    my ($name, $item, $method, $block, $blocks);
    my @itemlut = ( 
        LOAD_TEMPLATES => 'provider',
        LOAD_PLUGINS   => 'plugins',
        LOAD_FILTERS   => 'filters' 
    );

    # LOAD_TEMPLATE, LOAD_PLUGINS, LOAD_FILTERS - lists of providers
    while (($name, $method) = splice(@itemlut, 0, 2)) {
        $item = $config->{ $name } 
            || Template::Config->$method($config)
            || return $self->error($Template::Config::ERROR);
        $self->{ $name } = ref $item eq 'ARRAY' ? $item : [ $item ];
    }

    my $providers  = $self->{ LOAD_TEMPLATES };
    my $prefix_map = $self->{ PREFIX_MAP } = $config->{ PREFIX_MAP } || { };
    while (my ($key, $val) = each %$prefix_map) {
        $prefix_map->{ $key } = [ ref $val ? $val : 
                                  map { $providers->[$_] } split(/\D+/, $val) ]
                                  unless ref $val eq 'ARRAY';
    }

    # STASH
    $self->{ STASH } = $config->{ STASH } || do {
        my $predefs  = $config->{ VARIABLES } 
            || $config->{ PRE_DEFINE } 
            || { };

        # hack to get stash to know about debug mode
        $predefs->{ _DEBUG } = ( ($config->{ DEBUG } || 0)
                                 & &Template::Constants::DEBUG_UNDEF ) ? 1 : 0
                                 unless defined $predefs->{ _DEBUG };
        $predefs->{ _STRICT } = $config->{ STRICT };
        
        Template::Config->stash($predefs)
            || return $self->error($Template::Config::ERROR);
    };
    
    # compile any template BLOCKS specified as text
    $blocks = $config->{ BLOCKS } || { };
    $self->{ INIT_BLOCKS } = $self->{ BLOCKS } = { 
        map {
            $block = $blocks->{ $_ };
            $block = $self->template(\$block)
                || return undef
                unless ref $block;
            ($_ => $block);
        } 
        keys %$blocks
    };

    # define any VIEWS
    $self->define_views( $config->{ VIEWS } )
        if $config->{ VIEWS };

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # RECURSION - flag indicating is recursion into templates is supported
    # EVAL_PERL - flag indicating if PERL blocks should be processed
    # TRIM      - flag to remove leading and trailing whitespace from output
    # BLKSTACK  - list of hashes of BLOCKs defined in current template(s)
    # CONFIG    - original configuration hash
    # EXPOSE_BLOCKS - make blocks visible as pseudo-files
    # DEBUG_FORMAT  - format for generating template runtime debugging messages
    # DEBUG         - format for generating template runtime debugging messages

    $self->{ RECURSION } = $config->{ RECURSION } || 0;
    $self->{ EVAL_PERL } = $config->{ EVAL_PERL } || 0;
    $self->{ TRIM      } = $config->{ TRIM } || 0;
    $self->{ BLKSTACK  } = [ ];
    $self->{ CONFIG    } = $config;
    $self->{ EXPOSE_BLOCKS } = defined $config->{ EXPOSE_BLOCKS }
                                     ? $config->{ EXPOSE_BLOCKS } 
                                     : 0;

    $self->{ DEBUG_FORMAT  } =  $config->{ DEBUG_FORMAT };
    $self->{ DEBUG_DIRS    } = ($config->{ DEBUG } || 0) 
                               & Template::Constants::DEBUG_DIRS;
    $self->{ DEBUG } = defined $config->{ DEBUG } 
        ? $config->{ DEBUG } & ( Template::Constants::DEBUG_CONTEXT
                               | Template::Constants::DEBUG_FLAGS )
        : $DEBUG;

    return $self;
}



sub _dump {
    my $self = shift;
    my $output = "[Template::Context] {\n";
    my $format = "    %-16s => %s\n";
    my $key;

    foreach $key (qw( RECURSION EVAL_PERL TRIM )) {
    $output .= sprintf($format, $key, $self->{ $key });
    }
    foreach my $pname (qw( LOAD_TEMPLATES LOAD_PLUGINS LOAD_FILTERS )) {
    my $provtext = "[\n";
    foreach my $prov (@{ $self->{ $pname } }) {
        $provtext .= $prov->_dump();
    }
    $provtext =~ s/\n/\n        /g;
    $provtext =~ s/\s+$//;
    $provtext .= ",\n    ]";
    $output .= sprintf($format, $pname, $provtext);
    }
    $output .= sprintf($format, STASH => $self->{ STASH }->_dump());
    $output .= '}';
    return $output;
}


1;

__END__


