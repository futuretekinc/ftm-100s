
package Image::ExifTool::Reconyx;

use strict;
use vars qw($VERSION);

$VERSION = '1.02';

%Image::ExifTool::Reconyx::Main = (
    GROUPS => { 0 => 'MakerNotes', 2 => 'Camera' },
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    WRITE_PROC => \&Image::ExifTool::WriteBinaryData,
    CHECK_PROC => \&Image::ExifTool::CheckBinaryData,
    TAG_PREFIX => 'Reconyx',
    FORMAT => 'int16u',
    WRITABLE => 1,
    FIRST_ENTRY => 0,
    NOTES => q{
        The following tags are extracted from the maker notes of Reconyx Hyperfire
        cameras such as the HC500, HC600 and PC900.
    },
    0x00 => { #1
        Name => 'MakerNoteVersion',
        PrintConv => 'sprintf("0x%.4x", $val)',
        Writable => 0, # (we use this for identification, 0xf101 --> rev 1.0)
        PrintConvInv => 'hex $val',
    },
    0x01 => { #1
        Name => 'FirmwareVersion',
        Format => 'int16u[3]',
        PrintConv => '$val=~tr/ /./; $val',
        Writable => 0, # (we use this for identification, 0x0003 --> ver 2 or 3)
    },
    0x04 => { #1
        Name => 'FirmwareDate',
        Format => 'int16u[2]',
        ValueConv => q{
            my @v = split(' ',$val);
            sprintf('%.4x:%.2x:%.2x', $v[0], $v[1]>>8, $v[1]&0xff);
        },
        ValueConvInv => q{
            my @v = split(':', $val);
            hex($v[0]) . ' ' . hex($v[1] . $v[2]);
        },
    },
    0x06 => {
        Name => 'TriggerMode',
        Format => 'string[2]',
        PrintConv => {
            C => 'CodeLoc Not Entered', #1
            E => 'External Sensor', #1
            M => 'Motion Detection',
            T => 'Time Lapse',
        },
    },
    0x07 => {
        Name => 'Sequence',
        Format => 'int16u[2]',
        PrintConv => '$val =~ s/ / of /; $val',
        PrintConvInv => 'join(" ", $val=~/\d+/g)',
    },
    0x09 => { #1
        Name => 'EventNumber',
        Format => 'int16u[2]',
        ValueConv => 'my @v=split(" ",$val); ($v[0]<<16) + $v[1]',
        ValueConvInv => '($val>>16) . " " . ($val&0xffff)',
    },
    0x0b => {
        Name => 'DateTimeOriginal',
        Description => 'Date/Time Original',
        Format => 'int16u[6]',
        Groups => { 2 => 'Time' },
        Shift => 'Time',
        ValueConv => q{
            my @a = split ' ', $val;
            sprintf('%.4d:%.2d:%.2d %.2d:%.2d:%.2d', @a[5,3,4,2,1,0]);
        },
        ValueConvInv => q{
            my @a = ($val =~ /\d+/g);
            return undef unless @a >= 6;
            join ' ', @a[5,4,3,1,2,0];
        },
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val)',
    },
    0x12 => {
        Name => 'MoonPhase',
        Groups => { 2 => 'Time' },
        PrintConv => {
            0 => 'New',
            1 => 'New Crescent',
            2 => 'First Quarter',
            3 => 'Waxing Gibbous',
            4 => 'Full',
            5 => 'Waning Gibbous',
            6 => 'Last Quarter',
            7 => 'Old Crescent',
        },
    },
    0x13 => {
        Name => 'AmbientTemperatureFahrenheit',
        PrintConv => '"$val F"',
        PrintConvInv => '$val=~/(\d+)/ ? $1 : $val',
    },
    0x14 => {
        Name => 'AmbientTemperature',
        PrintConv => '"$val C"',
        PrintConvInv => '$val=~/(\d+)/ ? $1 : $val',
    },
    0x15 => {
        Name => 'SerialNumber',
        Format => 'undef[30]',
        RawConv => '$_ = $self->Decode($val, "UCS2"); s/\0.*//; $_',
        RawConvInv => q{
            $_ = $self->Encode($val, "UCS2");
            $_ = substr($_, 0, 30) if length($_) > 30;
            return $_;
        },
    },
    0x24 => 'Contrast', #1
    0x25 => 'Brightness', #1
    0x26 => 'Sharpness', #1
    0x27 => 'Saturation', #1
    0x28 => {
        Name => 'InfraredIlluminator',
        PrintConv => {
            0 => 'Off',
            1 => 'On',
        },
    },
    0x29 => 'MotionSensitivity', #1
    0x2a => { #1
        Name => 'BatteryVoltage',
        ValueConv => '$val / 1000',
        ValueConvInv => '$val * 1000',
        PrintConv => '"$val V"',
        PrintConvInv => '$val=~s/ ?V$//; $val',
    },
    0x2b => {
        Name => 'UserLabel',
        Format => 'string[22]', #1 (but manual says 16-char limit)
    },
);


__END__

