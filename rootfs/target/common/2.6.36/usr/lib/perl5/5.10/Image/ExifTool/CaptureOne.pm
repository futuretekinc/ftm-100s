
package Image::ExifTool::CaptureOne;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::XMP;
use Image::ExifTool::ZIP;

$VERSION = '1.02';

%Image::ExifTool::CaptureOne::Main = (
    GROUPS => { 0 => 'XML', 1 => 'XML', 2 => 'Image' },
    PROCESS_PROC => \&Image::ExifTool::XMP::ProcessXMP,
    VARS => { NO_ID => 1 },
    ColorCorrections => { ValueConv => '\$val' }, # (long list of floating point numbers)
);

sub HandleCOSAttrs($$$$)
{
    my ($attrList, $attrs, $prop, $valPt) = @_;
    if (not length $$valPt and defined $$attrs{K} and defined $$attrs{V}) {
        $$prop = $$attrs{K};
        $$valPt = $$attrs{V};
        # remove these attributes from the list
        my @attrs = @$attrList;
        @$attrList = ( );
        my $a;
        foreach $a (@attrs) {
            if ($a eq 'K' or $a eq 'V') {
                delete $$attrs{$a};
            } else {
                push @$attrList, $a;
            }
        }
    }
}

sub FoundCOS($$$$;$)
{
    my ($exifTool, $tagTablePtr, $props, $val, $attrs) = @_;

    my $tag = $$props[-1];
    unless ($$tagTablePtr{$tag}) {
        $exifTool->VPrint(0, "  | [adding $tag]\n");
        my $name = ucfirst $tag;
        $name =~ tr/-_a-zA-Z0-9//dc;
        return 0 unless length $tag;
        my %tagInfo = ( Name => $tag );
        # try formatting any tag with "Date" in the name as a date
        # (shouldn't affect non-date tags)
        if ($name =~ /Date(?![a-z])/) {
            $tagInfo{Groups} = { 2 => 'Time' };
            $tagInfo{ValueConv} = 'Image::ExifTool::XMP::ConvertXMPDate($val,1)';
            $tagInfo{PrintConv} = '$self->ConvertDateTime($val)';
        }
        Image::ExifTool::AddTagToTable($tagTablePtr, $tag, \%tagInfo);
    }
    # convert from UTF8 to ExifTool Charset
    $val = $exifTool->Decode($val, "UTF8");
    # un-escape XML character entities
    $val = Image::ExifTool::XMP::UnescapeXML($val);
    $exifTool->HandleTag($tagTablePtr, $tag, $val);
    return 0;
}

sub ProcessCOS($$)
{
    my ($exifTool, $dirInfo) = @_;

    # process using XMP module, but override handling of attributes and tags
    $$dirInfo{XMPParseOpts} = {
        AttrProc => \&HandleCOSAttrs,
        FoundProc => \&FoundCOS,
    };
    my $tagTablePtr = GetTagTable('Image::ExifTool::CaptureOne::Main');
    my $success = $exifTool->ProcessDirectory($dirInfo, $tagTablePtr);
    delete $$dirInfo{XMLParseArgs};
    return $success;
}

sub ProcessEIP($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $zip = $$dirInfo{ZIP};
    my ($file, $buff, $status, $member, %parseFile);

    $exifTool->SetFileType('EIP');

    # must catch all Archive::Zip warnings
    local $SIG{'__WARN__'} = \&Image::ExifTool::ZIP::WarnProc;
    # find all manifest files
    my @members = $zip->membersMatching('^manifest\d*.xml$');
    # and choose the one with the highest version number (any better ideas?)
    while (@members) {
        my $m = shift @members;
        my $f = $m->fileName();
        next if $file and $file gt $f;
        $member = $m;
        $file = $f;
    }
    # get file names from our chosen manifest file
    if ($member) {
        ($buff, $status) = $zip->contents($member);
        if (not $status) {
            my $foundImage;
            while ($buff =~ m{<(RawPath|SettingsPath)>(.*?)</\1>}sg) {
                $file = $2;
                next unless $file =~ /\.(cos|iiq|jpe?g|tiff?)$/i;
                $parseFile{$file} = 1;    # set flag to parse this file
                $foundImage = 1 unless $file =~ /\.cos$/i;
            }
            # ignore manifest unless it contained a valid image
            undef %parseFile unless $foundImage;
        }
    }
    # extract meta information from embedded files
    my $docNum = 0;
    @members = $zip->members(); # get all members
    foreach $member (@members) {
        # get filename of this ZIP member
        $file = $member->fileName();
        next unless defined $file;
        $exifTool->VPrint(0, "File: $file\n");
        # set the document number and extract ZIP tags
        $$exifTool{DOC_NUM} = ++$docNum;
        Image::ExifTool::ZIP::HandleMember($exifTool, $member);
        if (%parseFile) {
            next unless $parseFile{$file};
        } else {
            # reading the manifest didn't work, so look for image files in the
            # root directory and .cos files in the CaptureOne directory
            next unless $file =~ m{^([^/]+\.(iiq|jpe?g|tiff?)|CaptureOne/.*\.cos)$}i;
        }
        # extract the contents of the file
        # Note: this could use a LOT of memory here for RAW images...
        ($buff, $status) = $zip->contents($member);
        $status and $exifTool->Warn("Error extracting $file"), next;
        if ($file =~ /\.cos$/i) {
            # process Capture One Settings files
            my %dirInfo = (
                DataPt => \$buff,
                DirLen => length $buff,
                DataLen => length $buff,
            );
            ProcessCOS($exifTool, \%dirInfo);
        } else {
            # set HtmlDump error if necessary because it doesn't work with embedded files
            if ($$exifTool{HTML_DUMP}) {
                $$exifTool{HTML_DUMP}{Error} = "Sorry, can't dump images embedded in ZIP files";
            }
            # process IIQ, JPEG and TIFF images
            $exifTool->ExtractInfo(\$buff, { ReEntry => 1 });
        }
        undef $buff;    # (free memory now)
    }
    delete $$exifTool{DOC_NUM};
    return 1;
}

1;  # end

__END__


