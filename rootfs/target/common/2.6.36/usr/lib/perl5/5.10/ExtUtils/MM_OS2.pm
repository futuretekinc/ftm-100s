package ExtUtils::MM_OS2;

use strict;
use vars qw($VERSION @ISA);

use ExtUtils::MakeMaker qw(neatvalue);
use File::Spec;

$VERSION = '6.42';

require ExtUtils::MM_Any;
require ExtUtils::MM_Unix;
@ISA = qw(ExtUtils::MM_Any ExtUtils::MM_Unix);


sub init_dist {
    my($self) = @_;

    $self->{TO_UNIX} ||= <<'MAKE_TEXT';
$(NOECHO) $(TEST_F) tmp.zip && $(RM_F) tmp.zip; $(ZIP) -ll -mr tmp.zip $(DISTVNAME) && unzip -o tmp.zip && $(RM_F) tmp.zip
MAKE_TEXT

    $self->SUPER::init_dist;
}

sub dlsyms {
    my($self,%attribs) = @_;

    my($funcs) = $attribs{DL_FUNCS} || $self->{DL_FUNCS} || {};
    my($vars)  = $attribs{DL_VARS} || $self->{DL_VARS} || [];
    my($funclist) = $attribs{FUNCLIST} || $self->{FUNCLIST} || [];
    my($imports)  = $attribs{IMPORTS} || $self->{IMPORTS} || {};
    my(@m);
    (my $boot = $self->{NAME}) =~ s/:/_/g;

    if (not $self->{SKIPHASH}{'dynamic'}) {
	push(@m,"
$self->{BASEEXT}.def: Makefile.PL
",
     '	$(PERL) "-I$(PERL_ARCHLIB)" "-I$(PERL_LIB)" -e \'use ExtUtils::Mksymlists; \\
     Mksymlists("NAME" => "$(NAME)", "DLBASE" => "$(DLBASE)", ',
     '"VERSION" => "$(VERSION)", "DISTNAME" => "$(DISTNAME)", ',
     '"INSTALLDIRS" => "$(INSTALLDIRS)", ',
     '"DL_FUNCS" => ',neatvalue($funcs),
     ', "FUNCLIST" => ',neatvalue($funclist),
     ', "IMPORTS" => ',neatvalue($imports),
     ', "DL_VARS" => ', neatvalue($vars), ');\'
');
    }
    if ($self->{IMPORTS} && %{$self->{IMPORTS}}) {
	# Make import files (needed for static build)
	-d 'tmp_imp' or mkdir 'tmp_imp', 0777 or die "Can't mkdir tmp_imp";
	open IMP, '>tmpimp.imp' or die "Can't open tmpimp.imp";
	my ($name, $exp);
	while (($name, $exp)= each %{$self->{IMPORTS}}) {
	    my ($lib, $id) = ($exp =~ /(.*)\.(.*)/) or die "Malformed IMPORT `$exp'";
	    print IMP "$name $lib $id ?\n";
	}
	close IMP or die "Can't close tmpimp.imp";
	# print "emximp -o tmpimp$Config::Config{lib_ext} tmpimp.imp\n";
	system "emximp -o tmpimp$Config::Config{lib_ext} tmpimp.imp" 
	    and die "Cannot make import library: $!, \$?=$?";
	unlink <tmp_imp/*>;
	system "cd tmp_imp; $Config::Config{ar} x ../tmpimp$Config::Config{lib_ext}" 
	    and die "Cannot extract import objects: $!, \$?=$?";      
    }
    join('',@m);
}

sub static_lib {
    my($self) = @_;
    my $old = $self->ExtUtils::MM_Unix::static_lib();
    return $old unless $self->{IMPORTS} && %{$self->{IMPORTS}};
    
    my @chunks = split /\n{2,}/, $old;
    shift @chunks unless length $chunks[0]; # Empty lines at the start
    $chunks[0] .= <<'EOC';

	$(AR) $(AR_STATIC_ARGS) $@ tmp_imp/* && $(RANLIB) $@
EOC
    return join "\n\n". '', @chunks;
}

sub replace_manpage_separator {
    my($self,$man) = @_;
    $man =~ s,/+,.,g;
    $man;
}

sub maybe_command {
    my($self,$file) = @_;
    $file =~ s,[/\\]+,/,g;
    return $file if -x $file && ! -d _;
    return "$file.exe" if -x "$file.exe" && ! -d _;
    return "$file.cmd" if -x "$file.cmd" && ! -d _;
    return;
}


sub init_linker {
    my $self = shift;

    $self->{PERL_ARCHIVE} = "\$(PERL_INC)/libperl\$(LIB_EXT)";

    $self->{PERL_ARCHIVE_AFTER} = $OS2::is_aout
      ? ''
      : '$(PERL_INC)/libperl_override$(LIB_EXT)';
    $self->{EXPORT_LIST} = '$(BASEEXT).def';
}


sub os_flavor {
    return('OS/2');
}


1;
