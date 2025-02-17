
package Image::ExifTool::XMP;

use strict;
use Image::ExifTool qw(:Utils);
use Image::ExifTool::XMP;

my %sCuePointParam = (
    STRUCT_NAME => 'CuePointParam',
    NAMESPACE   => 'xmpDM',
    key         => { },
    value       => { },
);
my %sMarker = (
    STRUCT_NAME => 'Marker',
    NAMESPACE   => 'xmpDM',
    comment     => { },
    duration    => { },
    location    => { },
    name        => { },
    startTime   => { },
    target      => { },
    type        => { },
    # added Oct 2008
    cuePointParams => { Struct => \%sCuePointParam, List => 'Seq' },
    cuePointType=> { },
    probability => { Writable => 'real' },
    speaker     => { },
);
my %sTime = (
    STRUCT_NAME => 'Time',
    NAMESPACE   => 'xmpDM',
    scale       => { Writable => 'rational' },
    value       => { Writable => 'integer' },
);
my %sTimecode = (
    STRUCT_NAME => 'Timecode',
    NAMESPACE   => 'xmpDM',
    timeFormat  => {
        PrintConv => {
            '24Timecode' => '24 fps',
            '25Timecode' => '25 fps',
            '2997DropTimecode' => '29.97 fps (drop)',
            '2997NonDropTimecode' => '29.97 fps (non-drop)',
            '30Timecode' => '30 fps',
            '50Timecode' => '50 fps',
            '5994DropTimecode' => '59.94 fps (drop)',
            '5994NonDropTimecode' => '59.94 fps (non-drop)',
            '60Timecode' => '60 fps',
            '23976Timecode' => '23.976 fps',
        },
    },
    timeValue   => { },
    value       => { Writable => 'integer' },
);

%Image::ExifTool::XMP::xmpDM = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmpDM', 2 => 'Image' },
    NAMESPACE => 'xmpDM',
    NOTES => 'XMP Dynamic Media schema tags.',
    absPeakAudioFilePath=> { },
    album               => { },
    altTapeName         => { },
    altTimecode         => { Struct => \%sTimecode },
    artist              => { Avoid => 1, Groups => { 2 => 'Author' } },
    audioModDate        => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    audioSampleRate     => { Writable => 'integer' },
    audioSampleType => {
        PrintConv => {
            '8Int' => '8-bit integer',
            '16Int' => '16-bit integer',
            '24Int' => '24-bit integer',
            '32Int' => '32-bit integer',
            '32Float' => '32-bit float',
            'Compressed' => 'Compressed',
            'Packed' => 'Packed',
            'Other' => 'Other',
        },
    },
    audioChannelType => {
        PrintConv => {
            'Mono' => 'Mono',
            'Stereo' => 'Stereo',
            '5.1' => '5.1',
            '7.1' => '7.1',
            '16 Channel' => '16 Channel',
            'Other' => 'Other',
        },
    },
    audioCompressor     => { },
    beatSpliceParams => {
        Struct => {
            STRUCT_NAME => 'BeatSpliceStretch',
            NAMESPACE   => 'xmpDM',
            riseInDecibel       => { Writable => 'real' },
            riseInTimeDuration  => { Struct => \%sTime },
            useFileBeatsMarker  => { Writable => 'boolean' },
        },
    },
    cameraAngle         => { },
    cameraLabel         => { },
    cameraModel         => { },
    cameraMove          => { },
    client              => { },
    comment             => { Name => 'DMComment' },
    composer            => { Groups => { 2 => 'Author' } },
    contributedMedia => {
        Struct => {
            STRUCT_NAME => 'Media',
            NAMESPACE   => 'xmpDM',
            duration    => { Struct => \%sTime },
            managed     => { Writable => 'boolean' },
            path        => { },
            startTime   => { Struct => \%sTime },
            track       => { },
            webStatement=> { },
        },
        List => 'Bag',
    },
    copyright       => { Avoid => 1, Groups => { 2 => 'Author' } }, # (deprecated)
    director        => { },
    directorPhotography => { },
    duration        => { Struct => \%sTime },
    engineer        => { },
    fileDataRate    => { Writable => 'rational' },
    genre           => { },
    good            => { Writable => 'boolean' },
    instrument      => { },
    introTime       => { Struct => \%sTime },
    key => {
        PrintConvColumns => 3,
        PrintConv => {
            'C'  => 'C',  'C#' => 'C#', 'D'  => 'D',  'D#' => 'D#',
            'E'  => 'E',  'F'  => 'F',  'F#' => 'F#', 'G'  => 'G',
            'G#' => 'G#', 'A'  => 'A',  'A#' => 'A#', 'B'  => 'B',
        },
    },
    logComment      => { },
    loop            => { Writable => 'boolean' },
    numberOfBeats   => { Writable => 'real' },
    markers         => { Struct => \%sMarker, List => 'Seq' },
    metadataModDate => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    outCue          => { Struct => \%sTime },
    projectName     => { },
    projectRef => {
        Struct => {
            STRUCT_NAME => 'ProjectLink',
            NAMESPACE   => 'xmpDM',
            path        => { },
            type        => {
                PrintConv => {
                    movie => 'Movie',
                    still => 'Still Image',
                    audio => 'Audio',
                    custom => 'Custom',
                },
            },
        },
    },
    pullDown => {
        PrintConvColumns => 2,
        PrintConv => {
            'WSSWW' => 'WSSWW',  'SSWWW' => 'SSWWW',
            'SWWWS' => 'SWWWS',  'WWWSS' => 'WWWSS',
            'WWSSW' => 'WWSSW',  'WWWSW' => 'WWWSW',
            'WWSWW' => 'WWSWW',  'WSWWW' => 'WSWWW',
            'SWWWW' => 'SWWWW',  'WWWWS' => 'WWWWS',
        },
    },
    relativePeakAudioFilePath => { },
    relativeTimestamp   => { Struct => \%sTime },
    releaseDate         => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    resampleParams => {
        Struct => {
            STRUCT_NAME => 'ResampleStretch',
            NAMESPACE   => 'xmpDM',
            quality     => { PrintConv => { Low => 'Low', Medium => 'Medium', High => 'High' } },
        },
    },
    scaleType => {
        PrintConv => {
            Major => 'Major',
            Minor => 'Minor',
            Both => 'Both',
            Neither => 'Neither',
        },
    },
    scene           => { Avoid => 1 },
    shotDate        => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    shotDay         => { },
    shotLocation    => { },
    shotName        => { },
    shotNumber      => { },
    shotSize        => { },
    speakerPlacement=> { },
    startTimecode   => { Struct => \%sTimecode },
    stretchMode     => {
        PrintConv => {
            'Fixed length' => 'Fixed length',
            'Time-Scale' => 'Time-Scale',
            'Resample' => 'Resample',
            'Beat Splice' => 'Beat Splice',
            'Hybrid' => 'Hybrid',
        },
    },
    takeNumber      => { Writable => 'integer' },
    tapeName        => { },
    tempo           => { Writable => 'real' },
    timeScaleParams => {
        Struct => {
            STRUCT_NAME => 'TimeScaleStretch',
            NAMESPACE   => 'xmpDM',
            frameOverlappingPercentage => { Writable => 'real' },
            frameSize   => { Writable => 'real' },
            quality     => { PrintConv => { Low => 'Low', Medium => 'Medium', High => 'High' } },
        },
    },
    timeSignature   => {
        PrintConvColumns => 3,
        PrintConv => {
            '2/4' => '2/4',  '3/4' => '3/4',  '4/4' => '4/4',
            '5/4' => '5/4',  '7/4' => '7/4',  '6/8' => '6/8',
            '9/8' => '9/8',  '12/8'=> '12/8', 'other' => 'other',
        },
    },
    trackNumber     => { Writable => 'integer' },
    Tracks => {
        Struct => {
            STRUCT_NAME => 'Track',
            NAMESPACE   => 'xmpDM',
            frameRate => { },
            markers   => { Struct => \%sMarker, List => 'Seq' },
            trackName => { },
            trackType => { },
        },
        List => 'Bag',
    },
    videoAlphaMode => {
        PrintConv => {
            'straight' => 'Straight',
            'pre-multiplied', => 'Pre-multiplied',
            'none' => 'None',
        },
    },
    videoAlphaPremultipleColor   => { Struct => \%sColorant },
    videoAlphaUnityIsTransparent => { Writable => 'boolean' },
    videoColorSpace     => {
        PrintConv => {
            'sRGB' => 'sRGB',
            'CCIR-601' => 'CCIR-601',
            'CCIR-709' => 'CCIR-709',
        },
    },
    videoCompressor     => { },
    videoFieldOrder => {
        PrintConv => {
            Upper => 'Upper',
            Lower => 'Lower',
            Progressive => 'Progressive',
        },
    },
    videoFrameRate      => { },
    videoFrameSize      => { Struct => \%sDimensions },
    videoModDate        => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    videoPixelAspectRatio => { Writable => 'rational' },
    videoPixelDepth => {
        PrintConv => {
            '8Int' => '8-bit integer',
            '16Int' => '16-bit integer',
            '24Int' => '24-bit integer',
            '32Int' => '32-bit integer',
            '32Float' => '32-bit float',
            'Other' => 'Other',
        },
    },
);

my %plusVocab = (
    ValueConv => '$val =~ s{http://ns.useplus.org/ldf/vocab/}{}; $val',
    ValueConvInv => '"http://ns.useplus.org/ldf/vocab/$val"',
);

my %plusLicensee = (
    STRUCT_NAME => 'Licensee',
    NAMESPACE => 'plus',
    TYPE => 'plus:LicenseeDetail',
    LicenseeID  => { },
    LicenseeName=> { },
);
my %plusEndUser = (
    STRUCT_NAME => 'EndUser',
    NAMESPACE   => 'plus',
    TYPE => 'plus:EndUserDetail',
    EndUserID   => { },
    EndUserName => { },
);
my %plusLicensor = (
    STRUCT_NAME => 'Licensor',
    NAMESPACE   => 'plus',
    TYPE => 'plus:LicensorDetail',
    LicensorID              => { },
    LicensorName            => { },
    LicensorStreetAddress   => { },
    LicensorExtendedAddress => { },
    LicensorCity            => { },
    LicensorRegion          => { },
    LicensorPostalCode      => { },
    LicensorCountry         => { },
    LicensorTelephoneType1  => {
        %plusVocab,
        PrintConv => {
            'work'  => 'Work',
            'cell'  => 'Cell',
            'fax'   => 'FAX',
            'home'  => 'Home',
            'pager' => 'Pager',
        },
    },
    LicensorTelephone1      => { },
    LicensorTelephoneType2  => {
        %plusVocab,
        PrintConv => {
            'work'  => 'Work',
            'cell'  => 'Cell',
            'fax'   => 'FAX',
            'home'  => 'Home',
            'pager' => 'Pager',
        },
    },
    LicensorTelephone2  => { },
    LicensorEmail       => { },
    LicensorURL         => { },
);
my %plusCopyrightOwner = (
    STRUCT_NAME => 'CopyrightOwner',
    NAMESPACE   => 'plus',
    TYPE        => 'plus:CopyrightOwnerDetail',
    CopyrightOwnerID    => { },
    CopyrightOwnerName  => { },
);
my %plusImageCreator = (
    STRUCT_NAME => 'ImageCreator',
    NAMESPACE   => 'plus',
    TYPE        => 'plus:ImageCreatorDetail',
    ImageCreatorID      => { },
    ImageCreatorName    => { },
);
my %plusImageSupplier = (
    STRUCT_NAME => 'ImageSupplier',
    NAMESPACE   => 'plus',
    TYPE        => 'plus:ImageSupplierDetail',
    ImageSupplierID     => { },
    ImageSupplierName   => { },
);

%Image::ExifTool::XMP::plus = (
    %xmpTableDefaults,
    GROUPS => { 0 => 'XMP', 1 => 'XMP-plus', 2 => 'Author' },
    NAMESPACE => 'plus',
    NOTES => q{
        PLUS License Data Format 1.2.0 schema tags.  Note that all
        controlled-vocabulary tags in this table (ie. tags with a fixed set of
        values) have raw values which begin with "http://ns.useplus.org/ldf/vocab/",
        but to reduce clutter this prefix has been removed from the values shown
        below.  (see L<http://ns.useplus.org/>)
    },
    Version  => { Name => 'PLUSVersion' },
    Licensee => {
        Struct => \%plusLicensee,
        List => 'Seq',
    },
    LicenseeLicenseeID   => { Flat => 1, Name => 'LicenseeID' },
    LicenseeLicenseeName => { Flat => 1, Name => 'LicenseeName' },
    EndUser => {
        Struct => \%plusEndUser,
        List => 'Seq',
    },
    EndUserEndUserID    => { Flat => 1, Name => 'EndUserID' },
    EndUserEndUserName  => { Flat => 1, Name => 'EndUserName' },
    Licensor => {
        Struct => \%plusLicensor,
        List => 'Seq',
    },
    LicensorLicensorID              => { Flat => 1, Name => 'LicensorID' },
    LicensorLicensorName            => { Flat => 1, Name => 'LicensorName' },
    LicensorLicensorStreetAddress   => { Flat => 1, Name => 'LicensorStreetAddress' },
    LicensorLicensorExtendedAddress => { Flat => 1, Name => 'LicensorExtendedAddress' },
    LicensorLicensorCity            => { Flat => 1, Name => 'LicensorCity' },
    LicensorLicensorRegion          => { Flat => 1, Name => 'LicensorRegion' },
    LicensorLicensorPostalCode      => { Flat => 1, Name => 'LicensorPostalCode' },
    LicensorLicensorCountry         => { Flat => 1, Name => 'LicensorCountry' },
    LicensorLicensorTelephoneType1  => { Flat => 1, Name => 'LicensorTelephoneType1' },
    LicensorLicensorTelephone1      => { Flat => 1, Name => 'LicensorTelephone1' },
    LicensorLicensorTelephoneType2  => { Flat => 1, Name => 'LicensorTelephoneType2' },
    LicensorLicensorTelephone2      => { Flat => 1, Name => 'LicensorTelephone2' },
    LicensorLicensorEmail           => { Flat => 1, Name => 'LicensorEmail' },
    LicensorLicensorURL             => { Flat => 1, Name => 'LicensorURL' },
    LicensorNotes               => { Writable => 'lang-alt' },
    MediaSummaryCode            => { },
    LicenseStartDate            => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    LicenseEndDate              => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    MediaConstraints            => { Writable => 'lang-alt' },
    RegionConstraints           => { Writable => 'lang-alt' },
    ProductOrServiceConstraints => { Writable => 'lang-alt' },
    ImageFileConstraints => {
        List => 'Bag',
        %plusVocab,
        PrintConv => {
            'IF-MFN' => 'Maintain File Name',
            'IF-MID' => 'Maintain ID in File Name',
            'IF-MMD' => 'Maintain Metadata',
            'IF-MFT' => 'Maintain File Type',
        },
    },
    ImageAlterationConstraints => {
        List => 'Bag',
        %plusVocab,
        PrintConv => {
            'AL-CRP' => 'No Cropping',
            'AL-FLP' => 'No Flipping',
            'AL-RET' => 'No Retouching',
            'AL-CLR' => 'No Colorization',
            'AL-DCL' => 'No De-Colorization',
            'AL-MRG' => 'No Merging',
        },
    },
    ImageDuplicationConstraints => {
        %plusVocab,
        PrintConv => {
            'DP-NDC' => 'No Duplication Constraints',
            'DP-LIC' => 'Duplication Only as Necessary Under License',
            'DP-NOD' => 'No Duplication',
        },
    },
    ModelReleaseStatus => {
        %plusVocab,
        PrintConv => {
            'MR-NON' => 'None',
            'MR-NAP' => 'Not Applicable',
            'MR-UMR' => 'Unlimited Model Releases',
            'MR-LMR' => 'Limited or Incomplete Model Releases',
        },
    },
    ModelReleaseID      => { List => 'Bag' },
    MinorModelAgeDisclosure => {
        %plusVocab,
        PrintConv => {
            'AG-UNK' => 'Age Unknown',
            'AG-A25' => 'Age 25 or Over',
            'AG-A24' => 'Age 24',
            'AG-A23' => 'Age 23',
            'AG-A22' => 'Age 22',
            'AG-A21' => 'Age 21',
            'AG-A20' => 'Age 20',
            'AG-A19' => 'Age 19',
            'AG-A18' => 'Age 18',
            'AG-A17' => 'Age 17',
            'AG-A16' => 'Age 16',
            'AG-A15' => 'Age 15',
            'AG-U14' => 'Age 14 or Under',
        },
    },
    PropertyReleaseStatus => {
        %plusVocab,
        PrintConv => {
            'PR-NON' => 'None',
            'PR-NAP' => 'Not Applicable',
            'PR-UPR' => 'Unlimited Property Releases',
            'PR-LPR' => 'Limited or Incomplete Property Releases',
        },
    },
    PropertyReleaseID  => { List => 'Bag' },
    OtherConstraints   => { Writable => 'lang-alt' },
    CreditLineRequired => {
        %plusVocab,
        PrintConv => {
            'CR-NRQ' => 'Not Required',
            'CR-COI' => 'Credit on Image',
            'CR-CAI' => 'Credit Adjacent To Image',
            'CR-CCA' => 'Credit in Credits Area',
        },
    },
    AdultContentWarning => {
        %plusVocab,
        PrintConv => {
            'CW-NRQ' => 'Not Required',
            'CW-AWR' => 'Adult Content Warning Required',
            'CW-UNK' => 'Unknown',
        },
    },
    OtherLicenseRequirements    => { Writable => 'lang-alt' },
    TermsAndConditionsText      => { Writable => 'lang-alt' },
    TermsAndConditionsURL       => { },
    OtherConditions             => { Writable => 'lang-alt' },
    ImageType => {
        %plusVocab,
        PrintConv => {
            'TY-PHO' => 'Photographic Image',
            'TY-ILL' => 'Illustrated Image',
            'TY-MCI' => 'Multimedia or Composited Image',
            'TY-VID' => 'Video',
            'TY-OTR' => 'Other',
        },
    },
    LicensorImageID     => { },
    FileNameAsDelivered => { },
    ImageFileFormatAsDelivered => {
        %plusVocab,
        PrintConv => {
            'FF-JPG' => 'JPEG Interchange Formats (JPG, JIF, JFIF)',
            'FF-TIF' => 'Tagged Image File Format (TIFF)',
            'FF-GIF' => 'Graphics Interchange Format (GIF)',
            'FF-RAW' => 'Proprietary RAW Image Format',
            'FF-DNG' => 'Digital Negative (DNG)',
            'FF-EPS' => 'Encapsulated PostScript (EPS)',
            'FF-BMP' => 'Windows Bitmap (BMP)',
            'FF-PSD' => 'Photoshop Document (PSD)',
            'FF-PIC' => 'Macintosh Picture (PICT)',
            'FF-PNG' => 'Portable Network Graphics (PNG)',
            'FF-WMP' => 'Windows Media Photo (HD Photo)',
            'FF-OTR' => 'Other',
        },
    },
    ImageFileSizeAsDelivered => {
        %plusVocab,
        PrintConv => {
            'SZ-U01' => 'Up to 1 MB',
            'SZ-U10' => 'Up to 10 MB',
            'SZ-U30' => 'Up to 30 MB',
            'SZ-U50' => 'Up to 50 MB',
            'SZ-G50' => 'Greater than 50 MB',
        },
    },
    CopyrightStatus => {
        %plusVocab,
        PrintConv => {
            'CS-PRO' => 'Protected',
            'CS-PUB' => 'Public Domain',
            'CS-UNK' => 'Unknown',
        },
    },
    CopyrightRegistrationNumber => { },
    FirstPublicationDate        => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    CopyrightOwner              => { Struct => \%plusCopyrightOwner, List => 'Seq' },
    CopyrightOwnerCopyrightOwnerID   => { Flat => 1, Name => 'CopyrightOwnerID' },
    CopyrightOwnerCopyrightOwnerName => { Flat => 1, Name => 'CopyrightOwnerName' },
    CopyrightOwnerImageID            => { },
    ImageCreator => {
        Struct => \%plusImageCreator,
        List => 'Seq',
    },
    ImageCreatorImageCreatorID   => { Flat => 1, Name => 'ImageCreatorID' },
    ImageCreatorImageCreatorName => { Flat => 1, Name => 'ImageCreatorName' },
    ImageCreatorImageID          => { },
    ImageSupplier => {
        Struct => \%plusImageSupplier,
        List => 'Seq',
    },
    ImageSupplierImageSupplierID   => { Flat => 1, Name => 'ImageSupplierID' },
    ImageSupplierImageSupplierName => { Flat => 1, Name => 'ImageSupplierName' },
    ImageSupplierImageID    => { },
    LicenseeImageID         => { },
    LicenseeImageNotes      => { Writable => 'lang-alt' },
    OtherImageInfo          => { Writable => 'lang-alt' },
    LicenseID               => { },
    LicensorTransactionID   => { List => 'Bag' },
    LicenseeTransactionID   => { List => 'Bag' },
    LicenseeProjectReference=> { List => 'Bag' },
    LicenseTransactionDate  => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    Reuse => {
        %plusVocab,
        PrintConv => {
            'RE-REU' => 'Repeat Use',
            'RE-NAP' => 'Not Applicable',
        },
    },
    OtherLicenseDocuments   => { List => 'Bag' },
    OtherLicenseInfo        => { Writable => 'lang-alt' },
    # Note: these are Bag's of lang-alt lists -- a nested list tag!
    Custom1     => { List => 'Bag', Writable => 'lang-alt' },
    Custom2     => { List => 'Bag', Writable => 'lang-alt' },
    Custom3     => { List => 'Bag', Writable => 'lang-alt' },
    Custom4     => { List => 'Bag', Writable => 'lang-alt' },
    Custom5     => { List => 'Bag', Writable => 'lang-alt' },
    Custom6     => { List => 'Bag', Writable => 'lang-alt' },
    Custom7     => { List => 'Bag', Writable => 'lang-alt' },
    Custom8     => { List => 'Bag', Writable => 'lang-alt' },
    Custom9     => { List => 'Bag', Writable => 'lang-alt' },
    Custom10    => { List => 'Bag', Writable => 'lang-alt' },
);



%Image::ExifTool::XMP::prism = (
    %xmpTableDefaults,
    GROUPS => { 0 => 'XMP', 1 => 'XMP-prism', 2 => 'Document' },
    NAMESPACE => 'prism',
    NOTES => q{
        Publishing Requirements for Industry Standard Metadata 2.1 schema tags. (see
        L<http://www.prismstandard.org/>)
    },
    aggregationType => { List => 'Bag' },
    alternateTitle  => { List => 'Bag' },
    byteCount       => { Writable => 'integer' },
    channel         => { List => 'Bag' },
    complianceProfile=>{ PrintConv => { three => 'Three' } },
    copyright       => { Groups => { 2 => 'Author' } },
    corporateEntity => { List => 'Bag' },
    coverDate       => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    coverDisplayDate=> { },
    creationDate    => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    dateRecieved    => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    distributor     => { },
    doi             => { Name => 'DOI', Description => 'Digital Object Identifier' },
    edition         => { },
    eIssn           => { },
    embargoDate     => { List => 'Bag', %dateTimeInfo, Groups => { 2 => 'Time'} },
    endingPage      => { },
    event           => { List => 'Bag' },
    expirationDate  => { List => 'Bag', %dateTimeInfo, Groups => { 2 => 'Time'} },
    genre           => { List => 'Bag' },
    hasAlternative  => { List => 'Bag' },
    hasCorrection   => { },
    hasPreviousVersion => { },
    hasTranslation  => { List => 'Bag' },
    industry        => { List => 'Bag' },
    isCorrectionOf  => { List => 'Bag' },
    issn            => { Name => 'ISSN' },
    issueIdentifier => { },
    issueName       => { },
    isTranslationOf => { },
    keyword         => { List => 'Bag' },
    killDate        => { %dateTimeInfo, Groups => { 2 => 'Time'} },
    location        => { List => 'Bag' },
    # metadataContainer => { }, (not valid for PRISM XMP)
    modificationDate=> { %dateTimeInfo, Groups => { 2 => 'Time'} },
    number          => { },
    object          => { List => 'Bag' },
    organization    => { List => 'Bag' },
    originPlatform  => {
        List => 'Bag',
        PrintConv => {
            email       => 'E-Mail',
            mobile      => 'Mobile',
            broadcast   => 'Broadcast',
            web         => 'Web',
           'print'      => 'Print',
            recordableMedia => 'Recordable Media',
            other       => 'Other',
        },
    },
    pageRange       => { List => 'Bag' },
    person          => { },
    publicationDate => { List => 'Bag', %dateTimeInfo, Groups => { 2 => 'Time'} },
    publicationName => { },
    rightsAgent     => { },
    section         => { },
    startingPage    => { },
    subsection1     => { },
    subsection2     => { },
    subsection3     => { },
    subsection4     => { },
    teaser          => { List => 'Bag' },
    ticker          => { List => 'Bag' },
    timePeriod      => { },
    url             => { Name => 'URL', List => 'Bag' },
    versionIdentifier => { },
    volume          => { },
    wordCount       => { Writable => 'integer' },
    # new in PRISM 2.1
    isbn            => { Name => 'ISBN' },
);

%Image::ExifTool::XMP::prl = (
    %xmpTableDefaults,
    GROUPS => { 0 => 'XMP', 1 => 'XMP-prl', 2 => 'Document' },
    NAMESPACE => 'prl',
    NOTES => q{
        PRISM Rights Language 2.1 schema tags.  (see
        L<http://www.prismstandard.org/>)
    },
    geography       => { List => 'Bag' },
    industry        => { List => 'Bag' },
    usage           => { List => 'Bag' },
);

%Image::ExifTool::XMP::pur = (
    %xmpTableDefaults,
    GROUPS => { 0 => 'XMP', 1 => 'XMP-pur', 2 => 'Document' },
    NAMESPACE => 'pur',
    NOTES => q{
        Prism Usage Rights 2.1 schema tags.  (see L<http://www.prismstandard.org/>)
    },
    adultContentWarning => { List => 'Bag' },
    agreement           => { List => 'Bag' },
    copyright           => { Writable => 'lang-alt', Groups => { 2 => 'Author' } },
    creditLine          => { List => 'Bag' },
    embargoDate         => { List => 'Bag', %dateTimeInfo, Groups => { 2 => 'Time'} },
    exclusivityEndDate  => { List => 'Bag', %dateTimeInfo, Groups => { 2 => 'Time'} },
    expirationDate      => { List => 'Bag', %dateTimeInfo, Groups => { 2 => 'Time'} },
    imageSizeRestriction=> { },
    optionEndDate       => { List => 'Bag', %dateTimeInfo, Groups => { 2 => 'Time'} },
    permissions         => { List => 'Bag' },
    restrictions        => { List => 'Bag' },
    reuseProhibited     => { Writable => 'boolean' },
    rightsAgent         => { },
    rightsOwner         => { },
    usageFee            => { List => 'Bag' },
);

%Image::ExifTool::XMP::DICOM = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-DICOM', 2 => 'Image' },
    NAMESPACE => 'DICOM',
    NOTES => 'DICOM schema tags.',
    # change some tag names to correspond with DICOM tags
    PatientName             => { },
    PatientID               => { },
    PatientSex              => { },
    PatientDOB => {
        Name => 'PatientBirthDate',
        Groups => { 2 => 'Time' },
        %dateTimeInfo,
    },
    StudyID                 => { },
    StudyPhysician          => { },
    StudyDateTime           => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    StudyDescription        => { },
    SeriesNumber            => { },
    SeriesModality          => { },
    SeriesDateTime          => { Groups => { 2 => 'Time' }, %dateTimeInfo },
    SeriesDescription       => { },
    EquipmentInstitution    => { },
    EquipmentManufacturer   => { },
);

%Image::ExifTool::XMP::PixelLive = (
    GROUPS => { 1 => 'XMP-PixelLive', 2 => 'Image' },
    NAMESPACE => 'PixelLive',
    NOTES => q{
        PixelLive schema tags.  These tags are not writable becase they are very
        uncommon and I haven't been able to locate a reference which gives the
        namespace URI.
    },
    AUTHOR    => { Name => 'Author',   Avoid => 1, Groups => { 2 => 'Author' } },
    COMMENTS  => { Name => 'Comments', Avoid => 1 },
    COPYRIGHT => { Name => 'Copyright',Avoid => 1, Groups => { 2 => 'Author' } },
    DATE      => { Name => 'Date',     Avoid => 1, Groups => { 2 => 'Time' } },
    GENRE     => { Name => 'Genre',    Avoid => 1 },
    TITLE     => { Name => 'Title',    Avoid => 1 },
);

%Image::ExifTool::XMP::extensis = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-extensis', 2 => 'Image' },
    NAMESPACE => 'extensis',
    NOTES => 'Tags used by Extensis Portfolio.',
    Approved     => { Writable => 'boolean' },
    ApprovedBy   => { },
    ClientName   => { },
    JobName      => { },
    JobStatus    => { },
    RoutedTo     => { },
    RoutingNotes => { },
    WorkToDo     => { },
);

%Image::ExifTool::XMP::acdsee = (
    %xmpTableDefaults,
    GROUPS => { 0 => 'XMP', 1 => 'XMP-acdsee', 2 => 'Image' },
    NAMESPACE => 'acdsee',
    NOTES => q{
        ACD Systems ACDSee schema tags.

        (A note to software developers: Re-inventing your own private tags instead
        of using the equivalent tags in standard XMP schemas defeats one of the most
        valuable features of metadata: interoperability.  Your applications mumble
        to themselves instead of speaking out for the rest of the world to hear.)
    },
    author     => { Avoid => 1, Groups => { 2 => 'Author' } },
    caption    => { Avoid => 1 },
    categories => { Avoid => 1 },
    datetime   => { Avoid => 1, Groups => { 2 => 'Time' }, %dateTimeInfo },
    keywords   => { Avoid => 1, List => 'Bag' },
    notes      => { Avoid => 1 },
    rating     => { Avoid => 1, Writable => 'real' }, # integer?
    tagged     => { Avoid => 1, Writable => 'boolean' },
    rawrppused => { Writable => 'boolean' },
    rpp => {
        Name => 'RPP',
        Writable => 'lang-alt',
        Notes => 'raw processing settings in XML format',
        Binary => 1,
    },
    dpp => {
        Name => 'DPP',
        Writable => 'lang-alt',
        Notes => 'newer version of XML raw processing settings',
        Binary => 1,
    },
);

%Image::ExifTool::XMP::xmpPLUS = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-xmpPLUS', 2 => 'Author' },
    NAMESPACE => 'xmpPLUS',
    NOTES => 'XMP Picture Licensing Universal System (PLUS) schema tags.',
    CreditLineReq   => { Writable => 'boolean' },
    ReuseAllowed    => { Writable => 'boolean' },
);

%Image::ExifTool::XMP::cc = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-cc', 2 => 'Author' },
    NAMESPACE => 'cc',
    NOTES => q{
        Creative Commons schema tags.  (see
        L<http://creativecommons.org/technology/xmp>)
    },
    license => { },
    morePermissions => { },
    attributionName => { },
    attributionURL  => { },
);

%Image::ExifTool::XMP::dex = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-dex', 2 => 'Image' },
    NAMESPACE => 'dex',
    NOTES => q{
        Description Explorer schema tags.  These tags are not very common.  The
        Source and Rating tags are avoided when writing due to name conflicts with
        other XMP tags.  (see L<http://www.optimasc.com/products/fileid/>)
    },
    crc32       => { Name => 'CRC32', Writable => 'integer' },
    source      => { Avoid => 1 },
    shortdescription => {
        Name => 'ShortDescription',
        Writable => 'lang-alt',
    },
    licensetype => {
        Name => 'LicenseType',
        PrintConv => {
            unknown        => 'Unknown',
            shareware      => 'Shareware',
            freeware       => 'Freeware',
            adware         => 'Adware',
            demo           => 'Demo',
            commercial     => 'Commercial',
           'public domain' => 'Public Domain',
           'open source'   => 'Open Source',
        },
    },
    revision    => { },
    rating      => { Avoid => 1 },
    os          => { Name => 'OS', Writable => 'integer' },
    ffid        => { Name => 'FFID' },
);

%Image::ExifTool::XMP::MediaPro = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-mediapro', 2 => 'Image' },
    NAMESPACE => 'mediapro',
    NOTES => 'iView MediaPro schema tags.',
    Event       => { },
    Location    => {
        Avoid => 1,
        Groups => { 2 => 'Location' },
        Notes => 'avoided due to conflict with XMP-iptcCore:Location',
    },
    Status      => { },
    People      => { List => 'Bag' },
    UserFields  => { List => 'Bag' },
    CatalogSets => { List => 'Bag' },
);

%Image::ExifTool::XMP::digiKam = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-digiKam', 2 => 'Image' },
    NAMESPACE => 'digiKam',
    NOTES => 'DigiKam schema tags.',
    CaptionsAuthorNames    => { Writable => 'lang-alt' },
    CaptionsDateTimeStamps => { Writable => 'lang-alt' },
    TagsList               => { List => 'Seq' },
);

%Image::ExifTool::XMP::swf = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-swf', 2 => 'Image' },
    NAMESPACE => 'swf',
    NOTES => 'Adobe SWF schema tags.',
    type         => { Avoid => 1 },
    bgalpha      => { Name => 'BackgroundAlpha', Writable => 'integer' },
    forwardlock  => { Name => 'ForwardLock',     Writable => 'boolean' },
    maxstorage   => { Name => 'MaxStorage',      Writable => 'integer' }, # (CS5)
);

%Image::ExifTool::XMP::cell = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-cell', 2 => 'Location' },
    NAMESPACE => 'cell',
    NOTES => 'Location tags written by some Sony Ericsson phones.',
    mcc     => { Name => 'MobileCountryCode' },
    mnc     => { Name => 'MobileNetworkCode' },
    lac     => { Name => 'LocationAreaCode' },
    cellid  => { Name => 'CellTowerID' },
    cgi     => { Name => 'CellGlobalID' },
    r       => { Name => 'CellR' }, # (what is this? Radius?)
);

my %sExtensions = (
    STRUCT_NAME => 'Extensions',
    NAMESPACE   => undef, # variable namespace
    NOTES => q{
        This structure may contain any top-level XMP tags, but none have been
        pre-defined in ExifTool.  Without pre-defined flattened tag names,
        RegionExtensions may be written only as a structure (ie.
        C<{xmp-dc:creator=me,rating=5}>).  Fields for this structure are identified
        using the standard ExifTool tag name (with optional leading group name,
        and/or trailing language code, and/or trailing C<#> symbol to disable print
        conversion).
    },
);
my %sRegionStruct = (
    STRUCT_NAME => 'RegionStruct',
    NAMESPACE   => 'mwg-rs',
    Area => { Struct => \%sArea },
    Type => {
        PrintConv => {
            Face => 'Face',
            Pet => 'Pet',
            Focus => 'Focus',
            BarCode => 'BarCode',
        },
    },
    Name        => { },
    Description => { },
    FocusUsage  => {
        PrintConv => {
            EvaluatedUsed => 'Evaluated, Used',
            EvaluatedNotUsed => 'Evaluated, Not Used',
            NotEvaluatedNotUsed => 'Not Evaluated, Not Used',
        },
    },
    BarCodeValue=> { },
    Extensions  => { Struct => \%sExtensions },
    seeAlso => { Namespace => 'rdfs', Resource => 1 },
);
my %sKeywordStruct4 = (
    STRUCT_NAME => 'KeywordStruct4',
    NAMESPACE   => 'mwg-kw',
    Keyword   => { },
    Applied   => { Writable => 'boolean' },
);
my %sKeywordStruct3 = (
    STRUCT_NAME => 'KeywordStruct3',
    NAMESPACE   => 'mwg-kw',
    Keyword   => { },
    Applied   => { Writable => 'boolean' },
    Children  => { Struct => \%sKeywordStruct4, List => 'Bag' },
);
my %sKeywordStruct2 = (
    STRUCT_NAME => 'KeywordStruct2',
    NAMESPACE   => 'mwg-kw',
    Keyword   => { },
    Applied   => { Writable => 'boolean' },
    Children  => { Struct => \%sKeywordStruct3, List => 'Bag' },
);
my %sKeywordStruct1 = (
    STRUCT_NAME => 'KeywordStruct1',
    NAMESPACE   => 'mwg-kw',
    Keyword   => { },
    Applied   => { Writable => 'boolean' },
    Children  => { Struct => \%sKeywordStruct2, List => 'Bag' },
);

%Image::ExifTool::XMP::mwg_rs = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-mwg-rs', 2 => 'Image' },
    NAMESPACE => 'mwg-rs',
    NOTES => q{
        Image region metadata defined by the MWG 2.0 specification.  See
        L<http://www.metadataworkinggroup.org/> for the official specification.
    },
    Regions => {
        Name => 'RegionInfo',
        Struct => {
            STRUCT_NAME => 'RegionInfo',
            NAMESPACE   => 'mwg-rs',
            RegionList => { Struct => \%sRegionStruct, List => 'Bag' },
            AppliedToDimensions => { Struct => \%sDimensions },
        },
    },
    RegionsAppliedToDimensions  => { Flat => 1, Name => 'RegionAppliedToDimensions' },
    RegionsAppliedToDimensionsW => { Flat => 1, Name => 'RegionAppliedToDimensionsW' },
    RegionsAppliedToDimensionsH => { Flat => 1, Name => 'RegionAppliedToDimensionsH' },
    RegionsAppliedToDimensionsUnit=>{Flat => 1, Name => 'RegionAppliedToDimensionsUnit' },
    RegionsRegionList           => { Flat => 1, Name => 'RegionList' },
    RegionsRegionListArea       => { Flat => 1, Name => 'RegionArea' },
    RegionsRegionListAreaX      => { Flat => 1, Name => 'RegionAreaX' },
    RegionsRegionListAreaY      => { Flat => 1, Name => 'RegionAreaY' },
    RegionsRegionListAreaW      => { Flat => 1, Name => 'RegionAreaW' },
    RegionsRegionListAreaH      => { Flat => 1, Name => 'RegionAreaH' },
    RegionsRegionListAreaD      => { Flat => 1, Name => 'RegionAreaD' },
    RegionsRegionListAreaUnit   => { Flat => 1, Name => 'RegionAreaUnit' },
    RegionsRegionListType       => { Flat => 1, Name => 'RegionType' },
    RegionsRegionListName       => { Flat => 1, Name => 'RegionName' },
    RegionsRegionListDescription=> { Flat => 1, Name => 'RegionDescription' },
    RegionsRegionListFocusUsage => { Flat => 1, Name => 'RegionFocusUsage' },
    RegionsRegionListBarCodeValue=>{ Flat => 1, Name => 'RegionBarCodeValue' },
    RegionsRegionListExtensions => { Flat => 1, Name => 'RegionExtensions' },
    RegionsRegionListSeeAlso    => { Flat => 1, Name => 'RegionSeeAlso' },
);

%Image::ExifTool::XMP::mwg_kw = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-mwg-kw', 2 => 'Image' },
    NAMESPACE => 'mwg-kw',
    NOTES => q{
        Hierarchical keywords metadata defined by the MWG 2.0 specification. 
        ExifTool unrolls keyword structures to an arbitrary depth of 4 to allow
        individual levels to be accessed with different tag names, and to avoid
        infinite recursion.  See L<http://www.metadataworkinggroup.org/> for the
        official specification.
    },
    # arbitrarily define only the first 4 levels of the keyword hierarchy
    Keywords => {
        Name => 'KeywordInfo',
        Struct => {
            STRUCT_NAME => 'KeywordInfo',
            NAMESPACE   => 'mwg-kw',
            Hierarchy => { Struct => \%sKeywordStruct1, List => 'Bag' },
        },
    },
    KeywordsHierarchy => { Name => 'HierarchicalKeywords', Flat => 1 },
    KeywordsHierarchyKeyword  => { Name => 'HierarchicalKeywords1', Flat => 1 },
    KeywordsHierarchyApplied  => { Name => 'HierarchicalKeywords1Applied', Flat => 1 },
    KeywordsHierarchyChildren => { Name => 'HierarchicalKeywords1Children', Flat => 1 },
    KeywordsHierarchyChildrenKeyword  => { Name => 'HierarchicalKeywords2', Flat => 1 },
    KeywordsHierarchyChildrenApplied  => { Name => 'HierarchicalKeywords2Applied', Flat => 1 },
    KeywordsHierarchyChildrenChildren => { Name => 'HierarchicalKeywords2Children', Flat => 1 },
    KeywordsHierarchyChildrenChildrenKeyword  => { Name => 'HierarchicalKeywords3', Flat => 1 },
    KeywordsHierarchyChildrenChildrenApplied  => { Name => 'HierarchicalKeywords3Applied', Flat => 1 },
    KeywordsHierarchyChildrenChildrenChildren => { Name => 'HierarchicalKeywords3Children', Flat => 1 },
    KeywordsHierarchyChildrenChildrenChildrenKeyword => { Name => 'HierarchicalKeywords4', Flat => 1 },
    KeywordsHierarchyChildrenChildrenChildrenApplied => { Name => 'HierarchicalKeywords4Applied', Flat => 1 },
);

%Image::ExifTool::XMP::mwg_coll = (
    %xmpTableDefaults,
    GROUPS => { 1 => 'XMP-mwg-coll', 2 => 'Image' },
    NAMESPACE => 'mwg-coll',
    NOTES => q{
        Collections metadata defined by the MWG 2.0 specification.  See
        L<http://www.metadataworkinggroup.org/> for the official specification.
    },
    Collections => {
        List => 'Bag',
        Struct => {
            STRUCT_NAME => 'CollectionInfo',
            NAMESPACE   => 'mwg-coll',
            CollectionName => { },
            CollectionURI  => { },
        },
    },
    CollectionsCollectionName => { Name => 'CollectionName', Flat => 1 },
    CollectionsCollectionURI  => { Name => 'CollectionURI',  Flat => 1 },
);

%Image::ExifTool::XMP::SVG = (
    GROUPS => { 0 => 'SVG', 1 => 'SVG', 2 => 'Image' },
    NAMESPACE => 'svg',
    LANG_INFO => \&GetLangInfo,
    NOTES => q{
        SVG (Scalable Vector Graphics) image tags.  By default, only the top-level
        SVG and Metadata tags are extracted from these images, but all graphics tags
        may be extracted by setting the Unknown option to 2 (-U on the command
        line).  The SVG tags are not part of XMP as such, but are included with the
        XMP module for convenience.  (see L<http://www.w3.org/TR/SVG11/>)
    },
    version    => 'SVGVersion',
    id         => 'ID',
    metadataId => 'MetadataID',
    width      => 'ImageWidth',
    height     => 'ImageHeight',
);

%Image::ExifTool::XMP::otherSVG = (
    GROUPS => { 0 => 'SVG', 2 => 'Unknown' },
    LANG_INFO => \&GetLangInfo,
    NAMESPACE => undef, # variable namespace
);

my ($table, $key);
foreach $table (
    \%Image::ExifTool::XMP::prism,
    \%Image::ExifTool::XMP::prl,
    \%Image::ExifTool::XMP::pur)
{
    foreach $key (TagTableKeys($table)) {
        $table->{$key}->{Avoid} = 1;
    }
}


1;  #end

__END__

