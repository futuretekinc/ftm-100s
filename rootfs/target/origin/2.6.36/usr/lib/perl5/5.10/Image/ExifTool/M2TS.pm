
package Image::ExifTool::M2TS;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.09';

my %streamType = (
    0x00 => 'Reserved',
    0x01 => 'MPEG-1 Video',
    0x02 => 'MPEG-2 Video',
    0x03 => 'MPEG-1 Audio',
    0x04 => 'MPEG-2 Audio',
    0x05 => 'ISO 13818-1 private sections',
    0x06 => 'ISO 13818-1 PES private data',
    0x07 => 'ISO 13522 MHEG',
    0x08 => 'ISO 13818-1 DSM-CC',
    0x09 => 'ISO 13818-1 auxiliary',
    0x0A => 'ISO 13818-6 multi-protocol encap',
    0x0B => 'ISO 13818-6 DSM-CC U-N msgs',
    0x0C => 'ISO 13818-6 stream descriptors',
    0x0D => 'ISO 13818-6 sections',
    0x0E => 'ISO 13818-1 auxiliary',
    0x0F => 'MPEG-2 AAC Audio',
    0x10 => 'MPEG-4 Video',
    0x11 => 'MPEG-4 LATM AAC Audio',
    0x12 => 'MPEG-4 generic',
    0x13 => 'ISO 14496-1 SL-packetized',
    0x14 => 'ISO 13818-6 Synchronized Download Protocol',
  # 0x15-0x7F => 'ISO 13818-1 Reserved',
    0x1b => 'H.264 Video',
    0x80 => 'DigiCipher II Video',
    0x81 => 'A52/AC-3 Audio',
    0x82 => 'HDMV DTS Audio',
    0x83 => 'LPCM Audio',
    0x84 => 'SDDS Audio',
    0x85 => 'ATSC Program ID',
    0x86 => 'DTS-HD Audio',
    0x87 => 'E-AC-3 Audio',
    0x8a => 'DTS Audio',
    0x91 => 'A52b/AC-3 Audio',
    0x92 => 'DVD_SPU vls Subtitle',
    0x94 => 'SDDS Audio',
    0xa0 => 'MSCODEC Video',
    0xea => 'Private ES (VC-1)',
  # 0x80-0xFF => 'User Private',
);

my %tableID = (
    0x00 => 'Program Association',
    0x01 => 'Conditional Access',
    0x02 => 'Program Map',
    0x03 => 'Transport Stream Description',
    0x40 => 'Actual Network Information',
    0x41 => 'Other Network Information',
    0x42 => 'Actual Service Description',
    0x46 => 'Other Service Description',
    0x4a => 'Bouquet Association',
    0x4e => 'Actual Event Information - Present/Following',
    0x4f => 'Other Event Information - Present/Following',
    0x50 => 'Actual Event Information - Schedule', #(also 0x51-0x5f)
    0x60 => 'Other Event Information - Schedule', # (also 0x61-0x6f)
    0x70 => 'Time/Date',
    0x71 => 'Running Status',
    0x72 => 'Stuffing',
    0x73 => 'Time Offset',
    0x7e => 'Discontinuity Information',
    0x7f => 'Selection Information',
  # 0x80-0xfe => 'User Defined',
);

my %noSyntax = (
    0xbc => 1, # program_stream_map
    0xbe => 1, # padding_stream
    0xbf => 1, # private_stream_2
    0xf0 => 1, # ECM_stream
    0xf1 => 1, # EMM_stream
    0xf2 => 1, # DSMCC_stream
    0xf8 => 1, # ITU-T Rec. H.222.1 type E stream
    0xff => 1, # program_stream_directory
);

%Image::ExifTool::M2TS::Main = (
    GROUPS => { 2 => 'Video' },
    VARS => { NO_ID => 1 },
    NOTES => q{
        The MPEG-2 transport stream is used as a container for many different
        audio/video formats (including AVCHD).  This table lists information
        extracted from M2TS files.
    },
    VideoStreamType => {
        PrintHex => 1,
        PrintConv => \%streamType,
        SeparateTable => 'StreamType',
    },
    AudioStreamType => {
        PrintHex => 1,
        PrintConv => \%streamType,
        SeparateTable => 'StreamType',
    },
    Duration => {
        Notes => q{
            the -fast option may be used to avoid scanning to the end of file to
            calculate the Duration
        },
        ValueConv => '$val / 27000000', # (clock is 27MHz)
        PrintConv => 'ConvertDuration($val)',
    },
    # the following tags are for documentation purposes only
    _AC3  => { SubDirectory => { TagTable => 'Image::ExifTool::M2TS::AC3' } },
    _H264 => { SubDirectory => { TagTable => 'Image::ExifTool::H264::Main' } },
);

%Image::ExifTool::M2TS::AC3 = (
    GROUPS => { 1 => 'AC3', 2 => 'Audio' },
    VARS => { NO_ID => 1 },
    NOTES => 'Tags extracted from AC-3 audio streams.',
    AudioSampleRate => {
        PrintConv => {
            0 => '48000',
            1 => '44100',
            2 => '32000',
        },
    },
    AudioBitrate => {
        PrintConvColumns => 2,
        ValueConv => {
            0 => 32000,
            1 => 40000,
            2 => 48000,
            3 => 56000,
            4 => 64000,
            5 => 80000,
            6 => 96000,
            7 => 112000,
            8 => 128000,
            9 => 160000,
            10 => 192000,
            11 => 224000,
            12 => 256000,
            13 => 320000,
            14 => 384000,
            15 => 448000,
            16 => 512000,
            17 => 576000,
            18 => 640000,
            32 => '32000 max',
            33 => '40000 max',
            34 => '48000 max',
            35 => '56000 max',
            36 => '64000 max',
            37 => '80000 max',
            38 => '96000 max',
            39 => '112000 max',
            40 => '128000 max',
            41 => '160000 max',
            42 => '192000 max',
            43 => '224000 max',
            44 => '256000 max',
            45 => '320000 max',
            46 => '384000 max',
            47 => '448000 max',
            48 => '512000 max',
            49 => '576000 max',
            50 => '640000 max',
        },
        PrintConv => 'ConvertBitrate($val)',
    },
    SurroundMode => {
        PrintConv => {
            0 => 'Not indicated',
            1 => 'Not Dolby surround',
            2 => 'Dolby surround',
        },
    },
    AudioChannels => {
        PrintConvColumns => 2,
        PrintConv => {
            0 => '1 + 1',
            1 => 1,
            2 => 2,
            3 => 3,
            4 => '2/1',
            5 => '3/1',
            6 => '2/2',
            7 => '3/2',
            8 => 1,
            9 => '2 max',
            10 => '3 max',
            11 => '4 max',
            12 => '5 max',
            13 => '6 max',
        },
    },
);

sub ParseAC3Audio($$)
{
    my ($exifTool, $dataPt) = @_;
    if ($$dataPt =~ /\x0b\x77..(.)/sg) {
        my $sampleRate = ord($1) >> 6;
        my $tagTablePtr = GetTagTable('Image::ExifTool::M2TS::AC3');
        $exifTool->HandleTag($tagTablePtr, AudioSampleRate => $sampleRate);
    }
}

sub ParseAC3Descriptor($$)
{
    my ($exifTool, $dataPt) = @_;
    return if length $$dataPt < 3;
    my @v = unpack('C3', $$dataPt);
    my $tagTablePtr = GetTagTable('Image::ExifTool::M2TS::AC3');
    # $exifTool->HandleTag($tagTablePtr, 'AudioSampleRate', $v[0] >> 5);
    $exifTool->HandleTag($tagTablePtr, 'AudioBitrate', $v[1] >> 2);
    $exifTool->HandleTag($tagTablePtr, 'SurroundMode', $v[1] & 0x03);
    $exifTool->HandleTag($tagTablePtr, 'AudioChannels', ($v[2] >> 1) & 0x0f);
    # don't (yet) decode any more (language codes, etc)
}

sub ParsePID($$$$$)
{
    my ($exifTool, $pid, $type, $pidName, $dataPt) = @_;
    # can't parse until we know the type (Program Map Table may be later in the stream)
    return -1 unless defined $type;   
    my $verbose = $exifTool->Options('Verbose');
    if ($verbose > 1) {
        my $out = $exifTool->Options('TextOut');
        printf $out "Parsing stream 0x%.4x (%s)\n", $pid, $pidName;
        my %parms = ( Out => $out );
        $parms{MaxLen} = 96 if $verbose < 4;
        Image::ExifTool::HexDump($dataPt, undef, %parms) if $verbose > 2;
    }
    my $more = 0;
    if ($type == 0x01 or $type == 0x02) {
        # MPEG-1/MPEG-2 Video
        require Image::ExifTool::MPEG;
        Image::ExifTool::MPEG::ParseMPEGAudioVideo($exifTool, $dataPt);
    } elsif ($type == 0x03 or $type == 0x04) {
        # MPEG-1/MPEG-2 Audio
        require Image::ExifTool::MPEG;
        Image::ExifTool::MPEG::ParseMPEGAudio($exifTool, $dataPt);
    } elsif ($type == 0x1b) {
        # H.264 Video
        require Image::ExifTool::H264;
        $more = Image::ExifTool::H264::ParseH264Video($exifTool, $dataPt);
        # force parsing additional H264 frames with ExtractEmbedded option
        $more = 1 if $exifTool->Options('ExtractEmbedded');
    } elsif ($type == 0x81 or $type == 0x87 or $type == 0x91) {
        # AC-3 audio
        ParseAC3Audio($exifTool, $dataPt);
    }
    return $more;
}

sub ProcessM2TS($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my ($buff, $pLen, $upkPrefix, $j, $fileType, $eof);
    my (%pmt, %pidType, %data, %sectLen);
    my ($startTime, $endTime, $backScan, $maxBack);
    my $verbose = $exifTool->Options('Verbose');
    my $out = $exifTool->Options('TextOut');

    # read first packet
    return 0 unless $raf->Read($buff, 8) == 8;
    # test for magic number (sync byte is the only thing we can safely check)
    return 0 unless $buff =~ /^(....)?\x47/s;
    unless ($1) {
        $pLen = 188;        # no timecode
        $fileType = 'M2T';  # (just as a way to tell there is no timecode)
        $upkPrefix = 'N';
    } else {
        $pLen = 192; # 188-byte transport packet + leading 4-byte timecode (ref 4)
        $upkPrefix = 'x4N';
    }
    $exifTool->SetFileType($fileType);
    SetByteOrder('MM');
    $raf->Seek(0,0);        # rewind to start
    my $tagTablePtr = GetTagTable('Image::ExifTool::M2TS::Main');

    # PID lookup strings (will add to this with entries from program map table)
    my %pidName = (
        0 => 'Program Association Table',
        1 => 'Conditional Access Table',
        2 => 'Transport Stream Description Table',
        0x1fff => 'Null Packet',
    );
    my %didPID = ( 1 => 0, 2 => 0, 0x1fff => 0 );
    my %needPID = ( 0 => 1 );       # lookup for stream PID's that we still need to parse
    my $prePos = $pLen - 188;       # byte position of packet prefix
    my $readSize = 64 * $pLen;      # read 64 packets at once
    my $pEnd = 0;
    my $i = 0;
    $buff = '';

    # parse packets from MPEG-2 Transport Stream
    for (;;) {

        unless (%needPID) {
            last unless defined $startTime;
            # seek backwards to find last PCR
            if (defined $backScan) {
                last if defined $endTime;
                $backScan -= $pLen;
                last if $backScan < $maxBack;
            } else {
                undef $endTime;
                last if $exifTool->Options('FastScan');
                $verbose and print "[Starting backscan for last PCR]\n";
                # calculate position of last complete packet
                my $fwdPos = $raf->Tell();
                $raf->Seek(0, 2) or last;
                my $fsize = $raf->Tell();
                my $nPack = int($fsize / $pLen);
                $backScan = ($nPack - 1) * $pLen - $fsize;
                # set limit on how far back we will go
                $maxBack = $fwdPos - $fsize;
                $maxBack = -256000 if $maxBack < -256000;
            }
            $raf->Seek($backScan, 2) or last;
        }
        my $pos = $pEnd;
        # read more if necessary
        if ($pos + $pLen > length $buff) {
            $raf->Read($buff, $readSize) >= $pLen or $eof = 1, last;
            $pos = $pEnd = 0;
        }
        $pEnd += $pLen;
        # decode the packet prefix
        $pos += $prePos;
        my $prefix = unpack("x${pos}N", $buff); # (use unpack instead of Get32u for speed)
        # validate sync byte
        unless (($prefix & 0xff000000) == 0x47000000) {
            $exifTool->Warn('Synchronization error') unless defined $backScan;
            last;
        }
      # my $transport_error_indicator    = $prefix & 0x00800000;
        my $payload_unit_start_indicator = $prefix & 0x00400000;
      # my $transport_priority           = $prefix & 0x00200000;
        my $pid                          =($prefix & 0x001fff00) >> 8; # packet ID
      # my $transport_scrambling_control = $prefix & 0x000000c0;
        my $adaptation_field_exists      = $prefix & 0x00000020;
        my $payload_data_exists          = $prefix & 0x00000010;
      # my $continuity_counter           = $prefix & 0x0000000f;

        if ($verbose > 1) {
            print  $out "Transport packet $i:\n";
            ++$i;
            Image::ExifTool::HexDump(\$buff, $pLen, Addr => $i * $pLen, Out => $out,
                Start => $pos - $prePos) if $verbose > 2;
            my $str = $pidName{$pid} ? " ($pidName{$pid})" : '';
            printf $out "  Timecode:   0x%.4x\n", Get32u(\$buff, 0) if $pLen == 192;
            printf $out "  Packet ID:  0x%.4x$str\n", $pid;
            printf $out "  Start Flag: %s\n", $payload_unit_start_indicator ? 'Yes' : 'No';
        }

        $pos += 4;
        # handle adaptation field
        if ($adaptation_field_exists) {
            my $len = Get8u(\$buff, $pos++);
            $pos + $len > $pEnd and $exifTool->Warn('Invalid adaptation field length'), last;
            # read PCR value for calculation of Duration
            if ($len > 6) {
                my $flags = Get8u(\$buff, $pos);
                if ($flags & 0x10) { # PCR_flag
                    # combine 33-bit program_clock_reference_base and 9-bit extension
                    my $pcrBase = Get32u(\$buff, $pos + 1);
                    my $pcrExt  = Get16u(\$buff, $pos + 5);
                    # ignore separate programs (PID's) and store just the
                    # first and last timestamps found in the file (is this OK?)
                    $endTime = 300 * (2 * $pcrBase + ($pcrExt >> 15)) + ($pcrExt & 0x01ff);
                    $startTime = $endTime unless defined $startTime;
                }
            }
            $pos += $len;
        }

        # all done with this packet unless it carries a payload
        # or if we are just looking for the last timestamp
        next unless $payload_data_exists and not defined $backScan;

        # decode payload data
        if ($pid == 0 or            # program association table
            defined $pmt{$pid})     # program map table(s)
        {
            # must interpret pointer field if payload_unit_start_indicator is set
            my $buf2;
            if ($payload_unit_start_indicator) {
                # skip to start of section
                my $pointer_field = Get8u(\$buff, $pos);
                $pos += 1 + $pointer_field;
                $pos >= $pEnd and $exifTool->Warn('Bad pointer field'), last;
                $buf2 = substr($buff, $pEnd-$pLen, $pLen);
                $pos -= $pEnd - $pLen;
            } else {
                # not the start of a section
                next unless $sectLen{$pid};
                my $more = $sectLen{$pid} - length($data{$pid});
                my $size = $pLen - $pos;
                $size = $more if $size > $more;
                $data{$pid} .= substr($buff, $pos, $size);
                next unless $size == $more;
                # we have the complete section now, so put into $buf2 for parsing
                $buf2 = $data{$pid};
                $pos = 0;
                delete $data{$pid};
                delete $sectLen{$pid};
            }
            my $slen = length($buf2);   # section length
            $pos + 8 > $slen and $exifTool->Warn("Truncated payload"), last;
            # validate table ID
            my $table_id = Get8u(\$buf2, $pos);
            my $name = ($tableID{$table_id} || sprintf('Unknown (0x%x)',$table_id)) . ' Table';
            my $expectedID = $pid ? 0x02 : 0x00;
            unless ($table_id == $expectedID) {
                $verbose > 1 and printf $out "  (skipping $name)\n";
                delete $needPID{$pid};
                $didPID{$pid} = 1;
                next;
            }
            # validate section syntax indicator for parsed tables (PAT, PMT)
            my $section_syntax_indicator = Get8u(\$buf2, $pos + 1) & 0xc0;
            $section_syntax_indicator == 0x80 or $exifTool->Warn("Bad $name"), last;
            my $section_length = Get16u(\$buf2, $pos + 1) & 0x0fff;
            $section_length > 1021 and $exifTool->Warn("Invalid $name length"), last;
            if ($slen < $section_length + 3) { # (3 bytes for table_id + section_length)
                # must wait until we have the full section
                $data{$pid} = substr($buf2, $pos);
                $sectLen{$pid} = $section_length + 3;
                next;
            }
            my $program_number = Get16u(\$buf2, $pos + 3);
            my $section_number = Get8u(\$buf2, $pos + 6);
            my $last_section_number = Get8u(\$buf2, $pos + 7);
            if ($verbose > 1) {
                print  $out "  $name length: $section_length\n";
                print  $out "  Program No: $program_number\n" if $pid;
                printf $out "  Stream ID:  0x%x\n", $program_number if not $pid;
                print  $out "  Section No: $section_number\n";
                print  $out "  Last Sect.: $last_section_number\n";
            }
            my $end = $pos + $section_length + 3 - 4; # (don't read 4-byte CRC)
            $pos += 8;
            if ($pid == 0) {
                # decode PAT (Program Association Table)
                while ($pos <= $end - 4) {
                    my $program_number = Get16u(\$buf2, $pos);
                    my $program_map_PID = Get16u(\$buf2, $pos + 2) & 0x1fff;
                    $pmt{$program_map_PID} = $program_number; # save our PMT PID's
                    if (not $pidName{$program_map_PID} or $verbose > 1) {
                        my $str = "Program $program_number Map";
                        $pidName{$program_map_PID} = $str;
                        $needPID{$program_map_PID} = 1 unless $didPID{$program_map_PID};
                        $verbose and printf $out "  PID(0x%.4x) --> $str\n", $program_map_PID;
                    }
                    $pos += 4;
                }
            } else {
                # decode PMT (Program Map Table)
                $pos + 4 > $slen and $exifTool->Warn('Truncated PMT'), last;
                my $pcr_pid = Get16u(\$buf2, $pos) & 0x1fff;
                my $program_info_length = Get16u(\$buf2, $pos + 2) & 0x0fff;
                if (not $pidName{$pcr_pid} or $verbose > 1) {
                    my $str = "Program $program_number Clock Reference";
                    $pidName{$pcr_pid} = $str;
                    $verbose and printf $out "  PID(0x%.4x) --> $str\n", $pcr_pid;
                }
                $pos += 4;
                $pos + $program_info_length > $slen and $exifTool->Warn('Truncated program info'), last;
                # dump program information descriptors if verbose
                if ($verbose > 1) { for ($j=0; $j<$program_info_length-2; ) {
                    my $descriptor_tag = Get8u(\$buf2, $pos + $j);
                    my $descriptor_length = Get8u(\$buf2, $pos + $j + 1);
                    $j += 2;
                    last if $j + $descriptor_length > $program_info_length;
                    my $desc = substr($buf2, $pos+$j, $descriptor_length);
                    $j += $descriptor_length;
                    $desc =~ s/([\x00-\x1f\x80-\xff])/sprintf("\\x%.2x",ord $1)/eg;
                    printf $out "    Program Descriptor: Type=0x%.2x \"$desc\"\n", $descriptor_tag;
                }}
                $pos += $program_info_length; # skip descriptors (for now)
                while ($pos <= $end - 5) {
                    my $stream_type = Get8u(\$buf2, $pos);
                    my $elementary_pid = Get16u(\$buf2, $pos + 1) & 0x1fff;
                    my $es_info_length = Get16u(\$buf2, $pos + 3) & 0x0fff;
                    if (not $pidName{$elementary_pid} or $verbose > 1) {
                        my $str = $streamType{$stream_type};
                        $str or $str = ($stream_type < 0x7f ? 'Reserved' : 'Private');
                        $str = sprintf('%s (0x%.2x)', $str, $stream_type);
                        $str = "Program $program_number $str";
                        # save PID type and name string
                        $pidName{$elementary_pid} = $str;
                        $pidType{$elementary_pid} = $stream_type;
                        $verbose and printf $out "  PID(0x%.4x) --> $str\n", $elementary_pid;
                        if ($str =~ /(Audio|Video)/) {
                            $exifTool->HandleTag($tagTablePtr, $1 . 'StreamType', $stream_type);
                            # we want to parse all Audio and Video streams
                            $needPID{$elementary_pid} = 1 unless $didPID{$elementary_pid};
                        }
                    }
                    $pos += 5;
                    $pos + $es_info_length > $slen and $exifTool->Warn('Trunacted ES info'), $pos = $end, last;
                    # parse elementary stream descriptors
                    for ($j=0; $j<$es_info_length-2; ) {
                        my $descriptor_tag = Get8u(\$buf2, $pos + $j);
                        my $descriptor_length = Get8u(\$buf2, $pos + $j + 1);
                        $j += 2;
                        last if $j + $descriptor_length > $es_info_length;
                        my $desc = substr($buf2, $pos+$j, $descriptor_length);
                        $j += $descriptor_length;
                        if ($verbose > 1) {
                            my $dstr = $desc;
                            $dstr =~ s/([\x00-\x1f\x80-\xff])/sprintf("\\x%.2x",ord $1)/eg;
                            printf $out "    ES Descriptor: Type=0x%.2x \"$dstr\"\n", $descriptor_tag;
                        }
                        # parse type-specific descriptor information (once)
                        unless ($didPID{$pid}) {
                            if ($descriptor_tag == 0x81) {  # AC-3
                                ParseAC3Descriptor($exifTool, \$desc);
                            }
                        }
                    }
                    $pos += $es_info_length;
                }
            }
            # $pos = $end + 4; # skip CRC

        } elsif (not defined $didPID{$pid}) {

            # save data from the start of each elementary stream
            if ($payload_unit_start_indicator) {
                if (defined $data{$pid}) {
                    # we must have a whole section, so parse now
                    my $more = ParsePID($exifTool, $pid, $pidType{$pid}, $pidName{$pid}, \$data{$pid});
                    # start fresh even if we couldn't process this PID yet
                    delete $data{$pid};
                    unless ($more) {
                        delete $needPID{$pid};
                        $didPID{$pid} = 1;
                        next;
                    }
                    # set flag indicating we found this PID but we still want more
                    $needPID{$pid} = -1;
                }
                # check for a PES header
                next if $pos + 6 > $pEnd;
                my $start_code = Get32u(\$buff, $pos);
                next unless ($start_code & 0xffffff00) == 0x00000100;
                my $stream_id = $start_code & 0xff;
                if ($verbose > 1) {
                    my $pes_packet_length = Get16u(\$buff, $pos + 4);
                    printf $out "  Stream ID:  0x%.2x\n", $stream_id;
                    print  $out "  Packet Len: $pes_packet_length\n";
                }
                $pos += 6;
                unless ($noSyntax{$stream_id}) {
                    next if $pos + 3 > $pEnd;
                    # validate PES syntax
                    my $syntax = Get8u(\$buff, $pos) & 0xc0;
                    $syntax == 0x80 or $exifTool->Warn('Bad PES syntax'), next;
                    # skip PES header
                    my $pes_header_data_length = Get8u(\$buff, $pos + 2);
                    $pos += 3 + $pes_header_data_length;
                    next if $pos >= $pEnd;
                }
                $data{$pid} = substr($buff, $pos, $pEnd-$pos);
            } else {
                next unless defined $data{$pid};
                # accumulate data for each elementary stream
                $data{$pid} .= substr($buff, $pos, $pEnd-$pos);
            }
            # save only the first 256 bytes of most streams, except for
            # unknown or H.264 streams where we save 1 kB
            my $saveLen = (not $pidType{$pid} or $pidType{$pid} == 0x1b) ? 1024 : 256;
            if (length($data{$pid}) >= $saveLen) {
                my $more = ParsePID($exifTool, $pid, $pidType{$pid}, $pidName{$pid}, \$data{$pid});
                next if $more < 0;  # wait for program map table (hopefully not too long)
                delete $data{$pid};
                $more and $needPID{$pid} = -1, next; # parse more of these
                delete $needPID{$pid};
                $didPID{$pid} = 1;
            }
            next;
        }
        if ($needPID{$pid}) {
            # we found and parsed a section with this PID, so
            # delete from the lookup of PID's we still need to parse
            delete $needPID{$pid};
            $didPID{$pid} = 1;
        }
    }

    # calculate Duration if available
    if (defined $startTime and defined $endTime and $startTime != $endTime) {
        $endTime += 0x80000000 * 1200 if $startTime > $endTime; # handle 33-bit wrap
        $exifTool->HandleTag($tagTablePtr, 'Duration', $endTime - $startTime);
    }

    if ($verbose) {
        my @need;
        foreach (keys %needPID) {
            push @need, sprintf('0x%.2x',$_) if $needPID{$_} > 0;
        }
        if (@need) {
            @need = sort @need;
            print $out "End of file.  Missing PID(s): @need\n";
        } else {
            my $what = $eof ? 'of file' : 'scan';
            print $out "End $what.  All PID's parsed.\n";
        }
    }

    # parse any remaining partial PID streams
    my $pid;
    foreach $pid (sort keys %data) {
        ParsePID($exifTool, $pid, $pidType{$pid}, $pidName{$pid}, \$data{$pid});
        delete $data{$pid};
    }
    return 1;
}

1;  # end

__END__


