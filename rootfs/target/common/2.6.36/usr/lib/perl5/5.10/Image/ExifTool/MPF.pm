
package Image::ExifTool::MPF;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::Exif;

$VERSION = '1.05';

sub ProcessMPImageList($$$);

%Image::ExifTool::MPF::Main = (
    GROUPS => { 0 => 'MPF', 1 => 'MPF0', 2 => 'Image'},
    NOTES => q{
        These tags are part of the CIPA Multi-Picture Format specification, and are
        found in the APP2 "MPF" segment of JPEG images.  See
        L<http://www.cipa.jp/english/hyoujunka/kikaku/pdf/DC-007_E.pdf> for the
        official specification.
    },
    0xb000 => 'MPFVersion',
    0xb001 => 'NumberOfImages',
    0xb002 => {
        Name => 'MPImageList',
        SubDirectory => {
            TagTable => 'Image::ExifTool::MPF::MPImage',
            ProcessProc => \&ProcessMPImageList,
        },
    },
    0xb003 => {
        Name => 'ImageUIDList',
        Binary => 1,
    },
    0xb004 => 'TotalFrames',
    0xb101 => 'MPIndividualNum',
    0xb201 => {
        Name => 'PanOrientation',
        PrintHex => 1,
        Notes => 'long integer is split into 4 bytes',
        ValueConv => 'join(" ",unpack("C*",pack("N",$val)))',
        PrintConv => [
            '"$val rows"',
            '"$val columns"',
            {
                0 => '[unused]',
                1 => 'Start at top right',
                2 => 'Start at top left',
                3 => 'Start at bottom left',
                4 => 'Start at bottom right',
            },
            {
                0x01 => 'Left to right',
                0x02 => 'Right to left',
                0x03 => 'Top to bottom',
                0x04 => 'Bottom to top',
                0x10 => 'Clockwise',
                0x20 => 'Counter clockwise',
                0x30 => 'Zigzag (row start)',
                0x40 => 'Zigzag (column start)',
            },
        ],
    },          
    0xb202 => 'PanOverlapH',
    0xb203 => 'PanOverlapV',
    0xb204 => 'BaseViewpointNum',
    0xb205 => 'ConvergenceAngle',
    0xb206 => 'BaselineLength',
    0xb207 => 'VerticalDivergence',
    0xb208 => 'AxisDistanceX',
    0xb209 => 'AxisDistanceY',
    0xb20a => 'AxisDistanceZ',
    0xb20b => 'YawAngle',
    0xb20c => 'PitchAngle',
    0xb20d => 'RollAngle',
);

%Image::ExifTool::MPF::MPImage = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    #WRITE_PROC => \&Image::ExifTool::WriteBinaryData,
    #CHECK_PROC => \&Image::ExifTool::CheckBinaryData,
    #WRITABLE => 1,
    GROUPS => { 0 => 'MPF', 1 => 'MPImage', 2 => 'Image'},
    NOTES => q{
        The first MPF "Large Thumbnail" image is extracted as PreviewImage, and the
        rest of the embedded MPF images are extracted as MPImage#.  The
        ExtractEmbedded (-ee) option may be used to extract information from these
        embedded images.
    },
    0.1 => {
        Name => 'MPImageFlags',
        Format => 'int32u',
        Mask => 0xf8000000,
        PrintConv => { BITMASK => {
            29 => 'Representative image',
            30 => 'Dependent child image',
            31 => 'Dependent parent image',
        }},
    },
    0.2 => {
        Name => 'MPImageFormat',
        Format => 'int32u',
        Mask => 0x07000000,
        PrintConv => {
            0 => 'JPEG',
        },
    },
    0.3 => {
        Name => 'MPImageType',
        Format => 'int32u',
        Mask => 0x00ffffff,
        PrintHex => 1,
        PrintConv => {
            0x000000 => 'Undefined',
            0x010001 => 'Large Thumbnail (VGA equivalent)',
            0x010002 => 'Large Thumbnail (full HD equivalent)',
            0x020001 => 'Multi-frame Panorama',
            0x020002 => 'Multi-frame Disparity',
            0x020003 => 'Multi-angle',
            0x030000 => 'Baseline MP Primary Image',
        },
    },
    4 => {
        Name => 'MPImageLength',
        Format => 'int32u',
    },
    8 => {
        Name => 'MPImageStart',
        Format => 'int32u',
        IsOffset => '$val',
    },
    12 => {
        Name => 'DependentImage1EntryNumber',
        Format => 'int16u',
    },
    14 => {
        Name => 'DependentImage2EntryNumber',
        Format => 'int16u',
    },
);

%Image::ExifTool::MPF::Composite = (
    GROUPS => { 2 => 'Image' },
    MPImage => {
        Require => {
            0 => 'MPImageStart',
            1 => 'MPImageLength',
            2 => 'MPImageType',
        },
        Notes => q{
            the first MPF "Large Thumbnail" is extracted as PreviewImage, and the rest
            of the embedded MPF images are extracted as MPImage#.  The ExtractEmbedded
            option may be used to extract information from these embedded images.
        },
        # extract all MPF images (not just one)
        RawConv => q{
            require Image::ExifTool::MPF;
            Image::ExifTool::MPF::ExtractMPImages($self);
        },
    },
);

Image::ExifTool::AddCompositeTags('Image::ExifTool::MPF');

sub ExtractMPImages($)
{
    my $exifTool = shift;
    my $ee = $exifTool->Options('ExtractEmbedded');
    my $saveBinary = $exifTool->Options('Binary');
    my ($i, $didPreview, $xtra);

    for ($i=1; $xtra or not defined $xtra; ++$i) {
        # run through MP images in the same order they were extracted
        $xtra = defined $$exifTool{VALUE}{"MPImageStart ($i)"} ? " ($i)" : '';
        my $off = $exifTool->GetValue("MPImageStart$xtra");
        my $len = $exifTool->GetValue("MPImageLength$xtra");
        if ($off and $len) {
            my $type = $exifTool->GetValue("MPImageType$xtra", 'ValueConv');
            my $tag = "MPImage$i";
            # store first "Large Thumbnail" as a PreviewImage
            if (not $didPreview and $type and ($type & 0x0f0000) == 0x010000) {
                $tag = 'PreviewImage';
                $didPreview = 1;
            }
            $exifTool->Options('Binary', 1) if $ee;
            my $val = Image::ExifTool::Exif::ExtractImage($exifTool, $off, $len, $tag);
            $exifTool->Options('Binary', $saveBinary) if $ee;
            next unless defined $val;
            unless ($Image::ExifTool::Extra{$tag}) {
                Image::ExifTool::AddTagToTable(\%Image::ExifTool::Extra, $tag, {
                    Name => $tag,
                    Groups => { 0 => 'Composite', 1 => 'Composite', 2 => 'Image'},
                });
            }
            my $key = $exifTool->FoundTag($tag, $val);
            # set groups for PreviewImage
            if ($tag eq 'PreviewImage') {
                $exifTool->SetGroup($key, 'Composite', 0);
                $exifTool->SetGroup($key, 'Composite');
            }
            # extract information from MP images if ExtractEmbedded option used
            if ($ee) {
                $$exifTool{DOC_NUM} = $i;
                $exifTool->ExtractInfo($val, { ReEntry => 1 });
                delete $$exifTool{DOC_NUM};
            }
        }
    }
    return undef;
}

sub ProcessMPImageList($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $num = int($$dirInfo{DirLen} / 16); # (16 bytes per MP Entry)
    $$dirInfo{DirLen} = 16;
    my ($i, $success);
    my $oldG1 = $$exifTool{SET_GROUP1};
    for ($i=0; $i<$num; ++$i) {
        $$exifTool{SET_GROUP1} = '+' . ($i + 1);
        $success = $exifTool->ProcessBinaryData($dirInfo, $tagTablePtr);
        $$dirInfo{DirStart} += 16;
    }
    $$exifTool{SET_GROUP1} = $oldG1;
    return $success;
}

1;  # end

__END__


