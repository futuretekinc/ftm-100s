
package Template::Plugin::Table;

use strict;
use warnings;
use base 'Template::Plugin';
use Scalar::Util 'blessed';

our $VERSION = 2.71;
our $AUTOLOAD;



sub new {
    my ($class, $context, $data, $params) = @_;
    my ($size, $rows, $cols, $coloff, $overlap, $error);

    # if the data item is a reference to a Template::Iterator object,
    # or subclass thereof, we call its get_all() method to extract all
    # the data it contains
    if (blessed($data) && $data->isa('Template::Iterator')) {
        ($data, $error) = $data->get_all();
        return $class->error("iterator failed to provide data for table: ",
                             $error)
            if $error;
    }
        
    return $class->error('invalid table data, expecting a list')
        unless ref $data eq 'ARRAY';

    $params ||= { };
    return $class->error('invalid table parameters, expecting a hash')
        unless ref $params eq 'HASH';

    # ensure keys are folded to upper case
    @$params{ map { uc } keys %$params } = values %$params;

    $size = scalar @$data;
    $overlap = $params->{ OVERLAP } || 0;

    # calculate number of columns based on a specified number of rows
    if ($rows = $params->{ ROWS }) {
        if ($size < $rows) {
            $rows = $size;   # pad?
            $cols = 1;
            $coloff = 0;
        }
        else {
            $coloff = $rows - $overlap;
            $cols = int ($size / $coloff) 
                + ($size % $coloff > $overlap ? 1 : 0)
            }
    }
    # calculate number of rows based on a specified number of columns
    elsif ($cols = $params->{ COLS }) {
        if ($size < $cols) {
            $cols = $size;
            $rows = 1;
            $coloff = 1;
        }
        else {
            $coloff = int ($size / $cols) 
                + ($size % $cols > $overlap ? 1 : 0);
            $rows = $coloff + $overlap;
        }
    }
    else {
        $rows = $size;
        $cols = 1;
        $coloff = 0;
    }
    
    bless {
        _DATA    => $data,
        _SIZE    => $size,
        _NROWS   => $rows,
        _NCOLS   => $cols,
        _COLOFF  => $coloff,
        _OVERLAP => $overlap,
        _PAD     => defined $params->{ PAD } ? $params->{ PAD } : 1,
    }, $class;
}



sub row {
    my ($self, $row) = @_;
    my ($data, $cols, $offset, $size, $pad) 
        = @$self{ qw( _DATA _NCOLS _COLOFF _SIZE _PAD) };
    my @set;

    # return all rows if row number not specified
    return $self->rows()
        unless defined $row;

    return () if $row >= $self->{ _NROWS } || $row < 0;
    
    my $index = $row;

    for (my $c = 0; $c < $cols; $c++) {
        push(@set, $index < $size 
             ? $data->[$index] 
             : ($pad ? undef : ()));
        $index += $offset;
    }
    return \@set;
}



sub col {
    my ($self, $col) = @_;
    my ($data, $size) = @$self{ qw( _DATA _SIZE ) };
    my ($start, $end);
    my $blanks = 0;

    # return all cols if row number not specified
    return $self->cols()
        unless defined $col;

    return () if $col >= $self->{ _NCOLS } || $col < 0;

    $start = $self->{ _COLOFF } * $col;
    $end = $start + $self->{ _NROWS } - 1;
    $end = $start if $end < $start;
    if ($end >= $size) {
        $blanks = ($end - $size) + 1;
        $end = $size - 1;
    }
    return () if $start >= $size;
    return [ @$data[$start..$end], 
             $self->{ _PAD } ? ((undef) x $blanks) : () ];
}



sub rows {
    my $self = shift;
    return [ map { $self->row($_) } (0..$self->{ _NROWS }-1) ];
}



sub cols {
    my $self = shift;
    return [ map { $self->col($_) } (0..$self->{ _NCOLS }-1) ];
}



sub AUTOLOAD {
    my $self = shift;
    my $item = $AUTOLOAD;
    $item =~ s/.*:://;
    return if $item eq 'DESTROY';

    if ($item =~ /^(?:data|size|nrows|ncols|overlap|pad)$/) {
        return $self->{ $item };
    }
    else {
        return (undef, "no such table method: $item");
    }
}



1;

__END__


