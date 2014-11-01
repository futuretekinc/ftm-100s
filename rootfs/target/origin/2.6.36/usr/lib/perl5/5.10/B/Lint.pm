package B::Lint;

our $VERSION = '1.09';    ## no critic


use strict;
use B qw( walkoptree_slow
    main_root main_cv walksymtable parents
    OPpOUR_INTRO
    OPf_WANT_VOID OPf_WANT_LIST OPf_WANT OPf_STACKED SVf_POK );
use Carp 'carp';

use Module::Pluggable ( require => 1 );

use List::Util 'first';
sub any (&@) { my $test = shift @_; $test->() and return 1 for @_; return 0 }

BEGIN {

    # Import or create some constants from B. B doesn't provide
    # everything I need so some things like OPpCONST_BARE are defined
    # here.
    for my $sym ( qw( begin_av check_av init_av end_av ),
        [ 'OPpCONST_BARE' => 64 ] )
    {
        my $val;
        ( $sym, $val ) = @$sym if ref $sym;

        if ( any { $sym eq $_ } @B::EXPORT_OK, @B::EXPORT ) {
            B->import($sym);
        }
        else {
            require constant;
            constant->import( $sym => $val );
        }
    }
}

my $file     = "unknown";    # shadows current filename
my $line     = 0;            # shadows current line number
my $curstash = "main";       # shadows current stash
my $curcv;                   # shadows current B::CV for pad lookups

sub file     {$file}
sub line     {$line}
sub curstash {$curstash}
sub curcv    {$curcv}

my %check;
my %implies_ok_context;

map( $implies_ok_context{$_}++,
    qw(scalar av2arylen aelem aslice helem hslice
        keys values hslice defined undef delete) );

my @default_checks
    = qw(context magic_diamond undefined_subs regexp_variables);

my %valid_check;

for my $check (
    qw(context implicit_read implicit_write dollar_underscore
    private_names bare_subs undefined_subs regexp_variables
    magic_diamond )
    )
{
    $valid_check{$check} = __PACKAGE__;
}

my ($debug_op);

my %done_cv;           # used to mark which subs have already been linted
my @extra_packages;    # Lint checks mainline code and all subs which are
                       # in main:: or in one of these packages.

sub warning {
    my $format = ( @_ < 2 ) ? "%s" : shift @_;
    warn sprintf( "$format at %s line %d\n", @_, $file, $line );
    return undef;      ## no critic undef
}

sub gimme {
    my $op    = shift @_;
    my $flags = $op->flags;
    if ( $flags & OPf_WANT ) {
        return ( ( $flags & OPf_WANT ) == OPf_WANT_LIST ? 1 : 0 );
    }
    return undef;      ## no critic undef
}

my @plugins = __PACKAGE__->plugins;

sub inside_grepmap {

    # A boolean function to be used while inside a B::walkoptree_slow
    # call. If we are in the EXPR part of C<grep EXPR, ...> or C<grep
    # { EXPR } ...>, this returns true.
    return any { $_->name =~ m/\A(?:grep|map)/xms } @{ parents() };
}

sub inside_foreach_modifier {

    # TODO: use any()

    # A boolean function to be used while inside a B::walkoptree_slow
    # call. If we are in the EXPR part of C<EXPR foreach ...> this
    # returns true.
    for my $ancestor ( @{ parents() } ) {
        next unless $ancestor->name eq 'leaveloop';

        my $first = $ancestor->first;
        next unless $first->name eq 'enteriter';

        next if $first->redoop->name =~ m/\A(?:next|db|set)state\z/xms;

        return 1;
    }
    return 0;
}

for (
    [qw[ B::PADOP::gv_harder gv padix]],
    [qw[ B::SVOP::sv_harder  sv targ]],
    [qw[ B::SVOP::gv_harder gv padix]]
    )
{

    # I'm generating some functions here because they're mostly
    # similar. It's all for compatibility with threaded
    # perl. Perhaps... this code should inspect $Config{usethreads}
    # and generate a *specific* function. I'm leaving it generic for
    # the moment.
    #
    # In threaded perl SVs and GVs aren't used directly in the optrees
    # like they are in non-threaded perls. The ops that would use a SV
    # or GV keep an index into the subroutine's scratchpad. I'm
    # currently ignoring $cv->DEPTH and that might be at my peril.

    my ( $subname, $attr, $pad_attr ) = @$_;
    my $target = do {    ## no critic strict
        no strict 'refs';
        \*$subname;
    };
    *$target = sub {
        my ($op) = @_;

        my $elt;
        if ( not $op->isa('B::PADOP') ) {
            $elt = $op->$attr;
        }
        return $elt if eval { $elt->isa('B::SV') };

        my $ix         = $op->$pad_attr;
        my @entire_pad = $curcv->PADLIST->ARRAY;
        my @elts       = map +( $_->ARRAY )[$ix], @entire_pad;
        ($elt) = first {
            eval { $_->isa('B::SV') } ? $_ : ();
            }
            @elts[ 0, reverse 1 .. $#elts ];
        return $elt;
    };
}

sub B::OP::lint {
    my ($op) = @_;

    # This is a fallback ->lint for all the ops where I haven't
    # defined something more specific. Nothing happens here.

    # Call all registered plugins
    my $m;
    $m = $_->can('match'), $op->$m( \%check ) for @plugins;
    return;
}

sub B::COP::lint {
    my ($op) = @_;

    # nextstate ops sit between statements. Whenever I see one I
    # update the current info on file, line, and stash. This code also
    # updates it when it sees a dbstate or setstate op. I have no idea
    # what those are but having seen them mentioned together in other
    # parts of the perl I think they're kind of equivalent.
    if ( $op->name =~ m/\A(?:next|db|set)state\z/ ) {
        $file     = $op->file;
        $line     = $op->line;
        $curstash = $op->stash->NAME;
    }

    # Call all registered plugins
    my $m;
    $m = $_->can('match'), $op->$m( \%check ) for @plugins;
    return;
}

sub B::UNOP::lint {
    my ($op) = @_;

    my $opname = $op->name;

CONTEXT: {

        # Check arrays and hashes in scalar or void context where
        # scalar() hasn't been used.

        next
            unless $check{context}
            and $opname =~ m/\Arv2[ah]v\z/xms
            and not gimme($op);

        my ( $parent, $gparent ) = @{ parents() }[ 0, 1 ];
        my $pname = $parent->name;

        next if $implies_ok_context{$pname};

        # Three special cases to deal with: "foreach (@foo)", "delete
        # $a{$b}", and "exists $a{$b}" null out the parent so we have to
        # check for a parent of pp_null and a grandparent of
        # pp_enteriter, pp_delete, pp_exists

        next
            if $pname eq "null"
            and $gparent->name =~ m/\A(?:delete|enteriter|exists)\z/xms;

        # our( @bar ); would also trigger this error so I exclude
        # that.
        next
            if $op->private & OPpOUR_INTRO
            and ( $op->flags & OPf_WANT ) == OPf_WANT_VOID;

        warning 'Implicit scalar context for %s in %s',
            $opname eq "rv2av" ? "array" : "hash", $parent->desc;
    }

PRIVATE_NAMES: {

        # Looks for calls to methods with names that begin with _ and
        # that aren't visible within the current package. Maybe this
        # should look at @ISA.
        next
            unless $check{private_names}
            and $opname =~ m/\Amethod/xms;

        my $methop = $op->first;
        next unless $methop->name eq "const";

        my $method = $methop->sv_harder->PV;
        next
            unless $method =~ m/\A_/xms
            and not defined &{"$curstash\::$method"};

        warning q[Illegal reference to private method name '%s'], $method;
    }

    # Call all registered plugins
    my $m;
    $m = $_->can('match'), $op->$m( \%check ) for @plugins;
    return;
}

sub B::PMOP::lint {
    my ($op) = @_;

IMPLICIT_READ: {

        # Look for /.../ that doesn't use =~ to bind to something.
        next
            unless $check{implicit_read}
            and $op->name eq "match"
            and not( $op->flags & OPf_STACKED
            or inside_grepmap() );
        warning 'Implicit match on $_';
    }

IMPLICIT_WRITE: {

        # Look for s/.../.../ that doesn't use =~ to bind to
        # something.
        next
            unless $check{implicit_write}
            and $op->name eq "subst"
            and not $op->flags & OPf_STACKED;
        warning 'Implicit substitution on $_';
    }

    # Call all registered plugins
    my $m;
    $m = $_->can('match'), $op->$m( \%check ) for @plugins;
    return;
}

sub B::LOOP::lint {
    my ($op) = @_;

IMPLICIT_FOO: {

        # Look for C<for ( ... )>.
        next
            unless ( $check{implicit_read} or $check{implicit_write} )
            and $op->name eq "enteriter";

        my $last = $op->last;
        next
            unless $last->name         eq "gv"
            and $last->gv_harder->NAME eq "_"
            and $op->redoop->name =~ m/\A(?:next|db|set)state\z/xms;

        warning 'Implicit use of $_ in foreach';
    }

    # Call all registered plugins
    my $m;
    $m = $_->can('match'), $op->$m( \%check ) for @plugins;
    return;
}

*B::PADOP::lint = \&B::SVOP::lint;

sub B::SVOP::lint {
    my ($op) = @_;

MAGIC_DIAMOND: {
        next
            unless $check{magic_diamond}
            and parents()->[0]->name eq 'readline'
            and $op->gv_harder->NAME eq 'ARGV';

        warning 'Use of <>';
    }

BARE_SUBS: {
        next
            unless $check{bare_subs}
            and $op->name eq 'const'
            and $op->private & OPpCONST_BARE;

        my $sv = $op->sv_harder;
        next unless $sv->FLAGS & SVf_POK;

        my $sub     = $sv->PV;
        my $subname = "$curstash\::$sub";

        # I want to skip over things that were declared with the
        # constant pragma. Well... sometimes. Hmm. I want to ignore
        # C<<use constant FOO => ...>> but warn on C<<FOO => ...>>
        # later. The former is typical declaration syntax and the
        # latter would be an error.
        #
        # Skipping over both could be handled by looking if
        # $constant::declared{$subname} is true.

        # Check that it's a function.
        next
            unless exists &{"$curstash\::$sub"};

        warning q[Bare sub name '%s' interpreted as string], $sub;
    }

PRIVATE_NAMES: {
        next unless $check{private_names};

        my $opname = $op->name;
        if ( $opname =~ m/\Agv(?:sv)?\z/xms ) {

            # Looks for uses of variables and stuff that are named
            # private and we're not in the same package.
            my $gv   = $op->gv_harder;
            my $name = $gv->NAME;
            next
                unless $name =~ m/\A_./xms
                and $gv->STASH->NAME ne $curstash;

            warning q[Illegal reference to private name '%s'], $name;
        }
        elsif ( $opname eq "method_named" ) {
            my $method = $op->sv_harder->PV;
            next unless $method =~ m/\A_./xms;

            warning q[Illegal reference to private method name '%s'], $method;
        }
    }

DOLLAR_UNDERSCORE: {

        # Warn on uses of $_ with a few exceptions. I'm not warning on
        # $_ inside grep, map, or statement modifer foreach because
        # they localize $_ and it'd be impossible to use these
        # features without getting warnings.

        next
            unless $check{dollar_underscore}
            and $op->name            eq "gvsv"
            and $op->gv_harder->NAME eq "_"
            and not( inside_grepmap
            or inside_foreach_modifier );

        warning 'Use of $_';
    }

REGEXP_VARIABLES: {

        # Look for any uses of $`, $&, or $'.
        next
            unless $check{regexp_variables}
            and $op->name eq "gvsv";

        my $name = $op->gv_harder->NAME;
        next unless $name =~ m/\A[\&\'\`]\z/xms;

        warning 'Use of regexp variable $%s', $name;
    }

UNDEFINED_SUBS: {

        # Look for calls to functions that either don't exist or don't
        # have a definition.
        next
            unless $check{undefined_subs}
            and $op->name       eq "gv"
            and $op->next->name eq "entersub";

        my $gv      = $op->gv_harder;
        my $subname = $gv->STASH->NAME . "::" . $gv->NAME;

        no strict 'refs';    ## no critic strict
        if ( not exists &$subname ) {
            $subname =~ s/\Amain:://;
            warning q[Nonexistant subroutine '%s' called], $subname;
        }
        elsif ( not defined &$subname ) {
            $subname =~ s/\A\&?main:://;
            warning q[Undefined subroutine '%s' called], $subname;
        }
    }

    # Call all registered plugins
    my $m;
    $m = $_->can('match'), $op->$m( \%check ) for @plugins;
    return;
}

sub B::GV::lintcv {

    # Example: B::svref_2object( \ *A::Glob )->lintcv

    my $gv = shift @_;
    my $cv = $gv->CV;
    return unless $cv->can('lintcv');
    $cv->lintcv;
    return;
}

sub B::CV::lintcv {

    # Example: B::svref_2object( \ &foo )->lintcv

    # Write to the *global* $
    $curcv = shift @_;

    #warn sprintf("lintcv: %s::%s (done=%d)\n",
    #		 $gv->STASH->NAME, $gv->NAME, $done_cv{$$curcv});#debug
    return unless ref($curcv) and $$curcv and not $done_cv{$$curcv}++;
    my $root = $curcv->ROOT;

    #warn "    root = $root (0x$$root)\n";#debug
    walkoptree_slow( $root, "lint" ) if $$root;
    return;
}

sub do_lint {
    my %search_pack;

    # Copy to the global $curcv for use in pad lookups.
    $curcv = main_cv;
    walkoptree_slow( main_root, "lint" ) if ${ main_root() };

    # Do all the miscellaneous non-sub blocks.
    for my $av ( begin_av, init_av, check_av, end_av ) {
        next unless eval { $av->isa('B::AV') };
        for my $cv ( $av->ARRAY ) {
            next unless ref($cv) and $cv->FILE eq $0;
            $cv->lintcv;
        }
    }

    walksymtable(
        \%main::,
        sub {
            if ( $_[0]->FILE eq $0 ) { $_[0]->lintcv }
        },
        sub {1}
    );
    return;
}

sub compile {
    my @options = @_;

    # Turn on default lint checks
    for my $opt (@default_checks) {
        $check{$opt} = 1;
    }

OPTION:
    while ( my $option = shift @options ) {
        my ( $opt, $arg );
        unless ( ( $opt, $arg ) = $option =~ m/\A-(.)(.*)/xms ) {
            unshift @options, $option;
            last OPTION;
        }

        if ( $opt eq "-" && $arg eq "-" ) {
            shift @options;
            last OPTION;
        }
        elsif ( $opt eq "D" ) {
            $arg ||= shift @options;
            foreach my $arg ( split //, $arg ) {
                if ( $arg eq "o" ) {
                    B->debug(1);
                }
                elsif ( $arg eq "O" ) {
                    $debug_op = 1;
                }
            }
        }
        elsif ( $opt eq "u" ) {
            $arg ||= shift @options;
            push @extra_packages, $arg;
        }
    }

    foreach my $opt ( @default_checks, @options ) {
        $opt =~ tr/-/_/;
        if ( $opt eq "all" ) {
            %check = %valid_check;
        }
        elsif ( $opt eq "none" ) {
            %check = ();
        }
        else {
            if ( $opt =~ s/\Ano_//xms ) {
                $check{$opt} = 0;
            }
            else {
                $check{$opt} = 1;
            }
            carp "No such check: $opt"
                unless defined $valid_check{$opt};
        }
    }

    # Remaining arguments are things to check. So why aren't I
    # capturing them or something? I don't know.

    return \&do_lint;
}

sub register_plugin {
    my ( undef, $plugin, $new_checks ) = @_;

    # Allow the user to be lazy and not give us a name.
    $plugin = caller unless defined $plugin;

    # Register the plugin's named checks, if any.
    for my $check ( eval {@$new_checks} ) {
        if ( not defined $check ) {
            carp 'Undefined value in checks.';
            next;
        }
        if ( exists $valid_check{$check} ) {
            carp
                "$check is already registered as a $valid_check{$check} feature.";
            next;
        }

        $valid_check{$check} = $plugin;
    }

    # Register a non-Module::Pluggable loaded module. @plugins already
    # contains whatever M::P found on disk. The user might load a
    # plugin manually from some arbitrary namespace and ask for it to
    # be registered.
    if ( not any { $_ eq $plugin } @plugins ) {
        push @plugins, $plugin;
    }

    return;
}

1;
