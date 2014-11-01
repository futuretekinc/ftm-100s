
package Template::Plugin::Date;

use strict;
use warnings;
use base 'Template::Plugin';

use POSIX ();

our $VERSION = 2.78;
our $FORMAT  = '%H:%M:%S %d-%b-%Y';    # default strftime() format
our @LOCALE_SUFFIX = qw( .ISO8859-1 .ISO_8859-15 .US-ASCII .UTF-8 );



sub new {
    my ($class, $context, $params) = @_;
    bless {
        $params ? %$params : ()
    }, $class;
}



sub now {
    return time();
}



sub format {
    my $self   = shift;
    my $params = ref($_[$#_]) eq 'HASH' ? pop(@_) : { };
    my $time   = shift(@_) || $params->{ time } || $self->{ time } 
                           || $self->now();
    my $format = @_ ? shift(@_) 
                    : ($params->{ format } || $self->{ format } || $FORMAT);
    my $locale = @_ ? shift(@_)
                    : ($params->{ locale } || $self->{ locale });
    my $gmt = @_ ? shift(@_)
            : ($params->{ gmt } || $self->{ gmt });
    my (@date, $datestr);

    if ($time =~ /^\d+$/) {
        # $time is now in seconds since epoch
        if ($gmt) {
            @date = (gmtime($time))[0..6];
        }
        else {
            @date = (localtime($time))[0..6];
        }
    }
    else {
        # if $time is numeric, then we assume it's seconds since the epoch
        # otherwise, we try to parse it as either a 'Y:M:D H:M:S' or a
        # 'H:M:S D:M:Y' string

        my @parts = (split(/(?:\/| |:|-)/, $time));

        if (@parts >= 6) {
            if (length($parts[0]) == 4) {
                # year is first; assume 'Y:M:D H:M:S'
                @date = @parts[reverse 0..5];
            }
            else {
                # year is last; assume 'H:M:S D:M:Y'
                @date = @parts[2,1,0,3..5];
            }
        }

        if (!@date) {
            return (undef, Template::Exception->new('date',
                   "bad time/date string:  " .
                   "expects 'h:m:s d:m:y'  got: '$time'"));
        }
        $date[4] -= 1;     # correct month number 1-12 to range 0-11
        $date[5] -= 1900;  # convert absolute year to years since 1900
        $time = &POSIX::mktime(@date);
    }
    
    if ($locale) {
        # format the date in a specific locale, saving and subsequently
        # restoring the current locale.
        my $old_locale = &POSIX::setlocale(&POSIX::LC_ALL);

        # some systems expect locales to have a particular suffix
        for my $suffix ('', @LOCALE_SUFFIX) {
            my $try_locale = $locale.$suffix;
            my $setlocale = &POSIX::setlocale(&POSIX::LC_ALL, $try_locale);
            if (defined $setlocale && $try_locale eq $setlocale) {
                $locale = $try_locale;
                last;
            }
        }
        $datestr = &POSIX::strftime($format, @date);
        &POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
    }
    else {
        $datestr = &POSIX::strftime($format, @date);
    }

    return $datestr;
}

sub calc {
    my $self = shift;
    eval { require "Date/Calc.pm" };
    $self->throw("failed to load Date::Calc: $@") if $@;
    return Template::Plugin::Date::Calc->new('no context');
}

sub manip {
    my $self = shift;
    eval { require "Date/Manip.pm" };
    $self->throw("failed to load Date::Manip: $@") if $@;
    return Template::Plugin::Date::Manip->new('no context');
}


sub throw {
    my $self = shift;
    die (Template::Exception->new('date', join(', ', @_)));
}


package Template::Plugin::Date::Calc;
use base qw( Template::Plugin );
use vars qw( $AUTOLOAD );
*throw = \&Template::Plugin::Date::throw;

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';

    my $sub = \&{"Date::Calc::$method"};
    $self->throw("no such Date::Calc method: $method")
        unless $sub;

    &$sub(@_);
}

package Template::Plugin::Date::Manip;
use base qw( Template::Plugin );
use vars qw( $AUTOLOAD );
*throw = \&Template::Plugin::Date::throw;

sub AUTOLOAD {
    my $self = shift;
    my $method = $AUTOLOAD;
    
    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    
    my $sub = \&{"Date::Manip::$method"};
    $self->throw("no such Date::Manip method: $method")
        unless $sub;
    
    &$sub(@_);
}
    
    
1;

__END__

