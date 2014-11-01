package B::Terse;

our $VERSION = '1.05';

use strict;
use B qw(class @specialsv_name);
use B::Concise qw(concise_subref set_style_standard);
use Carp;

sub terse {
    my ($order, $subref) = @_;
    set_style_standard("terse");
    if ($order eq "exec") {
	concise_subref('exec', $subref);
    } else {
	concise_subref('basic', $subref);
    }
}

sub compile {
    my @args = @_;
    my $order = @args ? shift(@args) : "";
    $order = "-exec" if $order eq "exec";
    unshift @args, $order if $order ne "";
    B::Concise::compile("-terse", @args);
}

sub indent {
    my ($level) = @_ ? shift : 0;
    return "    " x $level;
}

sub B::OP::terse {
    carp "B::OP::terse is deprecated; use B::Concise instead";
    B::Concise::b_terse(@_);
}

sub B::SV::terse {
    my($sv, $level) = (@_, 0);
    my %info;
    B::Concise::concise_sv($sv, \%info);
    my $s = indent($level)
	. B::Concise::fmt_line(\%info, $sv,
				 "#svclass~(?((#svaddr))?)~#svval", 0);
    chomp $s;
    print "$s\n" unless defined wantarray;
    $s;
}

sub B::NULL::terse {
    my ($sv, $level) = (@_, 0);
    my $s = indent($level) . sprintf "%s (0x%lx)", class($sv), $$sv;
    print "$s\n" unless defined wantarray;
    $s;
}

sub B::SPECIAL::terse {
    my ($sv, $level) = (@_, 0);
    my $s = indent($level)
	. sprintf( "%s #%d %s", class($sv), $$sv, $specialsv_name[$$sv]);
    print "$s\n" unless defined wantarray;
    $s;
}

1;

__END__

