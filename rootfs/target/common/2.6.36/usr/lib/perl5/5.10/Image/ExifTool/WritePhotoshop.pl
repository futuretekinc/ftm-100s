
package Image::ExifTool::Photoshop;

use strict;

sub SetResourceName($$$)
{
    my ($tagInfo, $name, $valPt) = @_;
    my $setName = $$tagInfo{SetResourceName};
    if (defined $setName) {
        # extract resource name from value
        if ($$valPt =~ m{.*/#(.{0,255})#/$}s) {
            $name = $1;
            # strip name from value
            $$valPt = substr($$valPt, 0, -4 - length($name));
        } elsif ($setName eq '1') {
            return;     # use old name
        } else {
            $name = $setName;
        }
        # convert to padded pascal string
        $name = chr(length $name) . $name;
        $name .= "\0" if length($name) & 0x01;
        $_[1] = $name;  # return new name
    }
}

sub WritePhotoshop($$$)
{
    my ($exifTool, $dirInfo, $tagTablePtr) = @_;
    $exifTool or return 1;    # allow dummy access to autoload this package
    my $dataPt = $$dirInfo{DataPt};
    unless ($dataPt) {
        my $emptyData = '';
        $dataPt = \$emptyData;
    }
    my $start = $$dirInfo{DirStart} || 0;
    my $dirLen = $$dirInfo{DirLen} || (length($$dataPt) - $start);
    my $dirEnd = $start + $dirLen;
    my $newData = '';

    # make a hash of new tag info, keyed on tagID
    my $newTags = $exifTool->GetNewTagInfoHash($tagTablePtr);

    my ($addDirs, $editDirs) = $exifTool->GetAddDirHash($tagTablePtr);

    SetByteOrder('MM');     # Photoshop is always big-endian
    # Format: 0) Type, 4 bytes - '8BIM' (or the rare 'PHUT', 'DCSR' or 'AgHg')
    #         1) TagID,2 bytes
    #         2) Name, pascal string padded to even no. bytes
    #         3) Size, 4 bytes - N
    #         4) Data, N bytes
    my ($pos, $value, $size, $tagInfo, $tagID);
    for ($pos=$start; $pos+8<$dirEnd; $pos+=$size) {
        # each entry must be on same even byte boundary as directory start
        ++$pos if ($pos ^ $start) & 0x01;
        my $type = substr($$dataPt, $pos, 4);
        if ($type !~ /^(8BIM|PHUT|DCSR|AgHg)$/) {
            $exifTool->Error("Bad Photoshop IRB resource");
            undef $newData;
            last;
        }
        $tagID = Get16u($dataPt, $pos + 4);
        # get resource block name (pascal string padded to an even # of bytes)
        my $namelen = 1 + Get8u($dataPt, $pos + 6);
        ++$namelen if $namelen & 0x01;
        if ($pos + $namelen + 10 > $dirEnd) {
            $exifTool->Error("Bad APP13 resource block");
            undef $newData;
            last;
        }
        my $name = substr($$dataPt, $pos + 6, $namelen);
        $size = Get32u($dataPt, $pos + 6 + $namelen);
        $pos += $namelen + 10;
        if ($size + $pos > $dirEnd) {
            $exifTool->Error("Bad APP13 resource data size $size");
            undef $newData;
            last;
        }
        if ($$newTags{$tagID} and $type eq '8BIM') {
            $tagInfo = $$newTags{$tagID};
            delete $$newTags{$tagID};
            my $nvHash = $exifTool->GetNewValueHash($tagInfo);
            # check to see if we are overwriting this tag
            $value = substr($$dataPt, $pos, $size);
            my $isOverwriting = $exifTool->IsOverwriting($nvHash, $value);
            # handle special 'new' and 'old' values for IPTCDigest
            if (not $isOverwriting and $tagInfo eq $iptcDigestInfo) {
                if (grep /^new$/, @{$$nvHash{DelValue}}) {
                    $isOverwriting = 1 if $$exifTool{NewIPTCDigest} and
                                          $$exifTool{NewIPTCDigest} eq $value;
                }
                if (grep /^old$/, @{$$nvHash{DelValue}}) {
                    $isOverwriting = 1 if $$exifTool{OldIPTCDigest} and
                                          $$exifTool{OldIPTCDigest} eq $value;
                }
            }
            if ($isOverwriting) {
                $exifTool->VerboseValue("- Photoshop:$$tagInfo{Name}", $value);
                # handle IPTCDigest specially because we want to write it last
                # so the new IPTC digest will be known
                if ($tagInfo eq $iptcDigestInfo) {
                    $$newTags{$tagID} = $tagInfo;   # add later
                    $value = undef;
                } else {
                    $value = $exifTool->GetNewValues($nvHash);
                }
                ++$exifTool->{CHANGED};
                next unless defined $value;     # next if tag is being deleted
                # set resource name if necessary
                SetResourceName($tagInfo, $name, \$value);
                $exifTool->VerboseValue("+ Photoshop:$$tagInfo{Name}", $value);
            }
        } else {
            if ($type eq '8BIM') {
                $tagInfo = $$editDirs{$tagID};
                unless ($tagInfo) {
                    # process subdirectory anyway if writable (except EXIF to avoid recursion)
                    # --> this allows IPTC to be processed if found here in TIFF images
                    my $tmpInfo = $exifTool->GetTagInfo($tagTablePtr, $tagID);
                    if ($tmpInfo and $$tmpInfo{SubDirectory} and
                        $tmpInfo->{SubDirectory}->{TagTable} ne 'Image::ExifTool::Exif::Main')
                    {
                        my $table = Image::ExifTool::GetTagTable($tmpInfo->{SubDirectory}->{TagTable});
                        $tagInfo = $tmpInfo if $$table{WRITE_PROC};
                    }
                }
            }
            if ($tagInfo) {
                $$addDirs{$tagID} and delete $$addDirs{$tagID};
                my %subdirInfo = (
                    DataPt => $dataPt,
                    DirStart => $pos,
                    DataLen => $dirLen,
                    DirLen => $size,
                    Parent => $$dirInfo{DirName},
                );
                my $subTable = Image::ExifTool::GetTagTable($tagInfo->{SubDirectory}->{TagTable});
                my $writeProc = $tagInfo->{SubDirectory}->{WriteProc};
                my $newValue = $exifTool->WriteDirectory(\%subdirInfo, $subTable, $writeProc);
                if (defined $newValue) {
                    next unless length $newValue;   # remove subdirectory entry
                    $value = $newValue;
                    SetResourceName($tagInfo, $name, \$value);
                } else {
                    $value = substr($$dataPt, $pos, $size); # rewrite old directory
                }
            } else {
                $value = substr($$dataPt, $pos, $size);
            }
        }
        my $newSize = length $value;
        # write this directory entry
        $newData .= $type . Set16u($tagID) . $name . Set32u($newSize) . $value;
        $newData .= "\0" if $newSize & 0x01;    # must null pad to even byte
    }
    my @tagsLeft = sort { $a <=> $b } keys(%$newTags), keys(%$addDirs);
    foreach $tagID (@tagsLeft) {
        my $name = "\0\0";
        if ($$newTags{$tagID}) {
            $tagInfo = $$newTags{$tagID};
            my $nvHash = $exifTool->GetNewValueHash($tagInfo);
            $value = $exifTool->GetNewValues($nvHash);
            # handle new IPTCDigest value specially
            if ($tagInfo eq $iptcDigestInfo and defined $value) {
                if ($value eq 'new') {
                    $value = $$exifTool{NewIPTCDigest};
                } elsif ($value eq 'old') {
                    $value = $$exifTool{OldIPTCDigest};
                }
                # (we already know we want to create this tag)
            } else {
                # don't add this tag unless specified
                next unless Image::ExifTool::IsCreating($nvHash);
            }
            next unless defined $value;     # next if tag is being deleted
            $exifTool->VerboseValue("+ Photoshop:$$tagInfo{Name}", $value);
            ++$exifTool->{CHANGED};
        } else {
            $tagInfo = $$addDirs{$tagID};
            # create new directory
            my %subdirInfo = (
                Parent => $$dirInfo{DirName},
            );
            my $subTable = Image::ExifTool::GetTagTable($tagInfo->{SubDirectory}->{TagTable});
            my $writeProc = $tagInfo->{SubDirectory}->{WriteProc};
            $value = $exifTool->WriteDirectory(\%subdirInfo, $subTable, $writeProc);
            next unless $value;
        }
        # set resource name if necessary
        SetResourceName($tagInfo, $name, \$value);
        $size = length($value);
        # write the new directory entry
        $newData .= '8BIM' . Set16u($tagID) . $name . Set32u($size) . $value;
        $newData .= "\0" if $size & 0x01;   # must null pad to even numbered byte
        ++$exifTool->{CHANGED};
    }
    return $newData;
}


1; # end

__END__

