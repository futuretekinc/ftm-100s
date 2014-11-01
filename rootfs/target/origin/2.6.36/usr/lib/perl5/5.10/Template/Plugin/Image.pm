
package Template::Plugin::Image;

use strict;
use warnings;
use base 'Template::Plugin';
use Template::Exception;
use File::Spec;

our $VERSION = 1.21;
our $AUTOLOAD;

BEGIN {
    if (eval { require Image::Info; }) {
        *img_info = \&Image::Info::image_info;
    }
    elsif (eval { require Image::Size; }) {
        *img_info = sub {
            my $file = shift;
            my @stuff = Image::Size::imgsize($file);
            return { "width"  => $stuff[0],
                     "height" => $stuff[1],
                     "error"  =>
                        # imgsize returns either a three letter file type
                        # or an error message as third value
                        (defined($stuff[2]) && length($stuff[2]) > 3
                            ? $stuff[2]
                            : undef),
                   };
        }
    }
    else {
        die(Template::Exception->new("image",
            "Couldn't load Image::Info or Image::Size: $@"));
    }

}


sub new {
    my $config = ref($_[-1]) eq 'HASH' ? pop(@_) : { };
    my ($class, $context, $name) = @_;
    my ($root, $file, $type);

    # name can be a positional or named argument
    $name = $config->{ name } unless defined $name;

    return $class->throw('no image file specified')
        unless defined $name and length $name;

    # name can be specified as an absolute path or relative
    # to a root directory 

    if ($root = $config->{ root }) {
        $file = File::Spec->catfile($root, $name);
    }
    else {
        $file = defined $config->{file} ? $config->{file} : $name;
    }

    # Make a note of whether we are using Image::Size or
    # Image::Info -- at least for the test suite
    $type = $INC{"Image/Size.pm"} ? "Image::Size" : "Image::Info";

    # set a default (empty) alt attribute for tag()
    $config->{ alt } = '' unless defined $config->{ alt };

    # do we want to check to see if file exists?
    bless { 
        %$config,
        name => $name,
        file => $file,
        root => $root,
        type => $type,
    }, $class;
}


sub init {
    my $self = shift;
    return $self if $self->{ size };

    my $image = img_info($self->{ file });
    return $self->throw($image->{ error }) if defined $image->{ error };

    @$self{ keys %$image } = values %$image;
    $self->{ size } = [ $image->{ width }, $image->{ height } ];

    $self->{ modtime } = (stat $self->{ file })[10];

    return $self;
}


sub attr {
    my $self = shift;
    my $size = $self->size();
    return "width=\"$size->[0]\" height=\"$size->[1]\"";
}



sub modtime {
    my $self = shift;
    $self->init;
    return $self->{ modtime };
}



sub tag {
    my $self = shift;
    my $options = ref $_[0] eq 'HASH' ? shift : { @_ };

    my $tag = '<img src="' . $self->name() . '" ' . $self->attr();
 
    # XHTML spec says that the alt attribute is mandatory, so who
    # are we to argue?

    $options->{ alt } = $self->{ alt }
        unless defined $options->{ alt };

    if (%$options) {
        while (my ($key, $val) = each %$options) {
            my $escaped = escape( $val );
            $tag .= qq[ $key="$escaped"];
        }
    }

    $tag .= ' />';

    return $tag;
}

sub escape {
    my ($text) = @_;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
    }
    $text;
}

sub throw {
    my ($self, $error) = @_;
    die (Template::Exception->new('Image', $error));
}

sub AUTOLOAD {
    my $self = shift;
   (my $a = $AUTOLOAD) =~ s/.*:://;

    $self->init;
    return $self->{ $a };
}

1;

__END__


