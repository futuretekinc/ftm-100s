package ExtUtils::CBuilder;

use File::Spec ();
use File::Path ();
use File::Basename ();

use vars qw($VERSION @ISA);
$VERSION = '0.21';
$VERSION = eval $VERSION;


my %OSTYPES = qw(
		 aix       Unix
		 bsdos     Unix
		 dgux      Unix
		 dynixptx  Unix
		 freebsd   Unix
		 linux     Unix
		 hpux      Unix
		 irix      Unix
		 darwin    Unix
		 machten   Unix
		 next      Unix
		 openbsd   Unix
		 netbsd    Unix
		 dec_osf   Unix
		 svr4      Unix
		 svr5      Unix
		 sco_sv    Unix
		 unicos    Unix
		 unicosmk  Unix
		 solaris   Unix
		 sunos     Unix
		 cygwin    Unix
		 os2       Unix
		 
		 dos       Windows
		 MSWin32   Windows

		 os390     EBCDIC
		 os400     EBCDIC
		 posix-bc  EBCDIC
		 vmesa     EBCDIC

		 MacOS     MacOS
		 VMS       VMS
		 VOS       VOS
		 riscos    RiscOS
		 amigaos   Amiga
		 mpeix     MPEiX
		);

my $load = sub {
  my $mod = shift;
  eval "use $mod";
  die $@ if $@;
  @ISA = ($mod);
};

{
  my @package = split /::/, __PACKAGE__;
  
  if (grep {-e File::Spec->catfile($_, @package, 'Platform', $^O) . '.pm'} @INC) {
    $load->(__PACKAGE__ . "::Platform::$^O");
    
  } elsif (exists $OSTYPES{$^O} and
	   grep {-e File::Spec->catfile($_, @package, 'Platform', $OSTYPES{$^O}) . '.pm'} @INC) {
    $load->(__PACKAGE__ . "::Platform::$OSTYPES{$^O}");
    
  } else {
    $load->(__PACKAGE__ . "::Base");
  }
}

sub os_type { $OSTYPES{$^O} }

1;
__END__

