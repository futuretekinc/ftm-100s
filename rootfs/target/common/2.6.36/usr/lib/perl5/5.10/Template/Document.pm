
package Template::Document;

use strict;
use warnings;
use base 'Template::Base';
use Template::Constants;

our $VERSION = 2.79;
our $DEBUG   = 0 unless defined $DEBUG;
our $ERROR   = '';
our ($COMPERR, $AUTOLOAD, $UNICODE);

BEGIN {
    # UNICODE is supported in versions of Perl from 5.008 onwards
    if ($UNICODE = $] > 5.007 ? 1 : 0) {
        if ($] > 5.008) {
            # utf8::is_utf8() available from Perl 5.8.1 onwards
            *is_utf8 = \&utf8::is_utf8;
        }
        elsif ($] == 5.008) {
            # use Encode::is_utf8() for Perl 5.8.0
            require Encode;
            *is_utf8 = \&Encode::is_utf8;
        }
    }
}




sub new {
    my ($class, $doc) = @_;
    my ($block, $defblocks, $metadata) = @$doc{ qw( BLOCK DEFBLOCKS METADATA ) };
    $defblocks ||= { };
    $metadata  ||= { };

    # evaluate Perl code in $block to create sub-routine reference if necessary
    unless (ref $block) {
        local $SIG{__WARN__} = \&catch_warnings;
        $COMPERR = '';

        # DON'T LOOK NOW! - blindly untainting can make you go blind!
        $block =~ /(.*)/s;
        $block = $1;
        
        $block = eval $block;
        return $class->error($@)
            unless defined $block;
    }

    # same for any additional BLOCK definitions
    @$defblocks{ keys %$defblocks } = 
        # MORE BLIND UNTAINTING - turn away if you're squeamish
        map { 
            ref($_) 
                ? $_ 
                : ( /(.*)/s && eval($1) or return $class->error($@) )
            } values %$defblocks;
    
    bless {
        %$metadata,
        _BLOCK     => $block,
        _DEFBLOCKS => $defblocks,
        _HOT       => 0,
    }, $class;
}



sub block {
    return $_[0]->{ _BLOCK };
}



sub blocks {
    return $_[0]->{ _DEFBLOCKS };
}



sub process {
    my ($self, $context) = @_;
    my $defblocks = $self->{ _DEFBLOCKS };
    my $output;


    # check we're not already visiting this template
    return $context->throw(Template::Constants::ERROR_FILE, 
                           "recursion into '$self->{ name }'")
        if $self->{ _HOT } && ! $context->{ RECURSION };   ## RETURN ##

    $context->visit($self, $defblocks);

    $self->{ _HOT } = 1;
    eval {
        my $block = $self->{ _BLOCK };
        $output = &$block($context);
    };
    $self->{ _HOT } = 0;

    $context->leave();

    die $context->catch($@)
        if $@;
        
    return $output;
}



sub AUTOLOAD {
    my $self   = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;
    return if $method eq 'DESTROY';
    return $self->{ $method };
}





sub _dump {
    my $self = shift;
    my $dblks;
    my $output = "$self : $self->{ name }\n";

    $output .= "BLOCK: $self->{ _BLOCK }\nDEFBLOCKS:\n";

    if ($dblks = $self->{ _DEFBLOCKS }) {
        foreach my $b (keys %$dblks) {
            $output .= "    $b: $dblks->{ $b }\n";
        }
    }

    return $output;
}




sub as_perl {
    my ($class, $content) = @_;
    my ($block, $defblocks, $metadata) = @$content{ qw( BLOCK DEFBLOCKS METADATA ) };

    $block =~ s/\n(?!#line)/\n    /g;
    $block =~ s/\s+$//;

    $defblocks = join('', map {
        my $code = $defblocks->{ $_ };
        $code =~ s/\n(?!#line)/\n        /g;
        $code =~ s/\s*$//;
        "        '$_' => $code,\n";
    } keys %$defblocks);
    $defblocks =~ s/\s+$//;

    $metadata = join('', map { 
        my $x = $metadata->{ $_ }; 
        $x =~ s/(['\\])/\\$1/g; 
        "        '$_' => '$x',\n";
    } keys %$metadata);
    $metadata =~ s/\s+$//;

    return <<EOF

$class->new({
    METADATA => {
$metadata
    },
    BLOCK => $block,
    DEFBLOCKS => {
$defblocks
    },
});
EOF
}



sub write_perl_file {
    my ($class, $file, $content) = @_;
    my ($fh, $tmpfile);
    
    return $class->error("invalid filename: $file")
        unless $file =~ /^(.+)$/s;

    eval {
        require File::Temp;
        require File::Basename;
        ($fh, $tmpfile) = File::Temp::tempfile( 
            DIR => File::Basename::dirname($file) 
        );
        my $perlcode = $class->as_perl($content) || die $!;
        
        if ($UNICODE && is_utf8($perlcode)) {
            $perlcode = "use utf8;\n\n$perlcode";
            binmode $fh, ":utf8";
        }
        print $fh $perlcode;
        close($fh);
    };
    return $class->error($@) if $@;
    return rename($tmpfile, $file)
        || $class->error($!);
}



sub catch_warnings {
    $COMPERR .= join('', @_); 
}

    
1;

__END__


