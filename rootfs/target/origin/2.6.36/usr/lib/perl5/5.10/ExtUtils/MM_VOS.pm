package ExtUtils::MM_VOS;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '6.42';

require ExtUtils::MM_Unix;
@ISA = qw(ExtUtils::MM_Unix);



sub extra_clean_files {
    return qw(*.kp);
}




1;
