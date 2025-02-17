package ExtUtils::Mkbootstrap;

use strict 'refs';

use vars qw($VERSION @ISA @EXPORT);
$VERSION = '6.42';

require Exporter;
@ISA = ('Exporter');
@EXPORT = ('&Mkbootstrap');

use Config;

use vars qw($Verbose);


sub Mkbootstrap {
    my($baseext, @bsloadlibs)=@_;
    @bsloadlibs = grep($_, @bsloadlibs); # strip empty libs

    print STDOUT "	bsloadlibs=@bsloadlibs\n" if $Verbose;

    # We need DynaLoader here because we and/or the *_BS file may
    # call dl_findfile(). We don't say `use' here because when
    # first building perl extensions the DynaLoader will not have
    # been built when MakeMaker gets first used.
    require DynaLoader;

    rename "$baseext.bs", "$baseext.bso"
      if -s "$baseext.bs";

    if (-f "${baseext}_BS"){
	$_ = "${baseext}_BS";
	package DynaLoader; # execute code as if in DynaLoader
	local($osname, $dlsrc) = (); # avoid warnings
	($osname, $dlsrc) = @Config::Config{qw(osname dlsrc)};
	$bscode = "";
	unshift @INC, ".";
	require $_;
	shift @INC;
    }

    if ($Config{'dlsrc'} =~ /^dl_dld/){
	package DynaLoader;
	push(@dl_resolve_using, dl_findfile('-lc'));
    }

    my(@all) = (@bsloadlibs, @DynaLoader::dl_resolve_using);
    my($method) = '';
    if (@all){
	open BS, ">$baseext.bs"
		or die "Unable to open $baseext.bs: $!";
	print STDOUT "Writing $baseext.bs\n";
	print STDOUT "	containing: @all" if $Verbose;
	print BS "# $baseext DynaLoader bootstrap file for $^O architecture.\n";
	print BS "# Do not edit this file, changes will be lost.\n";
	print BS "# This file was automatically generated by the\n";
	print BS "# Mkbootstrap routine in ExtUtils::Mkbootstrap (v$VERSION).\n";
	print BS "\@DynaLoader::dl_resolve_using = ";
	# If @all contains names in the form -lxxx or -Lxxx then it's asking for
	# runtime library location so we automatically add a call to dl_findfile()
	if (" @all" =~ m/ -[lLR]/){
	    print BS "  dl_findfile(qw(\n  @all\n  ));\n";
	}else{
	    print BS "  qw(@all);\n";
	}
	# write extra code if *_BS says so
	print BS $DynaLoader::bscode if $DynaLoader::bscode;
	print BS "\n1;\n";
	close BS;
    }
}

1;

__END__

