package ExtUtils::testlib;

use strict;

use vars qw($VERSION);
$VERSION = 6.42;

use Cwd;
use File::Spec;

my $cwd;
BEGIN {
    ($cwd) = getcwd() =~ /(.*)/;
}
use lib map File::Spec->rel2abs($_, $cwd), qw(blib/arch blib/lib);
1;
__END__

