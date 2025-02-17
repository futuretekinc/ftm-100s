
package Image::ExifTool::XMP;

use strict;
use vars qw($VERSION $AUTOLOAD @ISA @EXPORT_OK $xlatNamespace %nsURI %dateTimeInfo
            %xmpTableDefaults %specialStruct %sDimensions %sArea %sColorant);
use Image::ExifTool qw(:Utils);
use Image::ExifTool::Exif;
require Exporter;

$VERSION = '2.40';
@ISA = qw(Exporter);
@EXPORT_OK = qw(EscapeXML UnescapeXML);

sub ProcessXMP($$;$);
sub WriteXMP($$;$);
sub CheckXMP($$$);
sub ParseXMPElement($$$;$$$);
sub DecodeBase64($);
sub SaveBlankInfo($$$;$);
sub ProcessBlankInfo($$$;$);
sub ValidateXMP($;$);
sub UnescapeChar($$);
sub AddFlattenedTags($$);
sub FormatXMPDate($);
sub ConvertRational($);

my %curNS;  # namespaces currently in effect while parsing the file

my %stdXlatNS = (
    # shorten ugly namespace prefixes
    'Iptc4xmpCore' => 'iptcCore',
    'Iptc4xmpExt' => 'iptcExt',
    'photomechanic'=> 'photomech',
    'MicrosoftPhoto' => 'microsoft',
    'prismusagerights' => 'pur',
);

my %xmpNS = (
    # shorten ugly namespace prefixes
    'iptcCore' => 'Iptc4xmpCore',
    'iptcExt' => 'Iptc4xmpExt',
    'photomechanic'=> 'photomech',
    'microsoft' => 'MicrosoftPhoto',
    # (prism changed their spec to now use 'pur')
    # 'pur' => 'prismusagerights',
);

%nsURI = (
    aux       => 'http://ns.adobe.com/exif/1.0/aux/',
    album     => 'http://ns.adobe.com/album/1.0/',
    cc        => 'http://creativecommons.org/ns#', # changed 2007/12/21 - PH
    crs       => 'http://ns.adobe.com/camera-raw-settings/1.0/',
    crss      => 'http://ns.adobe.com/camera-raw-saved-settings/1.0/',
    dc        => 'http://purl.org/dc/elements/1.1/',
    exif      => 'http://ns.adobe.com/exif/1.0/',
    iX        => 'http://ns.adobe.com/iX/1.0/',
    pdf       => 'http://ns.adobe.com/pdf/1.3/',
    pdfx      => 'http://ns.adobe.com/pdfx/1.3/',
    photoshop => 'http://ns.adobe.com/photoshop/1.0/',
    rdf       => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
    rdfs      => 'http://www.w3.org/2000/01/rdf-schema#',
    stDim     => 'http://ns.adobe.com/xap/1.0/sType/Dimensions#',
    stEvt     => 'http://ns.adobe.com/xap/1.0/sType/ResourceEvent#',
    stFnt     => 'http://ns.adobe.com/xap/1.0/sType/Font#',
    stJob     => 'http://ns.adobe.com/xap/1.0/sType/Job#',
    stRef     => 'http://ns.adobe.com/xap/1.0/sType/ResourceRef#',
    stVer     => 'http://ns.adobe.com/xap/1.0/sType/Version#',
    stMfs     => 'http://ns.adobe.com/xap/1.0/sType/ManifestItem#',
    tiff      => 'http://ns.adobe.com/tiff/1.0/',
   'x'        => 'adobe:ns:meta/',
    xmpG      => 'http://ns.adobe.com/xap/1.0/g/',
    xmpGImg   => 'http://ns.adobe.com/xap/1.0/g/img/',
    xmp       => 'http://ns.adobe.com/xap/1.0/',
    xmpBJ     => 'http://ns.adobe.com/xap/1.0/bj/',
    xmpDM     => 'http://ns.adobe.com/xmp/1.0/DynamicMedia/',
    xmpMM     => 'http://ns.adobe.com/xap/1.0/mm/',
    xmpRights => 'http://ns.adobe.com/xap/1.0/rights/',
    xmpNote   => 'http://ns.adobe.com/xmp/note/',
    xmpTPg    => 'http://ns.adobe.com/xap/1.0/t/pg/',
    xmpidq    => 'http://ns.adobe.com/xmp/Identifier/qual/1.0/',
    xmpPLUS   => 'http://ns.adobe.com/xap/1.0/PLUS/',
    dex       => 'http://ns.optimasc.com/dex/1.0/',
    mediapro  => 'http://ns.iview-multimedia.com/mediapro/1.0/',
    Iptc4xmpCore => 'http://iptc.org/std/Iptc4xmpCore/1.0/xmlns/',
    Iptc4xmpExt => 'http://iptc.org/std/Iptc4xmpExt/2008-02-29/',
    MicrosoftPhoto => 'http://ns.microsoft.com/photo/1.0',
    MP1       => 'http://ns.microsoft.com/photo/1.1', #PH (MP1 is fabricated)
    MP        => 'http://ns.microsoft.com/photo/1.2/',
    MPRI      => 'http://ns.microsoft.com/photo/1.2/t/RegionInfo#',
    MPReg     => 'http://ns.microsoft.com/photo/1.2/t/Region#',
    lr        => 'http://ns.adobe.com/lightroom/1.0/',
    DICOM     => 'http://ns.adobe.com/DICOM/',
    svg       => 'http://www.w3.org/2000/svg',
    et        => 'http://ns.exiftool.ca/1.0/',
    # namespaces defined in XMP2.pl:
    plus      => 'http://ns.useplus.org/ldf/xmp/1.0/',
    prism     => 'http://prismstandard.org/namespaces/basic/2.1/',
    prl       => 'http://prismstandard.org/namespaces/prl/2.1/',
    pur       => 'http://prismstandard.org/namespaces/prismusagerights/2.1/',
    acdsee    => 'http://ns.acdsee.com/iptc/1.0/',
    digiKam   => 'http://www.digikam.org/ns/1.0/',
    swf       => 'http://ns.adobe.com/swf/1.0',
    cell      => 'http://developer.sonyericsson.com/cell/1.0/',
   'mwg-rs'   => 'http://www.metadataworkinggroup.com/schemas/regions/',
   'mwg-kw'   => 'http://www.metadataworkinggroup.com/schemas/keywords/',
   'mwg-coll' => 'http://www.metadataworkinggroup.com/schemas/collections/',
    stArea    => 'http://ns.adobe.com/xmp/sType/Area#',
    extensis  => 'http://ns.extensis.com/extensis/1.0/',
);

my %uri2ns;
{
    my $ns;
    foreach $ns (keys %nsURI) {
        $uri2ns{$nsURI{$ns}} = $ns;
    }
}

sub ToDegrees
{
    require Image::ExifTool::GPS;
    Image::ExifTool::GPS::ToDegrees($_[0], 1);
}
my %latConv = (
    ValueConv    => \&ToDegrees,
    RawConv => 'require Image::ExifTool::GPS; $val', # to load Composite tags and routines
    ValueConvInv => q{
        require Image::ExifTool::GPS;
        Image::ExifTool::GPS::ToDMS($self, $val, 2, "N");
    },
    PrintConv    => 'Image::ExifTool::GPS::ToDMS($self, $val, 1, "N")',
    PrintConvInv => \&ToDegrees,
);
my %longConv = (
    ValueConv    => \&ToDegrees,
    RawConv => 'require Image::ExifTool::GPS; $val',
    ValueConvInv => q{
        require Image::ExifTool::GPS;
        Image::ExifTool::GPS::ToDMS($self, $val, 2, "E");
    },
    PrintConv    => 'Image::ExifTool::GPS::ToDMS($self, $val, 1, "E")',
    PrintConvInv => \&ToDegrees,
);
%dateTimeInfo = (
    # NOTE: Do NOT put "Groups" here because Groups hash must not be common!
    Writable => 'date',
    Shift => 'Time',
    PrintConv => '$self->ConvertDateTime($val)',
    PrintConvInv => '$self->InverseDateTime($val,undef,1)',
);

my %ignoreNamespace = ( 'x'=>1, rdf=>1, xmlns=>1, xml=>1, svg=>1, et=>1, office=>1 );

my %recognizedAttrs = (
    'rdf:about' => [ 'Image::ExifTool::XMP::rdf', 'about', 'About' ],
    'x:xmptk'   => [ 'Image::ExifTool::XMP::x',   'xmptk', 'XMPToolkit' ],
    'x:xaptk'   => [ 'Image::ExifTool::XMP::x',   'xmptk', 'XMPToolkit' ],
    'rdf:parseType' => 1,
    'rdf:nodeID' => 1,
    'et:toolkit' => 1,
    'rdf:xmlns' => 1, # this is presumably the default namespace, which we currently ignore
);

%specialStruct = (
    STRUCT_NAME => 1, # [optional] name of structure
    NAMESPACE   => 1, # [mandatory] namespace prefix used for fields of this structure
    NOTES       => 1, # [optional] notes for documentation about this structure
    TYPE        => 1, # [optional] rdf:type resource for struct (if used, the StructType flag
                      # will be set automatically for all derived flattened tags when writing)
);
my %sResourceRef = (
    STRUCT_NAME => 'ResourceRef',
    NAMESPACE   => 'stRef',
    documentID      => { },
    instanceID      => { },
    manager         => { },
    managerVariant  => { },
    manageTo        => { },
    manageUI        => { },
    renditionClass  => { },
    renditionParams => { },
    versionID       => { },
    # added Oct 2008
    alternatePaths  => { List => 'Seq' },
    filePath        => { },
    fromPart        => { },
    lastModifyDate  => { %dateTimeInfo, Groups => { 2 => 'Time' } },
    maskMarkers     => { PrintConv => { All => 'All', None => 'None' } },
    partMapping     => { },
    toPart          => { },
    # added May 2010
    originalDocumentID => { }, # (undocumented property written by Adobe InDesign)
);
my %sResourceEvent = (
    STRUCT_NAME => 'ResourceEvent',
    NAMESPACE   => 'stEvt',
    action          => { },
    instanceID      => { },
    parameters      => { },
    softwareAgent   => { },
    when            => { %dateTimeInfo, Groups => { 2 => 'Time' } },
    # added Oct 2008
    changed         => { },
);
my %sJobRef = (
    STRUCT_NAME => 'JobRef',
    NAMESPACE   => 'stJob',
    id          => { },
    name        => { },
    url         => { },
);
my %sVersion = (
    STRUCT_NAME => 'Version',
    NAMESPACE   => 'stVer',
    comments    => { },
    event       => { Struct => \%sResourceEvent },
    modifier    => { },
    modifyDate  => { %dateTimeInfo, Groups => { 2 => 'Time' } },
    version     => { },
);
my %sThumbnail = (
    STRUCT_NAME => 'Thumbnail',
    NAMESPACE   => 'xmpGImg',
    height      => { Writable => 'integer' },
    width       => { Writable => 'integer' },
   'format'     => { },
    image       => {
        ValueConv => 'Image::ExifTool::XMP::DecodeBase64($val)',
        ValueConvInv => 'Image::ExifTool::XMP::EncodeBase64($val)',
    },
);
my %sPageInfo = (
    STRUCT_NAME => 'PageInfo',
    NAMESPACE   => 'xmpGImg',
    PageNumber  => { Writable => 'integer', Namespace => 'xmpTPg' }, # override default namespace
    height      => { Writable => 'integer' },
    width       => { Writable => 'integer' },
   'format'     => { },
    image       => {
        ValueConv => 'Image::ExifTool::XMP::DecodeBase64($val)',
        ValueConvInv => 'Image::ExifTool::XMP::EncodeBase64($val)',
    },
);
%sDimensions = (
    STRUCT_NAME => 'Dimensions',
    NAMESPACE   => 'stDim',
    w           => { Writable => 'real' },
    h           => { Writable => 'real' },
    unit        => { },
);
%sArea = (
    STRUCT_NAME => 'Area',
    NAMESPACE   => 'stArea',
   'x'          => { Writable => 'real' },
   'y'          => { Writable => 'real' },
    w           => { Writable => 'real' },
    h           => { Writable => 'real' },
    d           => { Writable => 'real' },
    unit        => { },
);
%sColorant = (
    STRUCT_NAME => 'Colorant',
    NAMESPACE   => 'xmpG',
    swatchName  => { },
    mode        => { PrintConv => { CMYK=>'CMYK', RGB=>'RGB', LAB=>'Lab' } },
    # note: do not implement closed choice for "type" because Adobe can't
    # get the case right:  spec. says "PROCESS" but Indesign writes "Process"
    type        => { },
    cyan        => { Writable => 'real' },
    magenta     => { Writable => 'real' },
    yellow      => { Writable => 'real' },
    black       => { Writable => 'real' },
    red         => { Writable => 'integer' },
    green       => { Writable => 'integer' },
    blue        => { Writable => 'integer' },
    L           => { Writable => 'real' },
    A           => { Writable => 'integer' },
    B           => { Writable => 'integer' },
);
my %sFont = (
    STRUCT_NAME => 'Font',
    NAMESPACE   => 'stFnt',
    fontName    => { },
    fontFamily  => { },
    fontFace    => { },
    fontType    => { },
    versionString => { },
    composite   => { Writable => 'boolean' },
    fontFileName=> { },
    childFontFiles => { List => 'Seq' },
);
my %sOECF = (
    NAMESPACE   => 'exif',
    STRUCT_NAME => 'OECF',
    Columns     => { Writable => 'integer' },
    Rows        => { Writable => 'integer' },
    Names       => { List => 'Seq' },
    Values      => { List => 'Seq', Writable => 'rational' },
);

my %sCorrectionMask = (
    STRUCT_NAME => 'CorrectionMask',
    NAMESPACE   => 'crs',
    What         => { },
    MaskValue    => { Writable => 'real' },
    Radius       => { Writable => 'real' },
    Flow         => { Writable => 'real' },
    CenterWeight => { Writable => 'real' },
    Dabs         => { List => 'Seq' },
    ZeroX        => { Writable => 'real' },
    ZeroY        => { Writable => 'real' },
    FullX        => { Writable => 'real' },
    FullY        => { Writable => 'real' },
);
my %sCorrection = (
    STRUCT_NAME => 'Correction',
    NAMESPACE   => 'crs',
    What => { },
    CorrectionAmount => { Writable => 'real' },
    CorrectionActive => { Writable => 'boolean' },
    LocalExposure    => { Writable => 'real' },
    LocalSaturation  => { Writable => 'real' },
    LocalContrast    => { Writable => 'real' },
    LocalClarity     => { Writable => 'real' },
    LocalSharpness   => { Writable => 'real' },
    LocalBrightness  => { Writable => 'real' },
    LocalToningHue   => { Writable => 'real' },
    LocalToningSaturation => { Writable => 'real' },
    CorrectionMasks  => { Struct => \%sCorrectionMask, List => 'Seq' },
);

my %sLocationDetails = (
    NAMESPACE   => 'Iptc4xmpExt',
    STRUCT_NAME => 'LocationDetails',
    City         => { },
    CountryCode  => { },
    CountryName  => { },
    ProvinceState=> { },
    Sublocation  => { },
    WorldRegion  => { },
);

%Image::ExifTool::XMP::Main = (
    GROUPS => { 2 => 'Unknown' },
    PROCESS_PROC => \&ProcessXMP,
    WRITE_PROC => \&WriteXMP,
    dc => {
        Name => 'dc', # (otherwise generated name would be 'Dc')
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::dc' },
    },
    xmp => {
        Name => 'xmp',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmp' },
    },
    xmpDM => {
        Name => 'xmpDM',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmpDM' },
    },
    xmpRights => {
        Name => 'xmpRights',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmpRights' },
    },
    xmpNote => {
        Name => 'xmpNote',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmpNote' },
    },
    xmpMM => {
        Name => 'xmpMM',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmpMM' },
    },
    xmpBJ => {
        Name => 'xmpBJ',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmpBJ' },
    },
    xmpTPg => {
        Name => 'xmpTPg',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmpTPg' },
    },
    pdf => {
        Name => 'pdf',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::pdf' },
    },
    pdfx => {
        Name => 'pdfx',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::pdfx' },
    },
    photoshop => {
        Name => 'photoshop',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::photoshop' },
    },
    crs => {
        Name => 'crs',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::crs' },
    },
    # crss - it would be difficult to add the ability to write this
    aux => {
        Name => 'aux',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::aux' },
    },
    tiff => {
        Name => 'tiff',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::tiff' },
    },
    exif => {
        Name => 'exif',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::exif' },
    },
    iptcCore => {
        Name => 'iptcCore',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::iptcCore' },
    },
    iptcExt => {
        Name => 'iptcExt',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::iptcExt' },
    },
    PixelLive => {
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::PixelLive' },
    },
    xmpPLUS => {
        Name => 'xmpPLUS',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::xmpPLUS' },
    },
    plus => {
        Name => 'plus',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::plus' },
    },
    cc => {
        Name => 'cc',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::cc' },
    },
    dex => {
        Name => 'dex',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::dex' },
    },
    photomech => {
        Name => 'photomech',
        SubDirectory => { TagTable => 'Image::ExifTool::PhotoMechanic::XMP' },
    },
    mediapro => {
        Name => 'mediapro',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::MediaPro' },
    },
    microsoft => {
        Name => 'microsoft',
        SubDirectory => { TagTable => 'Image::ExifTool::Microsoft::XMP' },
    },
    MP => {
        Name => 'MP',
        SubDirectory => { TagTable => 'Image::ExifTool::Microsoft::MP' },
    },
    MP1 => {
        Name => 'MP1',
        SubDirectory => { TagTable => 'Image::ExifTool::Microsoft::MP1' },
    },
    lr => {
        Name => 'lr',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::Lightroom' },
    },
    DICOM => {
        Name => 'DICOM',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::DICOM' },
    },
    album => {
        Name => 'album',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::Album' },
    },
    prism => {
        Name => 'prism',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::prism' },
    },
    prl => {
        Name => 'prl',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::prl' },
    },
    pur => {
        Name => 'pur',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::pur' },
    },
    rdf => {
        Name => 'rdf',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::rdf' },
    },
   'x' => {
        Name => 'x',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::x' },
    },
    acdsee => {
        Name => 'acdsee',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::acdsee' },
    },
    digiKam => {
        Name => 'digiKam',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::digiKam' },
    },
    swf => {
        Name => 'swf',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::swf' },
    },
    cell => {
        Name => 'cell',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::cell' },
    },
   'mwg-rs' => {
        Name => 'mwg-rs',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::mwg_rs' },
    },
   'mwg-kw' => {
        Name => 'mwg-kw',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::mwg_kw' },
    },
   'mwg-coll' => {
        Name => 'mwg-coll',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::mwg_coll' },
    },
    extensis => {
        Name => 'extensis',
        SubDirectory => { TagTable => 'Image::ExifTool::XMP::extensis' },
    }
);

%xmpTableDefaults = (
    WRITE_PROC => \&WriteXMP,
    CHECK_PROC => \&CheckXMP,
    WRITABLE => 'string',
    LANG_INFO => \&GetLangInfo,
);

%Image::ExifTool::XMP::rdf = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-rdf', 2 => 'Document' },
    NAMESPACE   => 'rdf',
    NOTES => q{
        Most RDF attributes are handled internally, but the "about" attribute is
        treated specially to allow it to be set to a specific value if required.
    },
    about => { Protected => 1 },
);

%Image::ExifTool::XMP::x = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-x', 2 => 'Document' },
    NAMESPACE   => 'x',
    NOTES => qq{
        The "x" namespace is used for the "xmpmeta" wrapper, and may contain an
        "xmptk" attribute that is extracted as the XMPToolkit tag.  When writing,
        the XMPToolkit tag is automatically generated by ExifTool unless
        specifically set to another value.
    },
    xmptk => { Name => 'XMPToolkit', Protected => 1 },
);

%Image::ExifTool::XMP::dc = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-dc', 2 => 'Other' },
    NAMESPACE   => 'dc',
    TABLE_DESC => 'XMP Dublin Core',
    NOTES => 'Dublin Core schema tags.',
    contributor => { Groups => { 2 => 'Author' }, List => 'Bag' },
    coverage    => { },
    creator     => { Groups => { 2 => 'Author' }, List => 'Seq' },
    date        => { Groups => { 2 => 'Time' },   List => 'Seq', %dateTimeInfo },
    description => { Groups => { 2 => 'Image'  }, Writable => 'lang-alt' },
   'format'     => { Groups => { 2 => 'Image'  } },
    identifier  => { Groups => { 2 => 'Image'  } },
    language    => { List => 'Bag' },
    publisher   => { Groups => { 2 => 'Author' }, List => 'Bag' },
    relation    => { List => 'Bag' },
    rights      => { Groups => { 2 => 'Author' }, Writable => 'lang-alt' },
    source      => { Groups => { 2 => 'Author' }, Avoid => 1 },
    subject     => { Groups => { 2 => 'Image'  }, List => 'Bag' },
    title       => { Groups => { 2 => 'Image'  }, Writable => 'lang-alt' },
    type        => { Groups => { 2 => 'Image'  }, List => 'Bag' },
);

%Image::ExifTool::XMP::xmp = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmp', 2 => 'Image' },
    NAMESPACE   => 'xmp',
    NOTES => q{
        XMP Basic schema tags.  If the older "xap", "xapBJ", "xapMM" or "xapRights"
        namespace prefixes are found, they are translated to the newer "xmp",
        "xmpBJ", "xmpMM" and "xmpRights" prefixes for use in family 1 group names.
    },
    Advisory    => { List => 'Bag', Notes => 'deprecated' },
    BaseURL     => { },
    # (date/time tags not as reliable as EXIF)
    CreateDate  => { Groups => { 2 => 'Time' }, %dateTimeInfo, Priority => 0 },
    CreatorTool => { },
    Identifier  => { Avoid => 1, List => 'Bag' },
    Label       => { },
    MetadataDate=> { Groups => { 2 => 'Time' }, %dateTimeInfo },
    ModifyDate  => { Groups => { 2 => 'Time' }, %dateTimeInfo, Priority => 0 },
    Nickname    => { },
    Rating      => { Writable => 'real', Notes => 'a value from 0 to 5, or -1 for "rejected"' },
    Thumbnails  => { Struct => \%sThumbnail, List => 'Alt' },
    ThumbnailsHeight => { Name => 'ThumbnailHeight', Flat => 1 },
    ThumbnailsWidth  => { Name => 'ThumbnailWidth',  Flat => 1 },
    ThumbnailsFormat => { Name => 'ThumbnailFormat', Flat => 1 },
    ThumbnailsImage  => { Name => 'ThumbnailImage',  Flat => 1, Avoid => 1 },
    # the following written by Adobe InDesign, not part of XMP spec:
    PageInfo        => { Struct => \%sPageInfo, List => 'Seq' },
    PageInfoPageNumber=>{Name => 'PageImagePageNumber', Flat => 1 },
    PageInfoHeight  => { Name => 'PageImageHeight', Flat => 1 },
    PageInfoWidth   => { Name => 'PageImageWidth',  Flat => 1 },
    PageInfoFormat  => { Name => 'PageImageFormat', Flat => 1 },
    PageInfoImage   => { Name => 'PageImage',       Flat => 1 },
    Title       => { Avoid => 1, Notes => 'non-standard', Writable => 'lang-alt' }, #11
    Author      => { Avoid => 1, Notes => 'non-standard', Groups => { 2 => 'Author' } }, #11
    Keywords    => { Avoid => 1, Notes => 'non-standard' }, #11
    Description => { Avoid => 1, Notes => 'non-standard', Writable => 'lang-alt' }, #11
    Format      => { Avoid => 1, Notes => 'non-standard' }, #11
);

%Image::ExifTool::XMP::xmpRights = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmpRights', 2 => 'Author' },
    NAMESPACE   => 'xmpRights',
    NOTES => 'XMP Rights Management schema tags.',
    Certificate     => { },
    Marked          => { Writable => 'boolean' },
    Owner           => { List => 'Bag' },
    UsageTerms      => { Writable => 'lang-alt' },
    WebStatement    => { },
);

%Image::ExifTool::XMP::xmpNote = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmpNote' },
    NAMESPACE   => 'xmpNote',
    NOTES => 'XMP Note schema tags.',
    HasExtendedXMP => { Writable => 'boolean', Protected => 2 },
);

my %sManifestItem = (
    NAMESPACE => 'stMfs',
    STRUCT_NAME => 'ManifestItem',
    linkForm            => { },
    placedXResolution   => { Namespace => 'xmpMM', Writable => 'real' },
    placedYResolution   => { Namespace => 'xmpMM', Writable => 'real' },
    placedResolutionUnit=> { Namespace => 'xmpMM' },
    reference           => { Struct => \%sResourceRef },
);

my %sPantryItem = (
    NAMESPACE => undef, # stores any top-level XMP tags
    STRUCT_NAME => 'PantryItem',
    NOTES => q{
        This structure must have an InstanceID field, but may also contain any other
        XMP properties.
    },
    InstanceID => { Namespace => 'xmpMM' },
);

%Image::ExifTool::XMP::xmpMM = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmpMM', 2 => 'Other' },
    NAMESPACE   => 'xmpMM',
    TABLE_DESC => 'XMP Media Management',
    NOTES => 'XMP Media Management schema tags.',
    DerivedFrom     => { Struct => \%sResourceRef },
    DocumentID      => { },
    History         => { Struct => \%sResourceEvent, List => 'Seq' },
    # we treat these like list items since History is a list
    Ingredients     => { Struct => \%sResourceRef, List => 'Bag' },
    InstanceID      => { }, #PH (CS3)
    ManagedFrom     => { Struct => \%sResourceRef },
    Manager         => { Groups => { 2 => 'Author' } },
    ManageTo        => { Groups => { 2 => 'Author' } },
    ManageUI        => { },
    ManagerVariant  => { },
    Manifest        => { Struct => \%sManifestItem, List => 'Bag' },
    OriginalDocumentID=> { },
    Pantry          => { Struct => \%sPantryItem, List => 'Bag' },
    PreservedFileName => { },   # undocumented
    RenditionClass  => { },
    RenditionParams => { },
    VersionID       => { },
    Versions        => { Struct => \%sVersion, List => 'Seq' },
    LastURL         => { }, # (deprecated)
    RenditionOf     => { Struct => \%sResourceRef }, # (deprecated)
    SaveID          => { Writable => 'integer' }, # (deprecated)
    subject         => { List => 'Seq', Avoid => 1, Notes => 'undocumented' },
);

%Image::ExifTool::XMP::xmpBJ = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmpBJ', 2 => 'Other' },
    NAMESPACE   => 'xmpBJ',
    TABLE_DESC => 'XMP Basic Job Ticket',
    NOTES => 'XMP Basic Job Ticket schema tags.',
    # Note: JobRef is a List of structures.  To accomplish this, we set the XMP
    # List=>'Bag', but since SubDirectory is defined, this tag isn't writable
    # directly.  Then we need to set List=>1 for the members so the Writer logic
    # will allow us to add list items.
    JobRef => { Struct => \%sJobRef, List => 'Bag' },
);

%Image::ExifTool::XMP::xmpTPg = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmpTPg', 2 => 'Image' },
    NAMESPACE   => 'xmpTPg',
    TABLE_DESC => 'XMP Paged-Text',
    NOTES => 'XMP Paged-Text schema tags.',
    MaxPageSize         => { Struct => \%sDimensions },
    NPages              => { Writable => 'integer' },
    Fonts               => { Struct => \%sFont, List => 'Bag' },
    FontsFontName       => { Flat => 1, Name => 'FontName' },
    FontsFontFamily     => { Flat => 1, Name => 'FontFamily' },
    FontsFontFace       => { Flat => 1, Name => 'FontFace' },
    FontsFontType       => { Flat => 1, Name => 'FontType' },
    FontsVersionString  => { Flat => 1, Name => 'FontVersion' },
    FontsComposite      => { Flat => 1, Name => 'FontComposite' },
    FontsFontFileName   => { Flat => 1, Name => 'FontFileName' },
    FontsChildFontFiles => { Flat => 1, Name => 'ChildFontFiles' },
    Colorants           => { Struct => \%sColorant, List => 'Seq' },
    ColorantsSwatchName => { Flat => 1, Name => 'ColorantSwatchName' },
    ColorantsMode       => { Flat => 1, Name => 'ColorantMode' },
    ColorantsType       => { Flat => 1, Name => 'ColorantType' },
    ColorantsCyan       => { Flat => 1, Name => 'ColorantCyan' },
    ColorantsMagenta    => { Flat => 1, Name => 'ColorantMagenta' },
    ColorantsYellow     => { Flat => 1, Name => 'ColorantYellow' },
    ColorantsBlack      => { Flat => 1, Name => 'ColorantBlack' },
    ColorantsRed        => { Flat => 1, Name => 'ColorantRed' },
    ColorantsGreen      => { Flat => 1, Name => 'ColorantGreen' },
    ColorantsBlue       => { Flat => 1, Name => 'ColorantBlue' },
    ColorantsL          => { Flat => 1, Name => 'ColorantL' },
    ColorantsA          => { Flat => 1, Name => 'ColorantA' },
    ColorantsB          => { Flat => 1, Name => 'ColorantB' },
    PlateNames          => { List => 'Seq' },
);

%Image::ExifTool::XMP::pdf = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-pdf', 2 => 'Image' },
    NAMESPACE   => 'pdf',
    TABLE_DESC => 'XMP PDF',
    NOTES => q{
        Adobe PDF schema tags.  The official XMP specification defines only
        Keywords, PDFVersion, Producer and Trapped.  The other tags are included
        because they have been observed in PDF files, but some are avoided when
        writing due to name conflicts with other XMP namespaces.
    },
    Author      => { Groups => { 2 => 'Author' } }, #PH
    ModDate     => { Groups => { 2 => 'Time' }, %dateTimeInfo }, #PH
    CreationDate=> { Groups => { 2 => 'Time' }, %dateTimeInfo }, #PH
    Creator     => { Groups => { 2 => 'Author' }, Avoid => 1 },
    Copyright   => { Groups => { 2 => 'Author' }, Avoid => 1 }, #PH
    Marked      => { Avoid => 1, Writable => 'boolean' }, #PH
    Subject     => { Avoid => 1 },
    Title       => { Avoid => 1 },
    Trapped     => { #PH
        # remove leading '/' from '/True' or '/False'
        ValueConv => '$val=~s{^/}{}; $val',
        ValueConvInv => '"/$val"',
        PrintConv => { True => 'True', False => 'False', Unknown => 'Unknown' },
    },
    Keywords    => { },
    PDFVersion  => { },
    Producer    => { Groups => { 2 => 'Author' } },
);

%Image::ExifTool::XMP::pdfx = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-pdfx', 2 => 'Document' },
    NAMESPACE   => 'pdfx',
    NOTES => q{
        PDF extension tags.  This namespace is used to store application-defined PDF
        information, so there are no pre-defined tags.  User-defined tags must be
        created to enable writing of XMP-pdfx information.
    },
);

%Image::ExifTool::XMP::photoshop = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-photoshop', 2 => 'Image' },
    NAMESPACE   => 'photoshop',
    TABLE_DESC => 'XMP Photoshop',
    NOTES => 'Adobe Photoshop schema tags.',
    AuthorsPosition => { Groups => { 2 => 'Author' } },
    CaptionWriter   => { Groups => { 2 => 'Author' } },
    Category        => { },
    City            => { Groups => { 2 => 'Location' } },
    ColorMode       => {
        Writable => 'integer', # (as of July 2010 spec, courtesy of yours truly)
        PrintConvColumns => 2,
        PrintConv => {
            0 => 'Bitmap',
            1 => 'Grayscale',
            2 => 'Indexed',
            3 => 'RGB',
            4 => 'CMYK',
            7 => 'Multichannel',
            8 => 'Duotone',
            9 => 'Lab',
        },
    },
    Country         => { Groups => { 2 => 'Location' } },
    Credit          => { Groups => { 2 => 'Author' } },
    DateCreated     => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    DocumentAncestors => {
        List => 'bag',
        Struct => {
            STRUCT_NAME => 'Ancestor',
            NAMESPACE   => 'photoshop',
            AncestorID => { },
        },
    },
    DocumentAncestorsAncestorID => { Name => 'DocumentAncestorID', Flat => 1 },
    Headline        => { },
    History         => { }, #PH (CS3)
    ICCProfile      => { Name => 'ICCProfileName' }, #PH
    Instructions    => { },
    LegacyIPTCDigest=> { }, #PH
    SidecarForExtension => { }, #PH (CS3)
    Source          => { Groups => { 2 => 'Author' } },
    State           => { Groups => { 2 => 'Location' } },
    # the XMP spec doesn't show SupplementalCategories as a 'Bag', but
    # that's the way Photoshop writes it [fixed in the June 2005 XMP spec].
    # Also, it is incorrectly listed as "SupplementalCategory" in the
    # IPTC Standard Photo Metadata docs (2008rev2 and July 2009rev1) - PH
    SupplementalCategories  => { List => 'Bag' },
    TextLayers => {
        List => 'seq',
        Struct => {
            STRUCT_NAME => 'Layer',
            NAMESPACE   => 'photoshop',
            LayerName => { },
            LayerText => { },
        },
    },
    TextLayersLayerName => { Flat => 1, Name => 'TextLayerName' },
    TextLayersLayerText => { Flat => 1, Name => 'TextLayerText' },
    TransmissionReference   => { },
    Urgency         => {
        Writable => 'integer',
        Notes => 'should be in the range 1-8 to conform with the XMP spec',
        PrintConv => { # (same values as IPTC:Urgency)
            0 => '0 (reserved)',              # (not standard XMP)
            1 => '1 (most urgent)',
            2 => 2,
            3 => 3,
            4 => 4,
            5 => '5 (normal urgency)',
            6 => 6,
            7 => 7,
            8 => '8 (least urgent)',
            9 => '9 (user-defined priority)', # (not standard XMP)
        },
    },
);

%Image::ExifTool::XMP::crs = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-crs', 2 => 'Image' },
    NAMESPACE   => 'crs',
    TABLE_DESC => 'Photoshop Camera Raw Schema',
    NOTES => 'Photoshop Camera Raw Schema tags.',
    AlreadyApplied  => { Writable => 'boolean' }, #PH (written by LightRoom beta 4.1)
    AutoBrightness  => { Writable => 'boolean' },
    AutoContrast    => { Writable => 'boolean' },
    AutoExposure    => { Writable => 'boolean' },
    AutoShadows     => { Writable => 'boolean' },
    BlueHue         => { Writable => 'integer' },
    BlueSaturation  => { Writable => 'integer' },
    Brightness      => { Writable => 'integer' },
    CameraProfile   => { },
    ChromaticAberrationB=> { Writable => 'integer' },
    ChromaticAberrationR=> { Writable => 'integer' },
    ColorNoiseReduction => { Writable => 'integer' },
    Contrast        => { Writable => 'integer', Avoid => 1 },
    Converter       => { }, #PH guess (found in EXIF)
    CropTop         => { Writable => 'real' },
    CropLeft        => { Writable => 'real' },
    CropBottom      => { Writable => 'real' },
    CropRight       => { Writable => 'real' },
    CropAngle       => { Writable => 'real' },
    CropWidth       => { Writable => 'real' },
    CropHeight      => { Writable => 'real' },
    CropUnits => {
        Writable => 'integer',
        PrintConv => {
            0 => 'pixels',
            1 => 'inches',
            2 => 'cm',
        },
    },
    Exposure        => { Writable => 'real' },
    GreenHue        => { Writable => 'integer' },
    GreenSaturation => { Writable => 'integer' },
    HasCrop         => { Writable => 'boolean' },
    HasSettings     => { Writable => 'boolean' },
    LuminanceSmoothing  => { Writable => 'integer' },
    MoireFilter     => { PrintConv => { Off=>'Off', On=>'On' } },
    RawFileName     => { },
    RedHue          => { Writable => 'integer' },
    RedSaturation   => { Writable => 'integer' },
    Saturation      => { Writable => 'integer', Avoid => 1 },
    Shadows         => { Writable => 'integer' },
    ShadowTint      => { Writable => 'integer' },
    Sharpness       => { Writable => 'integer', Avoid => 1 },
    Smoothness      => { Writable => 'integer' },
    Temperature     => { Writable => 'integer', Avoid => 1, Name => 'ColorTemperature' },
    Tint            => { Writable => 'integer' },
    ToneCurve       => { List => 'Seq' },
    ToneCurveName => {
        PrintConv => {
            Linear           => 'Linear',
           'Medium Contrast' => 'Medium Contrast',
           'Strong Contrast' => 'Strong Contrast',
            Custom           => 'Custom',
        },
    },
    Version         => { },
    VignetteAmount  => { Writable => 'integer' },
    VignetteMidpoint=> { Writable => 'integer' },
    WhiteBalance    => {
        Avoid => 1,
        PrintConv => {
           'As Shot'    => 'As Shot',
            Auto        => 'Auto',
            Daylight    => 'Daylight',
            Cloudy      => 'Cloudy',
            Shade       => 'Shade',
            Tungsten    => 'Tungsten',
            Fluorescent => 'Fluorescent',
            Flash       => 'Flash',
            Custom      => 'Custom',
        },
    },
    # new tags observed in Adobe Lightroom output - PH
    CameraProfileDigest         => { },
    Clarity                     => { Writable => 'integer' },
    ConvertToGrayscale          => { Writable => 'boolean' },
    Defringe                    => { Writable => 'integer' },
    FillLight                   => { Writable => 'integer' },
    HighlightRecovery           => { Writable => 'integer' },
    HueAdjustmentAqua           => { Writable => 'integer' },
    HueAdjustmentBlue           => { Writable => 'integer' },
    HueAdjustmentGreen          => { Writable => 'integer' },
    HueAdjustmentMagenta        => { Writable => 'integer' },
    HueAdjustmentOrange         => { Writable => 'integer' },
    HueAdjustmentPurple         => { Writable => 'integer' },
    HueAdjustmentRed            => { Writable => 'integer' },
    HueAdjustmentYellow         => { Writable => 'integer' },
    IncrementalTemperature      => { Writable => 'integer' },
    IncrementalTint             => { Writable => 'integer' },
    LuminanceAdjustmentAqua     => { Writable => 'integer' },
    LuminanceAdjustmentBlue     => { Writable => 'integer' },
    LuminanceAdjustmentGreen    => { Writable => 'integer' },
    LuminanceAdjustmentMagenta  => { Writable => 'integer' },
    LuminanceAdjustmentOrange   => { Writable => 'integer' },
    LuminanceAdjustmentPurple   => { Writable => 'integer' },
    LuminanceAdjustmentRed      => { Writable => 'integer' },
    LuminanceAdjustmentYellow   => { Writable => 'integer' },
    ParametricDarks             => { Writable => 'integer' },
    ParametricHighlights        => { Writable => 'integer' },
    ParametricHighlightSplit    => { Writable => 'integer' },
    ParametricLights            => { Writable => 'integer' },
    ParametricMidtoneSplit      => { Writable => 'integer' },
    ParametricShadows           => { Writable => 'integer' },
    ParametricShadowSplit       => { Writable => 'integer' },
    SaturationAdjustmentAqua    => { Writable => 'integer' },
    SaturationAdjustmentBlue    => { Writable => 'integer' },
    SaturationAdjustmentGreen   => { Writable => 'integer' },
    SaturationAdjustmentMagenta => { Writable => 'integer' },
    SaturationAdjustmentOrange  => { Writable => 'integer' },
    SaturationAdjustmentPurple  => { Writable => 'integer' },
    SaturationAdjustmentRed     => { Writable => 'integer' },
    SaturationAdjustmentYellow  => { Writable => 'integer' },
    SharpenDetail               => { Writable => 'integer' },
    SharpenEdgeMasking          => { Writable => 'integer' },
    SharpenRadius               => { Writable => 'real' },
    SplitToningBalance          => { Writable => 'integer' },
    SplitToningHighlightHue     => { Writable => 'integer' },
    SplitToningHighlightSaturation => { Writable => 'integer' },
    SplitToningShadowHue        => { Writable => 'integer' },
    SplitToningShadowSaturation => { Writable => 'integer' },
    Vibrance                    => { Writable => 'integer' },
    # new tags written by LR 1.4 (not sure in what version they first appeared)
    GrayMixerRed                => { Writable => 'integer' },
    GrayMixerOrange             => { Writable => 'integer' },
    GrayMixerYellow             => { Writable => 'integer' },
    GrayMixerGreen              => { Writable => 'integer' },
    GrayMixerAqua               => { Writable => 'integer' },
    GrayMixerBlue               => { Writable => 'integer' },
    GrayMixerPurple             => { Writable => 'integer' },
    GrayMixerMagenta            => { Writable => 'integer' },
    RetouchInfo                 => { List => 'Seq' },
    RedEyeInfo                  => { List => 'Seq' },
    # new tags written by LR 2.0 (ref PH)
    CropUnit => { # was the XMP documentation wrong with "CropUnits"??
        Writable => 'integer',
        PrintConv => {
            0 => 'pixels',
            1 => 'inches',
            2 => 'cm',
            # have seen a value of 3 here! - PH
        },
    },
    PostCropVignetteAmount      => { Writable => 'integer' },
    PostCropVignetteMidpoint    => { Writable => 'integer' },
    PostCropVignetteFeather     => { Writable => 'integer' },
    PostCropVignetteRoundness   => { Writable => 'integer' },
    PostCropVignetteStyle       => { Writable => 'integer' },
    # disable List behaviour of flattened Gradient/PaintBasedCorrections
    # because these are nested in lists and the flattened tags can't
    # do justice to this complex structure
    GradientBasedCorrections => { Struct => \%sCorrection, List => 'Seq' },
    GradientBasedCorrectionsWhat => {
        Name => 'GradientBasedCorrWhat',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionAmount => {
        Name => 'GradientBasedCorrAmount',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionActive => {
        Name => 'GradientBasedCorrActive',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalExposure => {
        Name => 'GradientBasedCorrExposure',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalSaturation => {
        Name => 'GradientBasedCorrSaturation',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalContrast => {
        Name => 'GradientBasedCorrContrast',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalClarity => {
        Name => 'GradientBasedCorrClarity',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalSharpness => {
        Name => 'GradientBasedCorrSharpness',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalBrightness => {
        Name => 'GradientBasedCorrBrightness',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalToningHue => {
        Name => 'GradientBasedCorrHue',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsLocalToningSaturation => {
        Name => 'GradientBasedCorrSaturation',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasks => {
        Name => 'GradientBasedCorrMasks',
        Flat => 1
    },
    GradientBasedCorrectionsCorrectionMasksWhat => {
        Name => 'GradientBasedCorrMaskWhat',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksMaskValue => {
        Name => 'GradientBasedCorrMaskValue',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksRadius => {
        Name => 'GradientBasedCorrMaskRadius',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksFlow => {
        Name => 'GradientBasedCorrMaskFlow',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksCenterWeight => {
        Name => 'GradientBasedCorrMaskCenterWeight',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksDabs => {
        Name => 'GradientBasedCorrMaskDabs',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksZeroX => {
        Name => 'GradientBasedCorrMaskZeroX',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksZeroY => {
        Name => 'GradientBasedCorrMaskZeroY',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksFullX => {
        Name => 'GradientBasedCorrMaskFullX',
        Flat => 1, List => 0,
    },
    GradientBasedCorrectionsCorrectionMasksFullY => {
        Name => 'GradientBasedCorrMaskFullY',
        Flat => 1, List => 0,
    },
    PaintBasedCorrections => { Struct => \%sCorrection, List => 'Seq' },
    PaintBasedCorrectionsWhat => {
        Name => 'PaintCorrectionWhat',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionAmount => {
        Name => 'PaintCorrectionAmount',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionActive => {
        Name => 'PaintCorrectionActive',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalExposure => {
        Name => 'PaintCorrectionExposure',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalSaturation => {
        Name => 'PaintCorrectionSaturation',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalContrast => {
        Name => 'PaintCorrectionContrast',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalClarity => {
        Name => 'PaintCorrectionClarity',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalSharpness => {
        Name => 'PaintCorrectionSharpness',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalBrightness => {
        Name => 'PaintCorrectionBrightness',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalToningHue => {
        Name => 'PaintCorrectionHue',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsLocalToningSaturation => {
        Name => 'PaintCorrectionSaturation',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasks => {
        Name => 'PaintBasedCorrectionMasks',
        Flat => 1,
    },
    PaintBasedCorrectionsCorrectionMasksWhat => {
        Name => 'PaintCorrectionMaskWhat',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksMaskValue => {
        Name => 'PaintCorrectionMaskValue',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksRadius => {
        Name => 'PaintCorrectionMaskRadius',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksFlow => {
        Name => 'PaintCorrectionMaskFlow',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksCenterWeight => {
        Name => 'PaintCorrectionMaskCenterWeight',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksDabs => {
        Name => 'PaintCorrectionMaskDabs',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksZeroX => {
        Name => 'PaintCorrectionMaskZeroX',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksZeroY => {
        Name => 'PaintCorrectionMaskZeroY',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksFullX => {
        Name => 'PaintCorrectionMaskFullX',
        Flat => 1, List => 0,
    },
    PaintBasedCorrectionsCorrectionMasksFullY => {
        Name => 'PaintCorrectionMaskFullY',
        Flat => 1, List => 0,
    },
    # new tags written by LR 3 (thanks Wolfgang Guelcker)
    ProcessVersion                       => { },
    LensProfileEnable                    => { Writable => 'integer' },
    LensProfileSetup                     => { },
    LensProfileName                      => { },
    LensProfileFilename                  => { },
    LensProfileDigest                    => { },
    LensProfileDistortionScale           => { Writable => 'integer' },
    LensProfileChromaticAberrationScale  => { Writable => 'integer' },
    LensProfileVignettingScale           => { Writable => 'integer' },
    LensManualDistortionAmount           => { Writable => 'integer' },
    PerspectiveVertical                  => { Writable => 'integer' },
    PerspectiveHorizontal                => { Writable => 'integer' },
    PerspectiveRotate                    => { Writable => 'real'    },
    PerspectiveScale                     => { Writable => 'integer' },
    CropConstrainToWarp                  => { Writable => 'integer' },      
    LuminanceNoiseReductionDetail        => { Writable => 'integer' },
    LuminanceNoiseReductionContrast      => { Writable => 'integer' },
    ColorNoiseReductionDetail            => { Writable => 'integer' },
    GrainAmount                          => { Writable => 'integer' },
    GrainSize                            => { Writable => 'integer' },
    GrainFrequency                       => { Writable => 'integer' },
);

%Image::ExifTool::XMP::tiff = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-tiff', 2 => 'Image' },
    NAMESPACE   => 'tiff',
    PRIORITY => 0, # not as reliable as actual TIFF tags
    TABLE_DESC => 'XMP TIFF',
    NOTES => 'EXIF schema for TIFF tags.',
    ImageWidth    => { Writable => 'integer' },
    ImageLength   => { Writable => 'integer', Name => 'ImageHeight' },
    BitsPerSample => { Writable => 'integer', List => 'Seq', AutoSplit => 1 },
    Compression => {
        Writable => 'integer',
        SeparateTable => 'EXIF Compression',
        PrintConv => \%Image::ExifTool::Exif::compression,
    },
    PhotometricInterpretation => {
        Writable => 'integer',
        PrintConv => \%Image::ExifTool::Exif::photometricInterpretation,
    },
    Orientation => {
        Writable => 'integer',
        PrintConv => \%Image::ExifTool::Exif::orientation,
    },
    SamplesPerPixel => { Writable => 'integer' },
    PlanarConfiguration => {
        Writable => 'integer',
        PrintConv => {
            1 => 'Chunky',
            2 => 'Planar',
        },
    },
    YCbCrSubSampling => { PrintConv => \%Image::ExifTool::JPEG::yCbCrSubSampling },
    YCbCrPositioning => {
        Writable => 'integer',
        PrintConv => {
            1 => 'Centered',
            2 => 'Co-sited',
        },
    },
    XResolution => { Writable => 'rational' },
    YResolution => { Writable => 'rational' },
    ResolutionUnit => {
        Writable => 'integer',
        Notes => 'the value 1 is not standard EXIF',
        PrintConv => {
            1 => 'None',
            2 => 'inches',
            3 => 'cm',
        },
    },
    TransferFunction      => { Writable => 'integer',  List => 'Seq' },
    WhitePoint            => { Writable => 'rational', List => 'Seq', AutoSplit => 1 },
    PrimaryChromaticities => { Writable => 'rational', List => 'Seq', AutoSplit => 1 },
    YCbCrCoefficients     => { Writable => 'rational', List => 'Seq', AutoSplit => 1 },
    ReferenceBlackWhite   => { Writable => 'rational', List => 'Seq', AutoSplit => 1 },
    DateTime => { # (EXIF tag named ModifyDate, but this exists in XMP-xmp)
        Description => 'Date/Time Modified',
        Groups => { 2 => 'Time' },
        %dateTimeInfo,
    },
    ImageDescription => { Writable => 'lang-alt' },
    Make      => { Groups => { 2 => 'Camera' } },
    Model     => { Groups => { 2 => 'Camera' }, Description => 'Camera Model Name' },
    Software  => { },
    Artist    => { Groups => { 2 => 'Author' } },
    Copyright => { Groups => { 2 => 'Author' }, Writable => 'lang-alt' },
    NativeDigest => { }, #PH
);

%Image::ExifTool::XMP::exif = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-exif', 2 => 'Image' },
    NAMESPACE   => 'exif',
    PRIORITY => 0, # not as reliable as actual EXIF tags
    NOTES => 'EXIF schema for EXIF tags.',
    ExifVersion     => { },
    FlashpixVersion => { },
    ColorSpace => {
        Writable => 'integer',
        # (some applications incorrectly write -1 as a long integer)
        ValueConv => '$val == 0xffffffff ? 0xffff : $val',
        ValueConvInv => '$val',
        PrintConv => {
            1 => 'sRGB',
            2 => 'Adobe RGB',
            0xffff => 'Uncalibrated',
        },
    },
    ComponentsConfiguration => {
        List => 'Seq',
        Writable => 'integer',
        AutoSplit => 1,
        PrintConvColumns => 2,
        PrintConv => {
            0 => '-',
            1 => 'Y',
            2 => 'Cb',
            3 => 'Cr',
            4 => 'R',
            5 => 'G',
            6 => 'B',
        },
    },
    CompressedBitsPerPixel => { Writable => 'rational' },
    PixelXDimension  => { Name => 'ExifImageWidth',  Writable => 'integer' },
    PixelYDimension  => { Name => 'ExifImageHeight', Writable => 'integer' },
    MakerNote        => { },
    UserComment      => { Writable => 'lang-alt' },
    RelatedSoundFile => { },
    DateTimeOriginal => {
        Description => 'Date/Time Original',
        Groups => { 2 => 'Time' },
        %dateTimeInfo,
    },
    DateTimeDigitized => { # (EXIF tag named CreateDate, but this exists in XMP-xmp)
        Description => 'Date/Time Digitized',
        Groups => { 2 => 'Time' },
        %dateTimeInfo,
    },
    ExposureTime => {
        Writable => 'rational',
        PrintConv => 'Image::ExifTool::Exif::PrintExposureTime($val)',
        PrintConvInv => 'Image::ExifTool::Exif::ConvertFraction($val)',
    },
    FNumber => {
        Writable => 'rational',
        PrintConv => 'sprintf("%.1f",$val)',
        PrintConvInv => '$val',
    },
    ExposureProgram => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Not Defined',
            1 => 'Manual',
            2 => 'Program AE',
            3 => 'Aperture-priority AE',
            4 => 'Shutter speed priority AE',
            5 => 'Creative (Slow speed)',
            6 => 'Action (High speed)',
            7 => 'Portrait',
            8 => 'Landscape',
        },
    },
    SpectralSensitivity => { Groups => { 2 => 'Camera' } },
    ISOSpeedRatings => {
        Name => 'ISO',
        Writable => 'integer',
        List => 'Seq',
        AutoSplit => 1,
    },
    OECF => {
        Name => 'Opto-ElectricConvFactor',
        Groups => { 2 => 'Camera' },
        Struct => \%sOECF,
    },
    OECFColumns => { Flat => 1 },
    OECFRows    => { Flat => 1 },
    OECFNames   => { Flat => 1 },
    OECFValues  => { Flat => 1 },
    ShutterSpeedValue => {
        Writable => 'rational',
        ValueConv => 'abs($val)<100 ? 1/(2**$val) : 0',
        PrintConv => 'Image::ExifTool::Exif::PrintExposureTime($val)',
        ValueConvInv => '$val>0 ? -log($val)/log(2) : 0',
        PrintConvInv => 'Image::ExifTool::Exif::ConvertFraction($val)',
    },
    ApertureValue => {
        Writable => 'rational',
        ValueConv => 'sqrt(2) ** $val',
        PrintConv => 'sprintf("%.1f",$val)',
        ValueConvInv => '$val>0 ? 2*log($val)/log(2) : 0',
        PrintConvInv => '$val',
    },
    BrightnessValue   => { Writable => 'rational' },
    ExposureBiasValue => {
        Name => 'ExposureCompensation',
        Writable => 'rational',
        PrintConv => 'Image::ExifTool::Exif::PrintFraction($val)',
        PrintConvInv => '$val',
    },
    MaxApertureValue => {
        Groups => { 2 => 'Camera' },
        Writable => 'rational',
        ValueConv => 'sqrt(2) ** $val',
        PrintConv => 'sprintf("%.1f",$val)',
        ValueConvInv => '$val>0 ? 2*log($val)/log(2) : 0',
        PrintConvInv => '$val',
    },
    SubjectDistance => {
        Groups => { 2 => 'Camera' },
        Writable => 'rational',
        PrintConv => '$val =~ /^(inf|undef)$/ ? $val : "$val m"',
        PrintConvInv => '$val=~s/\s*m$//;$val',
    },
    MeteringMode => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            1 => 'Average',
            2 => 'Center-weighted average',
            3 => 'Spot',
            4 => 'Multi-spot',
            5 => 'Multi-segment',
            6 => 'Partial',
            255 => 'Other',
        },
    },
    LightSource => {
        Groups => { 2 => 'Camera' },
        SeparateTable => 'EXIF LightSource',
        PrintConv =>  \%Image::ExifTool::Exif::lightSource,
    },
    Flash => {
        Groups => { 2 => 'Camera' },
        Struct => {
            STRUCT_NAME => 'Flash',
            NAMESPACE   => 'exif',
            Fired       => { Writable => 'boolean' },
            Return => {
                Writable => 'integer',
                PrintConv => {
                    0 => 'No return detection',
                    2 => 'Return not detected',
                    3 => 'Return detected',
                },
            },
            Mode => {
                Writable => 'integer',
                PrintConv => {
                    0 => 'Unknown',
                    1 => 'On',
                    2 => 'Off',
                    3 => 'Auto',
                },
            },
            Function    => { Writable => 'boolean' },
            RedEyeMode  => { Writable => 'boolean' },
        },
    },
    FocalLength=> {
        Groups => { 2 => 'Camera' },
        Writable => 'rational',
        PrintConv => 'sprintf("%.1f mm",$val)',
        PrintConvInv => '$val=~s/\s*mm$//;$val',
    },
    SubjectArea => { Writable => 'integer', List => 'Seq', AutoSplit => 1 },
    FlashEnergy => { Groups => { 2 => 'Camera' }, Writable => 'rational' },
    SpatialFrequencyResponse => {
        Groups => { 2 => 'Camera' },
        Struct => \%sOECF,
    },
    FocalPlaneXResolution => { Groups => { 2 => 'Camera' }, Writable => 'rational' },
    FocalPlaneYResolution => { Groups => { 2 => 'Camera' }, Writable => 'rational' },
    FocalPlaneResolutionUnit => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        Notes => 'values 1, 4 and 5 are not standard EXIF',
        PrintConv => {
            1 => 'None', # (not standard EXIF)
            2 => 'inches',
            3 => 'cm',
            4 => 'mm',   # (not standard EXIF)
            5 => 'um',   # (not standard EXIF)
        },
    },
    SubjectLocation => { Writable => 'integer', List => 'Seq', AutoSplit => 1 },
    ExposureIndex   => { Writable => 'rational' },
    SensingMethod => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        Notes => 'values 1 and 6 are not standard EXIF',
        PrintConv => {
            1 => 'Monochrome area', # (not standard EXIF)
            2 => 'One-chip color area',
            3 => 'Two-chip color area',
            4 => 'Three-chip color area',
            5 => 'Color sequential area',
            6 => 'Monochrome linear', # (not standard EXIF)
            7 => 'Trilinear',
            8 => 'Color sequential linear',
        },
    },
    FileSource => {
        Writable => 'integer',
        PrintConv => {
            1 => 'Film Scanner',
            2 => 'Reflection Print Scanner',
            3 => 'Digital Camera',
        }
    },
    SceneType  => { Writable => 'integer', PrintConv => { 1 => 'Directly photographed' } },
    CFAPattern => {
        Struct => {
            STRUCT_NAME => 'CFAPattern',
            NAMESPACE   => 'exif',
            Columns     => { Writable => 'integer' },
            Rows        => { Writable => 'integer' },
            Values      => { Writable => 'integer', List => 'Seq' },
        },
    },
    CustomRendered => {
        Writable => 'integer',
        PrintConv => {
            0 => 'Normal',
            1 => 'Custom',
        },
    },
    ExposureMode => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Auto',
            1 => 'Manual',
            2 => 'Auto bracket',
        },
    },
    WhiteBalance => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Auto',
            1 => 'Manual',
        },
    },
    DigitalZoomRatio => { Writable => 'rational' },
    FocalLengthIn35mmFilm => {
        Name => 'FocalLengthIn35mmFormat',
        Writable => 'integer',
        Groups => { 2 => 'Camera' },
        PrintConv => '"$val mm"',
        PrintConvInv => '$val=~s/\s*mm$//;$val',
    },
    SceneCaptureType => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Standard',
            1 => 'Landscape',
            2 => 'Portrait',
            3 => 'Night',
        },
    },
    GainControl => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'None',
            1 => 'Low gain up',
            2 => 'High gain up',
            3 => 'Low gain down',
            4 => 'High gain down',
        },
    },
    Contrast => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Normal',
            1 => 'Low',
            2 => 'High',
        },
        PrintConvInv => 'Image::ExifTool::Exif::ConvertParameter($val)',
    },
    Saturation => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Normal',
            1 => 'Low',
            2 => 'High',
        },
        PrintConvInv => 'Image::ExifTool::Exif::ConvertParameter($val)',
    },
    Sharpness => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Normal',
            1 => 'Soft',
            2 => 'Hard',
        },
        PrintConvInv => 'Image::ExifTool::Exif::ConvertParameter($val)',
    },
    DeviceSettingDescription => {
        Groups => { 2 => 'Camera' },
        Struct => {
            STRUCT_NAME => 'DeviceSettings',
            NAMESPACE   => 'exif',
            Columns     => { Writable => 'integer' },
            Rows        => { Writable => 'integer' },
            Settings    => { List => 'Seq' },
        },
    },
    SubjectDistanceRange => {
        Groups => { 2 => 'Camera' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Unknown',
            1 => 'Macro',
            2 => 'Close',
            3 => 'Distant',
        },
    },
    ImageUniqueID   => { },
    GPSVersionID    => { Groups => { 2 => 'Location' } },
    GPSLatitude     => { Groups => { 2 => 'Location' }, %latConv },
    GPSLongitude    => { Groups => { 2 => 'Location' }, %longConv },
    GPSAltitudeRef  => {
        Groups => { 2 => 'Location' },
        Writable => 'integer',
        PrintConv => {
            0 => 'Above Sea Level',
            1 => 'Below Sea Level',
        },
    },
    GPSAltitude => {
        Groups => { 2 => 'Location' },
        Writable => 'rational',
        RawConv => 'require Image::ExifTool::GPS; $val', # to load Composite tags and routines
        # extricate unsigned decimal number from string
        ValueConvInv => '$val=~/((?=\d|\.\d)\d*(?:\.\d*)?)/ ? $1 : undef',
        PrintConv => '$val =~ /^(inf|undef)$/ ? $val : "$val m"',
        PrintConvInv => '$val=~s/\s*m$//;$val',
    },
    GPSTimeStamp => {
        Name => 'GPSDateTime',
        Description => 'GPS Date/Time',
        Groups => { 2 => 'Time' },
        Notes => q{
            a date/time tag called GPSTimeStamp by the XMP specification.  This tag is
            renamed here to prevent direct copy from EXIF:GPSTimeStamp which is a
            time-only tag.  Instead, the value of this tag should be taken from
            Composite:GPSDateTime when copying from EXIF
        },
        %dateTimeInfo,
    },
    GPSSatellites   => { Groups => { 2 => 'Location' } },
    GPSStatus => {
        Groups => { 2 => 'Location' },
        PrintConv => {
            A => 'Measurement Active',
            V => 'Measurement Void',
        },
    },
    GPSMeasureMode => {
        Groups => { 2 => 'Location' },
        Writable => 'integer',
        PrintConv => {
            2 => '2-Dimensional',
            3 => '3-Dimensional',
        },
    },
    GPSDOP => { Groups => { 2 => 'Location' }, Writable => 'rational' },
    GPSSpeedRef => {
        Groups => { 2 => 'Location' },
        PrintConv => {
            K => 'km/h',
            M => 'mph',
            N => 'knots',
        },
    },
    GPSSpeed => { Groups => { 2 => 'Location' }, Writable => 'rational' },
    GPSTrackRef => {
        Groups => { 2 => 'Location' },
        PrintConv => {
            M => 'Magnetic North',
            T => 'True North',
        },
    },
    GPSTrack => { Groups => { 2 => 'Location' }, Writable => 'rational' },
    GPSImgDirectionRef => {
        PrintConv => {
            M => 'Magnetic North',
            T => 'True North',
        },
    },
    GPSImgDirection => { Groups => { 2 => 'Location' }, Writable => 'rational' },
    GPSMapDatum     => { Groups => { 2 => 'Location' } },
    GPSDestLatitude => { Groups => { 2 => 'Location' }, %latConv },
    GPSDestLongitude=> { Groups => { 2 => 'Location' }, %longConv },
    GPSDestBearingRef => {
        Groups => { 2 => 'Location' },
        PrintConv => {
            M => 'Magnetic North',
            T => 'True North',
        },
    },
    GPSDestBearing => { Groups => { 2 => 'Location' }, Writable => 'rational' },
    GPSDestDistanceRef => {
        Groups => { 2 => 'Location' },
        PrintConv => {
            K => 'Kilometers',
            M => 'Miles',
            N => 'Nautical Miles',
        },
    },
    GPSDestDistance => {
        Groups => { 2 => 'Location' },
        Writable => 'rational',
    },
    GPSProcessingMethod => { Groups => { 2 => 'Location' } },
    GPSAreaInformation  => { Groups => { 2 => 'Location' } },
    GPSDifferential => {
        Groups => { 2 => 'Location' },
        Writable => 'integer',
        PrintConv => {
            0 => 'No Correction',
            1 => 'Differential Corrected',
        },
    },
    NativeDigest => { }, #PH
);

%Image::ExifTool::XMP::aux = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-aux', 2 => 'Camera' },
    NAMESPACE   => 'aux',
    NOTES => 'Photoshop Auxiliary schema tags.',
    Firmware        => { }, #7
    FlashCompensation => { Writable => 'rational' }, #7
    ImageNumber     => { }, #7
    LensInfo        => { #7
        Notes => '4 rational values giving focal and aperture ranges',
        # convert to floating point values (or 'inf' or 'undef')
        ValueConv => sub {
            my $val = shift;
            my @vals = split ' ', $val;
            return $val unless @vals == 4;
            foreach (@vals) {
                ConvertRational($_) or return $val;
            }
            return join ' ', @vals;
        },
        ValueConvInv => sub {
            my $val = shift;
            my @vals = split ' ', $val;
            return $val unless @vals == 4;
            foreach (@vals) {
                $_ eq 'inf' and $_ = '1/0', next;
                $_ eq 'undef' and $_ = '0/0', next;
                Image::ExifTool::IsFloat($_) or return $val;
                my @a = Image::ExifTool::Rationalize($_);
                $_ = join '/', @a;
            }
            return join ' ', @vals;
        },
        # convert to the form "12-20mm f/3.8-4.5" or "50mm f/1.4"
        PrintConv => \&Image::ExifTool::Exif::PrintLensInfo,
        PrintConvInv => \&Image::ExifTool::Exif::ConvertLensInfo,
    },
    Lens            => { },
    OwnerName       => { }, #7
    SerialNumber    => { },
    LensID          => {
        Priority => 0,
        # prevent this from getting set from a LensID that has been converted
        ValueConvInv => q{
            warn "Expected one or more integer values" if $val =~ /[^\d ]/;
            return $val;
        },
    },
    ApproximateFocusDistance => { Writable => 'rational' }, #PH (LR3)
);

%Image::ExifTool::XMP::iptcCore = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-iptcCore', 2 => 'Author' },
    NAMESPACE   => 'Iptc4xmpCore',
    TABLE_DESC => 'XMP IPTC Core',
    NOTES => q{
        IPTC Core schema tags.  The actual IPTC Core namespace prefix is
        "Iptc4xmpCore", which is the prefix recorded in the file, but ExifTool
        shortens this for the "XMP-iptcCore" family 1 group name. (see
        L<http://www.iptc.org/IPTC4XMP/>)
    },
    CountryCode         => { Groups => { 2 => 'Location' } },
    CreatorContactInfo => {
        Struct => {
            STRUCT_NAME => 'ContactInfo',
            NAMESPACE   => 'Iptc4xmpCore',
            CiAdrCity   => { },
            CiAdrCtry   => { },
            CiAdrExtadr => { },
            CiAdrPcode  => { },
            CiAdrRegion => { },
            CiEmailWork => { },
            CiTelWork   => { },
            CiUrlWork   => { },
        },
    },
    CreatorContactInfoCiAdrCity   => { Flat => 1, Name => 'CreatorCity' },
    CreatorContactInfoCiAdrCtry   => { Flat => 1, Name => 'CreatorCountry' },
    CreatorContactInfoCiAdrExtadr => { Flat => 1, Name => 'CreatorAddress' },
    CreatorContactInfoCiAdrPcode  => { Flat => 1, Name => 'CreatorPostalCode' },
    CreatorContactInfoCiAdrRegion => { Flat => 1, Name => 'CreatorRegion' },
    CreatorContactInfoCiEmailWork => { Flat => 1, Name => 'CreatorWorkEmail' },
    CreatorContactInfoCiTelWork   => { Flat => 1, Name => 'CreatorWorkTelephone' },
    CreatorContactInfoCiUrlWork   => { Flat => 1, Name => 'CreatorWorkURL' },
    IntellectualGenre   => { Groups => { 2 => 'Other' } },
    Location            => { Groups => { 2 => 'Location' } },
    Scene               => { Groups => { 2 => 'Other' }, List => 'Bag' },
    SubjectCode         => { Groups => { 2 => 'Other' }, List => 'Bag' },
);

%Image::ExifTool::XMP::iptcExt = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-iptcExt', 2 => 'Author' },
    NAMESPACE   => 'Iptc4xmpExt',
    TABLE_DESC => 'XMP IPTC Extension',
    NOTES => q{
        IPTC Extension schema tags.  The actual namespace prefix is "Iptc4xmpExt",
        but ExifTool shortens this for the "XMP-iptcExt" family 1 group name.
        (see L<http://www.iptc.org/IPTC4XMP/>)
    },
    AddlModelInfo   => { Name => 'AdditionalModelInformation' },
    ArtworkOrObject => {
        Struct => {
            STRUCT_NAME => 'ArtworkOrObjectDetails',
            NAMESPACE   => 'Iptc4xmpExt',
            AOCopyrightNotice => { },
            AOCreator    => { List => 'Seq' },
            AODateCreated=> { Groups => { 2 => 'Time' }, %dateTimeInfo },
            AOSource     => { },
            AOSourceInvNo=> { },
            AOTitle      => { Writable => 'lang-alt' },
        },
        List => 'Bag',
    },
    ArtworkOrObjectAOCopyrightNotice=> { Flat => 1, Name => 'ArtworkCopyrightNotice' },
    ArtworkOrObjectAOCreator        => { Flat => 1, Name => 'ArtworkCreator' },
    ArtworkOrObjectAODateCreated    => { Flat => 1, Name => 'ArtworkDateCreated' },
    ArtworkOrObjectAOSource         => { Flat => 1, Name => 'ArtworkSource' },
    ArtworkOrObjectAOSourceInvNo    => { Flat => 1, Name => 'ArtworkSourceInventoryNo' },
    ArtworkOrObjectAOTitle          => { Flat => 1, Name => 'ArtworkTitle' },
    OrganisationInImageCode => { List => 'Bag' },
    CVterm => {
        Name => 'ControlledVocabularyTerm',
        List => 'Bag',
    },
    LocationShown => {
        Struct => \%sLocationDetails,
        Groups => { 2 => 'Location' },
        List => 'Bag',
    },
    ModelAge                => { List => 'Bag', Writable => 'integer' },
    OrganisationInImageName => { List => 'Bag' },
    PersonInImage           => { List => 'Bag' },
    DigImageGUID            => { Name => 'DigitalImageGUID' },
    DigitalSourcefileType   => {
        Name => 'DigitalSourceFileType',
        Notes => 'now deprecated -- replaced by DigitalSourceType',
    },
    DigitalSourceType       => { Name => 'DigitalSourceType' },
    Event                   => { Writable => 'lang-alt' },
    RegistryId => {
        Struct => {
            STRUCT_NAME => 'RegistryEntryDetails',
            NAMESPACE   => 'Iptc4xmpExt',
            RegItemId    => { },
            RegOrgId     => { },
        },
        List => 'Bag',
    },
    RegistryIdRegItemId         => { Flat => 1, Name => 'RegistryItemID' },
    RegistryIdRegOrgId          => { Flat => 1, Name => 'RegistryOrganisationID' },
    IptcLastEdited          => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    LocationCreated => {
        Struct => \%sLocationDetails,
        Groups => { 2 => 'Location' },
        List => 'Bag',
    },
    MaxAvailHeight  => { Writable => 'integer' },
    MaxAvailWidth   => { Writable => 'integer' },
);

%Image::ExifTool::XMP::Lightroom = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-lr', 2 => 'Image' },
    NAMESPACE   => 'lr',
    TABLE_DESC => 'XMP Adobe Lightroom',
    NOTES => 'Adobe Lightroom "lr" schema tags.',
    privateRTKInfo => { },
    hierarchicalSubject => { List => 'Bag' },
);

%Image::ExifTool::XMP::Album = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-album', 2 => 'Image' },
    NAMESPACE   => 'album',
    TABLE_DESC => 'XMP Adobe Album',
    NOTES => 'Adobe Album schema tags.',
    Notes => { },
);

%Image::ExifTool::XMP::other = (
    GROUPS => { 2 => 'Unknown' },
    LANG_INFO => \&GetLangInfo,
);

%Image::ExifTool::XMP::Composite = (
    # get latitude/logitude reference from XMP lat/long tags
    # (used to set EXIF GPS position from XMP tags)
    GPSLatitudeRef => {
        Require => 'XMP:GPSLatitude',
        ValueConv => q{
            IsFloat($val[0]) and return $val[0] < 0 ? "S" : "N";
            $val[0] =~ /.*([NS])/;
            return $1;
        },
        PrintConv => {
            N => 'North',
            S => 'South',
        },
    },
    GPSLongitudeRef => {
        Require => 'XMP:GPSLongitude',
        ValueConv => q{
            IsFloat($val[0]) and return $val[0] < 0 ? "W" : "E";
            $val[0] =~ /.*([EW])/;
            return $1;
        },
        PrintConv => {
            E => 'East',
            W => 'West',
        },
    },
    LensID => {
        Notes => 'attempt to convert numerical XMP-aux:LensID stored by Adobe applications',
        Require => {
            0 => 'XMP-aux:LensID',
            1 => 'Make',
        },
        Desire => {
            2 => 'LensInfo',
            3 => 'FocalLength',
            4 => 'LensModel',
        },
        Inhibit => {
            5 => 'Composite:LensID',    # don't override existing Composite:LensID
        },
        ValueConv => '$val',
        PrintConv => 'Image::ExifTool::XMP::PrintLensID($self, @val)',
    },
    Flash => {
        Notes => 'facilitates copying camera flash information between XMP and EXIF',
        Desire => {
            0 => 'XMP:FlashFired',
            1 => 'XMP:FlashReturn',
            2 => 'XMP:FlashMode',
            3 => 'XMP:FlashFunction',
            4 => 'XMP:FlashRedEyeMode',
            5 => 'XMP:Flash', # handle structured flash information too
        },
        Writable => 1,
        PrintHex => 1,
        SeparateTable => 'EXIF Flash',
        ValueConv => q{
            if (ref $val[5] eq 'HASH') {
                # copy structure fields into value array
                my $i = 0;
                $val[$i++] = $val[5]{$_} foreach qw(Fired Return Mode Function RedEyeMode);
            }
            return (($val[0] and lc($val[0]) eq 'true') ? 0x01 : 0) |
                   (($val[1] || 0) << 1) |
                   (($val[2] || 0) << 3) |
                   (($val[3] and lc($val[3]) eq 'true') ? 0x20 : 0) |
                   (($val[4] and lc($val[4]) eq 'true') ? 0x40 : 0);
        },
        PrintConv => \%Image::ExifTool::Exif::flash,
        WriteAlso => {
            'XMP:FlashFired'      => '$val & 0x01 ? "True" : "False"',
            'XMP:FlashReturn'     => '($val & 0x06) >> 1',
            'XMP:FlashMode'       => '($val & 0x18) >> 3',
            'XMP:FlashFunction'   => '$val & 0x20 ? "True" : "False"',
            'XMP:FlashRedEyeMode' => '$val & 0x40 ? "True" : "False"',
        },
    },
);

Image::ExifTool::AddCompositeTags('Image::ExifTool::XMP');

sub AUTOLOAD
{
    return Image::ExifTool::DoAutoLoad($AUTOLOAD, @_);
}

my %charName = ('"'=>'quot', '&'=>'amp', "'"=>'#39', '<'=>'lt', '>'=>'gt');
sub EscapeXML($)
{
    my $str = shift;
    $str =~ s/([&><'"])/&$charName{$1};/sg; # escape necessary XML characters
    return $str;
}

my %charNum = ('quot'=>34, 'amp'=>38, 'apos'=>39, 'lt'=>60, 'gt'=>62);
sub UnescapeXML($;$)
{
    my ($str, $conv) = @_;
    $conv = \%charNum unless $conv;
    $str =~ s/&(#?\w+);/UnescapeChar($1,$conv)/sge;
    return $str;
}

sub FullEscapeXML($)
{
    my $str = shift;
    $str =~ s/([&><'"])/&$charName{$1};/sg; # escape necessary XML characters
    $str =~ s/\\/&#92;/sg;                  # escape backslashes too
    # then use C-escape sequences for invalid characters
    if ($str =~ /[\0-\x1f]/ or IsUTF8(\$str) < 0) {
        $str =~ s/([\0-\x1f\x80-\xff])/sprintf("\\x%.2x",ord $1)/sge;
    }
    return $str;
}

sub FullUnescapeXML($)
{
    my $str = shift;
    # unescape C escape sequences first
    $str =~ s/\\x([\da-f]{2})/chr(hex($1))/sge;
    my $conv = \%charNum;
    $str =~ s/&(#?\w+);/UnescapeChar($1,$conv)/sge;
    return $str;
}

sub UnescapeChar($$)
{
    my ($ch, $conv) = @_;
    my $val = $$conv{$ch};
    unless (defined $val) {
        if ($ch =~ /^#x([0-9a-fA-F]+)$/) {
            $val = hex($1);
        } elsif ($ch =~ /^#(\d+)$/) {
            $val = $1;
        } else {
            return "&$ch;"; # should issue a warning here? [no]
        }
    }
    return chr($val) if $val < 0x80;   # simple ASCII
    return pack('C0U', $val) if $] >= 5.006001;
    return Image::ExifTool::PackUTF8($val);
}

sub IsUTF8($)
{
    my $strPt = shift;
    pos($$strPt) = 0; # start at beginning of string
    return 0 unless $$strPt =~ /([\x80-\xff])/g;
    my $rtnVal = 1;
    for (;;) {
        my $ch = ord($1);
        # minimum lead byte for 2-byte sequence is 0xc2 (overlong sequences
        # not allowed), 0xf8-0xfd are restricted by RFC 3629 (no 5 or 6 byte
        # sequences), and 0xfe and 0xff are not valid in UTF-8 strings
        return -1 if $ch < 0xc2 or $ch >= 0xf8;
        # determine number of bytes remaining in sequence
        my $n;
        if ($ch < 0xe0) {
            $n = 1;
        } elsif ($ch < 0xf0) {
            $n = 2;
        } else {
            $n = 3;
            # character code is greater than 0xffff if more than 2 extra bytes
            # were required in the UTF-8 character
            $rtnVal = 2;
        }
        return -1 unless $$strPt =~ /\G[\x80-\xbf]{$n}/g;
        last unless $$strPt =~ /([\x80-\xff])/g;
    }
    return $rtnVal;
}

sub FixUTF8($)
{
    my $strPt = shift;
    my $fixed;
    pos($$strPt) = 0; # start at beginning of string
    for (;;) {
        last unless $$strPt =~ /([\x80-\xff])/g;
        my $ch = ord($1);
        my $pos = pos($$strPt);
        # (see comments in IsUTF8() above)
        if ($ch >= 0xc2 and $ch < 0xf8) {
            my $n = $ch < 0xe0 ? 1 : ($ch < 0xf0 ? 2 : 3);
            next if $$strPt =~ /\G[\x80-\xbf]{$n}/g;
        }
        # replace bad character with '?'
        substr($$strPt, $pos-1, 1) = '?';
        pos($$strPt) = $fixed = $pos;
    }
    return $fixed;
}

sub DecodeBase64($)
{
    local($^W) = 0; # unpack('u',...) gives bogus warning in 5.00[123]
    my $str = shift;

    # truncate at first unrecognized character (base 64 data
    # may only contain A-Z, a-z, 0-9, +, /, =, or white space)
    $str =~ s/[^A-Za-z0-9+\/= \t\n\r\f].*//s;
    # translate to uucoded and remove padding and white space
    $str =~ tr/A-Za-z0-9+\/= \t\n\r\f/ -_/d;

    # convert the data to binary in chunks
    my $chunkSize = 60;
    my $uuLen = pack('c', 32 + $chunkSize * 3 / 4); # calculate length byte
    my $dat = '';
    my ($i, $substr);
    # loop through the whole chunks
    my $len = length($str) - $chunkSize;
    for ($i=0; $i<=$len; $i+=$chunkSize) {
        $substr = substr($str, $i, $chunkSize);     # get a chunk of the data
        $dat .= unpack('u', $uuLen . $substr);      # decode it
    }
    $len += $chunkSize;
    # handle last partial chunk if necessary
    if ($i < $len) {
        $uuLen = pack('c', 32 + ($len-$i) * 3 / 4); # recalculate length
        $substr = substr($str, $i, $len-$i);        # get the last partial chunk
        $dat .= unpack('u', $uuLen . $substr);      # decode it
    }
    return \$dat;
}

sub GetXMPTagID($;$$)
{
    my ($props, $structProps, $nsList) = @_;
    my ($tag, $prop, $namespace);
    foreach $prop (@$props) {
        # split name into namespace and property name
        # (Note: namespace can be '' for property qualifiers)
        my ($ns, $nm) = ($prop =~ /(.*?):(.*)/) ? ($1, $2) : ('', $prop);
        if ($ignoreNamespace{$ns}) {
            # special case: don't ignore rdf numbered items
            unless ($prop =~ /^rdf:(_\d+)$/) {
                # save list index if necessary for structures
                if ($structProps and @$structProps and $prop =~ /^rdf:li (\d+)$/) {
                    push @{$$structProps[-1]}, $1;
                }
                next;
            }
            $tag .= $1 if defined $tag;
        } else {
            $nm =~ s/ .*//; # remove nodeID if it exists
            # all uppercase is ugly, so convert it
            if ($nm !~ /[a-z]/) {
                my $xlatNS = $$xlatNamespace{$ns} || $ns;
                my $info = $Image::ExifTool::XMP::Main{$xlatNS};
                my $table;
                if (ref $info eq 'HASH' and $info->{SubDirectory}) {
                    $table = GetTagTable($info->{SubDirectory}{TagTable});
                }
                unless ($table and $table->{$nm}) {
                    $nm = lc($nm);
                    $nm =~ s/_([a-z])/\u$1/g;
                }
            }
            if (defined $tag) {
                $tag .= ucfirst($nm);       # add to tag name
            } else {
                $tag = $nm;
            }
            # save structure information if necessary
            if ($structProps) {
                push @$structProps, [ $nm ];
                push @$nsList, $ns if $nsList;
            }
        }
        # save namespace of first property to contribute to tag name
        $namespace = $ns unless $namespace;
    }
    if (wantarray) {
        return ($tag, $namespace || '');
    } else {
        return $tag;
    }
}

sub RegisterNamespace($)
{
    my $table = shift;
    return $$table{NAMESPACE} unless ref $$table{NAMESPACE};
    my $nsRef = $$table{NAMESPACE};
    # recognize as either a list or hash
    my $ns;
    if (ref $nsRef eq 'ARRAY') {
        $ns = $$nsRef[0];
        $nsURI{$ns} = $$nsRef[1];
    } else { # must be a hash
        my @ns = sort keys %$nsRef; # allow multiple namespace definitions
        while (@ns) {
            $ns = pop @ns;
            if ($nsURI{$ns} and $nsURI{$ns} ne $$nsRef{$ns}) {
                warn "User-defined namespace prefix '$ns' conflicts with existing namespace\n";
            }
            $nsURI{$ns} = $$nsRef{$ns};
        }
    }
    return $$table{NAMESPACE} = $ns;
}

sub AddFlattenedTags($$)
{
    local $_;
    my ($tagTablePtr, $tagID) = @_;
    my $tagInfo = $$tagTablePtr{$tagID};

    $$tagInfo{Flattened} and return 0;  # only generate flattened tags once
    $$tagInfo{Flattened} = 1;

    my $strTable = $$tagInfo{Struct};
    unless (ref $strTable) { # (allow a structure name for backward compatibility only)
        my $strName = $strTable;
        $strTable = $Image::ExifTool::UserDefined::xmpStruct{$strTable} or return 0;
        $$strTable{STRUCT_NAME} or $$strTable{STRUCT_NAME} = $strName;
        $$tagInfo{Struct} = $strTable;  # replace old-style name with HASH ref
        delete $$tagInfo{SubDirectory}; # deprecated use of SubDirectory in Struct tags
    }
    # do not add flattened tags to variable-namespace structures
    return 0 if exists $$strTable{NAMESPACE} and not defined $$strTable{NAMESPACE};

    # get family 2 group name for this structure tag
    my ($tagG2, $field);
    $tagG2 = $$tagInfo{Groups}{2} if $$tagInfo{Groups};
    $tagG2 or $tagG2 = $$tagTablePtr{GROUPS}{2};

    my $count = 0;
    foreach $field (keys %$strTable) {
        next if $specialStruct{$field};
        my $fieldInfo = $$strTable{$field};
        next if $$fieldInfo{LangCode};  # don't flatten lang-alt tags
        # build a tag ID for the corresponding flattened tag
        my $fieldName = ucfirst($field);
        my $flatID = $tagID . $fieldName;
        my $flatInfo = $$tagTablePtr{$flatID};
        if ($flatInfo) {
            ref $flatInfo eq 'HASH' or warn("$flatInfo is not a HASH!\n"), next; # (to be safe)
            # pre-defined flattened tags should have Flat flag set
            if (not defined $$flatInfo{Flat} and $Image::ExifTool::debug) {
                warn "Missing Flat flag for $$flatInfo{Name}\n";
            }
            $$flatInfo{Flat} = 0;
            # copy all missing entries from field information
            foreach (keys %$fieldInfo) {
                # must not copy PropertyPath (but can't delete it afterwards
                # because the flat tag may already have this set)
                next if $_ eq 'PropertyPath';
                $$flatInfo{$_} = $$fieldInfo{$_} unless defined $$flatInfo{$_};
            }
            # NOTE: Do NOT delete Groups because we need them if GotGroups was done
            # --> just override group 2 later according to field group
            # re-generate List flag unless it is set to 0
            delete $$flatInfo{List} if $$flatInfo{List};
        } else {
            # generate new flattened tag information based on structure field
            $flatInfo = { %$fieldInfo, Name => $$tagInfo{Name} . $fieldName, Flat => 0 };
            # add new flattened tag to table
            Image::ExifTool::AddTagToTable($tagTablePtr, $flatID, $flatInfo);
            ++$count;
        }
        # propagate List flag (unless set to 0 in pre-defined flattened tag)
        unless (defined $$flatInfo{List}) {
            $$flatInfo{List} = $$fieldInfo{List} || 1 if $$fieldInfo{List} or $$tagInfo{List};
        }
        # set group 2 name from the first existing family 2 group in the:
        # 1) structure field Groups, 2) structure table GROUPS, 3) structure tag Groups
        if ($$fieldInfo{Groups} and $$fieldInfo{Groups}{2}) {
            $$flatInfo{Groups}{2} = $$fieldInfo{Groups}{2};
        } elsif ($$strTable{GROUPS} and $$strTable{GROUPS}{2}) {
            $$flatInfo{Groups}{2} = $$strTable{GROUPS}{2};
        } else {
            $$flatInfo{Groups}{2} = $tagG2;
        }
        # save reference to top-level structure
        $$flatInfo{RootTagInfo} = $$tagInfo{RootTagInfo} || $tagInfo;
        # recursively generate flattened tags for sub-structures
        next unless $$flatInfo{Struct};
        length($flatID) > 150 and warn("Possible deep recursion for tag $flatID\n"), last;
        # reset flattened tag just in case we flattened hierarchy in the wrong order
        # because we must start from the outtermost structure to get the List flags right
        # (this should only happen when building tag tables)
        delete $$flatInfo{Flattened};
        $count += AddFlattenedTags($tagTablePtr, $flatID);
    }
    return $count;
}

sub GetLangInfo($$)
{
    my ($tagInfo, $langCode) = @_;
    # only allow alternate language tags in lang-alt lists
    return undef unless $$tagInfo{Writable} and $$tagInfo{Writable} eq 'lang-alt';
    $langCode =~ tr/_/-/;   # RFC 3066 specifies '-' as a separator
    my $langInfo = Image::ExifTool::GetLangInfo($tagInfo, $langCode);
    # save reference to source tagInfo hash in case we need to set the PropertyPath later
    $$langInfo{SrcTagInfo} = $tagInfo;
    return $langInfo;
}

sub StandardLangCase($)
{
    my $lang = shift;
    # make 2nd subtag uppercase only if it is 2 letters
    return lc($1) . uc($2) . lc($3) if $lang =~ /^([a-z]{2,3}|[xi])(-[a-z]{2})\b(.*)/i;
    return lc($lang);
}

sub ScanForXMP($$)
{
    my ($exifTool, $raf) = @_;
    my ($buff, $xmp);
    my $lastBuff = '';

    $exifTool->VPrint(0,"Scanning for XMP\n");
    for (;;) {
        defined $buff or $raf->Read($buff, 65536) or return 0;
        unless (defined $xmp) {
            $lastBuff .= $buff;
            unless ($lastBuff =~ /(<\?xpacket begin=)/g) {
                # must keep last 15 bytes to match 16-byte "xpacket begin" string
                $lastBuff = length($buff) <= 15 ? $buff : substr($buff, -15);
                undef $buff;
                next;
            }
            $xmp = $1;
            $buff = substr($lastBuff, pos($lastBuff));
        }
        my $pos = length($xmp) - 18;    # (18 = length("<?xpacket end...") - 1)
        $xmp .= $buff;                  # add new data to our XMP
        pos($xmp) = $pos if $pos > 0;   # set start for "xpacket end" scan
        if ($xmp =~ /<\?xpacket end=['"][wr]['"]\?>/g) {
            $buff = substr($xmp, pos($xmp));    # save data after end of XMP
            $xmp = substr($xmp, 0, pos($xmp));  # isolate XMP
            # check XMP for validity (not valid if it contains null bytes)
            $pos = rindex($xmp, "\0") + 1 or last;
            $lastBuff = substr($xmp, $pos);     # re-parse beginning after last null byte
            undef $xmp;
        } else {
            undef $buff;
        }
    }
    unless ($exifTool->{VALUE}{FileType}) {
        $exifTool->{FILE_TYPE} = $exifTool->{FILE_EXT};
        $exifTool->SetFileType('<unknown file containing XMP>');
    }
    my %dirInfo = (
        DataPt => \$xmp,
        DirLen => length $xmp,
        DataLen => length $xmp,
    );
    ProcessXMP($exifTool, \%dirInfo);
    return 1;
}

sub PrintLensID(@)
{
    local $_;
    my ($exifTool, $id, $make, $info, $focalLength, $lensModel) = @_;
    my ($mk, $printConv);
    # missing: Olympus (no XMP:LensID written by Adobe)
    foreach $mk (qw(Canon Nikon Pentax Sony Sigma Samsung Leica)) {
        next unless $make =~ /$mk/i;
        # get name of module containing the lens lookup (default "Make.pm")
        my $mod = { Sigma => 'SigmaRaw', Leica => 'Panasonic' }->{$mk} || $mk;
        require "Image/ExifTool/$mod.pm";
        # get the name of the lens name lookup (default "makeLensTypes")
        my $convName = "Image::ExifTool::${mod}::" .
            ({ Nikon => 'nikonLensIDs' }->{$mk} || lc($mk) . 'LensTypes');
        no strict 'refs';
        %$convName or last;
        my $printConv = \%$convName;
        use strict 'refs';
        my ($minf, $maxf, $maxa, $mina);
        if ($info) {
            my @a = split ' ', $info;
            $_ eq 'undef' and $_ = undef foreach @a;
            ($minf, $maxf, $maxa, $mina) = @a;
        }
        my $str = $$printConv{$id} || "Unknown ($id)";
        # Nikon is a special case because Adobe doesn't store the full LensID
        if ($mk eq 'Nikon') {
            my $hex = sprintf("%.2X", $id);
            my %newConv;
            my $i = 0;
            foreach (grep /^$hex /, keys %$printConv) {
                $newConv{$i ? "$id.$i" : $id} = $$printConv{$_};
                ++$i;
            }
            $printConv = \%newConv;
        }
        return Image::ExifTool::Exif::PrintLensID($exifTool, $str, $id, $focalLength,
                    $maxa, undef, $minf, $maxf, $lensModel, undef, $printConv);
    }
    return "Unknown ($id)";
}

sub ConvertXMPDate($;$)
{
    my ($val, $unsure) = @_;
    if ($val =~ /^(\d{4})-(\d{2})-(\d{2})[T ](\d{2}:\d{2})(:\d{2})?\s*(\S*)$/) {
        my $s = $5 || '';           # seconds may be missing
        $val = "$1:$2:$3 $4$s$6";   # convert back to EXIF time format
    } elsif (not $unsure and $val =~ /^(\d{4})(-\d{2}){0,2}/) {
        $val =~ tr/-/:/;
    }
    return $val;
}

sub ConvertRational($)
{
    my $val = $_[0];
    $val =~ m{^(-?\d+)/(-?\d+)$} or return undef;
    if ($2) {
        $_[0] = $1 / $2; # calculate quotient
    } elsif ($1) {
        $_[0] = 'inf';
    } else {
        $_[0] = 'undef';
    }
    return 1;
}

sub FoundXMP($$$$;$)
{
    local $_;
    my ($exifTool, $tagTablePtr, $props, $val, $attrs) = @_;
    my ($lang, @structProps);
    my ($tag, $ns) = GetXMPTagID($props, $exifTool->{OPTIONS}{Struct} ? \@structProps : undef);
    return 0 unless $tag;   # ignore things that aren't valid tags

    # translate namespace if necessary
    $ns = $$xlatNamespace{$ns} if $$xlatNamespace{$ns};
    my $info = $tagTablePtr->{$ns};
    my ($table, $added, $xns, $tagID);
    if ($info) {
        $table = $info->{SubDirectory}{TagTable} or warn "Missing TagTable for $tag!\n";
    } elsif ($$props[0] eq 'svg:svg') {
        if (not $ns) {
            # disambiguate MetadataID by adding back the 'metadata' we ignored
            $tag = 'metadataId' if $tag eq 'id' and $$props[1] eq 'svg:metadata';
            # use SVG namespace in SVG files if nothing better to use
            $table = 'Image::ExifTool::XMP::SVG';
        } elsif (not grep /^rdf:/, @$props) {
            # only other SVG information if not inside RDF (call it XMP if in RDF)
            $table = 'Image::ExifTool::XMP::otherSVG';
        }
    }

    # look up this tag in the appropriate table
    $table or $table = 'Image::ExifTool::XMP::other';
    $tagTablePtr = GetTagTable($table);
    if ($$tagTablePtr{NAMESPACE}) {
        $tagID = $tag;
    } else {
        # add XMP namespace prefix to avoid collisions in variable-namespace tables
        $xns = $xmpNS{$ns} || $ns;
        $tagID = "$xns:$tag";
        # add namespace to top-level structure property
        $structProps[0][0] = "$xns:" . $structProps[0][0] if @structProps;
    }
    my $tagInfo = $exifTool->GetTagInfo($tagTablePtr, $tagID);

    $lang = $$attrs{'xml:lang'} if $attrs;

    # must add a new tag table entry if this tag isn't pre-defined
    # (or initialize from structure field if this is a pre-defined flattened tag)
NoLoop:
    while (not $tagInfo or $$tagInfo{Flat}) {
        my (@tagList, @nsList);
        GetXMPTagID($props, \@tagList, \@nsList);
        my ($ta, $t, $ti, $addedFlat, $i, $j);
        # build tag ID strings for each level in the property path
        foreach $ta (@tagList) {
            # insert tag ID in index 1 of tagList list
            $t = $$ta[1] = $t ? $t . ucfirst($$ta[0]) : $$ta[0];
            # generate flattened tags for top-level structure if necessary
            next if defined $addedFlat;
            $ti = $$tagTablePtr{$t} or next;
            next unless ref $ti eq 'HASH' and $$ti{Struct};
            $addedFlat = AddFlattenedTags($tagTablePtr, $t);
            if ($tagInfo) {
                # all done if we just wanted to initialize the flattened tag
                if ($$tagInfo{Flat}) {
                    warn "Orphan tagInfo with Flat flag set: $$tagInfo{Name}\n";
                    delete $$tagInfo{Flat};
                }
                last NoLoop;
            }
            # all done if we generated the tag we are looking for
            $tagInfo = $$tagTablePtr{$tagID} and last NoLoop if $addedFlat;
        }
        my $name = ucfirst($tag);

        # search for the innermost containing structure
        # (in case tag is an unknown field in a known structure)
        # (only necessary if we found a structure above)
        if (defined $addedFlat) {
            my $t2 = '';
            for ($i=$#tagList-1; $i>=0; --$i) {
                $t = $tagList[$i][1];
                $t2 = $tagList[$i+1][0] . ucfirst($t2); # build relative tag id
                $ti = $$tagTablePtr{$t} or next;
                next unless ref $ti eq 'HASH';
                my $strTable = $$ti{Struct} or next;
                $name = $$ti{Name} . ucfirst($t2);
                # don't continue if structure is known but field is not
                last if $$strTable{NAMESPACE} or not exists $$strTable{NAMESPACE};
                # this is a variable-namespace structure, so we must:
                # 1) get tagInfo from corresponding top-level XMP tag if it exists
                # 2) add new entry in this tag table, but with namespace prefix on tag ID
                my $n = $nsList[$i+1];  # namespace of structure field
                # translate to standard ExifTool namespace
                $n = $$xlatNamespace{$n} if $$xlatNamespace{$n};
                my $xn = $xmpNS{$n} || $n;  # standard XMP namespace
                # no need to continue with variable-namespace logic if
                # we are in our own namespace (right?)
                last if $xn eq ($$tagTablePtr{NAMESPACE} || '');
                $tagID = "$xn:$tag";    # add namespace to avoid collisions
                # change structure properties to add the standard XMP namespace
                # prefix for this field (needed for variable-namespace fields)
                if (@structProps) {
                    $structProps[$i+1][0] = "$xn:" . $structProps[$i+1][0];
                }
                # copy tagInfo entries from the existing top-level XMP tag
                my $tg = $Image::ExifTool::XMP::Main{$n};
                last unless ref $tg eq 'HASH' and $$tg{SubDirectory};
                my $tbl = GetTagTable($$tg{SubDirectory}{TagTable}) or last;
                my $sti = $exifTool->GetTagInfo($tbl, $t2);
                if (not $sti or $$sti{Flat}) {
                    # again, we must initialize flattened tags if necessary
                    # (but don't bother to recursively apply full logic to
                    #  allow nest variable-namespace strucures until someone
                    #  actually wants to do such a silly thing)
                    my $t3 = '';
                    for ($j=$i+1; $j<@tagList; ++$j) {
                        $t3 = $tagList[$j][0] . ucfirst($t3);
                        my $ti3 = $$tbl{$t3} or next;
                        next unless ref $ti3 eq 'HASH' and $$ti3{Struct};
                        last unless AddFlattenedTags($tbl, $t3);
                        $sti = $$tbl{$t2};
                        last;
                    }
                    last unless $sti;
                }
                $tagInfo = {
                    %$sti,
                    Name     => $$ti{Name} . $$sti{Name},
                    WasAdded => 1,
                };
                # be careful not to copy elements we shouldn't...
                delete $$tagInfo{Description}; # Description will be different
                # can't copy group hash because group 1 will be different and
                # we need to check this when writing tag to a specific group
                delete $$tagInfo{Groups};
                $$tagInfo{Groups}{2} = $$sti{Groups}{2} if $$sti{Groups};
                last;
            }
        }
        $tagInfo or $tagInfo = { Name => $name, WasAdded => 1 };

        # add tag Namespace entry for tags in variable-namespace tables
        $$tagInfo{Namespace} = $xns if $xns;
        if ($curNS{$ns} and $curNS{$ns} =~ m{^http://ns.exiftool.ca/(.*?)/(.*?)/}) {
            my %grps = ( 0 => $1, 1 => $2 );
            # apply a little magic to recover original group names
            # from this exiftool-written RDF/XML file
            if ($grps{1} =~ /^\d/) {
                # URI's with only family 0 are internal tags from the source file,
                # so change the group name to avoid confusion with tags from this file
                $grps{1} = "XML-$grps{0}";
                $grps{0} = 'XML';
            }
            $$tagInfo{Groups} = \%grps;
            # flag to avoid setting group 1 later
            $$tagInfo{StaticGroup1} = 1;
        }
        # construct tag information for this unknown tag
        # -> make this a List or lang-alt tag if necessary
        if (@$props > 2 and $$props[-1] =~ /^rdf:li \d+$/ and
            $$props[-2] =~ /^rdf:(Bag|Seq|Alt)$/)
        {
            if ($lang and $1 eq 'Alt') {
                $$tagInfo{Writable} = 'lang-alt';
            } else {
                $$tagInfo{List} = $1;
            }
        # tried this, but maybe not a good idea for complex structures:
        #} elsif (grep / /, @$props) {
        #    $$tagInfo{List} = 1;
        }
        Image::ExifTool::AddTagToTable($tagTablePtr, $tagID, $tagInfo);
        $added = 1;
        last;
    }
    # decode value if necessary (et:encoding was used before exiftool 7.71)
    if ($attrs) {
        my $enc = $$attrs{'rdf:datatype'} || $$attrs{'et:encoding'};
        if ($enc and $enc =~ /base64/) {
            $val = DecodeBase64($val); # (now a value ref)
            $val = $$val unless length $$val > 100 or $$val =~ /[\0-\x08\x0b\0x0c\x0e-\x1f]/;
        }
    }
    if (defined $lang and lc($lang) ne 'x-default') {
        $lang = StandardLangCase($lang);
        my $langInfo = GetLangInfo($tagInfo, $lang);
        $tagInfo = $langInfo if $langInfo;
    }
    # un-escape XML character entities (handling CDATA)
    pos($val) = 0;
    if ($val =~ /<!\[CDATA\[(.*?)\]\]>/sg) {
        my $p = pos $val;
        # unescape everything up to the start of the CDATA section
        # (the length of "<[[CDATA[]]>" is 12 characters)
        my $v = UnescapeXML(substr($val, 0, $p - length($1) - 12)) . $1;
        while ($val =~ /<!\[CDATA\[(.*?)\]\]>/sg) {
            my $p1 = pos $val;
            $v .= UnescapeXML(substr($val, $p, $p1 - length($1) - 12)) . $1;
            $p = $p1;
        }
        $val = $v . UnescapeXML(substr($val, $p));
    } else {
        $val = UnescapeXML($val);
    }
    # decode from UTF8
    $val = $exifTool->Decode($val, 'UTF8');
    # convert rational and date values to a more sensible format
    my $fmt = $$tagInfo{Writable};
    my $new = $$tagInfo{WasAdded};
    if ($fmt or $new) {
        unless (($new or $fmt eq 'rational') and ConvertRational($val)) {
            $val = ConvertXMPDate($val, $new) if $new or $fmt eq 'date';
        }
    }
    # store the value for this tag
    my $key = $exifTool->FoundTag($tagInfo, $val);
    # save structure/list information if necessary
    if (@structProps and (@structProps > 1 or defined $structProps[0][1])) {
        $exifTool->{TAG_EXTRA}{$key}{Struct} = \@structProps;
        $exifTool->{IsStruct} = 1;
    }
    if ($ns and not $$tagInfo{StaticGroup1}) {
        # set group1 dynamically according to the namespace
        $exifTool->SetGroup($key, "$tagTablePtr->{GROUPS}{0}-$ns");
    }
    if ($exifTool->{OPTIONS}{Verbose}) {
        if ($added) {
            my $g1 = $exifTool->GetGroup($key, 1);
            $exifTool->VPrint(0, $exifTool->{INDENT}, "[adding $g1:$tag]\n");
        }
        my $tagID = join('/',@$props);
        $exifTool->VerboseInfo($tagID, $tagInfo, Value=>$val);
    }
    return 1;
}

sub ParseXMPElement($$$;$$$)
{
    my ($exifTool, $tagTablePtr, $dataPt, $start, $propListPt, $blankInfo) = @_;
    my ($count, $nItems) = (0, 0);
    my $isWriting = $exifTool->{XMP_CAPTURE};
    my $isSVG = $$exifTool{XMP_IS_SVG};

    # get our parse procs
    my ($attrProc, $foundProc);
    if ($$exifTool{XMPParseOpts}) {
        $attrProc = $$exifTool{XMPParseOpts}{AttrProc};
        $foundProc = $$exifTool{XMPParseOpts}{FoundProc} || \&FoundXMP;
    } else {
        $foundProc = \&FoundXMP;
    }
    $start or $start = 0;
    $propListPt or $propListPt = [ ];

    my $processBlankInfo;
    # create empty blank node information hash if necessary
    $blankInfo or $blankInfo = $processBlankInfo = { Prop => { } };
    # keep track of current nodeID at this nesting level
    my $oldNodeID = $$blankInfo{NodeID};

    pos($$dataPt) = $start;
    Element: for (;;) {
        # reset nodeID before processing each element
        my $nodeID = $$blankInfo{NodeID} = $oldNodeID;
        # get next element
        last unless $$dataPt =~ m/<([-\w:.\x80-\xff]+)(.*?)>/sg;
        my ($prop, $attrs) = ($1, $2);
        my $val = '';
        # only look for closing token if this is not an empty element
        # (empty elements end with '/', ie. <a:b/>)
        if ($attrs !~ s/\/$//) {
            my $nesting = 1;
            for (;;) {
                my $pos = pos($$dataPt);
                unless ($$dataPt =~ m/<\/$prop>/sg) {
                    $exifTool->Warn("XMP format error (no closing tag for $prop)");
                    last Element;
                }
                my $len = pos($$dataPt) - $pos - length($prop) - 3;
                my $val2 = substr($$dataPt, $pos, $len);
                # increment nesting level for each contained similar opening token
                ++$nesting while $val2 =~ m/<$prop\b.*?(\/?)>/sg and $1 ne '/';
                $val .= $val2;
                --$nesting or last;
                $val .= "</$prop>";
            }
        }
        my $parseResource;
        if ($prop eq 'rdf:li') {
            # add index to list items so we can keep them in order
            # (this also enables us to keep structure elements grouped properly
            # for lists of structures, like JobRef)
            # Note: the list index is prefixed by the number of digits so sorting
            # alphabetically gives the correct order while still allowing a flexible
            # number of digits -- this scheme allows up to 9 digits in the index,
            # with index numbers ranging from 0 to 999999999.  The sequence is:
            # 10,11,12-19,210,211-299,3100,3101-3999,41000...9999999999.
            $prop .= ' ' . length($nItems) . $nItems;
            ++$nItems;
        } elsif ($prop eq 'rdf:Description') {
            # trim comments and whitespace from rdf:Description properties only
            $val =~ s/<!--.*?-->//g;
            $val =~ s/^\s*(.*)\s*$/$1/;
            # remove unnecessary rdf:Description elements since parseType='Resource'
            # is more efficient (also necessary to make property path consistent)
            $parseResource = 1 if grep /^rdf:Description$/, @$propListPt;
        } elsif ($prop eq 'xmp:xmpmeta') {
            # patch MicrosoftPhoto unconformity
            $prop = 'x:xmpmeta';
        }

        # extract property attributes
        my (%attrs, @attrs);
        while ($attrs =~ m/(\S+?)\s*=\s*(['"])(.*?)\2/sg) {
            push @attrs, $1;    # preserve order
            $attrs{$1} = $3;
        }

        # hook for special parsing of attributes
        $attrProc and &$attrProc(\@attrs, \%attrs, \$prop, \$val);
            
        # add nodeID to property path (with leading ' #') if it exists
        if (defined $attrs{'rdf:nodeID'}) {
            $nodeID = $$blankInfo{NodeID} = $attrs{'rdf:nodeID'};
            delete $attrs{'rdf:nodeID'};
            $prop .= ' #' . $nodeID;
            undef $parseResource;   # can't ignore if this is a node
        }

        # push this property name onto our hierarchy list
        push @$propListPt, $prop unless $parseResource;

        if ($isSVG) {
            # ignore everything but top level SVG tags and metadata unless Unknown set
            unless ($exifTool->{OPTIONS}{Unknown} > 1 or $exifTool->{OPTIONS}{Verbose}) {
                if (@$propListPt > 1 and $$propListPt[1] !~ /\b(metadata|desc|title)$/) {
                    pop @$propListPt;
                    next;
                }
            }
            if ($prop eq 'svg' or $prop eq 'metadata') {
                # add svg namespace prefix if missing to ignore these entries in the tag name
                $$propListPt[-1] = "svg:$prop";
            }
        }

        # handle properties inside element attributes (RDF shorthand format):
        # (attributes take the form a:b='c' or a:b="c")
        my ($shortName, $shorthand, $ignored);
        foreach $shortName (@attrs) {
            my $propName = $shortName;
            my ($ns, $name);
            if ($propName =~ /(.*?):(.*)/) {
                $ns = $1;   # specified namespace
                $name = $2;
            } elsif ($prop =~ /(\S*?):/) {
                $ns = $1;   # assume same namespace as parent
                $name = $propName;
                $propName = "$ns:$name";    # generate full property name
            } else {
                # a property qualifier is the only property name that may not
                # have a namespace, and a qualifier shouldn't have attributes,
                # but what the heck, let's allow this anyway
                $ns = '';
                $name = $propName;
            }
            # keep track of the namespace prefixes used
            if ($ns eq 'xmlns') {
                unless ($attrs{$shortName}) {
                    $exifTool->WarnOnce("Duplicate namespace '$shortName'");
                    next;
                }
                $curNS{$name} = $attrs{$shortName};
                my $stdNS = $uri2ns{$attrs{$shortName}};
                # translate namespace if non-standard (except 'x' and 'iX')
                if ($stdNS and $name ne $stdNS and $stdNS ne 'x' and $stdNS ne 'iX') {
                    # make a copy of the standard translations so we can modify it
                    $xlatNamespace = { %stdXlatNS } if $xlatNamespace eq \%stdXlatNS;
                    # translate this namespace prefix to the standard version
                    $$xlatNamespace{$name} = $stdXlatNS{$stdNS} || $stdNS;
                }
            }
            if ($isWriting) {
                # keep track of our namespaces when writing
                if ($ns eq 'xmlns') {
                    my $stdNS = $uri2ns{$attrs{$shortName}};
                    unless ($stdNS and ($stdNS eq 'x' or $stdNS eq 'iX')) {
                        my $nsUsed = $exifTool->{XMP_NS};
                        $$nsUsed{$name} = $attrs{$shortName} unless defined $$nsUsed{$name};
                    }
                    delete $attrs{$shortName};  # (handled by namespace logic)
                    next;
                } elsif ($recognizedAttrs{$propName}) {
                    # save UUID to use same ID when writing
                    if ($propName eq 'rdf:about') {
                        if (not $exifTool->{XMP_ABOUT}) {
                            $exifTool->{XMP_ABOUT} = $attrs{$shortName};
                        } elsif ($exifTool->{XMP_ABOUT} ne $attrs{$shortName}) {
                            $exifTool->Error("Different 'rdf:about' attributes not handled", 1);
                        }
                    }
                    next;
                }
            }
            my $shortVal = $attrs{$shortName};
            if ($ignoreNamespace{$ns}) {
                $ignored = $propName;
                # handle special attributes (extract as tags only once if not empty)
                if (ref $recognizedAttrs{$propName} and $shortVal) {
                    my ($tbl, $id, $name) = @{$recognizedAttrs{$propName}};
                    my $val = UnescapeXML($shortVal);
                    unless (defined $$exifTool{VALUE}{$name} and $$exifTool{VALUE}{$name} eq $val) {
                        $exifTool->HandleTag(GetTagTable($tbl), $id, $val);
                    }
                }
                next;
            }
            delete $attrs{$shortName};  # don't re-use this attribute
            push @$propListPt, $propName;
            # save this shorthand XMP property
            if (defined $nodeID) {
                SaveBlankInfo($blankInfo, $propListPt, $shortVal);
            } elsif ($isWriting) {
                CaptureXMP($exifTool, $propListPt, $shortVal);
            } else {
                &$foundProc($exifTool, $tagTablePtr, $propListPt, $shortVal);
            }
            pop @$propListPt;
            $shorthand = 1;
        }
        if ($isWriting) {
            if (ParseXMPElement($exifTool, $tagTablePtr, \$val, 0, $propListPt, $blankInfo)) {
                # undefine value since we found more properties within this one
                undef $val;
                # set an error on any ignored attributes here, because they will be lost
                $exifTool->{XMP_ERROR} = "Can't handle XMP attribute '$ignored'" if $ignored;
            }
            if (defined $val and (length $val or not $shorthand)) {
                if (defined $nodeID) {
                    SaveBlankInfo($blankInfo, $propListPt, $val, \%attrs);
                } else {
                    CaptureXMP($exifTool, $propListPt, $val, \%attrs);
                }
            }
        } else {
            # if element value is empty, take value from 'resource' attribute
            # (preferentially) or 'about' attribute (if no 'resource')
            my $wasEmpty;
            if ($val eq '' and ($attrs =~ /\bresource=(['"])(.*?)\1/ or
                                $attrs =~ /\babout=(['"])(.*?)\1/))
            {
                $val = $2;
                $wasEmpty = 1;
            }
            # look for additional elements contained within this one
            if (!ParseXMPElement($exifTool, $tagTablePtr, \$val, 0, $propListPt, $blankInfo)) {
                # there are no contained elements, so this must be a simple property value
                # (unless we already extracted shorthand values from this element)
                if (length $val or not $shorthand) {
                    my $lastProp = $$propListPt[-1];
                    if (defined $nodeID) {
                        SaveBlankInfo($blankInfo, $propListPt, $val);
                    } elsif ($lastProp eq 'rdf:type' and $wasEmpty) {
                        # do not extract empty structure types (for now)
                    } elsif ($lastProp =~ /^et:(desc|prt|val)$/ and ($count or $1 eq 'desc')) {
                        # ignore et:desc, and et:val if preceeded by et:prt
                        --$count;
                    } else {
                        &$foundProc($exifTool, $tagTablePtr, $propListPt, $val, \%attrs);
                    }
                }
            }
        }
        pop @$propListPt unless $parseResource;
        ++$count;
    }
    if ($processBlankInfo and %{$$blankInfo{Prop}}) {
        ProcessBlankInfo($exifTool, $tagTablePtr, $blankInfo, $isWriting);
        %$blankInfo = ();   # free some memory
    }
    return $count;  # return the number of elements found at this level
}

sub ProcessXMP($$;$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    my $dataPt = $$dirInfo{DataPt};
    my ($dirStart, $dirLen, $dataLen);
    my ($buff, $fmt, $hasXMP, $isXML, $isRDF, $isSVG);
    my $rtnVal = 0;
    my $bom = 0;
    undef %curNS;

    # ignore non-standard XMP while in strict MWG compatibility mode
    if ($Image::ExifTool::MWG::strict and not $$exifTool{XMP_CAPTURE} and
        $$exifTool{FILE_TYPE} =~ /^(JPEG|TIFF|PSD)$/)
    {
        my $path = $exifTool->MetadataPath();
        unless ($path =~ /^(JPEG-APP1-XMP|TIFF-IFD0-XMP|PSD-XMP)$/) {
            $exifTool->Warn("Ignored non-standard XMP at $path");
            return 1;
        }
    }
    if ($dataPt) {
        $dirStart = $$dirInfo{DirStart} || 0;
        $dirLen = $$dirInfo{DirLen} || (length($$dataPt) - $dirStart);
        $dataLen = $$dirInfo{DataLen} || length($$dataPt);
    } else {
        my $type;
        # read information from XMP file
        my $raf = $$dirInfo{RAF} or return 0;
        $raf->Read($buff, 256) or return 0;
        my ($buf2, $buf3, $double);
        ($buf2 = $buff) =~ tr/\0//d;    # cheap conversion to UTF-8
        # remove leading comments if they exist (ie. ImageIngester)
        while ($buf2 =~ /^\s*<!--/) {
            # remove the comment if it is complete
            if ($buf2 =~ s/^\s*<!--.*?-->\s+//s) {
                # continue with parsing if we have more than 128 bytes remaining
                next if length $buf2 > 128;
            } else {
                # don't read more than 10k when looking for the end of comment
                return 0 if length($buf2) > 10000;
            }
            $raf->Read($buf3, 256) or last; # read more data if available
            $buff .= $buf3;
            $buf3 =~ tr/\0//d;
            $buf2 .= $buf3;
        }
        # check to see if this is XMP format
        # (CS2 writes .XMP files without the "xpacket begin")
        if ($buf2 =~ /^\s*(<\?xpacket begin=|<x(mp)?:x[ma]pmeta)/) {
            $hasXMP = 1;
        } else {
            # also recognize XML files and .XMP files with BOM and without x:xmpmeta
            if ($buf2 =~ /^(\xfe\xff)(<\?xml|<rdf:RDF|<x(mp)?:x[ma]pmeta)/g) {
                $fmt = 'n';     # UTF-16 or 32 MM with BOM
            } elsif ($buf2 =~ /^(\xff\xfe)(<\?xml|<rdf:RDF|<x(mp)?:x[ma]pmeta)/g) {
                $fmt = 'v';     # UTF-16 or 32 II with BOM
            } elsif ($buf2 =~ /^(\xef\xbb\xbf)?(<\?xml|<rdf:RDF|<x(mp)?:x[ma]pmeta)/g) {
                $fmt = 0;       # UTF-8 with BOM or unknown encoding without BOM
            } elsif ($buf2 =~ /^(\xfe\xff|\xff\xfe|\xef\xbb\xbf)(<\?xpacket begin=)/g) {
                $double = $1;   # double-encoded UTF
            } else {
                return 0;       # not recognized XMP or XML
            }
            $bom = 1 if $1;
            if ($2 eq '<?xml') {
                if ($buf2 =~ /<x(mp)?:x[ma]pmeta/) {
                    $hasXMP = 1;
                } else {
                    # identify SVG images by DOCTYPE if available
                    if ($buf2 =~ /<!DOCTYPE\s+(\w+)/) {
                        if ($1 eq 'svg') {
                            $isSVG = 1;
                        } elsif ($1 eq 'plist') {
                            $type = 'PLIST';
                        } else {
                            return 0;
                        }
                    } elsif ($buf2 =~ /<svg[\s>]/) {
                        $isSVG = 1;
                    } elsif ($buf2 =~ /<rdf:RDF/) {
                        $isRDF = 1;
                    }
                    if ($isSVG and $exifTool->{XMP_CAPTURE}) {
                        $exifTool->Error("ExifTool does not yet support writing of SVG images");
                        return 0;
                    }
                }
                $isXML = 1;
            } elsif ($2 eq '<rdf:RDF') {
                $isRDF = 1;     # recognize XMP without x:xmpmeta element
            }
            if ($buff =~ /^\0\0/) {
                $fmt = 'N';     # UTF-32 MM with or without BOM
            } elsif ($buff =~ /^..\0\0/) {
                $fmt = 'V';     # UTF-32 II with or without BOM
            } elsif (not $fmt) {
                if ($buff =~ /^\0/) {
                    $fmt = 'n'; # UTF-16 MM without BOM
                } elsif ($buff =~ /^.\0/) {
                    $fmt = 'v'; # UTF-16 II without BOM
                }
            }
        }
        $raf->Seek(0, 2) or return 0;
        my $size = $raf->Tell() or return 0;
        $raf->Seek(0, 0) or return 0;
        $raf->Read($buff, $size) == $size or return 0;
        # decode the first layer of double-encoded UTF text
        if ($double) {
            $buff = substr($buff, length $double);  # remove leading BOM
            Image::ExifTool::SetWarning(undef);     # clear old warning
            local $SIG{'__WARN__'} = \&Image::ExifTool::SetWarning;
            my $tmp;
            # assume that character data has been re-encoded in UTF, so re-pack
            # as characters and look for warnings indicating a false assumption
            if ($double eq "\xef\xbb\xbf") {
                require Image::ExifTool::Charset;
                my $uni = Image::ExifTool::Charset::Decompose(undef,$buff,'UTF8');
                $tmp = pack('C*', @$uni);
            } else {
                my $fmt = ($double eq "\xfe\xff") ? 'n' : 'v';
                $tmp = pack('C*', unpack("$fmt*",$buff));
            }
            if (Image::ExifTool::GetWarning()) {
                $exifTool->Warn('Superfluous BOM at start of XMP');
            } else {
                $exifTool->Warn('XMP is double UTF-encoded');
                $buff = $tmp;   # use the decoded XMP
            }
            $size = length $buff;
        }
        $dataPt = \$buff;
        $dirStart = 0;
        $dirLen = $dataLen = $size;
        unless ($type) {
            if ($isSVG) {
                $type = 'SVG';
            } elsif ($isXML and not $hasXMP and not $isRDF) {
                $type = 'XML';
            }
        }
        $exifTool->SetFileType($type);
    }

    # take substring if necessary
    if ($dataLen != $dirStart + $dirLen) {
        $buff = substr($$dataPt, $dirStart, $dirLen);
        $dataPt = \$buff;
        $dirStart = 0;
    }
    # extract XMP as a block if specified
    if (($exifTool->{REQ_TAG_LOOKUP}{xmp} or $exifTool->{OPTIONS}{Binary}) and not $isSVG) {
        $exifTool->FoundTag('XMP', substr($$dataPt, $dirStart, $dirLen));
    }
    if ($exifTool->Options('Verbose') and not $exifTool->{XMP_CAPTURE}) {
        $exifTool->VerboseDir($isSVG ? 'SVG' : 'XMP', 0, $dirLen);
    }
    my $begin = '<?xpacket begin=';
    pos($$dataPt) = $dirStart;
    delete $$exifTool{XMP_IS_XML};
    delete $$exifTool{XMP_IS_SVG};
    if ($isXML or $isRDF) {
        $$exifTool{XMP_IS_XML} = $isXML;
        $$exifTool{XMP_IS_SVG} = $isSVG;
        $$exifTool{XMP_NO_XPACKET} = 1 + $bom;
    } elsif ($$dataPt =~ /\G\Q$begin\E/gc) {
        delete $$exifTool{XMP_NO_XPACKET};
    } elsif ($$dataPt =~ /<x(mp)?:x[ma]pmeta/gc) {
        $$exifTool{XMP_NO_XPACKET} = 1 + $bom;
    } else {
        delete $$exifTool{XMP_NO_XPACKET};
        # check for UTF-16 encoding (insert one \0 between characters)
        $begin = join "\0", split //, $begin;
        # must reset pos because it was killed by previous unsuccessful //g match
        pos($$dataPt) = $dirStart;
        if ($$dataPt =~ /\G(\0)?\Q$begin\E\0./g) {
            # validate byte ordering by checking for U+FEFF character
            if ($1) {
                # should be big-endian since we had a leading \0
                $fmt = 'n' if $$dataPt =~ /\G\xfe\xff/g;
            } else {
                $fmt = 'v' if $$dataPt =~ /\G\0\xff\xfe/g;
            }
        } else {
            # check for UTF-32 encoding (with three \0's between characters)
            $begin =~ s/\0/\0\0\0/g;
            pos($$dataPt) = $dirStart;
            if ($$dataPt !~ /\G(\0\0\0)?\Q$begin\E\0\0\0./g) {
                $fmt = 0;   # set format to zero as indication we didn't find encoded XMP
            } elsif ($1) {
                # should be big-endian
                $fmt = 'N' if $$dataPt =~ /\G\0\0\xfe\xff/g;
            } else {
                $fmt = 'V' if $$dataPt =~ /\G\0\0\0\xff\xfe\0\0/g;
            }
        }
        defined $fmt or $exifTool->Warn('XMP character encoding error');
    }
    if ($fmt) {
        # trim if necessary to avoid converting non-UTF data
        if ($dirStart or $dirLen != length($$dataPt) - $dirStart) {
            $buff = substr($$dataPt, $dirStart, $dirLen);
            $dataPt = \$buff;
        }
        # convert into UTF-8
        if ($] >= 5.006001) {
            $buff = pack('C0U*', unpack("$fmt*",$$dataPt));
        } else {
            $buff = Image::ExifTool::PackUTF8(unpack("$fmt*",$$dataPt));
        }
        $dataPt = \$buff;
        $dirStart = 0;
        $dirLen = length $$dataPt;
    }
    # initialize namespace translation
    $xlatNamespace = \%stdXlatNS;

    # avoid scanning for XMP later in case ScanForXMP is set
    $$exifTool{FoundXMP} = 1;

    # set XMP parsing options
    $$exifTool{XMPParseOpts} = $$dirInfo{XMPParseOpts};

    # need to preserve list indices to be able to handle multi-dimensional lists
    $$exifTool{NO_LIST} = 1 if $exifTool->Options('Struct');

    # parse the XMP
    $tagTablePtr or $tagTablePtr = GetTagTable('Image::ExifTool::XMP::Main');
    $rtnVal = 1 if ParseXMPElement($exifTool, $tagTablePtr, $dataPt, $dirStart);

    # return DataPt if successful in case we want it for writing
    $$dirInfo{DataPt} = $dataPt if $rtnVal and $$dirInfo{RAF};

    # restore structures if necessary
    if ($$exifTool{IsStruct}) {
        require 'Image/ExifTool/XMPStruct.pl';
        RestoreStruct($exifTool);
        delete $$exifTool{IsStruct};
    }
    # reset NO_LIST flag (must do this _after_ RestoreStruct() above)
    delete $$exifTool{NO_LIST};

    undef %curNS;
    return $rtnVal;
}


1;  #end

__END__

