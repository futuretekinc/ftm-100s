
package Image::ExifTool::PPM;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.06';

sub ProcessPPM($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $outfile = $$dirInfo{OutFile};
    my $verbose = $exifTool->Options('Verbose');
    my $out = $exifTool->Options('TextOut');
    my ($buff, $num, $type, %info);
    for (;;) {
        if (defined $buff) {
            # need to read some more data
            my $tmp;
            return 0 unless $raf->Read($tmp, 1024);
            $buff .= $tmp;
        } else {
            return 0 unless $raf->Read($buff, 1024);
        }
        # verify this is a valid PPM file
        return 0 unless $buff =~ /^P([1-6])\s+/g;
        $num = $1;
        # note: may contain comments starting with '#'
        if ($buff =~ /\G#/gc) {
            # must read more if we are in the middle of a comment
            next unless $buff =~ /\G ?(.*\n(#.*\n)*)\s*/g;
            $info{Comment} = $1;
            next if $buff =~ /\G#/gc;
        } else {
            delete $info{Comment};
        }
        next unless $buff =~ /\G(\S+)\s+(\S+)\s/g;
        $info{ImageWidth} = $1;
        $info{ImageHeight} = $2;
        $type = [qw{PPM PBM PGM}]->[$num % 3];
        last if $type eq 'PBM'; # (no MaxVal for PBM images)
        if ($buff =~ /\G\s*#/gc) {
            next unless $buff =~ /\G ?(.*\n(#.*\n)*)\s*/g;
            $info{Comment} = '' unless exists $info{Comment};
            $info{Comment} .= $1;
            next if $buff =~ /\G#/gc;
        }
        next unless $buff =~ /\G(\S+)\s/g;
        $info{MaxVal} = $1;
        last;
    }
    # validate numerical values
    foreach (keys %info) {
        next if $_ eq 'Comment';
        return 0 unless $info{$_} =~ /^\d+$/;
    }
    if (defined $info{Comment}) {
        $info{Comment} =~ s/^# ?//mg;   # remove "# " at the start of each line
        $info{Comment} =~ s/\n$//;      # remove trailing newline
    }
    $exifTool->SetFileType($type);
    my $len = pos($buff);
    if ($outfile) {
        my $nvHash;
        my $newComment = $exifTool->GetNewValues('Comment', \$nvHash);
        my $oldComment = $info{Comment};
        if ($exifTool->IsOverwriting($nvHash, $oldComment)) {
            ++$exifTool->{CHANGED};
            $exifTool->VerboseValue('- Comment', $oldComment) if defined $oldComment;
            $exifTool->VerboseValue('+ Comment', $newComment) if defined $newComment;
        } else {
            $newComment = $oldComment;  # use existing comment
        }
        my $hdr = "P$num\n";
        if (defined $newComment) {
            $newComment =~ s/\n/\n# /g;
            $hdr .= "# $newComment\n";
        }
        $hdr .= "$info{ImageWidth} $info{ImageHeight}\n";
        $hdr .= "$info{MaxVal}\n" if $type ne 'PBM';
        # write header and start of image
        Write($outfile, $hdr, substr($buff, $len)) or return -1;
        # copy over the rest of the image
        while ($raf->Read($buff, 0x10000)) {
            Write($outfile, $buff) or return -1;
        }
        return 1;
    }
    if ($verbose > 2) {
        print $out "$type header ($len bytes):\n";
        Image::ExifTool::HexDump(\$buff, $len, Out => $out);
    }
    my $tag;
    foreach $tag (qw{Comment ImageWidth ImageHeight MaxVal}) {
        $exifTool->FoundTag($tag, $info{$tag}) if defined $info{$tag};
    }
    return 1;
}

1;  # end

__END__


