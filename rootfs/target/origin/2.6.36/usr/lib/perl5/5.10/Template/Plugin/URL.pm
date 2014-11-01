
package Template::Plugin::URL;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 2.74;
our $JOINT   = '&amp;';



sub new {
    my ($class, $context, $base, $args) = @_;
    $args ||= { };

    return sub {
        my $newbase = shift unless ref $_[0] eq 'HASH';
        my $newargs = shift || { };
        my $combo   = { %$args, %$newargs };
        my $urlargs = join($JOINT,
                           map  { args($_, $combo->{ $_ }) }
                           grep { defined $combo->{ $_ } && length $combo->{ $_ } }
                           sort keys %$combo);

        my $query = $newbase || $base || '';
        $query .= '?' if length $query && length $urlargs;
        $query .= $urlargs if length $urlargs;

        return $query
    }
}


sub args {
    my ($key, $val) = @_;
    $key = escape($key);
    
    return map {
        "$key=" . escape($_);
    } ref $val eq 'ARRAY' ? @$val : $val;
    
}


sub escape {
    my $toencode = shift;
    return undef unless defined($toencode);
    $toencode=~s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $toencode;
}

1;

__END__


