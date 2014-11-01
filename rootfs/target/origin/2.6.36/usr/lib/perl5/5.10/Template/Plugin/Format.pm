
package Template::Plugin::Format;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 2.70;


sub new {
    my ($class, $context, $format) = @_;;
    return defined $format
        ? make_formatter($format)
        : \&make_formatter;
}


sub make_formatter {
    my $format = shift;
    $format = '%s' unless defined $format;
    return sub { 
        my @args = @_;
        push(@args, '') unless @args;
        return sprintf($format, @args); 
    }
}


1;

__END__


