
package Image::ExifTool::KyoceraRaw;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.02';

sub ProcessRAW($$);

sub ReverseString($) { pack('C*',reverse unpack('C*',shift)) }

%Image::ExifTool::KyoceraRaw::Main = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Camera' },
    NOTES => 'Tags for Kyocera Contax N Digital RAW images.',
    0x01 => {
        Name => 'FirmwareVersion',
        Format => 'string[10]',
        ValueConv => \&ReverseString,
    },
    0x0c => {
        Name => 'Model',
        Format => 'string[12]',
        ValueConv => \&ReverseString,
    },
    0x19 => { #1
        Name => 'Make',
        Format => 'string[7]',
        ValueConv => \&ReverseString,
    },
    0x21 => { #1
        Name => 'DateTimeOriginal',
        Description => 'Date/Time Original',
        Groups => { 2 => 'Time' },
        Format => 'string[20]',
        ValueConv => \&ReverseString,
        PrintConv => '$self->ConvertDateTime($val)',
    },
    0x34 => {
        Name => 'ISO',
        Groups => { 2 => 'Image' },
        Format => 'int32u',
        PrintConv => {
            7 => 25,
            8 => 32,
            9 => 40,
            10 => 50,
            11 => 64,
            12 => 80,
            13 => 100,
            14 => 125,
            15 => 160,
            16 => 200,
            17 => 250,
            18 => 320,
            19 => 400,
        },
    },
    0x38 => {
        Name => 'ExposureTime',
        Groups => { 2 => 'Image' },
        Format => 'int32u',
        ValueConv => '2**($val / 8) / 16000',
        PrintConv => 'Image::ExifTool::Exif::PrintExposureTime($val)',
    },
    0x3c => { #1
        Name => 'WB_RGGBLevels',
        Groups => { 2 => 'Image' },
        Format => 'int32u[4]',
    },
    0x58 => {
        Name => 'FNumber',
        Groups => { 2 => 'Image' },
        Format => 'int32u',
        ValueConv => '2**($val/16)',
        PrintConv => 'sprintf("%.2g",$val)',
    },
    0x68 => {
        Name => 'MaxAperture',
        Format => 'int32u',
        ValueConv => '2**($val/16)',
        PrintConv => 'sprintf("%.2g",$val)',
    },
    0x70 => {
        Name => 'FocalLength',
        Format => 'int32u',
        PrintConv => '"$val mm"',
    },
    0x7c => {
        Name => 'Lens',
        Format => 'string[32]',
    },
);

sub ProcessRAW($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $size = 156; # size of header
    my $buff;

    $raf->Read($buff, $size) == $size or return 0;
    # validate Make string ('KYOCERA' reversed)
    substr($buff, 0x19, 7) eq 'ARECOYK' or return 0;
    $exifTool->SetFileType();
    SetByteOrder('MM');
    my %dirInfo = (
        DataPt => \$buff,
        DataPos => 0,
        DataLen => $size,
        DirStart => 0,
        DirLen => $size,
    );
    my $tagTablePtr = GetTagTable('Image::ExifTool::KyoceraRaw::Main');
    $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
    return 1;
}

1;  # end

__END__

