
package Image::ExifTool::OOXML;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::XMP;
use Image::ExifTool::ZIP;

$VERSION = '1.06';

my %isOOXML = (
    DOCX => 1,  DOCM => 1,
    DOTX => 1,  DOTM => 1,
    POTX => 1,  POTM => 1,
    PPSX => 1,  PPSM => 1,
    PPTX => 1,  PPTM => 1,  THMX => 1,
    XLAM => 1,
    XLSX => 1,  XLSM => 1,  XLSB => 1,
    XLTX => 1,  XLTM => 1,
);

my %fileType;
{
    my $type;
    foreach $type (keys %isOOXML) {
        $fileType{$Image::ExifTool::mimeType{$type}} = $type;
    }
}

my %queuedAttrs;
my %queueAttrs = (
    fmtid => 1,
    pid   => 1,
    name  => 1,
);

my $vectorCount;
my @vectorVals;

%Image::ExifTool::OOXML::Main = (
    GROUPS => { 0 => 'XML', 1 => 'XML', 2 => 'Document' },
    PROCESS_PROC => \&Image::ExifTool::XMP::ProcessXMP,
    VARS => { NO_ID => 1 },
    NOTES => q{
        The Office Open XML (OOXML) format was introduced with Microsoft Office 2007
        and is used by file types such as DOCX, PPTX and XLSX.  These are
        essentially ZIP archives containing XML files.  The table below lists some
        tags which have been observed in OOXML documents, but ExifTool will extract
        any tags found from XML files of the OOXML document properties ("docProps")
        directory.

        B<Tips:>
        
        1) Structural ZIP tags may be ignored (if desired) with C<--ZIP:all> on the
        command line.
        
        2) Tags may be grouped by their document number in the ZIP archive with the
        C<-g3> or C<-G3> option.
    },
    # These tags all have 1:1 correspondence with FlashPix tags except for:
    #   OOXML            FlashPix
    #   ---------------  -------------
    #   DocSecurity      Security
    #   Application      Software
    #   dc:Description   Comments
    #   dc:Creator       Author
    Application => { },
    AppVersion  => { },
    category    => { },
    Characters  => { },
    CharactersWithSpaces => { },
    CheckedBy   => { },
    Client      => { },
    Company     => { },
    created     => {
        Name => 'CreateDate',
        Groups => { 2 => 'Time' },
        Format => 'date',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    createdType => { Hidden => 1, RawConv => 'undef' }, # ignore this XML type name
    DateCompleted => {
        Groups => { 2 => 'Time' },
        Format => 'date',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    Department  => { },
    Destination => { },
    Disposition => { },
    Division    => { },
    DocSecurity => {
        # (http://msdn.microsoft.com/en-us/library/documentformat.openxml.extendedproperties.documentsecurity.aspx)
        PrintConv => {
            0 => 'None',
            1 => 'Password protected',
            2 => 'Read-only recommended',
            4 => 'Read-only enforced',
            8 => 'Locked for annotations',
        },
    },
    DocumentNumber=> { },
    Editor      => { Groups => { 2 => 'Author'} },
    ForwardTo   => { },
    Group       => { },
    HeadingPairs=> { },
    HiddenSlides=> { },
    HyperlinkBase=>{ },
    HyperlinksChanged => { PrintConv => { 'false' => 'No', 'true' => 'Yes' } },
    keywords    => { },
    Language    => { },
    lastModifiedBy => { Groups => { 2 => 'Author'} },
    lastPrinted => {
        Groups => { 2 => 'Time' },
        Format => 'date',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    Lines       => { },
    LinksUpToDate=>{ PrintConv => { 'false' => 'No', 'true' => 'Yes' } },
    Mailstop    => { },
    Manager     => { },
    Matter      => { },
    MMClips     => { },
    modified    => {
        Name => 'ModifyDate', 
        Groups => { 2 => 'Time' },
        Format => 'date',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    modifiedType=> { Hidden => 1, RawConv => 'undef' }, # ignore this XML type name
    Notes       => { },
    Office      => { },
    Owner       => { Groups => { 2 => 'Author'} },
    Pages       => { },
    Paragraphs  => { },
    PresentationFormat => { },
    Project     => { },
    Publisher   => { },
    Purpose     => { },
    ReceivedFrom=> { },
    RecordedBy  => { },
    RecordedDate=> {
        Groups => { 2 => 'Time' },
        Format => 'date',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    Reference   => { },
    revision    => { Name => 'RevisionNumber' },
    ScaleCrop   => { PrintConv => { 'false' => 'No', 'true' => 'Yes' } },
    SharedDoc   => { PrintConv => { 'false' => 'No', 'true' => 'Yes' } },
    Slides      => { },
    Source      => { },
    Status      => { },
    TelephoneNumber => { },
    Template    => { },
    TitlesOfParts=>{ },
    TotalTime   => {
        Name => 'TotalEditTime',
        PrintConv => 'ConvertTimeSpan($val, 60)',
    },
    Typist      => { },
    Words       => { },
);

sub GetTagID($)
{
    my $props = shift;
    my ($tag, $prop, $namespace);
    foreach $prop (@$props) {
        # split name into namespace and property name
        # (Note: namespace can be '' for property qualifiers)
        my ($ns, $nm) = ($prop =~ /(.*?):(.*)/) ? ($1, $2) : ('', $prop);
        next if $ns eq 'vt';        # ignore 'vt' properties
        if (defined $tag) {
            $tag .= ucfirst($nm);   # add to tag name
        } elsif ($prop ne 'Properties' and $prop ne 'cp:coreProperties' and
                 $prop ne 'property')
        {
            $tag = $nm;
            # save namespace of first property to contribute to tag name
            $namespace = $ns unless $namespace;
        }
    }
    return ($tag, $namespace || '');
}

sub FoundTag($$$$;$)
{
    my ($exifTool, $tagTablePtr, $props, $val, $attrs) = @_;
    return 0 unless @$props;
    my $verbose = $exifTool->Options('Verbose');

    my $tag = $$props[-1];
    $exifTool->VPrint(0, "  | - Tag '", join('/',@$props), "'\n") if $verbose > 1;

    # un-escape XML character entities
    $val = Image::ExifTool::XMP::UnescapeXML($val);
    # convert OOXML-escaped characters (ie. "_x0000d_" is a newline)
    $val =~ s/_x([0-9a-f]{4})_/Image::ExifTool::PackUTF8(hex($1))/gie;
    # convert from UTF8 to ExifTool Charset
    $val = $exifTool->Decode($val, 'UTF8');
    # queue this attribute for later if necessary
    if ($queueAttrs{$tag}) {
        $queuedAttrs{$tag} = $val;
        return 0;
    }
    my $ns;
    ($tag, $ns) = GetTagID($props);
    if (not $tag) {
        # all properties are in ignored namespaces
        # so 'name' from our queued attributes for the tag
        my $name = $queuedAttrs{name} or return 0;
        $name =~ s/(^| )([a-z])/$1\U$2/g;     # start words with uppercase
        ($tag = $name) =~ tr/-_a-zA-Z0-9//dc;
        return 0 unless length $tag;
        unless ($$tagTablePtr{$tag}) {
            my %tagInfo = (
                Name => $tag,
                Description => $name,
            );
            # format as a date/time value if type is 'vt:filetime'
            if ($$props[-1] eq 'vt:filetime') {
                $tagInfo{Groups} = { 2 => 'Time' },
                $tagInfo{Format} = 'date',
                $tagInfo{PrintConv} = '$self->ConvertDateTime($val)';
            }
            $exifTool->VPrint(0, "  | [adding $tag]\n") if $verbose;
            Image::ExifTool::AddTagToTable($tagTablePtr, $tag, \%tagInfo);
        }
    } elsif ($tag eq 'xmlns') {
        # ignore namespaces (for now)
        return 0;
    } elsif (ref $Image::ExifTool::XMP::Main{$ns} eq 'HASH' and
        $Image::ExifTool::XMP::Main{$ns}{SubDirectory})
    {
        # use standard XMP table if it exists
        my $table = $Image::ExifTool::XMP::Main{$ns}{SubDirectory}{TagTable};
        no strict 'refs';
        if ($table and %$table) {
            $tagTablePtr = Image::ExifTool::GetTagTable($table);
        }
    } elsif (@$props > 2 and grep /^vt:vector$/, @$props) {
        # handle vector properties (accumulate as lists)
        if ($$props[-1] eq 'vt:size') {
            $vectorCount = $val;
            undef @vectorVals;
            return 0;
        } elsif ($$props[-1] eq 'vt:baseType') {
            return 0;   # ignore baseType
        } elsif ($vectorCount) {
            --$vectorCount;
            if ($vectorCount) {
                push @vectorVals, $val;
                return 0;
            }
            $val = [ @vectorVals, $val ] if @vectorVals;
            # Note: we will lose any improper-sized vector elements here
        }
    }
    # add any unknown tags to table
    if ($$tagTablePtr{$tag}) {
        my $tagInfo = $$tagTablePtr{$tag};
        if (ref $tagInfo eq 'HASH') {
            # reformat date/time values
            my $fmt = $$tagInfo{Format} || $$tagInfo{Writable} || '';
            $val = Image::ExifTool::XMP::ConvertXMPDate($val) if $fmt eq 'date';
        }
    } else {
        $exifTool->VPrint(0, "  [adding $tag]\n") if $verbose;
        Image::ExifTool::AddTagToTable($tagTablePtr, $tag, { Name => ucfirst $tag });
    }
    # save the tag
    $exifTool->HandleTag($tagTablePtr, $tag, $val);

    # start fresh for next tag
    undef $vectorCount;
    undef %queuedAttrs;

    return 1;
}

sub ProcessDOCX($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $zip = $$dirInfo{ZIP};
    my $tagTablePtr = GetTagTable('Image::ExifTool::OOXML::Main');
    my $mime = $$dirInfo{MIME} || $Image::ExifTool::mimeType{DOCX};

    # set the file type ('DOCX' by default)
    my $fileType = $fileType{$mime};
    if ($fileType) {
        # THMX is a special case because its contents.main MIME types is PPTX
        if ($fileType eq 'PPTX' and $$exifTool{FILE_EXT} and $$exifTool{FILE_EXT} eq 'THMX') {
            $fileType = 'THMX';
        }
    } else {
        $exifTool->VPrint(0, "Unrecognized MIME type: $mime\n");
        # get MIME type according to file extension
        $fileType = $$exifTool{FILE_EXT};
        # default to 'DOCX' if this isn't a known OOXML extension
        $fileType = 'DOCX' unless $fileType and $isOOXML{$fileType};
    }
    $exifTool->SetFileType($fileType);

    # must catch all Archive::Zip warnings
    local $SIG{'__WARN__'} = \&Image::ExifTool::ZIP::WarnProc;
    # extract meta information from all files in ZIP "docProps" directory
    my $docNum = 0;
    my @members = $zip->members();
    my $member;
    foreach $member (@members) {
        # get filename of this ZIP member
        my $file = $member->fileName();
        next unless defined $file;
        $exifTool->VPrint(0, "File: $file\n");
        # set the document number and extract ZIP tags
        $$exifTool{DOC_NUM} = ++$docNum;
        Image::ExifTool::ZIP::HandleMember($exifTool, $member);
        # process only XML and JPEG/WMF thumbnail images in "docProps" directory
        next unless $file =~ m{^docProps/(.*\.xml|(thumbnail\.(jpe?g|wmf)))$}i;
        # get the file contents (CAREFUL! $buff MUST be local since we hand off a value ref)
        my ($buff, $status) = $zip->contents($member);
        $status and $exifTool->Warn("Error extracting $file"), next;
        # extract docProps/thumbnail.(jpg|mwf) as PreviewImage|PreviewMWF
        if ($file =~ /\.(jpe?g|wmf)$/i) {
            my $tag = $file =~ /\.wmf$/i ? 'PreviewWMF' : 'PreviewImage';
            $exifTool->FoundTag($tag, \$buff);
            next;
        }
        # process XML files (docProps/app.xml, docProps/core.xml, docProps/custom.xml)
        my %dirInfo = (
            DataPt => \$buff,
            DirLen => length $buff,
            DataLen => length $buff,
            XMPParseOpts => {
                FoundProc => \&FoundTag,
            },
        );
        $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
        undef $buff;    # (free memory now)
    }
    delete $$exifTool{DOC_NUM};
    return 1;
}

1;  # end

__END__


