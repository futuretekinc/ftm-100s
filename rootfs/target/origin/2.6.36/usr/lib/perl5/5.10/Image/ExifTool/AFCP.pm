
package Image::ExifTool::AFCP;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.04';

sub ProcessAFCP($$);

%Image::ExifTool::AFCP::Main = (
    PROCESS_PROC => \&ProcessAFCP,
    NOTES => q{
AFCP stands for AXS File Concatenation Protocol, and is a poorly designed
protocol for appending information to the end of files.  This can be used as
an auxiliary technique to store IPTC information in images, but is
incompatible with some file formats.

ExifTool will read and write (but not create) AFCP IPTC information in JPEG
and TIFF images.
    },
    IPTC => { SubDirectory => { TagTable => 'Image::ExifTool::IPTC::Main' } },
    TEXT => 'Text',
    Nail => {
        Name => 'ThumbnailImage',
        # (the specification allows for a variable amount of padding before
        #  the image after a 10-byte header, so look for the JPEG SOI marker,
        #  otherwise assume a fixed 8 bytes of padding)
        RawConv => q{
            pos($val) = 10;
            my $start = ($val =~ /\xff\xd8\xff/g) ? pos($val) - 3 : 18;
            my $img = substr($val, $start);
            return $self->ValidateImage(\$img, $tag);
        },
    },
    PrVw => {
        Name => 'PreviewImage',
        RawConv => q{
            pos($val) = 10;
            my $start = ($val =~ /\xff\xd8\xff/g) ? pos($val) - 3 : 18;
            my $img = substr($val, $start);
            return $self->ValidateImage(\$img, $tag);
        },
    },
);

sub ProcessAFCP($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $curPos = $raf->Tell();
    my $offset = $$dirInfo{Offset} || 0;    # offset from end of file
    my $rtnVal = 0;

NoAFCP: for (;;) {
        my ($buff, $fix, $dirBuff, $valBuff, $fixup, $vers);
        # look for AXS trailer
        last unless $raf->Seek(-12-$offset, 2) and
                    $raf->Read($buff, 12) == 12 and
                    $buff =~ /^(AXS(!|\*))/;
        my $endPos = $raf->Tell();
        my $hdr = $1;
        SetByteOrder($2 eq '!' ? 'MM' : 'II');
        my $startPos = Get32u(\$buff, 4);
        if ($raf->Seek($startPos, 0) and $raf->Read($buff, 12) == 12 and $buff =~ /^$hdr/) {
            $fix = 0;
        } else {
            $rtnVal = -1;
            # look for start of AXS trailer if 'ScanForAFCP'
            last unless $$dirInfo{ScanForAFCP} and $raf->Seek($curPos, 0);
            my $actualPos = $curPos;
            # first look for header right at current position
            for (;;) {
                last if $raf->Read($buff, 12) == 12 and $buff =~ /^$hdr/;
                last NoAFCP if $actualPos != $curPos;
                # scan for AXS header (could be after preview image)
                for (;;) {
                    my $buf2;
                    $raf->Read($buf2, 65536) or last NoAFCP;
                    $buff .= $buf2;
                    if ($buff =~ /$hdr/g) {
                        $actualPos += pos($buff) - length($hdr);
                        last;   # ok, now go back and re-read header
                    }
                    $buf2 = substr($buf2, -3);  # only need last 3 bytes for next test
                    $actualPos += length($buff) - length($buf2);
                    $buff = $buf2;
                }
                last unless $raf->Seek($actualPos, 0);  # seek to start of AFCP
            }
            # calculate shift for fixing AFCP offsets
            $fix = $actualPos - $startPos;
        }
        # set variables returned in dirInfo hash
        $$dirInfo{DataPos} = $startPos + $fix;  # actual start position
        $$dirInfo{DirLen} = $endPos - ($startPos + $fix);

        $rtnVal = 1;
        my $verbose = $exifTool->Options('Verbose');
        my $out = $exifTool->Options('TextOut');
        my $outfile = $$dirInfo{OutFile};
        if ($outfile) {
            # allow all AFCP information to be deleted
            if ($exifTool->{DEL_GROUP}->{AFCP}) {
                $verbose and print $out "  Deleting AFCP\n";
                ++$exifTool->{CHANGED};
                last;
            }
            $dirBuff = $valBuff = '';
            require Image::ExifTool::Fixup;
            $fixup = $$dirInfo{Fixup};
            $fixup or $fixup = $$dirInfo{Fixup} = new Image::ExifTool::Fixup;
            $vers = substr($buff, 4, 2); # get version number
        } else {
            $exifTool->DumpTrailer($dirInfo) if $verbose or $exifTool->{HTML_DUMP};
        }
        # read AFCP directory data
        my $numEntries = Get16u(\$buff, 6);
        my $dir;
        unless ($raf->Read($dir, 12 * $numEntries) == 12 * $numEntries) {
            $exifTool->Error('Error reading AFCP directory', 1);
            last;
        }
        if ($verbose > 2 and not $outfile) {
            my $dat = $buff . $dir;
            print $out "  AFCP Directory:\n";
            Image::ExifTool::HexDump(\$dat, undef,
                Addr   => $$dirInfo{DataPos},
                Width  => 12,
                Prefix => $exifTool->{INDENT},
                Out => $out,
            );
        }
        $fix and $exifTool->Warn("Adjusted AFCP offsets by $fix", 1);
        my $tagTablePtr = GetTagTable('Image::ExifTool::AFCP::Main');
        my ($index, $entry);
        for ($index=0; $index<$numEntries; ++$index) {
            my $entry = 12 * $index;
            my $tag = substr($dir, $entry, 4);
            my $size = Get32u(\$dir, $entry + 4);
            my $offset = Get32u(\$dir, $entry + 8);
            if ($size < 0x80000000 and
                $raf->Seek($offset+$fix, 0) and
                $raf->Read($buff, $size) == $size)
            {
                if ($outfile) {
                    # rewrite this information
                    my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tag);
                    if ($tagInfo and $$tagInfo{SubDirectory}) {
                        my %subdirInfo = (
                            DataPt => \$buff,
                            DirStart => 0,
                            DirLen => $size,
                            DataPos => $offset + $fix,
                            Parent => 'AFCP',
                        );
                        my $subTable = GetTagTable($tagInfo->{SubDirectory}->{TagTable});
                        my $newDir = $exifTool->WriteDirectory(\%subdirInfo, $subTable);
                        if (defined $newDir) {
                            $size = length $newDir;
                            $buff = $newDir;
                        }
                    }
                    $fixup->AddFixup(length($dirBuff) + 8);
                    $dirBuff .= $tag . Set32u($size) . Set32u(length $valBuff);
                    $valBuff .= $buff;
                } else {
                    # extract information
                    $exifTool->HandleTag($tagTablePtr, $tag, $buff,
                        DataPt => \$buff,
                        Size => $size,
                        Index => $index,
                        DataPos => $offset + $fix,
                    );
                }
            } else {
                $exifTool->Warn("Bad AFCP directory");
                $rtnVal = -1 if $outfile;
                last;
            }
        }
        if ($outfile and length($dirBuff)) {
            my $outPos = Tell($outfile);    # get current outfile position
            # apply fixup to directory pointers
            my $valPos = $outPos + 12;      # start of value data
            $fixup->{Shift} += $valPos + length($dirBuff);
            $fixup->ApplyFixup(\$dirBuff);
            # write the AFCP header, directory, value data and EOF record (with zero checksums)
            Write($outfile, $hdr, $vers, Set16u(length($dirBuff)/12), Set32u(0),
                  $dirBuff, $valBuff, $hdr, Set32u($outPos), Set32u(0)) or $rtnVal = -1;
            # complete fixup so the calling routine can apply further shifts
            $fixup->AddFixup(length($dirBuff) + length($valBuff) + 4);
            $fixup->{Start} += $valPos;
            $fixup->{Shift} -= $valPos;
        }
        last;
    }
    return $rtnVal;
}

1;  # end

__END__


