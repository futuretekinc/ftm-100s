
package FCGI;

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT = qw(

);

$VERSION = q{0.74};

bootstrap FCGI;
$VERSION = eval $VERSION;


*FAIL_ACCEPT_ON_INTR = sub() { 1 };

sub Request(;***$*$) {
    my @defaults = (\*STDIN, \*STDOUT, \*STDERR, \%ENV, 0, FAIL_ACCEPT_ON_INTR());
    $_[4] = fileno($_[4]) if defined($_[4]) && defined(fileno($_[4]));
    splice @defaults,0,@_,@_;
    RequestX(@defaults);
}

sub accept() {
    warn "accept called as a method; you probably wanted to call Accept" if @_;
    if ( defined($FCGI::ENV) ) {
        %ENV = %$FCGI::ENV;
    } else {
        $FCGI::ENV = {%ENV};
    }
    my $rc = Accept($global_request);
    for (keys %$FCGI::ENV) {
        $ENV{$_} = $FCGI::ENV->{$_} unless exists $ENV{$_};
    }

    # not SFIO
    $SIG{__WARN__} = $warn_handler if (tied (*STDIN));
    $SIG{__DIE__} = $die_handler if (tied (*STDIN));

    return $rc;
}

sub finish() {
    warn "finish called as a method; you probably wanted to call Finish" if @_;
    %ENV = %$FCGI::ENV if defined($FCGI::ENV);

    # not SFIO
    if (tied (*STDIN)) {
        delete $SIG{__WARN__} if ($SIG{__WARN__} == $warn_handler);
        delete $SIG{__DIE__} if ($SIG{__DIE__} == $die_handler);
    }

    Finish ($global_request);
}

sub flush() {
    warn "flush called as a method; you probably wanted to call Flush" if @_;
    Flush($global_request);
}

sub detach() {
    warn "detach called as a method; you probably wanted to call Detach" if @_;
    Detach($global_request);
}

sub attach() {
    warn "attach called as a method; you probably wanted to call Attach" if @_;
    Attach($global_request);
}

sub set_exit_status {
}

sub start_filter_data() {
    StartFilterData($global_request);
}

$global_request = Request();
$warn_handler = sub { print STDERR @_ };
$die_handler = sub { print STDERR @_ unless $^S };

package FCGI::Stream;

sub PRINTF {
  shift->PRINT(sprintf(shift, @_));
}

sub BINMODE {
}

sub READLINE {
    my $stream = shift;
    my ($s, $c);
    my $rs = $/ eq '' ? "\n\n" : $/;
    my $l = substr $rs, -1;
    my $len = length $rs;

    $c = $stream->GETC();
    if ($/ eq '') {
        while ($c eq "\n") {
            $c = $stream->GETC();
        }
    }
    while (defined $c) {
        $s .= $c;
        last if $c eq $l and substr($s, -$len) eq $rs;
        $c = $stream->GETC();
    }
    $s;
}

sub OPEN {
    $_[0]->CLOSE;
    if (@_ == 2) {
        return open($_[0], $_[1]);
    } else {
        my $rc;
        eval("$rc = open($_[0], $_[1], $_[2])");
        die $@ if $@;
        return $rc;
    }
}

sub FILENO { -1 }

1;


__END__
