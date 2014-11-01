
package Template::Test;

use strict;
use warnings;
use Template qw( :template );
use Exporter;

our $VERSION = 2.75;
our $DEBUG   = 0;
our @ISA     = qw( Exporter );
our @EXPORT  = qw( ntests ok is match flush skip_all test_expect callsign banner );
our @EXPORT_OK = ( 'assert' );
our %EXPORT_TAGS = ( all => [ @EXPORT_OK, @EXPORT ] );
$| = 1;

our $REASON   = 'not applicable on this platform';
our $NO_FLUSH = 0;
our $EXTRA    = 0;   # any extra tests to come after test_expect()
our $PRESERVE = 0    # don't mangle newlines in output/expect
    unless defined $PRESERVE;

our ($loaded, %callsign);

$Template::BINMODE = ($^O eq 'MSWin32') ? 1 : 0;

my @results = ();
my ($ntests, $ok_count);
*is = \&match;

END {
    # ensure flush() is called to print any cached results 
    flush();
}



sub ntests {
    $ntests = shift;
    # add any pre-declared extra tests, or pre-stored test @results, to 
    # the grand total of tests
    $ntests += $EXTRA + scalar @results;     
    $ok_count = 1;
    print $ntests ? "1..$ntests\n" : "1..$ntests # skip $REASON\n";
    # flush cached results
    foreach my $pre_test (@results) {
        ok(@$pre_test);
    }
}



sub ok {
    my ($ok, $msg) = @_;

    # cache results if ntests() not yet called
    unless ($ok_count) {
        push(@results, [ $ok, $msg ]);
        return $ok;
    }

    $msg = defined $msg ? " - $msg" : '';
    if ($ok) {
        print "ok ", $ok_count++, "$msg\n";
    }
    else {
        print STDERR "FAILED $ok_count: $msg\n" if defined $msg;
        print "not ok ", $ok_count++, "$msg\n";
    }
}




sub assert {
    my ($ok, $err) = @_;
    return ok(1) if $ok;

    # failed
    my ($pkg, $file, $line) = caller();
    $err ||= "assert failed";
    $err .= " at $file line $line\n";
    ok(0);
    die $err;
}


sub match {
    my ($result, $expect, $msg) = @_;
    my $count = $ok_count ? $ok_count : scalar @results + 1;

    # force stringification of $result to avoid 'no eq method' overload errors
    $result = "$result" if ref $result;    

    if ($result eq $expect) {
        return ok(1, $msg);
    }
    else {
        print STDERR "FAILED $count:\n  expect: [$expect]\n  result: [$result]\n";
        return ok(0, $msg);
    }
}



sub flush {
    ntests(0)
    unless $ok_count || $NO_FLUSH;
}



sub skip_all {
    $REASON = join('', @_);
    exit(0);
}



sub test_expect {
    my ($src, $tproc, $params) = @_;
    my ($input, @tests);
    my ($output, $expect, $match);
    my $count = 0;
    my $ttprocs;

    # read input text
    eval {
        local $/ = undef;
        $input = ref $src ? <$src> : $src;
    };
    if ($@) {
        ntests(1); ok(0);
        warn "Cannot read input text from $src\n";
        return undef;
    }

    # remove any comment lines
    $input =~ s/^#.*?\n//gm;

    # remove anything before '-- start --' and/or after '-- stop --'
    $input = $' if $input =~ /\s*--\s*start\s*--\s*/;
    $input = $` if $input =~ /\s*--\s*stop\s*--\s*/;

    @tests = split(/^\s*--\s*test\s*--\s*\n/im, $input);

    # if the first line of the file was '--test--' (optional) then the 
    # first test will be empty and can be discarded
    shift(@tests) if $tests[0] =~ /^\s*$/;

    ntests(3 + scalar(@tests) * 2);

    # first test is that Template loaded OK, which it did
    ok(1, 'running test_expect()');

    # optional second param may contain a Template reference or a HASH ref
    # of constructor options, or may be undefined
    if (ref($tproc) eq 'HASH') {
        # create Template object using hash of config items
        $tproc = Template->new($tproc)
            || die Template->error(), "\n";
    }
    elsif (ref($tproc) eq 'ARRAY') {
        # list of [ name => $tproc, name => $tproc ], use first $tproc
        $ttprocs = { @$tproc };
        $tproc   = $tproc->[1];
    }
    elsif (! ref $tproc) {
        $tproc = Template->new()
            || die Template->error(), "\n";
    }
    # otherwise, we assume it's a Template reference

    # test: template processor created OK
    ok($tproc, 'template processor is engaged');

    # third test is that the input read ok, which it did
    ok(1, 'input read and split into ' . scalar @tests . ' tests');

    # the remaining tests are defined in @tests...
    foreach $input (@tests) {
        $count++;
        my $name = '';
        
        if ($input =~ s/^\s*-- name:? (.*?) --\s*\n//im) {
            $name = $1; 
        }
        else {
            $name = "template text $count";
        }

        # split input by a line like "-- expect --"
        ($input, $expect) = 
            split(/^\s*--\s*expect\s*--\s*\n/im, $input);
        $expect = '' 
            unless defined $expect;

        $output = '';

        # input text may be prefixed with "-- use name --" to indicate a
        # Template object in the $ttproc hash which we should use
        if ($input =~ s/^\s*--\s*use\s+(\S+)\s*--\s*\n//im) {
            my $ttname = $1;
            my $ttlookup;
            if ($ttlookup = $ttprocs->{ $ttname }) {
                $tproc = $ttlookup;
            }
            else {
                warn "no such template object to use: $ttname\n";
            }
        }

        # process input text
        $tproc->process(\$input, $params, \$output) || do {
            warn "Template process failed: ", $tproc->error(), "\n";
            # report failure and automatically fail the expect match
            ok(0, "$name process FAILED: " . subtext($input));
            ok(0, '(obviously did not match expected)');
            next;
        };

        # processed OK
        ok(1, "$name processed OK: " . subtext($input));

        # another hack: if the '-- expect --' section starts with 
        # '-- process --' then we process the expected output 
        # before comparing it with the generated output.  This is
        # slightly twisted but it makes it possible to run tests 
        # where the expected output isn't static.  See t/date.t for
        # an example.

        if ($expect =~ s/^\s*--+\s*process\s*--+\s*\n//im) {
            my $out;
            $tproc->process(\$expect, $params, \$out) || do {
                warn("Template process failed (expect): ", 
                     $tproc->error(), "\n");
                # report failure and automatically fail the expect match
                ok(0, "failed to process expected output ["
                   . subtext($expect) . ']');
                next;
            };
            $expect = $out;
        };      
        
        # strip any trailing blank lines from expected and real output
        foreach ($expect, $output) {
            s/[\n\r]*\Z//mg;
        }
        
        $match = ($expect eq $output) ? 1 : 0;
        if (! $match || $DEBUG) {
            print "MATCH FAILED\n"
                unless $match;
            
            my ($copyi, $copye, $copyo) = ($input, $expect, $output);
            unless ($PRESERVE) {
                foreach ($copyi, $copye, $copyo) {
                    s/\n/\\n/g;
                }
            }
            printf(" input: [%s]\nexpect: [%s]\noutput: [%s]\n", 
                   $copyi, $copye, $copyo);
        }
        
        ok($match, $match ? "$name matched expected" : "$name did not match expected");
    };
}


sub callsign {
    my %callsign;
    @callsign{ 'a'..'z' } = qw( 
        alpha bravo charlie delta echo foxtrot golf hotel india 
        juliet kilo lima mike november oscar papa quebec romeo 
        sierra tango umbrella victor whisky x-ray yankee zulu );
    return \%callsign;
}



sub banner {
    return unless $DEBUG;
    my $text = join('', @_);
    my $count = $ok_count ? $ok_count - 1 : scalar @results;
    print "-" x 72, "\n$text ($count tests completed)\n", "-" x 72, "\n";
}


sub subtext {
    my $text = shift;
    $text =~ s/\s*$//sg;
    $text = substr($text, 0, 32) . '...' if length $text > 32;
    $text =~ s/\n/\\n/g;
    return $text;
}


1;

__END__


