
package XML::SAX::DocumentLocator;
use strict;

sub new {
    my $class = shift;
    my %object;
    tie %object, $class, @_;

    return bless \%object, $class;
}

sub TIEHASH {
    my $class = shift;
    my ($pubmeth, $sysmeth, $linemeth, $colmeth, $encmeth, $xmlvmeth) = @_;
    return bless { 
        pubmeth => $pubmeth,
        sysmeth => $sysmeth,
        linemeth => $linemeth,
        colmeth => $colmeth,
        encmeth => $encmeth,
        xmlvmeth => $xmlvmeth,
    }, $class;
}

sub FETCH {
    my ($self, $key) = @_;
    my $method;
    if ($key eq 'PublicId') {
        $method = $self->{pubmeth};
    }
    elsif ($key eq 'SystemId') {
        $method = $self->{sysmeth};
    }
    elsif ($key eq 'LineNumber') {
        $method = $self->{linemeth};
    }
    elsif ($key eq 'ColumnNumber') {
        $method = $self->{colmeth};
    }
    elsif ($key eq 'Encoding') {
        $method = $self->{encmeth};
    }
    elsif ($key eq 'XMLVersion') {
        $method = $self->{xmlvmeth};
    }
    if ($method) {
        my $value = $method->($key);
        return $value;
    }
    return undef;
}

sub EXISTS {
    my ($self, $key) = @_;
    if ($key =~ /^(PublicId|SystemId|LineNumber|ColumnNumber|Encoding|XMLVersion)$/) {
        return 1;
    }
    return 0;
}

sub STORE {
    my ($self, $key, $value) = @_;
}

sub DELETE {
    my ($self, $key) = @_;
}

sub CLEAR {
    my ($self) = @_;
}

sub FIRSTKEY {
    my ($self) = @_;
    # assignment resets.
    $self->{keys} = {
        PublicId => 1,
        SystemId => 1,
        LineNumber => 1,
        ColumnNumber => 1,
        Encoding => 1,
        XMLVersion => 1,
    };
    return each %{$self->{keys}};
}

sub NEXTKEY {
    my ($self, $lastkey) = @_;
    return each %{$self->{keys}};
}

1;
__END__


