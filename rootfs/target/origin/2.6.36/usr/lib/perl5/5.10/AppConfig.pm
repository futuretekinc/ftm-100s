
package AppConfig;

use strict;
use warnings;
use base 'Exporter';
our $VERSION = 1.66;

use constant EXPAND_NONE   => 0;
use constant EXPAND_VAR    => 1;
use constant EXPAND_UID    => 2;
use constant EXPAND_ENV    => 4;
use constant EXPAND_ALL    => EXPAND_VAR | EXPAND_UID | EXPAND_ENV;
use constant EXPAND_WARN   => 8;

use constant ARGCOUNT_NONE => 0;
use constant ARGCOUNT_ONE  => 1;
use constant ARGCOUNT_LIST => 2;
use constant ARGCOUNT_HASH => 3;

our @EXPAND = qw(
    EXPAND_NONE
    EXPAND_VAR
    EXPAND_UID
    EXPAND_ENV 
    EXPAND_ALL
    EXPAND_WARN
);

our @ARGCOUNT = qw(
    ARGCOUNT_NONE
    ARGCOUNT_ONE
    ARGCOUNT_LIST
    ARGCOUNT_HASH
);

our @EXPORT_OK   = ( @EXPAND, @ARGCOUNT );
our %EXPORT_TAGS = (
    expand   => [ @EXPAND   ],
    argcount => [ @ARGCOUNT ],
);
our $AUTOLOAD;

require AppConfig::State;


sub new {
    my $class = shift;
    bless {
        STATE => AppConfig::State->new(@_)
    }, $class;
}



sub file {
    my $self  = shift;
    my $state = $self->{ STATE };
    my $file;

    require AppConfig::File;

    # create an AppConfig::File object if one isn't defined 
    $file = $self->{ FILE } ||= AppConfig::File->new($state);

    # call on the AppConfig::File object to process files.
    $file->parse(@_);
}



sub args {
    my $self  = shift;
    my $state = $self->{ STATE };
    my $args;

    require AppConfig::Args;

    # create an AppConfig::Args object if one isn't defined
    $args = $self->{ ARGS } ||= AppConfig::Args->new($state);

    # call on the AppConfig::Args object to process arguments.
    $args->parse(shift);
}



sub getopt {
    my $self  = shift;
    my $state = $self->{ STATE };
    my $getopt;

    require AppConfig::Getopt;

    # create an AppConfig::Getopt object if one isn't defined
    $getopt = $self->{ GETOPT } ||= AppConfig::Getopt->new($state);

    # call on the AppConfig::Getopt object to process arguments.
    $getopt->parse(@_);
}



sub cgi {
    my $self  = shift;
    my $state = $self->{ STATE };
    my $cgi;

    require AppConfig::CGI;

    # create an AppConfig::CGI object if one isn't defined
    $cgi = $self->{ CGI } ||= AppConfig::CGI->new($state);

    # call on the AppConfig::CGI object to process a query.
    $cgi->parse(shift);
}


sub AUTOLOAD {
    my $self = shift;
    my $method;

    # splat the leading package name
    ($method = $AUTOLOAD) =~ s/.*:://;

    # ignore destructor
    $method eq 'DESTROY' && return;

    # delegate method call to AppConfig::State object in $self->{ STATE } 
    $self->{ STATE }->$method(@_);
}

1;

__END__

