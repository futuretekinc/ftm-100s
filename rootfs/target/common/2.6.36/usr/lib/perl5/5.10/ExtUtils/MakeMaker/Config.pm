package ExtUtils::MakeMaker::Config;

$VERSION = '6.42';

use strict;
use Config ();

use vars qw(%Config);
%Config = %Config::Config;

sub import {
    my $caller = caller;

    no strict 'refs';
    *{$caller.'::Config'} = \%Config;
}

1;


