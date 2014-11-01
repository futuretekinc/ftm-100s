package ExtUtils::MM_Unix;

require 5.005_03;  # Maybe further back, dunno

use strict;

use Carp;
use ExtUtils::MakeMaker::Config;
use File::Basename qw(basename dirname);
use DirHandle;

use vars qw($VERSION @ISA
            $Is_OS2 $Is_VMS $Is_Win32 $Is_Dos
            $Is_OSF $Is_IRIX  $Is_NetBSD $Is_BSD
            $Is_SunOS4 $Is_Solaris $Is_SunOS $Is_Interix
            %Config_Override
           );

use ExtUtils::MakeMaker qw($Verbose neatvalue);

$VERSION = '6.42';

require ExtUtils::MM_Any;
@ISA = qw(ExtUtils::MM_Any);

BEGIN { 
    $Is_OS2     = $^O eq 'os2';
    $Is_Win32   = $^O eq 'MSWin32' || $Config{osname} eq 'NetWare';
    $Is_Dos     = $^O eq 'dos';
    $Is_VMS     = $^O eq 'VMS';
    $Is_OSF     = $^O eq 'dec_osf';
    $Is_IRIX    = $^O eq 'irix';
    $Is_NetBSD  = $^O eq 'netbsd';
    $Is_Interix = $^O eq 'interix';
    $Is_SunOS4  = $^O eq 'sunos';
    $Is_Solaris = $^O eq 'solaris';
    $Is_SunOS   = $Is_SunOS4 || $Is_Solaris;
    $Is_BSD     = ($^O =~ /^(?:free|net|open)bsd$/ or
                   grep( $^O eq $_, qw(bsdos interix dragonfly) )
                  );
}

BEGIN {
    if( $Is_VMS ) {
        # For things like vmsify()
        require VMS::Filespec;
        VMS::Filespec->import;
    }
}



my $Curdir  = __PACKAGE__->curdir;
my $Rootdir = __PACKAGE__->rootdir;
my $Updir   = __PACKAGE__->updir;



sub os_flavor {
    return('Unix');
}



sub c_o {

    my($self) = shift;
    return '' unless $self->needs_linking();
    my(@m);
    
    my $command = '$(CCCMD)';
    my $flags   = '$(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE)';
    
    if (my $cpp = $Config{cpprun}) {
        my $cpp_cmd = $self->const_cccmd;
        $cpp_cmd =~ s/^CCCMD\s*=\s*\$\(CC\)/$cpp/;
        push @m, qq{
.c.i:
	$cpp_cmd $flags \$*.c > \$*.i
};
    }

    push @m, qq{
.c.s:
	$command -S $flags \$*.c

.c\$(OBJ_EXT):
	$command $flags \$*.c

.cpp\$(OBJ_EXT):
	$command $flags \$*.cpp

.cxx\$(OBJ_EXT):
	$command $flags \$*.cxx

.cc\$(OBJ_EXT):
	$command $flags \$*.cc
};

    push @m, qq{
.C\$(OBJ_EXT):
	$command \$*.C
} if !$Is_OS2 and !$Is_Win32 and !$Is_Dos; #Case-specific

    return join "", @m;
}


#'

sub cflags {
    my($self,$libperl)=@_;
    return $self->{CFLAGS} if $self->{CFLAGS};
    return '' unless $self->needs_linking();

    my($prog, $uc, $perltype, %cflags);
    $libperl ||= $self->{LIBPERL_A} || "libperl$self->{LIB_EXT}" ;
    $libperl =~ s/\.\$\(A\)$/$self->{LIB_EXT}/;

    @cflags{qw(cc ccflags optimize shellflags)}
	= @Config{qw(cc ccflags optimize shellflags)};
    my($optdebug) = "";

    $cflags{shellflags} ||= '';

    my(%map) =  (
		D =>   '-DDEBUGGING',
		E =>   '-DEMBED',
		DE =>  '-DDEBUGGING -DEMBED',
		M =>   '-DEMBED -DMULTIPLICITY',
		DM =>  '-DDEBUGGING -DEMBED -DMULTIPLICITY',
		);

    if ($libperl =~ /libperl(\w*)\Q$self->{LIB_EXT}/){
	$uc = uc($1);
    } else {
	$uc = ""; # avoid warning
    }
    $perltype = $map{$uc} ? $map{$uc} : "";

    if ($uc =~ /^D/) {
	$optdebug = "-g";
    }


    my($name);
    ( $name = $self->{NAME} . "_cflags" ) =~ s/:/_/g ;
    if ($prog = $Config{$name}) {
	# Expand hints for this extension via the shell
	print STDOUT "Processing $name hint:\n" if $Verbose;
	my(@o)=`cc=\"$cflags{cc}\"
	  ccflags=\"$cflags{ccflags}\"
	  optimize=\"$cflags{optimize}\"
	  perltype=\"$cflags{perltype}\"
	  optdebug=\"$cflags{optdebug}\"
	  eval '$prog'
	  echo cc=\$cc
	  echo ccflags=\$ccflags
	  echo optimize=\$optimize
	  echo perltype=\$perltype
	  echo optdebug=\$optdebug
	  `;
	my($line);
	foreach $line (@o){
	    chomp $line;
	    if ($line =~ /(.*?)=\s*(.*)\s*$/){
		$cflags{$1} = $2;
		print STDOUT "	$1 = $2\n" if $Verbose;
	    } else {
		print STDOUT "Unrecognised result from hint: '$line'\n";
	    }
	}
    }

    if ($optdebug) {
	$cflags{optimize} = $optdebug;
    }

    for (qw(ccflags optimize perltype)) {
        $cflags{$_} ||= '';
	$cflags{$_} =~ s/^\s+//;
	$cflags{$_} =~ s/\s+/ /g;
	$cflags{$_} =~ s/\s+$//;
	$self->{uc $_} ||= $cflags{$_};
    }

    if ($self->{POLLUTE}) {
	$self->{CCFLAGS} .= ' -DPERL_POLLUTE ';
    }

    my $pollute = '';
    if ($Config{usemymalloc} and not $Config{bincompat5005}
	and not $Config{ccflags} =~ /-DPERL_POLLUTE_MALLOC\b/
	and $self->{PERL_MALLOC_OK}) {
	$pollute = '$(PERL_MALLOC_DEF)';
    }

    $self->{CCFLAGS}  = quote_paren($self->{CCFLAGS});
    $self->{OPTIMIZE} = quote_paren($self->{OPTIMIZE});

    return $self->{CFLAGS} = qq{
CCFLAGS = $self->{CCFLAGS}
OPTIMIZE = $self->{OPTIMIZE}
PERLTYPE = $self->{PERLTYPE}
MPOLLUTE = $pollute
};

}



sub const_cccmd {
    my($self,$libperl)=@_;
    return $self->{CONST_CCCMD} if $self->{CONST_CCCMD};
    return '' unless $self->needs_linking();
    return $self->{CONST_CCCMD} =
	q{CCCMD = $(CC) -c $(PASTHRU_INC) $(INC) \\
	$(CCFLAGS) $(OPTIMIZE) \\
	$(PERLTYPE) $(MPOLLUTE) $(DEFINE_VERSION) \\
	$(XS_DEFINE_VERSION)};
}


sub const_config {

    my($self) = shift;
    my(@m,$m);
    push(@m,"\n# These definitions are from config.sh (via $INC{'Config.pm'})\n");
    push(@m,"\n# They may have been overridden via Makefile.PL or on the command line\n");
    my(%once_only);
    foreach $m (@{$self->{CONFIG}}){
	# SITE*EXP macros are defined in &constants; avoid duplicates here
	next if $once_only{$m};
	$self->{uc $m} = quote_paren($self->{uc $m});
	push @m, uc($m) , ' = ' , $self->{uc $m}, "\n";
	$once_only{$m} = 1;
    }
    join('', @m);
}


sub const_loadlibs {
    my($self) = shift;
    return "" unless $self->needs_linking;
    my @m;
    push @m, qq{
};
    my($tmp);
    for $tmp (qw/
	 EXTRALIBS LDLOADLIBS BSLOADLIBS
	 /) {
	next unless defined $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }
    # don't set LD_RUN_PATH if empty
    for $tmp (qw/
	 LD_RUN_PATH
	 /) {
	next unless $self->{$tmp};
	push @m, "$tmp = $self->{$tmp}\n";
    }
    return join "", @m;
}


sub constants {
    my($self) = @_;
    my @m = ();

    $self->{DFSEP} = '$(DIRFILESEP)';  # alias for internal use

    for my $macro (qw(

              AR_STATIC_ARGS DIRFILESEP DFSEP
              NAME NAME_SYM 
              VERSION    VERSION_MACRO    VERSION_SYM DEFINE_VERSION
              XS_VERSION XS_VERSION_MACRO             XS_DEFINE_VERSION
              INST_ARCHLIB INST_SCRIPT INST_BIN INST_LIB
              INST_MAN1DIR INST_MAN3DIR
              MAN1EXT      MAN3EXT
              INSTALLDIRS INSTALL_BASE DESTDIR PREFIX
              PERLPREFIX      SITEPREFIX      VENDORPREFIX
                   ),
                   (map { ("INSTALL".$_,
                          "DESTINSTALL".$_)
                        } $self->installvars),
                   qw(
              PERL_LIB    
              PERL_ARCHLIB
              LIBPERL_A MYEXTLIB
              FIRST_MAKEFILE MAKEFILE_OLD MAKE_APERL_FILE 
              PERLMAINCC PERL_SRC PERL_INC 
              PERL            FULLPERL          ABSPERL
              PERLRUN         FULLPERLRUN       ABSPERLRUN
              PERLRUNINST     FULLPERLRUNINST   ABSPERLRUNINST
              PERL_CORE
              PERM_RW PERM_RWX

	      ) ) 
    {
	next unless defined $self->{$macro};

        # pathnames can have sharp signs in them; escape them so
        # make doesn't think it is a comment-start character.
        $self->{$macro} =~ s/#/\\#/g;
	push @m, "$macro = $self->{$macro}\n";
    }

    push @m, qq{
MAKEMAKER   = $self->{MAKEMAKER}
MM_VERSION  = $self->{MM_VERSION}
MM_REVISION = $self->{MM_REVISION}
};

    push @m, q{
};

    for my $macro (qw/
              MAKE
	      FULLEXT BASEEXT PARENT_NAME DLBASE VERSION_FROM INC DEFINE OBJECT
	      LDFROM LINKTYPE BOOTDEP
	      /	) 
    {
	next unless defined $self->{$macro};
	push @m, "$macro = $self->{$macro}\n";
    }

    push @m, "
XS_FILES = ".$self->wraplist(sort keys %{$self->{XS}})."
C_FILES  = ".$self->wraplist(@{$self->{C}})."
O_FILES  = ".$self->wraplist(@{$self->{O_FILES}})."
H_FILES  = ".$self->wraplist(@{$self->{H}})."
MAN1PODS = ".$self->wraplist(sort keys %{$self->{MAN1PODS}})."
MAN3PODS = ".$self->wraplist(sort keys %{$self->{MAN3PODS}})."
";


    push @m, q{
CONFIGDEP = $(PERL_ARCHLIB)$(DFSEP)Config.pm $(PERL_INC)$(DFSEP)config.h
};


    push @m, qq{
INST_LIBDIR      = $self->{INST_LIBDIR}
INST_ARCHLIBDIR  = $self->{INST_ARCHLIBDIR}

INST_AUTODIR     = $self->{INST_AUTODIR}
INST_ARCHAUTODIR = $self->{INST_ARCHAUTODIR}

INST_STATIC      = $self->{INST_STATIC}
INST_DYNAMIC     = $self->{INST_DYNAMIC}
INST_BOOT        = $self->{INST_BOOT}
};


    push @m, qq{
EXPORT_LIST        = $self->{EXPORT_LIST}
PERL_ARCHIVE       = $self->{PERL_ARCHIVE}
PERL_ARCHIVE_AFTER = $self->{PERL_ARCHIVE_AFTER}
};

    push @m, "

TO_INST_PM = ".$self->wraplist(sort keys %{$self->{PM}})."

PM_TO_BLIB = ".$self->wraplist(%{$self->{PM}})."
";

    join('',@m);
}



sub depend {
    my($self,%attribs) = @_;
    my(@m,$key,$val);
    while (($key,$val) = each %attribs){
	last unless defined $key;
	push @m, "$key : $val\n";
    }
    join "", @m;
}



sub init_DEST {
    my $self = shift;

    # Initialize DESTDIR
    $self->{DESTDIR} ||= '';

    # Make DEST variables.
    foreach my $var ($self->installvars) {
        my $destvar = 'DESTINSTALL'.$var;
        $self->{$destvar} ||= '$(DESTDIR)$(INSTALL'.$var.')';
    }
}



sub init_dist {
    my $self = shift;

    $self->{TAR}      ||= 'tar';
    $self->{TARFLAGS} ||= 'cvf';
    $self->{ZIP}      ||= 'zip';
    $self->{ZIPFLAGS} ||= '-r';
    $self->{COMPRESS} ||= 'gzip --best';
    $self->{SUFFIX}   ||= '.gz';
    $self->{SHAR}     ||= 'shar';
    $self->{PREOP}    ||= '$(NOECHO) $(NOOP)'; # eg update MANIFEST
    $self->{POSTOP}   ||= '$(NOECHO) $(NOOP)'; # eg remove the distdir
    $self->{TO_UNIX}  ||= '$(NOECHO) $(NOOP)';

    $self->{CI}       ||= 'ci -u';
    $self->{RCS_LABEL}||= 'rcs -Nv$(VERSION_SYM): -q';
    $self->{DIST_CP}  ||= 'best';
    $self->{DIST_DEFAULT} ||= 'tardist';

    ($self->{DISTNAME} = $self->{NAME}) =~ s{::}{-}g unless $self->{DISTNAME};
    $self->{DISTVNAME} ||= $self->{DISTNAME}.'-'.$self->{VERSION};

}


sub dist {
    my($self, %attribs) = @_;

    my $make = '';
    foreach my $key (qw( 
            TAR TARFLAGS ZIP ZIPFLAGS COMPRESS SUFFIX SHAR
            PREOP POSTOP TO_UNIX
            CI RCS_LABEL DIST_CP DIST_DEFAULT
            DISTNAME DISTVNAME
           ))
    {
        my $value = $attribs{$key} || $self->{$key};
        $make .= "$key = $value\n";
    }

    return $make;
}


sub dist_basics {
    my($self) = shift;

    return <<'MAKE_FRAG';
distclean :: realclean distcheck
	$(NOECHO) $(NOOP)

distcheck :
	$(PERLRUN) "-MExtUtils::Manifest=fullcheck" -e fullcheck

skipcheck :
	$(PERLRUN) "-MExtUtils::Manifest=skipcheck" -e skipcheck

manifest :
	$(PERLRUN) "-MExtUtils::Manifest=mkmanifest" -e mkmanifest

veryclean : realclean
	$(RM_F) *~ */*~ *.orig */*.orig *.bak */*.bak *.old */*.old 

MAKE_FRAG

}


sub dist_ci {
    my($self) = shift;
    return q{
ci :
	$(PERLRUN) "-MExtUtils::Manifest=maniread" \\
	  -e "@all = keys %{ maniread() };" \\
	  -e "print(qq{Executing $(CI) @all\n}); system(qq{$(CI) @all});" \\
	  -e "print(qq{Executing $(RCS_LABEL) ...\n}); system(qq{$(RCS_LABEL) @all});"
};
}


sub dist_core {
    my($self) = shift;

    my $make_frag = '';
    foreach my $target (qw(dist tardist uutardist tarfile zipdist zipfile 
                           shdist))
    {
        my $method = $target.'_target';
        $make_frag .= "\n";
        $make_frag .= $self->$method();
    }

    return $make_frag;
}



sub dist_target {
    my($self) = shift;

    my $date_check = $self->oneliner(<<'CODE', ['-l']);
print 'Warning: Makefile possibly out of date with $(VERSION_FROM)'
    if -e '$(VERSION_FROM)' and -M '$(VERSION_FROM)' < -M '$(FIRST_MAKEFILE)';
CODE

    return sprintf <<'MAKE_FRAG', $date_check;
dist : $(DIST_DEFAULT) $(FIRST_MAKEFILE)
	$(NOECHO) %s
MAKE_FRAG
}


sub tardist_target {
    my($self) = shift;

    return <<'MAKE_FRAG';
tardist : $(DISTVNAME).tar$(SUFFIX)
	$(NOECHO) $(NOOP)
MAKE_FRAG
}


sub zipdist_target {
    my($self) = shift;

    return <<'MAKE_FRAG';
zipdist : $(DISTVNAME).zip
	$(NOECHO) $(NOOP)
MAKE_FRAG
}


sub tarfile_target {
    my($self) = shift;

    return <<'MAKE_FRAG';
$(DISTVNAME).tar$(SUFFIX) : distdir
	$(PREOP)
	$(TO_UNIX)
	$(TAR) $(TARFLAGS) $(DISTVNAME).tar $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(COMPRESS) $(DISTVNAME).tar
	$(POSTOP)
MAKE_FRAG
}


sub zipfile_target {
    my($self) = shift;

    return <<'MAKE_FRAG';
$(DISTVNAME).zip : distdir
	$(PREOP)
	$(ZIP) $(ZIPFLAGS) $(DISTVNAME).zip $(DISTVNAME)
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)
MAKE_FRAG
}


sub uutardist_target {
    my($self) = shift;

    return <<'MAKE_FRAG';
uutardist : $(DISTVNAME).tar$(SUFFIX)
	uuencode $(DISTVNAME).tar$(SUFFIX) $(DISTVNAME).tar$(SUFFIX) > $(DISTVNAME).tar$(SUFFIX)_uu
MAKE_FRAG
}



sub shdist_target {
    my($self) = shift;

    return <<'MAKE_FRAG';
shdist : distdir
	$(PREOP)
	$(SHAR) $(DISTVNAME) > $(DISTVNAME).shar
	$(RM_RF) $(DISTVNAME)
	$(POSTOP)
MAKE_FRAG
}



sub dlsyms {
    return '';
}



sub dynamic_bs {
    my($self, %attribs) = @_;
    return '
BOOTSTRAP =
' unless $self->has_link_code();

    my $target = $Is_VMS ? '$(MMS$TARGET)' : '$@';

    return sprintf <<'MAKE_FRAG', ($target) x 5;
BOOTSTRAP = $(BASEEXT).bs

$(BOOTSTRAP) : $(FIRST_MAKEFILE) $(BOOTDEP) $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(NOECHO) $(ECHO) "Running Mkbootstrap for $(NAME) ($(BSLOADLIBS))"
	$(NOECHO) $(PERLRUN) \
		"-MExtUtils::Mkbootstrap" \
		-e "Mkbootstrap('$(BASEEXT)','$(BSLOADLIBS)');"
	$(NOECHO) $(TOUCH) %s
	$(CHMOD) $(PERM_RW) %s

$(INST_BOOT) : $(BOOTSTRAP) $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(NOECHO) $(RM_RF) %s
	- $(CP) $(BOOTSTRAP) %s
	$(CHMOD) $(PERM_RW) %s
MAKE_FRAG
}


sub dynamic_lib {
    my($self, %attribs) = @_;
    return '' unless $self->needs_linking(); #might be because of a subdir

    return '' unless $self->has_link_code;

    my($otherldflags) = $attribs{OTHERLDFLAGS} || "";
    my($inst_dynamic_dep) = $attribs{INST_DYNAMIC_DEP} || "";
    my($armaybe) = $attribs{ARMAYBE} || $self->{ARMAYBE} || ":";
    my($ldfrom) = '$(LDFROM)';
    $armaybe = 'ar' if ($Is_OSF and $armaybe eq ':');
    my(@m);
    my $ld_opt = $Is_OS2 ? '$(OPTIMIZE) ' : '';	# Useful on other systems too?
    my $ld_fix = $Is_OS2 ? '|| ( $(RM_F) $@ && sh -c false )' : '';
    push(@m,'
ARMAYBE = '.$armaybe.'
OTHERLDFLAGS = '.$ld_opt.$otherldflags.'
INST_DYNAMIC_DEP = '.$inst_dynamic_dep.'
INST_DYNAMIC_FIX = '.$ld_fix.'

$(INST_DYNAMIC): $(OBJECT) $(MYEXTLIB) $(BOOTSTRAP) $(INST_ARCHAUTODIR)$(DFSEP).exists $(EXPORT_LIST) $(PERL_ARCHIVE) $(PERL_ARCHIVE_AFTER) $(INST_DYNAMIC_DEP)
');
    if ($armaybe ne ':'){
	$ldfrom = 'tmp$(LIB_EXT)';
	push(@m,'	$(ARMAYBE) cr '.$ldfrom.' $(OBJECT)'."\n");
	push(@m,'	$(RANLIB) '."$ldfrom\n");
    }
    $ldfrom = "-all $ldfrom -none" if $Is_OSF;

    # The IRIX linker doesn't use LD_RUN_PATH
    my $ldrun = $Is_IRIX && $self->{LD_RUN_PATH} ?         
                       qq{-rpath "$self->{LD_RUN_PATH}"} : '';

    # For example in AIX the shared objects/libraries from previous builds
    # linger quite a while in the shared dynalinker cache even when nobody
    # is using them.  This is painful if one for instance tries to restart
    # a failed build because the link command will fail unnecessarily 'cos
    # the shared object/library is 'busy'.
    push(@m,'	$(RM_F) $@
');

    my $libs = '$(LDLOADLIBS)';

    if (($Is_NetBSD || $Is_Interix) && $Config{'useshrplib'} eq 'true') {
	# Use nothing on static perl platforms, and to the flags needed
	# to link against the shared libperl library on shared perl
	# platforms.  We peek at lddlflags to see if we need -Wl,-R
	# or -R to add paths to the run-time library search path.
        if ($Config{'lddlflags'} =~ /-Wl,-R/) {
            $libs .= ' -L$(PERL_INC) -Wl,-R$(INSTALLARCHLIB)/CORE -Wl,-R$(PERL_ARCHLIB)/CORE -lperl';
        } elsif ($Config{'lddlflags'} =~ /-R/) {
            $libs .= ' -L$(PERL_INC) -R$(INSTALLARCHLIB)/CORE -R$(PERL_ARCHLIB)/CORE -lperl';
        }
    }

    my $ld_run_path_shell = "";
    if ($self->{LD_RUN_PATH} ne "") {
	$ld_run_path_shell = 'LD_RUN_PATH="$(LD_RUN_PATH)" ';
    }

    push @m, sprintf <<'MAKE', $ld_run_path_shell, $ldrun, $ldfrom, $libs;
	%s$(LD) %s $(LDDLFLAGS) %s $(OTHERLDFLAGS) -o $@ $(MYEXTLIB)	\
	  $(PERL_ARCHIVE) %s $(PERL_ARCHIVE_AFTER) $(EXPORT_LIST)	\
	  $(INST_DYNAMIC_FIX)
MAKE

    push @m, <<'MAKE';
	$(CHMOD) $(PERM_RWX) $@
MAKE

    return join('',@m);
}


sub exescan {
    my($self,$path) = @_;
    $path;
}


sub extliblist {
    my($self,$libs) = @_;
    require ExtUtils::Liblist;
    $self->ext($libs, $Verbose);
}


sub find_perl {
    my($self, $ver, $names, $dirs, $trace) = @_;
    my($name, $dir);
    if ($trace >= 2){
        print "Looking for perl $ver by these names:
@$names
in these dirs:
@$dirs
";
    }

    my $stderr_duped = 0;
    local *STDERR_COPY;
    unless ($Is_BSD) {
        if( open(STDERR_COPY, '>&STDERR') ) {
            $stderr_duped = 1;
        }
        else {
            warn <<WARNING;
find_perl() can't dup STDERR: $!
You might see some garbage while we search for Perl
WARNING
        }
    }

    foreach $name (@$names){
        foreach $dir (@$dirs){
            next unless defined $dir; # $self->{PERL_SRC} may be undefined
            my ($abs, $val);
            if ($self->file_name_is_absolute($name)) {     # /foo/bar
                $abs = $name;
            } elsif ($self->canonpath($name) eq 
                     $self->canonpath(basename($name))) {  # foo
                $abs = $self->catfile($dir, $name);
            } else {                                            # foo/bar
                $abs = $self->catfile($Curdir, $name);
            }
            print "Checking $abs\n" if ($trace >= 2);
            next unless $self->maybe_command($abs);
            print "Executing $abs\n" if ($trace >= 2);

            my $version_check = qq{$abs -le "require $ver; print qq{VER_OK}"};
            $version_check = "$Config{run} $version_check"
                if defined $Config{run} and length $Config{run};

            # To avoid using the unportable 2>&1 to suppress STDERR,
            # we close it before running the command.
            # However, thanks to a thread library bug in many BSDs
            # ( http://www.freebsd.org/cgi/query-pr.cgi?pr=51535 )
            # we cannot use the fancier more portable way in here
            # but instead need to use the traditional 2>&1 construct.
            if ($Is_BSD) {
                $val = `$version_check 2>&1`;
            } else {
                close STDERR if $stderr_duped;
                $val = `$version_check`;
                open STDERR, '>&STDERR_COPY' if $stderr_duped;
            }

            if ($val =~ /^VER_OK/m) {
                print "Using PERL=$abs\n" if $trace;
                return $abs;
            } elsif ($trace >= 2) {
                print "Result: '$val' ".($? >> 8)."\n";
            }
        }
    }
    print STDOUT "Unable to find a perl $ver (by these names: @$names, in these dirs: @$dirs)\n";
    0; # false and not empty
}



sub fixin {    # stolen from the pink Camel book, more or less
    my ( $self, @files ) = @_;

    my ($does_shbang) = $Config{'sharpbang'} =~ /^\s*\#\!/;
    for my $file (@files) {
        my $file_new = "$file.new";
        my $file_bak = "$file.bak";

        local (*FIXIN);
        local (*FIXOUT);
        open( FIXIN, $file ) or croak "Can't process '$file': $!";
        local $/ = "\n";
        chomp( my $line = <FIXIN> );
        next unless $line =~ s/^\s*\#!\s*//;    # Not a shbang file.
        # Now figure out the interpreter name.
        my ( $cmd, $arg ) = split ' ', $line, 2;
        $cmd =~ s!^.*/!!;

        # Now look (in reverse) for interpreter in absolute PATH (unless perl).
        my $interpreter;
        if ( $cmd eq "perl" ) {
            if ( $Config{startperl} =~ m,^\#!.*/perl, ) {
                $interpreter = $Config{startperl};
                $interpreter =~ s,^\#!,,;
            }
            else {
                $interpreter = $Config{perlpath};
            }
        }
        else {
            my (@absdirs)
                = reverse grep { $self->file_name_is_absolute } $self->path;
            $interpreter = '';
            my ($dir);
            foreach $dir (@absdirs) {
                if ( $self->maybe_command($cmd) ) {
                    warn "Ignoring $interpreter in $file\n"
                        if $Verbose && $interpreter;
                    $interpreter = $self->catfile( $dir, $cmd );
                }
            }
        }

        # Figure out how to invoke interpreter on this machine.

        my ($shb) = "";
        if ($interpreter) {
            print STDOUT "Changing sharpbang in $file to $interpreter"
                if $Verbose;

            # this is probably value-free on DOSISH platforms
            if ($does_shbang) {
                $shb .= "$Config{'sharpbang'}$interpreter";
                $shb .= ' ' . $arg if defined $arg;
                $shb .= "\n";
            }
            $shb .= qq{
eval 'exec $interpreter $arg -S \$0 \${1+"\$\@"}'
    if 0; # not running under some shell
} unless $Is_Win32;    # this won't work on win32, so don't
        }
        else {
            warn "Can't find $cmd in PATH, $file unchanged"
                if $Verbose;
            next;
        }

        unless ( open( FIXOUT, ">$file_new" ) ) {
            warn "Can't create new $file: $!\n";
            next;
        }

        # Print out the new #! line (or equivalent).
        local $\;
        local $/;
        print FIXOUT $shb, <FIXIN>;
        close FIXIN;
        close FIXOUT;

        chmod 0666, $file_bak;
        unlink $file_bak;
        unless ( _rename( $file, $file_bak ) ) {
            warn "Can't rename $file to $file_bak: $!";
            next;
        }
        unless ( _rename( $file_new, $file ) ) {
            warn "Can't rename $file_new to $file: $!";
            unless ( _rename( $file_bak, $file ) ) {
                warn "Can't rename $file_bak back to $file either: $!";
                warn "Leaving $file renamed as $file_bak\n";
            }
            next;
        }
        unlink $file_bak;
    }
    continue {
        close(FIXIN) if fileno(FIXIN);
        system("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
    }
}


sub _rename {
    my($old, $new) = @_;

    foreach my $file ($old, $new) {
        if( $Is_VMS and basename($file) !~ /\./ ) {
            # rename() in 5.8.0 on VMS will not rename a file if it
            # does not contain a dot yet it returns success.
            $file = "$file.";
        }
    }

    return rename($old, $new);
}



sub force {
    my($self) = shift;
    '# Phony target to force checking subdirectories.
FORCE :
	$(NOECHO) $(NOOP)
';
}



sub guess_name {
    my($self) = @_;
    use Cwd 'cwd';
    my $name = basename(cwd());
    $name =~ s|[\-_][\d\.\-]+\z||;  # this is new with MM 5.00, we
                                    # strip minus or underline
                                    # followed by a float or some such
    print "Warning: Guessing NAME [$name] from current directory name.\n";
    $name;
}


sub has_link_code {
    my($self) = shift;
    return $self->{HAS_LINK_CODE} if defined $self->{HAS_LINK_CODE};
    if ($self->{OBJECT} or @{$self->{C} || []} or $self->{MYEXTLIB}){
	$self->{HAS_LINK_CODE} = 1;
	return 1;
    }
    return $self->{HAS_LINK_CODE} = 0;
}



sub init_dirscan {	# --- File and Directory Lists (.xs .pm .pod etc)
    my($self) = @_;
    my($name, %dir, %xs, %c, %h, %pl_files, %pm);

    my %ignore = map {( $_ => 1 )} qw(Makefile.PL Build.PL test.pl t);

    # ignore the distdir
    $Is_VMS ? $ignore{"$self->{DISTVNAME}.dir"} = 1
            : $ignore{$self->{DISTVNAME}} = 1;

    @ignore{map lc, keys %ignore} = values %ignore if $Is_VMS;

    foreach $name ($self->lsdir($Curdir)){
	next if $name =~ /\#/;
	next if $name eq $Curdir or $name eq $Updir or $ignore{$name};
	next unless $self->libscan($name);
	if (-d $name){
	    next if -l $name; # We do not support symlinks at all
            next if $self->{NORECURS};
	    $dir{$name} = $name if (-f $self->catfile($name,"Makefile.PL"));
	} elsif ($name =~ /\.xs\z/){
	    my($c); ($c = $name) =~ s/\.xs\z/.c/;
	    $xs{$name} = $c;
	    $c{$c} = 1;
	} elsif ($name =~ /\.c(pp|xx|c)?\z/i){  # .c .C .cpp .cxx .cc
	    $c{$name} = 1
		unless $name =~ m/perlmain\.c/; # See MAP_TARGET
	} elsif ($name =~ /\.h\z/i){
	    $h{$name} = 1;
	} elsif ($name =~ /\.PL\z/) {
	    ($pl_files{$name} = $name) =~ s/\.PL\z// ;
	} elsif (($Is_VMS || $Is_Dos) && $name =~ /[._]pl$/i) {
	    # case-insensitive filesystem, one dot per name, so foo.h.PL
	    # under Unix appears as foo.h_pl under VMS or fooh.pl on Dos
	    local($/); open(PL,$name); my $txt = <PL>; close PL;
	    if ($txt =~ /Extracting \S+ \(with variable substitutions/) {
		($pl_files{$name} = $name) =~ s/[._]pl\z//i ;
	    }
	    else { 
                $pm{$name} = $self->catfile($self->{INST_LIBDIR},$name); 
            }
	} elsif ($name =~ /\.(p[ml]|pod)\z/){
	    $pm{$name} = $self->catfile($self->{INST_LIBDIR},$name);
	}
    }

    $self->{PL_FILES}   ||= \%pl_files;
    $self->{DIR}        ||= [sort keys %dir];
    $self->{XS}         ||= \%xs;
    $self->{C}          ||= [sort keys %c];
    $self->{H}          ||= [sort keys %h];
    $self->{PM}         ||= \%pm;

    my @o_files = @{$self->{C}};
    $self->{O_FILES} = [grep s/\.c(pp|xx|c)?\z/$self->{OBJ_EXT}/i, @o_files];
}



sub init_MANPODS {
    my $self = shift;

    # Set up names of manual pages to generate from pods
    foreach my $man (qw(MAN1 MAN3)) {
	if ( $self->{"${man}PODS"}
             or $self->{"INSTALL${man}DIR"} =~ /^(none|\s*)$/
        ) {
            $self->{"${man}PODS"} ||= {};
        }
        else {
            my $init_method = "init_${man}PODS";
            $self->$init_method();
	}
    }
}


sub _has_pod {
    my($self, $file) = @_;

    local *FH;
    my($ispod)=0;
    if (open(FH,"<$file")) {
	while (<FH>) {
	    if (/^=(?:head\d+|item|pod)\b/) {
		$ispod=1;
		last;
	    }
	}
	close FH;
    } else {
	# If it doesn't exist yet, we assume, it has pods in it
	$ispod = 1;
    }

    return $ispod;
}



sub init_MAN1PODS {
    my($self) = @_;

    if ( exists $self->{EXE_FILES} ) {
	foreach my $name (@{$self->{EXE_FILES}}) {
	    next unless $self->_has_pod($name);

	    $self->{MAN1PODS}->{$name} =
		$self->catfile("\$(INST_MAN1DIR)", 
			       basename($name).".\$(MAN1EXT)");
	}
    }
}



sub init_MAN3PODS {
    my $self = shift;

    my %manifypods = (); # we collect the keys first, i.e. the files
                         # we have to convert to pod

    foreach my $name (keys %{$self->{PM}}) {
	if ($name =~ /\.pod\z/ ) {
	    $manifypods{$name} = $self->{PM}{$name};
	} elsif ($name =~ /\.p[ml]\z/ ) {
	    if( $self->_has_pod($name) ) {
		$manifypods{$name} = $self->{PM}{$name};
	    }
	}
    }

    my $parentlibs_re = join '|', @{$self->{PMLIBPARENTDIRS}};

    # Remove "Configure.pm" and similar, if it's not the only pod listed
    # To force inclusion, just name it "Configure.pod", or override 
    # MAN3PODS
    foreach my $name (keys %manifypods) {
	if ($self->{PERL_CORE} and $name =~ /(config|setup).*\.pm/is) {
	    delete $manifypods{$name};
	    next;
	}
	my($manpagename) = $name;
	$manpagename =~ s/\.p(od|m|l)\z//;
	# everything below lib is ok
	unless($manpagename =~ s!^\W*($parentlibs_re)\W+!!s) {
	    $manpagename = $self->catfile(
	        split(/::/,$self->{PARENT_NAME}),$manpagename
	    );
	}
	$manpagename = $self->replace_manpage_separator($manpagename);
	$self->{MAN3PODS}->{$name} =
	    $self->catfile("\$(INST_MAN3DIR)", "$manpagename.\$(MAN3EXT)");
    }
}



sub init_PM {
    my $self = shift;

    # Some larger extensions often wish to install a number of *.pm/pl
    # files into the library in various locations.

    # The attribute PMLIBDIRS holds an array reference which lists
    # subdirectories which we should search for library files to
    # install. PMLIBDIRS defaults to [ 'lib', $self->{BASEEXT} ].  We
    # recursively search through the named directories (skipping any
    # which don't exist or contain Makefile.PL files).

    # For each *.pm or *.pl file found $self->libscan() is called with
    # the default installation path in $_[1]. The return value of
    # libscan defines the actual installation location.  The default
    # libscan function simply returns the path.  The file is skipped
    # if libscan returns false.

    # The default installation location passed to libscan in $_[1] is:
    #
    #  ./*.pm		=> $(INST_LIBDIR)/*.pm
    #  ./xyz/...	=> $(INST_LIBDIR)/xyz/...
    #  ./lib/...	=> $(INST_LIB)/...
    #
    # In this way the 'lib' directory is seen as the root of the actual
    # perl library whereas the others are relative to INST_LIBDIR
    # (which includes PARENT_NAME). This is a subtle distinction but one
    # that's important for nested modules.

    unless( $self->{PMLIBDIRS} ) {
        if( $Is_VMS ) {
            # Avoid logical name vs directory collisions
            $self->{PMLIBDIRS} = ['./lib', "./$self->{BASEEXT}"];
        }
        else {
            $self->{PMLIBDIRS} = ['lib', $self->{BASEEXT}];
        }
    }

    #only existing directories that aren't in $dir are allowed

    # Avoid $_ wherever possible:
    # @{$self->{PMLIBDIRS}} = grep -d && !$dir{$_}, @{$self->{PMLIBDIRS}};
    my (@pmlibdirs) = @{$self->{PMLIBDIRS}};
    @{$self->{PMLIBDIRS}} = ();
    my %dir = map { ($_ => $_) } @{$self->{DIR}};
    foreach my $pmlibdir (@pmlibdirs) {
	-d $pmlibdir && !$dir{$pmlibdir} && push @{$self->{PMLIBDIRS}}, $pmlibdir;
    }

    unless( $self->{PMLIBPARENTDIRS} ) {
	@{$self->{PMLIBPARENTDIRS}} = ('lib');
    }

    return if $self->{PM} and $self->{ARGS}{PM};

    if (@{$self->{PMLIBDIRS}}){
	print "Searching PMLIBDIRS: @{$self->{PMLIBDIRS}}\n"
	    if ($Verbose >= 2);
	require File::Find;
        File::Find::find(sub {
            if (-d $_){
                unless ($self->libscan($_)){
                    $File::Find::prune = 1;
                }
                return;
            }
            return if /\#/;
            return if /~$/;    # emacs temp files
            return if /,v$/;   # RCS files

	    my $path   = $File::Find::name;
            my $prefix = $self->{INST_LIBDIR};
            my $striplibpath;

	    my $parentlibs_re = join '|', @{$self->{PMLIBPARENTDIRS}};
	    $prefix =  $self->{INST_LIB} 
                if ($striplibpath = $path) =~ s{^(\W*)($parentlibs_re)\W}
	                                       {$1}i;

	    my($inst) = $self->catfile($prefix,$striplibpath);
	    local($_) = $inst; # for backwards compatibility
	    $inst = $self->libscan($inst);
	    print "libscan($path) => '$inst'\n" if ($Verbose >= 2);
	    return unless $inst;
	    $self->{PM}{$path} = $inst;
	}, @{$self->{PMLIBDIRS}});
    }
}



sub init_DIRFILESEP {
    my($self) = shift;

    $self->{DIRFILESEP} = '/';
}
    


sub init_main {
    my($self) = @_;

    # --- Initialize Module Name and Paths

    # NAME    = Foo::Bar::Oracle
    # FULLEXT = Foo/Bar/Oracle
    # BASEEXT = Oracle
    # PARENT_NAME = Foo::Bar
    $self->{FULLEXT} = $self->catdir(split /::/, $self->{NAME});


    # Copied from DynaLoader:

    my(@modparts) = split(/::/,$self->{NAME});
    my($modfname) = $modparts[-1];

    # Some systems have restrictions on files names for DLL's etc.
    # mod2fname returns appropriate file base name (typically truncated)
    # It may also edit @modparts if required.
    if (defined &DynaLoader::mod2fname) {
        $modfname = &DynaLoader::mod2fname(\@modparts);
    }

    ($self->{PARENT_NAME}, $self->{BASEEXT}) = $self->{NAME} =~ m!(?:([\w:]+)::)?(\w+)\z! ;
    $self->{PARENT_NAME} ||= '';

    if (defined &DynaLoader::mod2fname) {
	# As of 5.001m, dl_os2 appends '_'
	$self->{DLBASE} = $modfname;
    } else {
	$self->{DLBASE} = '$(BASEEXT)';
    }


    # --- Initialize PERL_LIB, PERL_SRC

    # *Real* information: where did we get these two from? ...
    my $inc_config_dir = dirname($INC{'Config.pm'});
    my $inc_carp_dir   = dirname($INC{'Carp.pm'});

    unless ($self->{PERL_SRC}){
        foreach my $dir_count (1..8) { # 8 is the VMS limit for nesting
            my $dir = $self->catdir(($Updir) x $dir_count);

            if (-f $self->catfile($dir,"config_h.SH")   &&
                -f $self->catfile($dir,"perl.h")        &&
                -f $self->catfile($dir,"lib","Exporter.pm")
            ) {
                $self->{PERL_SRC}=$dir ;
                last;
            }
        }
    }

    warn "PERL_CORE is set but I can't find your PERL_SRC!\n" if
      $self->{PERL_CORE} and !$self->{PERL_SRC};

    if ($self->{PERL_SRC}){
	$self->{PERL_LIB}     ||= $self->catdir("$self->{PERL_SRC}","lib");

        if (defined $Cross::platform) {
            $self->{PERL_ARCHLIB} = 
              $self->catdir("$self->{PERL_SRC}","xlib",$Cross::platform);
            $self->{PERL_INC}     = 
              $self->catdir("$self->{PERL_SRC}","xlib",$Cross::platform, 
                                 $Is_Win32?("CORE"):());
        }
        else {
            $self->{PERL_ARCHLIB} = $self->{PERL_LIB};
            $self->{PERL_INC}     = ($Is_Win32) ? 
              $self->catdir($self->{PERL_LIB},"CORE") : $self->{PERL_SRC};
        }

	# catch a situation that has occurred a few times in the past:
	unless (
		-s $self->catfile($self->{PERL_SRC},'cflags')
		or
		$Is_VMS
		&&
		-s $self->catfile($self->{PERL_SRC},'perlshr_attr.opt')
		or
		$Is_Win32
	       ){
	    warn qq{
You cannot build extensions below the perl source tree after executing
a 'make clean' in the perl source tree.

To rebuild extensions distributed with the perl source you should
simply Configure (to include those extensions) and then build perl as
normal. After installing perl the source tree can be deleted. It is
not needed for building extensions by running 'perl Makefile.PL'
usually without extra arguments.

It is recommended that you unpack and build additional extensions away
from the perl source tree.
};
	}
    } else {
	# we should also consider $ENV{PERL5LIB} here
        my $old = $self->{PERL_LIB} || $self->{PERL_ARCHLIB} || $self->{PERL_INC};
	$self->{PERL_LIB}     ||= $Config{privlibexp};
	$self->{PERL_ARCHLIB} ||= $Config{archlibexp};
	$self->{PERL_INC}     = $self->catdir("$self->{PERL_ARCHLIB}","CORE"); # wild guess for now
	my $perl_h;

	if (not -f ($perl_h = $self->catfile($self->{PERL_INC},"perl.h"))
	    and not $old){
	    # Maybe somebody tries to build an extension with an
	    # uninstalled Perl outside of Perl build tree
	    my $lib;
	    for my $dir (@INC) {
	      $lib = $dir, last if -e $self->catdir($dir, "Config.pm");
	    }
	    if ($lib) {
              # Win32 puts its header files in /perl/src/lib/CORE.
              # Unix leaves them in /perl/src.
	      my $inc = $Is_Win32 ? $self->catdir($lib, "CORE" )
                                  : dirname $lib;
	      if (-e $self->catdir($inc, "perl.h")) {
		$self->{PERL_LIB}	   = $lib;
		$self->{PERL_ARCHLIB}	   = $lib;
		$self->{PERL_INC}	   = $inc;
		$self->{UNINSTALLED_PERL}  = 1;
		print STDOUT <<EOP;
... Detected uninstalled Perl.  Trying to continue.
EOP
	      }
	    }
	}	
    }

    # We get SITELIBEXP and SITEARCHEXP directly via
    # Get_from_Config. When we are running standard modules, these
    # won't matter, we will set INSTALLDIRS to "perl". Otherwise we
    # set it to "site". I prefer that INSTALLDIRS be set from outside
    # MakeMaker.
    $self->{INSTALLDIRS} ||= "site";

    $self->{MAN1EXT} ||= $Config{man1ext};
    $self->{MAN3EXT} ||= $Config{man3ext};

    # Get some stuff out of %Config if we haven't yet done so
    print STDOUT "CONFIG must be an array ref\n"
	if ($self->{CONFIG} and ref $self->{CONFIG} ne 'ARRAY');
    $self->{CONFIG} = [] unless (ref $self->{CONFIG});
    push(@{$self->{CONFIG}}, @ExtUtils::MakeMaker::Get_from_Config);
    push(@{$self->{CONFIG}}, 'shellflags') if $Config{shellflags};
    my(%once_only);
    foreach my $m (@{$self->{CONFIG}}){
	next if $once_only{$m};
	print STDOUT "CONFIG key '$m' does not exist in Config.pm\n"
		unless exists $Config{$m};
	$self->{uc $m} ||= $Config{$m};
	$once_only{$m} = 1;
    }


    $self->{AR_STATIC_ARGS} ||= "cr";

    # These should never be needed
    $self->{OBJ_EXT} ||= '.o';
    $self->{LIB_EXT} ||= '.a';

    $self->{MAP_TARGET} ||= "perl";

    $self->{LIBPERL_A} ||= "libperl$self->{LIB_EXT}";

    # make a simple check if we find Exporter
    warn "Warning: PERL_LIB ($self->{PERL_LIB}) seems not to be a perl library directory
        (Exporter.pm not found)"
	unless -f $self->catfile("$self->{PERL_LIB}","Exporter.pm") ||
        $self->{NAME} eq "ExtUtils::MakeMaker";
}


sub init_others {	# --- Initialize Other Attributes
    my($self) = shift;

    $self->{LD} ||= 'ld';

    # Compute EXTRALIBS, BSLOADLIBS and LDLOADLIBS from $self->{LIBS}
    # Lets look at $self->{LIBS} carefully: It may be an anon array, a string or
    # undefined. In any case we turn it into an anon array:

    # May check $Config{libs} too, thus not empty.
    $self->{LIBS} = [$self->{LIBS}] unless ref $self->{LIBS};

    $self->{LIBS} = [''] unless @{$self->{LIBS}} && defined $self->{LIBS}[0];
    $self->{LD_RUN_PATH} = "";
    my($libs);
    foreach $libs ( @{$self->{LIBS}} ){
	$libs =~ s/^\s*(.*\S)\s*$/$1/; # remove leading and trailing whitespace
	my(@libs) = $self->extliblist($libs);
	if ($libs[0] or $libs[1] or $libs[2]){
	    # LD_RUN_PATH now computed by ExtUtils::Liblist
	    ($self->{EXTRALIBS},  $self->{BSLOADLIBS}, 
             $self->{LDLOADLIBS}, $self->{LD_RUN_PATH}) = @libs;
	    last;
	}
    }

    if ( $self->{OBJECT} ) {
	$self->{OBJECT} =~ s!\.o(bj)?\b!\$(OBJ_EXT)!g;
    } else {
	# init_dirscan should have found out, if we have C files
	$self->{OBJECT} = "";
	$self->{OBJECT} = '$(BASEEXT)$(OBJ_EXT)' if @{$self->{C}||[]};
    }
    $self->{OBJECT} =~ s/\n+/ \\\n\t/g;
    $self->{BOOTDEP}  = (-f "$self->{BASEEXT}_BS") ? "$self->{BASEEXT}_BS" : "";
    $self->{PERLMAINCC} ||= '$(CC)';
    $self->{LDFROM} = '$(OBJECT)' unless $self->{LDFROM};

    # Sanity check: don't define LINKTYPE = dynamic if we're skipping
    # the 'dynamic' section of MM.  We don't have this problem with
    # 'static', since we either must use it (%Config says we can't
    # use dynamic loading) or the caller asked for it explicitly.
    if (!$self->{LINKTYPE}) {
       $self->{LINKTYPE} = $self->{SKIPHASH}{'dynamic'}
                        ? 'static'
                        : ($Config{usedl} ? 'dynamic' : 'static');
    };

    $self->{NOOP}               ||= '$(SHELL) -c true';
    $self->{NOECHO}             = '@' unless defined $self->{NOECHO};

    $self->{FIRST_MAKEFILE}     ||= $self->{MAKEFILE} || 'Makefile';
    $self->{MAKEFILE}           ||= $self->{FIRST_MAKEFILE};
    $self->{MAKEFILE_OLD}       ||= $self->{MAKEFILE}.'.old';
    $self->{MAKE_APERL_FILE}    ||= $self->{MAKEFILE}.'.aperl';

    # Some makes require a wrapper around macros passed in on the command 
    # line.
    $self->{MACROSTART}         ||= '';
    $self->{MACROEND}           ||= '';

    # Not everybody uses -f to indicate "use this Makefile instead"
    $self->{USEMAKEFILE}        ||= '-f';

    $self->{SHELL}              ||= $Config{sh} || '/bin/sh';

    $self->{ECHO}       ||= 'echo';
    $self->{ECHO_N}     ||= 'echo -n';
    $self->{RM_F}       ||= "rm -f";
    $self->{RM_RF}      ||= "rm -rf";
    $self->{TOUCH}      ||= "touch";
    $self->{TEST_F}     ||= "test -f";
    $self->{CP}         ||= "cp";
    $self->{MV}         ||= "mv";
    $self->{CHMOD}      ||= "chmod";
    $self->{MKPATH}     ||= '$(ABSPERLRUN) "-MExtUtils::Command" -e mkpath';
    $self->{EQUALIZE_TIMESTAMP} ||= 
      '$(ABSPERLRUN) "-MExtUtils::Command" -e eqtime';

    $self->{UNINST}     ||= 0;
    $self->{VERBINST}   ||= 0;
    $self->{MOD_INSTALL} ||= 
      $self->oneliner(<<'CODE', ['-MExtUtils::Install']);
install({@ARGV}, '$(VERBINST)', 0, '$(UNINST)');
CODE
    $self->{DOC_INSTALL}        ||= 
      '$(ABSPERLRUN) "-MExtUtils::Command::MM" -e perllocal_install';
    $self->{UNINSTALL}          ||= 
      '$(ABSPERLRUN) "-MExtUtils::Command::MM" -e uninstall';
    $self->{WARN_IF_OLD_PACKLIST} ||= 
      '$(ABSPERLRUN) "-MExtUtils::Command::MM" -e warn_if_old_packlist';
    $self->{FIXIN}              ||= 
      q{$(PERLRUN) "-MExtUtils::MY" -e "MY->fixin(shift)"};

    $self->{UMASK_NULL}         ||= "umask 0";
    $self->{DEV_NULL}           ||= "> /dev/null 2>&1";

    return 1;
}



sub init_linker {
    my($self) = shift;
    $self->{PERL_ARCHIVE} ||= '';
    $self->{PERL_ARCHIVE_AFTER} ||= '';
    $self->{EXPORT_LIST}  ||= '';
}


=begin _protected


sub init_lib2arch {
    my($self) = shift;

    # The user who requests an installation directory explicitly
    # should not have to tell us an architecture installation directory
    # as well. We look if a directory exists that is named after the
    # architecture. If not we take it as a sign that it should be the
    # same as the requested installation directory. Otherwise we take
    # the found one.
    for my $libpair ({l=>"privlib",   a=>"archlib"}, 
                     {l=>"sitelib",   a=>"sitearch"},
                     {l=>"vendorlib", a=>"vendorarch"},
                    )
    {
        my $lib = "install$libpair->{l}";
        my $Lib = uc $lib;
        my $Arch = uc "install$libpair->{a}";
        if( $self->{$Lib} && ! $self->{$Arch} ){
            my($ilib) = $Config{$lib};

            $self->prefixify($Arch,$ilib,$self->{$Lib});

            unless (-d $self->{$Arch}) {
                print STDOUT "Directory $self->{$Arch} not found\n" 
                  if $Verbose;
                $self->{$Arch} = $self->{$Lib};
            }
            print STDOUT "Defaulting $Arch to $self->{$Arch}\n" if $Verbose;
        }
    }
}



sub init_PERL {
    my($self) = shift;

    my @defpath = ();
    foreach my $component ($self->{PERL_SRC}, $self->path(), 
                           $Config{binexp}) 
    {
	push @defpath, $component if defined $component;
    }

    # Build up a set of file names (not command names).
    my $thisperl = $self->canonpath($^X);
    $thisperl .= $Config{exe_ext} unless 
                # VMS might have a file version # at the end
      $Is_VMS ? $thisperl =~ m/$Config{exe_ext}(;\d+)?$/i
              : $thisperl =~ m/$Config{exe_ext}$/i;

    # We need a relative path to perl when in the core.
    $thisperl = $self->abs2rel($thisperl) if $self->{PERL_CORE};

    my @perls = ($thisperl);
    push @perls, map { "$_$Config{exe_ext}" }
                     ('perl', 'perl5', "perl$Config{version}");

    # miniperl has priority over all but the cannonical perl when in the
    # core.  Otherwise its a last resort.
    my $miniperl = "miniperl$Config{exe_ext}";
    if( $self->{PERL_CORE} ) {
        splice @perls, 1, 0, $miniperl;
    }
    else {
        push @perls, $miniperl;
    }

    $self->{PERL} ||=
        $self->find_perl(5.0, \@perls, \@defpath, $Verbose );
    # don't check if perl is executable, maybe they have decided to
    # supply switches with perl

    # When built for debugging, VMS doesn't create perl.exe but ndbgperl.exe.
    my $perl_name = 'perl';
    $perl_name = 'ndbgperl' if $Is_VMS && 
      defined $Config{usevmsdebug} && $Config{usevmsdebug} eq 'define';

    # XXX This logic is flawed.  If "miniperl" is anywhere in the path
    # it will get confused.  It should be fixed to work only on the filename.
    # Define 'FULLPERL' to be a non-miniperl (used in test: target)
    ($self->{FULLPERL} = $self->{PERL}) =~ s/miniperl/$perl_name/i
	unless $self->{FULLPERL};

    # Little hack to get around VMS's find_perl putting "MCR" in front
    # sometimes.
    $self->{ABSPERL} = $self->{PERL};
    my $has_mcr = $self->{ABSPERL} =~ s/^MCR\s*//;
    if( $self->file_name_is_absolute($self->{ABSPERL}) ) {
        $self->{ABSPERL} = '$(PERL)';
    }
    else {
        $self->{ABSPERL} = $self->rel2abs($self->{ABSPERL});
        $self->{ABSPERL} = 'MCR '.$self->{ABSPERL} if $has_mcr;
    }

    # Are we building the core?
    $self->{PERL_CORE} = $ENV{PERL_CORE} unless exists $self->{PERL_CORE};
    $self->{PERL_CORE} = 0               unless defined $self->{PERL_CORE};

    # How do we run perl?
    foreach my $perl (qw(PERL FULLPERL ABSPERL)) {
        my $run  = $perl.'RUN';

        $self->{$run}  = "\$($perl)";

        # Make sure perl can find itself before it's installed.
        $self->{$run} .= q{ "-I$(PERL_LIB)" "-I$(PERL_ARCHLIB)"} 
          if $self->{UNINSTALLED_PERL} || $self->{PERL_CORE};

        $self->{$perl.'RUNINST'} = 
          sprintf q{$(%sRUN) "-I$(INST_ARCHLIB)" "-I$(INST_LIB)"}, $perl;
    }

    return 1;
}



sub init_platform {
    my($self) = shift;

    $self->{MM_Unix_VERSION} = $VERSION;
    $self->{PERL_MALLOC_DEF} = '-DPERL_EXTMALLOC_DEF -Dmalloc=Perl_malloc '.
                               '-Dfree=Perl_mfree -Drealloc=Perl_realloc '.
                               '-Dcalloc=Perl_calloc';

}

sub platform_constants {
    my($self) = shift;
    my $make_frag = '';

    foreach my $macro (qw(MM_Unix_VERSION PERL_MALLOC_DEF))
    {
        next unless defined $self->{$macro};
        $make_frag .= "$macro = $self->{$macro}\n";
    }

    return $make_frag;
}



sub init_PERM {
    my($self) = shift;

    $self->{PERM_RW}  = 644  unless defined $self->{PERM_RW};
    $self->{PERM_RWX} = 755  unless defined $self->{PERM_RWX};

    return 1;
}



sub init_xs {
    my $self = shift;

    if ($self->has_link_code()) {
        $self->{INST_STATIC}  = 
          $self->catfile('$(INST_ARCHAUTODIR)', '$(BASEEXT)$(LIB_EXT)');
        $self->{INST_DYNAMIC} = 
          $self->catfile('$(INST_ARCHAUTODIR)', '$(DLBASE).$(DLEXT)');
        $self->{INST_BOOT}    = 
          $self->catfile('$(INST_ARCHAUTODIR)', '$(BASEEXT).bs');
    } else {
        $self->{INST_STATIC}  = '';
        $self->{INST_DYNAMIC} = '';
        $self->{INST_BOOT}    = '';
    }
}    


sub install {
    my($self, %attribs) = @_;
    my(@m);

    push @m, q{
install :: all pure_install doc_install
	$(NOECHO) $(NOOP)

install_perl :: all pure_perl_install doc_perl_install
	$(NOECHO) $(NOOP)

install_site :: all pure_site_install doc_site_install
	$(NOECHO) $(NOOP)

install_vendor :: all pure_vendor_install doc_vendor_install
	$(NOECHO) $(NOOP)

pure_install :: pure_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

doc_install :: doc_$(INSTALLDIRS)_install
	$(NOECHO) $(NOOP)

pure__install : pure_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

doc__install : doc_site_install
	$(NOECHO) $(ECHO) INSTALLDIRS not defined, defaulting to INSTALLDIRS=site

pure_perl_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read }.$self->catfile('$(PERL_ARCHLIB)','auto','$(FULLEXT)','.packlist').q{ \
		write }.$self->catfile('$(DESTINSTALLARCHLIB)','auto','$(FULLEXT)','.packlist').q{ \
		$(INST_LIB) $(DESTINSTALLPRIVLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLARCHLIB) \
		$(INST_BIN) $(DESTINSTALLBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		}.$self->catdir('$(SITEARCHEXP)','auto','$(FULLEXT)').q{


pure_site_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read }.$self->catfile('$(SITEARCHEXP)','auto','$(FULLEXT)','.packlist').q{ \
		write }.$self->catfile('$(DESTINSTALLSITEARCH)','auto','$(FULLEXT)','.packlist').q{ \
		$(INST_LIB) $(DESTINSTALLSITELIB) \
		$(INST_ARCHLIB) $(DESTINSTALLSITEARCH) \
		$(INST_BIN) $(DESTINSTALLSITEBIN) \
		$(INST_SCRIPT) $(DESTINSTALLSITESCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLSITEMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLSITEMAN3DIR)
	$(NOECHO) $(WARN_IF_OLD_PACKLIST) \
		}.$self->catdir('$(PERL_ARCHLIB)','auto','$(FULLEXT)').q{

pure_vendor_install ::
	$(NOECHO) $(MOD_INSTALL) \
		read }.$self->catfile('$(VENDORARCHEXP)','auto','$(FULLEXT)','.packlist').q{ \
		write }.$self->catfile('$(DESTINSTALLVENDORARCH)','auto','$(FULLEXT)','.packlist').q{ \
		$(INST_LIB) $(DESTINSTALLVENDORLIB) \
		$(INST_ARCHLIB) $(DESTINSTALLVENDORARCH) \
		$(INST_BIN) $(DESTINSTALLVENDORBIN) \
		$(INST_SCRIPT) $(DESTINSTALLVENDORSCRIPT) \
		$(INST_MAN1DIR) $(DESTINSTALLVENDORMAN1DIR) \
		$(INST_MAN3DIR) $(DESTINSTALLVENDORMAN3DIR)

doc_perl_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLPRIVLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> }.$self->catfile('$(DESTINSTALLARCHLIB)','perllocal.pod').q{

doc_site_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLSITELIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> }.$self->catfile('$(DESTINSTALLARCHLIB)','perllocal.pod').q{

doc_vendor_install ::
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Module" "$(NAME)" \
		"installed into" "$(INSTALLVENDORLIB)" \
		LINKTYPE "$(LINKTYPE)" \
		VERSION "$(VERSION)" \
		EXE_FILES "$(EXE_FILES)" \
		>> }.$self->catfile('$(DESTINSTALLARCHLIB)','perllocal.pod').q{

};

    push @m, q{
uninstall :: uninstall_from_$(INSTALLDIRS)dirs
	$(NOECHO) $(NOOP)

uninstall_from_perldirs ::
	$(NOECHO) $(UNINSTALL) }.$self->catfile('$(PERL_ARCHLIB)','auto','$(FULLEXT)','.packlist').q{

uninstall_from_sitedirs ::
	$(NOECHO) $(UNINSTALL) }.$self->catfile('$(SITEARCHEXP)','auto','$(FULLEXT)','.packlist').q{

uninstall_from_vendordirs ::
	$(NOECHO) $(UNINSTALL) }.$self->catfile('$(VENDORARCHEXP)','auto','$(FULLEXT)','.packlist').q{
};

    join("",@m);
}


sub installbin {
    my($self) = shift;

    return "" unless $self->{EXE_FILES} && ref $self->{EXE_FILES} eq "ARRAY";
    my @exefiles = @{$self->{EXE_FILES}};
    return "" unless @exefiles;

    @exefiles = map vmsify($_), @exefiles if $Is_VMS;

    my %fromto;
    for my $from (@exefiles) {
	my($path)= $self->catfile('$(INST_SCRIPT)', basename($from));

	local($_) = $path; # for backwards compatibility
	my $to = $self->libscan($path);
	print "libscan($from) => '$to'\n" if ($Verbose >=2);

        $to = vmsify($to) if $Is_VMS;
	$fromto{$from} = $to;
    }
    my @to   = values %fromto;

    my @m;
    push(@m, qq{
EXE_FILES = @exefiles

pure_all :: @to
	\$(NOECHO) \$(NOOP)

realclean ::
});

    # realclean can get rather large.
    push @m, map "\t$_\n", $self->split_command('$(RM_F)', @to);
    push @m, "\n";


    # A target for each exe file.
    while (my($from,$to) = each %fromto) {
	last unless defined $from;

	push @m, sprintf <<'MAKE', $to, $from, $to, $from, $to, $to, $to;
%s : %s $(FIRST_MAKEFILE) $(INST_SCRIPT)$(DFSEP).exists $(INST_BIN)$(DFSEP).exists
	$(NOECHO) $(RM_F) %s
	$(CP) %s %s
	$(FIXIN) %s
	-$(NOECHO) $(CHMOD) $(PERM_RWX) %s

MAKE

    }

    join "", @m;
}



sub linkext {
    my($self, %attribs) = @_;
    # LINKTYPE => static or dynamic or ''
    my($linktype) = defined $attribs{LINKTYPE} ?
      $attribs{LINKTYPE} : '$(LINKTYPE)';
    "
linkext :: $linktype
	\$(NOECHO) \$(NOOP)
";
}


sub lsdir {
    my($self) = shift;
    my($dir, $regex) = @_;
    my(@ls);
    my $dh = new DirHandle;
    $dh->open($dir || ".") or return ();
    @ls = $dh->read;
    $dh->close;
    @ls = grep(/$regex/, @ls) if $regex;
    @ls;
}


sub macro {
    my($self,%attribs) = @_;
    my(@m,$key,$val);
    while (($key,$val) = each %attribs){
	last unless defined $key;
	push @m, "$key = $val\n";
    }
    join "", @m;
}


sub makeaperl {
    my($self, %attribs) = @_;
    my($makefilename, $searchdirs, $static, $extra, $perlinc, $target, $tmp, $libperl) =
	@attribs{qw(MAKE DIRS STAT EXTRA INCL TARGET TMP LIBPERL)};
    my(@m);
    push @m, "
MAP_TARGET    = $target
FULLPERL      = $self->{FULLPERL}
";
    return join '', @m if $self->{PARENT};

    my($dir) = join ":", @{$self->{DIR}};

    unless ($self->{MAKEAPERL}) {
	push @m, q{
$(MAP_TARGET) :: static $(MAKE_APERL_FILE)
	$(MAKE) $(USEMAKEFILE) $(MAKE_APERL_FILE) $@

$(MAKE_APERL_FILE) : $(FIRST_MAKEFILE) pm_to_blib
	$(NOECHO) $(ECHO) Writing \"$(MAKE_APERL_FILE)\" for this $(MAP_TARGET)
	$(NOECHO) $(PERLRUNINST) \
		Makefile.PL DIR=}, $dir, q{ \
		MAKEFILE=$(MAKE_APERL_FILE) LINKTYPE=static \
		MAKEAPERL=1 NORECURS=1 CCCDLFLAGS=};

	foreach (@ARGV){
		if( /\s/ ){
			s/=(.*)/='$1'/;
		}
		push @m, " \\\n\t\t$_";
	}
	push @m, "\n";

	return join '', @m;
    }



    my($cccmd, $linkcmd, $lperl);


    $cccmd = $self->const_cccmd($libperl);
    $cccmd =~ s/^CCCMD\s*=\s*//;
    $cccmd =~ s/\$\(INC\)/ "-I$self->{PERL_INC}" /;
    $cccmd .= " $Config{cccdlflags}"
	if ($Config{useshrplib} eq 'true');
    $cccmd =~ s/\(CC\)/\(PERLMAINCC\)/;

    # The front matter of the linkcommand...
    $linkcmd = join ' ', "\$(CC)",
	    grep($_, @Config{qw(ldflags ccdlflags)});
    $linkcmd =~ s/\s+/ /g;
    $linkcmd =~ s,(perl\.exp),\$(PERL_INC)/$1,;

    # Which *.a files could we make use of...
    my %static;
    require File::Find;
    File::Find::find(sub {
	return unless m/\Q$self->{LIB_EXT}\E$/;

        # Skip perl's libraries.
        return if m/^libperl/ or m/^perl\Q$self->{LIB_EXT}\E$/;

	# Skip purified versions of libraries 
        # (e.g., DynaLoader_pure_p1_c0_032.a)
	return if m/_pure_\w+_\w+_\w+\.\w+$/ and -f "$File::Find::dir/.pure";

	if( exists $self->{INCLUDE_EXT} ){
		my $found = 0;
		my $incl;
		my $xx;

		($xx = $File::Find::name) =~ s,.*?/auto/,,s;
		$xx =~ s,/?$_,,;
		$xx =~ s,/,::,g;

		# Throw away anything not explicitly marked for inclusion.
		# DynaLoader is implied.
		foreach $incl ((@{$self->{INCLUDE_EXT}},'DynaLoader')){
			if( $xx eq $incl ){
				$found++;
				last;
			}
		}
		return unless $found;
	}
	elsif( exists $self->{EXCLUDE_EXT} ){
		my $excl;
		my $xx;

		($xx = $File::Find::name) =~ s,.*?/auto/,,s;
		$xx =~ s,/?$_,,;
		$xx =~ s,/,::,g;

		# Throw away anything explicitly marked for exclusion
		foreach $excl (@{$self->{EXCLUDE_EXT}}){
			return if( $xx eq $excl );
		}
	}

	# don't include the installed version of this extension. I
	# leave this line here, although it is not necessary anymore:
	# I patched minimod.PL instead, so that Miniperl.pm won't
	# enclude duplicates

	# Once the patch to minimod.PL is in the distribution, I can
	# drop it
	return if $File::Find::name =~ m:auto/$self->{FULLEXT}/$self->{BASEEXT}$self->{LIB_EXT}\z:;
	use Cwd 'cwd';
	$static{cwd() . "/" . $_}++;
    }, grep( -d $_, @{$searchdirs || []}) );

    # We trust that what has been handed in as argument, will be buildable
    $static = [] unless $static;
    @static{@{$static}} = (1) x @{$static};

    $extra = [] unless $extra && ref $extra eq 'ARRAY';
    for (sort keys %static) {
	next unless /\Q$self->{LIB_EXT}\E\z/;
	$_ = dirname($_) . "/extralibs.ld";
	push @$extra, $_;
    }

    grep(s/^(.*)/"-I$1"/, @{$perlinc || []});

    $target ||= "perl";
    $tmp    ||= ".";

    push @m, "
MAP_LINKCMD   = $linkcmd
MAP_PERLINC   = @{$perlinc || []}
MAP_STATIC    = ",
join(" \\\n\t", reverse sort keys %static), "

MAP_PRELIBS   = $Config{perllibs} $Config{cryptlib}
";

    if (defined $libperl) {
	($lperl = $libperl) =~ s/\$\(A\)/$self->{LIB_EXT}/;
    }
    unless ($libperl && -f $lperl) { # Ilya's code...
	my $dir = $self->{PERL_SRC} || "$self->{PERL_ARCHLIB}/CORE";
	$dir = "$self->{PERL_ARCHLIB}/.." if $self->{UNINSTALLED_PERL};
	$libperl ||= "libperl$self->{LIB_EXT}";
	$libperl   = "$dir/$libperl";
	$lperl   ||= "libperl$self->{LIB_EXT}";
	$lperl     = "$dir/$lperl";

        if (! -f $libperl and ! -f $lperl) {
          # We did not find a static libperl. Maybe there is a shared one?
          if ($Is_SunOS) {
            $lperl  = $libperl = "$dir/$Config{libperl}";
            # SUNOS ld does not take the full path to a shared library
            $libperl = '' if $Is_SunOS4;
          }
        }

	print STDOUT "Warning: $libperl not found
    If you're going to build a static perl binary, make sure perl is installed
    otherwise ignore this warning\n"
		unless (-f $lperl || defined($self->{PERL_SRC}));
    }

    # SUNOS ld does not take the full path to a shared library
    my $llibperl = $libperl ? '$(MAP_LIBPERL)' : '-lperl';

    push @m, "
MAP_LIBPERL = $libperl
LLIBPERL    = $llibperl
";

    push @m, '
$(INST_ARCHAUTODIR)/extralibs.all : $(INST_ARCHAUTODIR)$(DFSEP).exists '.join(" \\\n\t", @$extra).'
	$(NOECHO) $(RM_F)  $@
	$(NOECHO) $(TOUCH) $@
';

    my $catfile;
    foreach $catfile (@$extra){
	push @m, "\tcat $catfile >> \$\@\n";
    }

push @m, "
\$(MAP_TARGET) :: $tmp/perlmain\$(OBJ_EXT) \$(MAP_LIBPERL) \$(MAP_STATIC) \$(INST_ARCHAUTODIR)/extralibs.all
	\$(MAP_LINKCMD) -o \$\@ \$(OPTIMIZE) $tmp/perlmain\$(OBJ_EXT) \$(LDFROM) \$(MAP_STATIC) \$(LLIBPERL) `cat \$(INST_ARCHAUTODIR)/extralibs.all` \$(MAP_PRELIBS)
	\$(NOECHO) \$(ECHO) 'To install the new \"\$(MAP_TARGET)\" binary, call'
	\$(NOECHO) \$(ECHO) '    \$(MAKE) \$(USEMAKEFILE) $makefilename inst_perl MAP_TARGET=\$(MAP_TARGET)'
	\$(NOECHO) \$(ECHO) 'To remove the intermediate files say'
	\$(NOECHO) \$(ECHO) '    \$(MAKE) \$(USEMAKEFILE) $makefilename map_clean'

$tmp/perlmain\$(OBJ_EXT): $tmp/perlmain.c
";
    push @m, "\t".$self->cd($tmp, qq[$cccmd "-I\$(PERL_INC)" perlmain.c])."\n";

    push @m, qq{
$tmp/perlmain.c: $makefilename}, q{
	$(NOECHO) $(ECHO) Writing $@
	$(NOECHO) $(PERL) $(MAP_PERLINC) "-MExtUtils::Miniperl" \\
		-e "writemain(grep s#.*/auto/##s, split(q| |, q|$(MAP_STATIC)|))" > $@t && $(MV) $@t $@

};
    push @m, "\t", q{$(NOECHO) $(PERL) $(INSTALLSCRIPT)/fixpmain
} if (defined (&Dos::UseLFN) && Dos::UseLFN()==0);


    push @m, q{
doc_inst_perl :
	$(NOECHO) $(ECHO) Appending installation info to $(DESTINSTALLARCHLIB)/perllocal.pod
	-$(NOECHO) $(MKPATH) $(DESTINSTALLARCHLIB)
	-$(NOECHO) $(DOC_INSTALL) \
		"Perl binary" "$(MAP_TARGET)" \
		MAP_STATIC "$(MAP_STATIC)" \
		MAP_EXTRA "`cat $(INST_ARCHAUTODIR)/extralibs.all`" \
		MAP_LIBPERL "$(MAP_LIBPERL)" \
		>> }.$self->catfile('$(DESTINSTALLARCHLIB)','perllocal.pod').q{

};

    push @m, q{
inst_perl : pure_inst_perl doc_inst_perl

pure_inst_perl : $(MAP_TARGET)
	}.$self->{CP}.q{ $(MAP_TARGET) }.$self->catfile('$(DESTINSTALLBIN)','$(MAP_TARGET)').q{

clean :: map_clean

map_clean :
	}.$self->{RM_F}.qq{ $tmp/perlmain\$(OBJ_EXT) $tmp/perlmain.c \$(MAP_TARGET) $makefilename \$(INST_ARCHAUTODIR)/extralibs.all
};

    join '', @m;
}


sub makefile {
    my($self) = shift;
    my $m;
    # We do not know what target was originally specified so we
    # must force a manual rerun to be sure. But as it should only
    # happen very rarely it is not a significant problem.
    $m = '
$(OBJECT) : $(FIRST_MAKEFILE)

' if $self->{OBJECT};

    my $newer_than_target = $Is_VMS ? '$(MMS$SOURCE_LIST)' : '$?';
    my $mpl_args = join " ", map qq["$_"], @ARGV;

    $m .= sprintf <<'MAKE_FRAG', $newer_than_target, $mpl_args;
$(FIRST_MAKEFILE) : Makefile.PL $(CONFIGDEP)
	$(NOECHO) $(ECHO) "Makefile out-of-date with respect to %s"
	$(NOECHO) $(ECHO) "Cleaning current config before rebuilding Makefile..."
	-$(NOECHO) $(RM_F) $(MAKEFILE_OLD)
	-$(NOECHO) $(MV)   $(FIRST_MAKEFILE) $(MAKEFILE_OLD)
	- $(MAKE) $(USEMAKEFILE) $(MAKEFILE_OLD) clean $(DEV_NULL)
	$(PERLRUN) Makefile.PL %s
	$(NOECHO) $(ECHO) "==> Your Makefile has been rebuilt. <=="
	$(NOECHO) $(ECHO) "==> Please rerun the $(MAKE) command.  <=="
	false

MAKE_FRAG

    return $m;
}



sub maybe_command {
    my($self,$file) = @_;
    return $file if -x $file && ! -d $file;
    return;
}



sub needs_linking {
    my($self) = shift;
    my($child,$caller);
    $caller = (caller(0))[3];
    confess("needs_linking called too early") if 
      $caller =~ /^ExtUtils::MakeMaker::/;
    return $self->{NEEDS_LINKING} if defined $self->{NEEDS_LINKING};
    if ($self->has_link_code or $self->{MAKEAPERL}){
	$self->{NEEDS_LINKING} = 1;
	return 1;
    }
    foreach $child (keys %{$self->{CHILDREN}}) {
	if ($self->{CHILDREN}->{$child}->needs_linking) {
	    $self->{NEEDS_LINKING} = 1;
	    return 1;
	}
    }
    return $self->{NEEDS_LINKING} = 0;
}



sub parse_abstract {
    my($self,$parsefile) = @_;
    my $result;
    local *FH;
    local $/ = "\n";
    open(FH,$parsefile) or die "Could not open '$parsefile': $!";
    my $inpod = 0;
    my $package = $self->{DISTNAME};
    $package =~ s/-/::/g;
    while (<FH>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if !$inpod;
        chop;
        next unless /^($package\s-\s)(.*)/;
        $result = $2;
        last;
    }
    close FH;
    return $result;
}


sub parse_version {
    my($self,$parsefile) = @_;
    my $result;
    local *FH;
    local $/ = "\n";
    local $_;
    open(FH,$parsefile) or die "Could not open '$parsefile': $!";
    my $inpod = 0;
    while (<FH>) {
        $inpod = /^=(?!cut)/ ? 1 : /^=cut/ ? 0 : $inpod;
        next if $inpod || /^\s*#/;
        chop;
        next unless /(?<!\\)([\$*])(([\w\:\']*)\bVERSION)\b.*\=/;
        my $eval = qq{
            package ExtUtils::MakeMaker::_version;
            no strict;
            BEGIN { eval {
                # Ensure any version() routine which might have leaked
                # into this package has been deleted.  Interferes with
                # version->import()
                undef *version;
                require version;
                "version"->import;
            } }

            local $1$2;
            \$$2=undef;
            do {
                $_
            }; \$$2
        };
        local $^W = 0;
        $result = eval($eval);
        warn "Could not eval '$eval' in $parsefile: $@" if $@;
        last;
    }
    close FH;

    $result = "undef" unless defined $result;
    return $result;
}



sub pasthru {
    my($self) = shift;
    my(@m,$key);

    my(@pasthru);
    my($sep) = $Is_VMS ? ',' : '';
    $sep .= "\\\n\t";

    foreach $key (qw(LIB LIBPERL_A LINKTYPE OPTIMIZE
                     PREFIX INSTALL_BASE)
                 ) 
    {
        next unless defined $self->{$key};
	push @pasthru, "$key=\"\$($key)\"";
    }

    foreach $key (qw(DEFINE INC)) {
        next unless defined $self->{$key};
	push @pasthru, "PASTHRU_$key=\"\$(PASTHRU_$key)\"";
    }

    push @m, "\nPASTHRU = ", join ($sep, @pasthru), "\n";
    join "", @m;
}


sub perl_script {
    my($self,$file) = @_;
    return $file if -r $file && -f _;
    return;
}


sub perldepend {
    my($self) = shift;
    my(@m);

    my $make_config = $self->cd('$(PERL_SRC)', '$(MAKE) lib/Config.pm');

    push @m, sprintf <<'MAKE_FRAG', $make_config if $self->{PERL_SRC};
$(PERL_INC)/config.h: $(PERL_SRC)/config.sh
	-$(NOECHO) $(ECHO) "Warning: $(PERL_INC)/config.h out of date with $(PERL_SRC)/config.sh"; false

$(PERL_ARCHLIB)/Config.pm: $(PERL_SRC)/config.sh
	$(NOECHO) $(ECHO) "Warning: $(PERL_ARCHLIB)/Config.pm may be out of date with $(PERL_SRC)/config.sh"
	%s
MAKE_FRAG

    return join "", @m unless $self->needs_linking;

    push @m, q{
PERL_HDRS = \
	$(PERL_INC)/EXTERN.h		\
	$(PERL_INC)/INTERN.h		\
	$(PERL_INC)/XSUB.h		\
	$(PERL_INC)/av.h		\
	$(PERL_INC)/cc_runtime.h	\
	$(PERL_INC)/config.h		\
	$(PERL_INC)/cop.h		\
	$(PERL_INC)/cv.h		\
	$(PERL_INC)/dosish.h		\
	$(PERL_INC)/embed.h		\
	$(PERL_INC)/embedvar.h		\
	$(PERL_INC)/fakethr.h		\
	$(PERL_INC)/form.h		\
	$(PERL_INC)/gv.h		\
	$(PERL_INC)/handy.h		\
	$(PERL_INC)/hv.h		\
	$(PERL_INC)/intrpvar.h		\
	$(PERL_INC)/iperlsys.h		\
	$(PERL_INC)/keywords.h		\
	$(PERL_INC)/mg.h		\
	$(PERL_INC)/nostdio.h		\
	$(PERL_INC)/op.h		\
	$(PERL_INC)/opcode.h		\
	$(PERL_INC)/patchlevel.h	\
	$(PERL_INC)/perl.h		\
	$(PERL_INC)/perlio.h		\
	$(PERL_INC)/perlsdio.h		\
	$(PERL_INC)/perlsfio.h		\
	$(PERL_INC)/perlvars.h		\
	$(PERL_INC)/perly.h		\
	$(PERL_INC)/pp.h		\
	$(PERL_INC)/pp_proto.h		\
	$(PERL_INC)/proto.h		\
	$(PERL_INC)/regcomp.h		\
	$(PERL_INC)/regexp.h		\
	$(PERL_INC)/regnodes.h		\
	$(PERL_INC)/scope.h		\
	$(PERL_INC)/sv.h		\
	$(PERL_INC)/thread.h		\
	$(PERL_INC)/unixish.h		\
	$(PERL_INC)/util.h

$(OBJECT) : $(PERL_HDRS)
} if $self->{OBJECT};

    push @m, join(" ", values %{$self->{XS}})." : \$(XSUBPPDEPS)\n"  if %{$self->{XS}};

    join "\n", @m;
}



sub perm_rw {
    return shift->{PERM_RW};
}


sub perm_rwx {
    return shift->{PERM_RWX};
}


sub pm_to_blib {
    my $self = shift;
    my($autodir) = $self->catdir('$(INST_LIB)','auto');
    my $r = q{
pm_to_blib : $(TO_INST_PM)
};

    my $pm_to_blib = $self->oneliner(<<CODE, ['-MExtUtils::Install']);
pm_to_blib({\@ARGV}, '$autodir', '\$(PM_FILTER)')
CODE

    my @cmds = $self->split_command($pm_to_blib, %{$self->{PM}});

    $r .= join '', map { "\t\$(NOECHO) $_\n" } @cmds;
    $r .= qq{\t\$(NOECHO) \$(TOUCH) pm_to_blib\n};

    return $r;
}


sub post_constants{
    "";
}


sub post_initialize {
    "";
}


sub postamble {
    "";
}


sub ppd {
    my($self) = @_;

    my ($pack_ver) = join ",", (split (/\./, $self->{VERSION}), (0)x4)[0..3];

    my $abstract = $self->{ABSTRACT} || '';
    $abstract =~ s/\n/\\n/sg;
    $abstract =~ s/</&lt;/g;
    $abstract =~ s/>/&gt;/g;

    my $author = $self->{AUTHOR} || '';
    $author =~ s/</&lt;/g;
    $author =~ s/>/&gt;/g;

    my $ppd_xml = sprintf <<'PPD_HTML', $pack_ver, $abstract, $author;
<SOFTPKG NAME="$(DISTNAME)" VERSION="%s">
    <TITLE>$(DISTNAME)</TITLE>
    <ABSTRACT>%s</ABSTRACT>
    <AUTHOR>%s</AUTHOR>
PPD_HTML

    $ppd_xml .= "    <IMPLEMENTATION>\n";
    foreach my $prereq (sort keys %{$self->{PREREQ_PM}}) {
        my $pre_req = $prereq;
        $pre_req =~ s/::/-/g;
        my ($dep_ver) = join ",", (split (/\./, $self->{PREREQ_PM}{$prereq}), 
                                  (0) x 4) [0 .. 3];
        $ppd_xml .= sprintf <<'PPD_OUT', $pre_req, $dep_ver;
        <DEPENDENCY NAME="%s" VERSION="%s" />
PPD_OUT

    }

    my $archname = $Config{archname};
    if ($] >= 5.008) {
        # archname did not change from 5.6 to 5.8, but those versions may
        # not be not binary compatible so now we append the part of the
        # version that changes when binary compatibility may change
        $archname .= "-". substr($Config{version},0,3);
    }
    $ppd_xml .= sprintf <<'PPD_OUT', $archname;
        <OS NAME="$(OSNAME)" />
        <ARCHITECTURE NAME="%s" />
PPD_OUT

    if ($self->{PPM_INSTALL_SCRIPT}) {
        if ($self->{PPM_INSTALL_EXEC}) {
            $ppd_xml .= sprintf qq{        <INSTALL EXEC="%s">%s</INSTALL>\n},
                  $self->{PPM_INSTALL_EXEC}, $self->{PPM_INSTALL_SCRIPT};
        }
        else {
            $ppd_xml .= sprintf qq{        <INSTALL>%s</INSTALL>\n}, 
                  $self->{PPM_INSTALL_SCRIPT};
        }
    }

    my ($bin_location) = $self->{BINARY_LOCATION} || '';
    $bin_location =~ s/\\/\\\\/g;

    $ppd_xml .= sprintf <<'PPD_XML', $bin_location;
        <CODEBASE HREF="%s" />
    </IMPLEMENTATION>
</SOFTPKG>
PPD_XML

    my @ppd_cmds = $self->echo($ppd_xml, '$(DISTNAME).ppd');

    return sprintf <<'PPD_OUT', join "\n\t", @ppd_cmds;
ppd :
	%s
PPD_OUT

}


sub prefixify {
    my($self,$var,$sprefix,$rprefix,$default) = @_;

    my $path = $self->{uc $var} || 
               $Config_Override{lc $var} || $Config{lc $var} || '';

    $rprefix .= '/' if $sprefix =~ m|/$|;

    print STDERR "  prefixify $var => $path\n" if $Verbose >= 2;
    print STDERR "    from $sprefix to $rprefix\n" if $Verbose >= 2;

    if( $self->{ARGS}{PREFIX} && $self->file_name_is_absolute($path) && 
        $path !~ s{^\Q$sprefix\E\b}{$rprefix}s ) 
    {

        print STDERR "    cannot prefix, using default.\n" if $Verbose >= 2;
        print STDERR "    no default!\n" if !$default && $Verbose >= 2;

        $path = $self->catdir($rprefix, $default) if $default;
    }

    print "    now $path\n" if $Verbose >= 2;
    return $self->{uc $var} = $path;
}



sub processPL {
    my $self = shift;
    my $pl_files = $self->{PL_FILES};

    return "" unless $pl_files;

    my $m = '';
    foreach my $plfile (sort keys %$pl_files) {
        my $list = ref($pl_files->{$plfile})
                     ?  $pl_files->{$plfile}
		     : [$pl_files->{$plfile}];

	foreach my $target (@$list) {
            if( $Is_VMS ) {
                $plfile = vmsify($self->eliminate_macros($plfile));
                $target = vmsify($self->eliminate_macros($target));
            }

	    # Normally a .PL file runs AFTER pm_to_blib so it can have
	    # blib in its @INC and load the just built modules.  BUT if
	    # the generated module is something in $(TO_INST_PM) which
	    # pm_to_blib depends on then it can't depend on pm_to_blib
	    # else we have a dependency loop.
	    my $pm_dep;
	    my $perlrun;
	    if( defined $self->{PM}{$target} ) {
		$pm_dep  = '';
		$perlrun = 'PERLRUN';
	    }
	    else {
		$pm_dep  = 'pm_to_blib';
		$perlrun = 'PERLRUNINST';
	    }

            $m .= <<MAKE_FRAG;

all :: $target
	\$(NOECHO) \$(NOOP)

$target :: $plfile $pm_dep
	\$($perlrun) $plfile $target
MAKE_FRAG

	}
    }

    return $m;
}


sub quote_paren {
    my $arg = shift;
    $arg =~ s{\$\((.+?)\)}{\$\\\\($1\\\\)}g;	# protect $(...)
    $arg =~ s{(?<!\\)([()])}{\\$1}g;		# quote unprotected
    $arg =~ s{\$\\\\\((.+?)\\\\\)}{\$($1)}g;	# unprotect $(...)
    return $arg;
}


sub replace_manpage_separator {
    my($self,$man) = @_;

    $man =~ s,/+,::,g;
    return $man;
}



sub cd {
    my($self, $dir, @cmds) = @_;

    # No leading tab and no trailing newline makes for easier embedding
    my $make_frag = join "\n\t", map { "cd $dir && $_" } @cmds;

    return $make_frag;
}


sub oneliner {
    my($self, $cmd, $switches) = @_;
    $switches = [] unless defined $switches;

    # Strip leading and trailing newlines
    $cmd =~ s{^\n+}{};
    $cmd =~ s{\n+$}{};

    my @cmds = split /\n/, $cmd;
    $cmd = join " \n\t  -e ", map $self->quote_literal($_), @cmds;
    $cmd = $self->escape_newlines($cmd);

    $switches = join ' ', @$switches;

    return qq{\$(ABSPERLRUN) $switches -e $cmd --};   
}



sub quote_literal {
    my($self, $text) = @_;

    # I think all we have to quote is single quotes and I think
    # this is a safe way to do it.
    $text =~ s{'}{'\\''}g;

    return "'$text'";
}



sub escape_newlines {
    my($self, $text) = @_;

    $text =~ s{\n}{\\\n}g;

    return $text;
}



sub max_exec_len {
    my $self = shift;

    if (!defined $self->{_MAX_EXEC_LEN}) {
        if (my $arg_max = eval { require POSIX;  &POSIX::ARG_MAX }) {
            $self->{_MAX_EXEC_LEN} = $arg_max;
        }
        else {      # POSIX minimum exec size
            $self->{_MAX_EXEC_LEN} = 4096;
        }
    }

    return $self->{_MAX_EXEC_LEN};
}



sub static {

    my($self) = shift;
    '
static :: $(FIRST_MAKEFILE) $(INST_STATIC)
	$(NOECHO) $(NOOP)
';
}


sub static_lib {
    my($self) = @_;
    return '' unless $self->has_link_code;

    my(@m);
    push(@m, <<'END');

$(INST_STATIC) : $(OBJECT) $(MYEXTLIB) $(INST_ARCHAUTODIR)$(DFSEP).exists
	$(RM_RF) $@
END

    # If this extension has its own library (eg SDBM_File)
    # then copy that to $(INST_STATIC) and add $(OBJECT) into it.
    push(@m, <<'MAKE_FRAG') if $self->{MYEXTLIB};
	$(CP) $(MYEXTLIB) $@
MAKE_FRAG

    my $ar; 
    if (exists $self->{FULL_AR} && -x $self->{FULL_AR}) {
        # Prefer the absolute pathed ar if available so that PATH
        # doesn't confuse us.  Perl itself is built with the full_ar.  
        $ar = 'FULL_AR';
    } else {
        $ar = 'AR';
    }
    push @m, sprintf <<'MAKE_FRAG', $ar;
	$(%s) $(AR_STATIC_ARGS) $@ $(OBJECT) && $(RANLIB) $@
	$(CHMOD) $(PERM_RWX) $@
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" > $(INST_ARCHAUTODIR)/extralibs.ld
MAKE_FRAG

    # Old mechanism - still available:
    push @m, <<'MAKE_FRAG' if $self->{PERL_SRC} && $self->{EXTRALIBS};
	$(NOECHO) $(ECHO) "$(EXTRALIBS)" >> $(PERL_SRC)/ext.libs
MAKE_FRAG

    join('', @m);
}


sub staticmake {
    my($self, %attribs) = @_;
    my(@static);

    my(@searchdirs)=($self->{PERL_ARCHLIB}, $self->{SITEARCHEXP},  $self->{INST_ARCHLIB});

    # And as it's not yet built, we add the current extension
    # but only if it has some C code (or XS code, which implies C code)
    if (@{$self->{C}}) {
	@static = $self->catfile($self->{INST_ARCHLIB},
				 "auto",
				 $self->{FULLEXT},
				 "$self->{BASEEXT}$self->{LIB_EXT}"
				);
    }

    # Either we determine now, which libraries we will produce in the
    # subdirectories or we do it at runtime of the make.

    # We could ask all subdir objects, but I cannot imagine, why it
    # would be necessary.

    # Instead we determine all libraries for the new perl at
    # runtime.
    my(@perlinc) = ($self->{INST_ARCHLIB}, $self->{INST_LIB}, $self->{PERL_ARCHLIB}, $self->{PERL_LIB});

    $self->makeaperl(MAKE	=> $self->{MAKEFILE},
		     DIRS	=> \@searchdirs,
		     STAT	=> \@static,
		     INCL	=> \@perlinc,
		     TARGET	=> $self->{MAP_TARGET},
		     TMP	=> "",
		     LIBPERL	=> $self->{LIBPERL_A}
		    );
}


sub subdir_x {
    my($self, $subdir) = @_;

    my $subdir_cmd = $self->cd($subdir, 
      '$(MAKE) $(USEMAKEFILE) $(FIRST_MAKEFILE) all $(PASTHRU)'
    );
    return sprintf <<'EOT', $subdir_cmd;

subdirs ::
	$(NOECHO) %s
EOT

}


sub subdirs {
    my($self) = shift;
    my(@m,$dir);
    # This method provides a mechanism to automatically deal with
    # subdirectories containing further Makefile.PL scripts.
    # It calls the subdir_x() method for each subdirectory.
    foreach $dir (@{$self->{DIR}}){
	push(@m, $self->subdir_x($dir));
    }
    if (@m){
	unshift(@m, "

");
    } else {
	push(@m, "\n# none")
    }
    join('',@m);
}


sub test {

    my($self, %attribs) = @_;
    my $tests = $attribs{TESTS} || '';
    if (!$tests && -d 't') {
        $tests = $self->find_tests;
    }
    # note: 'test.pl' name is also hardcoded in init_dirscan()
    my(@m);
    push(@m,"
TEST_VERBOSE=0
TEST_TYPE=test_\$(LINKTYPE)
TEST_FILE = test.pl
TEST_FILES = $tests
TESTDB_SW = -d

testdb :: testdb_\$(LINKTYPE)

test :: \$(TEST_TYPE) subdirs-test

subdirs-test ::
	\$(NOECHO) \$(NOOP)

");

    foreach my $dir (@{ $self->{DIR} }) {
        my $test = $self->cd($dir, '$(MAKE) test $(PASTHRU)');

        push @m, <<END
subdirs-test ::
	\$(NOECHO) $test

END
    }

    push(@m, "\t\$(NOECHO) \$(ECHO) 'No tests defined for \$(NAME) extension.'\n")
	unless $tests or -f "test.pl" or @{$self->{DIR}};
    push(@m, "\n");

    push(@m, "test_dynamic :: pure_all\n");
    push(@m, $self->test_via_harness('$(FULLPERLRUN)', '$(TEST_FILES)')) 
      if $tests;
    push(@m, $self->test_via_script('$(FULLPERLRUN)', '$(TEST_FILE)')) 
      if -f "test.pl";
    push(@m, "\n");

    push(@m, "testdb_dynamic :: pure_all\n");
    push(@m, $self->test_via_script('$(FULLPERLRUN) $(TESTDB_SW)', 
                                    '$(TEST_FILE)'));
    push(@m, "\n");

    # Occasionally we may face this degenerate target:
    push @m, "test_ : test_dynamic\n\n";

    if ($self->needs_linking()) {
	push(@m, "test_static :: pure_all \$(MAP_TARGET)\n");
	push(@m, $self->test_via_harness('./$(MAP_TARGET)', '$(TEST_FILES)')) if $tests;
	push(@m, $self->test_via_script('./$(MAP_TARGET)', '$(TEST_FILE)')) if -f "test.pl";
	push(@m, "\n");
	push(@m, "testdb_static :: pure_all \$(MAP_TARGET)\n");
	push(@m, $self->test_via_script('./$(MAP_TARGET) $(TESTDB_SW)', '$(TEST_FILE)'));
	push(@m, "\n");
    } else {
	push @m, "test_static :: test_dynamic\n";
	push @m, "testdb_static :: testdb_dynamic\n";
    }
    join("", @m);
}


sub test_via_harness {
    my($self, $perl, $tests) = @_;
    return $self->SUPER::test_via_harness("PERL_DL_NONLAZY=1 $perl", $tests);
}


sub test_via_script {
    my($self, $perl, $script) = @_;
    return $self->SUPER::test_via_script("PERL_DL_NONLAZY=1 $perl", $script);
}



sub tools_other {
    my($self) = shift;
    my @m;

    # We set PM_FILTER as late as possible so it can see all the earlier
    # on macro-order sensitive makes such as nmake.
    for my $tool (qw{ SHELL CHMOD CP MV NOOP NOECHO RM_F RM_RF TEST_F TOUCH 
                      UMASK_NULL DEV_NULL MKPATH EQUALIZE_TIMESTAMP 
                      ECHO ECHO_N
                      UNINST VERBINST
                      MOD_INSTALL DOC_INSTALL UNINSTALL
                      WARN_IF_OLD_PACKLIST
		      MACROSTART MACROEND
                      USEMAKEFILE
                      PM_FILTER
                      FIXIN
                    } ) 
    {
        next unless defined $self->{$tool};
        push @m, "$tool = $self->{$tool}\n";
    }

    return join "", @m;
}


sub tool_xsubpp {
    my($self) = shift;
    return "" unless $self->needs_linking;

    my $xsdir;
    my @xsubpp_dirs = @INC;

    # Make sure we pick up the new xsubpp if we're building perl.
    unshift @xsubpp_dirs, $self->{PERL_LIB} if $self->{PERL_CORE};

    foreach my $dir (@xsubpp_dirs) {
        $xsdir = $self->catdir($dir, 'ExtUtils');
        if( -r $self->catfile($xsdir, "xsubpp") ) {
            last;
        }
    }

    my $tmdir   = File::Spec->catdir($self->{PERL_LIB},"ExtUtils");
    my(@tmdeps) = $self->catfile($tmdir,'typemap');
    if( $self->{TYPEMAPS} ){
	my $typemap;
	foreach $typemap (@{$self->{TYPEMAPS}}){
		if( ! -f  $typemap ){
			warn "Typemap $typemap not found.\n";
		}
		else{
			push(@tmdeps,  $typemap);
		}
	}
    }
    push(@tmdeps, "typemap") if -f "typemap";
    my(@tmargs) = map("-typemap $_", @tmdeps);
    if( exists $self->{XSOPT} ){
 	unshift( @tmargs, $self->{XSOPT} );
    }

    if ($Is_VMS                          &&
        $Config{'ldflags'}               && 
        $Config{'ldflags'} =~ m!/Debug!i &&
        (!exists($self->{XSOPT}) || $self->{XSOPT} !~ /linenumbers/)
       ) 
    {
        unshift(@tmargs,'-nolinenumbers');
    }


    $self->{XSPROTOARG} = "" unless defined $self->{XSPROTOARG};

    return qq{
XSUBPPDIR = $xsdir
XSUBPP = \$(XSUBPPDIR)\$(DFSEP)xsubpp
XSUBPPRUN = \$(PERLRUN) \$(XSUBPP)
XSPROTOARG = $self->{XSPROTOARG}
XSUBPPDEPS = @tmdeps \$(XSUBPP)
XSUBPPARGS = @tmargs
XSUBPP_EXTRA_ARGS = 
};
};



sub all_target {
    my $self = shift;

    return <<'MAKE_EXT';
all :: pure_all manifypods
	$(NOECHO) $(NOOP)
MAKE_EXT
}


sub top_targets {

    my($self) = shift;
    my(@m);

    push @m, $self->all_target, "\n" unless $self->{SKIPHASH}{'all'};

    push @m, '
pure_all :: config pm_to_blib subdirs linkext
	$(NOECHO) $(NOOP)

subdirs :: $(MYEXTLIB)
	$(NOECHO) $(NOOP)

config :: $(FIRST_MAKEFILE) blibdirs
	$(NOECHO) $(NOOP)
';

    push @m, '
$(O_FILES): $(H_FILES)
' if @{$self->{O_FILES} || []} && @{$self->{H} || []};

    push @m, q{
help :
	perldoc ExtUtils::MakeMaker
};

    join('',@m);
}


sub writedoc {
    my($self,$what,$name,@attribs)=@_;
    my $time = localtime;
    print "=head2 $time: $what C<$name>\n\n=over 4\n\n=item *\n\n";
    print join "\n\n=item *\n\n", map("C<$_>",@attribs);
    print "\n\n=back\n\n";
}


sub xs_c {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs.c:
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $(XSUBPP_EXTRA_ARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.c
';
}


sub xs_cpp {
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs.cpp:
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.cpp
';
}


sub xs_o {	# many makes are too dumb to use xs_c then c_o
    my($self) = shift;
    return '' unless $self->needs_linking();
    '
.xs$(OBJ_EXT):
	$(XSUBPPRUN) $(XSPROTOARG) $(XSUBPPARGS) $*.xs > $*.xsc && $(MV) $*.xsc $*.c
	$(CCCMD) $(CCCDLFLAGS) "-I$(PERL_INC)" $(PASTHRU_DEFINE) $(DEFINE) $*.c
';
}


1;


__END__
