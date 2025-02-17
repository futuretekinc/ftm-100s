
package Image::ExifTool::PostScript;

use strict;
use vars qw($VERSION $AUTOLOAD);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.34';

sub WritePS($$);
sub ProcessPS($$;$);

%Image::ExifTool::PostScript::Main = (
    PROCESS_PROC => \&ProcessPS,
    WRITE_PROC => \&WritePS,
    PREFERRED => 1, # always add these tags when writing
    GROUPS => { 2 => 'Image' },
    # Note: Make all of these tags priority 0 since the first one found at
    # the start of the file should take priority (in case multiples exist)
    Author      => { Priority => 0, Groups => { 2 => 'Author' }, Writable => 'string' },
    BoundingBox => { Priority => 0 },
    Copyright   => { Priority => 0, Writable => 'string' }, #2
    CreationDate => {
        Name => 'CreateDate',
        Priority => 0,
        Groups => { 2 => 'Time' },
        Writable => 'string',
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val)',
    },
    Creator     => { Priority => 0, Writable => 'string' },
    ImageData   => { Priority => 0 },
    For         => { Priority => 0, Writable => 'string', Notes => 'for whom the document was prepared'},
    Keywords    => { Priority => 0, Writable => 'string' },
    ModDate => {
        Name => 'ModifyDate',
        Priority => 0,
        Groups => { 2 => 'Time' },
        Writable => 'string',
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val)',
    },
    Pages       => { Priority => 0 },
    Routing     => { Priority => 0, Writable => 'string' }, #2
    Subject     => { Priority => 0, Writable => 'string' },
    Title       => { Priority => 0, Writable => 'string' },
    Version     => { Priority => 0, Writable => 'string' }, #2
    # these subdirectories for documentation only
    BeginPhotoshop => {
        Name => 'PhotoshopData',
        SubDirectory => {
            TagTable => 'Image::ExifTool::Photoshop::Main',
        },
    },
    BeginICCProfile => {
        Name => 'ICC_Profile',
        SubDirectory => {
            TagTable => 'Image::ExifTool::ICC_Profile::Main',
        },
    },
    begin_xml_packet => {
        Name => 'XMP',
        SubDirectory => {
            TagTable => 'Image::ExifTool::XMP::Main',
        },
    },
    TIFFPreview => {
        Binary => 1,
        Notes => q{
            not a real tag ID, but used to represent the TIFF preview extracted from DOS
            EPS images
        },
    },
    BeginDocument => {
        Name => 'EmbeddedFile',
        SubDirectory => {
            TagTable => 'Image::ExifTool::PostScript::Main',
        },
        Notes => 'extracted with ExtractEmbedded option',
    },
    EmbeddedFileName => {
        Notes => q{
            not a real tag ID, but the file name from a BeginDocument statement.
            Extracted with document metadata when ExtractEmbedded option is used
        },
    },
);

%Image::ExifTool::PostScript::Composite = (
    GROUPS => { 2 => 'Image' },
    # BoundingBox is in points, not pixels,
    # but use it anyway if ImageData is not available
    ImageWidth => {
        Desire => {
            0 => 'Main:PostScript:ImageData',
            1 => 'PostScript:BoundingBox',
        },
        ValueConv => 'Image::ExifTool::PostScript::ImageSize(\@val, 0)',
    },
    ImageHeight => {
        Desire => {
            0 => 'Main:PostScript:ImageData',
            1 => 'PostScript:BoundingBox',
        },
        ValueConv => 'Image::ExifTool::PostScript::ImageSize(\@val, 1)',
    },
);

Image::ExifTool::AddCompositeTags('Image::ExifTool::PostScript');

sub AUTOLOAD
{
    return Image::ExifTool::DoAutoLoad($AUTOLOAD, @_);
}

my %isPC = (MSWin32 => 1, os2 => 1, dos => 1, NetWare => 1, symbian => 1, cygwin => 1);
sub IsPC()
{
    return $isPC{$^O};
}

sub ImageSize($$)
{
    my ($vals, $getHeight) = @_;
    my ($w, $h);
    if ($$vals[0] and $$vals[0] =~ /^(\d+) (\d+)/) {
        ($w, $h) = ($1, $2);
    } elsif ($$vals[1] and $$vals[1] =~ /^(\d+) (\d+) (\d+) (\d+)/) {
        ($w, $h) = ($3 - $1, $4 - $2);
    }
    return $getHeight ? $h : $w;
}

sub PSErr($$)
{
    my ($exifTool, $str) = @_;
    # set file type if not done already
    my $ext = $$exifTool{FILE_EXT};
    $exifTool->SetFileType(($ext and $ext eq 'AI') ? 'AI' : 'PS');
    $exifTool->Warn("PostScript format error ($str)");
    return 1;
}

sub GetInputRecordSeparator($)
{
    my $raf = shift;
    my $pos = $raf->Tell(); # save current position
    my ($data, $sep);
    $raf->Read($data,256) or return undef;
    my ($a, $d) = (999,999);
    $a = pos($data), pos($data) = 0 if $data =~ /\x0a/g;
    $d = pos($data) if $data =~ /\x0d/g;
    my $diff = $a - $d;
    if ($diff eq 1) {
        $sep = "\x0d\x0a";
    } elsif ($diff eq -1) {
        $sep = "\x0a\x0d";
    } elsif ($diff > 0) {
        $sep = "\x0d";
    } elsif ($diff < 0) {
        $sep = "\x0a";
    } # else error
    $raf->Seek($pos, 0);    # restore original position
    return $sep;
}

sub DecodeComment($$$;$)
{
    my ($val, $raf, $lines, $dataPt) = @_;
    $val =~ s/\x0d*\x0a*$//;        # remove trailing CR, LF or CR/LF
    # check for continuation comments
    for (;;) {
        unless (@$lines) {
            my $buff;
            $raf->ReadLine($buff) or last;
            my $altnl = $/ eq "\x0d" ? "\x0a" : "\x0d";
            if ($buff =~ /$altnl/) {
                # split into separate lines
                @$lines = split /$altnl/, $buff, -1;
                # handle case of DOS newline data inside file using Unix newlines
                @$lines = ( $$lines[0] . $$lines[1] ) if @$lines == 2 and $$lines[1] eq $/;
            } else {
                push @$lines, $buff;
            }
        }
        last unless $$lines[0] =~ /^%%\+/;  # is the next line a continuation?
        $$dataPt .= $$lines[0] if $dataPt;  # add to data if necessary
        $$lines[0] =~ s/\x0d*\x0a*$//;      # remove trailing CR, LF or CR/LF
        $val .= substr(shift(@$lines), 3);  # add to value (without leading "%%+")
    }
    my @vals;
    # handle bracketed string values
    if ($val =~ s/^\((.*)\)$/$1/) { # remove brackets if necessary
        # split into an array of strings if necessary
        my $nesting = 1;
        while ($val =~ /(\(|\))/g) {
            my $bra = $1;
            my $pos = pos($val) - 2;
            my $backslashes = 0;
            while ($pos and substr($val, $pos, 1) eq '\\') {
                --$pos;
                ++$backslashes;
            }
            next if $backslashes & 0x01;    # escaped if odd number
            if ($bra eq '(') {
                ++$nesting;
            } else {
                --$nesting;
                unless ($nesting) {
                    push @vals, substr($val, 0, pos($val)-1);
                    $val = substr($val, pos($val));
                    ++$nesting if $val =~ s/\s*\(//;
                }
            }
        }
        push @vals, $val;
        foreach $val (@vals) {
            # decode escape sequences in bracketed strings
            # (similar to code in PDF.pm, but without line continuation)
            while ($val =~ /\\(.)/sg) {
                my $n = pos($val) - 2;
                my $c = $1;
                my $r;
                if ($c =~ /[0-7]/) {
                    # get up to 2 more octal digits
                    $c .= $1 if $val =~ /\G([0-7]{1,2})/g;
                    # convert octal escape code
                    $r = chr(oct($c) & 0xff);
                } else {
                    # convert escaped characters
                    ($r = $c) =~ tr/nrtbf/\n\r\t\b\f/;
                }
                substr($val, $n, length($c)+1) = $r;
                # continue search after this character
                pos($val) = $n + length($r);
            }
        }
        $val = @vals > 1 ? \@vals : $vals[0];
    }
    return $val;
}

sub UnescapePostScript($)
{
    my $str = shift;
    # decode escape sequences in literal strings
    while ($str =~ /\\(.)/sg) {
        my $n = pos($str) - 2;
        my $c = $1;
        my $r;
        if ($c =~ /[0-7]/) {
            # get up to 2 more octal digits
            $c .= $1 if $str =~ /\G([0-7]{1,2})/g;
            # convert octal escape code
            $r = chr(oct($c) & 0xff);
        } elsif ($c eq "\x0d") {
            # the string is continued if the line ends with '\'
            # (also remove "\x0d\x0a")
            $c .= $1 if $str =~ /\G(\x0a)/g;
            $r = '';
        } elsif ($c eq "\x0a") {
            $r = '';
        } else {
            # convert escaped characters
            ($r = $c) =~ tr/nrtbf/\n\r\t\b\f/;
        }
        substr($str, $n, length($c)+1) = $r;
        # continue search after this character
        pos($str) = $n + length($r);
    }
    return $str;
}

sub ProcessPS($$;$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $raf = $$dirInfo{RAF};
    my $embedded = $exifTool->Options('ExtractEmbedded');
    my ($data, $dos, $endDoc, $fontTable, $comment);

    # allow read from data
    $raf = new File::RandomAccess($$dirInfo{DataPt}) unless $raf;
    $raf->Read($data, 4) == 4 or return 0;
    # accept either ASCII or DOS binary postscript file format
    return 0 unless $data =~ /^(%!PS|%!Ad|%!Fo|\xc5\xd0\xd3\xc6)/;
    if ($data =~ /^%!Ad/) {
        # I've seen PS files start with "%!Adobe-PS"...
        return 0 unless $raf->Read($data, 6) == 6 and $data eq "obe-PS";
    } elsif ($data =~ /^\xc5\xd0\xd3\xc6/) {
        # process DOS binary file header
        # - save DOS header then seek ahead and check PS header
        $raf->Read($dos, 26) == 26 or return 0;
        SetByteOrder('II');
        unless ($raf->Seek(Get32u(\$dos, 0), 0) and
                $raf->Read($data, 4) == 4 and $data eq '%!PS')
        {
            return PSErr($exifTool, 'invalid header');
        }
    } else {
        # check for PostScript font file (PFA or PFB)
        my $d2;
        $data .= $d2 if $raf->Read($d2,12);
        if ($data =~ /^%!(PS-(AdobeFont-|Bitstream )|FontType1-)/) {
            $exifTool->SetFileType('PFA');  # PostScript ASCII font file
            $fontTable = GetTagTable('Image::ExifTool::Font::PSInfo');
            # PostScript font files may contain an unformatted comments which may
            # contain useful information, so accumulate these for the Comment tag
            $comment = 1;
        }
        $raf->Seek(-length($data), 1);
    }
    local $/ = GetInputRecordSeparator($raf);
    $/ or return PSErr($exifTool, 'invalid PS data');

    # set file type (PostScript or EPS)
    $raf->ReadLine($data) or $data = '';
    my $type;
    if ($data =~ /EPSF/) {
        $type = 'EPS';
    } else {
        # read next line to see if this is an Illustrator file
        my $line2;
        my $pos = $raf->Tell();
        if ($raf->ReadLine($line2) and $line2 =~ /^%%Creator: Adobe Illustrator/) {
            $type = 'AI';
        } else {
            $type = 'PS';
        }
        $raf->Seek($pos, 0);
    }
    $exifTool->SetFileType($type);
    $tagTablePtr or $tagTablePtr = GetTagTable('Image::ExifTool::PostScript::Main');
    if ($dos) {
        my $base = Get32u(\$dos, 16);
        if ($base) {
            my $pos = $raf->Tell();
            # extract the TIFF preview
            my $len = Get32u(\$dos, 20);
            my $val = $exifTool->ExtractBinary($base, $len, 'TIFFPreview');
            if (defined $val and $val =~ /^(MM\0\x2a|II\x2a\0|Binary)/) {
                $exifTool->HandleTag($tagTablePtr, 'TIFFPreview', $val);
            } else {
                $exifTool->Warn('Bad TIFF preview image');
            }
            # extract information from TIFF in DOS header
            # (set Parent to '' to avoid setting FileType tag again)
            my %dirInfo = (
                Parent => '',
                RAF => $raf,
                Base => $base,
            );
            $exifTool->ProcessTIFF(\%dirInfo) or $exifTool->Warn('Bad embedded TIFF');
            # position file pointer to extract PS information
            $raf->Seek($pos, 0);
        }
    }
    my ($buff, $mode, $beginToken, $endToken, $docNum, $subDocNum, $changedNL);
    my (@lines, $altnl);
    if ($/ eq "\x0d") {
        $altnl = "\x0a";
    } else {
        $/ = "\x0a";        # end on any LF (even if DOS CR+LF)
        $altnl = "\x0d";
    }
    for (;;) {
        if (@lines) {
            $data = shift @lines;
        } else {
            $raf->ReadLine($data) or last;
            # check for alternate newlines as efficiently as possible
            if ($data =~ /$altnl/) {
                if (length($data) > 500000 and IsPC()) {
                    # Windows can't split very long lines due to poor memory handling,
                    # so re-read the file with the other newline character instead
                    # (slower but uses less memory)
                    unless ($changedNL) {
                        $changedNL = 1;
                        my $t = $/;
                        $/ = $altnl;
                        $altnl = $t;
                        $raf->Seek(-length($data), 1);
                        next;
                    }
                } else {
                    # split into separate lines
                    @lines = split /$altnl/, $data, -1;
                    $data = shift @lines;
                    if (@lines == 1 and $lines[0] eq $/) {
                        # handle case of DOS newline data inside file using Unix newlines
                        $data .= $lines[0];
                        undef @lines;
                    }
                }
            }
        }
        undef $changedNL;
        if ($mode) {
            if (not $endToken) {
                $buff .= $data;
                next unless $data =~ m{<\?xpacket end=.(w|r).\?>($/|$)};
            } elsif ($data !~ /^$endToken/i) {
                if ($mode eq 'XMP') {
                    $buff .= $data;
                } elsif ($mode eq 'Document') {
                    # ignore embedded documents, but keep track of nesting level
                    $docNum .= '-1' if $data =~ /^$beginToken/;
                } else {
                    # data is ASCII-hex encoded
                    $data =~ tr/0-9A-Fa-f//dc;  # remove all but hex characters
                    $buff .= pack('H*', $data); # translate from hex
                }
                next;
            } elsif ($mode eq 'Document') {
                $docNum =~ s/-?\d+$//;  # decrement document nesting level
                # done with Document mode if we are back at the top level
                undef $mode unless $docNum;
                next;
            }
        } elsif ($endDoc and $data =~ /^$endDoc/i) {
            $docNum =~ s/-?(\d+)$//;        # decrement nesting level
            $subDocNum = $1;                # remember our last sub-document number
            $$exifTool{DOC_NUM} = $docNum;
            undef $endDoc unless $docNum;   # done with document if top level
            next;
        } elsif ($data =~ /^(%{1,2})(Begin)(_xml_packet|Photoshop|ICCProfile|Document|Binary)/i) {
            # the beginning of a data block
            my %modeLookup = (
                _xml_packet => 'XMP',
                photoshop   => 'Photoshop',
                iccprofile  => 'ICC_Profile',
                document    => 'Document',
                binary      => undef, # (we will try to skip this)
            );
            $mode = $modeLookup{lc $3};
            unless ($mode) {
                if (not @lines and $data =~ /^%{1,2}BeginBinary:\s*(\d+)/i) {
                    $raf->Seek($1, 1) or last;  # skip binary data
                }
                next;
            }
            $buff = '';
            $beginToken = $1 . $2 . $3;
            $endToken = $1 . ($2 eq 'begin' ? 'end' : 'End') . $3;
            if ($mode eq 'Document') {
                # this is either the 1st sub-document or Nth document
                if ($docNum) {
                    # increase nesting level
                    $docNum .= '-' . (++$subDocNum);
                } else {
                    # this is the Nth document
                    $docNum = $$exifTool{DOC_COUNT} + 1;
                }
                $subDocNum = 0; # new level, so reset subDocNum
                next unless $embedded;  # skip over this document
                # set document number for family 4-7 group names
                $$exifTool{DOC_NUM} = $docNum;
                $$exifTool{LIST_TAGS} = { };  # don't build lists across different documents
                $exifTool->{PROCESSED} = { }; # re-initialize processed directory lookup too
                $endDoc = $endToken;          # parse to EndDocument token
                # reset mode to allow parsing into sub-directories
                undef $endToken;
                undef $mode;
                # save document name if available
                if ($data =~ /^$beginToken:\s+([^\n\r]+)/i) {
                    my $docName = $1;
                    # remove brackets if necessary
                    $docName = $1 if $docName =~ /^\((.*)\)$/;
                    $exifTool->HandleTag($tagTablePtr, 'EmbeddedFileName', $docName);
                }
            }
            next;
        } elsif ($data =~ /^<\?xpacket begin=.{7,13}W5M0MpCehiHzreSzNTczkc9d/) {
            # pick up any stray XMP data
            $mode = 'XMP';
            $buff = $data;
            undef $endToken;    # no end token (just look for xpacket end)
            # XMP could be contained in a single line (if newlines are different)
            next unless $data =~ m{<\?xpacket end=.(w|r).\?>($/|$)};
        } elsif ($data =~ /^%%?(\w+): ?(.*)/s and $$tagTablePtr{$1}) {
            my ($tag, $val) = ($1, $2);
            # only allow 'ImageData' to have single leading '%'
            next unless $data =~ /^%%/ or $1 eq 'ImageData';
            # decode comment string (reading continuation lines if necessary)
            $val = DecodeComment($val, $raf, \@lines);
            $exifTool->HandleTag($tagTablePtr, $tag, $val);
            next;
        } elsif ($embedded and $data =~ /^%AI12_CompressedData/) {
            # the rest of the file is compressed
            unless (eval 'require Compress::Zlib') {
                $exifTool->Warn('Install Compress::Zlib to extract compressed embedded data');
                last;
            }
            # seek back to find the start of the compressed data in the file
            my $tlen = length($data) + @lines;
            $tlen += length $_ foreach @lines;
            my $backTo = $raf->Tell() - $tlen - 64;
            $backTo = 0 if $backTo < 0;
            last unless $raf->Seek($backTo, 0) and $raf->Read($data, 2048);
            last unless $data =~ s/.*?%AI12_CompressedData//;
            my $inflate = Compress::Zlib::inflateInit();
            $inflate or $exifTool->Warn('Error initializing inflate'), last;
            # generate a PS-like file in memory from the compressed data
            my $verbose = $exifTool->Options('Verbose');
            if ($verbose > 1) {
                $exifTool->VerboseDir('AI12_CompressedData (first 4kB)');
                $exifTool->VerboseDump(\$data);
            }
            # remove header if it exists (Windows AI files only)
            $data =~ s/^.{0,256}EndData[\x0d\x0a]+//s;
            my $val;
            for (;;) {
                my ($v2, $stat) = $inflate->inflate($data);
                $stat == Compress::Zlib::Z_STREAM_END() and $val .= $v2, last;
                $stat != Compress::Zlib::Z_OK() and undef($val), last;
                if (defined $val) {
                    $val .= $v2;
                } elsif ($v2 =~ /^%!PS/) {
                    $val = $v2;
                } else {
                    # add postscript header (for file recognition) if it doesn't exist
                    $val = "%!PS-Adobe-3.0$/" . $v2;
                }
                $raf->Read($data, 65536) or last;
            }
            defined $val or $exifTool->Warn('Error inflating AI compressed data'), last;
            if ($verbose > 1) {
                $exifTool->VerboseDir('Uncompressed AI12 Data');
                $exifTool->VerboseDump(\$val);
            }
            # extract information from embedded images in the uncompressed data
            $val =  # add PS header in case it needs one
            ProcessPS($exifTool, { DataPt => \$val });
            last;
        } elsif ($fontTable) {
            if (defined $comment) {
                # extract initial comments from PostScript Font files
                if ($data =~ /^%\s+(.*?)[\x0d\x0a]/) {
                    $comment .= "\n" if $comment;
                    $comment .= $1;
                    next;
                } elsif ($data !~ /^%/) {
                    # stop extracting comments at the first non-comment line
                    $exifTool->FoundTag('Comment', $comment) if length $comment;
                    undef $comment;
                }
            }
            if ($data =~ m{^\s*/(\w+)\s*(.*)} and $$fontTable{$1}) {
                my ($tag, $val) = ($1, $2);
                if ($val =~ /^\((.*)\)/) {
                    $val = UnescapePostScript($1);
                } elsif ($val =~ m{/?(\S+)}) {
                    $val = $1;
                }
                $exifTool->HandleTag($fontTable, $tag, $val);
            } elsif ($data =~ /^currentdict end/) {
                # only extract tags from initial FontInfo dict
                undef $fontTable;
            }
            next;
        } else {
            next;
        }
        # extract information from buffered data
        my %dirInfo = (
            DataPt => \$buff,
            DataLen => length $buff,
            DirStart => 0,
            DirLen => length $buff,
            Parent => 'PostScript',
        );
        my $subTablePtr = GetTagTable("Image::ExifTool::${mode}::Main");
        unless ($exifTool->ProcessDirectory(\%dirInfo, $subTablePtr)) {
            $exifTool->Warn("Error processing $mode information in PostScript file");
        }
        undef $buff;
        undef $mode;
    }
    $mode = 'Document' if $endDoc and not $mode;
    $mode and PSErr($exifTool, "unterminated $mode data");
    return 1;
}

sub ProcessEPS($$)
{
    return ProcessPS($_[0],$_[1]);
}

1; # end


__END__

