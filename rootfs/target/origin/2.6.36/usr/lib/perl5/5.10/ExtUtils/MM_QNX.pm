package ExtUtils::MM_QNX;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '6.42';

require ExtUtils::MM_Unix;
@ISA = qw(ExtUtils::MM_Unix);



sub extra_clean_files {
    my $self = shift;

    my @errfiles = @{$self->{C}};
    for ( @errfiles ) {
	s/.c$/.err/;
    }

    return( @errfiles, 'perlmain.err' );
}




1;
