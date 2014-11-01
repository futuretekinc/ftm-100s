
package Image::ExifTool::Flash;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::FLAC;

$VERSION = '1.09';

sub ProcessMeta($$$;$);

my %processMetaPacket = ( onMetaData => 1, onXMPData => 1 );

%Image::ExifTool::Flash::Main = (
    GROUPS => { 2 => 'Video' },
    VARS => { ALPHA_FIRST => 1 },
    NOTES => q{
        The information below is extracted from SWF (Shockwave Flash) files.  Tags
        with string ID's represent information extracted from the file header.
    },
    FlashVersion => { },
    Compressed   => { PrintConv => { 0 => 'False', 1 => 'True' } },
    ImageWidth   => { },
    ImageHeight  => { },
    FrameRate    => { },
    FrameCount   => { },
    Duration => {
        Notes => 'calculated from FrameRate and FrameCount',
        PrintConv => 'ConvertDuration($val)',
    },
    69 => {
        Name => 'FileAttributes',
        PrintConv => { BITMASK => {
            0 => 'UseNetwork',
            3 => 'ActionScript3',
            4 => 'HasMetadata',
        } },
    },
    77 => {
        Name => 'XMP',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::Main' },
    },
);

%Image::ExifTool::Flash::FLV = (
    NOTES => q{
        Information is extracted from the following packets in FLV (Flash Video)
        files.
    },
    0x08 => {
        Name => 'Audio',
        BitMask => 0x04,
        SubDirectory => { TagTable => 'Image::ExifTool::Flash::Audio' },
    },
    0x09 => {
        Name => 'Video',
        BitMask => 0x01,
        SubDirectory => { TagTable => 'Image::ExifTool::Flash::Video' },
    },
    0x12 => {
        Name => 'Meta',
        SubDirectory => { TagTable => 'Image::ExifTool::Flash::Meta' },
    },
);

%Image::ExifTool::Flash::Audio = (
    PROCESS_PROC => \&Image::ExifTool::FLAC::ProcessBitStream,
    GROUPS => { 2 => 'Audio' },
    NOTES => 'Information extracted from the Flash Audio header.',
    'Bit0-3' => {
        Name => 'AudioEncoding',
        PrintConv => {
            0 => 'PCM-BE (uncompressed)', # PCM-BE according to ref 4
            1 => 'ADPCM',
            2 => 'MP3',
            3 => 'PCM-LE (uncompressed)', #4
            4 => 'Nellymoser 16kHz Mono', #8
            5 => 'Nellymoser 8kHz Mono',
            6 => 'Nellymoser',
            7 => 'G.711 A-law logarithmic PCM', #8
            8 => 'G.711 mu-law logarithmic PCM', #8
            # (9 is reserved, ref 8)
            10 => 'AAC', #8
            11 => 'Speex', #8
            13 => 'MP3 8-Khz', #8
            15 => 'Device-specific sound', #8
        },
    },
    'Bit4-5' => {
        Name => 'AudioSampleRate',
        ValueConv => {
            0 => 5512,
            1 => 11025,
            2 => 22050,
            3 => 44100,
        },
    },
    'Bit6' => {
        Name => 'AudioBitsPerSample',
        ValueConv => '8 * ($val + 1)',
    },
    'Bit7' => {
        Name => 'AudioChannels',
        ValueConv => '$val + 1',
        PrintConv => {
            1 => '1 (mono)',
            2 => '2 (stereo)',
        },
    },
);

%Image::ExifTool::Flash::Video = (
    PROCESS_PROC => \&Image::ExifTool::FLAC::ProcessBitStream,
    GROUPS => { 2 => 'Video' },
    NOTES => 'Information extracted from the Flash Video header.',
    'Bit4-7' => {
        Name => 'VideoEncoding',
        PrintConv => {
            1 => 'JPEG', #8
            2 => 'Sorensen H.263',
            3 => 'Screen Video',
            4 => 'On2 VP6',
            5 => 'On2 VP6 Alpha', #3
            6 => 'Screen Video 2', #3
            7 => 'H.264', #7 (called "AVC" by ref 8)
        },
    },
);

%Image::ExifTool::Flash::Meta = (
    PROCESS_PROC => \&ProcessMeta,
    GROUPS => { 2 => 'Video' },
    NOTES => q{
        Below are a few observed FLV Meta tags, but ExifTool will attempt to extract
        information from any tag found.
    },
    'audiocodecid'  => { Name => 'AudioCodecID',    Groups => { 2 => 'Audio' } },
    'audiodatarate' => {
        Name => 'AudioBitrate',
        Groups => { 2 => 'Audio' },
        ValueConv => '$val * 1000',
        PrintConv => 'ConvertBitrate($val)',
    },
    'audiodelay'    => { Name => 'AudioDelay',      Groups => { 2 => 'Audio' } },
    'audiosamplerate'=>{ Name => 'AudioSampleRate', Groups => { 2 => 'Audio' } },
    'audiosamplesize'=>{ Name => 'AudioSampleSize', Groups => { 2 => 'Audio' } },
    'audiosize'     => { Name => 'AudioSize',       Groups => { 2 => 'Audio' } },
    'bytelength'    => 'ByteLength', # (youtube)
    'canseekontime' => 'CanSeekOnTime', # (youtube)
    'canSeekToEnd'  => 'CanSeekToEnd',
    'creationdate'  => {
        # (not an AMF date type in my sample)
        Name => 'CreateDate',
        Groups => { 2 => 'Time' },
        ValueConv => '$val=~s/\s+$//; $val',    # trim trailing whitespace
    },
    'createdby'     => 'CreatedBy', #7
    'cuePoints'     => {
        Name => 'CuePoint',
        SubDirectory => { TagTable => 'Image::ExifTool::Flash::CuePoint' },
    },
    'datasize'      => 'DataSize',
    'duration' => {
        Name => 'Duration',
        PrintConv => 'ConvertDuration($val)',
    },
    'filesize'      => 'FileSizeBytes',
    'framerate'     => {
        Name => 'FrameRate',
        PrintConv => 'int($val * 1000 + 0.5) / 1000',
    },
    'hasAudio'      => { Name => 'HasAudio',        Groups => { 2 => 'Audio' } },
    'hasCuePoints'  => 'HasCuePoints',
    'hasKeyframes'  => 'HasKeyFrames',
    'hasMetadata'   => 'HasMetadata',
    'hasVideo'      => 'HasVideo',
    'height'        => 'ImageHeight',
    'httphostheader'=> 'HTTPHostHeader', # (youtube)
    'keyframesTimes'=> 'KeyFramesTimes',
    'keyframesFilepositions' => 'KeyFramePositions',
    'lasttimestamp' => 'LastTimeStamp',
    'lastkeyframetimestamp' => 'LastKeyFrameTime',
    'metadatacreator'=>'MetadataCreator',
    'metadatadate'  => {
        Name => 'MetadataDate',
        Groups => { 2 => 'Time' },
        PrintConv => '$self->ConvertDateTime($val)',
    },
    'purl'          => 'URL', # (youtube) (what does P mean?)
    'pmsg'          => 'Message', # (youtube) (what does P mean?)
    'sourcedata'    => 'SourceData', # (youtube)
    'starttime'     => { # (youtube)
        Name => 'StartTime',
        PrintConv => 'ConvertDuration($val)',
    },
    'stereo'        => { Name => 'Stereo',          Groups => { 2 => 'Audio' } },
    'totalduration' => { # (youtube)
        Name => 'TotalDuration',
        PrintConv => 'ConvertDuration($val)',
    },
    'totaldatarate' => { # (youtube)
        Name => 'TotalDataRate',
        ValueConv => '$val * 1000',
        PrintConv => 'int($val + 0.5)',
    },
    'totalduration' => 'TotalDuration',
    'videocodecid'  => 'VideoCodecID',
    'videodatarate' => {
        Name => 'VideoBitrate',
        ValueConv => '$val * 1000',
        PrintConv => 'ConvertBitrate($val)',
    },
    'videosize'     => 'VideoSize',
    'width'         => 'ImageWidth',
    # tags in 'onXMPData' packets
    'liveXML'       => { #5
        Name => 'XMP',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::Main' },
    },
);

%Image::ExifTool::Flash::CuePoint = (
    PROCESS_PROC => \&ProcessMeta,
    GROUPS => { 2 => 'Video' },
    NOTES => q{
        These tag names are added to the CuePoint name to generate complete tag
        names like "CuePoint0Name".
    },
    'name' => 'Name',
    'type' => 'Type',
    'time' => 'Time',
    'parameters' => {
        Name => 'Parameter',
        SubDirectory => { TagTable => 'Image::ExifTool::Flash::Parameter' },
    },
);

%Image::ExifTool::Flash::Parameter = (
    PROCESS_PROC => \&ProcessMeta,
    GROUPS => { 2 => 'Video' },
    NOTES => q{
        There are no pre-defined parameter tags, but ExifTool will extract any
        existing parameters, with tag names like "CuePoint0ParameterXxx".
    },
);

my @amfType = qw(double boolean string object movieClip null undefined reference
                 mixedArray objectEnd array date longString unsupported recordSet
                 XML typedObject AMF3data);

my %isStruct = ( 0x03 => 1, 0x08 => 1, 0x10 => 1 );

sub ProcessMeta($$$;$)
{
    my ($exifTool, $dirInfo, $tagTablePtr, $single) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my $dataPos = $$dirInfo{DataPos};
    my $dirLen = $$dirInfo{DirLen} || length($$dataPt);
    my $pos = $$dirInfo{Pos} || 0;
    my ($type, $val, $rec);

    $exifTool->VerboseDir('Meta') unless $single;

Record: for ($rec=0; ; ++$rec) {
        last if $pos >= $dirLen;
        $type = ord(substr($$dataPt, $pos));
        ++$pos;
        if ($type == 0x00 or $type == 0x0b) {   # double or date
            last if $pos + 8 > $dirLen;
            $val = GetDouble($dataPt, $pos);
            $pos += 8;
            if ($type == 0x0b) {    # date
                $val /= 1000;       # convert to seconds
                my $frac = $val - int($val);    # fractional seconds
                # get time zone
                last if $pos + 2 > $dirLen;
                my $tz = Get16s($dataPt, $pos);
                $pos += 2;
                # construct date/time string
                $val = Image::ExifTool::ConvertUnixTime(int($val));
                if ($frac) {
                    $frac = sprintf('%.6f', $frac);
                    $frac =~ s/(^0|0+$)//g;
                    $val .= $frac;
                }
                # add timezone
                if ($tz < 0) {
                    $val .= '-';
                    $tz *= -1;
                } else {
                    $val .= '+';
                }
                $val .= sprintf('%.2d:%.2d', int($tz/60), $tz%60);
            }
        } elsif ($type == 0x01) {   # boolean
            last if $pos + 1 > $dirLen;
            $val = Get8u($dataPt, $pos);
            $val = { 0 => 'No', 1 => 'Yes' }->{$val} if $val < 2;
            ++$pos;
        } elsif ($type == 0x02) {   # string
            last if $pos + 2 > $dirLen;
            my $len = Get16u($dataPt, $pos);
            last if $pos + 2 + $len > $dirLen;
            $val = substr($$dataPt, $pos + 2, $len);
            $pos += 2 + $len;
        } elsif ($isStruct{$type}) {   # object, mixed array or typed object
            $exifTool->VPrint(1, "  + [$amfType[$type]]\n");
            my $getName;
            $val = '';  # dummy value
            if ($type == 0x08) {        # mixed array
                # skip last array index for mixed array
                last if $pos + 4 > $dirLen;
                $pos += 4;
            } elsif ($type == 0x10) {   # typed object
                $getName = 1;
            }
            for (;;) {
                # get tag ID (or typed object name)
                last Record if $pos + 2 > $dirLen;
                my $len = Get16u($dataPt, $pos);
                if ($pos + 2 + $len > $dirLen) {
                    $exifTool->Warn("Truncated $amfType[$type] record");
                    last Record;
                }
                my $tag = substr($$dataPt, $pos + 2, $len);
                $pos += 2 + $len;
                # first string of a typed object is the object name
                if ($getName) {
                    $exifTool->VPrint(1,"  | (object name '$tag')\n");
                    undef $getName;
                    next; # (ignore name for now)
                }
                my $subTablePtr = $tagTablePtr;
                my $tagInfo = $$subTablePtr{$tag};
                # switch to subdirectory table if necessary
                if ($tagInfo and $$tagInfo{SubDirectory}) {
                    my $subTable = $tagInfo->{SubDirectory}->{TagTable};
                    # descend into Flash SubDirectory
                    if ($subTable =~ /^Image::ExifTool::Flash::/) {
                        $tag = $$tagInfo{Name}; # use our name for the tag
                        $subTablePtr = GetTagTable($subTable);
                    }
                }
                # get object value
                my $valPos = $pos + 1;
                $$dirInfo{Pos} = $pos;
                my $structName = $$dirInfo{StructName};
                # add structure name to start of tag name
                $tag = $structName . ucfirst($tag) if defined $structName;
                $$dirInfo{StructName} = $tag;       # set new structure name
                my ($t, $v) = ProcessMeta($exifTool, $dirInfo, $subTablePtr, 1);
                $$dirInfo{StructName} = $structName;# restore original structure name
                $pos = $$dirInfo{Pos};  # update to new position in packet
                # all done if this value contained tags
                last Record unless defined $t and defined $v;
                next if $isStruct{$t};  # already handled tags in sub-structures
                next if ref($v) eq 'ARRAY' and not @$v; # ignore empty arrays
                last if $t == 0x09; # (end of object)
                if (not $$subTablePtr{$tag} and $tag =~ /^\w+$/) {
                    Image::ExifTool::AddTagToTable($subTablePtr, $tag, { Name => ucfirst($tag) });
                    $exifTool->VPrint(1, "  | (adding $tag)\n");
                }
                $exifTool->HandleTag($subTablePtr, $tag, $v,
                    DataPt  => $dataPt,
                    DataPos => $dataPos,
                    Start   => $valPos,
                    Size    => $pos - $valPos,
                    Format  => $amfType[$t] || sprintf('0x%x',$t),
                );
            }
      # } elsif ($type == 0x04) {   # movie clip (not supported)
        } elsif ($type == 0x05 or $type == 0x06 or $type == 0x09 or $type == 0x0d) {
            # null, undefined, dirLen of object, or unsupported
            $val = '';
        } elsif ($type == 0x07) {   # reference
            last if $pos + 2 > $dirLen;
            $val = Get16u($dataPt, $pos);
            $pos += 2;
        } elsif ($type == 0x0a) {   # array
            last if $pos + 4 > $dirLen;
            my $num = Get32u($dataPt, $pos);
            $$dirInfo{Pos} = $pos + 4;
            my ($i, @vals);
            # add array index to compount tag name
            my $structName = $$dirInfo{StructName};
            for ($i=0; $i<$num; ++$i) {
                $$dirInfo{StructName} = $structName . $i if defined $structName;
                my ($t, $v) = ProcessMeta($exifTool, $dirInfo, $tagTablePtr, 1);
                last Record unless defined $v;
                # save value unless contained in a sub-structure
                push @vals, $v unless $isStruct{$t};
            }
            $$dirInfo{StructName} = $structName;
            $pos = $$dirInfo{Pos};
            $val = \@vals;
        } elsif ($type == 0x0c or $type == 0x0f) {  # long string or XML
            last if $pos + 4 > $dirLen;
            my $len = Get32u($dataPt, $pos);
            last if $pos + 4 + $len > $dirLen;
            $val = substr($$dataPt, $pos + 4, $len);
            $pos += 4 + $len;
      # } elsif ($type == 0x0e) {   # record set (not supported)
      # } elsif ($type == 0x11) {   # AMF3 data (can't add support for this without a test sample)
        } else {
            my $t = $amfType[$type] || sprintf('type 0x%x',$type);
            $exifTool->Warn("AMF $t record not yet supported");
            undef $type;    # (so we don't print another warning)
            last;           # can't continue
        }
        last if $single;        # all done if extracting single value
        unless ($isStruct{$type}) {
            # only process certain Meta packets
            if ($type == 0x02 and not $rec) {
                my $verb = $processMetaPacket{$val} ? 'processing' : 'ignoring';
                $exifTool->VPrint(0, "  | ($verb $val information)\n");
                last unless $processMetaPacket{$val};
            } else {
                # give verbose indication if we ignore a lone value
                my $t = $amfType[$type] || sprintf('type 0x%x',$type);
                $exifTool->VPrint(1, "  | (ignored lone $t value '$val')\n");
            }
        }
    }
    if (not defined $val and defined $type) {
        $exifTool->Warn(sprintf("Truncated AMF record 0x%x",$type));
    }
    return 1 unless $single;    # all done
    $$dirInfo{Pos} = $pos;      # update position
    return($type,$val);         # return single type/value pair
}

sub ProcessFLV($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $verbose = $exifTool->Options('Verbose');
    my $raf = $$dirInfo{RAF};
    my $buff;

    $raf->Read($buff, 9) == 9 or return 0;
    $buff =~ /^FLV\x01/ or return 0;
    SetByteOrder('MM');
    $exifTool->SetFileType();
    my ($flags, $offset) = unpack('x4CN', $buff);
    $raf->Seek($offset-9, 1) or return 1 if $offset > 9;
    $flags &= 0x05; # only look for audio/video
    my $found = 0;
    my $tagTablePtr = GetTagTable('Image::ExifTool::Flash::FLV');
    for (;;) {
        $raf->Read($buff, 15) == 15 or last;
        my $len = unpack('x4N', $buff);
        my $type = $len >> 24;
        $len &= 0x00ffffff;
        my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $type);
        if ($verbose > 1) {
            my $name = $tagInfo ? $$tagInfo{Name} : "type $type";
            $exifTool->VPrint(1, "FLV $name packet, len $len\n");
        }
        undef $buff;
        if ($tagInfo and $$tagInfo{SubDirectory}) {
            my $mask = $$tagInfo{BitMask};
            if ($mask) {
                # handle audio or video packet
                unless ($found & $mask) {
                    $found |= $mask;
                    $flags &= ~$mask;
                    if ($len>=1 and $raf->Read($buff, 1) == 1) {
                        $len -= 1;
                    } else {
                        $exifTool->Warn("Bad $$tagInfo{Name} packet");
                        last;
                    }
                }
            } elsif ($raf->Read($buff, $len) == $len) {
                $len = 0;
            } else {
                $exifTool->Warn('Truncated Meta packet');
                last;
            }
        }
        if (defined $buff) {
            $exifTool->HandleTag($tagTablePtr, $type, undef,
                DataPt  => \$buff,
                DataPos => $raf->Tell() - length($buff),
            );
        }
        last unless $flags;
        $raf->Seek($len, 1) or last if $len;
    }
    return 1;
}

sub FoundFlashTag($$$)
{
    my ($exifTool, $tag, $val) = @_;
    $exifTool->HandleTag(\%Image::ExifTool::Flash::Main, $tag, $val);
}

sub ReadCompressed($$$$)
{
    my ($raf, $len, $inflate) = ($_[0], $_[2], $_[3]);
    my $buff;
    unless ($raf->Read($buff, $len)) {
        $_[3] = 'Error reading file';
        return 0;
    }
    # uncompress if necessary
    if ($inflate) {
        unless (ref $inflate) {
            unless (eval 'require Compress::Zlib') {
                $_[3] = 'Install Compress::Zlib to extract compressed information';
                return 0;
            }
            $inflate = Compress::Zlib::inflateInit();
            unless ($inflate) {
                $_[3] = 'Error initializing inflate for Flash data';
                return 0;
            }
            $_[3] = $inflate;   # pass inflate object back to caller
        }
        my $tmp = $buff;
        $buff = '';
        # read 64 more bytes at a time and inflate until we get enough uncompressed data
        for (;;) {
            my ($dat, $stat) = $inflate->inflate($tmp);
            if ($stat == Compress::Zlib::Z_STREAM_END() or
                $stat == Compress::Zlib::Z_OK())
            {
                $buff .= $dat;  # add inflated data to buffer
                last if length $buff >= $len or $stat == Compress::Zlib::Z_STREAM_END();
                $raf->Read($tmp,64) or last;    # must read a bit more data
            } else {
                $buff = '';
                last;
            }
        }
        $_[3] = 'Error inflating compressed Flash data' unless length $buff;
    }
    $_[1] = defined $_[1] ? $_[1] . $buff : $buff;
    return length $buff;
}

sub ProcessSWF($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my ($buff, $hasMeta);

    $raf->Read($buff, 8) == 8 or return 0;
    $buff =~ /^(F|C)WS([^\0])/ or return 0;
    my ($compressed, $vers) = ($1 eq 'C' ? 1 : 0, ord($2));

    SetByteOrder('II');
    $exifTool->SetFileType();
    GetTagTable('Image::ExifTool::Flash::Main');  # make sure table is initialized

    FoundFlashTag($exifTool, FlashVersion => $vers);
    FoundFlashTag($exifTool, Compressed => $compressed);

    # read the next 64 bytes of the file (and inflate if necessary)
    $buff = '';
    unless (ReadCompressed($raf, $buff, 64, $compressed)) {
        $exifTool->Warn($compressed) if $compressed;
        return 1;
    }

    # unpack elements of bit-packed Flash Rect structure
    my $nBits = unpack('C', $buff) >> 3;    # bits in x1,x2,y1,y2 elements
    my $totBits = 5 + $nBits * 4;           # total bits in Rect structure
    my $nBytes = int(($totBits + 7) / 8);   # byte length of Rect structure
    if (length $buff < $nBytes + 4) {
        $exifTool->Warn('Truncated Flash file');
        return 1;
    }
    my $bits = unpack("B$totBits", $buff);
    # isolate Rect elements and convert from ASCII bit strings to integers
    my @vals = unpack('x5' . "a$nBits" x 4, $bits);
    # (do conversion the hard way because oct("0b$val") requires Perl 5.6)
    map { $_ = unpack('N', pack('B32', '0' x (32 - length $_) . $_)) } @vals;

    # calculate and store ImageWidth/Height
    FoundFlashTag($exifTool, ImageWidth  => ($vals[1] - $vals[0]) / 20);
    FoundFlashTag($exifTool, ImageHeight => ($vals[3] - $vals[2]) / 20);

    # get frame rate and count
    @vals = unpack("x${nBytes}v2", $buff);
    FoundFlashTag($exifTool, FrameRate => $vals[0] / 256);
    FoundFlashTag($exifTool, FrameCount => $vals[1]);
    FoundFlashTag($exifTool, Duration => $vals[1] * 256 / $vals[0]) if $vals[0];

    # scan through the tags to find FileAttributes and XMP
    $buff = substr($buff, $nBytes + 4);
    for (;;) {
        my $buffLen = length $buff;
        last if $buffLen < 2;
        my $code = Get16u(\$buff, 0);
        my $pos = 2;
        my $tag = $code >> 6;
        my $size = $code & 0x3f;
        $exifTool->VPrint(1, "SWF tag $tag ($size bytes):\n");
        last unless $tag == 69 or $tag == 77 or $hasMeta;
        # read enough to get a complete short record
        if ($pos + $size > $buffLen) {
            # (read 2 extra bytes if available to get next tag word)
            unless (ReadCompressed($raf, $buff, $size + 2, $compressed)) {
                $exifTool->Warn($compressed) if $compressed;
                return 1;
            }
            $buffLen = length $buff;
            last if $pos + $size > $buffLen;
        }
        # read extended record if necessary
        if ($size == 0x3f) {
            last if $pos + 4 > $buffLen;
            $size = Get32u(\$buff, $pos);
            $pos += 4;
            last if $size > 1000000; # don't read anything huge
            if ($pos + $size > $buffLen) {
                unless (ReadCompressed($raf, $buff, $size + 2, $compressed)) {
                    $exifTool->Warn($compressed) if $compressed;
                    return 1;
                }
                $buffLen = length $buff;
                last if $pos + $size > $buffLen;
            }
            $exifTool->VPrint(1, "  [extended size $size bytes]\n");
        }
        if ($tag == 69) {       # FileAttributes
            last unless $size;
            my $flags = Get8u(\$buff, $pos);
            FoundFlashTag($exifTool, $tag => $flags);
            last unless $flags & 0x10;  # only continue if we have metadata (XMP)
            $hasMeta = 1;
        } elsif ($tag == 77) {  # Metadata
            my $val = substr($buff, $pos, $size);
            FoundFlashTag($exifTool, $tag => $val);
            last;
        }
        last if $pos + 2 > $buffLen;
        $buff = substr($buff, $pos);    # remove everything before the next tag
    }
    return 1;
}

1;  # end

__END__


