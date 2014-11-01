
package Template::Plugin::Directory;

use strict;
use warnings;
use Cwd;
use File::Spec;
use Template::Plugin::File;
use base 'Template::Plugin::File';

our $VERSION = 2.70;



sub new {
    my $config = ref($_[-1]) eq 'HASH' ? pop(@_) : { };
    my ($class, $context, $path) = @_;

    return $class->throw('no directory specified')
        unless defined $path and length $path;

    my $self = $class->SUPER::new($context, $path, $config);
    my ($dir, @files, $name, $item, $abs, $rel, $check);
    $self->{ files } = [ ];
    $self->{ dirs  } = [ ];
    $self->{ list  } = [ ];
    $self->{ _dir  } = { };

    # don't read directory if 'nostat' or 'noscan' set
    return $self if $config->{ nostat } || $config->{ noscan };

    $self->throw("$path: not a directory")
        unless $self->{ isdir };

    $self->scan($config);

    return $self;
}



sub scan {
    my ($self, $config) = @_;
    $config ||= { };
    local *DH;
    my ($dir, @files, $name, $abs, $rel, $item);
    
    # set 'noscan' in config if recurse isn't set, to ensure Directories
    # created don't try to scan deeper
    $config->{ noscan } = 1 unless $config->{ recurse };

    $dir = $self->{ abs };
    opendir(DH, $dir) or return $self->throw("$dir: $!");

    @files = readdir DH;
    closedir(DH) 
        or return $self->throw("$dir close: $!");

    my ($path, $files, $dirs, $list) = @$self{ qw( path files dirs list ) };
    @$files = @$dirs = @$list = ();

    foreach $name (sort @files) {
        next if $name =~ /^\./;
        $abs = File::Spec->catfile($dir, $name);
        $rel = File::Spec->catfile($path, $name);

        if (-d $abs) {
            $item = Template::Plugin::Directory->new(undef, $rel, $config);
            push(@$dirs, $item);
        }
        else {
            $item = Template::Plugin::File->new(undef, $rel, $config);
            push(@$files, $item);
        }
        push(@$list, $item);
        $self->{ _dir }->{ $name } = $item;
    }

    return '';
}



sub file {
    my ($self, $name) = @_;
    return $self->{ _dir }->{ $name };
}



sub present {
    my ($self, $view) = @_;
    $view->view_directory($self);
}



sub content {
    my ($self, $view) = @_;
    return $self->{ list } unless $view;
    my $output = '';
    foreach my $file (@{ $self->{ list } }) {
        $output .= $file->present($view);
    }
    return $output;
}



sub throw {
    my ($self, $error) = @_;
    die (Template::Exception->new('Directory', $error));
}

1;

__END__

