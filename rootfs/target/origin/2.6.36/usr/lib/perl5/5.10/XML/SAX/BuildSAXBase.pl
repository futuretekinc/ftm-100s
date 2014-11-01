#!/usr/bin/perl

package SAX::Base::Builder;

use strict;
use warnings;

use File::Spec;

write_xml_sax_base() unless caller();

sub build_xml_sax_base {
    my $code = <<'EOHEADER';
package XML::SAX::Base;



use strict;

use XML::SAX::Exception qw();

EOHEADER

    my %EVENT_SPEC = (
                        start_document          => [qw(ContentHandler DocumentHandler Handler)],
                        end_document            => [qw(ContentHandler DocumentHandler Handler)],
                        start_element           => [qw(ContentHandler DocumentHandler Handler)],
                        end_element             => [qw(ContentHandler DocumentHandler Handler)],
                        characters              => [qw(ContentHandler DocumentHandler Handler)],
                        processing_instruction  => [qw(ContentHandler DocumentHandler Handler)],
                        ignorable_whitespace    => [qw(ContentHandler DocumentHandler Handler)],
                        set_document_locator    => [qw(ContentHandler DocumentHandler Handler)],
                        start_prefix_mapping    => [qw(ContentHandler Handler)],
                        end_prefix_mapping      => [qw(ContentHandler Handler)],
                        skipped_entity          => [qw(ContentHandler Handler)],
                        start_cdata             => [qw(DocumentHandler LexicalHandler Handler)],
                        end_cdata               => [qw(DocumentHandler LexicalHandler Handler)],
                        comment                 => [qw(DocumentHandler LexicalHandler Handler)],
                        entity_reference        => [qw(DocumentHandler Handler)],
                        notation_decl           => [qw(DTDHandler Handler)],
                        unparsed_entity_decl    => [qw(DTDHandler Handler)],
                        element_decl            => [qw(DeclHandler Handler)],
                        attlist_decl            => [qw(DTDHandler Handler)],
                        doctype_decl            => [qw(DTDHandler Handler)],
                        xml_decl                => [qw(DTDHandler Handler)],
                        entity_decl             => [qw(DTDHandler Handler)],
                        attribute_decl          => [qw(DeclHandler Handler)],
                        internal_entity_decl    => [qw(DeclHandler Handler)],
                        external_entity_decl    => [qw(DeclHandler Handler)],
                        resolve_entity          => [qw(EntityResolver Handler)],
                        start_dtd               => [qw(LexicalHandler Handler)],
                        end_dtd                 => [qw(LexicalHandler Handler)],
                        start_entity            => [qw(LexicalHandler Handler)],
                        end_entity              => [qw(LexicalHandler Handler)],
                        warning                 => [qw(ErrorHandler Handler)],
                        error                   => [qw(ErrorHandler Handler)],
                        fatal_error             => [qw(ErrorHandler Handler)],
                     );

    for my $ev (keys %EVENT_SPEC) {
        $code .= <<"        EOTOPCODE";
sub $ev {
    my \$self = shift;
    if (defined \$self->{Methods}->{'$ev'}) {
        \$self->{Methods}->{'$ev'}->(\@_);
    }
    else {
        my \$method;
        my \$callbacks;
        if (exists \$self->{ParseOptions}) {
            \$callbacks = \$self->{ParseOptions};
        }
        else {
            \$callbacks = \$self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        EOTOPCODE

       my ($can_string, $aload_string);
       for my $h (@{$EVENT_SPEC{$ev}}) {
            $can_string .= <<"            EOCANBLOCK";
        elsif (defined \$callbacks->{'$h'} and \$method = \$callbacks->{'$h'}->can('$ev') ) {
            my \$handler = \$callbacks->{'$h'};
            \$self->{Methods}->{'$ev'} = sub { \$method->(\$handler, \@_) };
            return \$method->(\$handler, \@_);
        }
            EOCANBLOCK
            $aload_string .= <<"            EOALOADBLOCK";
        elsif (defined \$callbacks->{'$h'} 
        	and \$callbacks->{'$h'}->can('AUTOLOAD')
        	and \$callbacks->{'$h'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my \$res = eval { \$callbacks->{'$h'}->$ev(\@_) };
            if (\$@) {
                die \$@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my \$handler = \$callbacks->{'$h'};
                \$self->{Methods}->{'$ev'} = sub { \$handler->$ev(\@_) };
            }
            return \$res;
        }
            EOALOADBLOCK
        }

        $code .= $can_string . $aload_string;

            $code .= <<"            EOFALLTHROUGH";
        else {
            \$self->{Methods}->{'$ev'} = sub { };
        }
    }
            EOFALLTHROUGH

        $code .= "\n}\n\n";
    }

    $code .= <<'BODY';
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $options = ($#_ == 0) ? shift : { @_ };

    unless ( defined( $options->{Handler} )         or
             defined( $options->{ContentHandler} )  or
             defined( $options->{DTDHandler} )      or
             defined( $options->{DocumentHandler} ) or
             defined( $options->{LexicalHandler} )  or
             defined( $options->{ErrorHandler} )    or
             defined( $options->{DeclHandler} ) ) {
            
             $options->{Handler} = XML::SAX::Base::NoHandler->new;
    }

    my $self = bless $options, $class;
    # turn NS processing on by default
    $self->set_feature('http://xml.org/sax/features/namespaces', 1);
    return $self;
}

sub parse {
    my $self = shift;
    my $parse_options = $self->get_options(@_);
    local $self->{ParseOptions} = $parse_options;
    if ($self->{Parent}) { # calling parse on a filter for some reason
        return $self->{Parent}->parse($parse_options);
    }
    else {
        my $method;
        if (defined $parse_options->{Source}{CharacterStream} and $method = $self->can('_parse_characterstream')) {
            warn("parse charstream???\n");
            return $method->($self, $parse_options->{Source}{CharacterStream});
        }
        elsif (defined $parse_options->{Source}{ByteStream} and $method = $self->can('_parse_bytestream')) {
            return $method->($self, $parse_options->{Source}{ByteStream});
        }
        elsif (defined $parse_options->{Source}{String} and $method = $self->can('_parse_string')) {
            return $method->($self, $parse_options->{Source}{String});
        }
        elsif (defined $parse_options->{Source}{SystemId} and $method = $self->can('_parse_systemid')) {
            return $method->($self, $parse_options->{Source}{SystemId});
        }
        else {
            die "No _parse_* routine defined on this driver (If it is a filter, remember to set the Parent property. If you call the parse() method, make sure to set a Source. You may want to call parse_uri, parse_string or parse_file instead.) [$self]";
        }
    }
}

sub parse_file {
    my $self = shift;
    my $file = shift;
    return $self->parse_uri($file, @_) if ref(\$file) eq 'SCALAR';
    my $parse_options = $self->get_options(@_);
    $parse_options->{Source}{ByteStream} = $file;
    return $self->parse($parse_options);
}

sub parse_uri {
    my $self = shift;
    my $file = shift;
    my $parse_options = $self->get_options(@_);
    $parse_options->{Source}{SystemId} = $file;
    return $self->parse($parse_options);
}

sub parse_string {
    my $self = shift;
    my $string = shift;
    my $parse_options = $self->get_options(@_);
    $parse_options->{Source}{String} = $string;
    return $self->parse($parse_options);
}

sub get_options {
    my $self = shift;

    if (@_ == 1) {
        return { %$self, %{$_[0]} };
    } else {
        return { %$self, @_ };
    }
}

sub get_features {
   return (
    'http://xml.org/sax/features/external-general-entities'     => undef,
    'http://xml.org/sax/features/external-parameter-entities'   => undef,
    'http://xml.org/sax/features/is-standalone'                 => undef,
    'http://xml.org/sax/features/lexical-handler'               => undef,
    'http://xml.org/sax/features/parameter-entities'            => undef,
    'http://xml.org/sax/features/namespaces'                    => 1,
    'http://xml.org/sax/features/namespace-prefixes'            => 0,
    'http://xml.org/sax/features/string-interning'              => undef,
    'http://xml.org/sax/features/use-attributes2'               => undef,
    'http://xml.org/sax/features/use-locator2'                  => undef,
    'http://xml.org/sax/features/validation'                    => undef,

    'http://xml.org/sax/properties/dom-node'                    => undef,
    'http://xml.org/sax/properties/xml-string'                  => undef,
               );
}

sub get_feature {
    my $self = shift;
    my $feat = shift;

    # check %FEATURES to see if it's there, and return it if so
    # throw XML::SAX::Exception::NotRecognized if it's not there
    # throw XML::SAX::Exception::NotSupported if it's there but we
    # don't support it
    
    my %features = $self->get_features();
    if (exists $features{$feat}) {
        my %supported = map { $_ => 1 } $self->supported_features();
        if ($supported{$feat}) {
            return $self->{__PACKAGE__ . "::Features"}{$feat};
        }
        throw XML::SAX::Exception::NotSupported(
            Message => "The feature '$feat' is not supported by " . ref($self),
            Exception => undef,
            );
    }
    throw XML::SAX::Exception::NotRecognized(
        Message => "The feature '$feat' is not recognized by " . ref($self),
        Exception => undef,
        );
}

sub set_feature {
    my $self = shift;
    my $feat = shift;
    my $value = shift;
    # check %FEATURES to see if it's there, and set it if so
    # throw XML::SAX::Exception::NotRecognized if it's not there
    # throw XML::SAX::Exception::NotSupported if it's there but we
    # don't support it
    
    my %features = $self->get_features();
    if (exists $features{$feat}) {
        my %supported = map { $_ => 1 } $self->supported_features();
        if ($supported{$feat}) {
            return $self->{__PACKAGE__ . "::Features"}{$feat} = $value;
        }
        throw XML::SAX::Exception::NotSupported(
            Message => "The feature '$feat' is not supported by " . ref($self),
            Exception => undef,
            );
    }
    throw XML::SAX::Exception::NotRecognized(
        Message => "The feature '$feat' is not recognized by " . ref($self),
        Exception => undef,
        );
}

sub get_handler {
    my $self = shift;
    my $handler_type = shift;
    $handler_type ||= 'Handler';
    return  defined( $self->{$handler_type} ) ? $self->{$handler_type} : undef;
}

sub get_document_handler {
    my $self = shift;
    return $self->get_handler('DocumentHandler', @_);
}

sub get_content_handler {
    my $self = shift;
    return $self->get_handler('ContentHandler', @_);
}

sub get_dtd_handler {
    my $self = shift;
    return $self->get_handler('DTDHandler', @_);
}

sub get_lexical_handler {
    my $self = shift;
    return $self->get_handler('LexicalHandler', @_);
}

sub get_decl_handler {
    my $self = shift;
    return $self->get_handler('DeclHandler', @_);
}

sub get_error_handler {
    my $self = shift;
    return $self->get_handler('ErrorHandler', @_);
}

sub get_entity_resolver {
    my $self = shift;
    return $self->get_handler('EntityResolver', @_);
}

sub set_handler {
    my $self = shift;
    my ($new_handler, $handler_type) = reverse @_;
    $handler_type ||= 'Handler';
    $self->{Methods} = {} if $self->{Methods};
    $self->{$handler_type} = $new_handler;
    $self->{ParseOptions}->{$handler_type} = $new_handler;
    return 1;
}

sub set_document_handler {
    my $self = shift;
    return $self->set_handler('DocumentHandler', @_);
}

sub set_content_handler {
    my $self = shift;
    return $self->set_handler('ContentHandler', @_);
}
sub set_dtd_handler {
    my $self = shift;
    return $self->set_handler('DTDHandler', @_);
}
sub set_lexical_handler {
    my $self = shift;
    return $self->set_handler('LexicalHandler', @_);
}
sub set_decl_handler {
    my $self = shift;
    return $self->set_handler('DeclHandler', @_);
}
sub set_error_handler {
    my $self = shift;
    return $self->set_handler('ErrorHandler', @_);
}
sub set_entity_resolver {
    my $self = shift;
    return $self->set_handler('EntityResolver', @_);
}


sub supported_features {
    my $self = shift;
    # Only namespaces are required by all parsers
    return (
        'http://xml.org/sax/features/namespaces',
    );
}

sub no_op {
    # this space intentionally blank
}


package XML::SAX::Base::NoHandler;

sub new {
    #warn "no handler called\n";
    return bless {};
}

1;

BODY

    $code .= "__END__\n";

    $code .= <<'FOOTER';


FOOTER


    return $code;
}


sub write_xml_sax_base {
    confirm_forced_update();

    my $path = File::Spec->catfile("lib", "XML", "SAX", "Base.pm");
    save_original_xml_sax_base($path);

    my $code = build_xml_sax_base();
    $code = add_version_stanzas($code);

    open my $fh, ">", $path or die "Cannot write $path: $!";
    print $fh $code;
    close $fh or die "Error writing $path: $!";
    print "Wrote $path\n";
}


sub confirm_forced_update {
    return if grep { $_ eq '--force' } @ARGV;

    print <<'EOF';
*** WARNING ***

The BuildSAXBase.pl script is used to generate the lib/XML/SAX/Base.pm file.
However a pre-generated version of Base.pm is included in the distribution
so you do not need to run this script unless you intend to modify the code.

You must use the --force option to deliberately overwrite the distributed
version of lib/XML/SAX/Base.pm

EOF

    exit;
}


sub save_original_xml_sax_base {
    my($path) = @_;

    return unless -e $path;
    (my $save_path = $path) =~ s{Base}{Base-orig};
    return if -e $save_path;
    print "Saving $path to $save_path\n";
    rename($path, $save_path);
}


sub add_version_stanzas {
    my($code) = @_;

    my $version = get_xml_sax_base_version();
    $code =~ s<^(package\s+(\w[:\w]+).*?\n)>
              <${1}BEGIN {\n  \$${2}::VERSION = '$version';\n}\n>mg;
    return $code;
}


sub get_xml_sax_base_version {
    open my $fh, '<', 'dist.ini' or die "open(<dist.ini): $!";
    while(<$fh>) {
        m{^\s*version\s*=\s*(\S+)} && return $1;
    }
    die "Failed to find version in dist.ini";
}

