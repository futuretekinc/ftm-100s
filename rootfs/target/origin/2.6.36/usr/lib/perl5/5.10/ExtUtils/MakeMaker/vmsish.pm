package ExtUtils::MakeMaker::vmsish;

use strict;

use vars qw($VERSION);
$VERSION = 6.42;

my $IsVMS = $^O eq 'VMS';

require vmsish if $IsVMS;


sub import {
    return unless $IsVMS;

    shift;
    unshift @_, 'vmsish';

    goto &vmsish::import;
}

1;


