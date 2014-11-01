
package Template;

use strict;
use warnings;
use 5.006;
use base 'Template::Base';

use Template::Config;
use Template::Constants;
use Template::Provider;  
use Template::Service;
use File::Basename;
use File::Path;
use Scalar::Util qw(blessed);

our $VERSION = '2.22';
our $ERROR   = '';
our $DEBUG   = 0;
our $BINMODE = 0 unless defined $BINMODE;
our $AUTOLOAD;

Template::Config->preload() if $ENV{ MOD_PERL };



sub process {
    my ($self, $template, $vars, $outstream, @opts) = @_;
    my ($output, $error);
    my $options = (@opts == 1) && ref($opts[0]) eq 'HASH'
        ? shift(@opts) : { @opts };

    $options->{ binmode } = $BINMODE
        unless defined $options->{ binmode };
    
    # we're using this for testing in t/output.t and t/filter.t so 
    # don't remove it if you don't want tests to fail...
    $self->DEBUG("set binmode\n") if $DEBUG && $options->{ binmode };

    $output = $self->{ SERVICE }->process($template, $vars);
    
    if (defined $output) {
        $outstream ||= $self->{ OUTPUT };
        unless (ref $outstream) {
            my $outpath = $self->{ OUTPUT_PATH };
            $outstream = "$outpath/$outstream" if $outpath;
        }   

        # send processed template to output stream, checking for error
        return ($self->error($error))
            if ($error = &_output($outstream, \$output, $options));
        
        return 1;
    }
    else {
        return $self->error($self->{ SERVICE }->error);
    }
}



sub service {
    my $self = shift;
    return $self->{ SERVICE };
}



sub context {
    my $self = shift;
    return $self->{ SERVICE }->{ CONTEXT };
}



sub _init {
    my ($self, $config) = @_;

    # convert any textual DEBUG args to numerical form
    my $debug = $config->{ DEBUG };
    $config->{ DEBUG } = Template::Constants::debug_flags($self, $debug)
        || return if defined $debug && $debug !~ /^\d+$/;
    
    # prepare a namespace handler for any CONSTANTS definition
    if (my $constants = $config->{ CONSTANTS }) {
        my $ns  = $config->{ NAMESPACE } ||= { };
        my $cns = $config->{ CONSTANTS_NAMESPACE } || 'constants';
        $constants = Template::Config->constants($constants)
            || return $self->error(Template::Config->error);
        $ns->{ $cns } = $constants;
    }
    
    $self->{ SERVICE } = $config->{ SERVICE }
        || Template::Config->service($config)
        || return $self->error(Template::Config->error);
    
    $self->{ OUTPUT      } = $config->{ OUTPUT } || \*STDOUT;
    $self->{ OUTPUT_PATH } = $config->{ OUTPUT_PATH };

    return $self;
}



sub _output {
    my ($where, $textref, $options) = @_;
    my $reftype;
    my $error = 0;
    
    # call a CODE reference
    if (($reftype = ref($where)) eq 'CODE') {
        &$where($$textref);
    }
    # print to a glob (such as \*STDOUT)
    elsif ($reftype eq 'GLOB') {
        print $where $$textref;
    }   
    # append output to a SCALAR ref
    elsif ($reftype eq 'SCALAR') {
        $$where .= $$textref;
    }
    # push onto ARRAY ref
    elsif ($reftype eq 'ARRAY') {
        push @$where, $$textref;
    }
    # call the print() method on an object that implements the method
    # (e.g. IO::Handle, Apache::Request, etc)
    elsif (blessed($where) && $where->can('print')) {
        $where->print($$textref);
    }
    # a simple string is taken as a filename
    elsif (! $reftype) {
        local *FP;
        # make destination directory if it doesn't exist
        my $dir = dirname($where);
        eval { mkpath($dir) unless -d $dir; };
        if ($@) {
            # strip file name and line number from error raised by die()
            ($error = $@) =~ s/ at \S+ line \d+\n?$//;
        }
        elsif (open(FP, ">$where")) { 
            # binmode option can be 1 or a specific layer, e.g. :utf8
            my $bm = $options->{ binmode  };
            if ($bm && $bm eq 1) { 
                binmode FP;
            }
            elsif ($bm){ 
                binmode FP, $bm;
            }
            print FP $$textref;
            close FP;
        }
        else {
            $error  = "$where: $!";
        }
    }
    # give up, we've done our best
    else {
        $error = "output_handler() cannot determine target type ($where)\n";
    }

    return $error;
}


1;

__END__


