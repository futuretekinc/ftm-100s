package Data::UUID;

use strict;

use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require Digest::MD5;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(
   NameSpace_DNS
   NameSpace_OID
   NameSpace_URL
   NameSpace_X500
);
$VERSION = '1.217';

bootstrap Data::UUID $VERSION;

1;
__END__

