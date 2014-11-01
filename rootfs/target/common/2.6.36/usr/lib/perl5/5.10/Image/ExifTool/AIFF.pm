
package Image::ExifTool::AIFF;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::ID3;

$VERSION = '1.03';

my %timeInfo = (
    Groups => { 2 => 'Time' },
    ValueConv => 'ConvertUnixTime($val - ((66 * 365 + 17) * 24 * 3600))',
    PrintConv => '$self->ConvertDateTime($val)',
);

%Image::ExifTool::AIFF::Main = (
    GROUPS => { 2 => 'Audio' },
    NOTES => 'Only the tags decoded by ExifTool are listed in this table.',
    FVER => {
        Name => 'FormatVersion',
        SubDirectory => { TagTable => 'Image::ExifTool::AIFF::FormatVers' },
    },
    COMM => {
        Name => 'Common',
        SubDirectory => { TagTable => 'Image::ExifTool::AIFF::Common' },
    },
    COMT => {
        Name => 'Comment',
        SubDirectory => { TagTable => 'Image::ExifTool::AIFF::Comment' },
    },
    NAME => 'Name',
    AUTH => { Name => 'Author', Groups => { 2 => 'Author' } },
   '(c) ' => { Name => 'Copyright', Groups => { 2 => 'Author' } },
    ANNO => 'Annotation',
   'ID3 ' => {
        Name => 'ID3',
        SubDirectory => {
            TagTable => 'Image::ExifTool::ID3::Main',
            ProcessProc => \&Image::ExifTool::ID3::ProcessID3,
        },
    },
);

%Image::ExifTool::AIFF::Common = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 2 => 'Audio' },
    FORMAT => 'int16u',
    0 => 'NumChannels',
    1 => { Name => 'NumSampleFrames', Format => 'int32u' },
    3 => 'SampleSize',
    4 => { Name => 'SampleRate', Format => 'extended' }, #3
    9 => {
        Name => 'CompressionType',
        Format => 'string[4]',
        PrintConv => {
            NONE => 'None',
            ACE2 => 'ACE 2-to-1',
            ACE8 => 'ACE 8-to-3',
            MAC3 => 'MAC 3-to-1',
            MAC6 => 'MAC 6-to-1',
            sowt => 'Little-endian, no compression',
        },
    },
);

%Image::ExifTool::AIFF::FormatVers = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    FORMAT => 'int32u',
    0 => { Name => 'FormatVersionTime', %timeInfo },
);

%Image::ExifTool::AIFF::Comment = (
    PROCESS_PROC => \&Image::ExifTool::AIFF::ProcessComment,
    GROUPS => { 2 => 'Audio' },
    0 => { Name => 'CommentTime', %timeInfo },
    1 => 'MarkerID',
    2 => 'Comment',
);

sub ProcessComment($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my $dirLen = $$dirInfo{DirLen};
    my $verbose = $exifTool->Options('Verbose');
    return 0 unless $dirLen > 2;
    my $numComments = unpack('n',$$dataPt);
    my $pos = 2;
    my $i;
    $verbose and $exifTool->VerboseDir('Comment', $numComments);
    for ($i=0; $i<$numComments; ++$i) {
        last if $pos + 8 > $dirLen;
        my ($time, $markerID, $size) = unpack("x${pos}Nnn", $$dataPt);
        $exifTool->HandleTag($tagTablePtr, 0, $time);
        $exifTool->HandleTag($tagTablePtr, 1, $markerID) if $markerID;
        $pos += 8;
        last if $pos + $size > $dirLen;
        my $val = substr($$dataPt, $pos, $size);
        $exifTool->HandleTag($tagTablePtr, 2, $val);
        ++$size if $size & 0x01;    # account for padding byte if necessary
        $pos += $size;
    }
}

sub ProcessAIFF($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my ($buff, $err, $tagTablePtr, $page, $type);

    # verify this is a valid AIFF file
    return 0 unless $raf->Read($buff, 12) == 12;
    my $pos = 12;
    # check for DjVu image
    if ($buff =~ /^AT&TFORM/) {
        # http://www.djvu.org/
        # http://djvu.sourceforge.net/specs/djvu3changes.txt
        my $buf2;
        return 0 unless $raf->Read($buf2, 4) == 4 and $buf2 =~ /^(DJVU|DJVM)/;
        $pos += 4;
        $buff = substr($buff, 4) . $buf2;
        $tagTablePtr = GetTagTable('Image::ExifTool::DjVu::Main');
        $exifTool->SetFileType('DJVU');
        # modifiy FileType to indicate a multi-page document
        $exifTool->{VALUE}->{FileType} .= " (multi-page)" if $buf2 eq 'DJVM';
        $type = 'DjVu';
    } else {
        return 0 unless $buff =~ /^FORM....(AIF(F|C))/s;
        $exifTool->SetFileType($1);
        $tagTablePtr = GetTagTable('Image::ExifTool::AIFF::Main');
        $type = 'AIFF';
    }
    SetByteOrder('MM');
    for (;;) {
        $raf->Read($buff, 8) == 8 or last;
        $pos += 8;
        my ($tag, $len) = unpack('a4N', $buff);
        my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tag);
        $exifTool->VPrint(0, "AIFF '$tag' chunk ($len bytes of data):\n");
        # AIFF chunks are padded to an even number of bytes
        my $len2 = $len + ($len & 0x01);
        if ($tagInfo) {
            if ($$tagInfo{TypeOnly}) {
                $len = $len2 = 4;
                $page = ($page || 0) + 1;
                $exifTool->VPrint(0, $exifTool->{INDENT} . "Page $page:\n");
            }
            $raf->Read($buff, $len2) >= $len or $err=1, last;
            unless ($$tagInfo{SubDirectory} or $$tagInfo{Binary}) {
                $buff =~ s/\0+$//;  # remove trailing nulls
            }
            $exifTool->HandleTag($tagTablePtr, $tag, $buff,
                DataPt => \$buff,
                DataPos => $pos,
                Start => 0,
                Size => $len,
            );
        } else {
            $raf->Seek($len2, 1) or $err=1, last;
        }
        $pos += $len2;
    }
    $err and $exifTool->Warn("Error reading $type file (corrupted?)");
    return 1;
}

1;  # end

__END__

