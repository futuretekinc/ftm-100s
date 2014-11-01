package ExtUtils::MM_Any;

use strict;
use vars qw($VERSION @ISA);
$VERSION = '6.42';

use Carp;
use File::Spec;
BEGIN { @ISA = qw(File::Spec); }

use ExtUtils::MakeMaker qw($Verbose);

use ExtUtils::MakeMaker::Config;


my $Curdir  = __PACKAGE__->curdir;
my $Rootdir = __PACKAGE__->rootdir;
my $Updir   = __PACKAGE__->updir;



sub os_flavor_is {
    my $self = shift;
    my %flavors = map { ($_ => 1) } $self->os_flavor;
    return (grep { $flavors{$_} } @_) ? 1 : 0;
}



sub split_command {
    my($self, $cmd, @args) = @_;

    my @cmds = ();
    return(@cmds) unless @args;

    # If the command was given as a here-doc, there's probably a trailing
    # newline.
    chomp $cmd;

    # set aside 20% for macro expansion.
    my $len_left = int($self->max_exec_len * 0.80);
    $len_left -= length $self->_expand_macros($cmd);

    do {
        my $arg_str = '';
        my @next_args;
        while( @next_args = splice(@args, 0, 2) ) {
            # Two at a time to preserve pairs.
            my $next_arg_str = "\t  ". join ' ', @next_args, "\n";

            if( !length $arg_str ) {
                $arg_str .= $next_arg_str
            }
            elsif( length($arg_str) + length($next_arg_str) > $len_left ) {
                unshift @args, @next_args;
                last;
            }
            else {
                $arg_str .= $next_arg_str;
            }
        }
        chop $arg_str;

        push @cmds, $self->escape_newlines("$cmd \n$arg_str");
    } while @args;

    return @cmds;
}


sub _expand_macros {
    my($self, $cmd) = @_;

    $cmd =~ s{\$\((\w+)\)}{
        defined $self->{$1} ? $self->{$1} : "\$($1)"
    }e;
    return $cmd;
}



sub echo {
    my($self, $text, $file, $appending) = @_;
    $appending ||= 0;

    my @cmds = map { '$(NOECHO) $(ECHO) '.$self->quote_literal($_) } 
               split /\n/, $text;
    if( $file ) {
        my $redirect = $appending ? '>>' : '>';
        $cmds[0] .= " $redirect $file";
        $_ .= " >> $file" foreach @cmds[1..$#cmds];
    }

    return @cmds;
}



sub wraplist {
    my $self = shift;
    return join " \\\n\t", @_;
}



sub maketext_filter { return $_[1] }



sub make {
    my $self = shift;

    my $make = lc $self->{MAKE};

    # Truncate anything like foomake6 to just foomake.
    $make =~ s/^(\w+make).*/$1/;

    # Turn gnumake into gmake.
    $make =~ s/^gnu/g/;

    return $make;
}



sub all_target {
    my $self = shift;

    return <<'MAKE_EXT';
all :: pure_all
	$(NOECHO) $(NOOP)
MAKE_EXT

}



sub blibdirs_target {
    my $self = shift;

    my @dirs = map { uc "\$(INST_$_)" } qw(libdir archlib
                                           autodir archautodir
                                           bin script
                                           man1dir man3dir
                                          );

    my @exists = map { $_.'$(DFSEP).exists' } @dirs;

    my $make = sprintf <<'MAKE', join(' ', @exists);
blibdirs : %s
	$(NOECHO) $(NOOP)

blibdirs.ts : blibdirs
	$(NOECHO) $(NOOP)

MAKE

    $make .= $self->dir_target(@dirs);

    return $make;
}



sub clean {

    my($self, %attribs) = @_;
    my @m;
    push(@m, '

clean :: clean_subdirs
');

    my @files = values %{$self->{XS}}; # .c files from *.xs files
    my @dirs  = qw(blib);

    # Normally these are all under blib but they might have been
    # redefined.
    # XXX normally this would be a good idea, but the Perl core sets
    # INST_LIB = ../../lib rather than actually installing the files.
    # So a "make clean" in an ext/ directory would blow away lib.
    # Until the core is adjusted let's leave this out.
                  

    if( $attribs{FILES} ) {
        # Use @dirs because we don't know what's in here.
        push @dirs, ref $attribs{FILES}                ?
                        @{$attribs{FILES}}             :
                        split /\s+/, $attribs{FILES}   ;
    }

    push(@files, qw[$(MAKE_APERL_FILE) 
                    perlmain.c tmon.out mon.out so_locations 
                    blibdirs.ts pm_to_blib pm_to_blib.ts
                    *$(OBJ_EXT) *$(LIB_EXT) perl.exe perl perl$(EXE_EXT)
                    $(BOOTSTRAP) $(BASEEXT).bso
                    $(BASEEXT).def lib$(BASEEXT).def
                    $(BASEEXT).exp $(BASEEXT).x
                   ]);

    push(@files, $self->catfile('$(INST_ARCHAUTODIR)','extralibs.all'));
    push(@files, $self->catfile('$(INST_ARCHAUTODIR)','extralibs.ld'));

    # core files
    push(@files, qw[core core.*perl.*.? *perl.core]);
    push(@files, map { "core." . "[0-9]"x$_ } (1..5));

    # OS specific things to clean up.  Use @dirs since we don't know
    # what might be in here.
    push @dirs, $self->extra_clean_files;

    # Occasionally files are repeated several times from different sources
    { my(%f) = map { ($_ => 1) } @files; @files = keys %f; }
    { my(%d) = map { ($_ => 1) } @dirs;  @dirs  = keys %d; }

    push @m, map "\t$_\n", $self->split_command('- $(RM_F)',  @files);
    push @m, map "\t$_\n", $self->split_command('- $(RM_RF)', @dirs);

    # Leave Makefile.old around for realclean
    push @m, <<'MAKE';
	- $(MV) $(FIRST_MAKEFILE) $(MAKEFILE_OLD) $(DEV_NULL)
MAKE

    push(@m, "\t$attribs{POSTOP}\n")   if $attribs{POSTOP};

    join("", @m);
}



sub clean_subdirs_target {
    my($self) = shift;

    # No subdirectories, no cleaning.
    return <<'NOOP_FRAG' unless @{$self->{DIR}};
clean_subdirs :
	$(NOECHO) $(NOOP)
NOOP_FRAG


    my $clean = "clean_subdirs :\n";

    for my $dir (@{$self->{DIR}}) {
        my $subclean = $self->oneliner(sprintf <<'CODE', $dir);
chdir '%s';  system '$(MAKE) clean' if -f '$(FIRST_MAKEFILE)';
CODE

        $clean .= "\t$subclean\n";
    }

    return $clean;
}



sub dir_target {
    my($self, @dirs) = @_;

    my $make = '';
    foreach my $dir (@dirs) {
        $make .= sprintf <<'MAKE', ($dir) x 7;
%s$(DFSEP).exists :: Makefile.PL
	$(NOECHO) $(MKPATH) %s
	$(NOECHO) $(CHMOD) 755 %s
	$(NOECHO) $(TOUCH) %s$(DFSEP).exists

MAKE

    }

    return $make;
}



*dist_dir = *distdir;

sub distdir {
    my($self) = shift;

    my $meta_target = $self->{NO_META} ? '' : 'distmeta';
    my $sign_target = !$self->{SIGN}   ? '' : 'distsignature';

    return sprintf <<'MAKE_FRAG', $meta_target, $sign_target;
create_distdir :
	$(RM_RF) $(DISTVNAME)
	$(PERLRUN) "-MExtUtils::Manifest=manicopy,maniread" \
		-e "manicopy(maniread(),'$(DISTVNAME)', '$(DIST_CP)');"

distdir : create_distdir %s %s
	$(NOECHO) $(NOOP)

MAKE_FRAG

}



sub dist_test {
    my($self) = shift;

    my $mpl_args = join " ", map qq["$_"], @ARGV;

    my $test = $self->cd('$(DISTVNAME)',
                         '$(ABSPERLRUN) Makefile.PL '.$mpl_args,
                         '$(MAKE) $(PASTHRU)',
                         '$(MAKE) test $(PASTHRU)'
                        );

    return sprintf <<'MAKE_FRAG', $test;
disttest : distdir
	%s

MAKE_FRAG


}



sub dynamic {

    my($self) = shift;
    '
dynamic :: $(FIRST_MAKEFILE) $(INST_DYNAMIC) $(INST_BOOT)
	$(NOECHO) $(NOOP)
';
}



sub makemakerdflt_target {
    return <<'MAKE_FRAG';
makemakerdflt : all
	$(NOECHO) $(NOOP)
MAKE_FRAG

}



sub manifypods_target {
    my($self) = shift;

    my $man1pods      = '';
    my $man3pods      = '';
    my $dependencies  = '';

    # populate manXpods & dependencies:
    foreach my $name (keys %{$self->{MAN1PODS}}, keys %{$self->{MAN3PODS}}) {
        $dependencies .= " \\\n\t$name";
    }

    my $manify = <<END;
manifypods : pure_all $dependencies
END

    my @man_cmds;
    foreach my $section (qw(1 3)) {
        my $pods = $self->{"MAN${section}PODS"};
        push @man_cmds, $self->split_command(<<CMD, %$pods);
	\$(NOECHO) \$(POD2MAN) --section=$section --perm_rw=\$(PERM_RW)
CMD
    }

    $manify .= "\t\$(NOECHO) \$(NOOP)\n" unless @man_cmds;
    $manify .= join '', map { "$_\n" } @man_cmds;

    return $manify;
}



sub metafile_target {
    my $self = shift;

    return <<'MAKE_FRAG' if $self->{NO_META};
metafile :
	$(NOECHO) $(NOOP)
MAKE_FRAG

    my $prereq_pm = '';
    foreach my $mod ( sort { lc $a cmp lc $b } keys %{$self->{PREREQ_PM}} ) {
        my $ver = $self->{PREREQ_PM}{$mod};
        $prereq_pm .= sprintf "\n    %-30s %s", "$mod:", $ver;
    }

    my $author_value = defined $self->{AUTHOR}
        ? "\n    - $self->{AUTHOR}"
        : undef;

    # Use a list to preserve order.
    my @meta_to_mm = (
        name         => $self->{DISTNAME},
        version      => $self->{VERSION},
        abstract     => $self->{ABSTRACT},
        license      => $self->{LICENSE},
        author       => $author_value,
        generated_by => 
                "ExtUtils::MakeMaker version $ExtUtils::MakeMaker::VERSION",
        distribution_type => $self->{PM} ? 'module' : 'script',
    );

    my $meta = "--- #YAML:1.0\n";

    while( @meta_to_mm ) {
        my($key, $val) = splice @meta_to_mm, 0, 2;

        $val = '~' unless defined $val;

        $meta .= sprintf "%-20s %s\n", "$key:", $val;
    };

    $meta .= <<"YAML";
requires:     $prereq_pm
meta-spec:
    url:     http://module-build.sourceforge.net/META-spec-v1.3.html
    version: 1.3
YAML

    $meta .= $self->{EXTRA_META} if $self->{EXTRA_META};

    my @write_meta = $self->echo($meta, 'META_new.yml');

    return sprintf <<'MAKE_FRAG', join("\n\t", @write_meta);
metafile : create_distdir
	$(NOECHO) $(ECHO) Generating META.yml
	%s
	-$(NOECHO) $(MV) META_new.yml $(DISTVNAME)/META.yml
MAKE_FRAG

}



sub distmeta_target {
    my $self = shift;

    my $add_meta = $self->oneliner(<<'CODE', ['-MExtUtils::Manifest=maniadd']);
eval { maniadd({q{META.yml} => q{Module meta-data (added by MakeMaker)}}) } 
    or print "Could not add META.yml to MANIFEST: $${'@'}\n"
CODE

    my $add_meta_to_distdir = $self->cd('$(DISTVNAME)', $add_meta);

    return sprintf <<'MAKE', $add_meta_to_distdir;
distmeta : create_distdir metafile
	$(NOECHO) %s

MAKE

}



sub realclean {
    my($self, %attribs) = @_;

    my @dirs  = qw($(DISTVNAME));
    my @files = qw($(FIRST_MAKEFILE) $(MAKEFILE_OLD));

    # Special exception for the perl core where INST_* is not in blib.
    # This cleans up the files built from the ext/ directory (all XS).
    if( $self->{PERL_CORE} ) {
	push @dirs, qw($(INST_AUTODIR) $(INST_ARCHAUTODIR));
        push @files, values %{$self->{PM}};
    }

    if( $self->has_link_code ){
        push @files, qw($(OBJECT));
    }

    if( $attribs{FILES} ) {
        if( ref $attribs{FILES} ) {
            push @dirs, @{ $attribs{FILES} };
        }
        else {
            push @dirs, split /\s+/, $attribs{FILES};
        }
    }

    # Occasionally files are repeated several times from different sources
    { my(%f) = map { ($_ => 1) } @files;  @files = keys %f; }
    { my(%d) = map { ($_ => 1) } @dirs;   @dirs  = keys %d; }

    my $rm_cmd  = join "\n\t", map { "$_" } 
                    $self->split_command('- $(RM_F)',  @files);
    my $rmf_cmd = join "\n\t", map { "$_" } 
                    $self->split_command('- $(RM_RF)', @dirs);

    my $m = sprintf <<'MAKE', $rm_cmd, $rmf_cmd;
realclean purge ::  clean realclean_subdirs
	%s
	%s
MAKE

    $m .= "\t$attribs{POSTOP}\n" if $attribs{POSTOP};

    return $m;
}



sub realclean_subdirs_target {
    my $self = shift;

    return <<'NOOP_FRAG' unless @{$self->{DIR}};
realclean_subdirs :
	$(NOECHO) $(NOOP)
NOOP_FRAG

    my $rclean = "realclean_subdirs :\n";

    foreach my $dir (@{$self->{DIR}}) {
        foreach my $makefile ('$(MAKEFILE_OLD)', '$(FIRST_MAKEFILE)' ) {
            my $subrclean .= $self->oneliner(sprintf <<'CODE', $dir, ($makefile) x 2);
chdir '%s';  system '$(MAKE) $(USEMAKEFILE) %s realclean' if -f '%s';
CODE

            $rclean .= sprintf <<'RCLEAN', $subrclean;
	- %s
RCLEAN

        }
    }

    return $rclean;
}



sub signature_target {
    my $self = shift;

    return <<'MAKE_FRAG';
signature :
	cpansign -s
MAKE_FRAG

}



sub distsignature_target {
    my $self = shift;

    my $add_sign = $self->oneliner(<<'CODE', ['-MExtUtils::Manifest=maniadd']);
eval { maniadd({q{SIGNATURE} => q{Public-key signature (added by MakeMaker)}}) } 
    or print "Could not add SIGNATURE to MANIFEST: $${'@'}\n"
CODE

    my $sign_dist        = $self->cd('$(DISTVNAME)' => 'cpansign -s');

    # cpansign -s complains if SIGNATURE is in the MANIFEST yet does not
    # exist
    my $touch_sig        = $self->cd('$(DISTVNAME)' => '$(TOUCH) SIGNATURE');
    my $add_sign_to_dist = $self->cd('$(DISTVNAME)' => $add_sign );

    return sprintf <<'MAKE', $add_sign_to_dist, $touch_sig, $sign_dist
distsignature : create_distdir
	$(NOECHO) %s
	$(NOECHO) %s
	%s

MAKE

}



sub special_targets {
    my $make_frag = <<'MAKE_FRAG';
.SUFFIXES : .xs .c .C .cpp .i .s .cxx .cc $(OBJ_EXT)

.PHONY: all config static dynamic test linkext manifest blibdirs clean realclean disttest distdir

MAKE_FRAG

    $make_frag .= <<'MAKE_FRAG' if $ENV{CLEARCASE_ROOT};
.NO_CONFIG_REC: Makefile

MAKE_FRAG

    return $make_frag;
}





sub init_ABSTRACT {
    my $self = shift;

    if( $self->{ABSTRACT_FROM} and $self->{ABSTRACT} ) {
        warn "Both ABSTRACT_FROM and ABSTRACT are set.  ".
             "Ignoring ABSTRACT_FROM.\n";
        return;
    }

    if ($self->{ABSTRACT_FROM}){
        $self->{ABSTRACT} = $self->parse_abstract($self->{ABSTRACT_FROM}) or
            carp "WARNING: Setting ABSTRACT via file ".
                 "'$self->{ABSTRACT_FROM}' failed\n";
    }
}


sub init_INST {
    my($self) = shift;

    $self->{INST_ARCHLIB} ||= $self->catdir($Curdir,"blib","arch");
    $self->{INST_BIN}     ||= $self->catdir($Curdir,'blib','bin');

    # INST_LIB typically pre-set if building an extension after
    # perl has been built and installed. Setting INST_LIB allows
    # you to build directly into, say $Config{privlibexp}.
    unless ($self->{INST_LIB}){
	if ($self->{PERL_CORE}) {
            if (defined $Cross::platform) {
                $self->{INST_LIB} = $self->{INST_ARCHLIB} = 
                  $self->catdir($self->{PERL_LIB},"..","xlib",
                                     $Cross::platform);
            }
            else {
                $self->{INST_LIB} = $self->{INST_ARCHLIB} = $self->{PERL_LIB};
            }
	} else {
	    $self->{INST_LIB} = $self->catdir($Curdir,"blib","lib");
	}
    }

    my @parentdir = split(/::/, $self->{PARENT_NAME});
    $self->{INST_LIBDIR}      = $self->catdir('$(INST_LIB)',     @parentdir);
    $self->{INST_ARCHLIBDIR}  = $self->catdir('$(INST_ARCHLIB)', @parentdir);
    $self->{INST_AUTODIR}     = $self->catdir('$(INST_LIB)', 'auto', 
                                              '$(FULLEXT)');
    $self->{INST_ARCHAUTODIR} = $self->catdir('$(INST_ARCHLIB)', 'auto',
                                              '$(FULLEXT)');

    $self->{INST_SCRIPT}  ||= $self->catdir($Curdir,'blib','script');

    $self->{INST_MAN1DIR} ||= $self->catdir($Curdir,'blib','man1');
    $self->{INST_MAN3DIR} ||= $self->catdir($Curdir,'blib','man3');

    return 1;
}



sub init_INSTALL {
    my($self) = shift;

    if( $self->{ARGS}{INSTALL_BASE} and $self->{ARGS}{PREFIX} ) {
        die "Only one of PREFIX or INSTALL_BASE can be given.  Not both.\n";
    }

    if( $self->{ARGS}{INSTALL_BASE} ) {
        $self->init_INSTALL_from_INSTALL_BASE;
    }
    else {
        $self->init_INSTALL_from_PREFIX;
    }
}



sub init_INSTALL_from_PREFIX {
    my $self = shift;

    $self->init_lib2arch;

    # There are often no Config.pm defaults for these new man variables so 
    # we fall back to the old behavior which is to use installman*dir
    foreach my $num (1, 3) {
        my $k = 'installsiteman'.$num.'dir';

        $self->{uc $k} ||= uc "\$(installman${num}dir)"
          unless $Config{$k};
    }

    foreach my $num (1, 3) {
        my $k = 'installvendorman'.$num.'dir';

        unless( $Config{$k} ) {
            $self->{uc $k}  ||= $Config{usevendorprefix}
                              ? uc "\$(installman${num}dir)"
                              : '';
        }
    }

    $self->{INSTALLSITEBIN} ||= '$(INSTALLBIN)'
      unless $Config{installsitebin};
    $self->{INSTALLSITESCRIPT} ||= '$(INSTALLSCRIPT)'
      unless $Config{installsitescript};

    unless( $Config{installvendorbin} ) {
        $self->{INSTALLVENDORBIN} ||= $Config{usevendorprefix} 
                                    ? $Config{installbin}
                                    : '';
    }
    unless( $Config{installvendorscript} ) {
        $self->{INSTALLVENDORSCRIPT} ||= $Config{usevendorprefix}
                                       ? $Config{installscript}
                                       : '';
    }


    my $iprefix = $Config{installprefixexp} || $Config{installprefix} || 
                  $Config{prefixexp}        || $Config{prefix} || '';
    my $vprefix = $Config{usevendorprefix}  ? $Config{vendorprefixexp} : '';
    my $sprefix = $Config{siteprefixexp}    || '';

    # 5.005_03 doesn't have a siteprefix.
    $sprefix = $iprefix unless $sprefix;


    $self->{PREFIX}       ||= '';

    if( $self->{PREFIX} ) {
        @{$self}{qw(PERLPREFIX SITEPREFIX VENDORPREFIX)} =
          ('$(PREFIX)') x 3;
    }
    else {
        $self->{PERLPREFIX}   ||= $iprefix;
        $self->{SITEPREFIX}   ||= $sprefix;
        $self->{VENDORPREFIX} ||= $vprefix;

        # Lots of MM extension authors like to use $(PREFIX) so we
        # put something sensible in there no matter what.
        $self->{PREFIX} = '$('.uc $self->{INSTALLDIRS}.'PREFIX)';
    }

    my $arch    = $Config{archname};
    my $version = $Config{version};

    # default style
    my $libstyle = $Config{installstyle} || 'lib/perl5';
    my $manstyle = '';

    if( $self->{LIBSTYLE} ) {
        $libstyle = $self->{LIBSTYLE};
        $manstyle = $self->{LIBSTYLE} eq 'lib/perl5' ? 'lib/perl5' : '';
    }

    # Some systems, like VOS, set installman*dir to '' if they can't
    # read man pages.
    for my $num (1, 3) {
        $self->{'INSTALLMAN'.$num.'DIR'} ||= 'none'
          unless $Config{'installman'.$num.'dir'};
    }

    my %bin_layouts = 
    (
        bin         => { s => $iprefix,
                         t => 'perl',
                         d => 'bin' },
        vendorbin   => { s => $vprefix,
                         t => 'vendor',
                         d => 'bin' },
        sitebin     => { s => $sprefix,
                         t => 'site',
                         d => 'bin' },
        script      => { s => $iprefix,
                         t => 'perl',
                         d => 'bin' },
        vendorscript=> { s => $vprefix,
                         t => 'vendor',
                         d => 'bin' },
        sitescript  => { s => $sprefix,
                         t => 'site',
                         d => 'bin' },
    );
    
    my %man_layouts =
    (
        man1dir         => { s => $iprefix,
                             t => 'perl',
                             d => 'man/man1',
                             style => $manstyle, },
        siteman1dir     => { s => $sprefix,
                             t => 'site',
                             d => 'man/man1',
                             style => $manstyle, },
        vendorman1dir   => { s => $vprefix,
                             t => 'vendor',
                             d => 'man/man1',
                             style => $manstyle, },

        man3dir         => { s => $iprefix,
                             t => 'perl',
                             d => 'man/man3',
                             style => $manstyle, },
        siteman3dir     => { s => $sprefix,
                             t => 'site',
                             d => 'man/man3',
                             style => $manstyle, },
        vendorman3dir   => { s => $vprefix,
                             t => 'vendor',
                             d => 'man/man3',
                             style => $manstyle, },
    );

    my %lib_layouts =
    (
        privlib     => { s => $iprefix,
                         t => 'perl',
                         d => '',
                         style => $libstyle, },
        vendorlib   => { s => $vprefix,
                         t => 'vendor',
                         d => '',
                         style => $libstyle, },
        sitelib     => { s => $sprefix,
                         t => 'site',
                         d => 'site_perl',
                         style => $libstyle, },
        
        archlib     => { s => $iprefix,
                         t => 'perl',
                         d => "$version/$arch",
                         style => $libstyle },
        vendorarch  => { s => $vprefix,
                         t => 'vendor',
                         d => "$version/$arch",
                         style => $libstyle },
        sitearch    => { s => $sprefix,
                         t => 'site',
                         d => "site_perl/$version/$arch",
                         style => $libstyle },
    );


    # Special case for LIB.
    if( $self->{LIB} ) {
        foreach my $var (keys %lib_layouts) {
            my $Installvar = uc "install$var";

            if( $var =~ /arch/ ) {
                $self->{$Installvar} ||= 
                  $self->catdir($self->{LIB}, $Config{archname});
            }
            else {
                $self->{$Installvar} ||= $self->{LIB};
            }
        }
    }

    my %type2prefix = ( perl    => 'PERLPREFIX',
                        site    => 'SITEPREFIX',
                        vendor  => 'VENDORPREFIX'
                      );

    my %layouts = (%bin_layouts, %man_layouts, %lib_layouts);
    while( my($var, $layout) = each(%layouts) ) {
        my($s, $t, $d, $style) = @{$layout}{qw(s t d style)};
        my $r = '$('.$type2prefix{$t}.')';

        print STDERR "Prefixing $var\n" if $Verbose >= 2;

        my $installvar = "install$var";
        my $Installvar = uc $installvar;
        next if $self->{$Installvar};

        $d = "$style/$d" if $style;
        $self->prefixify($installvar, $s, $r, $d);

        print STDERR "  $Installvar == $self->{$Installvar}\n" 
          if $Verbose >= 2;
    }

    # Generate these if they weren't figured out.
    $self->{VENDORARCHEXP} ||= $self->{INSTALLVENDORARCH};
    $self->{VENDORLIBEXP}  ||= $self->{INSTALLVENDORLIB};

    return 1;
}



my %map = (
           lib      => [qw(lib perl5)],
           arch     => [('lib', 'perl5', $Config{archname})],
           bin      => [qw(bin)],
           man1dir  => [qw(man man1)],
           man3dir  => [qw(man man3)]
          );
$map{script} = $map{bin};

sub init_INSTALL_from_INSTALL_BASE {
    my $self = shift;

    @{$self}{qw(PREFIX VENDORPREFIX SITEPREFIX PERLPREFIX)} = 
                                                         '$(INSTALL_BASE)';

    my %install;
    foreach my $thing (keys %map) {
        foreach my $dir (('', 'SITE', 'VENDOR')) {
            my $uc_thing = uc $thing;
            my $key = "INSTALL".$dir.$uc_thing;

            $install{$key} ||= 
              $self->catdir('$(INSTALL_BASE)', @{$map{$thing}});
        }
    }

    # Adjust for variable quirks.
    $install{INSTALLARCHLIB} ||= delete $install{INSTALLARCH};
    $install{INSTALLPRIVLIB} ||= delete $install{INSTALLLIB};

    foreach my $key (keys %install) {
        $self->{$key} ||= $install{$key};
    }

    return 1;
}



sub init_VERSION {
    my($self) = shift;

    $self->{MAKEMAKER}  = $ExtUtils::MakeMaker::Filename;
    $self->{MM_VERSION} = $ExtUtils::MakeMaker::VERSION;
    $self->{MM_REVISION}= $ExtUtils::MakeMaker::Revision;
    $self->{VERSION_FROM} ||= '';

    if ($self->{VERSION_FROM}){
        $self->{VERSION} = $self->parse_version($self->{VERSION_FROM});
        if( $self->{VERSION} eq 'undef' ) {
            carp("WARNING: Setting VERSION via file ".
                 "'$self->{VERSION_FROM}' failed\n");
        }
    }

    # strip blanks
    if (defined $self->{VERSION}) {
        $self->{VERSION} =~ s/^\s+//;
        $self->{VERSION} =~ s/\s+$//;
    }
    else {
        $self->{VERSION} = '';
    }


    $self->{VERSION_MACRO}  = 'VERSION';
    ($self->{VERSION_SYM} = $self->{VERSION}) =~ s/\W/_/g;
    $self->{DEFINE_VERSION} = '-D$(VERSION_MACRO)=\"$(VERSION)\"';


    # Graham Barr and Paul Marquess had some ideas how to ensure
    # version compatibility between the *.pm file and the
    # corresponding *.xs file. The bottomline was, that we need an
    # XS_VERSION macro that defaults to VERSION:
    $self->{XS_VERSION} ||= $self->{VERSION};

    $self->{XS_VERSION_MACRO}  = 'XS_VERSION';
    $self->{XS_DEFINE_VERSION} = '-D$(XS_VERSION_MACRO)=\"$(XS_VERSION)\"';

}



sub init_platform {
    return '';
}



sub init_MAKE {
    my $self = shift;

    $self->{MAKE} ||= $ENV{MAKE} || $Config{make};
}



sub manifypods {
    my $self          = shift;

    my $POD2MAN_macro = $self->POD2MAN_macro();
    my $manifypods_target = $self->manifypods_target();

    return <<END_OF_TARGET;

$POD2MAN_macro

$manifypods_target

END_OF_TARGET

}



sub POD2MAN_macro {
    my $self = shift;

    return <<'END_OF_DEF';
POD2MAN_EXE = $(PERLRUN) "-MExtUtils::Command::MM" -e pod2man "--"
POD2MAN = $(POD2MAN_EXE)
END_OF_DEF
}



sub test_via_harness {
    my($self, $perl, $tests) = @_;

    return qq{\t$perl "-MExtUtils::Command::MM" }.
           qq{"-e" "test_harness(\$(TEST_VERBOSE), '\$(INST_LIB)', '\$(INST_ARCHLIB)')" $tests\n};
}


sub test_via_script {
    my($self, $perl, $script) = @_;
    return qq{\t$perl "-I\$(INST_LIB)" "-I\$(INST_ARCHLIB)" $script\n};
}



sub tool_autosplit {
    my($self, %attribs) = @_;

    my $maxlen = $attribs{MAXLEN} ? '$$AutoSplit::Maxlen=$attribs{MAXLEN};' 
                                  : '';

    my $asplit = $self->oneliner(sprintf <<'PERL_CODE', $maxlen);
use AutoSplit; %s autosplit($$ARGV[0], $$ARGV[1], 0, 1, 1)
PERL_CODE

    return sprintf <<'MAKE_FRAG', $asplit;
AUTOSPLITFILE = %s

MAKE_FRAG

}





sub catfile {
    my $self = shift;
    return $self->canonpath($self->SUPER::catfile(@_));
}




sub find_tests {
    my($self) = shift;
    return -d 't' ? 't/*.t' : '';
}



sub extra_clean_files { 
    return;
}



sub installvars {
    return qw(PRIVLIB SITELIB  VENDORLIB
              ARCHLIB SITEARCH VENDORARCH
              BIN     SITEBIN  VENDORBIN
              SCRIPT  SITESCRIPT  VENDORSCRIPT
              MAN1DIR SITEMAN1DIR VENDORMAN1DIR
              MAN3DIR SITEMAN3DIR VENDORMAN3DIR
             );
}



sub libscan {
    my($self,$path) = @_;
    my($dirs,$file) = ($self->splitpath($path))[1,2];
    return '' if grep /^(?:RCS|CVS|SCCS|\.svn|_darcs)$/, 
                     $self->splitdir($dirs), $file;

    return $path;
}



sub platform_constants {
    return '';
}



1;
