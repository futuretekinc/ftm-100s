
package Image::ExifTool::APP12;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess);

$VERSION = '1.09';

sub ProcessAPP12($$$);
sub ProcessDucky($$$);
sub WriteDucky($$$);

%Image::ExifTool::APP12::PictureInfo = (
    PROCESS_PROC => \&ProcessAPP12,
    GROUPS => { 0 => 'APP12', 1 => 'PictureInfo', 2 => 'Image' },
    NOTES => q{
        The JPEG APP12 "Picture Info" segment was used by some older cameras, and
        contains ASCII-based meta information.  Below are some tags which have been
        observed Agfa and Polaroid images, however ExifTool will extract information
        from any tags found in this segment.
    },
    FNumber => {
        ValueConv => '$val=~s/^[A-Za-z ]*//;$val',  # Agfa leads with an 'F'
        PrintConv => 'sprintf("%.1f",$val)',
    },
    Aperture => {
        PrintConv => 'sprintf("%.1f",$val)',
    },
    TimeDate => {
        Name => 'DateTimeOriginal',
        Description => 'Date/Time Original',
        Groups => { 2 => 'Time' },
        ValueConv => '$val=~/^\d+$/ ? ConvertUnixTime($val) : $val',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    Shutter => {
        Name => 'ExposureTime',
        ValueConv => '$val * 1e-6',
        PrintConv => 'Image::ExifTool::Exif::PrintExposureTime($val)',
    },
    shtr => {
        Name => 'ExposureTime',
        ValueConv => '$val * 1e-6',
        PrintConv => 'Image::ExifTool::Exif::PrintExposureTime($val)',
    },
   'Serial#'    => {
        Name => 'SerialNumber',
        Groups => { 2 => 'Camera' },
    },
    Flash       => { PrintConv => { 0 => 'Off', 1 => 'On' } },
    Macro       => { PrintConv => { 0 => 'Off', 1 => 'On' } },
    StrobeTime  => { },
    Ytarget     => { Name => 'YTarget' },
    ylevel      => { Name => 'YLevel' },
    FocusPos    => { },
    FocusMode   => { },
    Quality     => { },
    ExpBias     => 'ExposureCompensation',
    FWare       => 'FirmwareVersion',
    StrobeTime  => { },
    Resolution  => { },
    Protect     => { },
    ConTake     => { },
    ImageSize   => { PrintConv => '$val=~tr/-/x/;$val' },
    ColorMode   => { },
    Zoom        => { },
    ZoomPos     => { },
    LightS      => { },
    Type        => {
        Name => 'CameraType',
        Groups => { 2 => 'Camera' },
        DataMember => 'CameraType',
        RawConv => '$self->{CameraType} = $val',
    },
    Version     => { Groups => { 2 => 'Camera' } },
    ID          => { Groups => { 2 => 'Camera' } },
);

%Image::ExifTool::APP12::Ducky = (
    PROCESS_PROC => \&ProcessDucky,
    WRITE_PROC => \&WriteDucky,
    GROUPS => { 0 => 'Ducky', 1 => 'Ducky', 2 => 'Image' },
    WRITABLE => 'string',
    NOTES => q{
        Photoshop uses the JPEG APP12 "Ducky" segment to store some information in
        "Save for Web" images.
    },
    1 => { #PH
        Name => 'Quality',
        Priority => 0,
        Avoid => 1,
        Writable => 'int32u',
        ValueConv => 'unpack("N",$val)',    # 4-byte integer
        ValueConvInv => 'pack("N",$val)',
        PrintConv => '"$val%"',
        PrintConvInv => '$val=~/(\d+)/ ? $1 : undef',
    },
    2 => { #1
        Name => 'Comment',
        Priority => 0,
        Avoid => 1,
        # (ignore 4-byte character count at start of value)
        ValueConv => '$self->Decode(substr($val,4),"UCS2","MM")',
        ValueConvInv => 'pack("N",length $val) . $self->Encode($val,"UCS2","MM")',
    },
    3 => { #PH
        Name => 'Copyright',
        Priority => 0,
        Avoid => 1,
        Groups => { 2 => 'Author' },
        # (ignore 4-byte character count at start of value)
        ValueConv => '$self->Decode(substr($val,4),"UCS2","MM")',
        ValueConvInv => 'pack("N",length $val) . $self->Encode($val,"UCS2","MM")',
    },
);

sub WriteDucky($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    $exifTool or return 1;    # allow dummy access to autoload this package
    my $dataPt = $$dirInfo{DataPt};
    my $pos = $$dirInfo{DirStart};
    my $newTags = $exifTool->GetNewTagInfoHash($tagTablePtr);
    my @addTags = sort { $a <=> $b } keys(%$newTags);
    my ($dirEnd, %doneTags);
    if ($dataPt) {
        $dirEnd = $pos + $$dirInfo{DirLen};
    } else {
        my $tmp = '';
        $dataPt = \$tmp;
        $pos = $dirEnd = 0;
    }
    my $newData = '';
    SetByteOrder('MM');
    # process all data blocks in Ducky segment
    for (;;) {
        my ($tag, $len, $val);
        if ($pos + 4 <= $dirEnd) {
            $tag = Get16u($dataPt, $pos);
            $len = Get16u($dataPt, $pos + 2);
            $pos += 4;
            if ($pos + $len > $dirEnd) {
                $exifTool->Warn('Invalid Ducky block length');
                return undef;
            }
            $val = substr($$dataPt, $pos, $len);
            $pos += $len;
        } else {
            last unless @addTags;
            $tag = pop @addTags;
            next if $doneTags{$tag};
        }
        $doneTags{$tag} = 1;
        my $tagInfo = $$newTags{$tag};
        if ($tagInfo) {
            my $nvHash = $exifTool->GetNewValueHash($tagInfo);
            my $isNew;
            if (defined $val) {
                if ($exifTool->IsOverwriting($nvHash, $val)) {
                    $exifTool->VerboseValue("- Ducky:$$tagInfo{Name}", $val);
                    $isNew = 1;
                }
            } else {
                next unless Image::ExifTool::IsCreating($nvHash);
                $isNew = 1;
            }
            if ($isNew) {
                $val = $exifTool->GetNewValues($nvHash);
                ++$exifTool->{CHANGED};
                next unless defined $val;   # next if tag is being deleted
                $exifTool->VerboseValue("+ Ducky:$$tagInfo{Name}", $val);
            }
        }
        $newData .= pack('nn', $tag, length $val) . $val;
    }
    $newData .= "\0\0" if length $newData;
    return $newData;
}

sub ProcessDucky($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my $pos = $$dirInfo{DirStart};
    my $dirEnd = $pos + $$dirInfo{DirLen};
    SetByteOrder('MM');
    # process all data blocks in Ducky segment
    for (;;) {
        last if $pos + 4 > $dirEnd;
        my $tag = Get16u($dataPt, $pos);
        my $len = Get16u($dataPt, $pos + 2);
        $pos += 4;
        if ($pos + $len > $dirEnd) {
            $exifTool->Warn('Invalid Ducky block length');
            last;
        }
        my $val = substr($$dataPt, $pos, $len);
        $exifTool->HandleTag($tagTablePtr, $tag, $val,
            DataPt => $dataPt,
            DataPos => $$dirInfo{DataPos},
            Start => $pos,
            Size => $len,
        );
        $pos += $len;
    }
    return 1;
}

sub ProcessAPP12($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my $dirStart = $$dirInfo{DirStart} || 0;
    my $dirLen = $$dirInfo{DirLen} || (length($$dataPt) - $dirStart);
    if ($dirLen != $dirStart + length($$dataPt)) {
        my $buff = substr($$dataPt, $dirStart, $dirLen);
        $dataPt = \$buff;
    } else {
        pos($$dataPt) = $$dirInfo{DirStart};
    }
    my $verbose = $exifTool->Options('Verbose');
    my $success = 0;
    my $section = '';
    pos($$dataPt) = 0;

    # this regular expression is a bit complex, but basically we are looking for
    # section headers (ie. "[Camera Info]") and tag/value pairs (ie. "tag=value",
    # where "value" may contain white space), separated by spaces or CR/LF.
    # (APP12 uses CR/LF, but Olympus TextualInfo is similar and uses spaces)
    while ($$dataPt =~ /(\[.*?\]|[\w#-]+=[\x20-\x7e]+?(?=\s*([\n\r\0]|[\w#-]+=|\[|$)))/g) {
        my $token = $1;
        # was this a section name?
        if ($token =~ /^\[(.*)\]/) {
            $exifTool->VerboseDir($1) if $verbose;
            $section = ($token =~ /\[(\S+) ?Info\]/i) ? $1 : '';
            $success = 1;
            next;
        }
        $exifTool->VerboseDir($$dirInfo{DirName}) if $verbose and not $success;
        $success = 1;
        my ($tag, $val) = ($token =~ /(\S+)=(.+)/);
        my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tag);
        $verbose and $exifTool->VerboseInfo($tag, $tagInfo, Value => $val);
        unless ($tagInfo) {
            # add new tag to table
            $tagInfo = { Name => ucfirst $tag };
            # put in Camera group if information in "Camera" section
            $$tagInfo{Groups} = { 2 => 'Camera' } if $section =~ /camera/i;
            Image::ExifTool::AddTagToTable($tagTablePtr, $tag, $tagInfo);
        }
        $exifTool->FoundTag($tagInfo, $val);
    }
    return $success;
}


1;  #end

__END__

