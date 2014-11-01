package Filter::Simple;

use Text::Balanced ':ALL';

use vars qw{ $VERSION @EXPORT };

$VERSION = '0.82';

use Filter::Util::Call;
use Carp;

@EXPORT = qw( FILTER FILTER_ONLY );


sub import {
    if (@_>1) { shift; goto &FILTER }
    else      { *{caller()."::$_"} = \&$_ foreach @EXPORT }
}

sub fail {
    croak "FILTER_ONLY: ", @_;
}

my $exql = sub {
    my @bits = extract_quotelike $_[0], qr//;
    return unless $bits[0];
    return \@bits;
};

my $ncws = qr/\s+/;
my $comment = qr/(?<![\$\@%])#.*/;
my $ws = qr/(?:$ncws|$comment)+/;
my $id = qr/\b(?!([ysm]|q[rqxw]?|tr)\b)\w+/;
my $EOP = qr/\n\n|\Z/;
my $CUT = qr/\n=cut.*$EOP/;
my $pod_or_DATA = qr/
              ^=(?:head[1-4]|item) .*? $CUT
            | ^=pod .*? $CUT
            | ^=for .*? $EOP
            | ^=begin \s* (\S+) .*? \n=end \s* \1 .*? $EOP
            | ^__(DATA|END)__\r?\n.*
            /smx;

my %extractor_for = (
    quotelike  => [ $ws,  \&extract_variable, $id, { MATCH  => \&extract_quotelike } ],
    regex      => [ $ws,  $pod_or_DATA, $id, $exql           ],
    string     => [ $ws,  $pod_or_DATA, $id, $exql           ],
    code       => [ $ws, { DONT_MATCH => $pod_or_DATA },
    		        \&extract_variable,
                    $id, { DONT_MATCH => \&extract_quotelike }   ],
    code_no_comments
               => [ { DONT_MATCH => $comment },
                    $ncws, { DONT_MATCH => $pod_or_DATA },
    		        \&extract_variable,
                    $id, { DONT_MATCH => \&extract_quotelike }   ],
    executable => [ $ws, { DONT_MATCH => $pod_or_DATA }      ],
    executable_no_comments
               => [ { DONT_MATCH => $comment },
                    $ncws, { DONT_MATCH => $pod_or_DATA }      ],
    all        => [        { MATCH  => qr/(?s:.*)/         } ],
);

my %selector_for = (
    all   => sub { my ($t)=@_; sub{ $_=$$_; $t->(@_); $_} },
    executable=> sub { my ($t)=@_; sub{ref() ? $_=$$_ : $t->(@_); $_} }, 
    quotelike => sub { my ($t)=@_; sub{ref() && do{$_=$$_; $t->(@_)}; $_} },
    regex     => sub { my ($t)=@_;
               sub{ref() or return $_;
                   my ($ql,undef,$pre,$op,$ld,$pat) = @$_;
                   return $_->[0] unless $op =~ /^(qr|m|s)/
                         || !$op && ($ld eq '/' || $ld eq '?');
                   $_ = $pat;
                   $t->(@_);
                   $ql =~ s/^(\s*\Q$op\E\s*\Q$ld\E)\Q$pat\E/$1$_/;
                   return "$pre$ql";
                  };
            },
    string     => sub { my ($t)=@_;
               sub{ref() or return $_;
                   local *args = \@_;
                   my ($pre,$op,$ld1,$str1,$rd1,$ld2,$str2,$rd2,$flg) = @{$_}[2..10];
                   return $_->[0] if $op =~ /^(qr|m)/
                         || !$op && ($ld1 eq '/' || $ld1 eq '?');
                   if (!$op || $op eq 'tr' || $op eq 'y') {
                       local *_ = \$str1;
                       $t->(@args);
                   }
                   if ($op =~ /^(tr|y|s)/) {
                       local *_ = \$str2;
                       $t->(@args);
                   }
                   my $result = "$pre$op$ld1$str1$rd1";
                   $result .= $ld2 if $ld1 =~ m/[[({<]/; #])}>
                   $result .= "$str2$rd2$flg";
                   return $result;
                  };
              },
);


sub gen_std_filter_for {
    my ($type, $transform) = @_;
    return sub {
        my $instr;
        local @components;
		for (extract_multiple($_,$extractor_for{$type})) {
            if (ref())     { push @components, $_; $instr=0 }
            elsif ($instr) { $components[-1] .= $_ }
            else           { push @components, $_; $instr=1 }
        }
        if ($type =~ /^code/) {
            my $count = 0;
            local $placeholder = qr/\Q$;\E(\C{4})\Q$;\E/;
            my $extractor =      qr/\Q$;\E(\C{4})\Q$;\E/;
            $_ = join "",
                  map { ref $_ ? $;.pack('N',$count++).$; : $_ }
                      @components;
            @components = grep { ref $_ } @components;
            $transform->(@_);
            s/$extractor/${$components[unpack('N',$1)]}/g;
        }
        else {
            my $selector = $selector_for{$type}->($transform);
            $_ = join "", map $selector->(@_), @components;
        }
    }
};

sub FILTER (&;$) {
    my $caller = caller;
    my ($filter, $terminator) = @_;
    no warnings 'redefine';
    *{"${caller}::import"} = gen_filter_import($caller,$filter,$terminator);
    *{"${caller}::unimport"} = gen_filter_unimport($caller);
}

sub FILTER_ONLY {
    my $caller = caller;
    while (@_ > 1) {
        my ($what, $how) = splice(@_, 0, 2);
        fail "Unknown selector: $what"
            unless exists $extractor_for{$what};
        fail "Filter for $what is not a subroutine reference"
            unless ref $how eq 'CODE';
        push @transforms, gen_std_filter_for($what,$how);
    }
    my $terminator = shift;

    my $multitransform = sub {
        foreach my $transform ( @transforms ) {
            $transform->(@_);
        }
    };
    no warnings 'redefine';
    *{"${caller}::import"} =
        gen_filter_import($caller,$multitransform,$terminator);
    *{"${caller}::unimport"} = gen_filter_unimport($caller);
}

my $ows    = qr/(?:[ \t]+|#[^\n]*)*/;

sub gen_filter_import {
    my ($class, $filter, $terminator) = @_;
    my %terminator;
    my $prev_import = *{$class."::import"}{CODE};
    return sub {
        my ($imported_class, @args) = @_;
        my $def_terminator =
            qr/^(?:\s*no\s+$imported_class\s*;$ows|__(?:END|DATA)__)\r?$/;
        if (!defined $terminator) {
            $terminator{terminator} = $def_terminator;
        }
        elsif (!ref $terminator || ref $terminator eq 'Regexp') {
            $terminator{terminator} = $terminator;
        }
        elsif (ref $terminator ne 'HASH') {
            croak "Terminator must be specified as scalar or hash ref"
        }
        elsif (!exists $terminator->{terminator}) {
            $terminator{terminator} = $def_terminator;
        }
        filter_add(
            sub {
                my ($status, $lastline);
                my $count = 0;
                my $data = "";
                while ($status = filter_read()) {
                    return $status if $status < 0;
                    if ($terminator{terminator} &&
                        m/$terminator{terminator}/) {
                        $lastline = $_;
                        last;
                    }
                    $data .= $_;
                    $count++;
                    $_ = "";
                }
                return $count if not $count;
                $_ = $data;
                $filter->($imported_class, @args) unless $status < 0;
                if (defined $lastline) {
                    if (defined $terminator{becomes}) {
                        $_ .= $terminator{becomes};
                    }
                    elsif ($lastline =~ $def_terminator) {
                        $_ .= $lastline;
                    }
                }
                return $count;
            }
        );
        if ($prev_import) {
            goto &$prev_import;
        }
        elsif ($class->isa('Exporter')) {
            $class->export_to_level(1,@_);
        }
    }
}

sub gen_filter_unimport {
    my ($class) = @_;
    return sub {
        filter_del();
        goto &$prev_unimport if $prev_unimport;
    }
}

1;

__END__

