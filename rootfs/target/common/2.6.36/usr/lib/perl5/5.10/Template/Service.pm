
package Template::Service;

use strict;
use warnings;
use base 'Template::Base';
use Template::Config;
use Template::Exception;
use Template::Constants;
use Scalar::Util 'blessed';

use constant EXCEPTION => 'Template::Exception';

our $VERSION = 2.80;
our $DEBUG   = 0 unless defined $DEBUG;
our $ERROR   = '';




sub process {
    my ($self, $template, $params) = @_;
    my $context = $self->{ CONTEXT };
    my ($name, $output, $procout, $error);
    $output = '';

    $self->debug("process($template, ", 
                 defined $params ? $params : '<no params>',
                 ')') if $self->{ DEBUG };

    $context->reset()
        if $self->{ AUTO_RESET };

    # pre-request compiled template from context so that we can alias it 
    # in the stash for pre-processed templates to reference
    eval { $template = $context->template($template) };
    return $self->error($@)
        if $@;

    # localise the variable stash with any parameters passed
    # and set the 'template' variable
    $params ||= { };
    # TODO: change this to C<||=> so we can use a template parameter
    $params->{ template } = $template 
        unless ref $template eq 'CODE';
    $context->localise($params);

    SERVICE: {
        # PRE_PROCESS
        eval {
            foreach $name (@{ $self->{ PRE_PROCESS } }) {
                $self->debug("PRE_PROCESS: $name") if $self->{ DEBUG };
                $output .= $context->process($name);
            }
        };
        last SERVICE if ($error = $@);

        # PROCESS
        eval {
            foreach $name (@{ $self->{ PROCESS } || [ $template ] }) {
                $self->debug("PROCESS: $name") if $self->{ DEBUG };
                $procout .= $context->process($name);
            }
        };
        if ($error = $@) {
            last SERVICE
                unless defined ($procout = $self->_recover(\$error));
        }
        
        if (defined $procout) {
            # WRAPPER
            eval {
                foreach $name (reverse @{ $self->{ WRAPPER } }) {
                    $self->debug("WRAPPER: $name") if $self->{ DEBUG };
                    $procout = $context->process($name, { content => $procout });
                }
            };
            last SERVICE if ($error = $@);
            $output .= $procout;
        }
        
        # POST_PROCESS
        eval {
            foreach $name (@{ $self->{ POST_PROCESS } }) {
                $self->debug("POST_PROCESS: $name") if $self->{ DEBUG };
                $output .= $context->process($name);
            }
        };
        last SERVICE if ($error = $@);
    }

    $context->delocalise();
    delete $params->{ template };

    if ($error) {
    #   $error = $error->as_string if ref $error;
        return $self->error($error);
    }

    return $output;
}



sub context {
    return $_[0]->{ CONTEXT };
}



sub _init {
    my ($self, $config) = @_;
    my ($item, $data, $context, $block, $blocks);
    my $delim = $config->{ DELIMITER };
    $delim = ':' unless defined $delim;

    # coerce PRE_PROCESS, PROCESS and POST_PROCESS to arrays if necessary, 
    # by splitting on non-word characters
    foreach $item (qw( PRE_PROCESS PROCESS POST_PROCESS WRAPPER )) {
        $data = $config->{ $item };
        $self->{ $item } = [ ], next unless (defined $data);
        $data = [ split($delim, $data || '') ]
            unless ref $data eq 'ARRAY';
        $self->{ $item } = $data;
    }
    # unset PROCESS option unless explicitly specified in config
    $self->{ PROCESS } = undef
        unless defined $config->{ PROCESS };
    
    $self->{ ERROR      } = $config->{ ERROR } || $config->{ ERRORS };
    $self->{ AUTO_RESET } = defined $config->{ AUTO_RESET }
                            ? $config->{ AUTO_RESET } : 1;
    $self->{ DEBUG      } = ( $config->{ DEBUG } || 0 )
                            & Template::Constants::DEBUG_SERVICE;
    
    $context = $self->{ CONTEXT } = $config->{ CONTEXT }
        || Template::Config->context($config)
        || return $self->error(Template::Config->error);
    
    return $self;
}



sub _recover {
    my ($self, $error) = @_;
    my $context = $self->{ CONTEXT };
    my ($hkey, $handler, $output);

    # there shouldn't ever be a non-exception object received at this
    # point... unless a module like CGI::Carp messes around with the 
    # DIE handler. 
    return undef
        unless blessed($$error) && $$error->isa(EXCEPTION);

    # a 'stop' exception is thrown by [% STOP %] - we return the output
    # buffer stored in the exception object
    return $$error->text()
        if $$error->type() eq 'stop';

    my $handlers = $self->{ ERROR }
        || return undef;                    ## RETURN

    if (ref $handlers eq 'HASH') {
        if ($hkey = $$error->select_handler(keys %$handlers)) {
            $handler = $handlers->{ $hkey };
            $self->debug("using error handler for $hkey") if $self->{ DEBUG };
        }
        elsif ($handler = $handlers->{ default }) {
            # use default handler
            $self->debug("using default error handler") if $self->{ DEBUG };
        }
        else {
            return undef;                   ## RETURN
        }
    }
    else {
        $handler = $handlers;
        $self->debug("using default error handler") if $self->{ DEBUG };
    }
    
    eval { $handler = $context->template($handler) };
    if ($@) {
        $$error = $@;
        return undef;                       ## RETURN
    };
    
    $context->stash->set('error', $$error);
    eval {
        $output .= $context->process($handler);
    };
    if ($@) {
        $$error = $@;
        return undef;                       ## RETURN
    }

    return $output;
}




sub _dump {
    my $self = shift;
    my $context = $self->{ CONTEXT }->_dump();
    $context =~ s/\n/\n    /gm;

    my $error = $self->{ ERROR };
    $error = join('', 
          "{\n",
          (map { "    $_ => $error->{ $_ }\n" }
           keys %$error),
          "}\n")
    if ref $error;
    
    local $" = ', ';
    return <<EOF;
$self
PRE_PROCESS  => [ @{ $self->{ PRE_PROCESS } } ]
POST_PROCESS => [ @{ $self->{ POST_PROCESS } } ]
ERROR        => $error
CONTEXT      => $context
EOF
}


1;

__END__


