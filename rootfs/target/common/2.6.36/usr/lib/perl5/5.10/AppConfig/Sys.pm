
package AppConfig::Sys;
use strict;
use warnings;
use POSIX qw( getpwnam getpwuid );

our $VERSION = '1.65';
our ($AUTOLOAD, $OS, %CAN, %METHOD);


BEGIN {
    # define the methods that may be available
    if($^O =~ m/win32/i) {
        $METHOD{ getpwuid } = sub { 
            return wantarray() 
                ? ( (undef) x 7, getlogin() )
                : getlogin(); 
        };
        $METHOD{ getpwnam } = sub { 
            die("Can't getpwnam on win32"); 
        };
    }
    else
    {
        $METHOD{ getpwuid } = sub { 
            getpwuid( defined $_[0] ? shift : $< ); 
        };
        $METHOD{ getpwnam } = sub { 
            getpwnam( defined $_[0] ? shift : '' );
        };
    }
    
    # try out each METHOD to see if it's supported on this platform;
    # it's important we do this before defining AUTOLOAD which would
    # otherwise catch the unresolved call
    foreach my $method  (keys %METHOD) {
        eval { &{ $METHOD{ $method } }() };
    	$CAN{ $method } = ! $@;
    }
}




sub new {
    my $class = shift;
    
    my $self = {
        METHOD => \%METHOD,
        CAN    => \%CAN,
    };

    bless $self, $class;

    $self->_configure(@_);
	
    return $self;
}



sub AUTOLOAD {
    my $self = shift;
    my $method;


    # splat the leading package name
    ($method = $AUTOLOAD) =~ s/.*:://;

    # ignore destructor
    $method eq 'DESTROY' && return;

    # can_method()
    if ($method =~ s/^can_//i && exists $self->{ CAN }->{ $method }) {
        return $self->{ CAN }->{ $method };
    }
    # method() 
    elsif (exists $self->{ METHOD }->{ $method }) {
        if ($self->{ CAN }->{ $method }) {
            return &{ $self->{ METHOD }->{ $method } }(@_);
        }
        else {
            return undef;
        }
    } 
    # variable
    elsif (exists $self->{ uc $method }) {
        return $self->{ uc $method };
    }
    else {
        warn("AppConfig::Sys->", $method, "(): no such method or variable\n");
    }

    return undef;
}



sub _configure {
    my $self = shift;

    # operating system may be defined as a parameter or in $OS
    my $os = shift || $OS;


    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
    # The following was lifted (and adapated slightly) from Lincoln Stein's 
    # CGI.pm module, version 2.36...
    #
    # FIGURE OUT THE OS WE'RE RUNNING UNDER
    # Some systems support the $^O variable.  If not
    # available then require() the Config library
    unless ($os) {
	unless ($os = $^O) {
	    require Config;
	    $os = $Config::Config{'osname'};
	}
    }
    if ($os =~ /win32/i) {
        $os = 'WINDOWS';
    } elsif ($os =~ /vms/i) {
        $os = 'VMS';
    } elsif ($os =~ /mac/i) {
        $os = 'MACINTOSH';
    } elsif ($os =~ /os2/i) {
        $os = 'OS2';
    } else {
        $os = 'UNIX';
    }


    # The path separator is a slash, backslash or semicolon, depending
    # on the platform.
    my $ps = {
        UNIX      => '/',
        OS2       => '\\',
        WINDOWS   => '\\',
        MACINTOSH => ':',
        VMS       => '\\'
    }->{ $os };
    #
    # Thanks Lincoln!
    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


    $self->{ OS      } = $os;
    $self->{ PATHSEP } = $ps;
}



sub _dump {
    my $self = shift;

    print "=" x 71, "\n";
    print "Status of AppConfig::Sys (Version $VERSION) object: $self\n";
    print "    Operating System : ", $self->{ OS      }, "\n";
    print "      Path Separator : ", $self->{ PATHSEP }, "\n";
    print "   Available methods :\n";
    foreach my $can (keys %{ $self->{ CAN } }) {
        printf "%20s : ", $can;
        print  $self->{ CAN }->{ $can } ? "yes" : "no", "\n";
    }
    print "=" x 71, "\n";
}



1;

__END__

