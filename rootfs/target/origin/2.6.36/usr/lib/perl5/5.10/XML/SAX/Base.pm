package XML::SAX::Base;
BEGIN {
  $XML::SAX::Base::VERSION = '1.08';
}



use strict;

use XML::SAX::Exception qw();

sub end_prefix_mapping {
    my $self = shift;
    if (defined $self->{Methods}->{'end_prefix_mapping'}) {
        $self->{Methods}->{'end_prefix_mapping'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('end_prefix_mapping') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'end_prefix_mapping'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('end_prefix_mapping') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'end_prefix_mapping'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->end_prefix_mapping(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'end_prefix_mapping'} = sub { $handler->end_prefix_mapping(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->end_prefix_mapping(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'end_prefix_mapping'} = sub { $handler->end_prefix_mapping(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'end_prefix_mapping'} = sub { };
        }
    }

}

sub internal_entity_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'internal_entity_decl'}) {
        $self->{Methods}->{'internal_entity_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DeclHandler'} and $method = $callbacks->{'DeclHandler'}->can('internal_entity_decl') ) {
            my $handler = $callbacks->{'DeclHandler'};
            $self->{Methods}->{'internal_entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('internal_entity_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'internal_entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DeclHandler'} 
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DeclHandler'}->internal_entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DeclHandler'};
                $self->{Methods}->{'internal_entity_decl'} = sub { $handler->internal_entity_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->internal_entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'internal_entity_decl'} = sub { $handler->internal_entity_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'internal_entity_decl'} = sub { };
        }
    }

}

sub characters {
    my $self = shift;
    if (defined $self->{Methods}->{'characters'}) {
        $self->{Methods}->{'characters'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('characters') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'characters'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('characters') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'characters'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('characters') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'characters'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->characters(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'characters'} = sub { $handler->characters(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->characters(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'characters'} = sub { $handler->characters(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->characters(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'characters'} = sub { $handler->characters(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'characters'} = sub { };
        }
    }

}

sub start_element {
    my $self = shift;
    if (defined $self->{Methods}->{'start_element'}) {
        $self->{Methods}->{'start_element'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('start_element') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'start_element'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('start_element') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'start_element'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('start_element') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'start_element'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->start_element(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'start_element'} = sub { $handler->start_element(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->start_element(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'start_element'} = sub { $handler->start_element(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->start_element(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'start_element'} = sub { $handler->start_element(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'start_element'} = sub { };
        }
    }

}

sub external_entity_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'external_entity_decl'}) {
        $self->{Methods}->{'external_entity_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DeclHandler'} and $method = $callbacks->{'DeclHandler'}->can('external_entity_decl') ) {
            my $handler = $callbacks->{'DeclHandler'};
            $self->{Methods}->{'external_entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('external_entity_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'external_entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DeclHandler'} 
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DeclHandler'}->external_entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DeclHandler'};
                $self->{Methods}->{'external_entity_decl'} = sub { $handler->external_entity_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->external_entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'external_entity_decl'} = sub { $handler->external_entity_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'external_entity_decl'} = sub { };
        }
    }

}

sub xml_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'xml_decl'}) {
        $self->{Methods}->{'xml_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DTDHandler'} and $method = $callbacks->{'DTDHandler'}->can('xml_decl') ) {
            my $handler = $callbacks->{'DTDHandler'};
            $self->{Methods}->{'xml_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('xml_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'xml_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DTDHandler'} 
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DTDHandler'}->xml_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DTDHandler'};
                $self->{Methods}->{'xml_decl'} = sub { $handler->xml_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->xml_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'xml_decl'} = sub { $handler->xml_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'xml_decl'} = sub { };
        }
    }

}

sub entity_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'entity_decl'}) {
        $self->{Methods}->{'entity_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DTDHandler'} and $method = $callbacks->{'DTDHandler'}->can('entity_decl') ) {
            my $handler = $callbacks->{'DTDHandler'};
            $self->{Methods}->{'entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('entity_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DTDHandler'} 
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DTDHandler'}->entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DTDHandler'};
                $self->{Methods}->{'entity_decl'} = sub { $handler->entity_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'entity_decl'} = sub { $handler->entity_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'entity_decl'} = sub { };
        }
    }

}

sub end_dtd {
    my $self = shift;
    if (defined $self->{Methods}->{'end_dtd'}) {
        $self->{Methods}->{'end_dtd'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'LexicalHandler'} and $method = $callbacks->{'LexicalHandler'}->can('end_dtd') ) {
            my $handler = $callbacks->{'LexicalHandler'};
            $self->{Methods}->{'end_dtd'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('end_dtd') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'end_dtd'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'LexicalHandler'} 
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD')
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'LexicalHandler'}->end_dtd(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'LexicalHandler'};
                $self->{Methods}->{'end_dtd'} = sub { $handler->end_dtd(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->end_dtd(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'end_dtd'} = sub { $handler->end_dtd(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'end_dtd'} = sub { };
        }
    }

}

sub unparsed_entity_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'unparsed_entity_decl'}) {
        $self->{Methods}->{'unparsed_entity_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DTDHandler'} and $method = $callbacks->{'DTDHandler'}->can('unparsed_entity_decl') ) {
            my $handler = $callbacks->{'DTDHandler'};
            $self->{Methods}->{'unparsed_entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('unparsed_entity_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'unparsed_entity_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DTDHandler'} 
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DTDHandler'}->unparsed_entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DTDHandler'};
                $self->{Methods}->{'unparsed_entity_decl'} = sub { $handler->unparsed_entity_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->unparsed_entity_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'unparsed_entity_decl'} = sub { $handler->unparsed_entity_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'unparsed_entity_decl'} = sub { };
        }
    }

}

sub processing_instruction {
    my $self = shift;
    if (defined $self->{Methods}->{'processing_instruction'}) {
        $self->{Methods}->{'processing_instruction'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('processing_instruction') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'processing_instruction'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('processing_instruction') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'processing_instruction'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('processing_instruction') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'processing_instruction'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->processing_instruction(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'processing_instruction'} = sub { $handler->processing_instruction(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->processing_instruction(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'processing_instruction'} = sub { $handler->processing_instruction(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->processing_instruction(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'processing_instruction'} = sub { $handler->processing_instruction(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'processing_instruction'} = sub { };
        }
    }

}

sub attribute_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'attribute_decl'}) {
        $self->{Methods}->{'attribute_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DeclHandler'} and $method = $callbacks->{'DeclHandler'}->can('attribute_decl') ) {
            my $handler = $callbacks->{'DeclHandler'};
            $self->{Methods}->{'attribute_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('attribute_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'attribute_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DeclHandler'} 
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DeclHandler'}->attribute_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DeclHandler'};
                $self->{Methods}->{'attribute_decl'} = sub { $handler->attribute_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->attribute_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'attribute_decl'} = sub { $handler->attribute_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'attribute_decl'} = sub { };
        }
    }

}

sub fatal_error {
    my $self = shift;
    if (defined $self->{Methods}->{'fatal_error'}) {
        $self->{Methods}->{'fatal_error'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ErrorHandler'} and $method = $callbacks->{'ErrorHandler'}->can('fatal_error') ) {
            my $handler = $callbacks->{'ErrorHandler'};
            $self->{Methods}->{'fatal_error'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('fatal_error') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'fatal_error'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ErrorHandler'} 
        	and $callbacks->{'ErrorHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ErrorHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ErrorHandler'}->fatal_error(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ErrorHandler'};
                $self->{Methods}->{'fatal_error'} = sub { $handler->fatal_error(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->fatal_error(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'fatal_error'} = sub { $handler->fatal_error(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'fatal_error'} = sub { };
        }
    }

}

sub end_cdata {
    my $self = shift;
    if (defined $self->{Methods}->{'end_cdata'}) {
        $self->{Methods}->{'end_cdata'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('end_cdata') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'end_cdata'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'LexicalHandler'} and $method = $callbacks->{'LexicalHandler'}->can('end_cdata') ) {
            my $handler = $callbacks->{'LexicalHandler'};
            $self->{Methods}->{'end_cdata'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('end_cdata') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'end_cdata'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->end_cdata(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'end_cdata'} = sub { $handler->end_cdata(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'LexicalHandler'} 
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD')
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'LexicalHandler'}->end_cdata(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'LexicalHandler'};
                $self->{Methods}->{'end_cdata'} = sub { $handler->end_cdata(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->end_cdata(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'end_cdata'} = sub { $handler->end_cdata(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'end_cdata'} = sub { };
        }
    }

}

sub start_entity {
    my $self = shift;
    if (defined $self->{Methods}->{'start_entity'}) {
        $self->{Methods}->{'start_entity'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'LexicalHandler'} and $method = $callbacks->{'LexicalHandler'}->can('start_entity') ) {
            my $handler = $callbacks->{'LexicalHandler'};
            $self->{Methods}->{'start_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('start_entity') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'start_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'LexicalHandler'} 
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD')
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'LexicalHandler'}->start_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'LexicalHandler'};
                $self->{Methods}->{'start_entity'} = sub { $handler->start_entity(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->start_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'start_entity'} = sub { $handler->start_entity(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'start_entity'} = sub { };
        }
    }

}

sub start_prefix_mapping {
    my $self = shift;
    if (defined $self->{Methods}->{'start_prefix_mapping'}) {
        $self->{Methods}->{'start_prefix_mapping'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('start_prefix_mapping') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'start_prefix_mapping'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('start_prefix_mapping') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'start_prefix_mapping'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->start_prefix_mapping(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'start_prefix_mapping'} = sub { $handler->start_prefix_mapping(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->start_prefix_mapping(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'start_prefix_mapping'} = sub { $handler->start_prefix_mapping(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'start_prefix_mapping'} = sub { };
        }
    }

}

sub error {
    my $self = shift;
    if (defined $self->{Methods}->{'error'}) {
        $self->{Methods}->{'error'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ErrorHandler'} and $method = $callbacks->{'ErrorHandler'}->can('error') ) {
            my $handler = $callbacks->{'ErrorHandler'};
            $self->{Methods}->{'error'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('error') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'error'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ErrorHandler'} 
        	and $callbacks->{'ErrorHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ErrorHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ErrorHandler'}->error(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ErrorHandler'};
                $self->{Methods}->{'error'} = sub { $handler->error(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->error(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'error'} = sub { $handler->error(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'error'} = sub { };
        }
    }

}

sub start_document {
    my $self = shift;
    if (defined $self->{Methods}->{'start_document'}) {
        $self->{Methods}->{'start_document'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('start_document') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'start_document'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('start_document') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'start_document'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('start_document') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'start_document'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->start_document(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'start_document'} = sub { $handler->start_document(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->start_document(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'start_document'} = sub { $handler->start_document(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->start_document(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'start_document'} = sub { $handler->start_document(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'start_document'} = sub { };
        }
    }

}

sub ignorable_whitespace {
    my $self = shift;
    if (defined $self->{Methods}->{'ignorable_whitespace'}) {
        $self->{Methods}->{'ignorable_whitespace'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('ignorable_whitespace') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'ignorable_whitespace'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('ignorable_whitespace') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'ignorable_whitespace'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('ignorable_whitespace') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'ignorable_whitespace'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->ignorable_whitespace(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'ignorable_whitespace'} = sub { $handler->ignorable_whitespace(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->ignorable_whitespace(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'ignorable_whitespace'} = sub { $handler->ignorable_whitespace(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->ignorable_whitespace(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'ignorable_whitespace'} = sub { $handler->ignorable_whitespace(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'ignorable_whitespace'} = sub { };
        }
    }

}

sub end_document {
    my $self = shift;
    if (defined $self->{Methods}->{'end_document'}) {
        $self->{Methods}->{'end_document'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('end_document') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'end_document'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('end_document') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'end_document'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('end_document') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'end_document'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->end_document(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'end_document'} = sub { $handler->end_document(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->end_document(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'end_document'} = sub { $handler->end_document(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->end_document(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'end_document'} = sub { $handler->end_document(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'end_document'} = sub { };
        }
    }

}

sub start_cdata {
    my $self = shift;
    if (defined $self->{Methods}->{'start_cdata'}) {
        $self->{Methods}->{'start_cdata'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('start_cdata') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'start_cdata'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'LexicalHandler'} and $method = $callbacks->{'LexicalHandler'}->can('start_cdata') ) {
            my $handler = $callbacks->{'LexicalHandler'};
            $self->{Methods}->{'start_cdata'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('start_cdata') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'start_cdata'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->start_cdata(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'start_cdata'} = sub { $handler->start_cdata(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'LexicalHandler'} 
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD')
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'LexicalHandler'}->start_cdata(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'LexicalHandler'};
                $self->{Methods}->{'start_cdata'} = sub { $handler->start_cdata(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->start_cdata(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'start_cdata'} = sub { $handler->start_cdata(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'start_cdata'} = sub { };
        }
    }

}

sub set_document_locator {
    my $self = shift;
    if (defined $self->{Methods}->{'set_document_locator'}) {
        $self->{Methods}->{'set_document_locator'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('set_document_locator') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'set_document_locator'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('set_document_locator') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'set_document_locator'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('set_document_locator') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'set_document_locator'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->set_document_locator(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'set_document_locator'} = sub { $handler->set_document_locator(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->set_document_locator(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'set_document_locator'} = sub { $handler->set_document_locator(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->set_document_locator(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'set_document_locator'} = sub { $handler->set_document_locator(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'set_document_locator'} = sub { };
        }
    }

}

sub attlist_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'attlist_decl'}) {
        $self->{Methods}->{'attlist_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DTDHandler'} and $method = $callbacks->{'DTDHandler'}->can('attlist_decl') ) {
            my $handler = $callbacks->{'DTDHandler'};
            $self->{Methods}->{'attlist_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('attlist_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'attlist_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DTDHandler'} 
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DTDHandler'}->attlist_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DTDHandler'};
                $self->{Methods}->{'attlist_decl'} = sub { $handler->attlist_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->attlist_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'attlist_decl'} = sub { $handler->attlist_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'attlist_decl'} = sub { };
        }
    }

}

sub start_dtd {
    my $self = shift;
    if (defined $self->{Methods}->{'start_dtd'}) {
        $self->{Methods}->{'start_dtd'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'LexicalHandler'} and $method = $callbacks->{'LexicalHandler'}->can('start_dtd') ) {
            my $handler = $callbacks->{'LexicalHandler'};
            $self->{Methods}->{'start_dtd'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('start_dtd') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'start_dtd'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'LexicalHandler'} 
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD')
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'LexicalHandler'}->start_dtd(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'LexicalHandler'};
                $self->{Methods}->{'start_dtd'} = sub { $handler->start_dtd(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->start_dtd(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'start_dtd'} = sub { $handler->start_dtd(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'start_dtd'} = sub { };
        }
    }

}

sub resolve_entity {
    my $self = shift;
    if (defined $self->{Methods}->{'resolve_entity'}) {
        $self->{Methods}->{'resolve_entity'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'EntityResolver'} and $method = $callbacks->{'EntityResolver'}->can('resolve_entity') ) {
            my $handler = $callbacks->{'EntityResolver'};
            $self->{Methods}->{'resolve_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('resolve_entity') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'resolve_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'EntityResolver'} 
        	and $callbacks->{'EntityResolver'}->can('AUTOLOAD')
        	and $callbacks->{'EntityResolver'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'EntityResolver'}->resolve_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'EntityResolver'};
                $self->{Methods}->{'resolve_entity'} = sub { $handler->resolve_entity(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->resolve_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'resolve_entity'} = sub { $handler->resolve_entity(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'resolve_entity'} = sub { };
        }
    }

}

sub entity_reference {
    my $self = shift;
    if (defined $self->{Methods}->{'entity_reference'}) {
        $self->{Methods}->{'entity_reference'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('entity_reference') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'entity_reference'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('entity_reference') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'entity_reference'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->entity_reference(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'entity_reference'} = sub { $handler->entity_reference(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->entity_reference(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'entity_reference'} = sub { $handler->entity_reference(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'entity_reference'} = sub { };
        }
    }

}

sub element_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'element_decl'}) {
        $self->{Methods}->{'element_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DeclHandler'} and $method = $callbacks->{'DeclHandler'}->can('element_decl') ) {
            my $handler = $callbacks->{'DeclHandler'};
            $self->{Methods}->{'element_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('element_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'element_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DeclHandler'} 
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DeclHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DeclHandler'}->element_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DeclHandler'};
                $self->{Methods}->{'element_decl'} = sub { $handler->element_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->element_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'element_decl'} = sub { $handler->element_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'element_decl'} = sub { };
        }
    }

}

sub notation_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'notation_decl'}) {
        $self->{Methods}->{'notation_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DTDHandler'} and $method = $callbacks->{'DTDHandler'}->can('notation_decl') ) {
            my $handler = $callbacks->{'DTDHandler'};
            $self->{Methods}->{'notation_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('notation_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'notation_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DTDHandler'} 
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DTDHandler'}->notation_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DTDHandler'};
                $self->{Methods}->{'notation_decl'} = sub { $handler->notation_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->notation_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'notation_decl'} = sub { $handler->notation_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'notation_decl'} = sub { };
        }
    }

}

sub skipped_entity {
    my $self = shift;
    if (defined $self->{Methods}->{'skipped_entity'}) {
        $self->{Methods}->{'skipped_entity'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('skipped_entity') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'skipped_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('skipped_entity') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'skipped_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->skipped_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'skipped_entity'} = sub { $handler->skipped_entity(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->skipped_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'skipped_entity'} = sub { $handler->skipped_entity(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'skipped_entity'} = sub { };
        }
    }

}

sub end_element {
    my $self = shift;
    if (defined $self->{Methods}->{'end_element'}) {
        $self->{Methods}->{'end_element'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ContentHandler'} and $method = $callbacks->{'ContentHandler'}->can('end_element') ) {
            my $handler = $callbacks->{'ContentHandler'};
            $self->{Methods}->{'end_element'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('end_element') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'end_element'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('end_element') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'end_element'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ContentHandler'} 
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ContentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ContentHandler'}->end_element(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ContentHandler'};
                $self->{Methods}->{'end_element'} = sub { $handler->end_element(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->end_element(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'end_element'} = sub { $handler->end_element(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->end_element(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'end_element'} = sub { $handler->end_element(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'end_element'} = sub { };
        }
    }

}

sub doctype_decl {
    my $self = shift;
    if (defined $self->{Methods}->{'doctype_decl'}) {
        $self->{Methods}->{'doctype_decl'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DTDHandler'} and $method = $callbacks->{'DTDHandler'}->can('doctype_decl') ) {
            my $handler = $callbacks->{'DTDHandler'};
            $self->{Methods}->{'doctype_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('doctype_decl') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'doctype_decl'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DTDHandler'} 
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DTDHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DTDHandler'}->doctype_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DTDHandler'};
                $self->{Methods}->{'doctype_decl'} = sub { $handler->doctype_decl(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->doctype_decl(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'doctype_decl'} = sub { $handler->doctype_decl(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'doctype_decl'} = sub { };
        }
    }

}

sub comment {
    my $self = shift;
    if (defined $self->{Methods}->{'comment'}) {
        $self->{Methods}->{'comment'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'DocumentHandler'} and $method = $callbacks->{'DocumentHandler'}->can('comment') ) {
            my $handler = $callbacks->{'DocumentHandler'};
            $self->{Methods}->{'comment'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'LexicalHandler'} and $method = $callbacks->{'LexicalHandler'}->can('comment') ) {
            my $handler = $callbacks->{'LexicalHandler'};
            $self->{Methods}->{'comment'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('comment') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'comment'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'DocumentHandler'} 
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD')
        	and $callbacks->{'DocumentHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'DocumentHandler'}->comment(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'DocumentHandler'};
                $self->{Methods}->{'comment'} = sub { $handler->comment(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'LexicalHandler'} 
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD')
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'LexicalHandler'}->comment(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'LexicalHandler'};
                $self->{Methods}->{'comment'} = sub { $handler->comment(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->comment(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'comment'} = sub { $handler->comment(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'comment'} = sub { };
        }
    }

}

sub end_entity {
    my $self = shift;
    if (defined $self->{Methods}->{'end_entity'}) {
        $self->{Methods}->{'end_entity'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'LexicalHandler'} and $method = $callbacks->{'LexicalHandler'}->can('end_entity') ) {
            my $handler = $callbacks->{'LexicalHandler'};
            $self->{Methods}->{'end_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('end_entity') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'end_entity'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'LexicalHandler'} 
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD')
        	and $callbacks->{'LexicalHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'LexicalHandler'}->end_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'LexicalHandler'};
                $self->{Methods}->{'end_entity'} = sub { $handler->end_entity(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->end_entity(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'end_entity'} = sub { $handler->end_entity(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'end_entity'} = sub { };
        }
    }

}

sub warning {
    my $self = shift;
    if (defined $self->{Methods}->{'warning'}) {
        $self->{Methods}->{'warning'}->(@_);
    }
    else {
        my $method;
        my $callbacks;
        if (exists $self->{ParseOptions}) {
            $callbacks = $self->{ParseOptions};
        }
        else {
            $callbacks = $self;
        }
        if (0) { # dummy to make elsif's below compile
        }
        elsif (defined $callbacks->{'ErrorHandler'} and $method = $callbacks->{'ErrorHandler'}->can('warning') ) {
            my $handler = $callbacks->{'ErrorHandler'};
            $self->{Methods}->{'warning'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'Handler'} and $method = $callbacks->{'Handler'}->can('warning') ) {
            my $handler = $callbacks->{'Handler'};
            $self->{Methods}->{'warning'} = sub { $method->($handler, @_) };
            return $method->($handler, @_);
        }
        elsif (defined $callbacks->{'ErrorHandler'} 
        	and $callbacks->{'ErrorHandler'}->can('AUTOLOAD')
        	and $callbacks->{'ErrorHandler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'ErrorHandler'}->warning(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'ErrorHandler'};
                $self->{Methods}->{'warning'} = sub { $handler->warning(@_) };
            }
            return $res;
        }
        elsif (defined $callbacks->{'Handler'} 
        	and $callbacks->{'Handler'}->can('AUTOLOAD')
        	and $callbacks->{'Handler'}->can('AUTOLOAD') ne (UNIVERSAL->can('AUTOLOAD') || '')
        	)
        {
            my $res = eval { $callbacks->{'Handler'}->warning(@_) };
            if ($@) {
                die $@;
            }
            else {
                # I think there's a buggette here...
                # if the first call throws an exception, we don't set it up right.
                # Not fatal, but we might want to address it.
                my $handler = $callbacks->{'Handler'};
                $self->{Methods}->{'warning'} = sub { $handler->warning(@_) };
            }
            return $res;
        }
        else {
            $self->{Methods}->{'warning'} = sub { };
        }
    }

}

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
BEGIN {
  $XML::SAX::Base::NoHandler::VERSION = '1.08';
}

sub new {
    #warn "no handler called\n";
    return bless {};
}

1;

__END__


