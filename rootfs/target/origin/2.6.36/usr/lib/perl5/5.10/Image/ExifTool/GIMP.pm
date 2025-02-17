
package Image::ExifTool::GIMP;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.01';

sub ProcessParasites($$$);

%Image::ExifTool::GIMP::Main = (
    GROUPS => { 2 => 'Image' },
    VARS => { ALPHA_FIRST => 1 },
    NOTES => q{
        The GNU Image Manipulation Program (GIMP) writes these tags in its native
        XCF (eXperimental Computing Facilty) images.
    },
    header => { SubDirectory => { TagTable => 'Image::ExifTool::GIMP::Header' } },
    17 => {
        Name => 'Compression',
        Format => 'int8u',
        PrintConv => {
            0 => 'None',
            1 => 'RLE Encoding',
            2 => 'Zlib',
            3 => 'Fractal',
        },
    },
    19 => {
        Name => 'Resolution',
        SubDirectory => { TagTable => 'Image::ExifTool::GIMP::Resolution' },
    },
    21 => {
        Name => 'Parasites',
        SubDirectory => { TagTable => 'Image::ExifTool::GIMP::Parasite' },
    },
);

%Image::ExifTool::GIMP::Header = (
    GROUPS => { 2 => 'Image' },
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    9 => {
        Name => 'XCFVersion',
        Format => 'string[5]',
        PrintConv => {
            'file' => '0',
            'v001' => '1',
            'v002' => '2',
        },
    },
    14 => { Name => 'ImageWidth',  Format => 'int32u' },
    18 => { Name => 'ImageHeight', Format => 'int32u' },
    22 => {
        Name => 'ColorMode',
        Format => 'int32u',
        PrintConv => {
            0 => 'RGB Color',
            1 => 'Grayscale',
            2 => 'Indexed Color',
        },
    },
);

%Image::ExifTool::GIMP::Resolution = (
    GROUPS => { 2 => 'Image' },
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    FORMAT => 'float',
    0 => 'XResolution',
    1 => 'YResolution',
);

%Image::ExifTool::GIMP::Parasite = (
    GROUPS => { 2 => 'Image' },
    PROCESS_PROC => \&ProcessParasites,
    'gimp-comment' => {
        Name => 'Comment',
        Format => 'string',
    },
    'exif-data' => {
        Name => 'ExifData',
        SubDirectory => {
            TagTable    => 'Image::ExifTool::Exif::Main',
            ProcessProc => \&Image::ExifTool::ProcessTIFF,
            Start       => 6, # starts after "Exif\0\0" header
        },
    },
    'jpeg-exif-data' => { # (deprecated, untested)
        Name => 'JPEGExifData',
        SubDirectory => {
            TagTable    => 'Image::ExifTool::Exif::Main',
            ProcessProc => \&Image::ExifTool::ProcessTIFF,
            Start       => 6,
        },
    },
    'iptc-data' => { # (untested)
        Name => 'IPTCData',
        SubDirectory => { TagTable => 'Image::ExifTool::IPTC::Main' },
    },
    'icc-profile' => {
        Name => 'ICC_Profile',
        SubDirectory => { TagTable => 'Image::ExifTool::ICC_Profile::Main' },
    },
    'icc-profile-name' => {
        Name => 'ICCProfileName',
        Format => 'string',
    },
    'gimp-metadata' => {
        Name => 'XMP',
        SubDirectory => {
            TagTable => 'Image::ExifTool::XMP::Main',
            Start => 10, # starts after "GIMP_XMP_1" header
        },
    },
);

sub ProcessParasites($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $unknown = $exifTool->Options('Unknown') || $exifTool->Options('Verbose');
    my $dataPt = $$dirInfo{DataPt};
    my $pos = $$dirInfo{DirStart} || 0;
    my $end = length $$dataPt;
    $exifTool->VerboseDir('Parasites', undef, $end);
    for (;;) {
        last if $pos + 4 > $end;
        my $size = Get32u($dataPt, $pos);   # length of tag string
        $pos += 4;
        last if $pos + $size + 8 > $end;
        my $tag = substr($$dataPt, $pos, $size);
        $pos += $size;
        $tag =~ s/\0.*//s;                  # trim at null terminator
        # my $flags = Get32u($dataPt, $pos);  (ignore flags)
        $size = Get32u($dataPt, $pos + 4);  # length of data
        $pos += 8;
        last if $pos + $size > $end;
        if (not $$tagTablePtr{$tag} and $unknown) {
            my $name = $tag;
            $name =~ tr/-_A-Za-z0-9//dc;
            $name =~ s/^gimp-//;
            next unless length $name;
            $name = ucfirst $name;
            $name =~ s/([a-z])-([a-z])/$1\u$2/g;
            $name = "GIMP-$name" unless length($name) > 1;
            Image::ExifTool::AddTagToTable($tagTablePtr, $tag, { Name => $name, Unknown => 1 });
        }
        $exifTool->HandleTag($tagTablePtr, $tag, undef,
            DataPt => $dataPt,
            Start  => $pos,
            Size   => $size,
        );
        $pos += $size;
    }
    return 1;
}

sub ProcessXCF($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $buff;

    return 0 unless $raf->Read($buff, 26) == 26;
    return 0 unless $buff =~ /^gimp xcf /;

    my $tagTablePtr = GetTagTable('Image::ExifTool::GIMP::Main');
    my $verbose = $exifTool->Options('Verbose');
    $exifTool->SetFileType();
    SetByteOrder('MM');

    # process the XCF header
    $exifTool->HandleTag($tagTablePtr, 'header', $buff);

    # loop through image properties
    for (;;) {
        $raf->Read($buff, 8) == 8 or last;
        my $tag  = Get32u(\$buff, 0) or last;
        my $size = Get32u(\$buff, 4);
        $verbose and $exifTool->VPrint(0, "XCF property $tag ($size bytes):\n");
        unless ($$tagTablePtr{$tag}) {
            $raf->Seek($size, 1);
            next;
        }
        $raf->Read($buff, $size) == $size or last;
        $exifTool->HandleTag($tagTablePtr, $tag, undef,
            DataPt  => \$buff,
            DataPos => $raf->Tell() - $size,
            Size    => $size,
        );
    }
    return 1;
}

1;  # end

__END__


