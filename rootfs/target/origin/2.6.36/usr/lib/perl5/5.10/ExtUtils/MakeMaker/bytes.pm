package ExtUtils::MakeMaker::bytes;

use strict;

use vars qw($VERSION);
$VERSION = 6.42;

my $Have_Bytes = eval q{require bytes; 1;};

sub import {
    return unless $Have_Bytes;

    shift;
    unshift @_, 'bytes';

    goto &bytes::import;
}

1;


