package Encode;
use strict;
use warnings;
our $VERSION = sprintf "%d.%02d", q$Revision: 2.23 $ =~ /(\d+)/g;
sub DEBUG () { 0 }
use XSLoader ();
XSLoader::load( __PACKAGE__, $VERSION );

require Exporter;
use base qw/Exporter/;


our @EXPORT = qw(
  decode  decode_utf8  encode  encode_utf8 str2bytes bytes2str
  encodings  find_encoding clone_encoding
);
our @FB_FLAGS = qw(
  DIE_ON_ERR WARN_ON_ERR RETURN_ON_ERR LEAVE_SRC
  PERLQQ HTMLCREF XMLCREF STOP_AT_PARTIAL
);
our @FB_CONSTS = qw(
  FB_DEFAULT FB_CROAK FB_QUIET FB_WARN
  FB_PERLQQ FB_HTMLCREF FB_XMLCREF
);
our @EXPORT_OK = (
    qw(
      _utf8_off _utf8_on define_encoding from_to is_16bit is_8bit
      is_utf8 perlio_ok resolve_alias utf8_downgrade utf8_upgrade
      ),
    @FB_FLAGS, @FB_CONSTS,
);

our %EXPORT_TAGS = (
    all          => [ @EXPORT,    @EXPORT_OK ],
    fallbacks    => [@FB_CONSTS],
    fallback_all => [ @FB_CONSTS, @FB_FLAGS ],
);


our $ON_EBCDIC = ( ord("A") == 193 );

use Encode::Alias;

our %Encoding;
our %ExtModule;
require Encode::Config;
eval { require Encode::ConfigLocal };

sub encodings {
    my $class = shift;
    my %enc;
    if ( @_ and $_[0] eq ":all" ) {
        %enc = ( %Encoding, %ExtModule );
    }
    else {
        %enc = %Encoding;
        for my $mod ( map { m/::/o ? $_ : "Encode::$_" } @_ ) {
            DEBUG and warn $mod;
            for my $enc ( keys %ExtModule ) {
                $ExtModule{$enc} eq $mod and $enc{$enc} = $mod;
            }
        }
    }
    return sort { lc $a cmp lc $b }
      grep      { !/^(?:Internal|Unicode|Guess)$/o } keys %enc;
}

sub perlio_ok {
    my $obj = ref( $_[0] ) ? $_[0] : find_encoding( $_[0] );
    $obj->can("perlio_ok") and return $obj->perlio_ok();
    return 0;    # safety net
}

sub define_encoding {
    my $obj  = shift;
    my $name = shift;
    $Encoding{$name} = $obj;
    my $lc = lc($name);
    define_alias( $lc => $obj ) unless $lc eq $name;
    while (@_) {
        my $alias = shift;
        define_alias( $alias, $obj );
    }
    return $obj;
}

sub getEncoding {
    my ( $class, $name, $skip_external ) = @_;

    ref($name) && $name->can('renew') and return $name;
    exists $Encoding{$name} and return $Encoding{$name};
    my $lc = lc $name;
    exists $Encoding{$lc} and return $Encoding{$lc};

    my $oc = $class->find_alias($name);
    defined($oc) and return $oc;
    $lc ne $name and $oc = $class->find_alias($lc);
    defined($oc) and return $oc;

    unless ($skip_external) {
        if ( my $mod = $ExtModule{$name} || $ExtModule{$lc} ) {
            $mod =~ s,::,/,g;
            $mod .= '.pm';
            eval { require $mod; };
            exists $Encoding{$name} and return $Encoding{$name};
        }
    }
    return;
}

sub find_encoding($;$) {
    my ( $name, $skip_external ) = @_;
    return __PACKAGE__->getEncoding( $name, $skip_external );
}

sub resolve_alias($) {
    my $obj = find_encoding(shift);
    defined $obj and return $obj->name;
    return;
}

sub clone_encoding($) {
    my $obj = find_encoding(shift);
    ref $obj or return;
    eval { require Storable };
    $@ and return;
    return Storable::dclone($obj);
}

sub encode($$;$) {
    my ( $name, $string, $check ) = @_;
    return undef unless defined $string;
    $string .= '' if ref $string;    # stringify;
    $check ||= 0;
    my $enc = find_encoding($name);
    unless ( defined $enc ) {
        require Carp;
        Carp::croak("Unknown encoding '$name'");
    }
    my $octets = $enc->encode( $string, $check );
    $_[1] = $string if $check and !ref $check and !( $check & LEAVE_SRC() );
    return $octets;
}
*str2bytes = \&encode;

sub decode($$;$) {
    my ( $name, $octets, $check ) = @_;
    return undef unless defined $octets;
    $octets .= '' if ref $octets;
    $check ||= 0;
    my $enc = find_encoding($name);
    unless ( defined $enc ) {
        require Carp;
        Carp::croak("Unknown encoding '$name'");
    }
    my $string = $enc->decode( $octets, $check );
    $_[1] = $octets if $check and !ref $check and !( $check & LEAVE_SRC() );
    return $string;
}
*bytes2str = \&decode;

sub from_to($$$;$) {
    my ( $string, $from, $to, $check ) = @_;
    return undef unless defined $string;
    $check ||= 0;
    my $f = find_encoding($from);
    unless ( defined $f ) {
        require Carp;
        Carp::croak("Unknown encoding '$from'");
    }
    my $t = find_encoding($to);
    unless ( defined $t ) {
        require Carp;
        Carp::croak("Unknown encoding '$to'");
    }
    my $uni = $f->decode($string);
    $_[0] = $string = $t->encode( $uni, $check );
    return undef if ( $check && length($uni) );
    return defined( $_[0] ) ? length($string) : undef;
}

sub encode_utf8($) {
    my ($str) = @_;
    utf8::encode($str);
    return $str;
}

sub decode_utf8($;$) {
    my ( $str, $check ) = @_;
    return $str if is_utf8($str);
    if ($check) {
        return decode( "utf8", $str, $check );
    }
    else {
        return decode( "utf8", $str );
        return $str;
    }
}

predefine_encodings(1);


sub predefine_encodings {
    require Encode::Encoding;
    no warnings 'redefine';
    my $use_xs = shift;
    if ($ON_EBCDIC) {

        # was in Encode::UTF_EBCDIC
        package Encode::UTF_EBCDIC;
        push @Encode::UTF_EBCDIC::ISA, 'Encode::Encoding';
        *decode = sub {
            my ( $obj, $str, $chk ) = @_;
            my $res = '';
            for ( my $i = 0 ; $i < length($str) ; $i++ ) {
                $res .=
                  chr(
                    utf8::unicode_to_native( ord( substr( $str, $i, 1 ) ) )
                  );
            }
            $_[1] = '' if $chk;
            return $res;
        };
        *encode = sub {
            my ( $obj, $str, $chk ) = @_;
            my $res = '';
            for ( my $i = 0 ; $i < length($str) ; $i++ ) {
                $res .=
                  chr(
                    utf8::native_to_unicode( ord( substr( $str, $i, 1 ) ) )
                  );
            }
            $_[1] = '' if $chk;
            return $res;
        };
        $Encode::Encoding{Unicode} =
          bless { Name => "UTF_EBCDIC" } => "Encode::UTF_EBCDIC";
    }
    else {

        package Encode::Internal;
        push @Encode::Internal::ISA, 'Encode::Encoding';
        *decode = sub {
            my ( $obj, $str, $chk ) = @_;
            utf8::upgrade($str);
            $_[1] = '' if $chk;
            return $str;
        };
        *encode = \&decode;
        $Encode::Encoding{Unicode} =
          bless { Name => "Internal" } => "Encode::Internal";
    }

    {

        # was in Encode::utf8
        package Encode::utf8;
        push @Encode::utf8::ISA, 'Encode::Encoding';

        #
        if ($use_xs) {
            Encode::DEBUG and warn __PACKAGE__, " XS on";
            *decode = \&decode_xs;
            *encode = \&encode_xs;
        }
        else {
            Encode::DEBUG and warn __PACKAGE__, " XS off";
            *decode = sub {
                my ( $obj, $octets, $chk ) = @_;
                my $str = Encode::decode_utf8($octets);
                if ( defined $str ) {
                    $_[1] = '' if $chk;
                    return $str;
                }
                return undef;
            };
            *encode = sub {
                my ( $obj, $string, $chk ) = @_;
                my $octets = Encode::encode_utf8($string);
                $_[1] = '' if $chk;
                return $octets;
            };
        }
        *cat_decode = sub {    # ($obj, $dst, $src, $pos, $trm, $chk)
                               # currently ignores $chk
            my ( $obj, undef, undef, $pos, $trm ) = @_;
            my ( $rdst, $rsrc, $rpos ) = \@_[ 1, 2, 3 ];
            use bytes;
            if ( ( my $npos = index( $$rsrc, $trm, $pos ) ) >= 0 ) {
                $$rdst .=
                  substr( $$rsrc, $pos, $npos - $pos + length($trm) );
                $$rpos = $npos + length($trm);
                return 1;
            }
            $$rdst .= substr( $$rsrc, $pos );
            $$rpos = length($$rsrc);
            return '';
        };
        $Encode::Encoding{utf8} =
          bless { Name => "utf8" } => "Encode::utf8";
        $Encode::Encoding{"utf-8-strict"} =
          bless { Name => "utf-8-strict", strict_utf8 => 1 } =>
          "Encode::utf8";
    }
}

1;

__END__

