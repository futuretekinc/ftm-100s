
package Image::ExifTool::Unknown;

use strict;
use vars qw($VERSION);
use Image::ExifTool::Exif;

$VERSION = '1.13';

%Image::ExifTool::Unknown::Main = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 1 => 'MakerUnknown', 2 => 'Camera' },

    # this seems to be a common fixture, so look for it in unknown maker notes
    0x0e00 => {
        Name => 'PrintIM',
        Description => 'Print Image Matching',
        SubDirectory => {
            TagTable => 'Image::ExifTool::PrintIM::Main',
        },
    },
);


1;  # end

__END__

