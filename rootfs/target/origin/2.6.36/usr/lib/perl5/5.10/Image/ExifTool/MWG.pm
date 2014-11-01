
package Image::ExifTool::MWG;

use strict;
use vars qw($VERSION);
use Image::ExifTool qw(:DataAccess :Utils);
use Image::ExifTool::Exif;

$VERSION = '1.09';

$Image::ExifTool::MWG::strict = 1 unless defined $Image::ExifTool::MWG::strict;

sub RecoverTruncatedIPTC($$$);
sub ListToString($);
sub StringToList($$);
sub OverwriteStringList($$$$);

%Image::ExifTool::MWG::Composite = (
    GROUPS => { 0 => 'Composite', 1 => 'MWG', 2 => 'Image' },
    VARS => { NO_ID => 1 },
    NOTES => q{
        The Metadata Working Group (MWG) recommendations provide a set of rules to
        allow certain overlapping EXIF, IPTC and XMP tags to be reconciled when
        reading, and synchronized when writing.  The ExifTool MWG module is designed
        to aid in the implementation of these recommendations.  (See
        L<http://www.metadataworkinggroup.org/> for the complete MWG technical
        specifications.)

        The table below lists special Composite tags which are used to access other
        tags based on the MWG 2.0 recommendations.  These tags are only accessible
        when the MWG module is loaded.  The MWG module is loaded automatically by
        the exiftool application if MWG is specified as a group for any tag on the
        command line, or manually with the C<-use MWG> option.  Via the API, the MWG
        module is loaded with "C<use Image::ExifTool::MWG>".

        When reading, the value of each MWG tag is B<Derived From> the specified
        tags based on the MWG guidelines.  When writing, the appropriate associated
        tags are written.  The value of the IPTCDigest tag is updated automatically
        when the IPTC is changed if either the IPTCDigest tag didn't exist
        beforehand or its value agreed with the original IPTC digest (indicating
        that the XMP is synchronized with the IPTC).  IPTC information is written
        only if the original file contained IPTC.

        Loading the MWG module activates "strict MWG conformance mode", which has
        the effect of causing EXIF, IPTC and XMP in non-standard locations to be
        ignored when reading, as per the MWG recommendations.  Instead, a "Warning"
        tag is generated when non-standard metadata is encountered.  This feature
        may be disabled by setting C<$Image::ExifTool::MWG::strict = 0> in the
        ExifTool config file (or from your Perl script when using the API).  Note
        that the behaviour when writing is not changed:  ExifTool always creates new
        records only in the standard location, but writes new tags to any
        EXIF/IPTC/XMP records that exist.

        A complication of the specification is that although the MWG:Creator
        property may consist of multiple values, the associated EXIF tag
        (EXIF:Artist) is only a simple string.  To resolve this discrepancy the MWG
        recommends a technique which allows a list of values to be stored in a
        string by using a semicolon-space separator (with quotes around values if
        necessary).  When the MWG module is loaded, ExifTool automatically
        implements this policy and changes EXIF:Artist to a list-type tag.
    },
    Keywords => {
        Flags  => ['Writable','List'],
        Desire => {
            0 => 'IPTC:Keywords', # (64-character limit)
            1 => 'XMP-dc:Subject',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 64);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            # only write Keywords if IPTC exists (ie. set EditGroup option)
            'IPTC:Keywords'  => '$opts{EditGroup} = 1; $val',
            'XMP-dc:Subject' => '$val',
        },
    },
    Description => {
        Writable => 1,
        Desire => {
            0 => 'EXIF:ImageDescription',
            1 => 'IPTC:Caption-Abstract', # (2000-character limit)
            2 => 'XMP-dc:Description',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[0] if defined $val[0] and $val[0] !~ /^ *$/;
            return $val[2] if not defined $val[3] or (defined $val[2] and
                             (not defined $val[4] or $val[3] eq $val[4]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[1], $val[2], 2000);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:ImageDescription' => '$val',
            'IPTC:Caption-Abstract' => '$opts{EditGroup} = 1; $val',
            'XMP-dc:Description'    => '$val',
        },
    },
    DateTimeOriginal => {
        Description => 'Date/Time Original',
        Groups => { 2 => 'Time' },
        Notes => '"creation date of the intellectual content being shown" - MWG',
        Writable => 1,
        Desire => {
            0 => 'EXIF:DateTimeOriginal',
            1 => 'EXIF:SubSecTimeOriginal',
            2 => 'IPTC:DateCreated',
            3 => 'IPTC:TimeCreated',
            4 => 'XMP-photoshop:DateCreated',
            5 => 'CurrentIPTCDigest',
            6 => 'IPTCDigest',
        },
        ValueConv => q{
            if (defined $val[0] and $val[0] !~ /^[: ]*$/) {
                return ($val[1] and $val[1] !~ /^ *$/) ? "$val[0].$val[1]" : $val[0];
            }
            return $val[4] if not defined $val[5] or (defined $val[4] and
                             (not defined $val[6] or $val[5] eq $val[6]));
            return $val[3] ? "$val[2] $val[3]" : $val[2] if $val[2];
            return undef;
        },
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,undef,1)',
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            # set EXIF date/time values according to PrintConv option instead
            # of defaulting to Type=ValueConv to allow reformatting to be applied
            'EXIF:DateTimeOriginal'     => 'delete $opts{Type}; $val',
            'EXIF:SubSecTimeOriginal'   => 'delete $opts{Type}; $val',
            'IPTC:DateCreated'          => '$opts{EditGroup} = 1; $val',
            'IPTC:TimeCreated'          => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:DateCreated' => '$val',
        },
    },
    CreateDate => {
        Groups => { 2 => 'Time' },
        Notes => '"creation date of the digital representation" - MWG',
        Writable => 1,
        Desire => {
            0 => 'EXIF:CreateDate',
            1 => 'EXIF:SubSecTimeDigitized',
            2 => 'IPTC:DigitalCreationDate',
            3 => 'IPTC:DigitalCreationTime',
            4 => 'XMP-xmp:CreateDate',
            5 => 'CurrentIPTCDigest',
            6 => 'IPTCDigest',
        },
        ValueConv => q{
            if (defined $val[0] and $val[0] !~ /^[: ]*$/) {
                return ($val[1] and $val[1] !~ /^ *$/) ? "$val[0].$val[1]" : $val[0];
            }
            return $val[4] if not defined $val[5] or (defined $val[4] and
                             (not defined $val[6] or $val[5] eq $val[6]));
            return $val[3] ? "$val[2] $val[3]" : $val[2] if $val[2];
            return undef;
        },
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,undef,1)',
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:CreateDate'          => 'delete $opts{Type}; $val',
            'EXIF:SubSecTimeDigitized' => 'delete $opts{Type}; $val',
            'IPTC:DigitalCreationDate' => '$opts{EditGroup} = 1; $val',
            'IPTC:DigitalCreationTime' => '$opts{EditGroup} = 1; $val',
            'XMP-xmp:CreateDate'       => '$val',
        },
    },
    ModifyDate => {
        Groups => { 2 => 'Time' },
        Notes => '"modification date of the digital image file" - MWG',
        Writable => 1,
        Desire => {
            0 => 'EXIF:ModifyDate',
            1 => 'EXIF:SubSecTime',
            2 => 'XMP-xmp:ModifyDate',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        ValueConv => q{
            if (defined $val[0] and $val[0] !~ /^[: ]*$/) {
                return ($val[1] and $val[1] !~ /^ *$/) ? "$val[0].$val[1]" : $val[0];
            }
            return $val[2] if not defined $val[3] or not defined $val[4] or $val[3] eq $val[4];
            return undef;
        },
        PrintConv => '$self->ConvertDateTime($val)',
        PrintConvInv => '$self->InverseDateTime($val,undef,1)',
        # return empty string from check routines so this tag will never be set
        # (only WriteAlso tags are written), the only difference is a -v2 message
        DelCheck   => '""',
        WriteCheck => '""',
        WriteAlso  => {
            'EXIF:ModifyDate'    => 'delete $opts{Type}; $val',
            'EXIF:SubSecTime'    => 'delete $opts{Type}; $val',
            'XMP-xmp:ModifyDate' => '$val',
        },
    },
    Orientation => {
        Writable   => 1,
        Require    => 'EXIF:Orientation',
        ValueConv  => '$val',
        PrintConv  => \%Image::ExifTool::Exif::orientation,
        DelCheck   => '""',
        WriteCheck => '""',
        WriteAlso  => {
            'EXIF:Orientation' => '$val',
        },
    },
    Rating => {
        Writable   => 1,
        Require    => 'XMP-xmp:Rating',
        ValueConv  => '$val',
        DelCheck   => '""',
        WriteCheck => '""',
        WriteAlso  => {
            'XMP-xmp:Rating' => '$val',
        },
    },
    Copyright => {
        Groups => { 2 => 'Author' },
        Writable => 1,
        Desire => {
            0 => 'EXIF:Copyright',
            1 => 'IPTC:CopyrightNotice', # (128-character limit)
            2 => 'XMP-dc:Rights',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[0] if defined $val[0] and $val[0] !~ /^ *$/;
            return $val[2] if not defined $val[3] or (defined $val[2] and
                             (not defined $val[4] or $val[3] eq $val[4]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[1], $val[2], 128);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:Copyright'       => '$val',
            'IPTC:CopyrightNotice' => '$opts{EditGroup} = 1; $val',
            'XMP-dc:Rights'        => '$val',
        },
    },
    Creator => {
        Groups => { 2 => 'Author' },
        Flags  => ['Writable','List'],
        Desire => {
            0 => 'EXIF:Artist',
            1 => 'IPTC:By-line', # (32-character limit)
            2 => 'XMP-dc:Creator',
            3 => 'CurrentIPTCDigest',
            4 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[0] if defined $val[0] and $val[0] !~ /^ *$/;
            return $val[2] if not defined $val[3] or (defined $val[2] and
                             (not defined $val[4] or $val[3] eq $val[4]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[1], $val[2], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'EXIF:Artist'    => '$val',
            'IPTC:By-line'   => '$opts{EditGroup} = 1; $val',
            'XMP-dc:Creator' => '$val',
        },
    },
    Country => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:Country-PrimaryLocationName', # (64-character limit)
            1 => 'XMP-photoshop:Country',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 64);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:Country-PrimaryLocationName' => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:Country'            => '$val',
        },
    },
    State => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:Province-State', # (32-character limit)
            1 => 'XMP-photoshop:State',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:Province-State' => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:State' => '$val',
        },
    },
    City => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:City', # (32-character limit)
            1 => 'XMP-photoshop:City',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:City'          => '$opts{EditGroup} = 1; $val',
            'XMP-photoshop:City' => '$val',
        },
    },
    Location => {
        Groups => { 2 => 'Location' },
        Writable => 1,
        Desire => {
            0 => 'IPTC:Sub-location', # (32-character limit)
            1 => 'XMP-iptcCore:Location',
            2 => 'CurrentIPTCDigest',
            3 => 'IPTCDigest',
        },
        ValueConv => q{
            return $val[1] if not defined $val[2] or (defined $val[1] and
                             (not defined $val[3] or $val[2] eq $val[3]));
            return Image::ExifTool::MWG::RecoverTruncatedIPTC($val[0], $val[1], 32);
        },
        DelCheck   => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteCheck => 'Image::ExifTool::MWG::ReconcileIPTCDigest($self)',
        WriteAlso  => {
            'IPTC:Sub-location'     => '$opts{EditGroup} = 1; $val',
            'XMP-iptcCore:Location' => '$val',
        },
    },
);

unless ($Image::ExifTool::documentOnly) {
    # add our composite tags
    Image::ExifTool::AddCompositeTags('Image::ExifTool::MWG');
    # must also add to lookup so we can write them
    # (since MWG tags aren't in the tag lookup by default)
    Image::ExifTool::AddTagsToLookup(\%Image::ExifTool::MWG::Composite,
                                     'Image::ExifTool::Composite');
}

{
    my $artist = $Image::ExifTool::Exif::Main{0x13b};
    $$artist{List} = 1;
    $$artist{IsOverwriting} = \&OverwriteStringList;
    $$artist{RawConv} = \&StringToList;
}

sub ListToString($)
{
    my $vals = shift;
    foreach (@$vals) {
        # double all quotes in value and quote the value if it begins
        # with a quote or contains a semicolon-space separator
        if (/^"/ or /; /) {
            s/"/""/g;       # double all quotes
            $_ = qq{"$_"};  # quote the value
        }
    }
    return join('; ', @$vals);
}

sub StringToList($$)
{
    my ($str, $exifTool) = @_;
    my (@vals, $inQuotes);
    my @t = split '; ', $str, -1;
    foreach (@t) {
        my $wasQuotes = $inQuotes;
        $inQuotes = 1 if not $inQuotes and s/^"//;
        if ($inQuotes) {
            # remove the last quote and reset the inQuotes flag if
            # the value ended in an odd number of quotes
            $inQuotes = 0 if s/((^|[^"])("")*)"$/$1/;
            s/""/"/g;   # un-double the contained quotes
        }
        if ($wasQuotes) {
            # previous separator was quoted, so concatinate with previous value
            $vals[-1] .= '; ' . $_;
        } else {
            push @vals, $_;
        }
    }
    $exifTool->Warn('Incorrectly quoted MWG string-list value') if $inQuotes;
    return @vals > 1 ? \@vals : $vals[0];
}

sub OverwriteStringList($$$$)
{
    local $_;
    my ($exifTool, $nvHash, $val, $newValuePt) = @_;
    my (@new, $delIndex);
    if ($$nvHash{DelValue} and defined $val) {
        # preserve specified old values
        my $old = StringToList($val, $exifTool);
        my @old = ref $old eq 'ARRAY' ? @$old : $old;
        if (@{$$nvHash{DelValue}}) {
            my %del;
            $del{$_} = 1 foreach @{$$nvHash{DelValue}};
            foreach (@old) {
                $del{$_} or push(@new, $_), next;
                $delIndex or $delIndex = scalar @new;
            }
        } else {
            push @new, @old;
        }
    }
    # add new values (at location of deleted values, if any)
    if ($$nvHash{Value}) {
        if (defined $delIndex) {
            splice @new, $delIndex, 0, @{$$nvHash{Value}};
        } else {
            push @new, @{$$nvHash{Value}};
        }
    }
    if (@new) {
        # convert back to string format
        $$newValuePt = ListToString(\@new);
    } else {
        $$newValuePt = undef;   # delete the tag
    }
    return 1;
}

sub ReconcileIPTCDigest($)
{
    my $exifTool = shift;

    # set new value for IPTCDigest if not done already
    unless ($Image::ExifTool::Photoshop::iptcDigestInfo and
            $exifTool->{NEW_VALUE}{$Image::ExifTool::Photoshop::iptcDigestInfo})
    {
        # write new IPTCDigest only if it doesn't exist or
        # is the same as the digest of the original IPTC
        my @a; # (capture warning messages)
        @a = $exifTool->SetNewValue('Photoshop:IPTCDigest', 'old', Protected => 1, DelValue => 1);
        @a = $exifTool->SetNewValue('Photoshop:IPTCDigest', 'new', Protected => 1);
    }
    return '';
}

sub RecoverTruncatedIPTC($$$)
{
    my ($iptc, $xmp, $limit) = @_;

    return $iptc unless defined $xmp;
    if (ref $iptc) {
        $xmp = [ $xmp ] unless ref $xmp;
        my ($i, @vals);
        for ($i=0; $i<@$iptc; ++$i) {
            push @vals, RecoverTruncatedIPTC($$iptc[$i], $$xmp[$i], $limit);
        }
        return \@vals;
    } elsif (defined $iptc and length $iptc == $limit) {    
        $xmp = $$xmp[0] if ref $xmp;    # take first element of list
        return $xmp if length $xmp > $limit and $iptc eq substr($xmp, 0, $limit);
    }
    return $iptc;
}

1;  # end

__END__

