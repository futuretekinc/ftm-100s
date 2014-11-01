 
package Template::Constants;

require Exporter;
use strict;
use warnings;
use Exporter;
use vars qw( @EXPORT_OK %EXPORT_TAGS );
use vars qw( $DEBUG_OPTIONS @STATUS @ERROR @CHOMP @DEBUG @ISA );
@ISA = qw( Exporter );

our $VERSION = 2.75;



use constant STATUS_OK       =>   0;      # ok
use constant STATUS_RETURN   =>   1;      # ok, block ended by RETURN
use constant STATUS_STOP     =>   2;      # ok, stoppped by STOP 
use constant STATUS_DONE     =>   3;      # ok, iterator done
use constant STATUS_DECLINED =>   4;      # ok, declined to service request
use constant STATUS_ERROR    => 255;      # error condition

use constant ERROR_RETURN    =>  'return'; # return a status code
use constant ERROR_FILE      =>  'file';   # file error: I/O, parse, recursion
use constant ERROR_VIEW      =>  'view';   # view error
use constant ERROR_UNDEF     =>  'undef';  # undefined variable value used
use constant ERROR_PERL      =>  'perl';   # error in [% PERL %] block
use constant ERROR_FILTER    =>  'filter'; # filter error
use constant ERROR_PLUGIN    =>  'plugin'; # plugin error

use constant CHOMP_NONE      => 0; # do not remove whitespace
use constant CHOMP_ALL       => 1; # remove whitespace up to newline
use constant CHOMP_ONE       => 1; # new name for CHOMP_ALL
use constant CHOMP_COLLAPSE  => 2; # collapse whitespace to a single space
use constant CHOMP_GREEDY    => 3; # remove all whitespace including newlines

use constant DEBUG_OFF       =>    0; # do nothing
use constant DEBUG_ON        =>    1; # basic debugging flag
use constant DEBUG_UNDEF     =>    2; # throw undef on undefined variables
use constant DEBUG_VARS      =>    4; # general variable debugging
use constant DEBUG_DIRS      =>    8; # directive debugging
use constant DEBUG_STASH     =>   16; # general stash debugging
use constant DEBUG_CONTEXT   =>   32; # context debugging
use constant DEBUG_PARSER    =>   64; # parser debugging
use constant DEBUG_PROVIDER  =>  128; # provider debugging
use constant DEBUG_PLUGINS   =>  256; # plugins debugging
use constant DEBUG_FILTERS   =>  512; # filters debugging
use constant DEBUG_SERVICE   => 1024; # context debugging
use constant DEBUG_ALL       => 2047; # everything

use constant DEBUG_CALLER    => 4096; # add caller file/line
use constant DEBUG_FLAGS     => 4096; # bitmask to extraxt flags

$DEBUG_OPTIONS  = {
    &DEBUG_OFF      => off      => off      => &DEBUG_OFF,
    &DEBUG_ON       => on       => on       => &DEBUG_ON,
    &DEBUG_UNDEF    => undef    => undef    => &DEBUG_UNDEF,
    &DEBUG_VARS     => vars     => vars     => &DEBUG_VARS,
    &DEBUG_DIRS     => dirs     => dirs     => &DEBUG_DIRS,
    &DEBUG_STASH    => stash    => stash    => &DEBUG_STASH,
    &DEBUG_CONTEXT  => context  => context  => &DEBUG_CONTEXT,
    &DEBUG_PARSER   => parser   => parser   => &DEBUG_PARSER,
    &DEBUG_PROVIDER => provider => provider => &DEBUG_PROVIDER,
    &DEBUG_PLUGINS  => plugins  => plugins  => &DEBUG_PLUGINS,
    &DEBUG_FILTERS  => filters  => filters  => &DEBUG_FILTERS,
    &DEBUG_SERVICE  => service  => service  => &DEBUG_SERVICE,
    &DEBUG_ALL      => all      => all      => &DEBUG_ALL,
    &DEBUG_CALLER   => caller   => caller   => &DEBUG_CALLER,
};

@STATUS  = qw( STATUS_OK STATUS_RETURN STATUS_STOP STATUS_DONE
               STATUS_DECLINED STATUS_ERROR );
@ERROR   = qw( ERROR_FILE ERROR_VIEW ERROR_UNDEF ERROR_PERL 
               ERROR_RETURN ERROR_FILTER ERROR_PLUGIN );
@CHOMP   = qw( CHOMP_NONE CHOMP_ALL CHOMP_ONE CHOMP_COLLAPSE CHOMP_GREEDY );
@DEBUG   = qw( DEBUG_OFF DEBUG_ON DEBUG_UNDEF DEBUG_VARS 
               DEBUG_DIRS DEBUG_STASH DEBUG_CONTEXT DEBUG_PARSER
               DEBUG_PROVIDER DEBUG_PLUGINS DEBUG_FILTERS DEBUG_SERVICE
               DEBUG_ALL DEBUG_CALLER DEBUG_FLAGS );

@EXPORT_OK   = ( @STATUS, @ERROR, @CHOMP, @DEBUG );
%EXPORT_TAGS = (
    'all'      => [ @EXPORT_OK ],
    'status'   => [ @STATUS    ],
    'error'    => [ @ERROR     ],
    'chomp'    => [ @CHOMP     ],
    'debug'    => [ @DEBUG     ],
);


sub debug_flags {
    my ($self, $debug) = @_;
    my (@flags, $flag, $value);
    $debug = $self unless defined($debug) || ref($self);
    
    if ($debug =~ /^\d+$/) {
        foreach $flag (@DEBUG) {
            next if $flag =~ /^DEBUG_(OFF|ALL|FLAGS)$/;

            # don't trash the original
            my $copy = $flag;
            $flag =~ s/^DEBUG_//;
            $flag = lc $flag;
            return $self->error("no value for flag: $flag")
                unless defined($value = $DEBUG_OPTIONS->{ $flag });
            $flag = $value;

            if ($debug & $flag) {
                $value = $DEBUG_OPTIONS->{ $flag };
                return $self->error("no value for flag: $flag") unless defined $value;
                push(@flags, $value);
            }
        }
        return wantarray ? @flags : join(', ', @flags);
    }
    else {
        @flags = split(/\W+/, $debug);
        $debug = 0;
        foreach $flag (@flags) {
            $value = $DEBUG_OPTIONS->{ $flag };
            return $self->error("unknown debug flag: $flag") unless defined $value;
            $debug |= $value;
        }
        return $debug;
    }
}


1;

__END__


