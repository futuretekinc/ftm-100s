
package Image::ExifTool::Charset;

use strict;
use vars qw($VERSION %csType);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.07';

my %charsetTable;   # character set tables we've loaded

my %unicode2byte = (
  Latin => {    # pre-load Latin (cp1252) for speed
    0x20ac => 0x80,  0x0160 => 0x8a,  0x2013 => 0x96,
    0x201a => 0x82,  0x2039 => 0x8b,  0x2014 => 0x97,
    0x0192 => 0x83,  0x0152 => 0x8c,  0x02dc => 0x98,
    0x201e => 0x84,  0x017d => 0x8e,  0x2122 => 0x99,
    0x2026 => 0x85,  0x2018 => 0x91,  0x0161 => 0x9a,
    0x2020 => 0x86,  0x2019 => 0x92,  0x203a => 0x9b,
    0x2021 => 0x87,  0x201c => 0x93,  0x0153 => 0x9c,
    0x02c6 => 0x88,  0x201d => 0x94,  0x017e => 0x9e,
    0x2030 => 0x89,  0x2022 => 0x95,  0x0178 => 0x9f,
  },
);

%csType = (
    UTF8         => 0x100,
    ASCII        => 0x100, # (treated like UTF8)
    Arabic       => 0x101,
    Baltic       => 0x101,
    Cyrillic     => 0x101,
    Greek        => 0x101,
    Hebrew       => 0x101,
    Latin        => 0x101,
    Latin2       => 0x101,
    MacCroatian  => 0x101,
    MacCyrillic  => 0x101,
    MacGreek     => 0x101,
    MacIceland   => 0x101,
    MacLatin2    => 0x101,
    MacRoman     => 0x101,
    MacRomanian  => 0x101,
    MacTurkish   => 0x101,
    Thai         => 0x101,
    Turkish      => 0x101,
    Vietnam      => 0x101,
    MacArabic    => 0x103, # (directional characters not supported)
    PDFDoc       => 0x181,
    Unicode      => 0x200, # (UCS2)
    UCS2         => 0x200,
    UTF16        => 0x200,
    Symbol       => 0x201,
    JIS          => 0x201,
    UCS4         => 0x400,
    MacChineseCN => 0x803,
    MacChineseTW => 0x803,
    MacHebrew    => 0x803, # (directional characters not supported)
    MacKorean    => 0x803,
    MacRSymbol   => 0x803,
    MacThai      => 0x803,
    MacJapanese  => 0x883,
    ShiftJIS     => 0x883,
);

sub LoadCharset($)
{
    my $charset = shift;
    my $conv = $charsetTable{$charset};
    unless ($conv) {
        # load translation module
        my $module = "Image::ExifTool::Charset::$charset";
        no strict 'refs';
        if (%$module or eval "require $module") {
            $conv = $charsetTable{$charset} = \%$module;
        }
    }
    return $conv;
}

sub Decompose($$$;$)
{
    local $_;
    my ($exifTool, $val, $charset) = @_; # ($byteOrder assigned later if required)
    my $type = $csType{$charset};
    my (@uni, $conv);

    if ($type & 0x001) {
        $conv = LoadCharset($charset);
        unless ($conv) {
            # (shouldn't happen)
            $exifTool->Warn("Invalid character set $charset") if $exifTool;
            return \@uni;   # error!
        }
    } elsif ($type == 0x100) {
        # convert ASCII and UTF8 (treat ASCII as UTF8)
        if ($] < 5.006001) {
            # do it ourself
            @uni = Image::ExifTool::UnpackUTF8($val);
        } else {
            # handle warnings from malformed UTF-8
            undef $Image::ExifTool::evalWarning;
            local $SIG{'__WARN__'} = \&Image::ExifTool::SetWarning;
            # (somehow the meaning of "U0" was reversed in Perl 5.10.0!)
            @uni = unpack($] < 5.010000 ? 'U0U*' : 'C0U*', $val);
            # issue warning if we had errors
            if ($Image::ExifTool::evalWarning and $exifTool and not $$exifTool{WarnBadUTF8}) {
                $exifTool->Warn('Malformed UTF-8 character(s)');
                $$exifTool{WarnBadUTF8} = 1;
            }
        }
        return \@uni;       # all done!
    }
    if ($type & 0x100) {        # 1-byte fixed-width characters
        @uni = unpack('C*', $val);
        foreach (@uni) {
            $_ = $$conv{$_} if defined $$conv{$_};
        }
    } elsif ($type & 0x600) {   # 2-byte or 4-byte fixed-width characters
        my $unknown;
        my $byteOrder = $_[3];
        if (not $byteOrder) {
            $byteOrder = GetByteOrder();
        } elsif ($byteOrder eq 'Unknown') {
            $byteOrder = GetByteOrder();
            $unknown = 1;
        }
        my $fmt = $byteOrder eq 'MM' ? 'n*' : 'v*';
        if ($type & 0x400) {    # 4-byte
            $fmt = uc $fmt; # unpack as 'N*' or 'V*'
            # honour BOM if it exists
            $val =~ s/^(\0\0\xfe\xff|\xff\xfe\0\0)// and $fmt = $1 eq "\0\0\xfe\xff" ? 'N*' : 'V*';
            undef $unknown; # (byte order logic applies to 2-byte only)
        } elsif ($val =~ s/^(\xfe\xff|\xff\xfe)//) {
            $fmt = $1 eq "\xfe\xff" ? 'n*' : 'v*';
            undef $unknown;
        }
        # convert from UCS2 or UCS4
        @uni = unpack($fmt, $val);

        if (not $conv) {
            # no translation necessary
            if ($unknown) {
                # check the byte order
                my (%bh, %bl);
                my ($zh, $zl) = (0, 0);
                foreach (@uni) {
                    $bh{$_ >> 8} = 1;
                    $bl{$_ & 0xff} = 1;
                    ++$zh unless $_ & 0xff00;
                    ++$zl unless $_ & 0x00ff;
                }
                # count the number of unique values in the hi and lo bytes
                my ($bh, $bl) = (scalar(keys %bh), scalar(keys %bl));
                # the byte with the greater number of unique values should be
                # the low-order byte, otherwise the byte which is zero more
                # often is likely the high-order byte
                if ($bh > $bl or ($bh == $bl and $zl > $zh)) {
                    # we guessed wrong, so decode using the other byte order
                    $fmt =~ tr/nvNV/vnVN/;
                    @uni = unpack($fmt, $val);
                }
            }
            # handle surrogate pairs of UTF-16
            if ($charset eq 'UTF16') {
                my $i;
                for ($i=0; $i<$#uni; ++$i) {
                    next unless ($uni[$i]   & 0xfc00) == 0xd800 and
                                ($uni[$i+1] & 0xfc00) == 0xdc00;
                    my $cp = 0x10000 + (($uni[$i] & 0x3ff) << 10) + ($uni[$i+1] & 0x3ff);
                    splice(@uni, $i, 2, $cp);
                }
            }
        } elsif ($unknown) {
            # count encoding errors as we do the translation
            my $e1 = 0;
            foreach (@uni) {
                defined $$conv{$_} and $_ = $$conv{$_}, next;
                ++$e1;
            }
            # try the other byte order if we had any errors
            if ($e1) {
                $fmt = $byteOrder eq 'MM' ? 'v*' : 'n*'; #(reversed)
                my @try = unpack($fmt, $val);
                my $e2 = 0;
                foreach (@try) {
                    defined $$conv{$_} and $_ = $$conv{$_}, next;
                    ++$e2;
                }
                # use this byte order if there are fewer errors
                return \@try if $e2 < $e1;
            }
        } else {
            # translate any characters found in the lookup
            foreach (@uni) {
                $_ = $$conv{$_} if defined $$conv{$_};
            }
        }
    } else {                    # variable-width characters
        # unpack into bytes
        my @bytes = unpack('C*', $val);
        while (@bytes) {
            my $ch = shift @bytes;
            my $cv = $$conv{$ch};
            # pass straight through if no translation
            $cv or push(@uni, $ch), next;
            # byte translates into single Unicode character
            ref $cv or push(@uni, $cv), next;
            # byte maps into multiple Unicode characters
            ref $cv eq 'ARRAY' and push(@uni, @$cv), next;
            # handle 2-byte character codes
            $ch = shift @bytes;
            if (defined $ch) {
                if ($$cv{$ch}) {
                    $cv = $$cv{$ch};
                    ref $cv or push(@uni, $cv), next;
                    push @uni, @$cv;        # multiple Unicode characters
                } else {
                    push @uni, ord('?');    # encoding error
                    unshift @bytes, $ch;
                }
            } else {
                push @uni, ord('?');        # encoding error
            }
        }
    }
    return \@uni;
}

sub Recompose($$;$$)
{
    local $_;
    my ($exifTool, $uni, $charset) = @_; # ($byteOrder assigned later if required)
    my ($outVal, $conv, $inv);
    $charset or $charset = $$exifTool{OPTIONS}{Charset};
    my $csType = $csType{$charset};
    if ($csType == 0x100) {     # UTF8 (also treat ASCII as UTF8)
        if ($] >= 5.006001) {
            # let Perl do it
            $outVal = pack('C0U*', @$uni);
        } else {
            # do it ourself
            $outVal = Image::ExifTool::PackUTF8(@$uni);
        }
        $outVal =~ s/\0.*//s;   # truncate at null terminator
        return $outVal;
    }
    # get references to forward and inverse lookup tables
    if ($csType & 0x801) {
        $conv = LoadCharset($charset);
        unless ($conv) {
            $exifTool->Warn("Missing charset $charset") if $exifTool;
            return '';
        }
        $inv = $unicode2byte{$charset};
        # generate inverse lookup if necessary
        unless ($inv) {
            if (not $csType or $csType & 0x802) {
                $exifTool->Warn("Invalid destination charset $charset") if $exifTool;
                return '';
            }
            # prepare table to convert from Unicode to 1-byte characters
            my ($char, %inv);
            foreach $char (keys %$conv) {
                $inv{$$conv{$char}} = $char;
            }
            $inv = $unicode2byte{$charset} = \%inv;
        }
    }
    if ($csType & 0x100) {      # 1-byte fixed-width
        # convert to specified character set
        foreach (@$uni) {
            next if $_ < 0x80;
            $$inv{$_} and $_ = $$inv{$_}, next;
            # our tables omit 1-byte characters with the same values as Unicode,
            # so pass them straight through after making sure there isn't a
            # different character with this byte value
            next if $_ < 0x100 and not $$conv{$_};
            $_ = ord('?');  # set invalid characters to '?'
            if ($exifTool and not $$exifTool{EncodingError}) {
                $exifTool->Warn("Some character(s) could not be encoded in $charset");
                $$exifTool{EncodingError} = 1;
            }
        }
        # repack as an 8-bit string and truncate at null
        $outVal = pack('C*', @$uni);
        $outVal =~ s/\0.*//s;
    } else {                    # 2-byte and 4-byte fixed-width
        # convert if required
        if ($inv) {
            $$inv{$_} and $_ = $$inv{$_} foreach @$uni;
        }
        # generate surrogate pairs of UTF-16
        if ($charset eq 'UTF16') {
            my $i;
            for ($i=0; $i<@$uni; ++$i) {
                next unless $$uni[$i] >= 0x10000 and $$uni[$i] < 0x10ffff;
                my $t = $$uni[$i] - 0x10000;
                my $w1 = 0xd800 + (($t >> 10) & 0x3ff);
                my $w2 = 0xdc00 + ($t & 0x3ff);
                splice(@$uni, $i, 1, $w1, $w2);
                ++$i;   # skip surrogate pair
            }
        }
        # pack as 2- or 4-byte integer in specified byte order
        my $byteOrder = $_[3] || GetByteOrder();
        my $fmt = $byteOrder eq 'MM' ? 'n*' : 'v*';
        $fmt = uc($fmt) if $csType & 0x400;
        $outVal = pack($fmt, @$uni);
    }
    return $outVal;
}

1; # end

__END__

