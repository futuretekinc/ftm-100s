
package Image::ExifTool::Fixup;

use strict;
use Image::ExifTool qw(GetByteOrder SetByteOrder Get32u Get32s Set32u
                       Get16u Get16s Set16u);
use vars qw($VERSION);

$VERSION = '1.04';

sub AddFixup($$;$$);
sub ApplyFixup($$);
sub Dump($;$);

sub new
{
    local $_;
    my $that = shift;
    my $class = ref($that) || $that || 'Image::ExifTool::Fixup';
    my $self = bless {}, $class;

    # initialize required members
    $self->{Start} = 0;
    $self->{Shift} = 0;

    return $self;
}

sub Clone($)
{
    my $self = shift;
    my $clone = new Image::ExifTool::Fixup;
    $clone->{Start} = $self->{Start};
    $clone->{Shift} = $self->{Shift};
    my $phash = $self->{Pointers};
    if ($phash) {
        $clone->{Pointers} = { };
        my $byteOrder;
        foreach $byteOrder (keys %$phash) {
            my @pointers = @{$phash->{$byteOrder}};
            $clone->{Pointers}->{$byteOrder} = \@pointers;
        }
    }
    if ($self->{Fixups}) {
        $clone->{Fixups} = [ ];
        my $subFixup;
        foreach $subFixup (@{$self->{Fixups}}) {
            push @{$clone->{Fixups}}, $subFixup->Clone();
        }
    }
    return $clone;
}

sub AddFixup($$;$$)
{
    my ($self, $pointer, $marker, $format) = @_;
    if (ref $pointer) {
        $self->{Fixups} or $self->{Fixups} = [ ];
        push @{$self->{Fixups}}, $pointer;
    } else {
        my $byteOrder = GetByteOrder();
        if (defined $format) {
            if ($format eq 'int16u') {
                $byteOrder .= '2';
            } elsif ($format ne 'int32u') {
                warn "Bad Fixup pointer format $format\n";
            }
        }
        $byteOrder .= "_$marker" if defined $marker;
        my $phash = $self->{Pointers};
        $phash or $phash = $self->{Pointers} = { };
        $phash->{$byteOrder} or $phash->{$byteOrder} = [ ];
        push @{$phash->{$byteOrder}}, $pointer;
    }
}

sub ApplyFixup($$)
{
    my ($self, $dataPt) = @_;

    my $start = $self->{Start};
    my $shift = $self->{Shift} + $start;   # make shift relative to start
    my $phash = $self->{Pointers};

    # fix up pointers in this fixup
    if ($phash and ($start or $shift)) {
        my $saveOrder = GetByteOrder(); # save original byte ordering
        my ($byteOrder, $ptr);
        foreach $byteOrder (keys %$phash) {
            SetByteOrder(substr($byteOrder,0,2));
            # apply the fixup offset shift (must get as signed integer
            # to avoid overflow in case it was negative before)
            my ($get, $set) = ($byteOrder =~ /^(II2|MM2)/) ?
                              (\&Get16s, \&Set16u) : (\&Get32s, \&Set32u);
            foreach $ptr (@{$phash->{$byteOrder}}) {
                $ptr += $start;         # update pointer to new start location
                next unless $shift;
                &$set(&$get($dataPt, $ptr) + $shift, $dataPt, $ptr);
            }
        }
        SetByteOrder($saveOrder);       # restore original byte ordering
    }
    # recurse into contained fixups
    if ($self->{Fixups}) {
        # create our pointer hash if it doesn't exist
        $phash or $phash = $self->{Pointers} = { };
        # loop through all contained fixups
        my $subFixup;
        foreach $subFixup (@{$self->{Fixups}}) {
            # adjust the subfixup start and shift
            $subFixup->{Start} += $start;
            $subFixup->{Shift} += $shift - $start;
            # recursively apply contained fixups
            ApplyFixup($subFixup, $dataPt);
            my $shash = $subFixup->{Pointers} or next;
            # add all pointers to our collapsed lists
            my $byteOrder;
            foreach $byteOrder (keys %$shash) {
                $phash->{$byteOrder} or $phash->{$byteOrder} = [ ];
                push @{$phash->{$byteOrder}}, @{$shash->{$byteOrder}};
                delete $shash->{$byteOrder};
            }
            delete $subFixup->{Pointers};
        }
        delete $self->{Fixups};    # remove our contained fixups
    }
    # reset our Start/Shift for the collapsed fixup
    $self->{Start} = $self->{Shift} = 0;
}

sub HasMarker($$)
{
    my ($self, $marker) = @_;
    my $phash = $self->{Pointers};
    return 0 unless $phash;
    return 1 if grep /_$marker$/, keys %$phash;
    return 0 unless $self->{Fixups};
    my $subFixup;
    foreach $subFixup (@{$self->{Fixups}}) {
        return 1 if $subFixup->HasMarker($marker);
    }
    return 0;
}

sub SetMarkerPointers($$$$;$)
{
    my ($self, $dataPt, $marker, $value, $startOffset) = @_;
    my $start = $self->{Start} + ($startOffset || 0);
    my $phash = $self->{Pointers};

    if ($phash) {
        my $saveOrder = GetByteOrder(); # save original byte ordering
        my ($byteOrder, $ptr);
        foreach $byteOrder (keys %$phash) {
            next unless $byteOrder =~ /^(II|MM)(2?)_$marker$/;
            SetByteOrder($1);
            my $set = $2 ? \&Set16u : \&Set32u;
            foreach $ptr (@{$phash->{$byteOrder}}) {
                &$set($value, $dataPt, $ptr + $start);
            }
        }
        SetByteOrder($saveOrder);       # restore original byte ordering
    }
    if ($self->{Fixups}) {
        my $subFixup;
        foreach $subFixup (@{$self->{Fixups}}) {
            $subFixup->SetMarkerPointers($dataPt, $marker, $value, $start);
        }
    }
}

sub GetMarkerPointers($$$;$)
{
    my ($self, $dataPt, $marker, $startOffset) = @_;
    my $start = $self->{Start} + ($startOffset || 0);
    my $phash = $self->{Pointers};
    my @pointers;

    if ($phash) {
        my $saveOrder = GetByteOrder();
        my ($byteOrder, $ptr);
        foreach $byteOrder (grep /_$marker$/, keys %$phash) {
            SetByteOrder(substr($byteOrder,0,2));
            my $get = ($byteOrder =~ /^(II2|MM2)/) ? \&Get16u : \&Get32u;
            foreach $ptr (@{$phash->{$byteOrder}}) {
                push @pointers, &$get($dataPt, $ptr + $start);
            }
        }
        SetByteOrder($saveOrder);       # restore original byte ordering
    }
    if ($self->{Fixups}) {
        my $subFixup;
        foreach $subFixup (@{$self->{Fixups}}) {
            push @pointers, $subFixup->GetMarkerPointers($dataPt, $marker, $start);
        }
    }
    return @pointers if wantarray;
    return $pointers[0];
}

sub Dump($;$)
{
    my ($self, $indent) = @_;
    $indent or $indent = '';
    printf "${indent}Fixup start=0x%x shift=0x%x\n", $self->{Start}, $self->{Shift};
    my $phash = $self->{Pointers};
    if ($phash) {
        my $byteOrder;
        foreach $byteOrder (sort keys %$phash) {
            print "$indent  $byteOrder: ", join(' ',@{$phash->{$byteOrder}}),"\n";
        }
    }
    if ($self->{Fixups}) {
        my $subFixup;
        foreach $subFixup (@{$self->{Fixups}}) {
            Dump($subFixup, $indent . '  ');
        }
    }
}


1; # end

__END__

