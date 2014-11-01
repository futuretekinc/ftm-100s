
package Template::Plugin::CGI;

use strict;
use warnings;
use base 'Template::Plugin';
use CGI;

our $VERSION = 2.70;

sub new {
    my $class   = shift;
    my $context = shift;
    CGI->new(@_);
}


sub CGI::params {
    my $self = shift;
    local $" = ', ';

    return $self->{ _TT_PARAMS } ||= do {
        # must call Vars() in a list context to receive
        # plain list of key/vals rather than a tied hash
        my $params = { $self->Vars() };

        # convert any null separated values into lists
        @$params{ keys %$params } = map { 
            /\0/ ? [ split /\0/ ] : $_ 
        } values %$params;

        $params;
    };
}

1;

__END__


