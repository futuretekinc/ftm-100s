
package Image::ExifTool::BMP;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.07';

%Image::ExifTool::BMP::Main = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 0 => 'File', 1 => 'File', 2 => 'Image' },
    NOTES => q{
        There really isn't much meta information in a BMP file as such, just a bit
        of image related information.
    },
    # 0 => size of bitmap structure:
    #        12  bytes => 'OS/2 V1',
    #        40  bytes => 'Windows V3',
    #        64  bytes => 'OS/2 V2',
    #        68  bytes => some bitmap structure in AVI videos
    #        108 bytes => 'Windows V4',
    #        124 bytes => 'Windows V5',
    4 => {
        Name => 'ImageWidth',
        Format => 'int32u',
    },
    8 => {
        Name => 'ImageHeight',
        Format => 'int32s', # (negative when stored in top-to-bottom order)
        ValueConv => 'abs($val)',
    },
    12 => {
        Name => 'Planes',
        Format => 'int16u',
    },
    14 => {
        Name => 'BitDepth',
        Format => 'int16u',
    },
    16 => {
        Name => 'Compression',
        Format => 'int32u',
        # (formatted as string[4] for some values in AVI images)
        ValueConv => '$val > 256 ? unpack("A4",pack("V",$val)) : $val',
        PrintConv => {
            0 => 'None',
            1 => '8-Bit RLE',
            2 => '4-Bit RLE',
            3 => 'Bitfields',
            4 => 'JPEG', #2
            5 => 'PNG', #2
            # pass through ASCII video compression codec ID's
            OTHER => sub {
                my $val = shift;
                # convert non-ascii characters
                $val =~ s/([\0-\x1f\x7f-\xff])/sprintf('\\x%.2x',ord $1)/eg;
                return $val;
            },
        },
    },
    20 => {
        Name => 'ImageLength',
        Format => 'int32u',
    },
    24 => {
        Name => 'PixelsPerMeterX',
        Format => 'int32u',
    },
    28 => {
        Name => 'PixelsPerMeterY',
        Format => 'int32u',
    },
    32 => {
        Name => 'NumColors',
        Format => 'int32u',
        PrintConv => '$val ? $val : "Use BitDepth"',
    },
    36 => {
        Name => 'NumImportantColors',
        Format => 'int32u',
        PrintConv => '$val ? $val : "All"',
    },
);

%Image::ExifTool::BMP::OS2 = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 0 => 'File', 1 => 'File', 2 => 'Image' },
    NOTES => 'Information extracted from OS/2-format BMP images.',
    # 0 => size of bitmap structure (12)
    4  => { Name => 'ImageWidth',  Format => 'int16u' },
    6  => { Name => 'ImageHeight', Format => 'int16u' },
    8  => { Name => 'Planes',      Format => 'int16u' },
    10 => { Name => 'BitDepth',    Format => 'int16u' },
);

sub ProcessBMP($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my ($buff, $tagTablePtr);

    # verify this is a valid BMP file
    return 0 unless $raf->Read($buff, 18) == 18;
    return 0 unless $buff =~ /^BM/;
    SetByteOrder('II');
    my $len = Get32u(\$buff, 14);
    return 0 unless $len == 12 or $len >= 40;
    return 0 unless $raf->Seek(-4, 1) and $raf->Read($buff, $len) == $len;
    $exifTool->SetFileType();   # set the FileType tag
    my %dirInfo = (
        DataPt => \$buff,
        DirStart => 0,
        DirLen => length($buff),
    );
    if ($len == 12) {   # old OS/2 format BMP
        $tagTablePtr = GetTagTable('Image::ExifTool::BMP::OS2');
    } else {
        $tagTablePtr = GetTagTable('Image::ExifTool::BMP::Main');
    }
    $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
    return 1;
}

1;  # end

__END__


