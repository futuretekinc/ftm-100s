package Encode::TW;
BEGIN {
    if ( ord("A") == 193 ) {
        die "Encode::TW not supported on EBCDIC\n";
    }
}
use strict;
use warnings;
use Encode;
our $VERSION = do { my @r = ( q$Revision: 2.2 $ =~ /\d+/g ); sprintf "%d." . "%02d" x $#r, @r };
use XSLoader;
XSLoader::load( __PACKAGE__, $VERSION );

1;
__END__

