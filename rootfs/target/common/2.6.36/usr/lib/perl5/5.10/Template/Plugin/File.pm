
package Template::Plugin::File;

use strict;
use warnings;
use Cwd;
use File::Spec;
use File::Basename;
use base 'Template::Plugin';

our $VERSION = 2.71;

our @STAT_KEYS = qw( dev ino mode nlink uid gid rdev size 
                     atime mtime ctime blksize blocks );



sub new {
    my $config = ref($_[-1]) eq 'HASH' ? pop(@_) : { };
    my ($class, $context, $path) = @_;
    my ($root, $home, @stat, $abs);

    return $class->throw('no file specified')
        unless defined $path and length $path;

    # path, dir, name, root, home

    if (File::Spec->file_name_is_absolute($path)) {
        $root = '';
    }
    elsif (($root = $config->{ root })) {
        # strip any trailing '/' from root
        $root =~ s[/$][];
    }
    else {
        $root = '';
    }

    my ($name, $dir, $ext) = fileparse($path, '\.\w+');
    # fixup various items
    $dir  =~ s[/$][];
    $dir  = '' if $dir eq '.';
    $name = $name . $ext;
    $ext  =~ s/^\.//g;

    my @fields = File::Spec->splitdir($dir);
    shift @fields if @fields && ! length $fields[0];
    $home = join('/', ('..') x @fields);
    $abs = File::Spec->catfile($root ? $root : (), $path);

    my $self = { 
        path  => $path,
        name  => $name,
        root  => $root,
        home  => $home,
        dir   => $dir,
        ext   => $ext,
        abs   => $abs,
        user  => '',
        group => '',
        isdir => '',
        stat  => defined $config->{ stat } 
                       ? $config->{ stat } 
                       : ! $config->{ nostat },
        map { ($_ => '') } @STAT_KEYS,
    };

    if ($self->{ stat }) {
        (@stat = stat( $abs ))
            || return $class->throw("$abs: $!");

        @$self{ @STAT_KEYS } = @stat;

        unless ($config->{ noid }) {
            $self->{ user  } = eval { getpwuid( $self->{ uid }) || $self->{ uid } };
            $self->{ group } = eval { getgrgid( $self->{ gid }) || $self->{ gid } };
        }
        $self->{ isdir } = -d $abs;
    }

    bless $self, $class;
}



sub rel {
    my ($self, $path) = @_;
    $path = $path->{ path } if ref $path eq ref $self;  # assumes same root
    return $path if $path =~ m[^/];
    return $path unless $self->{ home };
    return $self->{ home } . '/' . $path;
}



sub present {
    my ($self, $view) = @_;
    $view->view_file($self);
}


sub throw {
    my ($self, $error) = @_;
    die (Template::Exception->new('File', $error));
}

1;

__END__

