package ExtUtils::MM_MacOS;

use strict;

use vars qw($VERSION);
$VERSION = 6.42;

sub new {
    die <<'UNSUPPORTED';
MacOS Classic (MacPerl) is no longer supported by MakeMaker.
Please use Module::Build instead.
UNSUPPORTED
}


1;
