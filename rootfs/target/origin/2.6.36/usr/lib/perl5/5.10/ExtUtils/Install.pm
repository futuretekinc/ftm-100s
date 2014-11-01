package ExtUtils::Install;
use 5.00503;
use strict;

use vars qw(@ISA @EXPORT $VERSION $MUST_REBOOT %Config);
$VERSION = '1.44';
$VERSION = eval $VERSION;

use AutoSplit;
use Carp ();
use Config qw(%Config);
use Cwd qw(cwd);
use Exporter;
use ExtUtils::Packlist;
use File::Basename qw(dirname);
use File::Compare qw(compare);
use File::Copy;
use File::Find qw(find);
use File::Path;
use File::Spec;


@ISA = ('Exporter');
@EXPORT = ('install','uninstall','pm_to_blib', 'install_default');


my $Is_VMS     = $^O eq 'VMS';
my $Is_MacPerl = $^O eq 'MacOS';
my $Is_Win32   = $^O eq 'MSWin32';
my $Is_cygwin  = $^O eq 'cygwin';
my $CanMoveAtBoot = ($Is_Win32 || $Is_cygwin);

my $Has_Win32API_File = ($Is_Win32 || $Is_cygwin)
    ? (eval {require Win32API::File; 1} || 0)
    : 0;


my $Inc_uninstall_warn_handler;


my $INSTALL_ROOT = $ENV{PERL_INSTALL_ROOT};

my $Curdir = File::Spec->curdir;
my $Updir  = File::Spec->updir;

sub _estr(@) {
    return join "\n",'!' x 72,@_,'!' x 72,'';
}

{my %warned;
sub _warnonce(@) {
    my $first=shift;
    my $msg=_estr "WARNING: $first",@_;
    warn $msg unless $warned{$msg}++;
}}

sub _choke(@) {
    my $first=shift;
    my $msg=_estr "ERROR: $first",@_;
    Carp::croak($msg);
}


sub _chmod($$;$) {
    my ( $mode, $item, $verbose )=@_;
    $verbose ||= 0;
    if (chmod $mode, $item) {
        print "chmod($mode, $item)\n" if $verbose > 1;
    } else {
        my $err="$!";
        _warnonce "WARNING: Failed chmod($mode, $item): $err\n"
            if -e $item;
    }
}

=begin _private




sub _move_file_at_boot { #XXX OS-SPECIFIC
    my ( $file, $target, $moan  )= @_;
    Carp::confess("Panic: Can't _move_file_at_boot on this platform!")
         unless $CanMoveAtBoot;

    my $descr= ref $target
                ? "'$file' for deletion"
                : "'$file' for installation as '$target'";

    if ( ! $Has_Win32API_File ) {

        my @msg=(
            "Cannot schedule $descr at reboot.",
            "Try installing Win32API::File to allow operations on locked files",
            "to be scheduled during reboot. Or try to perform the operation by",
            "hand yourself. (You may need to close other perl processes first)"
        );
        if ( $moan ) { _warnonce(@msg) } else { _choke(@msg) }
        return 0;
    }
    my $opts= Win32API::File::MOVEFILE_DELAY_UNTIL_REBOOT();
    $opts= $opts | Win32API::File::MOVEFILE_REPLACE_EXISTING()
        unless ref $target;

    _chmod( 0666, $file );
    _chmod( 0666, $target ) unless ref $target;

    if (Win32API::File::MoveFileEx( $file, $target, $opts )) {
        $MUST_REBOOT ||= ref $target ? 0 : 1;
        return 1;
    } else {
        my @msg=(
            "MoveFileEx $descr at reboot failed: $^E",
            "You may try to perform the operation by hand yourself. ",
            "(You may need to close other perl processes first).",
        );
        if ( $moan ) { _warnonce(@msg) } else { _choke(@msg) }
    }
    return 0;
}


=begin _private




sub _unlink_or_rename { #XXX OS-SPECIFIC
    my ( $file, $tryhard, $installing )= @_;

    _chmod( 0666, $file );
    unlink $file
        and return $file;
    my $error="$!";

    _choke("Cannot unlink '$file': $!")
          unless $CanMoveAtBoot && $tryhard;

    my $tmp= "AAA";
    ++$tmp while -e "$file.$tmp";
    $tmp= "$file.$tmp";

    warn "WARNING: Unable to unlink '$file': $error\n",
         "Going to try to rename it to '$tmp'.\n";

    if ( rename $file, $tmp ) {
        warn "Rename succesful. Scheduling '$tmp'\nfor deletion at reboot.\n";
        # when $installing we can set $moan to true.
        # IOW, if we cant delete the renamed file at reboot its
        # not the end of the world. The other cases are more serious
        # and need to be fatal.
        _move_file_at_boot( $tmp, [], $installing );
        return $file;
    } elsif ( $installing ) {
        _warnonce("Rename failed: $!. Scheduling '$tmp'\nfor".
             " installation as '$file' at reboot.\n");
        _move_file_at_boot( $tmp, $file );
        return $tmp;
    } else {
        _choke("Rename failed:$!", "Cannot procede.");
    }

}




=begin _private




sub _get_install_skip {
    my ( $skip, $verbose )= @_;
    if ($ENV{EU_INSTALL_IGNORE_SKIP}) {
        print "EU_INSTALL_IGNORE_SKIP is set, ignore skipfile settings\n"
            if $verbose>2;
        return [];
    }
    if ( ! defined $skip ) {
        print "Looking for install skip list\n"
            if $verbose>2;
        for my $file ( 'INSTALL.SKIP', $ENV{EU_INSTALL_SITE_SKIPFILE} ) {
            next unless $file;
            print "\tChecking for $file\n"
                if $verbose>2;
            if (-e $file) {
                $skip= $file;
                last;
            }
        }
    }
    if ($skip && !ref $skip) {
        print "Reading skip patterns from '$skip'.\n"
            if $verbose;
        if (open my $fh,$skip ) {
            my @patterns;
            while (<$fh>) {
                chomp;
                next if /^\s*(?:#|$)/;
                print "\tSkip pattern: $_\n" if $verbose>3;
                push @patterns, $_;
            }
            $skip= \@patterns;
        } else {
            warn "Can't read skip file:'$skip':$!\n";
            $skip=[];
        }
    } elsif ( UNIVERSAL::isa($skip,'ARRAY') ) {
        print "Using array for skip list\n"
            if $verbose>2;
    } elsif ($verbose) {
        print "No skip list found.\n"
            if $verbose>1;
        $skip= [];
    }
    warn "Got @{[0+@$skip]} skip patterns.\n"
        if $verbose>3;
    return $skip
}



{
    my  $has_posix;
    sub _have_write_access {
        my $dir=shift;
        if (!defined $has_posix) {
            $has_posix=eval "local $^W; require POSIX; 1" || 0;
        }
        if ($has_posix) {
            return POSIX::access($dir, POSIX::W_OK());
        } else {
            return -w $dir;
        }
    }
}




sub _can_write_dir {
    my $dir=shift;
    return
        unless defined $dir and length $dir;

    my ($vol, $dirs, $file) = File::Spec->splitpath(File::Spec->rel2abs($dir),1);
    my @dirs = File::Spec->splitdir($dirs);
    my $path='';
    my @make;
    while (@dirs) {
        $dir = File::Spec->catdir($vol,@dirs);
        next if ( $dir eq $path );
        if ( ! -e $dir ) {
            unshift @make,$dir;
            next;
        }
        if ( _have_write_access($dir) ) {
            return 1,$dir,@make
        } else {
            return 0,$dir,@make
        }
    } continue {
        pop @dirs;
    }
    return 0;
}


sub _mkpath {
    my ($dir,$show,$mode,$verbose,$fake)=@_;
    if ( $verbose && $verbose > 1 && ! -d $dir) {
        $show= 1;
        printf "mkpath(%s,%d,%#o)\n", $dir, $show, $mode;
    }
    if (!$fake) {
        if ( ! eval { File::Path::mkpath($dir,$show,$mode); 1 } ) {
            _choke("Can't create '$dir'","$@");
        }

    }
    my ($can,$root,@make)=_can_write_dir($dir);
    if (!$can) {
        my @msg=(
            "Can't create '$dir'",
            $root ? "Do not have write permissions on '$root'"
                  : "Unknown Error"
        );
        if ($fake) {
            _warnonce @msg;
        } else {
            _choke @msg;
        }
    } elsif ($show and $fake) {
        print "$_\n" for @make;
    }
}



sub _copy {
    my ( $from, $to, $verbose, $nonono)=@_;
    if ($verbose && $verbose>1) {
        printf "copy(%s,%s)\n", $from, $to;
    }
    if (!$nonono) {
        File::Copy::copy($from,$to)
            or Carp::croak( _estr "ERROR: Cannot copy '$from' to '$to': $!" );
    }
}


sub _chdir {
    my ($dir)= @_;
    my $ret;
    if (defined wantarray) {
        $ret= cwd;
    }
    chdir $dir
        or _choke("Couldn't chdir to '$dir': $!");
    return $ret;
}

=end _private

=cut

sub install { #XXX OS-SPECIFIC
    my($from_to,$verbose,$nonono,$inc_uninstall,$skip) = @_;
    $verbose ||= 0;
    $nonono  ||= 0;

    $skip= _get_install_skip($skip,$verbose);

    my(%from_to) = %$from_to;
    my(%pack, $dir, %warned);
    my($packlist) = ExtUtils::Packlist->new();

    local(*DIR);
    for (qw/read write/) {
        $pack{$_}=$from_to{$_};
        delete $from_to{$_};
    }
    my $tmpfile = install_rooted_file($pack{"read"});
    $packlist->read($tmpfile) if (-f $tmpfile);
    my $cwd = cwd();
    my @found_files;
    my %check_dirs;
    
    MOD_INSTALL: foreach my $source (sort keys %from_to) {
        #copy the tree to the target directory without altering
        #timestamp and permission and remember for the .packlist
        #file. The packlist file contains the absolute paths of the
        #install locations. AFS users may call this a bug. We'll have
        #to reconsider how to add the means to satisfy AFS users also.

        #October 1997: we want to install .pm files into archlib if
        #there are any files in arch. So we depend on having ./blib/arch
        #hardcoded here.

        my $targetroot = install_rooted_dir($from_to{$source});

        my $blib_lib  = File::Spec->catdir('blib', 'lib');
        my $blib_arch = File::Spec->catdir('blib', 'arch');
        if ($source eq $blib_lib and
            exists $from_to{$blib_arch} and
            directory_not_empty($blib_arch)
        ){
            $targetroot = install_rooted_dir($from_to{$blib_arch});
            print "Files found in $blib_arch: installing files in $blib_lib into architecture dependent library tree\n";
        }

        next unless -d $source;
        _chdir($source);
        # 5.5.3's File::Find missing no_chdir option
        # XXX OS-SPECIFIC
        # File::Find seems to always be Unixy except on MacPerl :(
        my $current_directory= $Is_MacPerl ? $Curdir : '.';
        find(sub {
            my ($mode,$size,$atime,$mtime) = (stat)[2,7,8,9];

            return if !-f _;
            my $origfile = $_;

            return if $origfile eq ".exists";
            my $targetdir  = File::Spec->catdir($targetroot, $File::Find::dir);
            my $targetfile = File::Spec->catfile($targetdir, $origfile);
            my $sourcedir  = File::Spec->catdir($source, $File::Find::dir);
            my $sourcefile = File::Spec->catfile($sourcedir, $origfile);

            for my $pat (@$skip) {
                if ( $sourcefile=~/$pat/ ) {
                    print "Skipping $targetfile (filtered)\n"
                        if $verbose>1;
                    return;
                }
            }
            # we have to do this for back compat with old File::Finds
            # and because the target is relative
            my $save_cwd = _chdir($cwd); 
            my $diff = 0;
            if ( -f $targetfile && -s _ == $size) {
                # We have a good chance, we can skip this one
                $diff = compare($sourcefile, $targetfile);
            } else {
                $diff++;
            }
            $check_dirs{$targetdir}++ 
                unless -w $targetfile;
            
            push @found_files,
                [ $diff, $File::Find::dir, $origfile,
                  $mode, $size, $atime, $mtime,
                  $targetdir, $targetfile, $sourcedir, $sourcefile,
                  
                ];  
            #restore the original directory we were in when File::Find
            #called us so that it doesnt get horribly confused.
            _chdir($save_cwd);                
        }, $current_directory ); 
        _chdir($cwd);
    }   
    
    foreach my $targetdir (sort keys %check_dirs) {
        _mkpath( $targetdir, 0, 0755, $verbose, $nonono );
    }
    foreach my $found (@found_files) {
        my ($diff, $ffd, $origfile, $mode, $size, $atime, $mtime,
            $targetdir, $targetfile, $sourcedir, $sourcefile)= @$found;
        
        my $realtarget= $targetfile;
        if ($diff) {
            if (-f $targetfile) {
                print "_unlink_or_rename($targetfile)\n" if $verbose>1;
                $targetfile= _unlink_or_rename( $targetfile, 'tryhard', 'install' )
                    unless $nonono;
            } elsif ( ! -d $targetdir ) {
                _mkpath( $targetdir, 0, 0755, $verbose, $nonono );
            }
            print "Installing $targetfile\n";
            _copy( $sourcefile, $targetfile, $verbose, $nonono, );
            #XXX OS-SPECIFIC
            print "utime($atime,$mtime,$targetfile)\n" if $verbose>1;
            utime($atime,$mtime + $Is_VMS,$targetfile) unless $nonono>1;


            $mode = 0444 | ( $mode & 0111 ? 0111 : 0 );
            $mode = $mode | 0222
                if $realtarget ne $targetfile;
            _chmod( $mode, $targetfile, $verbose );
        } else {
            print "Skipping $targetfile (unchanged)\n" if $verbose;
        }

        if ( $inc_uninstall ) {
            inc_uninstall($sourcefile,$ffd, $verbose,
                          $nonono,
                          $realtarget ne $targetfile ? $realtarget : "");
        }

        # Record the full pathname.
        $packlist->{$targetfile}++;
    }

    if ($pack{'write'}) {
        $dir = install_rooted_dir(dirname($pack{'write'}));
        _mkpath( $dir, 0, 0755, $verbose, $nonono );
        print "Writing $pack{'write'}\n";
        $packlist->write(install_rooted_file($pack{'write'})) unless $nonono;
    }

    _do_cleanup($verbose);
}

=begin _private


sub _do_cleanup {
    my ($verbose) = @_;
    if ($MUST_REBOOT) {
        die _estr "Operation not completed! ",
            "You must reboot to complete the installation.",
            "Sorry.";
    } elsif (defined $MUST_REBOOT & $verbose) {
        warn _estr "Installation will be completed at the next reboot.\n",
             "However it is not necessary to reboot immediately.\n";
    }
}

=begin _undocumented



sub install_rooted_file {
    if (defined $INSTALL_ROOT) {
        File::Spec->catfile($INSTALL_ROOT, $_[0]);
    } else {
        $_[0];
    }
}


sub install_rooted_dir {
    if (defined $INSTALL_ROOT) {
        File::Spec->catdir($INSTALL_ROOT, $_[0]);
    } else {
        $_[0];
    }
}

=begin _undocumented



sub forceunlink {
    my ( $file, $tryhard )= @_; #XXX OS-SPECIFIC
    _unlink_or_rename( $file, $tryhard );
}

=begin _undocumented


sub directory_not_empty ($) {
  my($dir) = @_;
  my $files = 0;
  find(sub {
           return if $_ eq ".exists";
           if (-f) {
             $File::Find::prune++;
             $files = 1;
           }
       }, $dir);
  return $files;
}



sub install_default {
  @_ < 2 or Carp::croak("install_default should be called with 0 or 1 argument");
  my $FULLEXT = @_ ? shift : $ARGV[0];
  defined $FULLEXT or die "Do not know to where to write install log";
  my $INST_LIB = File::Spec->catdir($Curdir,"blib","lib");
  my $INST_ARCHLIB = File::Spec->catdir($Curdir,"blib","arch");
  my $INST_BIN = File::Spec->catdir($Curdir,'blib','bin');
  my $INST_SCRIPT = File::Spec->catdir($Curdir,'blib','script');
  my $INST_MAN1DIR = File::Spec->catdir($Curdir,'blib','man1');
  my $INST_MAN3DIR = File::Spec->catdir($Curdir,'blib','man3');
  install({
           read => "$Config{sitearchexp}/auto/$FULLEXT/.packlist",
           write => "$Config{installsitearch}/auto/$FULLEXT/.packlist",
           $INST_LIB => (directory_not_empty($INST_ARCHLIB)) ?
                         $Config{installsitearch} :
                         $Config{installsitelib},
           $INST_ARCHLIB => $Config{installsitearch},
           $INST_BIN => $Config{installbin} ,
           $INST_SCRIPT => $Config{installscript},
           $INST_MAN1DIR => $Config{installman1dir},
           $INST_MAN3DIR => $Config{installman3dir},
          },1,0,0);
}



sub uninstall {
    my($fil,$verbose,$nonono) = @_;
    $verbose ||= 0;
    $nonono  ||= 0;

    die _estr "ERROR: no packlist file found: '$fil'"
        unless -f $fil;
    # my $my_req = $self->catfile(qw(auto ExtUtils Install forceunlink.al));
    # require $my_req; # Hairy, but for the first
    my ($packlist) = ExtUtils::Packlist->new($fil);
    foreach (sort(keys(%$packlist))) {
        chomp;
        print "unlink $_\n" if $verbose;
        forceunlink($_,'tryhard') unless $nonono;
    }
    print "unlink $fil\n" if $verbose;
    forceunlink($fil, 'tryhard') unless $nonono;
    _do_cleanup($verbose);
}

=begin _undocumented


sub inc_uninstall {
    my($filepath,$libdir,$verbose,$nonono,$ignore) = @_;
    my($dir);
    $ignore||="";
    my $file = (File::Spec->splitpath($filepath))[2];
    my %seen_dir = ();

    my @PERL_ENV_LIB = split $Config{path_sep}, defined $ENV{'PERL5LIB'}
      ? $ENV{'PERL5LIB'} : $ENV{'PERLLIB'} || '';

    foreach $dir (@INC, @PERL_ENV_LIB, @Config{qw(archlibexp
                                                  privlibexp
                                                  sitearchexp
                                                  sitelibexp)}) {
        my $canonpath = File::Spec->canonpath($dir);
        next if $canonpath eq $Curdir;
        next if $seen_dir{$canonpath}++;
        my $targetfile = File::Spec->catfile($canonpath,$libdir,$file);
        next unless -f $targetfile;

        # The reason why we compare file's contents is, that we cannot
        # know, which is the file we just installed (AFS). So we leave
        # an identical file in place
        my $diff = 0;
        if ( -f $targetfile && -s _ == -s $filepath) {
            # We have a good chance, we can skip this one
            $diff = compare($filepath,$targetfile);
        } else {
            $diff++;
        }
        print "#$file and $targetfile differ\n" if $diff && $verbose > 1;

        next if !$diff or $targetfile eq $ignore;
        if ($nonono) {
            if ($verbose) {
                $Inc_uninstall_warn_handler ||= ExtUtils::Install::Warn->new();
                $libdir =~ s|^\./||s ; # That's just cosmetics, no need to port. It looks prettier.
                $Inc_uninstall_warn_handler->add(
                                     File::Spec->catfile($libdir, $file),
                                     $targetfile
                                    );
            }
            # if not verbose, we just say nothing
        } else {
            print "Unlinking $targetfile (shadowing?)\n" if $verbose;
            forceunlink($targetfile,'tryhard');
        }
    }
}

=begin _undocumented


sub run_filter {
    my ($cmd, $src, $dest) = @_;
    local(*CMD, *SRC);
    open(CMD, "|$cmd >$dest") || die "Cannot fork: $!";
    open(SRC, $src)           || die "Cannot open $src: $!";
    my $buf;
    my $sz = 1024;
    while (my $len = sysread(SRC, $buf, $sz)) {
        syswrite(CMD, $buf, $len);
    }
    close SRC;
    close CMD or die "Filter command '$cmd' failed for $src";
}



sub pm_to_blib {
    my($fromto,$autodir,$pm_filter) = @_;

    _mkpath($autodir,0,0755);
    while(my($from, $to) = each %$fromto) {
        if( -f $to && -s $from == -s $to && -M $to < -M $from ) {
            print "Skip $to (unchanged)\n";
            next;
        }

        # When a pm_filter is defined, we need to pre-process the source first
        # to determine whether it has changed or not.  Therefore, only perform
        # the comparison check when there's no filter to be ran.
        #    -- RAM, 03/01/2001

        my $need_filtering = defined $pm_filter && length $pm_filter &&
                             $from =~ /\.pm$/;

        if (!$need_filtering && 0 == compare($from,$to)) {
            print "Skip $to (unchanged)\n";
            next;
        }
        if (-f $to){
            # we wont try hard here. its too likely to mess things up.
            forceunlink($to);
        } else {
            _mkpath(dirname($to),0,0755);
        }
        if ($need_filtering) {
            run_filter($pm_filter, $from, $to);
            print "$pm_filter <$from >$to\n";
        } else {
            _copy( $from, $to );
            print "cp $from $to\n";
        }
        my($mode,$atime,$mtime) = (stat $from)[2,8,9];
        utime($atime,$mtime+$Is_VMS,$to);
        _chmod(0444 | ( $mode & 0111 ? 0111 : 0 ),$to);
        next unless $from =~ /\.pm$/;
        _autosplit($to,$autodir);
    }
}


=begin _private


sub _autosplit { #XXX OS-SPECIFIC
    my $retval = autosplit(@_);
    close *AutoSplit::IN if defined *AutoSplit::IN{IO};

    return $retval;
}


package ExtUtils::Install::Warn;

sub new { bless {}, shift }

sub add {
    my($self,$file,$targetfile) = @_;
    push @{$self->{$file}}, $targetfile;
}

sub DESTROY {
    unless(defined $INSTALL_ROOT) {
        my $self = shift;
        my($file,$i,$plural);
        foreach $file (sort keys %$self) {
            $plural = @{$self->{$file}} > 1 ? "s" : "";
            print "## Differing version$plural of $file found. You might like to\n";
            for (0..$#{$self->{$file}}) {
                print "rm ", $self->{$file}[$_], "\n";
                $i++;
            }
        }
        $plural = $i>1 ? "all those files" : "this file";
        my $inst = (_invokant() eq 'ExtUtils::MakeMaker')
                 ? ( $Config::Config{make} || 'make' ).' install UNINST=1'
                 : './Build install uninst=1';
        print "## Running '$inst' will unlink $plural for you.\n";
    }
}

=begin _private


sub _invokant {
    my @stack;
    my $frame = 0;
    while (my $file = (caller($frame++))[1]) {
        push @stack, (File::Spec->splitpath($file))[2];
    }

    my $builder;
    my $top = pop @stack;
    if ($top =~ /^Build/i || exists($INC{'Module/Build.pm'})) {
        $builder = 'Module::Build';
    } else {
        $builder = 'ExtUtils::MakeMaker';
    }
    return $builder;
}



1;
