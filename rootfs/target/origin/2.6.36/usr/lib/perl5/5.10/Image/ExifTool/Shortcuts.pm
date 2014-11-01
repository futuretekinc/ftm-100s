
package Image::ExifTool::Shortcuts;

use strict;
use vars qw($VERSION);

$VERSION = '1.42';

%Image::ExifTool::Shortcuts::Main = (
    # this shortcut allows the three common date/time tags to be shifted at once
    AllDates => [
        'DateTimeOriginal',
        'CreateDate',
        'ModifyDate',
    ],
    # This is a shortcut to some common information which is useful in most images
    Common => [
        'FileName',
        'FileSize',
        'Model',
        'DateTimeOriginal',
        'ImageSize',
        'Quality',
        'FocalLength',
        'ShutterSpeed',
        'Aperture',
        'ISO',
        'WhiteBalance',
        'Flash',
    ],
    # This shortcut provides the same information as the Canon utilities
    Canon => [
        'FileName',
        'Model',
        'DateTimeOriginal',
        'ShootingMode',
        'ShutterSpeed',
        'Aperture',
        'MeteringMode',
        'ExposureCompensation',
        'ISO',
        'Lens',
        'FocalLength',
        'ImageSize',
        'Quality',
        'Flash',
        'FlashType',
        'ConditionalFEC',
        'RedEyeReduction',
        'ShutterCurtainHack',
        'WhiteBalance',
        'FocusMode',
        'Contrast',
        'Sharpness',
        'Saturation',
        'ColorTone',
        'ColorSpace',
        'LongExposureNoiseReduction',
        'FileSize',
        'FileNumber',
        'DriveMode',
        'OwnerName',
        'SerialNumber',
    ],
    Nikon => [
        'Model',
        'SubSecDateTimeOriginal',
        'ShutterCount',
        'LensSpec',
        'FocalLength',
        'ImageSize',
        'ShutterSpeed',
        'Aperture',
        'ISO',
        'NoiseReduction',
        'ExposureProgram',
        'ExposureCompensation',
        'WhiteBalance',
        'WhiteBalanceFineTune',
        'ShootingMode',
        'Quality',
        'MeteringMode',
        'FocusMode',
        'ImageOptimization',
        'ToneComp',
        'ColorHue',
        'ColorSpace',
        'HueAdjustment',
        'Saturation',
        'Sharpness',
        'Flash',
        'FlashMode',
        'FlashExposureComp',
    ],
    # This shortcut may be useful when copying tags between files to either
    # copy the maker notes as a block or prevent it from being copied
    MakerNotes => [
        'MakerNotes',   # (for RIFF MakerNotes)
        'MakerNoteCanon',
        'MakerNoteCasio',
        'MakerNoteCasio2',
        'MakerNoteFujiFilm',
        'MakerNoteGE',
        'MakerNoteGE2',
        'MakerNoteHP',
        'MakerNoteHP2',
        'MakerNoteHP4',
        'MakerNoteHP6',
        'MakerNoteISL',
        'MakerNoteJVC',
        'MakerNoteJVCText',
        'MakerNoteKodak1a',
        'MakerNoteKodak1b',
        'MakerNoteKodak2',
        'MakerNoteKodak3',
        'MakerNoteKodak4',
        'MakerNoteKodak5',
        'MakerNoteKodak6a',
        'MakerNoteKodak6b',
        'MakerNoteKodak7',
        'MakerNoteKodak8a',
        'MakerNoteKodak8b',
        'MakerNoteKodak9',
        'MakerNoteKodak10',
        'MakerNoteKodakUnknown',
        'MakerNoteKyocera',
        'MakerNoteMinolta',
        'MakerNoteMinolta2',
        'MakerNoteMinolta3',
        'MakerNoteNikon',
        'MakerNoteNikon2',
        'MakerNoteNikon3',
        'MakerNoteOlympus',
        'MakerNoteOlympus2',
        'MakerNoteLeica',
        'MakerNoteLeica2',
        'MakerNoteLeica3',
        'MakerNoteLeica4',
        'MakerNoteLeica5',
        'MakerNoteLeica6',
        'MakerNotePanasonic',
        'MakerNotePanasonic2',
        'MakerNotePentax',
        'MakerNotePentax2',
        'MakerNotePentax3',
        'MakerNotePentax4',
        'MakerNotePentax5',
        'MakerNotePentax6',
        'MakerNotePhaseOne',
        'MakerNoteReconyx',
        'MakerNoteRicoh',
        'MakerNoteRicohText',
        'MakerNoteSamsung1a',
        'MakerNoteSamsung1b',
        'MakerNoteSamsung2',
        'MakerNoteSanyo',
        'MakerNoteSanyoC4',
        'MakerNoteSanyoPatch',
        'MakerNoteSigma',
        'MakerNoteSony',
        'MakerNoteSony2',
        'MakerNoteSony3',
        'MakerNoteSony4',
        'MakerNoteSonyEricsson',
        'MakerNoteSonySRF',
        'MakerNoteUnknownText',
        'MakerNoteUnknown',
    ],
    # "unsafe" tags we normally don't copy in JPEG images, defined
    # as a shortcut to use when rebuilding JPEG EXIF from scratch
    Unsafe => [
        'IFD0:YCbCrPositioning',
        'IFD0:YCbCrCoefficients',
        'IFD0:TransferFunction',
        'ExifIFD:ComponentsConfiguration',
        'ExifIFD:CompressedBitsPerPixel',
        'InteropIFD:InteropIndex',
        'InteropIFD:InteropVersion',
        'InteropIFD:RelatedImageWidth',
        'InteropIFD:RelatedImageHeight',
    ],
    # common metadata tags found in IFD0 of TIFF images
    CommonIFD0 => [
        # standard EXIF
        'IFD0:ImageDescription',
        'IFD0:Make',
        'IFD0:Model',
        'IFD0:Software',
        'IFD0:ModifyDate',
        'IFD0:Artist',
        'IFD0:Copyright',
        # other TIFF tags
        'IFD0:Rating', 
        'IFD0:RatingPercent',
        'IFD0:DNGLensInfo',
        'IFD0:PanasonicTitle',
        'IFD0:PanasonicTitle2',
        'IFD0:XPTitle',
        'IFD0:XPComment',
        'IFD0:XPAuthor',
        'IFD0:XPKeywords',
        'IFD0:XPSubject',
    ],
);

sub LoadShortcuts($)
{
    my $shortcuts = shift;
    my $shortcut;
    foreach $shortcut (keys %$shortcuts) {
        my $val = $$shortcuts{$shortcut};
        # also allow simple aliases
        $val = [ $val ] unless ref $val eq 'ARRAY';
        # save the user-defined shortcut or alias
        $Image::ExifTool::Shortcuts::Main{$shortcut} = $val;
    }
}
if (%Image::ExifTool::Shortcuts::UserDefined) {
    LoadShortcuts(\%Image::ExifTool::Shortcuts::UserDefined);
}
if (%Image::ExifTool::UserDefined::Shortcuts) {
    LoadShortcuts(\%Image::ExifTool::UserDefined::Shortcuts);
}


1; # end

__END__

