
package Image::ExifTool::MPC;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::FLAC;

$VERSION = '1.00';

%Image::ExifTool::MPC::Main = (
    PROCESS_PROC => \&Image::ExifTool::FLAC::ProcessBitStream,
    GROUPS => { 2 => 'Audio' },
    NOTES => q{
        Tags used in Musepack (MPC) audio files.  ExifTool also extracts ID3 and APE
        information from these files.
    },
    'Bit032-063' => 'TotalFrames',
    'Bit080-081' => {
        Name => 'SampleRate',
        PrintConv => {
            0 => 44100,
            1 => 48000,
            2 => 37800,
            3 => 32000,
        },
    },
    'Bit084-087' => {
        Name => 'Quality',
        PrintConv => {
             1 => 'Unstable/Experimental',
             5 => '0',
             6 => '1',
             7 => '2 (Telephone)',
             8 => '3 (Thumb)',
             9 => '4 (Radio)',
            10 => '5 (Standard)',
            11 => '6 (Xtreme)',
            12 => '7 (Insane)',
            13 => '8 (BrainDead)',
            14 => '9',
            15 => '10',
       },
    },
    'Bit088-093' => 'MaxBand',
    'Bit096-111' => 'ReplayGainTrackPeak',
    'Bit112-127' => 'ReplayGainTrackGain',
    'Bit128-143' => 'ReplayGainAlbumPeak',
    'Bit144-159' => 'ReplayGainAlbumGain',
    'Bit179' => {
        Name => 'FastSeek',
        PrintConv => { 0 => 'No', 1 => 'Yes' },
    },
    'Bit191' => {
        Name => 'Gapless',
        PrintConv => { 0 => 'No', 1 => 'Yes' },
    },
    'Bit216-223' => {
        Name => 'EncoderVersion',
        PrintConv => '$val =~ s/(\d)(\d)(\d)$/$1.$2.$3/; $val',
    },
);

sub ProcessMPC($$)
{
    my ($exifTool, $dirInfo) = @_;

    # must first check for leading ID3 information
    unless ($exifTool->{DoneID3}) {
        require Image::ExifTool::ID3;
        Image::ExifTool::ID3::ProcessID3($exifTool, $dirInfo) and return 1;
    }
    my $raf = $$dirInfo{RAF};
    my $buff;

    # check MPC signature
    $raf->Read($buff, 32) == 32 and $buff =~ /^MP\+(.)/s or return 0;
    my $vers = ord($1) & 0x0f;
    $exifTool->SetFileType();

    # extract audio information (currently only from version 7 MPC files)
    if ($vers == 0x07) {
        SetByteOrder('II');
        my $pos = $raf->Tell() - 32;
        if ($exifTool->Options('Verbose')) {
            $exifTool->VPrint(0, "MPC Header (32 bytes):\n");
            $exifTool->VerboseDump(\$buff, DataPos => $pos);
        }
        my $tagTablePtr = GetTagTable('Image::ExifTool::MPC::Main');
        my %dirInfo = ( DataPt => \$buff, DataPos => $pos );
        $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
    } else {
        $exifTool->Warn('Audio info not currently extracted from this version MPC file');
    }

    # process APE trailer if it exists
    require Image::ExifTool::APE;
    Image::ExifTool::APE::ProcessAPE($exifTool, $dirInfo);

    return 1;
}

1;  # end

__END__


