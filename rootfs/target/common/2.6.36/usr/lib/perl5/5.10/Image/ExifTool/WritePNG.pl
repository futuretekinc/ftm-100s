package Image::ExifTool::PNG;

use strict;

my @crcTable;
sub CalculateCRC($;$$$)
{
    my ($dataPt, $crc, $pos, $len) = @_;
    $crc = 0 unless defined $crc;
    $pos = 0 unless defined $pos;
    $len = length($$dataPt) - $pos unless defined $len;
    $crc ^= 0xffffffff;         # undo 1's complement
    # build lookup table unless done already
    unless (@crcTable) {
        my ($c, $n, $k);
        for ($n=0; $n<256; ++$n) {
            for ($k=0, $c=$n; $k<8; ++$k) {
                $c = ($c & 1) ? 0xedb88320 ^ ($c >> 1) : $c >> 1;
            }
            $crcTable[$n] = $c;
        }
    }
    # calculate the CRC
    foreach (unpack("x${pos}C$len", $$dataPt)) {
        $crc = $crcTable[($crc^$_) & 0xff] ^ ($crc >> 8);
    }
    return $crc ^ 0xffffffff;   # return 1's complement
}

sub HexEncode($)
{
    my $dataPt = shift;
    my $len = length($$dataPt);
    my $hex = '';
    my $pos;
    for ($pos = 0; $pos < $len; $pos += 36) {
        my $n = $len - $pos;
        $n > 36 and $n = 36;
        $hex .= unpack('H*',substr($$dataPt,$pos,$n)) . "\n";
    }
    return $hex;
}

sub WriteProfile($$$;$)
{
    my ($outfile, $rawType, $dataPt, $profile) = @_;
    my ($buff, $prefix, $chunk, $deflate);
    if (eval 'require Compress::Zlib') {
        $deflate = Compress::Zlib::deflateInit();
    }
    if (not defined $profile) {
        # write ICC profile as compressed iCCP chunk if possible
        return 0 unless $deflate;
        $buff = $deflate->deflate($$dataPt);
        return 0 unless defined $buff;
        $buff .= $deflate->flush();
        my %rawTypeChunk = ( icm => 'iCCP' );
        $chunk = $rawTypeChunk{$rawType} or return 0;
        $prefix = "$rawType\0\0";
        $dataPt = \$buff;
    } else {
        # write as ASCII-hex encoded profile in tEXt or zTXt chunk
        my $txtHdr = sprintf("\n$profile profile\n%8d\n", length($$dataPt));
        $buff = $txtHdr . HexEncode($dataPt);
        $chunk = 'tEXt';         # write as tEXt if deflate not available
        $prefix = "Raw profile type $rawType\0";
        $dataPt = \$buff;
        # write profile as zTXt chunk if possible
        if ($deflate) {
            my $buf2 = $deflate->deflate($buff);
            if (defined $buf2) {
                $dataPt = \$buf2;
                $buf2 .= $deflate->flush();
                $chunk = 'zTXt';
                $prefix .= "\0";    # compression type byte (0=deflate)
            }
        }
    }
    my $hdr = pack('Na4', length($prefix) + length($$dataPt), $chunk) . $prefix;
    my $crc = CalculateCRC(\$hdr, undef, 4);
    $crc = CalculateCRC($dataPt, $crc);
    return Write($outfile, $hdr, $$dataPt, pack('N',$crc));
}

sub Add_iCCP($$)
{
    my ($exifTool, $outfile) = @_;
    if ($exifTool->{ADD_DIRS}->{ICC_Profile}) {
        # write new ICC data
        my $tagTablePtr = Image::ExifTool::GetTagTable('Image::ExifTool::ICC_Profile::Main');
        my %dirInfo = ( Parent => 'PNG', DirName => 'ICC_Profile' );
        my $buff = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr);
        if (defined $buff and length $buff and WriteProfile($outfile, 'icm', \$buff)) {
            $exifTool->VPrint(0, "Created ICC profile\n");
            delete $exifTool->{ADD_DIRS}->{ICC_Profile}; # don't add it again
        }
    }
    return 1;
}

sub BuildTextChunk($$$$$)
{
    my ($exifTool, $tag, $tagInfo, $val, $lang) = @_;
    my ($xtra, $compVal, $iTXt, $comp);
    if ($$tagInfo{SubDirectory}) {
        if ($$tagInfo{Name} eq 'XMP') {
            $iTXt = 2;      # write as iTXt but flag to avoid encoding
            # (never compress XMP)
        } else {
            $comp = 2;      # compress raw profile if possible
        }
    } else {
        # compress if specified
        $comp = 1 if $exifTool->Options('Compress');
        if ($lang) {
            $iTXt = 1;      # write as iTXt if it has a language code
            $tag =~ s/-$lang$//;    # remove language code from tagID
        } elsif ($$exifTool{OPTIONS}{Charset} ne 'Latin' and $val =~  /[\x80-\xff]/) {
            $iTXt = 1;      # write as iTXt if it contains non-Latin special characters
        }
    }
    if ($comp) {
        my $warn;
        if (eval 'require Compress::Zlib') {
            my $deflate = Compress::Zlib::deflateInit();
            $compVal = $deflate->deflate($val) if $deflate;
            if (defined $compVal) {
                $compVal .= $deflate->flush();
                # only compress if it actually saves space
                unless (length($compVal) < length($val)) {
                    undef $compVal;
                    $warn = 'uncompressed data is smaller';
                }
            } else {
                $warn = 'deflate error';
            }
        } else {
            $warn = 'Compress::Zlib not available';
        }
        # warn if any user-specified compression fails
        if ($warn and $comp == 1) {
            $exifTool->Warn("PNG:$$tagInfo{Name} not compressed ($warn)", 1);
        }
    }
    # decide whether to write as iTXt, zTXt or tEXt
    if ($iTXt) {
        $$exifTool{TextChunkType} = 'iTXt';
        $xtra = (defined $compVal ? "\x01\0" : "\0\0") . ($lang || '') . "\0\0";
        # iTXt is encoded as UTF-8 (but note that XMP is already UTF-8)
        $val = $exifTool->Encode($val, 'UTF8') if $iTXt == 1;
    } elsif (defined $compVal) {
        $$exifTool{TextChunkType} = 'zTXt';
        $xtra = "\0";
    } else {
        $$exifTool{TextChunkType} = 'tEXt';
        $xtra = '';
    }
    return $tag . "\0" . $xtra . (defined $compVal ? $compVal : $val);
}

sub AddChunks($$)
{
    my ($exifTool, $outfile) = @_;
    # write any outstanding PNG tags
    my $addTags = $exifTool->{ADD_PNG};
    delete $exifTool->{ADD_PNG};
    my ($tag, $dir, $err, $tagTablePtr);

    foreach $tag (sort keys %$addTags) {
        my $tagInfo = $$addTags{$tag};
        my $nvHash = $exifTool->GetNewValueHash($tagInfo);
        # (always create native PNG information, so don't check IsCreating())
        next unless $exifTool->IsOverwriting($nvHash) > 0;
        my $val = $exifTool->GetNewValues($nvHash);
        if (defined $val) {
            my $data;
            if ($$tagInfo{Table} eq \%Image::ExifTool::PNG::TextualData) {
                $data = BuildTextChunk($exifTool, $tag, $tagInfo, $val, $$tagInfo{LangCode});
                $data = $$exifTool{TextChunkType} . $data;
                delete $$exifTool{TextChunkType};
            } else {
                $data = "$tag$val";
            }
            my $hdr = pack('N', length($data) - 4);
            my $cbuf = pack('N', CalculateCRC(\$data, undef));
            Write($outfile, $hdr, $data, $cbuf) or $err = 1;
            $exifTool->VerboseValue("+ PNG:$$tagInfo{Name}", $val);
            ++$exifTool->{CHANGED};
        }
    }
    $addTags = { };     # prevent from adding tags again
    # create any necessary directories
    foreach $dir (sort keys %{$exifTool->{ADD_DIRS}}) {
        my $buff;
        my %dirInfo = (
            Parent => 'PNG',
            DirName => $dir,
        );
        if ($dir eq 'IFD0') {
            $exifTool->VPrint(0, "Creating EXIF profile:\n");
            $exifTool->{TIFF_TYPE} = 'APP1';
            $tagTablePtr = Image::ExifTool::GetTagTable('Image::ExifTool::Exif::Main');
            $buff = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr, \&Image::ExifTool::WriteTIFF);
            if (defined $buff and length $buff) {
                $buff = $Image::ExifTool::exifAPP1hdr . $buff;
                WriteProfile($outfile, 'APP1', \$buff, 'generic') or $err = 1;
            }
        } elsif ($dir eq 'XMP') {
            $exifTool->VPrint(0, "Creating XMP iTXt chunk:\n");
            $tagTablePtr = Image::ExifTool::GetTagTable('Image::ExifTool::XMP::Main');
            $dirInfo{ReadOnly} = 1;
            $buff = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr);
            if (defined $buff and length $buff and
                # the packet is read-only (because of CRC)
                Image::ExifTool::XMP::ValidateXMP(\$buff, 'r'))
            {
                # (previously, XMP was created as a non-standard XMP profile chunk)
                # $buff = $Image::ExifTool::xmpAPP1hdr . $buff;
                # WriteProfile($outfile, 'APP1', \$buff, 'generic') or $err = 1;
                # (but now write XMP iTXt chunk according to XMP specification)
                $buff = "iTXtXML:com.adobe.xmp\0\0\0\0\0" . $buff;
                my $hdr = pack('N', length($buff) - 4);
                my $cbuf = pack('N', CalculateCRC(\$buff, undef));
                Write($outfile, $hdr, $buff, $cbuf) or $err = 1;
            }
        } elsif ($dir eq 'IPTC') {
            $exifTool->VPrint(0, "Creating IPTC profile:\n");
            # write new IPTC data
            $tagTablePtr = Image::ExifTool::GetTagTable('Image::ExifTool::Photoshop::Main');
            $buff = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr);
            if (defined $buff and length $buff) {
                WriteProfile($outfile, 'iptc', \$buff, 'IPTC') or $err = 1;
            }
        } elsif ($dir eq 'ICC_Profile') {
            $exifTool->VPrint(0, "Creating ICC profile:\n");
            # write new ICC data (only done if we couldn't create iCCP chunk)
            $tagTablePtr = Image::ExifTool::GetTagTable('Image::ExifTool::ICC_Profile::Main');
            $buff = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr);
            if (defined $buff and length $buff) {
                WriteProfile($outfile, 'icm', \$buff, 'ICC') or $err = 1;
                $exifTool->Warn('Wrote ICC as a raw profile (no Compress::Zlib)');
            }
        }
    }
    $exifTool->{ADD_DIRS} = { };    # prevent from adding dirs again
    return not $err;
}


1; # end

__END__

