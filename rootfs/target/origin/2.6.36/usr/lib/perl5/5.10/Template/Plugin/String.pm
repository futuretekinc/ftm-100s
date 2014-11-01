
package Template::Plugin::String;

use strict;
use warnings;
use base 'Template::Plugin';
use Template::Exception;

use overload q|""| => "text",
             fallback => 1;

our $VERSION = 2.40;
our $ERROR   = '';

*centre  = \*center;
*append  = \*push;
*prepend = \*unshift; 


sub new {
    my ($class, @args) = @_;
    my $context = ref $class ? undef : shift(@args);
    my $config = @args && ref $args[-1] eq 'HASH' ? pop(@args) : { };

    $class = ref($class) || $class;

    my $text = defined $config->{ text } 
        ? $config->{ text }
        : (@args ? shift(@args) : '');

    
    my $self = bless {
        text     => $text,
        filters  => [ ],
        _CONTEXT => $context,
    }, $class;

    my $filter = $config->{ filter } || $config->{ filters };

    # install any output filters specified as 'filter' or 'filters' option
    $self->output_filter($filter)
        if $filter;

    return $self;
}


sub text {
    my $self = shift;
    return $self->{ text } unless @{ $self->{ filters } };

    my $text = $self->{ text };
    my $context = $self->{ _CONTEXT };

    foreach my $dispatch (@{ $self->{ filters } }) {
        my ($name, $args) = @$dispatch;
        my $code = $context->filter($name, $args)
            || $self->throw($context->error());
        $text = &$code($text);
    }
    return $text;
}


sub copy {
    my $self = shift;
    $self->new($self->{ text });
}


sub throw {
    my $self = shift;

    die (Template::Exception->new('String', join('', @_)));
}



sub output_filter {
    my ($self, $filter) = @_;
    my ($name, $args, $dispatch);
    my $filters = $self->{ filters };
    my $count = 0;

    if (ref $filter eq 'HASH') {
        $filter = [ %$filter ];
    }
    elsif (ref $filter ne 'ARRAY') {
        $filter = [ split(/\s*\W+\s*/, $filter) ];
    }

    while (@$filter) {
        $name = shift @$filter;

        # args may follow as a reference (or empty string, e.g. { foo => '' }
        if (@$filter && (ref($filter->[0]) || ! length $filter->[0])) {
            $args = shift @$filter;
            if ($args) {
                $args = [ $args ] unless ref $args eq 'ARRAY';
            }
            else {
                $args = [ ];
            }
        }
        else {
            $args = [ ];
        }


        push(@$filters, [ $name, $args ]);
        $count++;
    }

    return '';
}



sub push {
    my $self = shift;
    $self->{ text } .= join('', @_);
    return $self;
}


sub unshift {
    my $self = shift;
    $self->{ text } = join('', @_) . $self->{ text };
    return $self;
}


sub pop {
    my $self = shift;
    my $strip = shift || return $self;
    $self->{ text } =~ s/$strip$//;
    return $self;
}


sub shift {
    my $self = shift;
    my $strip = shift || return $self;
    $self->{ text } =~ s/^$strip//;
    return $self;
}


sub center {
    my ($self, $width) = @_;
    my $text = $self->{ text };
    my $len = length $text;
    $width ||= 0;

    if ($len < $width) {
        my $lpad = int(($width - $len) / 2);
        my $rpad = $width - $len - $lpad;
        $self->{ text } = (' ' x $lpad) . $self->{ text } . (' ' x $rpad);
    }

    return $self;
}


sub left {
    my ($self, $width) = @_;
    my $len = length $self->{ text };
    $width ||= 0;

    $self->{ text } .= (' ' x ($width - $len))
        if $width > $len;

    return $self;
}


sub right {
    my ($self, $width) = @_;
    my $len = length $self->{ text };
    $width ||= 0;

    $self->{ text } = (' ' x ($width - $len)) . $self->{ text }
        if $width > $len;

    return $self;
}


sub format {
    my ($self, $format) = @_;
    $format = '%s' unless defined $format;
    $self->{ text } = sprintf($format, $self->{ text });
    return $self;
}


sub filter {
    my ($self, $name, @args) = @_;

    my $context = $self->{ _CONTEXT };

    my $code = $context->filter($name, \@args)
        || $self->throw($context->error());
    return &$code($self->{ text });
}



sub upper {
    my $self = CORE::shift;
    $self->{ text } = uc $self->{ text };
    return $self;
}


sub lower {
    my $self = CORE::shift;
    $self->{ text } = lc $self->{ text };
    return $self;    
}


sub capital {
    my $self = CORE::shift;
    $self->{ text } =~ s/^(.)/\U$1/;
    return $self;    
}


sub chop {
    my $self = CORE::shift;
    chop $self->{ text };
    return $self;
}


sub chomp {
    my $self = CORE::shift;
    chomp $self->{ text };
    return $self;
}


sub trim {
    my $self = CORE::shift;
    for ($self->{ text }) {
        s/^\s+//; 
        s/\s+$//; 
    }
    return $self;    
}


sub collapse {
    my $self = CORE::shift;
    for ($self->{ text }) {
        s/^\s+//; 
        s/\s+$//; 
        s/\s+/ /g 
    }
    return $self;    

}


sub length {
    my $self = CORE::shift;
    return length $self->{ text };
}


sub truncate {
    my ($self, $length, $suffix) = @_;
    return $self unless defined $length;
    $suffix ||= '';
    return $self if CORE::length $self->{ text } <= $length;
    $self->{ text } = CORE::substr($self->{ text }, 0, 
                             $length - CORE::length($suffix)) . $suffix;
    return $self;
}


sub substr {
    my ($self, $offset, $length, $replacement) = @_;
    $offset ||= 0;

    if(defined $length) {
        if (defined $replacement) {
            my $removed = CORE::substr( $self->{text}, $offset, $length );
            CORE::substr( $self->{text}, $offset, $length ) = $replacement;
            return $removed;
        }
        else {
            return CORE::substr( $self->{text}, $offset, $length );
        }
    } 
    else {
        return CORE::substr( $self->{text}, $offset );
    }
}


sub repeat {
    my ($self, $n) = @_;
    return $self unless defined $n;
    $self->{ text } = $self->{ text } x $n;
    return $self;
}


sub replace {
    my ($self, $search, $replace) = @_;
    return $self unless defined $search;
    $replace = '' unless defined $replace;
    $self->{ text } =~ s/$search/$replace/g;
    return $self;
}


sub remove {
    my ($self, $search) = @_;
    $search = '' unless defined $search;
    $self->{ text } =~ s/$search//g;
    return $self;
}


sub split {
    my $self  = CORE::shift;
    my $split = CORE::shift;
    my $limit = CORE::shift || 0;
    $split = '\s+' unless defined $split;
    return [ split($split, $self->{ text }, $limit) ];
}


sub search {
    my ($self, $pattern) = @_;
    return $self->{ text } =~ /$pattern/;
}


sub equals {
    my ($self, $comparison) = @_;
    return $self->{ text } eq $comparison;
}


1;

__END__


