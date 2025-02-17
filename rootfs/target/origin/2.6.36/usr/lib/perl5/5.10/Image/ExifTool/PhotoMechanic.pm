
package Image::ExifTool::PhotoMechanic;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::Exif;
use Image::ExifTool::IPTC;
use Image::ExifTool::XMP;

$VERSION = '1.02';

sub ProcessPhotoMechanic($$);

my %colorClasses = (
    0 => '0 (None)',
    1 => '1 (Winner)',
    2 => '2 (Winner alt)',
    3 => '3 (Superior)',
    4 => '4 (Superior alt)',
    5 => '5 (Typical)',
    6 => '6 (Typical alt)',
    7 => '7 (Extras)',
    8 => '8 (Trash)',
);

%Image::ExifTool::PhotoMechanic::Main = (
    GROUPS => { 2 => 'Image' },
    PROCESS_PROC => \&Image::ExifTool::IPTC::ProcessIPTC,
    WRITE_PROC => \&Image::ExifTool::IPTC::WriteIPTC,
    NOTES => q{
        The Photo Mechanic trailer contains data in an IPTC-format structure, with
        soft edit information stored under record number 2.
    },
    2 => {
        Name => 'SoftEdit',
        SubDirectory => {
            TagTable => 'Image::ExifTool::PhotoMechanic::SoftEdit',
        },
    },
);

my %rawCropConv = (
    ValueConv => '$val / 655.36',
    ValueConvInv => 'int($val * 655.36 + 0.5)',
    PrintConv => 'sprintf("%.3f%%",$val)',
    PrintConvInv => '$val=~tr/ %//d; $val',
);

%Image::ExifTool::PhotoMechanic::SoftEdit = (
    GROUPS => { 2 => 'Image' },
    WRITE_PROC => \&Image::ExifTool::IPTC::WriteIPTC,
    CHECK_PROC => \&Image::ExifTool::IPTC::CheckIPTC,
    WRITABLE => 1,
    FORMAT => 'int32s',
    209 => { Name => 'RawCropLeft',   %rawCropConv },
    210 => { Name => 'RawCropTop',    %rawCropConv },
    211 => { Name => 'RawCropRight',  %rawCropConv },
    212 => { Name => 'RawCropBottom', %rawCropConv },
    213 => 'ConstrainedCropWidth',
    214 => 'ConstrainedCropHeight',
    215 => 'FrameNum',
    216 => {
        Name => 'Rotation',
        PrintConv => {
            0 => '0',
            1 => '90',
            2 => '180',
            3 => '270',
        },
    },
    217 => 'CropLeft',
    218 => 'CropTop',
    219 => 'CropRight',
    220 => 'CropBottom',
    221 => {
        Name => 'Tagged',
        PrintConv => { 0 => 'No', 1 => 'Yes' },
    },
    222 => {
        Name => 'ColorClass',
        PrintConv => \%colorClasses,
    },
    223 => 'Rating',
    236 => { Name => 'PreviewCropLeft',   %rawCropConv },
    237 => { Name => 'PreviewCropTop',    %rawCropConv },
    238 => { Name => 'PreviewCropRight',  %rawCropConv },
    239 => { Name => 'PreviewCropBottom', %rawCropConv },
);

%Image::ExifTool::PhotoMechanic::XMP = (
    GROUPS => { 0 => 'XMP', 1 => 'XMP-photomech', 2 => 'Image' },
    NAMESPACE => { photomechanic => 'http://ns.camerabits.com/photomechanic/1.0/' },
    WRITE_PROC => \&Image::ExifTool::XMP::WriteXMP,
    WRITABLE => 'string',
    NOTES => q{
        Below is a list of the observed PhotoMechanic XMP tags.  The actual
        namespace prefix is "photomechanic" but ExifTool shortens this in
        the "XMP-photomech" family 1 group name.
    },
    CountryCode => { Avoid => 1, Groups => { 2 => 'Location' } },
    EditStatus  => { },
    Prefs       => {
        Notes => 'format is "Tagged:0, ColorClass:1, Rating:2, FrameNum:3"',
        PrintConv => q{
            $val =~ s[\s*(\d+):\s*(\d+):\s*(\d+):\s*(\S*)]
                     [Tagged:$1, ColorClass:$2, Rating:$3, FrameNum:$4];
            return $val;
        },
        PrintConvInv => q{
            $val =~ s[Tagged:\s*(\d+).*ColorClass:\s*(\d+).*Rating:\s*(\d+).*FrameNum:\s*(\S*)]
                     [$1:$2:$3:$4]is;
            return $val;
        },
    },
    TimeCreated => {
        Avoid => 1,
        Groups => { 2 => 'Time' },
        Shift => 'Time',
        ValueConv => 'Image::ExifTool::Exif::ExifTime($val)',
        ValueConvInv => 'Image::ExifTool::IPTC::IptcTime($val)',
    },
);

sub ProcessPhotoMechanic($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $offset = $$dirInfo{Offset} || 0;
    my $outfile = $$dirInfo{OutFile};
    my $verbose = $exifTool->Options('Verbose');
    my $out = $exifTool->Options('TextOut');
    my $rtnVal = 0;
    my ($buff, $footer);

    for (;;) {
        # read and validate trailer footer (last 12 bytes)
        last unless $raf->Seek(-12-$offset, 2) and $raf->Read($footer, 12) == 12;
        last unless $footer =~ /cbipcbbl$/;
        my $size = unpack('N', $footer);

        if ($size & 0x80000000 or not $raf->Seek(-$size-12, 1)) {
            $exifTool->Warn('Bad PhotoMechanic trailer');
            last;
        }
        unless ($raf->Read($buff, $size) == $size) {
            $exifTool->Warn('Error reading PhotoMechanic trailer');
            last;
        }
        $rtnVal = 1;    # we read the trailer successfully

        # set variables returned in dirInfo hash
        $$dirInfo{DataPos} = $raf->Tell() - $size;
        $$dirInfo{DirLen} = $size + 12;

        my %dirInfo = (
            DataPt => \$buff,
            DataPos => $$dirInfo{DataPos},
            DirStart => 0,
            DirLen => $size,
            Parent => 'PhotoMechanic',
        );
        my $tagTablePtr = GetTagTable('Image::ExifTool::PhotoMechanic::Main');
        if (not $outfile) {
            # extract trailer information
            $exifTool->DumpTrailer($dirInfo) if $verbose or $exifTool->{HTML_DUMP};
            $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
        } elsif ($exifTool->{DEL_GROUP}->{PhotoMechanic}) {
            # delete the trailer
            $verbose and printf $out "  Deleting PhotoMechanic trailer\n";
            ++$exifTool->{CHANGED};
        } else {
            # rewrite the trailer
            my $newPt;
            my $newBuff = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr);
            if (defined $newBuff) {
                $newPt = \$newBuff; # write out the modified trailer
                my $pad = 0x800 - length($newBuff);
                if ($pad > 0 and not $exifTool->Options('Compact')) {
                    # pad out to 2kB like PhotoMechanic does
                    $newBuff .= "\0" x $pad;
                }
                # generate new footer
                $footer = pack('N', length($$newPt)) . 'cbipcbbl';
            } else {
                $newPt = \$buff;    # just copy existing trailer
            }
            # write out the trailer
            Write($outfile, $$newPt, $footer) or $rtnVal = -1;
        }
        last;
    }
    return $rtnVal;
}

1;  # end

__END__


