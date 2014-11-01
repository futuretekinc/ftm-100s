
package Image::ExifTool::ITC;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.00';

sub ProcessITC($$);

%Image::ExifTool::ITC::Main = (
    NOTES => 'This information is found in iTunes Cover Flow data files.',
    itch => { SubDirectory => { TagTable => 'Image::ExifTool::ITC::Header' } },
    item => { SubDirectory => { TagTable => 'Image::ExifTool::ITC::Item' } },
    data => {
        Name => 'ImageData',
        Notes => 'embedded JPEG or PNG image, depending on ImageType',
    },
);

%Image::ExifTool::ITC::Header = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 2 => 'Image' },
    0x10 => {
        Name => 'DataType',
        Format => 'undef[4]',
        PrintConv => { artw => 'Artwork' },
    },
);

%Image::ExifTool::ITC::Item = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 2 => 'Image' },
    FORMAT => 'int32u',
    FIRST_ENTRY => 0,
    0 => {
        Name => 'LibraryID',
        Format => 'undef[8]',
        ValueConv => 'uc unpack "H*", $val',
    },
    2 => {
        Name => 'TrackID',
        Format => 'undef[8]',
        ValueConv => 'uc unpack "H*", $val',
    },
    4 => {
        Name => 'DataLocation',
        Format => 'undef[4]',
        PrintConv => {
            down => 'Downloaded Separately',
            locl => 'Local Music File',
        },
    },
    5 => {
        Name => 'ImageType',
        Format => 'undef[4]',
        PrintConv => {
            'PNGf' => 'PNG',
            "\0\0\0\x0d" => 'JPEG',
        },
    },
    7 => 'ImageWidth',
    8 => 'ImageHeight',
);

sub ProcessITC($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $rtnVal = 0;
    my ($buff, $err, $pos, $tagTablePtr, %dirInfo);

    # loop through all blocks in this image
    for (;;) {
        # read the block header
        my $n = $raf->Read($buff, 8);
        unless ($n == 8) {
            # no error if we reached the EOF normally
            undef $err unless $n;
            last;
        }
        my ($size, $tag) = unpack('Na4', $buff);
        if ($rtnVal) {
            last unless $size >= 8 and $size < 0x80000000;
        } else {
            # check to be sure this is a valid ITC image
            # (first block must be 'itch')
            last unless $tag eq 'itch';
            last unless $size >= 0x1c and $size < 0x10000;
            $exifTool->SetFileType();
            SetByteOrder('MM');
            $rtnVal = 1;    # this is an ITC file
            $err = 1;       # format error unless we read to EOF
        }
        if ($tag eq 'itch') {
            $pos = $raf->Tell();
            $size -= 8; # size of remaining data in block
            $raf->Read($buff,$size) == $size or last;
            # extract header information
            %dirInfo = (
                DirName => 'ITC Header',
                DataPt  => \$buff,
                DataPos => $pos,
            );
            my $tagTablePtr = GetTagTable('Image::ExifTool::ITC::Header');
            $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
        } elsif ($tag eq 'item') {
            # don't want to read the entire item data (includes image)
            $size > 12 or last;
            $raf->Read($buff, 4) == 4 or last;
            my $len = unpack('N', $buff);
            $len >= 0xd0 and $len <= $size or last;
            $size -= $len;  # size of data after item header
            $len -= 12;     # length of remaining item header
            # read in 4-byte blocks until we find the null terminator
            # (this is just a guess about how to parse this variable-length part)
            while ($len >= 4) {
                $raf->Read($buff, 4) == 4 or last;
                $len -= 4;
                last if $buff eq "\0\0\0\0";
            }
            last if $len < 4;
            $pos = $raf->Tell();
            $raf->Read($buff, $len) == $len or last;
            unless ($len >= 0xb4 and substr($buff, 0xb0, 4) eq 'data') {
                $exifTool->Warn('Parsing error. Please submit this ITC file for testing');
                last;
            }
            %dirInfo = (
                DirName => 'ITC Item',
                DataPt  => \$buff,
                DataPos => $pos,
            );
            $tagTablePtr = GetTagTable('Image::ExifTool::ITC::Item');
            $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
            # extract embedded image
            $pos += $len;
            if ($size > 0) {
                $tagTablePtr = GetTagTable('Image::ExifTool::ITC::Main');
                my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, 'data');
                my $image = $exifTool->ExtractBinary($pos, $size, $$tagInfo{Name});
                $exifTool->FoundTag($tagInfo, \$image);
                # skip the rest of the block if necessary
                $raf->Seek($pos+$size, 0) or last
            } elsif ($size < 0) {
                last;
            }
        } else {
            $exifTool->VPrint(0, "Unknown $tag block ($size bytes)\n");
            $raf->Seek($size-8, 1) or last;
        }
    }
    $err and $exifTool->Warn('ITC file format error');
    return $rtnVal;
}

1;  # end

__END__


