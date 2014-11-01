
package Image::ExifTool;

use strict;

sub ShiftTime($$$;$);

sub ApplyShift($$$$;$)
{
    my ($self, $func, $shift, $val, $nvHash) = @_;

    # get shift direction from first character in shift string
    my $pre = ($shift =~ s/^(\+|-)//) ? $1 : '+';
    my $dir = ($pre eq '+') ? 1 : -1;
    my $tagInfo = $$nvHash{TagInfo};
    my $tag = $$tagInfo{Name};
    my $shiftOffset;
    if ($$nvHash{ShiftOffset}) {
        $shiftOffset = $$nvHash{ShiftOffset};
    } else {
        $shiftOffset = $$nvHash{ShiftOffset} = { };
    }

    # initialize handler for eval warnings
    local $SIG{'__WARN__'} = \&SetWarning;
    SetWarning(undef);

    # shift is applied to ValueConv value, so we must ValueConv-Shift-ValueConvInv
    my ($type, $err);
    foreach $type ('ValueConv','Shift','ValueConvInv') {
        if ($type eq 'Shift') {
            #### eval ShiftXxx function
            $err = eval "Shift$func(\$val, \$shift, \$dir, \$shiftOffset)";
        } elsif ($$tagInfo{$type}) {
            my $conv = $$tagInfo{$type};
            if (ref $conv eq 'CODE') {
                $val = &$conv($val, $self);
            } else {
                return "Can't handle $type for $tag in ApplyShift()" if ref $$tagInfo{$type};
                #### eval ValueConv/ValueConvInv ($val, $self)
                $val = eval $$tagInfo{$type};
            }
        } else {
            next;
        }
        # handle errors
        $err and return $err;
        $@ and SetWarning($@);
        GetWarning() and return CleanWarning();
    }
    # update value in new value hash
    $nvHash->{Value} = [ $val ];
    return undef;   # success
}

sub CheckShift($$)
{
    my ($type, $shift) = @_;
    my $err;
    if ($type eq 'Time') {
        return "No shift direction" unless $shift =~ s/^(\+|-)//;
        # do a test shift to validate the shift string
        my $testTime = '2005:11:02 09:00:13.25-04:00';
        $err = ShiftTime($testTime, $shift, $1 eq '+' ? 1 : -1);
    } else {
        $err = "Unknown shift type ($type)";
    }
    return $err;
}

sub DaysInMonth($$)
{
    my ($mon, $year) = @_;
    my @days = (31,28,31,30,31,30,31,31,30,31,30,31);
    # adjust to the range [0,11]
    while ($mon < 1)  { $mon += 12; --$year; }
    while ($mon > 12) { $mon -= 12; ++$year; }
    # return standard number of days unless february on a leap year
    return $days[$mon-1] unless $mon == 2 and not $year % 4;
    # leap years don't occur on even centuries except every 400 years
    return 29 if $year % 100 or not $year % 400;
    return 28;
}

sub SplitTime($$;$)
{
    my ($val, $vals, $time) = @_;
    # insert zeros if missing in shift string
    if ($time) {
        $val =~ s/(^|[-+:\s]):/${1}0:/g;
        $val =~ s/:([:\s]|$)/:0$1/g;
    }
    # change dashes to colons in date (for XMP dates)
    if ($val =~ s/^(\d{4})-(\d{2})-(\d{2})/$1:$2:$3/) {
        $val =~ tr/T/ /;    # change 'T' separator to ' '
    }
    # add space before timezone to split it into a separate word
    $val =~ s/(\+|-)/ $1/;
    my @words = split ' ', $val;
    my $err = 1;
    my @v;
    for (;;) {
        my $word = shift @words;
        last unless defined $word;
        # split word into separate numbers (allow decimal points but no signs)
        my @vals = $word =~ /(?=\d|\.\d)\d*(?:\.\d*)?/g or last;
        if ($word =~ /^(\+|-)/) {
            # this is the timezone
            (defined $v[6] or @vals > 2) and $err = 1, last;
            my $sign = ($1 ne '-') ? 1 : -1;
            # apply sign to both minutes and seconds
            $v[6] = $sign * shift(@vals);
            $v[7] = $sign * (shift(@vals) || 0);
        } elsif ((@words and $words[0] =~ /^\d+/) or # there is a time word to follow
            (not $time and $vals[0] =~ /^\d{3}/) or # first value is year (3 or more digits)
            ($time and not defined $$time[3] and not defined $v[0])) # we don't have a time
        {
            # this is a date (must come first)
            (@v or @vals > 3) and $err = 1, last;
            not $time and @vals != 3 and $err = 1, last;
            $v[2] = pop(@vals);     # take day first if only one specified
            $v[1] = pop(@vals) || 0;
            $v[0] = pop(@vals) || 0;
        } else {
            # this is a time (can't come after timezone)
            (defined $v[3] or defined $v[6] or @vals > 3) and $err = 1, last;
            not $time and @vals != 3 and @vals != 2 and $err = 1, last;
            $v[3] = shift(@vals);   # take hour first if only one specified
            $v[4] = shift(@vals) || 0;
            $v[5] = shift(@vals) || 0;
        }
        $err = 0;
    }
    return 0 if $err or not @v;
    if ($time) {
        # zero any required shift entries which aren't yet defined
        $v[0] = $v[1] = $v[2] = 0 if defined $$time[0] and not defined $v[0];
        $v[3] = $v[4] = $v[5] = 0 if defined $$time[3] and not defined $v[3];
        $v[6] = $v[7] = 0 if defined $$time[6] and not defined $v[6];
    }
    @$vals = @v;    # return split time components
    return 1;
}

sub ShiftComponents($$$$$;$)
{
    my ($time, $shift, $dir, $toTime, $dec, $rndPt) = @_;
    # min/max for Y, M, D, h, m, s
    my @min = (    0, 1, 1, 0, 0, 0);
    my @max = (10000,12,28,24,60,60);
    my $i;
    my $c = 0;
    for ($i=0; $i<@$time; ++$i) {
        my $v = ($$time[$i] || 0) + $dir * ($$shift[$i] || 0) + $c;
        # handle fractional values by propagating remainders downwards
        if ($v != int($v) and $i < 5) {
            my $iv = int($v);
            $c = ($v - $iv) * $max[$i+1];
            $v = $iv;
        } else {
            $c = 0;
        }
        $$toTime[$i] = $v;
    }
    # round off seconds to the required number of decimal points
    my $sec = $$toTime[5];
    if (defined $sec and $sec != int($sec)) {
        my $mult = 10 ** $dec;
        my $rndSec = int($sec * $mult + 0.5 * ($sec <=> 0)) / $mult;
        $rndPt and $$rndPt = $sec - $rndSec;
        $$toTime[5] = $rndSec;
    }
    $c = 0;
    for ($i=5; $i>=0; $i--) {
        defined $$time[$i] or $c = 0, next;
        # apply shift and adjust for previous overflow
        my $v = $$toTime[$i] + $c;
        $c = 0; # set carry to zero
        # adjust for over/underflow
        my ($min, $max) = ($min[$i], $max[$i]);
        if ($v < $min) {
            if ($i == 2) {  # 2 = day of month
                do {
                    # add number of days in previous month
                    --$c;
                    my $mon = $$toTime[$i-1] + $c;
                    $v += DaysInMonth($mon, $$toTime[$i-2]);
                } while ($v < 1);
            } else {
                my $fc = ($v - $min) / $max;
                # carry ($c) must be largest integer equal to or less than $fc
                $c = int($fc);
                --$c if $c > $fc;
                $v -= $c * $max;
            }
        } elsif ($v >= $max + $min) {
            if ($i == 2) {
                for (;;) {
                    # test against number of days in current month
                    my $mon = $$toTime[$i-1] + $c;
                    my $days = DaysInMonth($mon, $$toTime[$i-2]);
                    last if $v <= $days;
                    $v -= $days;
                    ++$c;
                    last if $v <= 28;
                }
            } else {
                my $fc = ($v - $max - $min) / $max;
                # carry ($c) must be smallest integer greater than $fc
                $c = int($fc);
                ++$c if $c <= $fc;
                $v -= $c * $max;
            }
        }
        $$toTime[$i] = $v;  # save the new value
    }
    # handle overflows in timezone
    if (defined $$toTime[6]) {
        my $m = $$toTime[6] * 60 + $$toTime[7];
        $m += 0.5 * ($m <=> 0);     # avoid round-off errors
        $$toTime[6] = int($m / 60);
        $$toTime[7] = int($m - $$toTime[6] * 60);
    }
    return undef;   # success
}

sub ShiftNumber($$$;$)
{
    my ($val, $shift, $dir) = @_;
    $_[0] = $val + $shift * $dir;   # return shifted value
    return undef;                   # success!
}

sub ShiftTime($$$;$)
{
    local $_;
    my ($val, $shift, $dir, $shiftOffset) = @_;
    my (@time, @shift, @toTime, $mode, $needShiftOffset, $dec);
    SplitTime($val, \@time) or return "Invalid time string ($val)";
    if (defined $time[0]) {
        $mode = defined $time[3] ? 'DateTime' : 'Date';
    } elsif (defined $time[3]) {
        $mode = 'Time';
    }
    # get number of digits after the seconds decimal point
    if (defined $time[5] and $time[5] =~ /\.(\d+)/) {
        $dec = length($1);
    } else {
        $dec = 0;
    }
    if ($shiftOffset) {
        $needShiftOffset = 1 unless defined $$shiftOffset{$mode};
        $needShiftOffset = 1 if defined $time[6] and not defined $$shiftOffset{Timezone};
    } else {
        $needShiftOffset = 1;
    }
    if ($needShiftOffset) {
        SplitTime($shift, \@shift, \@time) or return "Invalid shift string ($shift)";

        # change 'Z' timezone to '+00:00' only if necessary
        if (@shift > 6 and @time <= 6) {
            $time[6] = $time[7] = 0 if $val =~ s/Z$/\+00:00/;
        }
        my $rndDiff;
        my $err = ShiftComponents(\@time, \@shift, $dir, \@toTime, $dec, \$rndDiff);
        $err and return $err;
        if ($shiftOffset) {
            if (defined $time[0] or defined $time[3]) {
                my @tm1 = (0, 0, 0, 1, 0, 2000);
                my @tm2 = (0, 0, 0, 1, 0, 2000);
                if (defined $time[0]) {
                    @tm1[3..5] = reverse @time[0..2];
                    @tm2[3..5] = reverse @toTime[0..2];
                    --$tm1[4]; # month should start from 0
                    --$tm2[4];
                }
                my $diff = 0;
                if (defined $time[3]) {
                    @tm1[0..2] = reverse @time[3..5];
                    @tm2[0..2] = reverse @toTime[3..5];
                    # handle fractional seconds separately
                    $diff = $tm2[0] - int($tm2[0]) - ($tm1[0] - int($tm1[0]));
                    $diff += $rndDiff if defined $rndDiff;  # un-do rounding
                    $tm1[0] = int($tm1[0]);
                    $tm2[0] = int($tm2[0]);
                }
                eval q{
                    require Time::Local;
                    $diff += Time::Local::timegm(@tm2) - Time::Local::timegm(@tm1);
                };
                # not a problem if we failed here since we'll just try again next time,
                # so don't return error message
                unless (@$) {
                    my $mode;
                    if (defined $time[0]) {
                        $mode = defined $time[3] ? 'DateTime' : 'Date';
                    } else {
                        $mode = 'Time';
                    }
                    $$shiftOffset{$mode} = $diff;
                }
            }
            if (defined $time[6]) {
                $$shiftOffset{Timezone} = ($toTime[6] - $time[6]) * 60 +
                                           $toTime[7] - $time[7];
            }
        }

    } else {
        if ($$shiftOffset{Timezone} and @time <= 6) {
            # change 'Z' timezone to '+00:00' only if necessary
            $time[6] = $time[7] = 0 if $val =~ s/Z$/\+00:00/;
        }
        # apply the previous date/time shift if necessary
        if ($mode) {
            my @tm = (0, 0, 0, 1, 0, 2000);
            if (defined $time[0]) {
                @tm[3..5] = reverse @time[0..2];
                --$tm[4]; # month should start from 0
            }
            @tm[0..2] = reverse @time[3..5] if defined $time[3];
            # save fractional seconds
            my $frac = $tm[0] - int($tm[0]);
            $tm[0] = int($tm[0]);
            my $tm;
            eval q{
                require Time::Local;
                $tm = Time::Local::timegm(@tm) + $frac;
            };
            $@ and return CleanWarning($@);
            $tm += $$shiftOffset{$mode};    # apply the shift
            $tm < 0 and return 'Shift results in negative time';
            # save fractional seconds in shifted time
            $frac = $tm - int($tm);
            if ($frac) {
                $tm = int($tm);
                # must account for any rounding that could occur
                $frac + 0.5 * 10 ** (-$dec) >= 1 and ++$tm, $frac = 0;
            }
            @tm = gmtime($tm);
            @toTime = reverse @tm[0..5];
            $toTime[0] += 1900;
            ++$toTime[1];
            $toTime[5] += $frac;    # add the fractional seconds back in
        }
        # apply the previous timezone shift if necessary
        if (defined $time[6]) {
            my $m = $time[6] * 60 + $time[7];
            $m += $$shiftOffset{Timezone};
            $m += 0.5 * ($m <=> 0);     # avoid round-off errors
            $toTime[6] = int($m / 60);
            $toTime[7] = int($m - $toTime[6] * 60);
        }
    }
    my ($i, $err);
    for ($i=0; $i<@toTime; ++$i) {
        next unless defined $time[$i] and defined $toTime[$i];
        my ($v, $d, $s);
        if ($i != 6) {  # not timezone hours
            last unless $val =~ /((?=\d|\.\d)\d*(\.\d*)?)/g;
            next if $toTime[$i] == $time[$i];
            $v = $1;    # value
            $d = $2;    # decimal part of value
            $s = '';    # no sign
        } else {
            last if $time[$i] == $toTime[$i] and $time[$i+1] == $toTime[$i+1];
            last unless $val =~ /((?:\+|-)(?=\d|\.\d)\d*(\.\d*)?)/g;
            $v = $1;
            $d = $2;
            if ($toTime[6] >= 0 and $toTime[7] >= 0) {
                $s = '+';
            } else {
                $s = '-';
                $toTime[6] = -$toTime[6];
                $toTime[7] = -$toTime[7];
            }
        }
        my $nv = $toTime[$i];
        my $pos = pos $val;
        my $len = length $v;
        my $sig = $len - length $s;
        my $dec = $d ? length($d) - 1 : 0;
        my $newNum = sprintf($dec ? "$s%0$sig.${dec}f" : "$s%0${sig}d", $nv);
        length($newNum) != $len and $err = 1;
        substr($val, $pos - $len, $len) = $newNum;
        pos($val) = $pos;
    }
    $err and return "Error packing shifted time ($val)";
    $_[0] = $val;   # return shifted value
    return undef;   # success!
}


1; # end

__END__

