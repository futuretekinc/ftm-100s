
package Image::ExifTool::Panasonic;

use strict;
use vars qw($VERSION %leicaLensTypes);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::Exif;

$VERSION = '1.60';

sub ProcessPanasonicType2($$$);
sub WhiteBalanceConv($;$$);

%leicaLensTypes = (
    OTHER => sub {
        my ($val, $inv, $conv) = @_;
        return undef if $inv or not $val =~ s/ .*//;
        return $$conv{$val};
    },
    Notes => q{
        Entries with 2 numbers give the lower 2 bits of the LensType value which are
        used to identify certain manually coded lenses on the M9, or the focal
        length of some multi-focal lenses.
    },
    # All M9 codes (two numbers: first the LensID then the lower 2 bits)
    # are ref PH with samples from ref 13.  From ref 10, the lower 2 bits of
    # the LensType value give the frame selector position for most lenses,
    # although for the 28-35-50mm (at least) it gives the focal length selection.
    # The M9 also gives the focal length selection but for other lenses the
    # lower 3 bits don't change with frame selector position except for the lens
    # shows as uncoded for certain lenses and some incorrect positions of the
    # frame selector.  The bits are zero for uncoded lenses when manually coding
    # from the menu on the M9. - PH
    # Frame selector bits (from ref 10, M8):
    #   1 => '28/90mm frame lines engaged',
    #   2 => '24/35mm frame lines engaged',
    #   3 => '50/75mm frame lines engaged',
    '0 0' => 'Uncoded lens',
                                            # model number(s):
    1 => 'Elmarit-M 21mm f/2.8',            # 11134
    3 => 'Elmarit-M 28mm f/2.8 (III)',      # 11804
    4 => 'Tele-Elmarit-M 90mm f/2.8 (II)',  # 11800
    5 => 'Summilux-M 50mm f/1.4 (II)',      # 11868/11856/11114
    6 => 'Summicron-M 35mm f/2 (IV)',       # 11310/11311
    '6 0' => 'Summilux-M 35mm f/1.4',       # 11869/11870/11860
    7 => 'Summicron-M 90mm f/2 (II)',       # 11136/11137
    9 => 'Elmarit-M 135mm f/2.8 (I/II)',    # 11829
    '9 0' => 'Apo-Telyt-M 135mm f/3.4',     # 11889
    16 => 'Tri-Elmar-M 16-18-21mm f/4 ASPH.',# 11626
    '16 1' => 'Tri-Elmar-M 16-18-21mm f/4 ASPH. (at 16mm)',
    '16 2' => 'Tri-Elmar-M 16-18-21mm f/4 ASPH. (at 18mm)',
    '16 3' => 'Tri-Elmar-M 16-18-21mm f/4 ASPH. (at 21mm)',
    23 => 'Summicron-M 50mm f/2 (III)',     # 11817, version (I) in camera menu
    24 => 'Elmarit-M 21mm f/2.8 ASPH.',     # 11135/11897
    25 => 'Elmarit-M 24mm f/2.8 ASPH.',     # 11878/11898
    26 => 'Summicron-M 28mm f/2 ASPH.',     # 11604
    27 => 'Elmarit-M 28mm f/2.8 (IV)',      # 11809
    28 => 'Elmarit-M 28mm f/2.8 ASPH.',     # 11606
    29 => 'Summilux-M 35mm f/1.4 ASPH.',    # 11874/11883
    '29 0' => 'Summilux-M 35mm f/1.4 ASPHERICAL', # 11873 (different from "ASPH." model!)
    30 => 'Summicron-M 35mm f/2 ASPH.',     # 11879/11882
    31 => 'Noctilux-M 50mm f/1',            # 11821/11822
    '31 0' => 'Noctilux-M 50mm f/1.2',      # 11820
    32 => 'Summilux-M 50mm f/1.4 ASPH.',    # 11891/11892
    33 => 'Summicron-M 50mm f/2 (IV, V)',   # 11819/11825/11826/11816, version (II,III) in camera menu
    34 => 'Elmar-M 50mm f/2.8',             # 11831/11823/11825
    35 => 'Summilux-M 75mm f/1.4',          # 11814/11815/11810
    36 => 'Apo-Summicron-M 75mm f/2 ASPH.', # 11637
    37 => 'Apo-Summicron-M 90mm f/2 ASPH.', # 11884/11885
    38 => 'Elmarit-M 90mm f/2.8',           # 11807/11808, version (II) in camera menu
    39 => 'Macro-Elmar-M 90mm f/4',         # 11633/11634
    '39 0' => 'Tele-Elmar-M 135mm f/4 (II)',# 11861
    40 => 'Macro-Adapter M',                # 14409
    42 => 'Tri-Elmar-M 28-35-50mm f/4 ASPH.',# 11625
    '42 1' => 'Tri-Elmar-M 28-35-50mm f/4 ASPH. (at 28mm)',
    '42 2' => 'Tri-Elmar-M 28-35-50mm f/4 ASPH. (at 35mm)',
    '42 3' => 'Tri-Elmar-M 28-35-50mm f/4 ASPH. (at 50mm)',
    43 => 'Summarit-M 35mm f/2.5',          # ? (ref PH)
    44 => 'Summarit-M 50mm f/2.5',          # ? (ref PH)
    45 => 'Summarit-M 75mm f/2.5',          # ? (ref PH)
    46 => 'Summarit-M 90mm f/2.5',          # ?
    47 => 'Summilux-M 21mm f/1.4 ASPH.',    # ? (ref 11)
    48 => 'Summilux-M 24mm f/1.4 ASPH.',    # ? (ref 11)
    49 => 'Noctilux-M 50mm f/0.95 ASPH.',   # ? (ref 11)
    50 => 'Elmar-M 24mm f/3.8 ASPH.',       # ? (ref 11)
    51 => 'Super-Elmar-M 21mm f/3.4 Asph',  # ? (ref 16, frameSelectorBits=1)
    '51 2' => 'Super-Elmar-M 14mm f/3.8 Asph', # ? (ref 16)
    52 => 'Super-Elmar-M 18mm f/3.8 ASPH.', # ? (ref PH/11)
    53 => 'Apo-Telyt-M 135mm f/3.4',        # ? (ref 16)

);

my %frameSelectorBits = (
    1 => 1,
    3 => 1,
    4 => 1,
    5 => 3,
    6 => 2,
    7 => 1,
    9 => 1, # (because lens has special magnifier for the rangefinder)
    16 => 1, # or 2 or 3
    23 => 3,
    24 => 1,
    25 => 2,
    26 => 1,
    27 => 1,
    28 => 1,
    29 => 2,
    30 => 2,
    31 => 3,
    32 => 3,
    33 => 3,
    34 => 3,
    35 => 3,
    36 => 3,
    37 => 1,
    38 => 1,
    39 => 1,
    40 => 1,
    42 => 1, # or 2 or 3
    43 => 2, # (NC)
    44 => 3, # (NC)
    45 => 3,
    46 => 1, # (NC)
    47 => 1, # (NC)
    48 => 2, # (NC)
    49 => 3, # (NC)
    50 => 2, # (NC)
    51 => 1, # or 2 (ref 16)
    52 => 3,
    53 => 2, #16
);

my %shootingMode = (
    1  => 'Normal',
    2  => 'Portrait',
    3  => 'Scenery',
    4  => 'Sports',
    5  => 'Night Portrait',
    6  => 'Program',
    7  => 'Aperture Priority',
    8  => 'Shutter Priority',
    9  => 'Macro',
    10 => 'Spot', #7
    11 => 'Manual',
    12 => 'Movie Preview', #PH (LZ6)
    13 => 'Panning',
    14 => 'Simple', #PH (LZ6)
    15 => 'Color Effects', #7
    16 => 'Self Portrait', #PH (TZ5)
    17 => 'Economy', #7
    18 => 'Fireworks',
    19 => 'Party',
    20 => 'Snow',
    21 => 'Night Scenery',
    22 => 'Food', #7
    23 => 'Baby', #JD
    24 => 'Soft Skin', #PH (LZ6)
    25 => 'Candlelight', #PH (LZ6)
    26 => 'Starry Night', #PH (LZ6)
    27 => 'High Sensitivity', #7 (LZ6)
    28 => 'Panorama Assist', #7
    29 => 'Underwater', #7
    30 => 'Beach', #PH (LZ6)
    31 => 'Aerial Photo', #PH (LZ6)
    32 => 'Sunset', #PH (LZ6)
    33 => 'Pet', #JD
    34 => 'Intelligent ISO', #PH (LZ6)
    35 => 'Clipboard', #7
    36 => 'High Speed Continuous Shooting', #7
    37 => 'Intelligent Auto', #7
    39 => 'Multi-aspect', #PH (TZ5)
    41 => 'Transform', #PH (FS7)
    42 => 'Flash Burst', #PH (FZ28)
    43 => 'Pin Hole', #PH (FZ28)
    44 => 'Film Grain', #PH (FZ28)
    45 => 'My Color', #PH (GF1)
    46 => 'Photo Frame', #PH (FS7)
    51 => 'HDR', #12
);

%Image::ExifTool::Panasonic::Main = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Camera' },
    WRITABLE => 1,
    0x01 => {
        Name => 'ImageQuality',
        Writable => 'int16u',
        PrintConv => {
            2 => 'High',
            3 => 'Normal',
            6 => 'Very High', #3 (Leica)
            7 => 'Raw', #3 (Leica)
            9 => 'Motion Picture', #PH (LZ6)
        },
    },
    0x02 => {
        Name => 'FirmwareVersion',
        Writable => 'undef',
        Notes => q{
            for some camera models such as the FZ30 this may be an internal production
            reference number and not the actual firmware version
        }, # (ref http://www.stevesforums.com/forums/view_topic.php?id=87764&forum_id=23&)
        # (can be either binary or ascii -- add decimal points if binary)
        ValueConv => '$val=~/[\0-\x2f]/ ? join(" ",unpack("C*",$val)) : $val',
        ValueConvInv => q{
            $val =~ /(\d+ ){3}\d+/ and $val = pack('C*',split(' ', $val));
            length($val) == 4 or warn "Version must be 4 numbers\n";
            return $val;
        },
        PrintConv => '$val=~tr/ /./; $val',
        PrintConvInv => '$val=~tr/./ /; $val',
    },
    0x03 => {
        Name => 'WhiteBalance',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Auto',
            2 => 'Daylight',
            3 => 'Cloudy',
            4 => 'Incandescent', #PH
            5 => 'Manual',
            8 => 'Flash',
            10 => 'Black & White', #3 (Leica)
            11 => 'Manual', #PH (FZ8)
            12 => 'Shade', #PH (FS7)
        },
    },
    0x07 => {
        Name => 'FocusMode',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Auto',
            2 => 'Manual',
            4 => 'Auto, Focus button', #4
            5 => 'Auto, Continuous', #4
            # have seens 6 for GF1 - PH
        },
    },
    0x0f => [
        {
            Name => 'AFAreaMode',
            Condition => '$$self{Model} =~ /DMC-FZ10\b/', #JD
            Writable => 'int8u',
            Count => 2,
            Notes => 'DMC-FZ10',
            PrintConv => {
                '0 1'   => 'Spot Mode On',
                '0 16'  => 'Spot Mode Off',
            },
        },{
            Name => 'AFAreaMode',
            Writable => 'int8u',
            Count => 2,
            Notes => 'other models',
            PrintConv => { #PH
                '0 1'   => '9-area', # (FS7)
                '0 16'  => '3-area (high speed)', # (FZ8)
                '1 0'   => 'Spot Focusing', # (FZ8)
                '1 1'   => '5-area', # (FZ8)
                '16'    => 'Normal?', # (only mode for DMC-LC20)
                '16 0'  => '1-area', # (FZ8)
                '16 16' => '1-area (high speed)', # (FZ8)
                '32 0'  => 'Auto or Face Detect', # (Face Detect for FS7, Auto is DMC-L1 guess)
                '32 1'  => '3-area (left)?', # (DMC-L1 guess)
                '32 2'  => '3-area (center)?', # (DMC-L1 guess)
                '32 3'  => '3-area (right)?', # (DMC-L1 guess)
                '64 0'  => 'Face Detect',
            },
        },
    ],
    0x1a => {
        Name => 'ImageStabilization',
        Writable => 'int16u',
        PrintConv => {
            2 => 'On, Mode 1',
            3 => 'Off',
            4 => 'On, Mode 2',
            # GF1 also has a mode 3
        },
    },
    0x1c => {
        Name => 'MacroMode',
        Writable => 'int16u',
        PrintConv => {
            1 => 'On',
            2 => 'Off',
            0x101 => 'Tele-Macro', #7
            0x201 => 'Macro Zoom', #PH (FS7)
        },
    },
    0x1f => {
        Name => 'ShootingMode',
        Writable => 'int16u',
        PrintConvColumns => 2,
        PrintConv => \%shootingMode,
    },
    0x20 => {
        Name => 'Audio',
        Writable => 'int16u',
        PrintConv => { 1 => 'Yes', 2 => 'No' },
    },
    0x21 => { #2
        Name => 'DataDump',
        Writable => 0,
        Binary => 1,
    },
    # 0x22 - normally 0, but 2 for 'Simple' ShootingMode in LZ6 sample - PH
    0x23 => {
        Name => 'WhiteBalanceBias',
        Format => 'int16s',
        Writable => 'int16s',
        ValueConv => '$val / 3',
        ValueConvInv => '$val * 3',
        PrintConv => 'Image::ExifTool::Exif::PrintFraction($val)',
        PrintConvInv => 'Image::ExifTool::Exif::ConvertFraction($val)',
    },
    0x24 => {
        Name => 'FlashBias',
        Format => 'int16s',
        Writable => 'int16s',
    },
    0x25 => { #PH
        Name => 'InternalSerialNumber',
        Writable => 'undef',
        Count => 16,
        Notes => q{
            this number is unique, and contains the date of manufacture, but is not the
            same as the number printed on the camera body
        },
        PrintConv => q{
            return $val unless $val=~/^([A-Z]\d{2})(\d{2})(\d{2})(\d{2})(\d{4})/;
            my $yr = $2 + ($2 < 70 ? 2000 : 1900);
            return "($1) $yr:$3:$4 no. $5";
        },
        PrintConvInv => '$_=$val; tr/A-Z0-9//dc; s/(.{3})(19|20)/$1/; $_',
    },
    0x26 => { #PH
        Name => 'PanasonicExifVersion',
        Writable => 'undef',
    },
    # 0x27 - values: 0 (LZ6,FX10K)
    0x28 => {
        Name => 'ColorEffect',
        Writable => 'int16u',
        # FX30 manual: (ColorMode) natural, vivid, cool, warm, b/w, sepia
        PrintConv => {
            1 => 'Off',
            2 => 'Warm',
            3 => 'Cool',
            4 => 'Black & White',
            5 => 'Sepia',
            6 => 'Happy', #PH (FX70) (yes, really. you wouldn't want sad colors now would you?)
        },
    },
    0x29 => { #JD
        Name => 'TimeSincePowerOn',
        Writable => 'int32u',
        Notes => q{
            time in 1/100 s from when the camera was powered on to when the image is
            written to memory card
        },
        ValueConv => '$val / 100',
        ValueConvInv => '$val * 100',
        PrintConv => sub { # convert to format "[DD days ]HH:MM:SS.ss"
            my $val = shift;
            my $str = '';
            if ($val >= 24 * 3600) {
                my $d = int($val / (24 * 3600));
                $str .= "$d days ";
                $val -= $d * 24 * 3600;
            }
            my $h = int($val / 3600);
            $val -= $h * 3600;
            my $m = int($val / 60);
            $val -= $m * 60;
            my $s = int($val);
            my $f = 100 * ($val - int($val));
            return sprintf("%s%.2d:%.2d:%.2d.%.2d",$str,$h,$m,$s,$f);
        },
        PrintConvInv => sub {
            my $val = shift;
            my @vals = ($val =~ /\d+(?:\.\d*)?/g);
            my $sec = 0;
            $sec += 24 * 3600 * shift(@vals) if @vals > 3;
            $sec += 3600 * shift(@vals) if @vals > 2;
            $sec += 60 * shift(@vals) if @vals > 1;
            $sec += shift(@vals) if @vals;
            return $sec;
        },
    },
    0x2a => { #4
        Name => 'BurstMode',
        Writable => 'int16u',
        Notes => 'decoding may be different for some models',
        PrintConv => {
            0 => 'Off',
            1 => 'On', #PH (TZ5) [was "Low/High Quality" from ref 4]
            2 => 'Infinite',
            4 => 'Unlimited', #PH (TZ5)
        },
    },
    0x2b => { #4
        Name => 'SequenceNumber',
        Writable => 'int32u',
    },
    0x2c => [
        {
            Name => 'ContrastMode',
            Condition => '$$self{Model} !~ /^DMC-(FX10|G1|L1|L10|LC80|GF1|TZ10|ZS7)$/',
            Flags => 'PrintHex',
            Writable => 'int16u',
            Notes => q{
                this decoding seems to work for some models such as the LC1, LX2, FZ7, FZ8,
                FZ18 and FZ50, but may not be correct for other models such as the FX10, G1, L1,
                L10 and LC80
            },
            PrintConv => {
                0 => 'Normal',
                1 => 'Low',
                2 => 'High',
                # 3 - observed with LZ6 and TZ5 in Fireworks mode - PH
                # 5 - observed with FX01, FX40 and FP8 (EXIF contrast "Normal") - PH
                6 => 'Medium Low', #PH (FZ18)
                7 => 'Medium High', #PH (FZ18)
                # DMC-LC1 values:
                0x100 => 'Low',
                0x110 => 'Normal',
                0x120 => 'High',
            }
        },{
            Name => 'ContrastMode',
            Condition => '$$self{Model} eq "DMC-GF1"',
            Notes => 'these values are used by the GF1',
            Writable => 'int16u',
            PrintConv => {
                0 => '-2',
                1 => '-1',
                2 => 'Normal',
                3 => '+1',
                4 => '+2',
                # Note: Other Contrast tags will be "Normal" in any of these modes:
                7 => 'Nature (Color Film)',
                12 => 'Smooth (Color Film) or Pure (My Color)',
                17 => 'Dynamic (B&W Film)',
                22 => 'Smooth (B&W Film)',
                27 => 'Dynamic (Color Film)',
                32 => 'Vibrant (Color Film) or Expressive (My Color)',
                33 => 'Elegant (My Color)',
                37 => 'Nostalgic (Color Film)',
                41 => 'Dynamic Art (My Color)',
                42 => 'Retro (My Color)',
            },
        },{
            Name => 'ContrastMode',
            Condition => '$$self{Model} =~ /^DMC-(TZ10|ZS7)$/',
            Notes => 'these values are used by the TZ10 and ZS7',
            Writable => 'int16u',
            PrintConv => {
                0 => 'Normal',
                1 => '-2',
                2 => '+2',
                5 => '-1',
                6 => '+1',
            },
        },{
            Name => 'ContrastMode',
            Writable => 'int16u',
        },
    ],
    0x2d => {
        Name => 'NoiseReduction',
        Writable => 'int16u',
        PrintConv => {
            0 => 'Standard',
            1 => 'Low (-1)',
            2 => 'High (+1)',
            3 => 'Lowest (-2)', #JD
            4 => 'Highest (+2)', #JD
        },
    },
    0x2e => { #4
        Name => 'SelfTimer',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Off',
            2 => '10 s',
            3 => '2 s',
        },
    },
    # 0x2f - values: 1 (LZ6,FX10K)
    0x30 => { #7
        Name => 'Rotation',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Horizontal (normal)',
            3 => 'Rotate 180', #PH
            6 => 'Rotate 90 CW', #PH (ref 7 gives 270 CW)
            8 => 'Rotate 270 CW', #PH (ref 7 gives 90 CW)
        },
    },
    0x31 => { #PH (FS7)
        Name => 'AFAssistLamp',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Fired',
            2 => 'Enabled but Not Used',
            3 => 'Disabled but Required',
            4 => 'Disabled and Not Required',
            # have seen a value of 5 - PH
            # values possibly related to FOC-L? - JD
        },
    },
    0x32 => { #7
        Name => 'ColorMode',
        Writable => 'int16u',
        PrintConv => {
            0 => 'Normal',
            1 => 'Natural',
            2 => 'Vivid',
            # have seen 3 for GF2 - PH
        },
    },
    0x33 => { #JD
        Name => 'BabyAge',
        Writable => 'string',
        Notes => 'or pet age', #PH
        PrintConv => '$val eq "9999:99:99 00:00:00" ? "(not set)" : $val',
        PrintConvInv => '$val =~ /^\d/ ? $val : "9999:99:99 00:00:00"',
    },
    0x34 => { #7/PH
        Name => 'OpticalZoomMode',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Standard',
            2 => 'Extended',
        },
    },
    0x35 => { #9
        Name => 'ConversionLens',
        Writable => 'int16u',
        PrintConv => { #PH (unconfirmed)
            1 => 'Off',
            2 => 'Wide',
            3 => 'Telephoto',
            4 => 'Macro',
        },
    },
    0x36 => { #8
        Name => 'TravelDay',
        Writable => 'int16u',
        PrintConv => '$val == 65535 ? "n/a" : $val',
        PrintConvInv => '$val =~ /(\d+)/ ? $1 : $val',
    },
    # 0x37 - values: 0,1,2 (LZ6, 0 for movie preview); 257 (FX10K); 0,256 (TZ5, 0 for movie preview)
    # 0x38 - values: 0,1,2 (LZ6, same as 0x37); 1,2 (FX10K); 0,256 (TZ5, 0 for movie preview)
    0x39 => { #7 (L1/L10)
        Name => 'Contrast',
        Format => 'int16s',
        Writable => 'int16u',
        %Image::ExifTool::Exif::printParameter,
    },
    0x3a => {
        Name => 'WorldTimeLocation',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Home',
            2 => 'Destination',
        },
    },
    0x3b => { #PH (TZ5/FS7)
        # (tags 0x3b, 0x3e, 0x8008 and 0x8009 have the same values in all my samples - PH)
        Name => 'TextStamp',
        Writable => 'int16u',
        PrintConv => { 1 => 'Off', 2 => 'On' },
    },
    0x3c => { #PH
        Name => 'ProgramISO', # (maybe should rename this ISOSetting?)
        Writable => 'int16u',
        PrintConv => {
            OTHER => sub { return shift },
            65534 => 'Intelligent ISO', #PH (FS7)
            65535 => 'n/a',
        },
    },
    0x3d => { #PH
        Name => 'AdvancedSceneMode',
        Writable => 'int16u',
        # values for the FZ28 (SceneMode/AdvancedSceneMode, "*"=add mode name) - PH:
        # Portrait: 2/1=Normal*, 24/1=Soft Skin, 2/2=Outdoor*, 2/3=Indoor*, 2/4=Creative*
        # Scenery: 3/1=Normal*, 3/2=Nature, 3/3=Architecture, 3/4=Creative*
        # Sports: 4/1=Normal*, 4/2=Outdoor*, 4/3=Indoor*, 4/4=Creative*
        # Night Scenery: 5/1=Night Portrait, 21/1=*, 21/2=Illuminations, 21/4=Creative*
        # Macro (Close-up): 9/2=Flower, 22/1=Food, 9/3=Objects, 9/4=Creative*
        # - have seen value of 5 for TZ5 (Macro) and FS20 (Scenery and Intelligent Auto)
        #   --> I'm guessing this is "Auto" - PH
        # - values for HDR mode (ref 12): 1=Standard, 2=Art, 3=B&W
        PrintConv => {
            1 => 'Normal',
            2 => 'Outdoor/Illuminations/Flower/HDR Art',
            3 => 'Indoor/Architecture/Objects/HDR B&W',
            4 => 'Creative',
            5 => 'Auto',
            7 => 'Expressive', #(GF1)
            8 => 'Retro', #(GF1)
            9 => 'Pure', #(GF1)
            10 => 'Elegant', #(GF1)
            12 => 'Monochrome', #(GF1)
            13 => 'Dynamic Art', #(GF1)
            14 => 'Silhouette', #(GF1)
        },
    },
    0x3e => { #PH (TZ5/FS7)
        # (tags 0x3b, 0x3e, 0x8008 and 0x8009 have the same values in all my samples - PH)
        Name => 'TextStamp',
        Writable => 'int16u',
        PrintConv => { 1 => 'Off', 2 => 'On' },
    },
    0x3f => { #PH (TZ7)
        Name => 'FacesDetected',
        Writable => 'int16u',
    },
    0x40 => { #7 (L1/L10)
        Name => 'Saturation',
        Format => 'int16s',
        Writable => 'int16u',
        %Image::ExifTool::Exif::printParameter,
    },
    0x41 => { #7 (L1/L10)
        Name => 'Sharpness',
        Format => 'int16s',
        Writable => 'int16u',
        %Image::ExifTool::Exif::printParameter,
    },
    0x42 => { #7 (DMC-L1)
        Name => 'FilmMode',
        Writable => 'int16u',
        PrintConv => {
            0 => 'n/a', #PH (ie. FZ100 "Photo Frame" ShootingMode)
            1 => 'Standard (color)',
            2 => 'Dynamic (color)',
            3 => 'Nature (color)',
            4 => 'Smooth (color)',
            5 => 'Standard (B&W)',
            6 => 'Dynamic (B&W)',
            7 => 'Smooth (B&W)',
            # 8 => 'My Film 1'? (from owner manual)
            # 9 => 'My Film 2'?
            10 => 'Nostalgic', # GH1
            11 => 'Vibrant', # GH1
            # 12 => 'Multi Film'? (in the GH1 specs)
        },
    },
    # 0x43 - int16u: 2,3
    # 0x44 - int16u: 0,2500
    # 0x45 - int16u: 0
    0x46 => { #PH/JD
        Name => 'WBAdjustAB',
        Format => 'int16s',
        Writable => 'int16u',
        Notes => 'positive is a shift toward blue',
    },
    0x47 => { #PH/JD
        Name => 'WBAdjustGM',
        Format => 'int16s',
        Writable => 'int16u',
        Notes => 'positive is a shift toward green',
    },
    # 0x48 - int16u: 0
    # 0x49 - int16u: 2
    # 0x4a - int16u: 0
    0x4b => { #PH
        Name => 'PanasonicImageWidth',
        Writable => 'int32u',
    },
    0x4c => { #PH
        Name => 'PanasonicImageHeight',
        Writable => 'int32u',
    },
    0x4d => { #PH (FS7)
        Name => 'AFPointPosition',
        Writable => 'rational64u',
        Count => 2,
        Notes => 'X Y coordinates of primary AF area center, in the range 0.0 to 1.0',
        PrintConv => q{
            return 'none' if $val eq '16777216 16777216';
            my @a = split ' ', $val;
            sprintf("%.2g %.2g",@a);
        },
        PrintConvInv => '$val eq "none" ? "16777216 16777216" : $val',
    },
    0x4e => { #PH
        Name => 'FaceDetInfo',
        PrintConv => 'length $val',
        SubDirectory => {
            TagTable => 'Image::ExifTool::Panasonic::FaceDetInfo',
        },
    },
    # 0x4f,0x50 - int16u: 0
    0x51 => {
        Name => 'LensType',
        Writable => 'string',
    },
    0x52 => { #7 (DMC-L1)
        Name => 'LensSerialNumber',
        Writable => 'string',
    },
    0x53 => { #7 (DMC-L1)
        Name => 'AccessoryType',
        Writable => 'string',
    },
    # 0x54 - string[14]: "0000000"
    # 0x55 - int16u: 1
    # 0x57 - int16u: 0
    0x59 => { #PH (FS7)
        Name => 'Transform',
        Writable => 'undef',
        Notes => 'decoded as two 16-bit signed integers',
        Format => 'int16s',
        Count => 2,
        PrintConv => {
            '-3 2' => 'Slim High',
            '-1 1' => 'Slim Low',
            '0 0' => 'Off',
            '1 1' => 'Stretch Low',
            '3 2' => 'Stretch High',
        },
    },
    # 0x5a - int16u: 0,2
    # 0x5b - int16u: 0
    # 0x5c - int16u: 0,2
    0x5d => { #PH (GF1, FZ35)
        Name => 'IntelligentExposure',
        Notes => 'not valid for some models', # (doesn't change in ZS7 and GH1 images)
        Writable => 'int16u',
        PrintConv => {
            0 => 'Off',
            1 => 'Low',
            2 => 'Standard',
            3 => 'High',
        },
    },
    # 0x5e,0x5f,0x60 - undef[4]
    0x61 => { #PH
        Name => 'FaceRecInfo',
        SubDirectory => {
            TagTable => 'Image::ExifTool::Panasonic::FaceRecInfo',
        },
    },
    0x62 => { #PH (FS7)
        Name => 'FlashWarning',
        Writable => 'int16u',
        PrintConv => { 0 => 'No', 1 => 'Yes (flash required but disabled)' },
    },
    0x63 => { #PH
        # not sure exactly what this means, but in my samples this is
        # FacesRecognized bytes of 0x01, padded with 0x00 to a length of 4 - PH
        Name => 'RecognizedFaceFlags',
        Format => 'int8u',
        Count => 4,
        Writable => 'undef',
        Unknown => 1,
    },
    0x65 => { #15
        Name => 'Title',
        Format => 'string',
        Writable => 'undef', # (Count 64)
    },
    0x66 => { #15
        Name => 'BabyName',
        Notes => 'or pet name',
        Format => 'string',
        Writable => 'undef', # (Count 64)
    },
    0x67 => { #15
        Name => 'Location',
        Groups => { 2 => 'Location' },
        Format => 'string',
        Writable => 'undef', # (Count 64)
    },
    # 0x68 - int8u: 1
    0x69 => { #PH (ZS7)
        Name => 'Country', # (Country/Region)
        Groups => { 2 => 'Location' },
        Format => 'string',
        Writable => 'undef', # (Count 72)
    },
    # 0x6a - int8u: 1
    0x6b => { #PH (ZS7)
        Name => 'State', # (State/Province/Count -- what is Count?)
        Groups => { 2 => 'Location' },
        Format => 'string',
        Writable => 'undef', # (Count 72)
    },
    # 0x6c - int8u: 1
    0x6d => { #PH (ZS7)
        Name => 'City', # (City/Town)
        Groups => { 2 => 'Location' },
        Format => 'string',
        Writable => 'undef', # (Count 72)
    },
    # 0x6e - int8u: 1
    0x6f => { #PH (ZS7)
        Name => 'Landmark', # (Landmark)
        Groups => { 2 => 'Location' },
        Format => 'string',
        Writable => 'undef', # (Count 128)
    },
    0x70 => { #PH (ZS7)
        Name => 'IntelligentResolution',
        Writable => 'int8u',
        PrintConv => {
            0 => 'Off',
            # Note: I think these values make sense for the GH2, but meanings
            #       may be different for other models
            1 => 'Low',
            2 => 'Standard',
            3 => 'High',
            4 => 'Extended',
        },
    },
    # 0x71 - undef[128] (maybe text stamp text?)
    # 0x72,0x73,0x74,0x75,0x76,0x77,0x78: 0
    0x79 => { #PH (GH2)
        Name => 'IntelligentD-Range',
        Writable => 'int16u',
        PrintConv => {
            0 => 'Off',
            1 => 'Low',
            2 => 'Standard',
            3 => 'High',
        },
    },
    # 0x7a,0x7b: 0
    0x0e00 => {
        Name => 'PrintIM',
        Description => 'Print Image Matching',
        Writable => 0,
        SubDirectory => {
            TagTable => 'Image::ExifTool::PrintIM::Main',
        },
    },
    0x8000 => { #PH
        Name => 'MakerNoteVersion',
        Format => 'undef',
    },
    0x8001 => { #7/PH/JD
        Name => 'SceneMode',
        Writable => 'int16u',
        PrintConvColumns => 2,
        PrintConv => {
            0  => 'Off',
            %shootingMode,
        },
    },
    # 0x8002 - values: 1,2 related to focus? (PH/JD)
    #          1 for HDR modes, 2 for Portrait (ref 12)
    # 0x8003 - values: 1,2 related to focus? (PH/JD)
    0x8004 => { #PH/JD
        Name => 'WBRedLevel',
        Writable => 'int16u',
    },
    0x8005 => { #PH/JD
        Name => 'WBGreenLevel',
        Writable => 'int16u',
    },
    0x8006 => { #PH/JD
        Name => 'WBBlueLevel',
        Writable => 'int16u',
    },
    0x8007 => { #PH
        Name => 'FlashFired',
        Writable => 'int16u',
        PrintConv => { 1 => 'No', 2 => 'Yes' },
    },
    0x8008 => { #PH (TZ5/FS7)
        # (tags 0x3b, 0x3e, 0x8008 and 0x8009 have the same values in all my samples - PH)
        Name => 'TextStamp',
        Writable => 'int16u',
        PrintConv => { 1 => 'Off', 2 => 'On' },
    },
    0x8009 => { #PH (TZ5/FS7)
        # (tags 0x3b, 0x3e, 0x8008 and 0x8009 have the same values in all my samples - PH)
        Name => 'TextStamp',
        Writable => 'int16u',
        PrintConv => { 1 => 'Off', 2 => 'On' },
    },
    0x8010 => { #PH
        Name => 'BabyAge',
        Writable => 'string',
        Notes => 'or pet age',
        PrintConv => '$val eq "9999:99:99 00:00:00" ? "(not set)" : $val',
        PrintConvInv => '$val =~ /^\d/ ? $val : "9999:99:99 00:00:00"',
    },
    0x8012 => { #PH (FS7)
        Name => 'Transform',
        Writable => 'undef',
        Notes => 'decoded as two 16-bit signed integers',
        Format => 'int16s',
        Count => 2,
        PrintConv => {
            '-3 2' => 'Slim High',
            '-1 1' => 'Slim Low',
            '0 0' => 'Off',
            '1 1' => 'Stretch Low',
            '3 2' => 'Stretch High',
        },
    },
);

%Image::ExifTool::Panasonic::Leica2 = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    WRITABLE => 1,
    NOTES => 'These tags are used by the Leica M8.',
    0x300 => {
        Name => 'Quality',
        Writable => 'int16u',
        PrintConv => {
            1 => 'Fine',
            2 => 'Basic',
        },
    },
    0x302 => {
        Name => 'UserProfile',
        Writable => 'int32u',
        PrintConv => {
            1 => 'User Profile 1',
            2 => 'User Profile 2',
            3 => 'User Profile 3',
            4 => 'User Profile 0 (Dynamic)',
        },
    },
    0x303 => {
        Name => 'SerialNumber',
        Writable => 'int32u',
        PrintConv => 'sprintf("%.7d", $val)',
        PrintConvInv => '$val',
    },
    0x304 => {
        Name => 'WhiteBalance',
        Writable => 'int16u',
        Notes => 'values above 0x8000 are converted to Kelvin color temperatures',
        PrintConv => {
            0 => 'Auto or Manual',
            1 => 'Daylight',
            2 => 'Fluorescent',
            3 => 'Tungsten',
            4 => 'Flash',
            10 => 'Cloudy',
            11 => 'Shade',
            OTHER => \&WhiteBalanceConv,
        },
    },
    0x310 => {
        Name => 'LensType',
        Writable => 'int32u',
        SeparateTable => 1,
        ValueConv => '($val >> 2) . " " . ($val & 0x3)',
        ValueConvInv => \&LensTypeConvInv,
        PrintConv => \%leicaLensTypes,
    },
    0x311 => {
        Name => 'ExternalSensorBrightnessValue',
        Format => 'rational64s', # (incorrectly unsigned in JPEG images)
        Writable => 'rational64s',
        Notes => '"blue dot" measurement',
        PrintConv => 'sprintf("%.2f", $val)',
        PrintConvInv => '$val',
    },
    0x312 => {
        Name => 'MeasuredLV',
        Format => 'rational64s', # (incorrectly unsigned in JPEG images)
        Writable => 'rational64s',
        Notes => 'imaging sensor or TTL exposure meter measurement',
        PrintConv => 'sprintf("%.2f", $val)',
        PrintConvInv => '$val',
    },
    0x313 => {
        Name => 'ApproximateFNumber',
        Writable => 'rational64u',
        PrintConv => 'sprintf("%.1f", $val)',
        PrintConvInv => '$val',
    },
    0x320 => {
        Name => 'CameraTemperature',
        Writable => 'int32s',
        PrintConv => '"$val C"',
        PrintConvInv => '$val=~s/ ?C//; $val',
    },
    0x321 => { Name => 'ColorTemperature',  Writable => 'int32u' },
    0x322 => { Name => 'WBRedLevel',        Writable => 'rational64u' },
    0x323 => { Name => 'WBGreenLevel',      Writable => 'rational64u' },
    0x324 => { Name => 'WBBlueLevel',       Writable => 'rational64u' },
    0x325 => {
        Name => 'UV-IRFilterCorrection',
        Description => 'UV/IR Filter Correction',
        Writable => 'int32u',
        PrintConv => {
            0 => 'Not Active',
            1 => 'Active',
        },
    },
    0x330 => { Name => 'CCDVersion',        Writable => 'int32u' },
    0x331 => { Name => 'CCDBoardVersion',   Writable => 'int32u' },
    0x332 => { Name => 'ControllerBoardVersion', Writable => 'int32u' },
    0x333 => { Name => 'M16CVersion',       Writable => 'int32u' },
    0x340 => { Name => 'ImageIDNumber',     Writable => 'int32u' },
);

%Image::ExifTool::Panasonic::Leica3 = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    WRITABLE => 1,
    NOTES => 'These tags are used by the Leica R8 and R9 digital backs.',
    0x0d => {
        Name => 'WB_RGBLevels',
        Writable => 'int16u',
        Count => 3,
    },
);

%Image::ExifTool::Panasonic::Leica4 = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    WRITABLE => 1,
    NOTES => 'This information is written by the M9.',
    0x3000 => {
        Name => 'Subdir3000',
        SubDirectory => {
            TagTable => 'Image::ExifTool::Panasonic::Subdir',
            ByteOrder => 'Unknown',
        },
    },
    0x3100 => {
        Name => 'Subdir3100',
        SubDirectory => {
            TagTable => 'Image::ExifTool::Panasonic::Subdir',
            ByteOrder => 'Unknown',
        },
    },
    0x3400 => {
        Name => 'Subdir3400',
        SubDirectory => {
            TagTable => 'Image::ExifTool::Panasonic::Subdir',
            ByteOrder => 'Unknown',
        },
    },
    0x3900 => {
        Name => 'Subdir3900',
        SubDirectory => {
            TagTable => 'Image::ExifTool::Panasonic::Subdir',
            ByteOrder => 'Unknown',
        },
    },
);

%Image::ExifTool::Panasonic::Subdir = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    TAG_PREFIX => 'Leica_Subdir',
    WRITABLE => 1,
    # 0x3001 - normally 0 but value of 2 when manual coding is used
    #          with a coded lens (but only tested with Elmar-M 50mm f/2.8) - PH
    0x300a => {
        Name => 'Contrast',
        Writable => 'int32u',
        PrintConv => {
            0 => 'Low',
            1 => 'Medium Low',
            2 => 'Normal',
            3 => 'Medium High',
            4 => 'High',
        },
    },
    0x300b => {
        Name => 'Sharpening',
        Writable => 'int32u',
        PrintConv => {
            0 => 'Off',
            1 => 'Low',
            2 => 'Normal',
            3 => 'Medium High',
            4 => 'High',
        },
    },
    0x300d => {
        Name => 'Saturation',
        Writable => 'int32u',
        PrintConv => {
            0 => 'Low',
            1 => 'Medium Low',
            2 => 'Normal',
            3 => 'Medium High',
            4 => 'High',
            5 => 'Black & White',
            6 => 'Vintage B&W',
        },
    },
    # 0x3032 - some sort of RGB coefficients? (zeros unless Kelvin WB, but same for all Color Temps)
    0x3033 => {
        Name => 'WhiteBalance',
        Writable => 'int32u',
        PrintConv => { #13
            0 => 'Auto',
            1 => 'Tungsten',
            2 => 'Fluorescent',
            3 => 'Daylight Fluorescent',
            4 => 'Daylight',
            5 => 'Flash',
            6 => 'Cloudy',
            7 => 'Shade',
            8 => 'Manual',
            9 => 'Kelvin',
        },
    },
    0x3034 => {
        Name => 'JPEGQuality',
        Writable => 'int32u',
        PrintConv => {
            94 => 'Basic',
            97 => 'Fine',
        },
    },
    # 0x3035 (int32u): -1 unless Manual WB (2 in my Manual sample)
    0x3036 => {
        Name => 'WB_RGBLevels',
        Writable => 'rational64u',
        Count => 3,
    },
    0x3038 => {
        Name => 'UserProfile', # (CameraProfile according to ref 14)
        Writable => 'string',
    },
    0x303a => {
        Name => 'JPEGSize',
        Writable => 'int32u',
        PrintConv => {
            0 => '5216x3472',
            1 => '3840x2592',
            2 => '2592x1728',
            3 => '1728x1152',
            4 => '1280x864',
        },
    },
    0x3103 => { #13 (valid for FW 1.116 and later)
        Name => 'SerialNumber',
        Writable => 'string',
    },
    # 0x3104 body-dependent string ("00012905000000") (not serial number)
    # 0x3105 body-dependent string ("00012905000000")
    # 0x3107 - body-dependent string ("4H205800116800") (not serial number)
    0x3109 => {
        Name => 'FirmwareVersion',
        Writable => 'string',
    },
    0x312a => { #14 (NC)
        Name => 'BaseISO',
        Writable => 'int32u',
    },
    0x312b => {
        Name => 'SensorWidth',
        Writable => 'int32u',
    },
    0x312c => {
        Name => 'SensorHeight',
        Writable => 'int32u',
    },
    0x312d => { #14 (NC)
        Name => 'SensorBitDepth',
        Writable => 'int32u',
    },
    0x3402 => { #PH/13
        Name => 'CameraTemperature',
        Writable => 'int32s',
        PrintConv => '"$val C"',
        PrintConvInv => '$val=~s/ ?C//; $val',
    },
    0x3405 => {
        Name => 'LensType',
        Writable => 'int32u',
        SeparateTable => 1,
        ValueConv => '($val >> 2) . " " . ($val & 0x3)',
        ValueConvInv => \&LensTypeConvInv,
        PrintConv => \%leicaLensTypes,
    },
    0x3406 => { #PH/13
        Name => 'ApproximateFNumber',
        Writable => 'rational64u',
        PrintConv => 'sprintf("%.1f", $val)',
        PrintConvInv => '$val',
    },
    0x3407 => { #14
        Name => 'MeasuredLV',
        Writable => 'int32s',
        Notes => 'imaging sensor or TTL exposure meter measurement',
        ValueConv => '$val / 1e5', #PH (NC)
        ValueConvInv => '$val * 1e5', #PH (NC)
        PrintConv => 'sprintf("%.2f", $val)',
        PrintConvInv => '$val',
    },
    0x3408 => { #14
        Name => 'ExternalSensorBrightnessValue',
        Writable => 'int32s',
        Notes => '"blue dot" measurement',
        ValueConv => '$val / 1e5', #PH (NC)
        ValueConvInv => '$val * 1e5', #PH (NC)
        PrintConv => 'sprintf("%.2f", $val)',
        PrintConvInv => '$val',
    },
    0x3901 => {
        Name => 'Data1',
        SubDirectory => { TagTable => 'Image::ExifTool::Panasonic::Data1' },
    },
    0x3902 => {
        Name => 'Data2',
        SubDirectory => { TagTable => 'Image::ExifTool::Panasonic::Data2' },
    },
    # 0x3903 - larger binary data block
);

%Image::ExifTool::Panasonic::Data1 = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    WRITE_PROC => \&Image::ExifTool::WriteBinaryData,
    CHECK_PROC => \&Image::ExifTool::CheckBinaryData,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    WRITABLE => 1,
    TAG_PREFIX => 'Leica_Data1',
    FIRST_ENTRY => 0,
    0x0016 => {
        Name => 'LensType',
        Writable => 'int32u',
        Priority => 0,
        SeparateTable => 1,
        ValueConv => '($val >> 2) . " " . ($val & 0x3)',
        ValueConvInv => \&LensTypeConvInv,
        PrintConv => \%leicaLensTypes,
    },
);

%Image::ExifTool::Panasonic::Data2 = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    TAG_PREFIX => 'Leica_Data2',
    FIRST_ENTRY => 0,
);

%Image::ExifTool::Panasonic::Leica5 = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    WRITABLE => 1,
    NOTES => 'This information is written by the X1.',
    # 0x0406 - saturation or sharpness
    0x0407 => { Name => 'OriginalFileName', Writable => 'string' },
    0x0408 => { Name => 'OriginalDirectory',Writable => 'string' },
    # 0x040b - related to white balance
    0x040d => {
        Name => 'ExposureMode',
        Format => 'int8u',
        Count => 4,
        PrintConv => {
            '0 0 0 0' => 'Program AE',
            '1 0 0 0' => 'Aperture-priority AE',
            '2 0 0 0' => 'Shutter speed priority AE', #(guess)
            '3 0 0 0' => 'Manual',
        },
    },
    # 0x0411 - saturation or sharpness
    0x0412 => { Name => 'FilmMode',         Writable => 'string' },
    0x0413 => { Name => 'WB_RGBLevels',     Writable => 'rational64u', Count => 3 },
);

%Image::ExifTool::Panasonic::Leica6 = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 1 => 'Leica', 2 => 'Camera' },
    NOTES => 'This information is written by the S2 (as a trailer in JPEG images).',
    0x300 => {
        Name => 'PreviewImage',
        Writable => 'undef',
        Notes => 'S2',
        DataTag => 'PreviewImage',
        RawConv => q{
            return \$val if $val =~ /^Binary/;
            return \$val if $val =~ /^\xff\xd8\xff/;
            $$self{PreviewError} = 1 unless $val eq 'none';
            return undef;
        },
        ValueConvInv => '$val || "none"',
        WriteCheck => 'return $val=~/^(none|\xff\xd8\xff)/s ? undef : "Not a valid image"',
        ChangeBase => '$dirStart + $dataPos - 8',
    },
    0x301 => {
        Name => 'UnknownBlock',
        Notes => 'unknown 320kB block, not copied to JPEG images',
        Flags => [ 'Unknown', 'Binary', 'Drop' ],
    },
    # 0x302 - same value as 4 unknown bytes at the end of JPEG or after the DNG TIFF header
    0x303 => {
        Name => 'LensType',
        Writable => 'string',
    },
    # 0x340 - same as 0x302
);

%Image::ExifTool::Panasonic::Type2 = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Image' },
    FIRST_ENTRY => 0,
    FORMAT => 'int16u',
    NOTES => q{
        This type of maker notes is used by models such as the NV-DS65, PV-D2002,
        PV-DC3000, PV-DV203, PV-DV401, PV-DV702, PV-L2001, PV-SD4090, PV-SD5000 and
        iPalm.
    },
    0 => {
        Name => 'MakerNoteType',
        Format => 'string[4]',
    },
    # seems to vary inversely with amount of light, so I'll call it 'Gain' - PH
    # (minimum is 16, maximum is 136.  Value is 0 for pictures captured from video)
    3 => 'Gain',
);

%Image::ExifTool::Panasonic::FaceDetInfo = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    WRITE_PROC => \&Image::ExifTool::WriteBinaryData,
    CHECK_PROC => \&Image::ExifTool::CheckBinaryData,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Image' },
    WRITABLE => 1,
    FORMAT => 'int16u',
    FIRST_ENTRY => 0,
    DATAMEMBER => [ 0 ],
    NOTES => 'Face detection position information.',
    0 => {
        Name => 'NumFacePositions',
        Format => 'int16u',
        DataMember => 'NumFacePositions',
        RawConv => '$$self{NumFacePositions} = $val',
        Notes => q{
            number of detected face positions stored in this record.  May be less than
            FacesDetected
        },
    },
    1 => {
        Name => 'Face1Position',
        Format => 'int16u[4]',
        RawConv => '$$self{NumFacePositions} < 1 ? undef : $val',
        Notes => q{
            4 numbers: X/Y coordinates of the face center and width/height of face. 
            Coordinates are relative to an image twice the size of the thumbnail, or 320
            pixels wide
        },
    },
    5 => {
        Name => 'Face2Position',
        Format => 'int16u[4]',
        RawConv => '$$self{NumFacePositions} < 2 ? undef : $val',
    },
    9 => {
        Name => 'Face3Position',
        Format => 'int16u[4]',
        RawConv => '$$self{NumFacePositions} < 3 ? undef : $val',
    },
    13 => {
        Name => 'Face4Position',
        Format => 'int16u[4]',
        RawConv => '$$self{NumFacePositions} < 4 ? undef : $val',
    },
    17 => {
        Name => 'Face5Position',
        Format => 'int16u[4]',
        RawConv => '$$self{NumFacePositions} < 5 ? undef : $val',
    },
);

%Image::ExifTool::Panasonic::FaceRecInfo = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    WRITE_PROC => \&Image::ExifTool::WriteBinaryData,
    CHECK_PROC => \&Image::ExifTool::CheckBinaryData,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Image' },
    WRITABLE => 1,
    FIRST_ENTRY => 0,
    DATAMEMBER => [ 0 ],
    NOTES => q{
        Tags written by cameras with facial recognition.  These cameras not only
        detect faces in an image, but also recognize specific people based a
        user-supplied set of known faces.
    },
    0 => {
        Name => 'FacesRecognized',
        Format => 'int16u',
        DataMember => 'FacesRecognized',
        RawConv => '$$self{FacesRecognized} = $val',
    },
    4 => {
        Name => 'RecognizedFace1Name',
        Format => 'string[20]',
        RawConv => '$$self{FacesRecognized} < 1 ? undef : $val',
    },
    24 => {
        Name => 'RecognizedFace1Position',
        Format => 'int16u[4]',
        RawConv => '$$self{FacesRecognized} < 1 ? undef : $val',
        Notes => 'coordinates in same format as face detection tags above',
    },
    32 => {
        Name => 'RecognizedFace1Age',
        Format => 'string[20]',
        RawConv => '$$self{FacesRecognized} < 1 ? undef : $val',
    },
    52 => {
        Name => 'RecognizedFace2Name',
        Format => 'string[20]',
        RawConv => '$$self{FacesRecognized} < 2 ? undef : $val',
    },
    72 => {
        Name => 'RecognizedFace2Position',
        Format => 'int16u[4]',
        RawConv => '$$self{FacesRecognized} < 2 ? undef : $val',
    },
    80 => {
        Name => 'RecognizedFace2Age',
        Format => 'string[20]',
        RawConv => '$$self{FacesRecognized} < 2 ? undef : $val',
    },
    100 => {
        Name => 'RecognizedFace3Name',
        Format => 'string[20]',
        RawConv => '$$self{FacesRecognized} < 3 ? undef : $val',
    },
    120 => {
        Name => 'RecognizedFace3Position',
        Format => 'int16u[4]',
        RawConv => '$$self{FacesRecognized} < 3 ? undef : $val',
    },
    128 => {
        Name => 'RecognizedFace3Age',
        Format => 'string[20]',
        RawConv => '$$self{FacesRecognized} < 3 ? undef : $val',
    },
);

sub LensTypeConvInv($)
{
    my $val = shift;
    if ($val =~ /^(\d+) (\d+)$/) {
        return ($1 << 2) + ($2 & 0x03);
    } elsif ($val =~ /^\d+$/) {
        my $bits = $frameSelectorBits{$val};
        return undef unless defined $bits;
        return ($val << 2) | $bits;
    } else {
        return undef;
    }
}

sub WhiteBalanceConv($;$$)
{
    my ($val, $inv) = @_;
    if ($inv) {
        return $1 + 0x8000 if $val =~ /(\d+)/;
    } else {
        return ($val - 0x8000) . ' Kelvin' if $val > 0x8000;
    }
    return undef;
}

sub ProcessLeicaTrailer($;$)
{
    my ($exifTool, $newPos) = @_;
    my $trail = $$exifTool{LeicaTrailer};
    my $raf = $$exifTool{RAF};
    my $trailPos = $$trail{TrailPos};
    my $pos = $trailPos || $$trail{Offset};
    my $len = $$trail{TrailLen} || $$trail{Size};
    my ($buff, $result, %tagPtr);

    delete $$exifTool{LeicaTrailer} if $trailPos;   # done after this
    unless ($len > 0) {
        $exifTool->Warn('Missing Leica MakerNote trailer', 1) if $trailPos;
        undef $$exifTool{LeicaTrailer};
        return undef;
    }
    my $oldPos = $raf->Tell();
    my $ok = ($raf->Seek($pos, 0) and $raf->Read($buff, $len) == $len);
    $raf->Seek($oldPos, 0);
    unless ($ok) {
        $exifTool->Warn('Error reading Leica MakerNote trailer', 1) if $trailPos;
        return undef;
    }
    # look for Leica MakerNote header (should be at start of
    # trailer, but allow up to 256 bytes of garbage just in case)
    if ($buff !~ /^(.{0,256})LEICA\0..../sg) {
        my $what = $trailPos ? 'trailer' : 'offset';
        $exifTool->Warn("Invalid Leica MakerNote $what", 1);
        return undef;
    }
    my $junk = $1;
    my $start = pos($buff) - 10;
    if ($start and not $trailPos) {
        $exifTool->Warn('Invalid Leica MakerNote offset', 1);
        return undef;
    }
    my $hdrLen = 8;
    my $dirStart = $start + $hdrLen;
    my $tagInfo = $$trail{TagInfo};
    if ($$exifTool{HTML_DUMP}) {
        my $name = $$tagInfo{Name};
        $exifTool->HDump($pos+$start, $len-$start, "$name value", 'Leica MakerNote trailer', 4);
        $exifTool->HDump($pos+$start, $hdrLen, "MakerNotes header", $name);
    } elsif ($exifTool->Options('Verbose')) {
        my $where = sprintf('at offset 0x%x', $pos);
        $exifTool->VPrint(0, "Leica MakerNote trailer ($len bytes $where):\n");
    }
    # delete LeicaTrailer member so we don't try to process it again
    delete $$exifTool{LeicaTrailer};
    $$exifTool{LeicaTrailerPos} = $pos + $start;    # return actual start position of Leica trailer

    my $oldOrder = GetByteOrder();
    my $num = Get16u(\$buff, $dirStart);            # get entry count
    ToggleByteOrder() if ($num>>8) > ($num&0xff);   # set byte order

    # use specialized algorithm to automatically fix offsets
    my $valStart = $dirStart + 2 + 12 * $num + 4;
    my $fix = 0;
    if ($valStart < $len) {
        my $valBlock = Image::ExifTool::MakerNotes::GetValueBlocks(\$buff, $dirStart, \%tagPtr);
        # find the minimum offset (excluding the PreviewImage tag 0x300)
        my $minPtr;
        foreach (keys %tagPtr) {
            my $ptr = $tagPtr{$_};
            next if $_ == 0x300 or not $ptr;
            $minPtr = $ptr if not defined $minPtr or $minPtr > $ptr;
        }
        if ($minPtr) {
            my $diff = $minPtr - ($valStart + $pos);
            # scan value data for the first non-zero byte
            pos($buff) = $valStart;
            if ($buff =~ /[^\0]/g) {
                my $n = pos($buff) - 1 - $valStart; # number of zero bytes
                # S2 writes 282 bytes of zeros, exiftool writes none
                my $expect = $n >= 282 ? 282 : 0;
                my $fixBase = $exifTool->Options('FixBase');
                if ($diff != $expect or defined $fixBase) {
                    $fix = $expect - $diff;
                    if (defined $fixBase) {
                        $fix = $fixBase if $fixBase ne '';
                        $exifTool->Warn("Adjusted MakerNotes base by $fix",1);
                    } else {
                        $exifTool->Warn("Possibly incorrect maker notes offsets (fixed by $fix)",1);
                    }
                }
            }
        }
    }
    # generate dirInfo for Leica MakerNote directory
    my %dirInfo = (
        Name       => $$tagInfo{Name},
        Base       => $fix,
        DataPt     => \$buff,
        DataPos    => $pos - $fix,
        DataLen    => $len,
        DirStart   => $dirStart,
        DirLen     => $len - $dirStart,
        DirName    => 'MakerNotes',
        Parent     => 'ExifIFD',
        TagInfo    => $tagInfo,
    );
    my $tagTablePtr = GetTagTable($$tagInfo{SubDirectory}{TagTable});
    if ($newPos) { # are we writing?
        # set position of new MakerNote IFD (+ 8 for Leica MakerNote header)
        $dirInfo{NewDataPos} = $newPos + $start + 8;
        $result = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr);
        # write preview image last if necessary and fix up the preview offsets
        my $previewInfo = $$exifTool{PREVIEW_INFO};
        delete $$exifTool{PREVIEW_INFO};
        if ($result) {
            if ($previewInfo) {
                my $fixup = $previewInfo->{Fixup};
                # set preview offset (relative to start of makernotes, + 8 for makernote header)
                $fixup->SetMarkerPointers(\$result, 'PreviewImage', length($result) + 8);
                $result .= $$previewInfo{Data};
            }
            return $junk . substr($buff, $start, $hdrLen) . $result;
        }
    } else {
        # extract information
        $result = $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
        # also extract as a block if necessary
        if ($exifTool->Options('MakerNotes') or
            $exifTool->{REQ_TAG_LOOKUP}{lc($$tagInfo{Name})})
        {
            # makernote header must be included in RebuildMakerNotes call
            $dirInfo{DirStart} -= 8;
            $dirInfo{DirLen} += 8;
            $exifTool->{MAKER_NOTE_BYTE_ORDER} = GetByteOrder();
            # rebuild maker notes (creates $exifTool->{MAKER_NOTE_FIXUP})
            my $val = Image::ExifTool::Exif::RebuildMakerNotes($exifTool, $tagTablePtr, \%dirInfo);
            unless (defined $val) {
                $exifTool->Warn('Error rebuilding maker notes (may be corrupt)');
                $val = $buff,
            }
            my $key = $exifTool->FoundTag($tagInfo, $val);
            $exifTool->SetGroup($key, 'ExifIFD');
        }
    }
    SetByteOrder($oldOrder);
    return $result;
}

1;  # end

__END__

