package ExtUtils::Manifest;

require Exporter;
use Config;
use File::Basename;
use File::Copy 'copy';
use File::Find;
use File::Spec;
use Carp;
use strict;

use vars qw($VERSION @ISA @EXPORT_OK 
          $Is_MacOS $Is_VMS 
          $Debug $Verbose $Quiet $MANIFEST $DEFAULT_MSKIP);

$VERSION = '1.51_01';
@ISA=('Exporter');
@EXPORT_OK = qw(mkmanifest
                manicheck  filecheck  fullcheck  skipcheck
                manifind   maniread   manicopy   maniadd
               );

$Is_MacOS = $^O eq 'MacOS';
$Is_VMS   = $^O eq 'VMS';
require VMS::Filespec if $Is_VMS;

$Debug   = $ENV{PERL_MM_MANIFEST_DEBUG} || 0;
$Verbose = defined $ENV{PERL_MM_MANIFEST_VERBOSE} ?
                   $ENV{PERL_MM_MANIFEST_VERBOSE} : 1;
$Quiet = 0;
$MANIFEST = 'MANIFEST';

$DEFAULT_MSKIP = File::Spec->catfile( dirname(__FILE__), "$MANIFEST.SKIP" );



sub _sort {
    return sort { lc $a cmp lc $b } @_;
}

sub mkmanifest {
    my $manimiss = 0;
    my $read = (-r 'MANIFEST' && maniread()) or $manimiss++;
    $read = {} if $manimiss;
    local *M;
    my $bakbase = $MANIFEST;
    $bakbase =~ s/\./_/g if $Is_VMS; # avoid double dots
    rename $MANIFEST, "$bakbase.bak" unless $manimiss;
    open M, ">$MANIFEST" or die "Could not open $MANIFEST: $!";
    my $skip = _maniskip();
    my $found = manifind();
    my($key,$val,$file,%all);
    %all = (%$found, %$read);
    $all{$MANIFEST} = ($Is_VMS ? "$MANIFEST\t\t" : '') . 'This list of files'
        if $manimiss; # add new MANIFEST to known file list
    foreach $file (_sort keys %all) {
	if ($skip->($file)) {
	    # Policy: only remove files if they're listed in MANIFEST.SKIP.
	    # Don't remove files just because they don't exist.
	    warn "Removed from $MANIFEST: $file\n" if $Verbose and exists $read->{$file};
	    next;
	}
	if ($Verbose){
	    warn "Added to $MANIFEST: $file\n" unless exists $read->{$file};
	}
	my $text = $all{$file};
	$file = _unmacify($file);
	my $tabs = (5 - (length($file)+1)/8);
	$tabs = 1 if $tabs < 1;
	$tabs = 0 unless $text;
	print M $file, "\t" x $tabs, $text, "\n";
    }
    close M;
}

sub clean_up_filename {
  my $filename = shift;
  $filename =~ s|^\./||;
  $filename =~ s/^:([^:]+)$/$1/ if $Is_MacOS;
  return $filename;
}



sub manifind {
    my $p = shift || {};
    my $found = {};

    my $wanted = sub {
	my $name = clean_up_filename($File::Find::name);
	warn "Debug: diskfile $name\n" if $Debug;
	return if -d $_;
	
        if( $Is_VMS ) {
            $name =~ s#(.*)\.$#\L$1#;
            $name = uc($name) if $name =~ /^MANIFEST(\.SKIP)?$/i;
        }
	$found->{$name} = "";
    };

    # We have to use "$File::Find::dir/$_" in preprocess, because 
    # $File::Find::name is unavailable.
    # Also, it's okay to use / here, because MANIFEST files use Unix-style 
    # paths.
    find({wanted => $wanted},
	 $Is_MacOS ? ":" : ".");

    return $found;
}



sub manicheck {
    return _check_files();
}



sub filecheck {
    return _check_manifest();
}



sub fullcheck {
    return [_check_files()], [_check_manifest()];
}



sub skipcheck {
    my($p) = @_;
    my $found = manifind();
    my $matches = _maniskip();

    my @skipped = ();
    foreach my $file (_sort keys %$found){
        if (&$matches($file)){
            warn "Skipping $file\n";
            push @skipped, $file;
            next;
        }
    }

    return @skipped;
}


sub _check_files {
    my $p = shift;
    my $dosnames=(defined(&Dos::UseLFN) && Dos::UseLFN()==0);
    my $read = maniread() || {};
    my $found = manifind($p);

    my(@missfile) = ();
    foreach my $file (_sort keys %$read){
        warn "Debug: manicheck checking from $MANIFEST $file\n" if $Debug;
        if ($dosnames){
            $file = lc $file;
            $file =~ s=(\.(\w|-)+)=substr ($1,0,4)=ge;
            $file =~ s=((\w|-)+)=substr ($1,0,8)=ge;
        }
        unless ( exists $found->{$file} ) {
            warn "No such file: $file\n" unless $Quiet;
            push @missfile, $file;
        }
    }

    return @missfile;
}


sub _check_manifest {
    my($p) = @_;
    my $read = maniread() || {};
    my $found = manifind($p);
    my $skip  = _maniskip();

    my @missentry = ();
    foreach my $file (_sort keys %$found){
        next if $skip->($file);
        warn "Debug: manicheck checking from disk $file\n" if $Debug;
        unless ( exists $read->{$file} ) {
            my $canon = $Is_MacOS ? "\t" . _unmacify($file) : '';
            warn "Not in $MANIFEST: $file$canon\n" unless $Quiet;
            push @missentry, $file;
        }
    }

    return @missentry;
}



sub maniread {
    my ($mfile) = @_;
    $mfile ||= $MANIFEST;
    my $read = {};
    local *M;
    unless (open M, $mfile){
        warn "Problem opening $mfile: $!";
        return $read;
    }
    local $_;
    while (<M>){
        chomp;
        next if /^\s*#/;

        my($file, $comment) = /^(\S+)\s*(.*)/;
        next unless $file;

        if ($Is_MacOS) {
            $file = _macify($file);
            $file =~ s/\\([0-3][0-7][0-7])/sprintf("%c", oct($1))/ge;
        }
        elsif ($Is_VMS) {
            require File::Basename;
            my($base,$dir) = File::Basename::fileparse($file);
            # Resolve illegal file specifications in the same way as tar
            $dir =~ tr/./_/;
            my(@pieces) = split(/\./,$base);
            if (@pieces > 2) { $base = shift(@pieces) . '.' . join('_',@pieces); }
            my $okfile = "$dir$base";
            warn "Debug: Illegal name $file changed to $okfile\n" if $Debug;
            $file = $okfile;
            $file = lc($file) unless $file =~ /^MANIFEST(\.SKIP)?$/;
        }

        $read->{$file} = $comment;
    }
    close M;
    $read;
}

sub _maniskip {
    my @skip ;
    my $mfile = "$MANIFEST.SKIP";
    _check_mskip_directives($mfile) if -f $mfile;
    local(*M, $_);
    open M, $mfile or open M, $DEFAULT_MSKIP or return sub {0};
    while (<M>){
	chomp;
	s/\r//;
	next if /^#/;
	next if /^\s*$/;
	push @skip, _macify($_);
    }
    close M;
    return sub {0} unless (scalar @skip > 0);

    my $opts = $Is_VMS ? '(?i)' : '';

    # Make sure each entry is isolated in its own parentheses, in case
    # any of them contain alternations
    my $regex = join '|', map "(?:$_)", @skip;

    return sub { $_[0] =~ qr{$opts$regex} };
}

sub _check_mskip_directives {
    my $mfile = shift;
    local (*M, $_);
    my @lines = ();
    my $flag = 0;
    unless (open M, $mfile) {
        warn "Problem opening $mfile: $!";
        return;
    }
    while (<M>) {
        if (/^#!include_default\s*$/) {
	    if (my @default = _include_mskip_file()) {
	        push @lines, @default;
		warn "Debug: Including default MANIFEST.SKIP\n" if $Debug;
		$flag++;
	    }
	    next;
        }
	if (/^#!include\s+(.*)\s*$/) {
	    my $external_file = $1;
	    if (my @external = _include_mskip_file($external_file)) {
	        push @lines, @external;
		warn "Debug: Including external $external_file\n" if $Debug;
		$flag++;
	    }
            next;
        }
        push @lines, $_;
    }
    close M;
    return unless $flag;
    my $bakbase = $mfile;
    $bakbase =~ s/\./_/g if $Is_VMS;  # avoid double dots
    rename $mfile, "$bakbase.bak";
    warn "Debug: Saving original $mfile as $bakbase.bak\n" if $Debug;
    unless (open M, ">$mfile") {
        warn "Problem opening $mfile: $!";
        return;
    }
    print M $_ for (@lines);
    close M;
    return;
}

sub _include_mskip_file {
    my $mskip = shift || $DEFAULT_MSKIP;
    unless (-f $mskip) {
        warn qq{Included file "$mskip" not found - skipping};
        return;
    }
    local (*M, $_);
    unless (open M, $mskip) {
        warn "Problem opening $mskip: $!";
        return;
    }
    my @lines = ();
    push @lines, "\n#!start included $mskip\n";
    push @lines, $_ while <M>;
    close M;
    push @lines, "#!end included $mskip\n\n";
    return @lines;
}


sub manicopy {
    my($read,$target,$how)=@_;
    croak "manicopy() called without target argument" unless defined $target;
    $how ||= 'cp';
    require File::Path;
    require File::Basename;

    $target = VMS::Filespec::unixify($target) if $Is_VMS;
    File::Path::mkpath([ $target ],! $Quiet,$Is_VMS ? undef : 0755);
    foreach my $file (keys %$read){
    	if ($Is_MacOS) {
	    if ($file =~ m!:!) { 
	   	my $dir = _maccat($target, $file);
		$dir =~ s/[^:]+$//;
	    	File::Path::mkpath($dir,1,0755);
	    }
	    cp_if_diff($file, _maccat($target, $file), $how);
	} else {
	    $file = VMS::Filespec::unixify($file) if $Is_VMS;
	    if ($file =~ m!/!) { # Ilya, that hurts, I fear, or maybe not?
		my $dir = File::Basename::dirname($file);
		$dir = VMS::Filespec::unixify($dir) if $Is_VMS;
		File::Path::mkpath(["$target/$dir"],! $Quiet,$Is_VMS ? undef : 0755);
	    }
	    cp_if_diff($file, "$target/$file", $how);
	}
    }
}

sub cp_if_diff {
    my($from, $to, $how)=@_;
    -f $from or carp "$0: $from not found";
    my($diff) = 0;
    local(*F,*T);
    open(F,"< $from\0") or die "Can't read $from: $!\n";
    if (open(T,"< $to\0")) {
        local $_;
	while (<F>) { $diff++,last if $_ ne <T>; }
	$diff++ unless eof(T);
	close T;
    }
    else { $diff++; }
    close F;
    if ($diff) {
	if (-e $to) {
	    unlink($to) or confess "unlink $to: $!";
	}
        STRICT_SWITCH: {
	    best($from,$to), last STRICT_SWITCH if $how eq 'best';
	    cp($from,$to), last STRICT_SWITCH if $how eq 'cp';
	    ln($from,$to), last STRICT_SWITCH if $how eq 'ln';
	    croak("ExtUtils::Manifest::cp_if_diff " .
		  "called with illegal how argument [$how]. " .
		  "Legal values are 'best', 'cp', and 'ln'.");
	}
    }
}

sub cp {
    my ($srcFile, $dstFile) = @_;
    my ($access,$mod) = (stat $srcFile)[8,9];

    copy($srcFile,$dstFile);
    utime $access, $mod + ($Is_VMS ? 1 : 0), $dstFile;
    _manicopy_chmod($srcFile, $dstFile);
}


sub ln {
    my ($srcFile, $dstFile) = @_;
    return &cp if $Is_VMS or ($^O eq 'MSWin32' and Win32::IsWin95());
    link($srcFile, $dstFile);

    unless( _manicopy_chmod($srcFile, $dstFile) ) {
        unlink $dstFile;
        return;
    }
    1;
}

sub _manicopy_chmod {
    my($srcFile, $dstFile) = @_;

    my $perm = 0444 | (stat $srcFile)[2] & 0700;
    chmod( $perm | ( $perm & 0100 ? 0111 : 0 ), $dstFile );
}

my @Exceptions = qw(MANIFEST META.yml SIGNATURE);
sub best {
    my ($srcFile, $dstFile) = @_;

    my $is_exception = grep $srcFile =~ /$_/, @Exceptions;
    if ($is_exception or !$Config{d_link} or -l $srcFile) {
	cp($srcFile, $dstFile);
    } else {
	ln($srcFile, $dstFile) or cp($srcFile, $dstFile);
    }
}

sub _macify {
    my($file) = @_;

    return $file unless $Is_MacOS;

    $file =~ s|^\./||;
    if ($file =~ m|/|) {
	$file =~ s|/+|:|g;
	$file = ":$file";
    }

    $file;
}

sub _maccat {
    my($f1, $f2) = @_;

    return "$f1/$f2" unless $Is_MacOS;

    $f1 .= ":$f2";
    $f1 =~ s/([^:]:):/$1/g;
    return $f1;
}

sub _unmacify {
    my($file) = @_;

    return $file unless $Is_MacOS;

    $file =~ s|^:||;
    $file =~ s|([/ \n])|sprintf("\\%03o", unpack("c", $1))|ge;
    $file =~ y|:|/|;

    $file;
}



sub maniadd {
    my($additions) = shift;

    _normalize($additions);
    _fix_manifest($MANIFEST);

    my $manifest = maniread();
    my @needed = grep { !exists $manifest->{$_} } keys %$additions;
    return 1 unless @needed;

    open(MANIFEST, ">>$MANIFEST") or 
      die "maniadd() could not open $MANIFEST: $!";

    foreach my $file (_sort @needed) {
        my $comment = $additions->{$file} || '';
        printf MANIFEST "%-40s %s\n", $file, $comment;
    }
    close MANIFEST or die "Error closing $MANIFEST: $!";

    return 1;
}


sub _fix_manifest {
    my $manifest_file = shift;

    open MANIFEST, $MANIFEST or die "Could not open $MANIFEST: $!";

    # Yes, we should be using seek(), but I'd like to avoid loading POSIX
    # to get SEEK_*
    my @manifest = <MANIFEST>;
    close MANIFEST;

    unless( $manifest[-1] =~ /\n\z/ ) {
        open MANIFEST, ">>$MANIFEST" or die "Could not open $MANIFEST: $!";
        print MANIFEST "\n";
        close MANIFEST;
    }
}


sub _normalize {
    return;
}



1;
