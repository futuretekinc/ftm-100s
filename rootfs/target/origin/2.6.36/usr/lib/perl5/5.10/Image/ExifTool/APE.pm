
package Image::ExifTool::APE;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.01';

%Image::ExifTool::APE::Main = (
    GROUPS => { 2 => 'Audio' },
    NOTES => q{
        Tags found in Monkey's Audio (APE) information.  Only a few common tags are
        listed below, but ExifTool will extract any tag found.  ExifTool supports
        APEv1 and APEv2 tags, as well as ID3 information in APE files.
    },
    Album   => { },
    Artist  => { },
    Genre   => { },
    Title   => { },
    Track   => { },
    Year    => { },
    'Tool Version' => { Name => 'ToolVersion' },
    'Tool Name'    => { Name => 'ToolName' },
);

%Image::ExifTool::APE::OldHeader = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 1 => 'MAC', 2 => 'Audio' },
    FORMAT => 'int16u',
    NOTES => 'APE MAC audio header for version 3.97 or earlier.',
    0 => {
        Name => 'APEVersion',
        ValueConv => '$val / 1000',
    },
    1 => 'CompressionLevel',
  # 2 => 'FormatFlags',
    3 => 'Channels',
    4 => { Name => 'SampleRate', Format => 'int32u' },
  # 6 => { Name => 'HeaderBytes', Format => 'int32u' }, # WAV header bytes
  # 8 => { Name => 'TerminatingBytes', Format => 'int32u' },
    10 => { Name => 'TotalFrames', Format => 'int32u' },
    12 => { Name => 'FinalFrameBlocks', Format => 'int32u' },
);

%Image::ExifTool::APE::NewHeader = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 1 => 'MAC', 2 => 'Audio' },
    FORMAT => 'int16u',
    NOTES => 'APE MAC audio header for version 3.98 or later.',
    0 => 'CompressionLevel',
  # 1 => 'FormatFlags',
    2 => { Name => 'BlocksPerFrame',   Format => 'int32u' },
    4 => { Name => 'FinalFrameBlocks', Format => 'int32u' },
    6 => { Name => 'TotalFrames',      Format => 'int32u' },
    8 => 'BitsPerSample',
    9 => 'Channels',
    10 => { Name => 'SampleRate',      Format => 'int32u' },
);

sub MakeTag($$)
{
    my ($tag, $tagTablePtr) = @_;
    my $name = ucfirst(lc($tag));
    # remove invalid characters in tag name and capitalize following letters
    $name =~ s/[^\w-]+(.?)/\U$1/sg;
    $name =~ s/([a-z0-9])_([a-z])/$1\U$2/g;
    Image::ExifTool::AddTagToTable($tagTablePtr, $tag, { Name => $name });
}

sub ProcessAPE($$)
{
    my ($exifTool, $dirInfo) = @_;

    # must first check for leading/trailing ID3 information
    unless ($exifTool->{DoneID3}) {
        require Image::ExifTool::ID3;
        Image::ExifTool::ID3::ProcessID3($exifTool, $dirInfo) and return 1;
    }
    my $raf = $$dirInfo{RAF};
    my $verbose = $exifTool->Options('Verbose');
    my ($buff, $i, $header, $tagTablePtr, $dataPos);

    # check APE signature and process audio information
    # unless this is some other type of file
    unless ($exifTool->{VALUE}->{FileType}) {
        $raf->Read($buff, 32) == 32 or return 0;
        $buff =~ /^(MAC |APETAGEX)/ or return 0;
        $exifTool->SetFileType();
        SetByteOrder('II');

        if ($buff =~ /^APETAGEX/) {
            # we already read the APE header
            $header = 1;
        } else {
            # process the MAC header
            my $vers = Get16u(\$buff, 4);
            my $table;
            if ($vers <= 3970) {
                $buff = substr($buff, 4);
                $table = GetTagTable('Image::ExifTool::APE::OldHeader');
            } else {
                my $dlen = Get32u(\$buff, 8);
                my $hlen = Get32u(\$buff, 12);
                unless ($dlen & 0x80000000 or $hlen & 0x80000000) {
                    if ($raf->Seek($dlen, 0) and $raf->Read($buff, $hlen) == $hlen) {
                        $table = GetTagTable('Image::ExifTool::APE::NewHeader');
                    }
                }
            }
            $exifTool->ProcessDirectory( { DataPt => \$buff }, $table) if $table;
        }
    }
    # look for APE trailer unless we already found an APE header
    unless ($header) {
        # look for the APE trailer footer...
        my $footPos = -32;
        # (...but before the ID3v1 trailer if it exists)
        $footPos -= 128 if $exifTool->{DoneID3} == 2;
        $raf->Seek($footPos, 2)     or return 1;
        $raf->Read($buff, 32) == 32 or return 1;
        $buff =~ /^APETAGEX/        or return 1;
        SetByteOrder('II');
    }
    my ($version, $size, $count, $flags) = unpack('x8V4', $buff);
    $version /= 1000;
    $size -= 32;    # get size of data only
    if (($size & 0x80000000) == 0 and
        ($header or $raf->Seek(-$size-32, 1)) and
        $raf->Read($buff, $size) == $size)
    {
        if ($verbose) {
            $exifTool->VerboseDir("APEv$version", $count, $size);
            $exifTool->VerboseDump(\$buff, DataPos => $raf->Tell() - $size);
        }
        $tagTablePtr = GetTagTable('Image::ExifTool::APE::Main');
        $dataPos = $raf->Tell() - $size;
    } else {
        $count = -1;
    }
    my $pos = 0;
    for ($i=0; $i<$count; ++$i) {
        # read next APE tag
        last if $pos + 8 > $size;
        my $len = Get32u(\$buff, $pos);
        my $flags = Get32u(\$buff, $pos + 4);
        pos($buff) = $pos + 8;
        last unless $buff =~ /\G(.*?)\0/sg;
        my $tag = $1;
        $pos = pos($buff);
        last if $pos + $len > $size;
        my $val = substr($buff, $pos, $len);
        MakeTag($tag, $tagTablePtr) unless $$tagTablePtr{$tag};
        # handle binary-value tags
        if (($flags & 0x06) == 0x02) {
            my $buf2 = $val;
            $val = \$buf2;
            # extract cover art description separately (hackitty hack)
            if ($tag =~ /^Cover Art/) {
                $buf2 =~ s/^([\x20-\x7f]*)\0//;
                if ($1) {
                    my $t = "$tag Desc";
                    my $v = $1;
                    MakeTag($t, $tagTablePtr) unless $$tagTablePtr{$t};
                    $exifTool->HandleTag($tagTablePtr, $t, $v);
                }
            }
        }
        $exifTool->HandleTag($tagTablePtr, $tag, $val,
            Index => $i,
            DataPt => \$buff,
            DataPos => $dataPos,
            Start => $pos,
            Size => $len,
        );
        $pos += $len;
    }
    $i == $count or $exifTool->Warn('Bad APE trailer');
    return 1;
}

1;  # end

__END__


