
package Image::ExifTool::JVC;

use strict;
use vars qw($VERSION);
use Image::ExifTool::Exif;

$VERSION = '1.02';

sub ProcessJVCText($$$);

%Image::ExifTool::JVC::Main = (
    WRITE_PROC => \&Image::ExifTool::Exif::WriteExif,
    CHECK_PROC => \&Image::ExifTool::Exif::CheckExif,
    GROUPS => { 0 => 'MakerNotes', 2 => 'Camera' },
    NOTES => 'JVC EXIF maker note tags.',
    #0x0001 - almost always '2', but '3' for GR-DV700 samples
    0x0002 => { #PH
        Name => 'CPUVersions',
        # remove trailing nulls/spaces and split at remaining nulls/spaces
        ValueConv => '$_=$val; s/(\s*\0)+$//; s/(\s*\0)+/, /g; $_',
    },
    0x0003 => { #PH
        Name => 'Quality',
        PrintConv => {
            0 => 'Low',
            1 => 'Normal',
            2 => 'Fine',
        },
    },
);

%Image::ExifTool::JVC::Text = (
    GROUPS => { 0 => 'MakerNotes', 2 => 'Camera' },
    PROCESS_PROC => \&ProcessJVCText,
    NOTES => 'JVC/Victor text-based maker note tags.',
    VER => 'MakerNoteVersion', #PH
    QTY => { #PH
        Name => 'Quality',
        PrintConv => {
            STND => 'Normal',
            STD  => 'Normal',
            FINE => 'Fine',
        },
    },
);

sub ProcessJVCText($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my $dirStart = $$dirInfo{DirStart} || 0;
    my $dataLen = $$dirInfo{DataLen};
    my $dirLen = $$dirInfo{DirLen} || $dataLen - $dirStart;
    my $verbose = $exifTool->Options('Verbose');

    my $data = substr($$dataPt, $dirStart, $dirLen);
    # validate text maker notes
    unless ($data =~ /^VER:/) {
        $exifTool->Warn('Bad JVC text maker notes');
        return 0;
    }
    while ($data =~ m/([A-Z]+):(.{3,4})/sg) {
        my ($tag, $val) = ($1, $2);
        my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tag);
        $exifTool->VerboseInfo($tag, $tagInfo,
            Table  => $tagTablePtr,
            Value  => $val,
        ) if $verbose;
        unless ($tagInfo) {
            next unless $exifTool->{OPTIONS}->{Unknown};
            $tagInfo = {
                Name => "JVC_Text_$tag",
                Unknown => 1,
                PrintConv => 'length($val) > 60 ? substr($val,0,55) . "[...]" : $val',
            };
            # add tag information to table
            Image::ExifTool::AddTagToTable($tagTablePtr, $tag, $tagInfo);
        }
        $exifTool->FoundTag($tagInfo, $val);
    }
    return 1;
}

1;  # end

__END__

