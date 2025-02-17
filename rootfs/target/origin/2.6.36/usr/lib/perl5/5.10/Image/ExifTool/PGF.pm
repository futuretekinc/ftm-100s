
package Image::ExifTool::PGF;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.01';

%Image::ExifTool::PGF::Main = (
    GROUPS => { 0 => 'File', 1 => 'File', 2 => 'Image' },
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    PRIORITY => 2,  # (to take precedence over PNG tags from embedded image)
    NOTES => q{
        The following table lists information extracted from the header of
        Progressive Graphics File (PGF) images.  As well, information is extracted
        from the embedded PNG metadata image if it exists.  See
        L<http://www.libpgf.org/> for the PGF specification.
    },
    3  => {
        Name => 'PGFVersion',
        PrintConv => 'sprintf("0x%.2x", $val)',
        # this is actually a bitmask (ref digikam PGFtypes.h):
        # 0x02 - data structure PGFHeader of major version 2
        # 0x04 - 32-bit values
        # 0x08 - supports regions of interest
        # 0x10 - new coding scheme since major version 5
        # 0x20 - new HeaderSize: 32 bits instead of 16 bits
    },
    8  => { Name => 'ImageWidth',  Format => 'int32u' },
    12 => { Name => 'ImageHeight', Format => 'int32u' },
    16 => 'PyramidLevels',
    17 => 'Quality',
    18 => 'BitsPerPixel',
    19 => 'ColorComponents',
    20 => {
        Name => 'ColorMode',
        RawConv => '$$self{PGFColorMode} = $val',
        PrintConvColumns => 2,
        PrintConv => {
            0 => 'Bitmap',
            1 => 'Grayscale',
            2 => 'Indexed',
            3 => 'RGB',
            4 => 'CMYK',
            7 => 'Multichannel',
            8 => 'Duotone',
            9 => 'Lab',
        },
    },
    21 => { Name => 'BackgroundColor', Format => 'int8u[3]' },
);

sub ProcessPGF($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $buff;

    # read header and check magic number
    return 0 unless $raf->Read($buff, 24) == 24 and $buff =~ /^PGF(.)/s;
    my $ver = ord $1;
    $exifTool->SetFileType();
    SetByteOrder('II');

    # currently support only version 0x36
    unless ($ver == 0x36) {
        $exifTool->Error(sprintf('Unsupported PGF version 0x%.2x', $ver));
        return 1;
    }
    # extract information from the PGF header
    my $tagTablePtr = GetTagTable('Image::ExifTool::PGF::Main');
    $exifTool->ProcessDirectory({ DataPt => \$buff, DataPos => 0 }, $tagTablePtr);

    my $len = Get32u(\$buff, 4) - 16; # length of post-header data

    # skip colour table if necessary
    $len -= $raf->Seek(1024, 1) ? 1024 : $len if $$exifTool{PGFColorMode} == 2;

    # extract information from the embedded metadata image (PNG format)
    if ($len > 0 and $len < 0x1000000 and $raf->Read($buff, $len) == $len) {
        $exifTool->ExtractInfo(\$buff, { ReEntry => 1 });
    }
    return 1;
}


1;  # end

__END__


