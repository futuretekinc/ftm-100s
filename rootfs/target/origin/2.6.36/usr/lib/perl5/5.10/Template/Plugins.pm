
package Template::Plugins;

use strict;
use warnings;
use base 'Template::Base';
use Template::Constants;

our $VERSION = 2.77;
our $DEBUG   = 0 unless defined $DEBUG;
our $PLUGIN_BASE = 'Template::Plugin';
our $STD_PLUGINS = {
    'assert'     => 'Template::Plugin::Assert',
    'autoformat' => 'Template::Plugin::Autoformat',
    'cgi'        => 'Template::Plugin::CGI',
    'datafile'   => 'Template::Plugin::Datafile',
    'date'       => 'Template::Plugin::Date',
    'debug'      => 'Template::Plugin::Debug',
    'directory'  => 'Template::Plugin::Directory',
    'dbi'        => 'Template::Plugin::DBI',
    'dumper'     => 'Template::Plugin::Dumper',
    'file'       => 'Template::Plugin::File',
    'format'     => 'Template::Plugin::Format',
    'html'       => 'Template::Plugin::HTML',
    'image'      => 'Template::Plugin::Image',
    'iterator'   => 'Template::Plugin::Iterator',
    'latex'      => 'Template::Plugin::Latex',
    'pod'        => 'Template::Plugin::Pod',
    'scalar'     => 'Template::Plugin::Scalar',
    'table'      => 'Template::Plugin::Table',
    'url'        => 'Template::Plugin::URL',
    'view'       => 'Template::Plugin::View',
    'wrap'       => 'Template::Plugin::Wrap',
    'xml'        => 'Template::Plugin::XML',
    'xmlstyle'   => 'Template::Plugin::XML::Style',
};




sub fetch {
    my ($self, $name, $args, $context) = @_;
    my ($factory, $plugin, $error);

    $self->debug("fetch($name, ", 
                 defined $args ? ('[ ', join(', ', @$args), ' ]') : '<no args>', ', ',
                 defined $context ? $context : '<no context>', 
                 ')') if $self->{ DEBUG };

    # NOTE:
    # the $context ref gets passed as the first parameter to all regular
    # plugins, but not to those loaded via LOAD_PERL;  to hack around
    # this until we have a better implementation, we pass the $args
    # reference to _load() and let it unshift the first args in the 
    # LOAD_PERL case

    $args ||= [ ];
    unshift @$args, $context;

    $factory = $self->{ FACTORY }->{ $name } ||= do {
        ($factory, $error) = $self->_load($name, $context);
        return ($factory, $error) if $error;			## RETURN
        $factory;
    };

    # call the new() method on the factory object or class name
    eval {
        if (ref $factory eq 'CODE') {
            defined( $plugin = &$factory(@$args) )
                || die "$name plugin failed\n";
        }
        else {
            defined( $plugin = $factory->new(@$args) )
                || die "$name plugin failed: ", $factory->error(), "\n";
        }
    };
    if ($error = $@) {
        return $self->{ TOLERANT } 
	       ? (undef,  Template::Constants::STATUS_DECLINED)
	       : ($error, Template::Constants::STATUS_ERROR);
    }

    return $plugin;
}





sub _init {
    my ($self, $params) = @_;
    my ($pbase, $plugins, $factory) = 
        @$params{ qw( PLUGIN_BASE PLUGINS PLUGIN_FACTORY ) };

    $plugins ||= { };

    # update PLUGIN_BASE to an array ref if necessary
    $pbase = [ ] unless defined $pbase;
    $pbase = [ $pbase ] unless ref($pbase) eq 'ARRAY';
    
    # add default plugin base (Template::Plugin) if set
    push(@$pbase, $PLUGIN_BASE) if $PLUGIN_BASE;

    $self->{ PLUGIN_BASE } = $pbase;
    $self->{ PLUGINS     } = { %$STD_PLUGINS, %$plugins };
    $self->{ TOLERANT    } = $params->{ TOLERANT }  || 0;
    $self->{ LOAD_PERL   } = $params->{ LOAD_PERL } || 0;
    $self->{ FACTORY     } = $factory || { };
    $self->{ DEBUG       } = ( $params->{ DEBUG } || 0 )
                             & Template::Constants::DEBUG_PLUGINS;

    return $self;
}




sub _load {
    my ($self, $name, $context) = @_;
    my ($factory, $module, $base, $pkg, $file, $ok, $error);

    if ($module = $self->{ PLUGINS }->{ $name } || $self->{ PLUGINS }->{ lc $name }) {
        # plugin module name is explicitly stated in PLUGIN_NAME
        $pkg = $module;
        ($file = $module) =~ s|::|/|g;
        $file =~ s|::|/|g;
        $self->debug("loading $module.pm (PLUGIN_NAME)")
            if $self->{ DEBUG };
        $ok = eval { require "$file.pm" };
        $error = $@;
    }
    else {
        # try each of the PLUGIN_BASE values to build module name
        ($module = $name) =~ s/\./::/g;
        
        foreach $base (@{ $self->{ PLUGIN_BASE } }) {
            $pkg = $base . '::' . $module;
            ($file = $pkg) =~ s|::|/|g;
            
            $self->debug("loading $file.pm (PLUGIN_BASE)")
                if $self->{ DEBUG };
            
            $ok = eval { require "$file.pm" };
            last unless $@;
            
            $error .= "$@\n" 
                unless ($@ =~ /^Can\'t locate $file\.pm/);
        }
    }
    
    if ($ok) {
        $self->debug("calling $pkg->load()") if $self->{ DEBUG };

	$factory = eval { $pkg->load($context) };
        $error   = '';
        if ($@ || ! $factory) {
            $error = $@ || 'load() returned a false value';
        }
    }
    elsif ($self->{ LOAD_PERL }) {
        # fallback - is it a regular Perl module?
        ($file = $module) =~ s|::|/|g;
        eval { require "$file.pm" };
        if ($@) {
            $error = $@;
        }
        else {
            # this is a regular Perl module so the new() constructor
            # isn't expecting a $context reference as the first argument;
            # so we construct a closure which removes it before calling
            # $module->new(@_);
            $factory = sub {
                shift;
                $module->new(@_);
            };
            $error   = '';
        }
    }
    
    if ($factory) {
        $self->debug("$name => $factory") if $self->{ DEBUG };
        return $factory;
    }
    elsif ($error) {
        return $self->{ TOLERANT } 
	    ? (undef,  Template::Constants::STATUS_DECLINED) 
            : ($error, Template::Constants::STATUS_ERROR);
    }
    else {
        return (undef, Template::Constants::STATUS_DECLINED);
    }
}



sub _dump {
    my $self = shift;
    my $output = "[Template::Plugins] {\n";
    my $format = "    %-16s => %s\n";
    my $key;

    foreach $key (qw( TOLERANT LOAD_PERL )) {
        $output .= sprintf($format, $key, $self->{ $key });
    }

    local $" = ', ';
    my $fkeys = join(", ", keys %{$self->{ FACTORY }});
    my $plugins = $self->{ PLUGINS };
    $plugins = join('', map { 
        sprintf("    $format", $_, $plugins->{ $_ });
    } keys %$plugins);
    $plugins = "{\n$plugins    }";
    
    $output .= sprintf($format, 'PLUGIN_BASE', "[ @{ $self->{ PLUGIN_BASE } } ]");
    $output .= sprintf($format, 'PLUGINS', $plugins);
    $output .= sprintf($format, 'FACTORY', $fkeys);
    $output .= '}';
    return $output;
}


1;

__END__


