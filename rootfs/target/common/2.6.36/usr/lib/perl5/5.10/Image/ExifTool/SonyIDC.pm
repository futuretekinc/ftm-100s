
package Image::ExifTool::SonyIDC;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.02';

%Image::ExifTool::SonyIDC::Main = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Image' },
    NOTES => 'Tags written by the Sony Image Data Converter utility in ARW images.',
    SET_GROUP1 => 1,
    0x201 => {
        Name => 'IDCPreviewStart',
        IsOffset => 1,
        OffsetPair => 0x202,
        DataTag => 'IDCPreview',
        Writable => 'int32u',
        Protected => 2,
    },
    0x202 => {
        Name => 'IDCPreviewLength',
        OffsetPair => 0x201,
        DataTag => 'IDCPreview',
        Writable => 'int32u',
        Protected => 2,
    },
    0x8000 => {
        Name => 'IDCCreativeStyle',
        Writable => 'int32u',
        PrintConvColumns => 2,
        PrintConv => {
            1 => 'Camera Setting',
            2 => 'Standard',
            3 => 'Real',
            4 => 'Vivid',
            5 => 'Adobe RGB',
            6 => 'A100 Standard', # shows up as '-' in IDC menu
            7 => 'Neutral',
            8 => 'Portrait',
            9 => 'Landscape',
            10 => 'Clear',
            11 => 'Deep',
            12 => 'Light',
            13 => 'Sunset',
            14 => 'Night View',
            15 => 'Autumn Leaves',
            16 => 'B&W',
            17 => 'Sepia',
        },
    },
    0x8001 => {
        Name => 'CreativeStyleWasChanged',
        Writable => 'int32u',
        Notes => 'set if the creative style was ever changed',
        #        (even if it was changed back again later)
        PrintConv => { 0 => 'No', 1 => 'Yes' },
    },
    0x8002 => {
        Name => 'PresetWhiteBalance',
        Writable => 'int32u',
        PrintConv => {
            1 => 'Camera Setting',
            2 => 'Color Temperature',
            3 => 'Specify Gray Point',
            4 => 'Daylight',
            5 => 'Cloudy',
            6 => 'Shade',
            7 => 'Cool White Fluorescent',
            8 => 'Day Light Fluorescent',
            9 => 'Day White Fluorescent',
            10 => 'Warm White Fluorescent',
            11 => 'Tungsten',
            12 => 'Flash',
            13 => 'Auto',
        },
    },
    0x8013 => { Name => 'ColorTemperatureAdj',  Writable => 'int16u' },
    0x8014 => { Name => 'PresetWhiteBalanceAdj',Writable => 'int32s' },
    0x8015 => { Name => 'ColorCorrection',      Writable => 'int32s' },
    0x8016 => { Name => 'SaturationAdj',        Writable => 'int32s' },
    0x8017 => { Name => 'ContrastAdj',          Writable => 'int32s' },
    0x8018 => { Name => 'BrightnessAdj',        Writable => 'int32s' },
    0x8019 => { Name => 'HueAdj',               Writable => 'int32s' },
    0x801a => { Name => 'SharpnessAdj',         Writable => 'int32s' },
    0x801b => { Name => 'SharpnessOvershoot',   Writable => 'int32s' },
    0x801c => { Name => 'SharpnessUndershoot',  Writable => 'int32s' },
    0x801d => { Name => 'SharpnessThreshold',   Writable => 'int32s' },
    0x801e => {
        Name => 'NoiseReductionMode',
        Writable => 'int16u',
        PrintConv => {
            0 => 'Off',
            1 => 'On',
        },
    },
    0x8021 => {
        Name => 'GrayPoint',
        Writable => 'int16u',
        Count => 4,
    },
    0x8022 => {
        Name => 'D-RangeOptimizerMode',
        Writable => 'int16u',
        PrintConv => {
            0 => 'Off',
            1 => 'Auto',
            2 => 'Manual',
        },
    },
    0x8023 => { Name => 'D-RangeOptimizerValue',    Writable => 'int32s' },
    0x8024 => { Name => 'D-RangeOptimizerHighlight',Writable => 'int32s' },
    0x8026 => {
        Name => 'HighlightColorDistortReduct',
        Writable => 'int16u',
        PrintConv => {
            0 => 'Standard',
            1 => 'Advanced',
        },
    },
    0x8027 => {
        Name => 'NoiseReductionValue',
        Writable => 'int32s',
        ValueConv => '($val + 100) / 2',
        ValueConvInv => '$val * 2 - 100',
    },
    0x8028 => {
        Name => 'EdgeNoiseReduction',
        Writable => 'int32s',
        ValueConv => '($val + 100) / 2',
        ValueConvInv => '$val * 2 - 100',
    },
    0x8029 => {
        Name => 'ColorNoiseReduction',
        Writable => 'int32s',
        ValueConv => '($val + 100) / 2',
        ValueConvInv => '$val * 2 - 100',
    },
    0x802d => { Name => 'D-RangeOptimizerShadow',       Writable => 'int32s' },
    0x8030 => { Name => 'PeripheralIllumCentralRadius', Writable => 'int32s' },
    0x8031 => { Name => 'PeripheralIllumCentralValue',  Writable => 'int32s' },
    0x8032 => { Name => 'PeripheralIllumPeriphValue',   Writable => 'int32s' },
    0x9000 => {
        Name => 'ToneCurveBrightnessX',
        Writable => 'int16u',
        Count => -1,
    },
    0x9001 => {
        Name => 'ToneCurveRedX',
        Writable => 'int16u',
        Count => -1,
    },
    0x9002 => {
        Name => 'ToneCurveGreenX',
        Writable => 'int16u',
        Count => -1,
    },
    0x9003 => {
        Name => 'ToneCurveBlueX',
        Writable => 'int16u',
        Count => -1,
    },
    0x9004 => {
        Name => 'ToneCurveBrightnessY',
        Writable => 'int16u',
        Count => -1,
    },
    0x9005 => {
        Name => 'ToneCurveRedY',
        Writable => 'int16u',
        Count => -1,
    },
    0x9006 => {
        Name => 'ToneCurveGreenY',
        Writable => 'int16u',
        Count => -1,
    },
    0x9007 => {
        Name => 'ToneCurveBlueY',
        Writable => 'int16u',
        Count => -1,
    },
    0xd000 => { Name => 'CurrentVersion',   Writable => 'int32u' },
    0xd001 => {
        Name => 'VersionIFD',
        Groups => { 1 => 'Version0' },
        Flags => 'SubIFD',
        Notes => 'there is one VersionIFD for each entry in the "Version Stack"',
        SubDirectory => {
            DirName => 'Version0',
            TagTable => 'Image::ExifTool::SonyIDC::Main',
            Start => '$val',
            Base => '$start',
            MaxSubdirs => 20,   # (IDC v3.0 writes max. 10)
            RelativeBase => 1,  # needed to write SubIFD with relative offsets
        },
    },
    0xd100 => {
        Name => 'VersionCreateDate',
        Writable => 'string',
        Groups => { 2 => 'Time' },
        Notes => 'date/time when this entry was created in the "Version Stack"',
        Shift => 'Time',
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,0)',
    },
    0xd101 => {
        Name => 'VersionModifyDate',
        Writable => 'string',
        Groups => { 2 => 'Time' },
        Shift => 'Time',
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,0)',
    },
);

%Image::ExifTool::SonyIDC::Composite = (
    GROUPS => { 2 => 'Image' },
    IDCPreviewImage => {
        Require => {
            0 => 'IDCPreviewStart',
            1 => 'IDCPreviewLength',
        },
        # extract all preview images (not just one)
        RawConv => q{
            require Image::ExifTool::SonyIDC;
            Image::ExifTool::SonyIDC::ExtractPreviews($self);
        },
    },
);

Image::ExifTool::AddCompositeTags('Image::ExifTool::SonyIDC');

{
    my $key;
    foreach $key (TagTableKeys(\%Image::ExifTool::SonyIDC::Main)) {
        $Image::ExifTool::SonyIDC::Main{$key}{Permanent} = 1;
    }
}

sub ExtractPreviews($)
{
    my $exifTool = shift;
    my $i = 1;
    my $xtra = ' (1)';
    my $preview;
    # loop through all available IDC preview images in the order they were found
    for (;;) {
        my $key = "IDCPreviewStart$xtra";
        unless (defined $$exifTool{VALUE}{$key}) {
            last unless $xtra;
            $xtra = ''; # do the last tag extracted last
            next;
        }
        # run through IDC preview images in the same order they were extracted
        my $off = $exifTool->GetValue($key) or last;
        my $len = $exifTool->GetValue("IDCPreviewLength$xtra") or last;
        # get stack version from number in group 1 name
        my $grp1 = $exifTool->GetGroup($key, 1);
        if ($grp1 =~ /(\d+)$/) {
            my $tag = "IDCPreviewImage$1";
            unless ($Image::ExifTool::Extra{$tag}) {
                Image::ExifTool::AddTagToTable(\%Image::ExifTool::Extra, $tag, {
                    Name => $tag,
                    Groups => { 0 => 'Composite', 1 => 'Composite', 2 => 'Image'},
                });
            }
            my $val = Image::ExifTool::Exif::ExtractImage($exifTool, $off, $len, $tag);
            $exifTool->FoundTag($tag, $val);
        } else {
            $preview = Image::ExifTool::Exif::ExtractImage($exifTool, $off, $len, 'IDCPreviewImage');
        }
        # step to next set of tags unless we are done
        last unless $xtra;
        ++$i;
        $xtra = " ($i)";
    }
    return $preview;
}

1;  # end

__END__


