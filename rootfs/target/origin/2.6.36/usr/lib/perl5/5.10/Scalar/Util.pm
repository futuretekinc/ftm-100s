
package Scalar::Util;

use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);
require Exporter;
require List::Util; # List::Util loads the XS

@ISA       = qw(Exporter);
@EXPORT_OK = qw(blessed dualvar reftype weaken isweak tainted readonly openhandle refaddr isvstring looks_like_number set_prototype);
$VERSION    = "1.19";
$VERSION   = eval $VERSION;

sub export_fail {
  if (grep { /^(weaken|isweak)$/ } @_ ) {
    require Carp;
    Carp::croak("Weak references are not implemented in the version of perl");
  }
  if (grep { /^(isvstring)$/ } @_ ) {
    require Carp;
    Carp::croak("Vstrings are not implemented in the version of perl");
  }
  if (grep { /^(dualvar|set_prototype)$/ } @_ ) {
    require Carp;
    Carp::croak("$1 is only avaliable with the XS version");
  }

  @_;
}

sub openhandle ($) {
  my $fh = shift;
  my $rt = reftype($fh) || '';

  return defined(fileno($fh)) ? $fh : undef
    if $rt eq 'IO';

  if (reftype(\$fh) eq 'GLOB') { # handle  openhandle(*DATA)
    $fh = \(my $tmp=$fh);
  }
  elsif ($rt ne 'GLOB') {
    return undef;
  }

  (tied(*$fh) or defined(fileno($fh)))
    ? $fh : undef;
}

eval <<'ESQ' unless defined &dualvar;

use vars qw(@EXPORT_FAIL);
push @EXPORT_FAIL, qw(weaken isweak dualvar isvstring set_prototype);


sub UNIVERSAL::a_sub_not_likely_to_be_here { ref($_[0]) }

sub blessed ($) {
  local($@, $SIG{__DIE__}, $SIG{__WARN__});
  length(ref($_[0]))
    ? eval { $_[0]->a_sub_not_likely_to_be_here }
    : undef
}

sub refaddr($) {
  my $pkg = ref($_[0]) or return undef;
  if (blessed($_[0])) {
    bless $_[0], 'Scalar::Util::Fake';
  }
  else {
    $pkg = undef;
  }
  "$_[0]" =~ /0x(\w+)/;
  my $i = do { local $^W; hex $1 };
  bless $_[0], $pkg if defined $pkg;
  $i;
}

sub reftype ($) {
  local($@, $SIG{__DIE__}, $SIG{__WARN__});
  my $r = shift;
  my $t;

  length($t = ref($r)) or return undef;

  # This eval will fail if the reference is not blessed
  eval { $r->a_sub_not_likely_to_be_here; 1 }
    ? do {
      $t = eval {
	  # we have a GLOB or an IO. Stringify a GLOB gives it's name
	  my $q = *$r;
	  $q =~ /^\*/ ? "GLOB" : "IO";
	}
	or do {
	  # OK, if we don't have a GLOB what parts of
	  # a glob will it populate.
	  # NOTE: A glob always has a SCALAR
	  local *glob = $r;
	  defined *glob{ARRAY} && "ARRAY"
	  or defined *glob{HASH} && "HASH"
	  or defined *glob{CODE} && "CODE"
	  or length(ref(${$r})) ? "REF" : "SCALAR";
	}
    }
    : $t
}

sub tainted {
  local($@, $SIG{__DIE__}, $SIG{__WARN__});
  local $^W = 0;
  eval { kill 0 * $_[0] };
  $@ =~ /^Insecure/;
}

sub readonly {
  return 0 if tied($_[0]) || (ref(\($_[0])) ne "SCALAR");

  local($@, $SIG{__DIE__}, $SIG{__WARN__});
  my $tmp = $_[0];

  !eval { $_[0] = $tmp; 1 };
}

sub looks_like_number {
  local $_ = shift;

  # checks from perlfaq4
  return 0 if !defined($_) or ref($_);
  return 1 if (/^[+-]?\d+$/); # is a +/- integer
  return 1 if (/^([+-]?)(?=\d|\.\d)\d*(\.\d*)?([Ee]([+-]?\d+))?$/); # a C float
  return 1 if ($] >= 5.008 and /^(Inf(inity)?|NaN)$/i) or ($] >= 5.006001 and /^Inf$/i);

  0;
}

ESQ

1;

__END__

