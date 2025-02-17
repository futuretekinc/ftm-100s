
package Image::ExifTool::RSRC;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.02';

%Image::ExifTool::RSRC::Main = (
    GROUPS => { 2 => 'Document' },
    NOTES => q{
        Tags extracted from Mac OS resource files and DFONT files.  These tags may
        also be extracted from the resource fork of any file in OS X, either by
        adding "/rsrc" to the filename to process the resource fork alone, or by
        using the ExtractEmbedded (-ee) option to process the resource fork as a
        sub-document of the main file.
    },
    '8BIM' => {
        Name => 'PhotoshopInfo',
        SubDirectory => { TagTable => 'Image::ExifTool::Photoshop::Main' },
    },
    'sfnt' => {
        Name => 'Font',
        SubDirectory => { TagTable => 'Image::ExifTool::Font::Name' },
    },
    'usro_0x0000' => 'OpenWithApplication',
    'vers_0x0001' => 'ApplicationVersion',
    'STR _0xbff3' => 'ApplicationMissingMsg',
    'STR _0xbff4' => 'CreatorApplication',
    # the following written by Photoshop
    # (ref http://www.adobe.ca/devnet/photoshop/psir/ps_image_resources.pdf)
    'STR#_0x0080' => 'Keywords',
    'TEXT_0x0080' => 'Description',
    # don't extract PICT's because the clip region isn't set properly
    # in the PICT resource for some reason.  Also, a dummy 512-byte
    # header would have to be added to create a valid PICT file.
    # 'PICT' => { Name => 'PreviewPICT', Binary => 1 },
);

sub ProcessRSRC($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my ($hdr, $map, $buff, $i, $j);

    # attempt to validate the format as thoroughly as practical
    return 0 unless $raf->Read($hdr, 30) == 30;
    my ($datOff, $mapOff, $datLen, $mapLen) = unpack('N*', $hdr);
    return 0 unless $raf->Seek(0, 2);
    my $fLen = $raf->Tell();
    return 0 if $datOff < 0x10 or $datOff + $datLen > $fLen;
    return 0 if $mapOff < 0x10 or $mapOff + $mapLen > $fLen or $mapLen < 30;
    return 0 if $datOff < $mapOff and $datOff + $datLen > $mapOff;
    return 0 if $mapOff < $datOff and $mapOff + $mapLen > $datOff;

    # read the resource map
    $raf->Seek($mapOff, 0) and $raf->Read($map, $mapLen) == $mapLen or return 0;
    SetByteOrder('MM');
    my $typeOff = Get16u(\$map, 24);
    my $nameOff = Get16u(\$map, 26);
    my $numTypes = Get16u(\$map, 28);

    # validate offsets in the resource map
    return 0 if $typeOff < 28 or $nameOff < 30;

    $exifTool->SetFileType('RSRC') unless $$exifTool{IN_RESOURCE};
    my $verbose = $exifTool->Options('Verbose');
    my $tagTablePtr = GetTagTable('Image::ExifTool::RSRC::Main');

    # parse resource type list
    for ($i=0; $i<=$numTypes; ++$i) {
        my $off = $typeOff + 2 + 8 * $i;    # offset of entry in type list
        last if $off + 8 > $mapLen;
        my $resType = substr($map,$off,4);  # resource type
        my $resNum = Get16u(\$map,$off+4);  # number of resources - 1
        my $refOff = Get16u(\$map,$off+6) + $typeOff; # offset to first resource reference
        # loop through all resources
        for ($j=0; $j<=$resNum; ++$j) {
            my $roff = $refOff + 12 * $j;
            last if $roff + 12 > $mapLen;
            # read only the 24-bit resource data offset
            my $id = Get16u(\$map,$roff);
            my $resOff = (Get32u(\$map,$roff+4) & 0x00ffffff) + $datOff;
            my $resNameOff = Get16u(\$map,$roff+2) + $nameOff + $mapOff;
            my ($tag, $val, $valLen);
            my $tagInfo = $$tagTablePtr{$resType};
            if ($tagInfo) {
                $tag = $resType;
            } else {
                $tag = sprintf('%s_0x%.4x', $resType, $id);
                $tagInfo = $$tagTablePtr{$tag};
            }
            # read the resource data if necessary
            if ($tagInfo or $verbose) {
                unless ($raf->Seek($resOff, 0) and $raf->Read($buff, 4) == 4 and
                        ($valLen = unpack('N', $buff)) < 1024000 and # arbitrary size limit
                        $raf->Read($val, $valLen) == $valLen)
                {
                    $exifTool->Warn("Error reading $resType resource");
                    next;
                }
            }
            if ($verbose) {
                my ($resName, $nameLen);
                $resName = '' unless $raf->Seek($resNameOff, 0) and $raf->Read($buff, 1) and
                    ($nameLen = ord $buff) != 0 and $raf->Read($resName, $nameLen) == $nameLen;
                $exifTool->VPrint(0,sprintf("$resType resource ID 0x%.4x (offset 0x%.4x, $valLen bytes, name='$resName'):\n", $id, $resOff));
                $exifTool->VerboseDump(\$val);
            }
            next unless $tagInfo;
            if ($resType eq 'vers') {
                # parse the 'vers' resource to get the long version string
                next unless $valLen > 8;
                # long version string is after short version
                my $p = 7 + Get8u(\$val, 6);
                next if $p >= $valLen;
                my $vlen = Get8u(\$val, $p++);
                next if $p + $vlen > $valLen;
                my $tagTablePtr = GetTagTable('Image::ExifTool::RSRC::Main');
                $val = $exifTool->Decode(substr($val, $p, $vlen), 'MacRoman');
            } elsif ($resType eq 'sfnt') {
                # parse the OTF font block
                $raf->Seek($resOff + 4, 0) or next;
                $$dirInfo{Base} = $resOff + 4;
                require Image::ExifTool::Font;
                unless (Image::ExifTool::Font::ProcessOTF($exifTool, $dirInfo)) {
                    $exifTool->Warn('Unrecognized sfnt resource format');
                }
                $exifTool->OverrideFileType('DFONT');
                next;
            } elsif ($resType eq '8BIM') {
                my $ttPtr = GetTagTable('Image::ExifTool::Photoshop::Main');
                $exifTool->HandleTag($ttPtr, $id, $val,
                    DataPt  => \$val,
                    DataPos => $resOff + 4,
                    Size    => $valLen,
                    Start   => 0,
                    Parent  => 'RSRC',
                );
                next;
            } elsif ($resType eq 'STR ' and $valLen > 1) {
                # extract Pascal string
                my $len = ord $val;
                next unless $valLen >= $len + 1;
                $val = substr($val, 1, $len);
            } elsif ($resType eq 'usro' and $valLen > 4) {
                my $len = unpack('N', $val);
                next unless $valLen >= $len + 4;
                ($val = substr($val, 4, $len)) =~ s/\0.*//g; # truncate at null
            } elsif ($resType eq 'STR#' and $valLen > 2) {
                # extract list of strings (ref http://simtech.sourceforge.net/tech/strings.html)
                my $num = unpack('n', $val);
                next if $num & 0xf000; # (ignore special-format STR# resources)
                my ($i, @vals);
                my $pos = 2;
                for ($i=0; $i<$num; ++$i) {
                    last if $pos >= $valLen;
                    my $len = ord substr($val, $pos++, 1);
                    last if $pos + $len > $valLen;
                    push @vals, substr($val, $pos, $len);
                    $pos += $len;
                }
                $val = \@vals;
            } elsif ($resType ne 'TEXT') {
                next;
            }
            $exifTool->HandleTag($tagTablePtr, $tag, $val);
        }
    }
    return 1;
}

1;  # end

__END__


