package B::Xref;

our $VERSION = '1.01';


use strict;
use Config;
use B qw(peekop class comppadlist main_start svref_2object walksymtable
         OPpLVAL_INTRO SVf_POK OPpOUR_INTRO cstring
        );

sub UNKNOWN { ["?", "?", "?"] }

my @pad;			# lexicals in current pad
				# as ["(lexical)", type, name]
my %done;			# keyed by $$op: set when each $op is done
my $top = UNKNOWN;		# shadows top element of stack as
				# [pack, type, name] (pack can be "(lexical)")
my $file;			# shadows current filename
my $line;			# shadows current line number
my $subname;			# shadows current sub name
my %table;			# Multi-level hash to record all uses etc.
my @todo = ();			# List of CVs that need processing

my %code = (intro => "i", used => "",
	    subdef => "s", subused => "&",
	    formdef => "f", meth => "->");


my ($debug_op, $debug_top, $nodefs, $raw);

sub process {
    my ($var, $event) = @_;
    my ($pack, $type, $name) = @$var;
    if ($type eq "*") {
	if ($event eq "used") {
	    return;
	} elsif ($event eq "subused") {
	    $type = "&";
	}
    }
    $type =~ s/(.)\*$/$1/g;
    if ($raw) {
	printf "%-16s %-12s %5d %-12s %4s %-16s %s\n",
	    $file, $subname, $line, $pack, $type, $name, $event;
    } else {
	# Wheee
	push(@{$table{$file}->{$subname}->{$pack}->{$type.$name}->{$event}},
	    $line);
    }
}

sub load_pad {
    my $padlist = shift;
    my ($namelistav, $vallistav, @namelist, $ix);
    @pad = ();
    return if class($padlist) eq "SPECIAL";
    ($namelistav,$vallistav) = $padlist->ARRAY;
    @namelist = $namelistav->ARRAY;
    for ($ix = 1; $ix < @namelist; $ix++) {
	my $namesv = $namelist[$ix];
	next if class($namesv) eq "SPECIAL";
	my ($type, $name) = $namesv->PV =~ /^(.)([^\0]*)(\0.*)?$/;
	$pad[$ix] = ["(lexical)", $type || '?', $name || '?'];
    }
    if ($Config{useithreads}) {
	my (@vallist);
	@vallist = $vallistav->ARRAY;
	for ($ix = 1; $ix < @vallist; $ix++) {
	    my $valsv = $vallist[$ix];
	    next unless class($valsv) eq "GV";
	    # these pad GVs don't have corresponding names, so same @pad
	    # array can be used without collisions
	    $pad[$ix] = [$valsv->STASH->NAME, "*", $valsv->NAME];
	}
    }
}

sub xref {
    my $start = shift;
    my $op;
    for ($op = $start; $$op; $op = $op->next) {
	last if $done{$$op}++;
	warn sprintf("top = [%s, %s, %s]\n", @$top) if $debug_top;
	warn peekop($op), "\n" if $debug_op;
	my $opname = $op->name;
	if ($opname =~ /^(or|and|mapwhile|grepwhile|range|cond_expr)$/) {
	    xref($op->other);
	} elsif ($opname eq "match" || $opname eq "subst") {
	    xref($op->pmreplstart);
	} elsif ($opname eq "substcont") {
	    xref($op->other->pmreplstart);
	    $op = $op->other;
	    redo;
	} elsif ($opname eq "enterloop") {
	    xref($op->redoop);
	    xref($op->nextop);
	    xref($op->lastop);
	} elsif ($opname eq "subst") {
	    xref($op->pmreplstart);
	} else {
	    no strict 'refs';
	    my $ppname = "pp_$opname";
	    &$ppname($op) if defined(&$ppname);
	}
    }
}

sub xref_cv {
    my $cv = shift;
    my $pack = $cv->GV->STASH->NAME;
    $subname = ($pack eq "main" ? "" : "$pack\::") . $cv->GV->NAME;
    load_pad($cv->PADLIST);
    xref($cv->START);
    $subname = "(main)";
}

sub xref_object {
    my $cvref = shift;
    xref_cv(svref_2object($cvref));
}

sub xref_main {
    $subname = "(main)";
    load_pad(comppadlist);
    xref(main_start);
    while (@todo) {
	xref_cv(shift @todo);
    }
}

sub pp_nextstate {
    my $op = shift;
    $file = $op->file;
    $line = $op->line;
    $top = UNKNOWN;
}

sub pp_padsv {
    my $op = shift;
    $top = $pad[$op->targ];
    process($top, $op->private & OPpLVAL_INTRO ? "intro" : "used");
}

sub pp_padav { pp_padsv(@_) }
sub pp_padhv { pp_padsv(@_) }

sub deref {
    my ($op, $var, $as) = @_;
    $var->[1] = $as . $var->[1];
    process($var, $op->private & OPpOUR_INTRO ? "intro" : "used");
}

sub pp_rv2cv { deref(shift, $top, "&"); }
sub pp_rv2hv { deref(shift, $top, "%"); }
sub pp_rv2sv { deref(shift, $top, "\$"); }
sub pp_rv2av { deref(shift, $top, "\@"); }
sub pp_rv2gv { deref(shift, $top, "*"); }

sub pp_gvsv {
    my $op = shift;
    my $gv;
    if ($Config{useithreads}) {
	$top = $pad[$op->padix];
	$top = UNKNOWN unless $top;
	$top->[1] = '$';
    }
    else {
	$gv = $op->gv;
	$top = [$gv->STASH->NAME, '$', $gv->SAFENAME];
    }
    process($top, $op->private & OPpLVAL_INTRO ||
                  $op->private & OPpOUR_INTRO   ? "intro" : "used");
}

sub pp_gv {
    my $op = shift;
    my $gv;
    if ($Config{useithreads}) {
	$top = $pad[$op->padix];
	$top = UNKNOWN unless $top;
	$top->[1] = '*';
    }
    else {
	$gv = $op->gv;
	$top = [$gv->STASH->NAME, "*", $gv->SAFENAME];
    }
    process($top, $op->private & OPpLVAL_INTRO ? "intro" : "used");
}

sub pp_const {
    my $op = shift;
    my $sv = $op->sv;
    # constant could be in the pad (under useithreads)
    if ($$sv) {
	$top = ["?", "",
		(class($sv) ne "SPECIAL" && $sv->FLAGS & SVf_POK)
		? cstring($sv->PV) : "?"];
    }
    else {
	$top = $pad[$op->targ];
	$top = UNKNOWN unless $top;
    }
}

sub pp_method {
    my $op = shift;
    $top = ["(method)", "->".$top->[1], $top->[2]];
}

sub pp_entersub {
    my $op = shift;
    if ($top->[1] eq "m") {
	process($top, "meth");
    } else {
	process($top, "subused");
    }
    $top = UNKNOWN;
}


sub B::GV::xref {
    my $gv = shift;
    my $cv = $gv->CV;
    if ($$cv) {
	#return if $done{$$cv}++;
	$file = $gv->FILE;
	$line = $gv->LINE;
	process([$gv->STASH->NAME, "&", $gv->NAME], "subdef");
	push(@todo, $cv);
    }
    my $form = $gv->FORM;
    if ($$form) {
	return if $done{$$form}++;
	$file = $gv->FILE;
	$line = $gv->LINE;
	process([$gv->STASH->NAME, "", $gv->NAME], "formdef");
    }
}

sub xref_definitions {
    my ($pack, %exclude);
    return if $nodefs;
    $subname = "(definitions)";
    foreach $pack (qw(B O AutoLoader DynaLoader XSLoader Config DB VMS
		      strict vars FileHandle Exporter Carp PerlIO::Layer
		      attributes utf8 warnings)) {
        $exclude{$pack."::"} = 1;
    }
    no strict qw(vars refs);
    walksymtable(\%{"main::"}, "xref", sub { !defined($exclude{$_[0]}) });
}

sub output {
    return if $raw;
    my ($file, $subname, $pack, $name, $ev, $perfile, $persubname,
	$perpack, $pername, $perev);
    foreach $file (sort(keys(%table))) {
	$perfile = $table{$file};
	print "File $file\n";
	foreach $subname (sort(keys(%$perfile))) {
	    $persubname = $perfile->{$subname};
	    print "  Subroutine $subname\n";
	    foreach $pack (sort(keys(%$persubname))) {
		$perpack = $persubname->{$pack};
		print "    Package $pack\n";
		foreach $name (sort(keys(%$perpack))) {
		    $pername = $perpack->{$name};
		    my @lines;
		    foreach $ev (qw(intro formdef subdef meth subused used)) {
			$perev = $pername->{$ev};
			if (defined($perev) && @$perev) {
			    my $code = $code{$ev};
			    push(@lines, map("$code$_", @$perev));
			}
		    }
		    printf "      %-16s  %s\n", $name, join(", ", @lines);
		}
	    }
	}
    }
}

sub compile {
    my @options = @_;
    my ($option, $opt, $arg);
  OPTION:
    while ($option = shift @options) {
	if ($option =~ /^-(.)(.*)/) {
	    $opt = $1;
	    $arg = $2;
	} else {
	    unshift @options, $option;
	    last OPTION;
	}
	if ($opt eq "-" && $arg eq "-") {
	    shift @options;
	    last OPTION;
	} elsif ($opt eq "o") {
	    $arg ||= shift @options;
	    open(STDOUT, ">$arg") or return "$arg: $!\n";
	} elsif ($opt eq "d") {
	    $nodefs = 1;
	} elsif ($opt eq "r") {
	    $raw = 1;
	} elsif ($opt eq "D") {
            $arg ||= shift @options;
	    foreach $arg (split(//, $arg)) {
		if ($arg eq "o") {
		    B->debug(1);
		} elsif ($arg eq "O") {
		    $debug_op = 1;
		} elsif ($arg eq "t") {
		    $debug_top = 1;
		}
	    }
	}
    }
    if (@options) {
	return sub {
	    my $objname;
	    xref_definitions();
	    foreach $objname (@options) {
		$objname = "main::$objname" unless $objname =~ /::/;
		eval "xref_object(\\&$objname)";
		die "xref_object(\\&$objname) failed: $@" if $@;
	    }
	    output();
	}
    } else {
	return sub {
	    xref_definitions();
	    xref_main();
	    output();
	}
    }
}

1;
