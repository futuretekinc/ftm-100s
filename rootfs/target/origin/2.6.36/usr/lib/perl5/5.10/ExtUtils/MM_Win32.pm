package ExtUtils::MM_Win32;

use strict;



use ExtUtils::MakeMaker::Config;
use File::Basename;
use File::Spec;
use ExtUtils::MakeMaker qw( neatvalue );

use vars qw(@ISA $VERSION);

require ExtUtils::MM_Any;
require ExtUtils::MM_Unix;
@ISA = qw( ExtUtils::MM_Any ExtUtils::MM_Unix );
$VERSION = '6.42';

$ENV{EMXSHELL} = 'sh'; # to run `commands`

my $BORLAND = 1 if $Config{'cc'} =~ /^bcc/i;
my $GCC     = 1 if $Config{'cc'} =~ /^gcc/i;



sub dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my($funclist) = $attribs{FUNCLIST} || $self->{FUNCLIST} || [];
    my($imports)  = $attribs{IMPORTS} || $self->{IMPORTS} || {};
    my(@m);

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",
     q!	$(PERLRUN) -MExtUtils::Mksymlists \\
     -e "Mksymlists('NAME'=>\"!, $self->{NAME},
     q!\", 'DLBASE' => '!,$self->{DLBASE},
     # The above two lines quoted differently to work around
     # a bug in the 4DOS/4NT command line interpreter.  The visible
     # result of the bug was files named q('extension_name',) *with the
     # single quotes and the comma* in the extension build directories.
     q!', 'DL_FUNCS' => !,neatvalue($funcs),
     q!, 'FUNCLIST' => !,neatvalue($funclist),
     q!, 'IMPORTS' => !,neatvalue($imports),
     q!, 'DL_VARS' => !, neatvalue($vars), q!);"
!);
    }
    join('',@m);
}


sub replace_manpage_separator {
    my($self,$man) = @_;
    $man =~ s,/+,.,g;
    $man;
}



sub maybe_command {
    my($self,$file) = @_;
    my @e = exists($ENV{'PATHEXT'})
          ? split(/;/, $ENV{PATHEXT})
	  : qw(.com .exe .bat .cmd);
    my $e = '';
    for (@e) { $e .= "\Q$_\E|" }
    chop $e;
    # see if file ends in one of the known extensions
    if ($file =~ /($e)$/i) {
	return $file if -e $file;
    }
    else {
	for (@e) {
	    return "$file$_" if -e "$file$_";
	}
    }
    return;
}



sub init_DIRFILESEP {
    my($self) = shift;

    my $make = $self->make;

    # The ^ makes sure its not interpreted as an escape in nmake
    $self->{DIRFILESEP} = $make eq 'nmake' ? '^\\' :
                          $make eq 'dmake' ? '\\\\'
                                           : '\\';
}


sub init_others {
    my ($self) = @_;

    # Used in favor of echo because echo won't strip quotes. :(
    $self->{ECHO}     ||= $self->oneliner('print qq{@ARGV}', ['-l']);
    $self->{ECHO_N}   ||= $self->oneliner('print qq{@ARGV}');

    $self->{TOUCH}    ||= '$(ABSPERLRUN) -MExtUtils::Command -e touch';
    $self->{CHMOD}    ||= '$(ABSPERLRUN) -MExtUtils::Command -e chmod'; 
    $self->{CP}       ||= '$(ABSPERLRUN) -MExtUtils::Command -e cp';
    $self->{RM_F}     ||= '$(ABSPERLRUN) -MExtUtils::Command -e rm_f';
    $self->{RM_RF}    ||= '$(ABSPERLRUN) -MExtUtils::Command -e rm_rf';
    $self->{MV}       ||= '$(ABSPERLRUN) -MExtUtils::Command -e mv';
    $self->{NOOP}     ||= 'rem';
    $self->{TEST_F}   ||= '$(ABSPERLRUN) -MExtUtils::Command -e test_f';
    $self->{DEV_NULL} ||= '> NUL';

    $self->{FIXIN}    ||= $self->{PERL_CORE} ? 
      "\$(PERLRUN) $self->{PERL_SRC}/win32/bin/pl2bat.pl" : 
      'pl2bat.bat';

    $self->{LD}     ||= $Config{ld} || 'link';
    $self->{AR}     ||= $Config{ar} || 'lib';

    $self->SUPER::init_others;

    # Setting SHELL from $Config{sh} can break dmake.  Its ok without it.
    delete $self->{SHELL};

    $self->{LDLOADLIBS} ||= $Config{libs};
    # -Lfoo must come first for Borland, so we put it in LDDLFLAGS
    if ($BORLAND) {
        my $libs = $self->{LDLOADLIBS};
        my $libpath = '';
        while ($libs =~ s/(?:^|\s)(("?)-L.+?\2)(?:\s|$)/ /) {
            $libpath .= ' ' if length $libpath;
            $libpath .= $1;
        }
        $self->{LDLOADLIBS} = $libs;
        $self->{LDDLFLAGS} ||= $Config{lddlflags};
        $self->{LDDLFLAGS} .= " $libpath";
    }

    return 1;
}



sub init_platform {
    my($self) = shift;

    $self->{MM_Win32_VERSION} = $VERSION;
}

sub platform_constants {
    my($self) = shift;
    my $make_frag = '';

    foreach my $macro (qw(MM_Win32_VERSION))
    {
        next unless defined $self->{$macro};
        $make_frag .= "$macro = $self->{$macro}\n";
    }

    return $make_frag;
}



sub special_targets {
    my($self) = @_;

    my $make_frag = $self->SUPER::special_targets;

    $make_frag .= <<'MAKE_FRAG' if $self->make eq 'dmake';
.USESHELL :
MAKE_FRAG

    return $make_frag;
}



sub static_lib {
    my($self) = @_;
    return '' unless $self->has_link_code;

    my(@m);
    push(@m, <<'END');
$(INST_STATIC): $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(RM_RF) $@
END

    # If this extension has its own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push @m, <<'MAKE_FRAG' if $self->{MYEXTLIB};
	$(CP) $(MYEXTLIB) $@
MAKE_FRAG

    push @m,
q{	$(AR) }.($BORLAND ? '$@ $(OBJECT:^"+")'
			  : ($GCC ? '-ru $@ $(OBJECT)'
			          : '-out:$@ $(OBJECT)')).q{
	$(CHMOD) $(PERM_RWX) $@
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)\extralibs.ld
};

    # Old mechanism - still available:
    push @m, <<'MAKE_FRAG' if $self->{PERL_SRC} && $self->{EXTRALIBS};
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" >> $(PERL_SRC)\ext.libs
MAKE_FRAG

    join('', @m);
}



sub dynamic_lib {
    my($self, %attribs) = @_;
    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code;

    my($otherldflags) = $attribs{OTHERLDFLAGS} || ($BORLAND ? 'c0d32.obj': '');
    my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
    my($ldfrom) = '$(LDFROM)';
    my(@m);

    if ($GCC) { 
	my $dllname = $self->{BASEEXT} . "." . $self->{DLEXT};
	$dllname =~ /(....)(.{0,4})/;
	my $baseaddr = unpack("n", $1 ^ $2);
	$otherldflags .= sprintf("-Wl,--image-base,0x%x0000 ", $baseaddr);
    }

    push(@m,'
OTHERLDFLAGS = '.$otherldflags.'
INST_DYNAMIC_DEP = '.$inst_dynamic_dep.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)$(DFSEP).exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(INST_DYNAMIC_DEP)
');
    if ($GCC) {
      push(@m,  
       q{	dlltool --def $(EXPORT_LIST) --output-exp dll.exp
	$(LD) -o $@ -Wl,--base-file -Wl,dll.base $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) dll.exp
	dlltool --def $(EXPORT_LIST) --base-file dll.base --output-exp dll.exp
	$(LD) -o $@ $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) $(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) dll.exp });
    } elsif ($BORLAND) {
      push(@m,
       q{	$(LD) $(LDDLFLAGS) $(OTHERLDFLAGS) }.$ldfrom.q{,$@,,}
       .($self->make eq 'dmake' 
                ? q{$(PERL_ARCHIVE:s,/,\,) $(LDLOADLIBS:s,/,\,) }
		 .q{$(MYEXTLIB:s,/,\,),$(EXPORT_LIST:s,/,\,)}
		: q{$(subst /,\,$(PERL_ARCHIVE)) $(subst /,\,$(LDLOADLIBS)) }
		 .q{$(subst /,\,$(MYEXTLIB)),$(subst /,\,$(EXPORT_LIST))})
       .q{,$(RESFILES)});
    } else {	# VC
      push(@m,
       q{	$(LD) -out:$@ $(LDDLFLAGS) }.$ldfrom.q{ $(OTHERLDFLAGS) }
      .q{$(MYEXTLIB) $(PERL_ARCHIVE) $(LDLOADLIBS) -def:$(EXPORT_LIST)});

      # VS2005 (aka VC 8) or higher, but not for 64-bit compiler from Platform SDK
      if ($Config{ivsize} == 4 && $Config{cc} eq 'cl' and $Config{ccversion} =~ /^(\d+)/ and $1 >= 14) 
    {
        push(@m,
          q{
	mt -nologo -manifest $@.manifest -outputresource:$@;2 && del $@.manifest});
      }
    }
    push @m, '
	$(CHMOD) $(PERM_RWX) $@
';

    join('',@m);
}


sub extra_clean_files {
    my $self = shift;

    return $GCC ? (qw(dll.base dll.exp)) : ('*.pdb');
}


sub init_linker {
    my $self = shift;

    $self->{PERL_ARCHIVE}       = "\$(PERL_INC)\\$Config{libperl}";
    $self->{PERL_ARCHIVE_AFTER} = '';
    $self->{EXPORT_LIST}        = '$(BASEEXT).def';
}



sub perl_script {
    my($self,$file) = @_;
    return $file if -r $file && -f _;
    return "$file.pl"  if -r "$file.pl" && -f _;
    return "$file.plx" if -r "$file.plx" && -f _;
    return "$file.bat" if -r "$file.bat" && -f _;
    return;
}



sub xs_o {
    return ''
}



sub pasthru {
    my($self) = shift;
    return "PASTHRU = " . ($self->make eq 'nmake' ? "-nologo" : "");
}



sub oneliner {
    my($self, $cmd, $switches) = @_;
    $switches = [] unless defined $switches;

    # Strip leading and trailing newlines
    $cmd =~ s{^\n+}{};
    $cmd =~ s{\n+$}{};

    $cmd = $self->quote_literal($cmd);
    $cmd = $self->escape_newlines($cmd);

    $switches = join ' ', @$switches;

    return qq{\$(ABSPERLRUN) $switches -e $cmd --};
}


sub quote_literal {
    my($self, $text) = @_;

    # I don't know if this is correct, but it seems to work on
    # Win98's command.com
    $text =~ s{"}{\\"}g;

    # dmake eats '{' inside double quotes and leaves alone { outside double
    # quotes; however it transforms {{ into { either inside and outside double
    # quotes.  It also translates }} into }.  The escaping below is not
    # 100% correct.
    if( $self->make eq 'dmake' ) {
        $text =~ s/{/{{/g;
        $text =~ s/}}/}}}/g;
    }

    return qq{"$text"};
}


sub escape_newlines {
    my($self, $text) = @_;

    # Escape newlines
    $text =~ s{\n}{\\\n}g;

    return $text;
}



sub cd {
    my($self, $dir, @cmds) = @_;

    return $self->SUPER::cd($dir, @cmds) unless $self->make eq 'nmake';

    my $cmd = join "\n\t", map "$_", @cmds;

    my $updirs = $self->catdir(map { $self->updir } $self->splitdir($dir));

    # No leading tab and no trailing newline makes for easier embedding.
    my $make_frag = sprintf <<'MAKE_FRAG', $dir, $cmd, $updirs;
cd %s
	%s
	cd %s
MAKE_FRAG

    chomp $make_frag;

    return $make_frag;
}



sub max_exec_len {
    my $self = shift;

    return $self->{_MAX_EXEC_LEN} ||= 2 * 1024;
}



sub os_flavor {
    return('Win32');
}



sub cflags {
    my($self,$libperl)=@_;
    return $self->{CFLAGS} if $self->{CFLAGS};
    return '' unless $self->needs_linking();

    my $base = $self->SUPER::cflags($libperl);
    foreach (split /\n/, $base) {
        /^(\S*)\s*=\s*(\S*)$/ and $self->{$1} = $2;
    };
    $self->{CCFLAGS} .= " -DPERLDLL" if ($self->{LINKTYPE} eq 'static');

    return $self->{CFLAGS} = qq{
CCFLAGS = $self->{CCFLAGS}
OPTIMIZE = $self->{OPTIMIZE}
PERLTYPE = $self->{PERLTYPE}
};

}

1;
__END__



