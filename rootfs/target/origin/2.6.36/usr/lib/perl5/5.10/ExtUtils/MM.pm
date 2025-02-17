package ExtUtils::MM;

use strict;
use ExtUtils::MakeMaker::Config;
use vars qw(@ISA $VERSION);
$VERSION = '6.42';

require ExtUtils::Liblist;
require ExtUtils::MakeMaker;

@ISA = qw(ExtUtils::Liblist ExtUtils::MakeMaker);


{
    # Convenient alias.
    package MM;
    use vars qw(@ISA);
    @ISA = qw(ExtUtils::MM);
    sub DESTROY {}
}

sub _is_win95 {
    # miniperl might not have the Win32 functions available and we need
    # to run in miniperl.
    return defined &Win32::IsWin95 ? Win32::IsWin95() 
                                   : ! defined $ENV{SYSTEMROOT}; 
}

my %Is = ();
$Is{VMS}    = $^O eq 'VMS';
$Is{OS2}    = $^O eq 'os2';
$Is{MacOS}  = $^O eq 'MacOS';
if( $^O eq 'MSWin32' ) {
    _is_win95() ? $Is{Win95} = 1 : $Is{Win32} = 1;
}
$Is{UWIN}   = $^O =~ /^uwin(-nt)?$/;
$Is{Cygwin} = $^O eq 'cygwin';
$Is{NW5}    = $Config{osname} eq 'NetWare';  # intentional
$Is{BeOS}   = $^O =~ /beos/i;    # XXX should this be that loose?
$Is{DOS}    = $^O eq 'dos';
if( $Is{NW5} ) {
    $^O = 'NetWare';
    delete $Is{Win32};
}
$Is{VOS}    = $^O eq 'vos';
$Is{QNX}    = $^O eq 'qnx';
$Is{AIX}    = $^O eq 'aix';

$Is{Unix}   = !grep { $_ } values %Is;

map { delete $Is{$_} unless $Is{$_} } keys %Is;
_assert( keys %Is == 1 );
my($OS) = keys %Is;


my $class = "ExtUtils::MM_$OS";
eval "require $class" unless $INC{"ExtUtils/MM_$OS.pm"};
die $@ if $@;
unshift @ISA, $class;


sub _assert {
    my $sanity = shift;
    die sprintf "Assert failed at %s line %d\n", (caller)[1,2] unless $sanity;
    return;
}
