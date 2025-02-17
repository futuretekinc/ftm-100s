package ExtUtils::Mksymlists;

use 5.00503;
use strict qw[ subs refs ];

use Carp;
use Exporter;
use Config;

use vars qw(@ISA @EXPORT $VERSION);
@ISA = 'Exporter';
@EXPORT = '&Mksymlists';
$VERSION = '6.42';

sub Mksymlists {
    my(%spec) = @_;
    my($osname) = $^O;

    croak("Insufficient information specified to Mksymlists")
        unless ( $spec{NAME} or
                 ($spec{FILE} and ($spec{DL_FUNCS} or $spec{FUNCLIST})) );

    $spec{DL_VARS} = [] unless $spec{DL_VARS};
    ($spec{FILE} = $spec{NAME}) =~ s/.*::// unless $spec{FILE};
    $spec{FUNCLIST} = [] unless $spec{FUNCLIST};
    $spec{DL_FUNCS} = { $spec{NAME} => [] }
        unless ( ($spec{DL_FUNCS} and keys %{$spec{DL_FUNCS}}) or
                 @{$spec{FUNCLIST}});
    if (defined $spec{DL_FUNCS}) {
        my($package);
        foreach $package (keys %{$spec{DL_FUNCS}}) {
            my($packprefix,$sym,$bootseen);
            ($packprefix = $package) =~ s/\W/_/g;
            foreach $sym (@{$spec{DL_FUNCS}->{$package}}) {
                if ($sym =~ /^boot_/) {
                    push(@{$spec{FUNCLIST}},$sym);
                    $bootseen++;
                }
                else { push(@{$spec{FUNCLIST}},"XS_${packprefix}_$sym"); }
            }
            push(@{$spec{FUNCLIST}},"boot_$packprefix") unless $bootseen;
        }
    }

    if (defined &DynaLoader::mod2fname and not $spec{DLBASE}) {
        $spec{DLBASE} = DynaLoader::mod2fname([ split(/::/,$spec{NAME}) ]);
    }

    if    ($osname eq 'aix') { _write_aix(\%spec); }
    elsif ($osname eq 'MacOS'){ _write_aix(\%spec) }
    elsif ($osname eq 'VMS') { _write_vms(\%spec) }
    elsif ($osname eq 'os2') { _write_os2(\%spec) }
    elsif ($osname eq 'MSWin32') { _write_win32(\%spec) }
    else { croak("Don't know how to create linker option file for $osname\n"); }
}


sub _write_aix {
    my($data) = @_;

    rename "$data->{FILE}.exp", "$data->{FILE}.exp_old";

    open(EXP,">$data->{FILE}.exp")
        or croak("Can't create $data->{FILE}.exp: $!\n");
    print EXP join("\n",@{$data->{DL_VARS}}, "\n") if @{$data->{DL_VARS}};
    print EXP join("\n",@{$data->{FUNCLIST}}, "\n") if @{$data->{FUNCLIST}};
    close EXP;
}


sub _write_os2 {
    my($data) = @_;
    require Config;
    my $threaded = ($Config::Config{archname} =~ /-thread/ ? " threaded" : "");

    if (not $data->{DLBASE}) {
        ($data->{DLBASE} = $data->{NAME}) =~ s/.*:://;
        $data->{DLBASE} = substr($data->{DLBASE},0,7) . '_';
    }
    my $distname = $data->{DISTNAME} || $data->{NAME};
    $distname = "Distribution $distname";
    my $patchlevel = " pl$Config{perl_patchlevel}" || '';
    my $comment = sprintf "Perl (v%s%s%s) module %s", 
      $Config::Config{version}, $threaded, $patchlevel, $data->{NAME};
    chomp $comment;
    if ($data->{INSTALLDIRS} and $data->{INSTALLDIRS} eq 'perl') {
	$distname = 'perl5-porters@perl.org';
	$comment = "Core $comment";
    }
    $comment = "$comment (Perl-config: $Config{config_args})";
    $comment = substr($comment, 0, 200) . "...)" if length $comment > 203;
    rename "$data->{FILE}.def", "$data->{FILE}_def.old";

    open(DEF,">$data->{FILE}.def")
        or croak("Can't create $data->{FILE}.def: $!\n");
    print DEF "LIBRARY '$data->{DLBASE}' INITINSTANCE TERMINSTANCE\n";
    print DEF "DESCRIPTION '\@#$distname:$data->{VERSION}#\@ $comment'\n";
    print DEF "CODE LOADONCALL\n";
    print DEF "DATA LOADONCALL NONSHARED MULTIPLE\n";
    print DEF "EXPORTS\n  ";
    print DEF join("\n  ",@{$data->{DL_VARS}}, "\n") if @{$data->{DL_VARS}};
    print DEF join("\n  ",@{$data->{FUNCLIST}}, "\n") if @{$data->{FUNCLIST}};
    if (%{$data->{IMPORTS}}) {
        print DEF "IMPORTS\n";
	my ($name, $exp);
	while (($name, $exp)= each %{$data->{IMPORTS}}) {
	    print DEF "  $name=$exp\n";
	}
    }
    close DEF;
}

sub _write_win32 {
    my($data) = @_;

    require Config;
    if (not $data->{DLBASE}) {
        ($data->{DLBASE} = $data->{NAME}) =~ s/.*:://;
        $data->{DLBASE} = substr($data->{DLBASE},0,7) . '_';
    }
    rename "$data->{FILE}.def", "$data->{FILE}_def.old";

    open(DEF,">$data->{FILE}.def")
        or croak("Can't create $data->{FILE}.def: $!\n");
    # put library name in quotes (it could be a keyword, like 'Alias')
    if ($Config::Config{'cc'} !~ /^gcc/i) {
      print DEF "LIBRARY \"$data->{DLBASE}\"\n";
    }
    print DEF "EXPORTS\n  ";
    my @syms;
    # Export public symbols both with and without underscores to
    # ensure compatibility between DLLs from different compilers
    # NOTE: DynaLoader itself only uses the names without underscores,
    # so this is only to cover the case when the extension DLL may be
    # linked to directly from C. GSAR 97-07-10
    if ($Config::Config{'cc'} =~ /^bcc/i) {
	for (@{$data->{DL_VARS}}, @{$data->{FUNCLIST}}) {
	    push @syms, "_$_", "$_ = _$_";
	}
    }
    else {
	for (@{$data->{DL_VARS}}, @{$data->{FUNCLIST}}) {
	    push @syms, "$_", "_$_ = $_";
	}
    }
    print DEF join("\n  ",@syms, "\n") if @syms;
    if (%{$data->{IMPORTS}}) {
        print DEF "IMPORTS\n";
        my ($name, $exp);
        while (($name, $exp)= each %{$data->{IMPORTS}}) {
            print DEF "  $name=$exp\n";
        }
    }
    close DEF;
}


sub _write_vms {
    my($data) = @_;

    require Config; # a reminder for once we do $^O
    require ExtUtils::XSSymSet;

    my($isvax) = $Config::Config{'archname'} =~ /VAX/i;
    my($set) = new ExtUtils::XSSymSet;
    my($sym);

    rename "$data->{FILE}.opt", "$data->{FILE}.opt_old";

    open(OPT,">$data->{FILE}.opt")
        or croak("Can't create $data->{FILE}.opt: $!\n");

    # Options file declaring universal symbols
    # Used when linking shareable image for dynamic extension,
    # or when linking PerlShr into which we've added this package
    # as a static extension
    # We don't do anything to preserve order, so we won't relax
    # the GSMATCH criteria for a dynamic extension

    print OPT "case_sensitive=yes\n"
        if $Config::Config{d_vms_case_sensitive_symbols};
    foreach $sym (@{$data->{FUNCLIST}}) {
        my $safe = $set->addsym($sym);
        if ($isvax) { print OPT "UNIVERSAL=$safe\n" }
        else        { print OPT "SYMBOL_VECTOR=($safe=PROCEDURE)\n"; }
    }
    foreach $sym (@{$data->{DL_VARS}}) {
        my $safe = $set->addsym($sym);
        print OPT "PSECT_ATTR=${sym},PIC,OVR,RD,NOEXE,WRT,NOSHR\n";
        if ($isvax) { print OPT "UNIVERSAL=$safe\n" }
        else        { print OPT "SYMBOL_VECTOR=($safe=DATA)\n"; }
    }
    close OPT;

}

1;

__END__

