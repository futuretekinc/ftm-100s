
package Image::ExifTool::InDesign;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);

$VERSION = '1.02';

my %indMap = (
    XMP => 'IND',
);

my $masterPageGUID    = "\x06\x06\xed\xf5\xd8\x1d\x46\xe5\xbd\x31\xef\xe7\xfe\x74\xb7\x1d";
my $objectHeaderGUID  = "\xde\x39\x39\x79\x51\x88\x4b\x6c\x8E\x63\xee\xf8\xae\xe0\xdd\x38";
my $objectTrailerGUID = "\xfd\xce\xdb\x70\xf7\x86\x4b\x4f\xa4\xd3\xc7\x28\xb3\x41\x71\x06";

sub ProcessIND($$)
{
    my ($exifTool, $dirInfo) = @_;
    my $raf = $$dirInfo{RAF};
    my $outfile = $$dirInfo{OutFile};
    my ($hdr, $buff, $buf2, $err, $writeLen, $foundXMP);

    # validate the InDesign file
    return 0 unless $raf->Read($hdr, 16) == 16;
    return 0 unless $hdr eq $masterPageGUID;
    return 0 unless $raf->Read($buff, 8) == 8;
    $exifTool->SetFileType($buff eq 'DOCUMENT' ? 'INDD' : 'IND');   # set the FileType tag

    # read the master pages
    $raf->Seek(0, 0) or $err = 'Seek error', goto DONE;
    unless ($raf->Read($buff, 4096) == 4096 and
            $raf->Read($buf2, 4096) == 4096)
    {
        $err = 'Unexpected end of file';
        goto DONE; # (goto's can be our friend)
    }
    SetByteOrder('II');
    unless ($buf2 =~ /^\Q$masterPageGUID/) {
        $err = 'Second master page is invalid';
        goto DONE;
    }
    my $seq1 = Get64u(\$buff, 264);
    my $seq2 = Get64u(\$buf2, 264);
    # take the most current master page
    my $curPage = $seq2 > $seq1 ? \$buf2 : \$buff;
    # byte order of stream data may be different than headers
    my $streamInt32u = Get8u($curPage, 24);
    if ($streamInt32u == 1) {
        $streamInt32u = 'V'; # little-endian int32u
    } elsif ($streamInt32u == 2) {
        $streamInt32u = 'N'; # big-endian int32u
    } else {
        $err = 'Invalid stream byte order';
        goto DONE;
    }
    my $pages = Get32u($curPage, 280);
    $pages < 2 and $err = 'Invalid page count', goto DONE;
    my $pos = $pages * 4096;
    if ($pos > 0x7fffffff and not $exifTool->Options('LargeFileSupport')) {
        $err = 'InDesign files larger than 2 GB not supported (LargeFileSupport not set)';
        goto DONE;
    }
    if ($outfile) {
        # make XMP the preferred group for writing
        $exifTool->InitWriteDirs(\%indMap, 'XMP');

        Write($outfile, $buff, $buf2) or $err = 1, goto DONE;
        my $result = Image::ExifTool::CopyBlock($raf, $outfile, $pos - 8192);
        unless ($result) {
            $err = defined $result ? 'Error reading InDesign database' : 1;
            goto DONE;
        }
        $writeLen = 0;
    } else {
        $raf->Seek($pos, 0) or $err = 'Seek error', goto DONE;
    }
    # scan through the contiguous objects for XMP
    my $verbose = $exifTool->Options('Verbose');
    my $out = $exifTool->Options('TextOut');
    for (;;) {
        $raf->Read($hdr, 32) or last;
        unless (length($hdr) == 32 and $hdr =~ /^\Q$objectHeaderGUID/) {
            # this must be null padding or we have an error
            $hdr =~ /^\0+$/ or $err = 'Corrupt file or unsupported InDesign version';
            last;
        }
        my $len = Get32u(\$hdr, 24);
        if ($verbose) {
            printf $out "Contiguous object at offset 0x%x (%d bytes):\n", $raf->Tell(), $len;
            if ($verbose > 2) {
                my %parms = (Addr => $raf->Tell());
                $parms{MaxLen} = $verbose > 3 ? 1024 : 96 if $verbose < 5;
                $raf->Seek(-$raf->Read($buff, $len), 1) or $err = 1;
                Image::ExifTool::HexDump(\$buff, undef, %parms);
            }
        }
        # check for XMP if stream data is long enough
        # (56 bytes is just enough for XMP header)
        if ($len > 56) {
            $raf->Read($buff, 56) == 56 or $err = 'Unexpected end of file', last;
            if ($buff =~ /^(....)<\?xpacket begin=(['"])\xef\xbb\xbf\2 id=(['"])W5M0MpCehiHzreSzNTczkc9d\3/s) {
                my $lenWord = $1;   # save length word for writing later
                $len -= 4;          # get length of XMP only
                # load and parse the XMP data
                unless ($raf->Seek(-52, 1) and $raf->Read($buff, $len) == $len) {
                    $err = 'Error reading XMP stream';
                    last;
                }
                $foundXMP = 1;
                my %dirInfo = (
                    DataPt  => \$buff,
                    Parent  => 'IND',
                    NoDelete => 1, # do not allow this to be deleted when writing
                );
                my $tagTablePtr = GetTagTable('Image::ExifTool::XMP::Main');
                if ($outfile) {
                    # validate xmp data length (should be same as length in header - 4)
                    my $xmpLen = unpack($streamInt32u, $lenWord);
                    unless ($xmpLen == $len) {
                        $err = "Incorrect XMP stream length ($xmpLen should be $len)";
                        last;
                    }
                    # make sure that XMP is writable
                    my $classID = Get32u(\$hdr, 20);
                    $classID & 0x40000000 or $err = 'XMP stream is not writable', last;
                    my $xmp = $exifTool->WriteDirectory(\%dirInfo, $tagTablePtr);
                    if ($xmp and length $xmp) {
                        # write new xmp with leading length word
                        $buff = pack($streamInt32u, length $xmp) . $xmp;
                        # update header with new length and invalid checksum
                        Set32u(length($buff), \$hdr, 24);
                        Set32u(0xffffffff, \$hdr, 28);
                    } else {
                        $$exifTool{CHANGED} = 0;    # didn't change anything
                        $exifTool->Warn("Can't delete XMP as a block from InDesign file") if defined $xmp;
                        # put length word back at start of stream
                        $buff = $lenWord . $buff;
                    }
                } else {
                    $exifTool->ProcessDirectory(\%dirInfo, $tagTablePtr);
                }
                $len = 0;   # we got the full stream (nothing left to read)
            } else {
                $len -= 56; # we got 56 bytes of the stream
            }
        } else {
            $buff = '';     # must reset this for writing later
        }
        if ($outfile) {
            # write object header and data
            Write($outfile, $hdr, $buff) or $err = 1, last;
            my $result = Image::ExifTool::CopyBlock($raf, $outfile, $len);
            unless ($result) {
                $err = defined $result ? 'Truncated stream data' : 1;
                last;
            }
            $writeLen += 32 + length($buff) + $len;
        } elsif ($len) {
            # skip over remaining stream data
            $raf->Seek($len, 1) or $err = 'Seek error', last;
        }
        $raf->Read($buff, 32) == 32 or $err = 'Unexpected end of file', last;
        unless ($buff =~ /^\Q$objectTrailerGUID/) {
            $err = 'Invalid object trailer';
            last;
        }
        if ($outfile) {
            # make sure object UID and ClassID are the same in the trailer
            substr($hdr,16,8) eq substr($buff,16,8) or $err = 'Non-matching object trailer', last;
            # write object trailer
            Write($outfile, $objectTrailerGUID, substr($hdr,16)) or $err = 1, last;
            $writeLen += 32;
        }
    }
    if ($outfile) {
        # write null padding if necessary
        # (InDesign files must be an even number of 4096-byte blocks)
        my $part = $writeLen % 4096;
        Write($outfile, "\0" x (4096 - $part)) or $err = 1 if $part;
    }
DONE:
    if (not $err) {
        $exifTool->Warn('No XMP stream to edit') if $outfile and not $foundXMP;
        return 1;       # success!
    } elsif (not $outfile) {
        # issue warning on read error
        $exifTool->Warn($err) unless $err eq '1';
    } elsif ($err ne '1') {
        # set error and return success code
        $exifTool->Error($err);
    } else {
        return -1;      # write error
    }
    return 1;
}

1;  # end

__END__


