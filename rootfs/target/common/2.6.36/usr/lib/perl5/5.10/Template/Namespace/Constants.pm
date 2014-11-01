
package Template::Namespace::Constants;

use strict;
use warnings;
use base 'Template::Base';
use Template::Config;
use Template::Directive;
use Template::Exception;

our $VERSION = 1.27;
our $DEBUG   = 0 unless defined $DEBUG;


sub _init {
    my ($self, $config) = @_;
    $self->{ STASH } = Template::Config->stash($config)
        || return $self->error(Template::Config->error());
    return $self;
}




sub ident {
    my ($self, $ident) = @_;
    my @save = @$ident;

    # discard first node indicating constants namespace
    splice(@$ident, 0, 2);

    my $nelems = @$ident / 2;
    my ($e, $result);
    local $" = ', ';

    print STDERR "constant ident [ @$ident ] " if $DEBUG;

    foreach $e (0..$nelems-1) {
        # node name must be a constant
        unless ($ident->[$e * 2] =~ s/^'(.+)'$/$1/s) {
            $self->DEBUG(" * deferred (non-constant item: ", $ident->[$e * 2], ")\n")
                if $DEBUG;
            return Template::Directive->ident(\@save);
        }

        # if args is non-zero then it must be eval'ed 
        if ($ident->[$e * 2 + 1]) {
            my $args = $ident->[$e * 2 + 1];
            my $comp = eval "$args";
            if ($@) {
                $self->DEBUG(" * deferred (non-constant args: $args)\n") if $DEBUG;
                return Template::Directive->ident(\@save);
            }
            $self->DEBUG("($args) ") if $comp && $DEBUG;
            $ident->[$e * 2 + 1] = $comp;
        }
    }


    $result = $self->{ STASH }->get($ident);

    if (! length $result || ref $result) {
        my $reason = length $result ? 'reference' : 'no result';
        $self->DEBUG(" * deferred ($reason)\n") if $DEBUG;
        return Template::Directive->ident(\@save);
    }

    $result =~ s/'/\\'/g;

    $self->DEBUG(" * resolved => '$result'\n") if $DEBUG;

    return "'$result'";
}

1;

__END__


