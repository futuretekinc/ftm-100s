
package Image::ExifTool::GE;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::Exif;

$VERSION = '1.00';

sub ProcessGE2($$$);

%Image::ExifTool::GE::Main = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    WRITABLE => 1,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Camera' },
    NOTES => q{
        This table lists tags found in the maker notes of some General Imaging
        camera models.
    },
    # 0x0104 - int32u
    # 0x0200 - int32u[3] (with invalid offset of 0)
    0x0202 => {
        Name => 'Macro',
        Writable => 'int16u',
        PrintConv => { 0 => 'Off', 1 => 'On' },
    },
    # 0x0203 - int16u: 0
    # 0x0204 - rational64u: 10/10
    # 0x0205 - rational64u: 7.249,7.34,9.47 (changes with camera model)
    # 0x0206 - int16u[6] (with invalid offset of 0)
    0x0207 => {
        Name => 'GEModel',
        Format => 'string',
    },
    0x0300 => {
        Name => 'GEMake',
        Format => 'string',
    },
    # 0x0500 - int16u: 0
    # 0x0600 - int32u: 0
);

__END__

