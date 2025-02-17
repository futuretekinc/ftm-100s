
package File::RandomAccess;

use strict;
require 5.002;
require Exporter;

use vars qw($VERSION @ISA @EXPORT_OK);
$VERSION = '1.10';
@ISA = qw(Exporter);

sub Read($$$);

my $CHUNK_SIZE = 8192;  # size of chunks to read from file (must be power of 2)
my $SLURP_CHUNKS = 16;  # read this many chunks at a time when slurping

sub new($$;$)
{
    my ($that, $filePt, $isRandom) = @_;
    my $class = ref($that) || $that;
    my $self;

    if (ref $filePt eq 'SCALAR') {
        # string i/o
        $self = {
            BUFF_PT => $filePt,
            POS => 0,
            LEN => length($$filePt),
            TESTED => -1,
        };
        bless $self, $class;
    } else {
        # file i/o
        my $buff = '';
        $self = {
            FILE_PT => $filePt, # file pointer
            BUFF_PT => \$buff,  # reference to file data
            POS => 0,           # current position in file
            LEN => 0,           # data length
            TESTED => 0,        # 0=untested, 1=passed, -1=failed (requires buffering)
        };
        bless $self, $class;
        $self->SeekTest() unless $isRandom;
    }
    return $self;
}

sub Debug($)
{
    my $self = shift;
    $self->{DEBUG} = { };
}

sub SeekTest($)
{
    my $self = shift;
    unless ($self->{TESTED}) {
        my $fp = $self->{FILE_PT};
        if (seek($fp, 1, 1) and seek($fp, -1, 1)) {
            $self->{TESTED} = 1;    # test passed
        } else {
            $self->{TESTED} = -1;   # test failed (requires buffering)
        }
    }
    return $self->{TESTED} == 1 ? 1 : 0;
}

sub Tell($)
{
    my $self = shift;
    my $rtnVal;
    if ($self->{TESTED} < 0) {
        $rtnVal = $self->{POS};
    } else {
        $rtnVal = tell($self->{FILE_PT});
    }
    return $rtnVal;
}

sub Seek($$;$)
{
    my ($self, $num, $whence) = @_;
    $whence = 0 unless defined $whence;
    my $rtnVal;
    if ($self->{TESTED} < 0) {
        my $newPos;
        if ($whence == 0) {
            $newPos = $num;                 # from start of file
        } elsif ($whence == 1) {
            $newPos = $num + $self->{POS};  # relative to current position
        } else {
            $self->Slurp();                 # read whole file into buffer
            $newPos = $num + $self->{LEN};  # relative to end of file
        }
        if ($newPos >= 0) {
            $self->{POS} = $newPos;
            $rtnVal = 1;
        }
    } else {
        $rtnVal = seek($self->{FILE_PT}, $num, $whence);
    }
    return $rtnVal;
}

sub Read($$$)
{
    my $self = shift;
    my $len = $_[1];
    my $rtnVal;

    # protect against reading too much at once
    # (also from dying with a "Negative length" error)
    if ($len & 0xf8000000) {
        return 0 if $len < 0;
        # read in smaller blocks because Windows attempts to pre-allocate
        # memory for the full size, which can lead to an out-of-memory error
        my $maxLen = 0x4000000; # (MUST be less than bitmask in "if" above)
        my $num = Read($self, $_[0], $maxLen);
        return $num if $num < $maxLen;
        for (;;) {
            $len -= $maxLen;
            last if $len <= 0;
            my $l = $len < $maxLen ? $len : $maxLen;
            my $buff;
            my $n = Read($self, $buff, $l);
            last unless $n;
            $_[0] .= $buff;
            $num += $n;
            last if $n < $l;
        }
        return $num;
    }
    # read through our buffer if necessary
    if ($self->{TESTED} < 0) {
        my $buff;
        my $newPos = $self->{POS} + $len;
        # number of bytes to read from file
        my $num = $newPos - $self->{LEN};
        if ($num > 0 and $self->{FILE_PT}) {
            # read data from file in multiples of $CHUNK_SIZE
            $num = (($num - 1) | ($CHUNK_SIZE - 1)) + 1;
            $num = read($self->{FILE_PT}, $buff, $num);
            if ($num) {
                ${$self->{BUFF_PT}} .= $buff;
                $self->{LEN} += $num;
            }
        }
        # number of bytes left in data buffer
        $num = $self->{LEN} - $self->{POS};
        if ($len <= $num) {
            $rtnVal = $len;
        } elsif ($num <= 0) {
            $_[0] = '';
            return 0;
        } else {
            $rtnVal = $num;
        }
        # return data from our buffer
        $_[0] = substr(${$self->{BUFF_PT}}, $self->{POS}, $rtnVal);
        $self->{POS} += $rtnVal;
    } else {
        # read directly from file
        $_[0] = '' unless defined $_[0];
        $rtnVal = read($self->{FILE_PT}, $_[0], $len) || 0;
    }
    if ($self->{DEBUG}) {
        my $pos = $self->Tell() - $rtnVal;
        unless ($self->{DEBUG}->{$pos} and $self->{DEBUG}->{$pos} > $rtnVal) {
            $self->{DEBUG}->{$pos} = $rtnVal;
        }
    }
    return $rtnVal;
}

sub ReadLine($$)
{
    my $self = shift;
    my $rtnVal;
    my $fp = $self->{FILE_PT};

    if ($self->{TESTED} < 0) {
        my ($num, $buff);
        my $pos = $self->{POS};
        if ($fp) {
            # make sure we have some data after the current position
            while ($self->{LEN} <= $pos) {
                $num = read($fp, $buff, $CHUNK_SIZE);
                return 0 unless $num;
                ${$self->{BUFF_PT}} .= $buff;
                $self->{LEN} += $num;
            }
            # scan and read until we find the EOL (or hit EOF)
            for (;;) {
                $pos = index(${$self->{BUFF_PT}}, $/, $pos);
                if ($pos >= 0) {
                    $pos += length($/);
                    last;
                }
                $pos = $self->{LEN};    # have scanned to end of buffer
                $num = read($fp, $buff, $CHUNK_SIZE) or last;
                ${$self->{BUFF_PT}} .= $buff;
                $self->{LEN} += $num;
            }
        } else {
            # string i/o
            $pos = index(${$self->{BUFF_PT}}, $/, $pos);
            if ($pos < 0) {
                $pos = $self->{LEN};
                $self->{POS} = $pos if $self->{POS} > $pos;
            } else {
                $pos += length($/);
            }
        }
        # read the line from our buffer
        $rtnVal = $pos - $self->{POS};
        $_[0] = substr(${$self->{BUFF_PT}}, $self->{POS}, $rtnVal);
        $self->{POS} = $pos;
    } else {
        $_[0] = <$fp>;
        if (defined $_[0]) {
            $rtnVal = length($_[0]);
        } else {
            $rtnVal = 0;
        }
    }
    if ($self->{DEBUG}) {
        my $pos = $self->Tell() - $rtnVal;
        unless ($self->{DEBUG}->{$pos} and $self->{DEBUG}->{$pos} > $rtnVal) {
            $self->{DEBUG}->{$pos} = $rtnVal;
        }
    }
    return $rtnVal;
}

sub Slurp($)
{
    my $self = shift;
    my $fp = $self->{FILE_PT} || return;
    # read whole file into buffer (in large chunks)
    my ($buff, $num);
    while (($num = read($fp, $buff, $CHUNK_SIZE * $SLURP_CHUNKS)) != 0) {
        ${$self->{BUFF_PT}} .= $buff;
        $self->{LEN} += $num;
    }
}


sub BinMode($)
{
    my $self = shift;
    binmode($self->{FILE_PT}) if $self->{FILE_PT};
}

sub Close($)
{
    my $self = shift;

    if ($self->{DEBUG}) {
        local $_;
        if ($self->Seek(0,2)) {
            $self->{DEBUG}->{$self->Tell()} = 0;    # set EOF marker
            my $last;
            my $tot = 0;
            my $bad = 0;
            foreach (sort { $a <=> $b } keys %{$self->{DEBUG}}) {
                my $pos = $_;
                my $len = $self->{DEBUG}->{$_};
                if (defined $last and $last < $pos) {
                    my $bytes = $pos - $last;
                    $tot += $bytes;
                    $self->Seek($last);
                    my $buff;
                    $self->Read($buff, $bytes);
                    my $warn = '';
                    if ($buff =~ /[^\0]/) {
                        $bad += ($pos - $last);
                        $warn = ' - NON-ZERO!';
                    }
                    printf "0x%.8x - 0x%.8x (%d bytes)$warn\n", $last, $pos, $bytes;
                }
                my $cur = $pos + $len;
                $last = $cur unless defined $last and $last > $cur;
            }
            print "$tot bytes missed";
            $bad and print ", $bad non-zero!";
            print "\n";
        } else {
            warn "File::RandomAccess DEBUG not working (file already closed?)\n";
        }
        delete $self->{DEBUG};
    }
    # close the file
    if ($self->{FILE_PT}) {
        close($self->{FILE_PT});
        delete $self->{FILE_PT};
    }
    # reset the buffer
    my $emptyBuff = '';
    $self->{BUFF_PT} = \$emptyBuff;
    $self->{LEN} = 0;
    $self->{POS} = 0;
}

1;  # end
