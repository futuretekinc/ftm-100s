
package Template::Plugin::HTML;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 2.62;

sub new {
    my ($class, $context, @args) = @_;
    my $hash = ref $args[-1] eq 'HASH' ? pop @args : { };
    bless {
        _SORTED => $hash->{ sorted } || 0,
    }, $class;
}

sub element {
    my ($self, $name, $attr) = @_;
    ($name, $attr) = %$name if ref $name eq 'HASH';
    return '' unless defined $name and length $name;
    $attr = $self->attributes($attr);
    $attr = " $attr" if $attr;
    return "<$name$attr>";
}

sub attributes {
    my ($self, $hash) = @_;
    return '' unless ref $hash eq 'HASH';

    my @keys = keys %$hash;
    @keys = sort @keys if $self->{ _SORTED };

    join(' ', map { 
        "$_=\"" . $self->escape( $hash->{ $_ } ) . '"';
    } @keys);
}

sub escape {
    my ($self, $text) = @_;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
    }
    $text;
}

sub url {
    my ($self, $text) = @_;
    return undef unless defined $text;
    $text =~ s/([^a-zA-Z0-9_.-])/uc sprintf("%%%02x",ord($1))/eg;
    return $text;
}


1;

__END__


