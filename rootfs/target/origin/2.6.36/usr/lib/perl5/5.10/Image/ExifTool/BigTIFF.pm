
package Image::ExifTool::BigTIFF;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::Exif;

$VERSION = '1.05';

my $maxOffset = 0x7fffffff; # currently supported maximum data offset/size

sub ProcessBigIFD($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $raf = $$dirInfo{RAF};
    my $verbose = $exifTool->{OPTIONS}->{Verbose};
    my $htmlDump = $exifTool->{HTML_DUMP};
    my $dirName = $$dirInfo{DirName};
    my $dirStart = $$dirInfo{DirStart};

    $verbose = -1 if $htmlDump; # mix htmlDump into verbose so we can test for both at once

    # loop through IFD chain
    for (;;) {
        if ($dirStart > $maxOffset and not $exifTool->Options('LargeFileSupport')) {
            $exifTool->Warn('Huge offsets not supported (LargeFileSupport not set)');
            last;
        }
        unless ($raf->Seek($dirStart, 0)) {
            $exifTool->Warn("Bad $dirName offset");
            return 0;
        }
        my ($dirBuff, $index);
        unless ($raf->Read($dirBuff, 8) == 8) {
            $exifTool->Warn("Truncated $dirName count");
            return 0;
        }
        my $numEntries = Image::ExifTool::Get64u(\$dirBuff, 0);
        $verbose > 0 and $exifTool->VerboseDir($dirName, $numEntries);
        my $bsize = $numEntries * 20;
        if ($bsize > $maxOffset) {
            $exifTool->Warn('Huge directory counts not yet supported');
            last;
        }
        my $bufPos = $raf->Tell();
        unless ($raf->Read($dirBuff, $bsize) == $bsize) {
            $exifTool->Warn("Truncated $dirName directory");
            return 0;
        }
        my $nextIFD;
        $raf->Read($nextIFD, 8) == 8 or undef $nextIFD; # try to read next IFD pointer
        if ($htmlDump) {
            $exifTool->HDump($bufPos-8, 8, "$dirName entries", "Entry count: $numEntries");
            if (defined $nextIFD) {
                my $tip = sprintf("Offset: 0x%.8x", Image::ExifTool::Get64u(\$nextIFD, 0));
                $exifTool->HDump($bufPos + 20 * $numEntries, 8, "Next IFD", $tip, 0);
            }
        }
        # loop through all entries in this BigTIFF IFD
        for ($index=0; $index<$numEntries; ++$index) {
            my $entry = 20 * $index;
            my $tagID = Get16u(\$dirBuff, $entry);
            my $format = Get16u(\$dirBuff, $entry+2);
            my $count = Image::ExifTool::Get64u(\$dirBuff, $entry+4);
            my $formatSize = $Image::ExifTool::Exif::formatSize[$format];
            unless (defined $formatSize) {
                $exifTool->HDump($bufPos+$entry,20,"[invalid IFD entry]",
                         "Bad format value: $format", 1);
                # warn unless the IFD was just padded with zeros
                $exifTool->Warn(sprintf("Unknown format ($format) for $dirName tag 0x%x",$tagID));
                return 0; # assume corrupted IFD
            }
            my $formatStr = $Image::ExifTool::Exif::formatName[$format];
            my $size = $count * $formatSize;
            my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tagID);
            next unless defined $tagInfo or $verbose;
            my $valuePtr = $entry + 12;
            my ($valBuff, $valBase);
            if ($size > 8) {
                if ($size > $maxOffset) {
                    $exifTool->Warn("Can't handle $dirName entry $index (huge size)");
                    next;
                }
                $valuePtr = Image::ExifTool::Get64u(\$dirBuff, $valuePtr);
                if ($valuePtr > $maxOffset and not $exifTool->Options('LargeFileSupport')) {
                    $exifTool->Warn("Can't handle $dirName entry $index (LargeFileSupport not set)");
                    next;
                }
                unless ($raf->Seek($valuePtr, 0) and $raf->Read($valBuff, $size) == $size) {
                    $exifTool->Warn("Error reading $dirName entry $index");
                    next;
                }
                $valBase = 0;
            } else {
                $valBuff = substr($dirBuff, $valuePtr, $size);
                $valBase = $bufPos;
            }
            if (defined $tagInfo and not $tagInfo) {
                # GetTagInfo() required the value for a Condition
                $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tagID, \$valBuff);
            }
            my $val = ReadValue(\$valBuff, 0, $formatStr, $count, $size);
            if ($htmlDump) {
                my $tval = $val;
                if ($formatStr =~ /^rational64([su])$/) {
                    # show numerator/denominator separately
                    my $f = ReadValue(\$valBuff, 0, "int32$1", $count*2, $size);
                    $f =~ s/(-?\d+) (-?\d+)/$1\/$2/g;
                    $tval .= " ($f)";
                }
                my ($tagName, $colName);
                if ($tagID == 0x927c and $dirName eq 'ExifIFD') {
                    $tagName = 'MakerNotes';
                } elsif ($tagInfo) {
                    $tagName = $$tagInfo{Name};
                } else {
                    $tagName = sprintf("Tag 0x%.4x",$tagID);
                }
                my $dname = sprintf("$dirName-%.2d", $index);
                # build our tool tip
                my $tip = sprintf("Tag ID: 0x%.4x\n", $tagID) .
                          "Format: $formatStr\[$count]\nSize: $size bytes\n";
                if ($size > 8) {
                    $tip .= sprintf("Value offset: 0x%.8x\n", $valuePtr);
                    $colName = "<span class=H>$tagName</span>";
                } else {
                    $colName = $tagName;
                }
                $tval = substr($tval,0,28) . '[...]' if length($tval) > 32;
                if ($formatStr =~ /^(string|undef|binary)/) {
                    # translate non-printable characters
                    $tval =~ tr/\x00-\x1f\x7f-\xff/./;
                } elsif ($tagInfo and Image::ExifTool::IsInt($tval)) {
                    if ($$tagInfo{IsOffset}) {
                        $tval = sprintf('0x%.4x', $tval);
                    } elsif ($$tagInfo{PrintHex}) {
                        $tval = sprintf('0x%x', $tval);
                    }
                }
                $tip .= "Value: $tval";
                $exifTool->HDump($entry+$bufPos, 20, "$dname $colName", $tip, 1);
                if ($size > 8) {
                    # add value data block
                    my $flg = ($tagInfo and $$tagInfo{SubDirectory} and $$tagInfo{MakerNotes}) ? 4 : 0;
                    $exifTool->HDump($valuePtr,$size,"$tagName value",'SAME', $flg);
                }
            }
            if ($tagInfo and $$tagInfo{SubIFD}) {
                # process all SubIFD's as BigTIFF
                $verbose > 0 and $exifTool->VerboseInfo($tagID, $tagInfo,
                    Table   => $tagTablePtr,
                    Index   => $index,
                    Value   => $val,
                    DataPt  => \$valBuff,
                    DataPos => $valBase + $valuePtr,
                    Start   => 0,
                    Size    => $size,
                    Format  => $formatStr,
                    Count   => $count,
                );
                my @offsets = split ' ', $val;
                my $i;
                for ($i=0; $i<scalar(@offsets); ++$i) {
                    my $subdirName = $$tagInfo{Name};
                    $subdirName .= $i if $i;
                    my %subdirInfo = (
                        RAF      => $raf,
                        DataPos  => 0,
                        DirStart => $offsets[$i],
                        DirName  => $subdirName,
                        Parent   => $dirInfo,
                    );
                    $exifTool->ProcessDirectory(\%subdirInfo, $tagTablePtr, \&ProcessBigIFD);
                }
            } else {
                my $tagKey = $exifTool->HandleTag($tagTablePtr, $tagID, $val,
                    Index   => $index,
                    DataPt  => \$valBuff,
                    DataPos => $valBase + $valuePtr,
                    Start   => 0,
                    Size    => $size,
                    Format  => $formatStr,
                    TagInfo => $tagInfo,
                    RAF     => $raf,
                );
                $tagKey and $exifTool->SetGroup($tagKey, $dirName);
            }
        }
        last unless $dirName =~ /^(IFD|SubIFD)(\d*)$/;
        $dirName = $1 . (($2 || 0) + 1);
        defined $nextIFD or $exifTool->Warn("Bad $dirName pointer"), return 0;
        $dirStart = Image::ExifTool::Get64u(\$nextIFD, 0);
        $dirStart or last;
    }
    return 1;
}

sub ProcessBTF($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $buff;

    return 0 unless $raf->Read($buff, 16) == 16;
    return 0 unless $buff =~ /^(MM\0\x2b\0\x08\0\0|II\x2b\0\x08\0\0\0)/;
    if ($$dirInfo{OutFile}) {
        $exifTool->Error('ExifTool does not support writing of BigTIFF images');
        return 1;
    }
    $exifTool->SetFileType('BTF'); # set the FileType tag
    SetByteOrder(substr($buff, 0, 2));
    my $offset = Image::ExifTool::Get64u(\$buff, 8);
    if ($exifTool->{HTML_DUMP}) {
        my $o = (GetByteOrder() eq 'II') ? 'Little' : 'Big';
        $exifTool->HDump(0, 8, "BigTIFF header", "Byte order: $o endian", 0);
        $exifTool->HDump(8, 8, "IFD0 pointer", sprintf("Offset: 0x%.8x",$offset), 0);
    }
    my %dirInfo = (
        RAF      => $raf,
        DataPos  => 0,
        DirStart => $offset,
        DirName  => 'IFD0',
        Parent   => 'BigTIFF',
    );
    my $tagTablePtr = GetTagTable('Image::ExifTool::Exif::Main');
    $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr, \&ProcessBigIFD);
    return 1;
}

1;  # end

__END__


