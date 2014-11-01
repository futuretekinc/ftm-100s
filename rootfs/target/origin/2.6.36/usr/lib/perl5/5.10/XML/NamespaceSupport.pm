

package XML::NamespaceSupport;
use strict;
use constant FATALS         => 0; # root object
use constant NSMAP          => 1;
use constant UNKNOWN_PREF   => 2;
use constant AUTO_PREFIX    => 3;
use constant XMLNS_11       => 4;
use constant DEFAULT        => 0; # maps
use constant PREFIX_MAP     => 1;
use constant DECLARATIONS   => 2;

use vars qw($VERSION $NS_XMLNS $NS_XML);
$VERSION    = '1.11';
$NS_XMLNS   = 'http://www.w3.org/2000/xmlns/';
$NS_XML     = 'http://www.w3.org/XML/1998/namespace';




sub new {
    my $class   = ref($_[0]) ? ref(shift) : shift;
    my $options = shift;
    my $self = [
                1, # FATALS
                [[ # NSMAP
                  undef,              # DEFAULT
                  { xml => $NS_XML }, # PREFIX_MAP
                  undef,              # DECLARATIONS
                ]],
                'aaa', # UNKNOWN_PREF
                0,     # AUTO_PREFIX
                1,     # XML_11
               ];
    $self->[NSMAP]->[0]->[PREFIX_MAP]->{xmlns} = $NS_XMLNS if $options->{xmlns};
    $self->[FATALS] = $options->{fatal_errors} if defined $options->{fatal_errors};
    $self->[AUTO_PREFIX] = $options->{auto_prefix} if defined $options->{auto_prefix};
    $self->[XMLNS_11] = $options->{xmlns_11} if defined $options->{xmlns_11};
    return bless $self, $class;
}

sub reset {
    my $self = shift;
    $#{$self->[NSMAP]} = 0;
}

sub push_context {
    my $self = shift;
    push @{$self->[NSMAP]}, [
                             $self->[NSMAP]->[-1]->[DEFAULT],
                             { %{$self->[NSMAP]->[-1]->[PREFIX_MAP]} },
                             [],
                            ];
}

sub pop_context {
    my $self = shift;
    die 'Trying to pop context without push context' unless @{$self->[NSMAP]} > 1;
    pop @{$self->[NSMAP]};
}

sub declare_prefix {
    my $self    = shift;
    my $prefix  = shift;
    my $value   = shift;

    warn <<'    EOWARN' unless defined $prefix or $self->[AUTO_PREFIX];
    Prefix was undefined.
    If you wish to set the default namespace, use the empty string ''.
    If you wish to autogenerate prefixes, set the auto_prefix option
    to a true value.
    EOWARN

    no warnings 'uninitialized';
    if ($prefix eq 'xml' and $value ne $NS_XML) {
        die "The xml prefix can only be bound to the $NS_XML namespace."
    }
    elsif ($value eq $NS_XML and $prefix ne 'xml') {
        die "the $NS_XML namespace can only be bound to the xml prefix.";
    }
    elsif ($value eq $NS_XML and $prefix eq 'xml') {
        return 1;
    }
    return 0 if index(lc($prefix), 'xml') == 0;
    use warnings 'uninitialized';

    if (defined $prefix and $prefix eq '') {
        $self->[NSMAP]->[-1]->[DEFAULT] = $value;
    }
    else {
        die "Cannot undeclare prefix $prefix" if $value eq '' and not $self->[XMLNS_11];
        if (not defined $prefix and $self->[AUTO_PREFIX]) {
            while (1) {
                $prefix = $self->[UNKNOWN_PREF]++;
                last if not exists $self->[NSMAP]->[-1]->[PREFIX_MAP]->{$prefix};
            }
        }
        elsif (not defined $prefix and not $self->[AUTO_PREFIX]) {
            return 0;
        }
        $self->[NSMAP]->[-1]->[PREFIX_MAP]->{$prefix} = $value;
    }
    push @{$self->[NSMAP]->[-1]->[DECLARATIONS]}, $prefix;
    return 1;
}

sub declare_prefixes {
    my $self     = shift;
    my %prefixes = @_;
    while (my ($k,$v) = each %prefixes) {
        $self->declare_prefix($k,$v);
    }
}

sub undeclare_prefix {
    my $self   = shift;
    my $prefix = shift;
    return unless not defined $prefix or $prefix eq '';
    return unless exists $self->[NSMAP]->[-1]->[PREFIX_MAP]->{$prefix};

    my ( $tfix ) = grep { $_ eq $prefix } @{$self->[NSMAP]->[-1]->[DECLARATIONS]};
    if ( not defined $tfix ) {
        die "prefix $prefix not declared in this context\n";
    }

    @{$self->[NSMAP]->[-1]->[DECLARATIONS]} = grep { $_ ne $prefix } @{$self->[NSMAP]->[-1]->[DECLARATIONS]};
    delete $self->[NSMAP]->[-1]->[PREFIX_MAP]->{$prefix};
}

sub get_prefix {
    my $self    = shift;
    my $uri     = shift;

    # we have to iterate over the whole hash here because if we don't
    # the iterator isn't reset and the next pass will fail
    my $pref;
    while (my ($k, $v) = each %{$self->[NSMAP]->[-1]->[PREFIX_MAP]}) {
        $pref = $k if $v eq $uri;
    }
    return $pref;
}

sub get_prefixes {
    my $self    = shift;
    my $uri     = shift;

    return keys %{$self->[NSMAP]->[-1]->[PREFIX_MAP]} unless defined $uri;
    return grep { $self->[NSMAP]->[-1]->[PREFIX_MAP]->{$_} eq $uri } keys %{$self->[NSMAP]->[-1]->[PREFIX_MAP]};
}

sub get_declared_prefixes {
    return @{$_[0]->[NSMAP]->[-1]->[DECLARATIONS]};
}

sub get_uri {
    my $self    = shift;
    my $prefix  = shift;

    warn "Prefix must not be undef in get_uri(). The emtpy prefix must be ''" unless defined $prefix;

    return $self->[NSMAP]->[-1]->[DEFAULT] if $prefix eq '';
    return $self->[NSMAP]->[-1]->[PREFIX_MAP]->{$prefix} if exists $self->[NSMAP]->[-1]->[PREFIX_MAP]->{$prefix};
    return undef;
}

sub process_name {
    my $self    = shift;
    my $qname   = shift;
    my $aflag   = shift;

    if ($self->[FATALS]) {
        return( ($self->_get_ns_details($qname, $aflag))[0,2], $qname );
    }
    else {
        eval { return( ($self->_get_ns_details($qname, $aflag))[0,2], $qname ); }
    }
}

sub process_element_name {
    my $self    = shift;
    my $qname   = shift;

    if ($self->[FATALS]) {
        return $self->_get_ns_details($qname, 0);
    }
    else {
        eval { return $self->_get_ns_details($qname, 0); }
    }
}


sub process_attribute_name {
    my $self    = shift;
    my $qname   = shift;

    if ($self->[FATALS]) {
        return $self->_get_ns_details($qname, 1);
    }
    else {
        eval { return $self->_get_ns_details($qname, 1); }
    }
}


sub _get_ns_details {
    my $self    = shift;
    my $qname   = shift;
    my $aflag   = shift;

    my ($ns, $prefix, $lname);
    (my ($tmp_prefix, $tmp_lname) = split /:/, $qname, 3)
                                    < 3 or die "Invalid QName: $qname";

    # no prefix
    my $cur_map = $self->[NSMAP]->[-1];
    if (not defined($tmp_lname)) {
        $prefix = undef;
        $lname = $qname;
        # attr don't have a default namespace
        $ns = ($aflag) ? undef : $cur_map->[DEFAULT];
    }

    # prefix
    else {
        if (exists $cur_map->[PREFIX_MAP]->{$tmp_prefix}) {
            $prefix = $tmp_prefix;
            $lname  = $tmp_lname;
            $ns     = $cur_map->[PREFIX_MAP]->{$prefix}
        }
        else { # no ns -> lname == name, all rest undef
            die "Undeclared prefix: $tmp_prefix";
        }
    }

    return ($ns, $prefix, $lname);
}

sub parse_jclark_notation {
    shift;
    my $jc = shift;
    $jc =~ m/^\{(.*)\}([^}]+)$/;
    return $1, $2;
}


*XML::NamespaceSupport::pushContext          = \&push_context;
*XML::NamespaceSupport::popContext           = \&pop_context;
*XML::NamespaceSupport::declarePrefix        = \&declare_prefix;
*XML::NamespaceSupport::declarePrefixes      = \&declare_prefixes;
*XML::NamespaceSupport::getPrefix            = \&get_prefix;
*XML::NamespaceSupport::getPrefixes          = \&get_prefixes;
*XML::NamespaceSupport::getDeclaredPrefixes  = \&get_declared_prefixes;
*XML::NamespaceSupport::getURI               = \&get_uri;
*XML::NamespaceSupport::processName          = \&process_name;
*XML::NamespaceSupport::processElementName   = \&process_element_name;
*XML::NamespaceSupport::processAttributeName = \&process_attribute_name;
*XML::NamespaceSupport::parseJClarkNotation  = \&parse_jclark_notation;
*XML::NamespaceSupport::undeclarePrefix      = \&undeclare_prefix;


1;


