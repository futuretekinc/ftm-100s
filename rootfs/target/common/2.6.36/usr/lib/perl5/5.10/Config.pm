
package Config;
use strict;
@Config::EXPORT = qw(%Config);
@Config::EXPORT_OK = qw(myconfig config_sh config_vars config_re);


sub myconfig;
sub config_sh;
sub config_vars;
sub config_re;

my %Export_Cache = map {($_ => 1)} (@Config::EXPORT, @Config::EXPORT_OK);

our %Config;

sub import {
    my $pkg = shift;
    @_ = @Config::EXPORT unless @_;

    my @funcs = grep $_ ne '%Config', @_;
    my $export_Config = @funcs < @_ ? 1 : 0;

    no strict 'refs';
    my $callpkg = caller(0);
    foreach my $func (@funcs) {
	die sprintf qq{"%s" is not exported by the %s module\n},
	    $func, __PACKAGE__ unless $Export_Cache{$func};
	*{$callpkg.'::'.$func} = \&{$func};
    }

    *{"$callpkg\::Config"} = \%Config if $export_Config;
    return;
}

die "Perl lib version (5.10.0) doesn't match executable version ($])"
    unless $^V;

$^V eq 5.10.0
    or die "Perl lib version (5.10.0) doesn't match executable version (" .
	sprintf("v%vd",$^V) . ")";


sub FETCH {
    my($self, $key) = @_;

    # check for cached value (which may be undef so we use exists not defined)
    return $self->{$key} if exists $self->{$key};

    return $self->fetch_string($key);
}
sub TIEHASH {
    bless $_[1], $_[0];
}

sub DESTROY { }

sub AUTOLOAD {
    require 'Config_heavy.pl';
    goto \&launcher unless $Config::AUTOLOAD =~ /launcher$/;
    die "&Config::AUTOLOAD failed on $Config::AUTOLOAD";
}

tie %Config, 'Config', {
    archlibexp => '',
    archname => 'arm-linux-uclibc',
    cc => 'arm-openwrt-linux-uclibcgnueabi-gcc',
    d_readlink => 'define',
    d_symlink => 'define',
    dlsrc => 'dl_dlopen.xs',
    dont_use_nlink => undef,
    exe_ext => '',
    inc_version_list => ' ',
    intsize => '4',
    ldlibpthname => 'LD_LIBRARY_PATH',
    libpth => '/home/xtra/Work/cortina/openwrt-2.6.36/staging_dir/target-arm_uClibc-0.9.32_eabi/lib /home/xtra/Work/cortina/openwrt-2.6.36/staging_dir/target-arm_uClibc-0.9.32_eabi/usr/lib',
    osname => 'linux',
    osvers => '2.6.22',
    path_sep => ':',
    privlibexp => '/usr/lib/perl5/5.10',
    scriptdir => '/usr/bin',
    sitearchexp => '',
    sitelibexp => '',
    useithreads => undef,
    usevendorprefix => undef,
    version => '5.10.0',
};
