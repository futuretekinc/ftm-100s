
package Image::ExifTool::Rawzor;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.01';

my $implementedRawzorVersion = 199; # (up to version 1.99)

%Image::ExifTool::Rawzor::Main = (
    GROUPS => { 2 => 'Other' },
    VARS => { NO_ID => 1 },
    NOTES => q{
        Rawzor files store compressed images of other formats. As well as the
        information listed below, exiftool uncompresses and extracts the meta
        information from the original image.
    },
    OriginalFileType => { },
    OriginalFileSize => {
        PrintConv => $Image::ExifTool::Extra{FileSize}->{PrintConv},
    },
    RawzorRequiredVersion => {
        ValueConv => '$val / 100',
        PrintConv => 'sprintf("%.2f", $val)',
    },
    RawzorCreatorVersion => {
        ValueConv => '$val / 100',
        PrintConv => 'sprintf("%.2f", $val)',
    },
    # compression factor is originalSize/compressedSize (and compression
    # ratio is the inverse - ref "Data Compression" by David Salomon)
    CompressionFactor => { PrintConv => 'sprintf("%.2f", $val)' },
);

sub ProcessRWZ($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my ($buff, $buf2);

    # read the Rawzor file header:
    #  0 string - "rawzor" signature
    #  6 int16u - Required SDK version
    #  8 int16u - Creator SDK version
    # 10 int64u - RWZ file size
    # 18 int64u - original raw file size
    # 26 undef[12] - reserved
    # 38 int64u - metadata offset
    $raf->Read($buff, 46) == 46 and $buff =~ /^rawzor/ or return 0;

    SetByteOrder('II');
    my $reqVers = Get16u(\$buff, 6);
    my $creatorVers = Get16u(\$buff, 8);
    my $rwzSize = Get64u(\$buff, 10);
    my $origSize = Get64u(\$buff, 18);
    my $tagTablePtr = GetTagTable('Image::ExifTool::Rawzor::Main');
    $exifTool->HandleTag($tagTablePtr, RawzorRequiredVersion => $reqVers);
    $exifTool->HandleTag($tagTablePtr, RawzorCreatorVersion => $creatorVers);
    $exifTool->HandleTag($tagTablePtr, OriginalFileSize => $origSize);
    $exifTool->HandleTag($tagTablePtr, CompressionFactor => $origSize/$rwzSize) if $rwzSize;
    # check version numbers
    if ($reqVers > $implementedRawzorVersion) {
        $exifTool->Warn("Version $reqVers Rawzor images not yet supported");
        return 1;
    }
    my $metaOffset = Get64u(\$buff, 38);
    if ($metaOffset > 0x7fffffff) {
        $exifTool->Warn('Bad metadata offset');
        return 1;
    }
    # check for the ability to uncompress the information
    unless (eval 'require IO::Uncompress::Bunzip2') {
        $exifTool->Warn('Install IO::Compress::Bzip2 to decode Rawzor bzip2 compression');
        return 1;
    }
    # read the metadata header:
    #  0 int64u - metadata section 0 end (offset in original file)
    #  8 int64u - metadata section 1 start
    # 16 int64u - metadata section 1 end
    # 24 int64u - metadata section 2 start
    # 32 undef[4] - reserved
    # 36 int32u - original metadata size
    # 40 int32u - compressed metadata size
    unless ($raf->Seek($metaOffset, 0) and $raf->Read($buff, 44) == 44) {
        $exifTool->Warn('Error reading metadata header');
        return 1;
    }
    my $metaSize = Get32u(\$buff, 36);
    if ($metaSize) {
        # validate the metadata header and read the compressed metadata
        my $end0 = Get64u(\$buff, 0);
        my $pos1 = Get64u(\$buff, 8);
        my $end1 = Get64u(\$buff, 16);
        my $pos2 = Get64u(\$buff, 24);
        my $len = Get32u(\$buff, 40);
        unless ($raf->Read($buff, $len) == $len and
            $end0 + ($end1 - $pos1) + ($origSize - $pos2) == $metaSize and
            $end0 <= $pos1 and $pos1 <= $end1 and $end1 <= $pos2)
        {
            $exifTool->Warn('Error reading image metadata');
            return 1;
        }
        # uncompress the metadata
        unless (IO::Uncompress::Bunzip2::bunzip2(\$buff, \$buf2) and
            length($buf2) eq $metaSize)
        {
            $exifTool->Warn('Error uncompressing image metadata');
            return 1;
        }
        # re-assemble the original file (sans image data)
        undef $buff; # (can't hurt to free memory as soon as possible)
        $buff = substr($buf2, 0, $end0) . ("\0" x ($pos1 - $end0)) .
                substr($buf2, $end0, $end1 - $pos1) . ("\0" x ($pos2 - $end1)) .
                substr($buf2, $end0 + $end1 - $pos1, $origSize - $pos2);
        undef $buf2;

        # extract original information by calling ExtractInfo recursively
        $exifTool->ExtractInfo(\$buff, { ReEntry => 1 });
        undef $buff;
    }
    # set OriginalFileType from FileType of original file
    # then change FileType and MIMEType to indicate a Rawzor image
    my $origFileType = $exifTool->{VALUE}->{FileType};
    if ($origFileType) {
        $exifTool->HandleTag($tagTablePtr, OriginalFileType => $origFileType);
        $exifTool->{VALUE}->{FileType} = 'RWZ';
        $exifTool->{VALUE}->{MIMEType} = 'image/x-rawzor';
    } else {
        $exifTool->HandleTag($tagTablePtr, OriginalFileType => 'Unknown');
        $exifTool->SetFileType();
    }
    return 1;
}

1;  # end

__END__


