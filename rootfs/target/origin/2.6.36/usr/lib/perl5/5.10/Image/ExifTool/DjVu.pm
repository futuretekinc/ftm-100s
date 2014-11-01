
package Image::ExifTool::DjVu;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.03';

sub ParseAnt($);
sub ProcessAnt($$$);
sub ProcessMeta($$$);
sub ProcessBZZ($$$);

%Image::ExifTool::DjVu::Main = (
    GROUPS => { 2 => 'Image' },
    NOTES => 'Information is extracted from the following chunks in DjVu images.',
    INFO => {
        SubDirectory => { TagTable => 'Image::ExifTool::DjVu::Info' },
    },
    FORM => {
        TypeOnly => 1,  # extract chunk type only, then descend into chunk
        SubDirectory => { TagTable => 'Image::ExifTool::DjVu::Form' },
    },
    ANTa => {
        SubDirectory => { TagTable => 'Image::ExifTool::DjVu::Ant' },
    },
    ANTz => {
        Name => 'CompressedAnnotation',
        SubDirectory => {
            TagTable => 'Image::ExifTool::DjVu::Ant',
            ProcessProc => \&ProcessBZZ,
        }
    },
    INCL => 'IncludedFileID',
);

%Image::ExifTool::DjVu::Info = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 2 => 'Image' },
    FORMAT => 'int8u',
    PRIORITY => 0, # first INFO block takes priority
    0 => {
        Name => 'ImageWidth',
        Format => 'int16u',
    },
    2 => {
        Name => 'ImageHeight',
        Format => 'int16u',
    },
    4 => {
        Name => 'DjVuVersion',
        Description => 'DjVu Version',
        Format => 'int8u[2]',
        # (this may be just one byte as with version 0.16)
        ValueConv => '$val=~/(\d+) (\d+)/ ? "$2.$1" : "0.$val"',
    },
    6 => {
        Name => 'SpatialResolution',
        Format => 'int16u',
        ValueConv => '(($val & 0xff)<<8) + ($val>>8)', # (little-endian!)
    },
    8 => {
        Name => 'Gamma',
        ValueConv => '$val / 10',
    },
    9 => {
        Name => 'Orientation',
        Mask => 0x07, # (upper 5 bits reserved)
        PrintConv => {
            1 => 'Horizontal (normal)',
            2 => 'Rotate 180',
            5 => 'Rotate 90 CW',
            6 => 'Rotate 270 CW',
        },
    },
);

%Image::ExifTool::DjVu::Form = (
    PROCESS_PROC => \&Image::ExifTool::ProcessBinaryData,
    GROUPS => { 2 => 'Image' },
    0 => {
        Name => 'SubfileType',
        Format => 'undef[4]',
        Priority => 0,
        PrintConv => {
            DJVU => 'Single-page image',
            DJVM => 'Multi-page document',
            PM44 => 'Color IW44',
            BM44 => 'Grayscale IW44',
            DJVI => 'Shared component',
            THUM => 'Thumbnail image',
        },
    },
);

%Image::ExifTool::DjVu::Ant = (
    PROCESS_PROC => \&Image::ExifTool::DjVu::ProcessAnt,
    GROUPS => { 2 => 'Image' },
    NOTES => 'Information extracted from annotation chunks.',
    # Note: For speed, ProcessAnt() pre-scans for known tag ID's, so if any
    # new tags are added here they must also be added to the pre-scan check
    metadata => {
        SubDirectory => { TagTable => 'Image::ExifTool::DjVu::Meta' }
    },
    xmp => {
        Name => 'XMP',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::Main' }
    },
);

%Image::ExifTool::DjVu::Meta = (
    PROCESS_PROC => \&Image::ExifTool::DjVu::ProcessMeta,
    GROUPS => { 1 => 'DjVu-Meta', 2 => 'Image' },
    NOTES => q{
        This table lists the standard DjVu metadata tags, but ExifTool will extract
        any tags that exist even if they don't appear here.  The DjVu v3
        documentation endorses tags borrowed from two standards: 1) BibTeX
        bibliography system tags (all lowercase Tag ID's in the table below), and 2)
        PDF DocInfo tags (uppercase Tag ID's).
    },
    # BibTeX tags (ref http://en.wikipedia.org/wiki/BibTeX)
    address     => { Groups => { 2 => 'Location' } },
    annote      => { Name => 'Annotation' },
    author      => { Groups => { 2 => 'Author' } },
    booktitle   => { Name => 'BookTitle' },
    chapter     => { },
    crossref    => { Name => 'CrossRef' },
    edition     => { },
    eprint      => { Name => 'EPrint' },
    howpublished=> { Name => 'HowPublished' },
    institution => { },
    journal     => { },
    key         => { },
    month       => { Groups => { 2 => 'Time' } },
    note        => { },
    number      => { },
    organization=> { },
    pages       => { },
    publisher   => { },
    school      => { },
    series      => { },
    title       => { },
    type        => { },
    url         => { Name => 'URL' },
    volume      => { },
    year        => { Groups => { 2 => 'Time' } },
    # PDF tags (same as Image::ExifTool::PDF::Info)
    Title       => { },
    Author      => { Groups => { 2 => 'Author' } },
    Subject     => { },
    Keywords    => { },
    Creator     => { },
    Producer    => { },
    CreationDate => {
        Name => 'CreateDate',
        Groups => { 2 => 'Time' },
        # RFC 3339 date/time format
        ValueConv => 'require Image::ExifTool::XMP; Image::ExifTool::XMP::ConvertXMPDate($val)',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    ModDate => {
        Name => 'ModifyDate',
        Groups => { 2 => 'Time' },
        ValueConv => 'require Image::ExifTool::XMP; Image::ExifTool::XMP::ConvertXMPDate($val)',
        PrintConv => '$self->ConvertDateTime($val)',
    },
    Trapped => {
        # remove leading '/' from '/True' or '/False'
        ValueConv => '$val=~s{^/}{}; $val',
    },
);

sub ParseAnt($)
{
    my $dataPt = shift;
    my (@toks, $tok, $more);
    # (the DjVu annotation syntax really sucks, and requires that every
    # single token be parsed in order to properly scan through the items)
Tok: for (;;) {
        # find the next token
        last unless $$dataPt =~ /(\S)/sg;   # get next non-space character
        if ($1 eq '(') {       # start of list
            $tok = ParseAnt($dataPt);
        } elsif ($1 eq ')') {  # end of list
            $more = 1;
            last;
        } elsif ($1 eq '"') {  # quoted string
            $tok = '';
            for (;;) {
                # get string up to the next quotation mark
                # this doesn't work in perl 5.6.2! grrrr
                # last Tok unless $$dataPt =~ /(.*?)"/sg;
                # $tok .= $1;
                my $pos = pos($$dataPt);
                last Tok unless $$dataPt =~ /"/sg;
                $tok .= substr($$dataPt, $pos, pos($$dataPt)-1-$pos);
                # we're good unless quote was escaped by odd number of backslashes
                last unless $tok =~ /(\\+)$/ and length($1) & 0x01;
                $tok .= '"';    # quote is part of the string
            }
            # convert C escape sequences (allowed in quoted text)
            $tok = eval qq{"$tok"};
        } else {                # key name
            pos($$dataPt) = pos($$dataPt) - 1;
            # allow anything in key but whitespace, braces and double quotes
            # (this is one of those assumptions I mentioned)
            $$dataPt =~ /([^\s()"]+)/sg;
            $tok = $1;
        }
        push @toks, $tok if defined $tok;
    }
    # prevent further parsing unless more after this
    pos($$dataPt) = length $$dataPt unless $more;
    return @toks ? \@toks : undef;
}

sub ProcessAnt($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};

    # quick pre-scan to check for metadata or XMP
    return 1 unless $$dataPt =~ /\(\s*(metadata|xmp)[\s("]/s;

    # parse annotations into a tree structure
    pos($$dataPt) = 0;
    my $toks = ParseAnt($dataPt) or return 0;

    # process annotations individually
    my $ant;
    foreach $ant (@$toks) {
        next unless ref $ant eq 'ARRAY' and @$ant >= 2;
        my $tag = shift @$ant;
        next if ref $tag or not defined $$tagTablePtr{$tag};
        if ($tag eq 'metadata') {
            # ProcessMeta() takes array reference
            $exifTool->HandleTag($tagTablePtr, $tag, $ant);
        } else {
            next if ref $$ant[0];   # only process simple values
            $exifTool->HandleTag($tagTablePtr, $tag, $$ant[0]);
        }
    }
    return 1;
}

sub ProcessMeta($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    return 0 unless ref $$dataPt eq 'ARRAY';
    $exifTool->VerboseDir('Metadata', scalar @$$dataPt);
    my ($item, $err);
    foreach $item (@$$dataPt) {
        # make sure item is a simple tag/value pair
        $err=1, next unless ref $item eq 'ARRAY' and @$item >= 2 and
                            not ref $$item[0] and not ref $$item[1];
        # add any new tags to the table
        unless ($$tagTablePtr{$$item[0]}) {
            my $name = $$item[0];
            $name =~ tr/-_a-zA-Z0-9//dc; # remove illegal characters
            length $name or $err = 1, next;
            Image::ExifTool::AddTagToTable($tagTablePtr, $$item[0], { Name => ucfirst($name) });
        }
        $exifTool->HandleTag($tagTablePtr, $$item[0], $$item[1]);
    }
    $err and $exifTool->Warn('Ignored invalid metadata entry(s)');
    return 1;
}

sub ProcessBZZ($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    require Image::ExifTool::BZZ;
    my $buff = Image::ExifTool::BZZ::Decode($$dirInfo{DataPt});
    unless (defined $buff) {
        $exifTool->Warn("Error decoding $$dirInfo{DirName}");
        return 0;
    }
    my $verbose = $exifTool->Options('Verbose');
    if ($verbose >= 3) {
        # dump the decoded data in very verbose mode
        $exifTool->VerboseDir("Decoded $$dirInfo{DirName}", 0, length $buff);
        $exifTool->VerboseDump(\$buff);
    }
    $$dirInfo{DataPt} = \$buff;
    $$dirInfo{DataLen} = $$dirInfo{DirLen} = length $buff;
    # process the data using the default process proc for this table
    my $processProc = $$tagTablePtr{PROCESS_PROC} or return 0;
    return &$processProc($exifTool, $dirInfo, $tagTablePtr);
}

1;  # end

__END__


