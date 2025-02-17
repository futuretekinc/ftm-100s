
package Template::Filters;

use strict;
use warnings;
use locale;
use base 'Template::Base';
use Template::Constants;
use Scalar::Util 'blessed';

our $VERSION         = 2.87;
our $AVAILABLE       = { };
our $TRUNCATE_LENGTH = 32;
our $TRUNCATE_ADDON  = '...';



our $FILTERS = {
    # static filters 
    'html'            => \&html_filter,
    'html_para'       => \&html_paragraph,
    'html_break'      => \&html_para_break,
    'html_para_break' => \&html_para_break,
    'html_line_break' => \&html_line_break,
    'xml'             => \&xml_filter,
    'uri'             => \&uri_filter,
    'url'             => \&url_filter,
    'upper'           => sub { uc $_[0] },
    'lower'           => sub { lc $_[0] },
    'ucfirst'         => sub { ucfirst $_[0] },
    'lcfirst'         => sub { lcfirst $_[0] },
    'stderr'          => sub { print STDERR @_; return '' },
    'trim'            => sub { for ($_[0]) { s/^\s+//; s/\s+$// }; $_[0] },
    'null'            => sub { return '' },
    'collapse'        => sub { for ($_[0]) { s/^\s+//; s/\s+$//; s/\s+/ /g };
                               $_[0] },

    # dynamic filters
    'html_entity' => [ \&html_entity_filter_factory, 1 ],
    'indent'      => [ \&indent_filter_factory,      1 ],
    'format'      => [ \&format_filter_factory,      1 ],
    'truncate'    => [ \&truncate_filter_factory,    1 ],
    'repeat'      => [ \&repeat_filter_factory,      1 ],
    'replace'     => [ \&replace_filter_factory,     1 ],
    'remove'      => [ \&remove_filter_factory,      1 ],
    'eval'        => [ \&eval_filter_factory,        1 ],
    'evaltt'      => [ \&eval_filter_factory,        1 ],  # alias
    'perl'        => [ \&perl_filter_factory,        1 ],
    'evalperl'    => [ \&perl_filter_factory,        1 ],  # alias
    'redirect'    => [ \&redirect_filter_factory,    1 ],
    'file'        => [ \&redirect_filter_factory,    1 ],  # alias
    'stdout'      => [ \&stdout_filter_factory,      1 ],
};

our $PLUGIN_FILTER = 'Template::Plugin::Filter';





sub fetch {
    my ($self, $name, $args, $context) = @_;
    my ($factory, $is_dynamic, $filter, $error);

    $self->debug("fetch($name, ", 
                 defined $args ? ('[ ', join(', ', @$args), ' ]') : '<no args>', ', ',
                 defined $context ? $context : '<no context>', 
                 ')') if $self->{ DEBUG };

    # allow $name to be specified as a reference to 
    # a plugin filter object;  any other ref is 
    # assumed to be a coderef and hence already a filter;
    # non-refs are assumed to be regular name lookups

    if (ref $name) {
        if (blessed($name) && $name->isa($PLUGIN_FILTER)) {
            $factory = $name->factory()
                || return $self->error($name->error());
        }
        else {
            return $name;
        }
    }
    else {
        return (undef, Template::Constants::STATUS_DECLINED)
            unless ($factory = $self->{ FILTERS }->{ $name }
                    || $FILTERS->{ $name });
    }

    # factory can be an [ $code, $dynamic ] or just $code
    if (ref $factory eq 'ARRAY') {
        ($factory, $is_dynamic) = @$factory;
    }
    else {
        $is_dynamic = 0;
    }

    if (ref $factory eq 'CODE') {
        if ($is_dynamic) {
            # if the dynamic flag is set then the sub-routine is a 
            # factory which should be called to create the actual 
            # filter...
            eval {
                ($filter, $error) = &$factory($context, $args ? @$args : ());
            };
            $error ||= $@;
            $error = "invalid FILTER for '$name' (not a CODE ref)"
                unless $error || ref($filter) eq 'CODE';
        }
        else {
            # ...otherwise, it's a static filter sub-routine
            $filter = $factory;
        }
    }
    else {
        $error = "invalid FILTER entry for '$name' (not a CODE ref)";
    }

    if ($error) {
        return $self->{ TOLERANT } 
               ? (undef,  Template::Constants::STATUS_DECLINED) 
               : ($error, Template::Constants::STATUS_ERROR) ;
    }
    else {
        return $filter;
    }
}



sub store {
    my ($self, $name, $filter) = @_;

    $self->debug("store($name, $filter)") if $self->{ DEBUG };

    $self->{ FILTERS }->{ $name } = $filter;
    return 1;
}




sub _init {
    my ($self, $params) = @_;

    $self->{ FILTERS  } = $params->{ FILTERS } || { };
    $self->{ TOLERANT } = $params->{ TOLERANT }  || 0;
    $self->{ DEBUG    } = ( $params->{ DEBUG } || 0 )
                          & Template::Constants::DEBUG_FILTERS;


    return $self;
}




sub _dump {
    my $self = shift;
    my $output = "[Template::Filters] {\n";
    my $format = "    %-16s => %s\n";
    my $key;

    foreach $key (qw( TOLERANT )) {
        my $val = $self->{ $key };
        $val = '<undef>' unless defined $val;
        $output .= sprintf($format, $key, $val);
    }

    my $filters = $self->{ FILTERS };
    $filters = join('', map { 
        sprintf("    $format", $_, $filters->{ $_ });
    } keys %$filters);
    $filters = "{\n$filters    }";
    
    $output .= sprintf($format, 'FILTERS (local)' => $filters);

    $filters = $FILTERS;
    $filters = join('', map { 
        my $f = $filters->{ $_ };
        my ($ref, $dynamic) = ref $f eq 'ARRAY' ? @$f : ($f, 0);
        sprintf("    $format", $_, $dynamic ? 'dynamic' : 'static');
    } sort keys %$filters);
    $filters = "{\n$filters    }";
    
    $output .= sprintf($format, 'FILTERS (global)' => $filters);

    $output .= '}';
    return $output;
}




our $URI_ESCAPES;

sub uri_filter {
    my $text = shift;

    $URI_ESCAPES ||= {
        map { ( chr($_), sprintf("%%%02X", $_) ) } (0..255),
    };

    if ($] >= 5.008 && utf8::is_utf8($text)) {
        utf8::encode($text);
    }
    
    $text =~ s/([^A-Za-z0-9\-_.!~*'()])/$URI_ESCAPES->{$1}/eg;
    $text;
}


sub url_filter {
    my $text = shift;

    $URI_ESCAPES ||= {
        map { ( chr($_), sprintf("%%%02X", $_) ) } (0..255),
    };

    if ($] >= 5.008 && utf8::is_utf8($text)) {
        utf8::encode($text);
    }
    
    $text =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$URI_ESCAPES->{$1}/eg;
    $text;
}



sub html_filter {
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
    }
    return $text;
}



sub xml_filter {
    my $text = shift;
    for ($text) {
        s/&/&amp;/g;
        s/</&lt;/g;
        s/>/&gt;/g;
        s/"/&quot;/g;
        s/'/&apos;/g;
    }
    return $text;
}



sub html_paragraph  {
    my $text = shift;
    return "<p>\n" 
           . join("\n</p>\n\n<p>\n", split(/(?:\r?\n){2,}/, $text))
           . "</p>\n";
}



sub html_para_break  {
    my $text = shift;
    $text =~ s|(\r?\n){2,}|$1<br />$1<br />$1|g;
    return $text;
}


sub html_line_break  {
    my $text = shift;
    $text =~ s|(\r?\n)|<br />$1|g;
    return $text;
}



sub use_html_entities {
    require HTML::Entities;
    return ($AVAILABLE->{ HTML_ENTITY } = \&HTML::Entities::encode_entities);
}

sub use_apache_util {
    require Apache::Util;
    Apache::Util::escape_html('');      # TODO: explain this
    return ($AVAILABLE->{ HTML_ENTITY } = \&Apache::Util::escape_html);
}

sub html_entity_filter_factory {
    my $context = shift;
    my $haz;
    
    # if Apache::Util is installed then we use escape_html
    $haz = $AVAILABLE->{ HTML_ENTITY } 
       ||  eval { use_apache_util()   }
       ||  eval { use_html_entities() }
       ||  -1;      # we use -1 for "not available" because it's a true value

    return ref $haz eq 'CODE'
        ? $haz
        : (undef, Template::Exception->new( 
            html_entity => 'cannot locate Apache::Util or HTML::Entities' )
          );
}



sub indent_filter_factory {
    my ($context, $pad) = @_;
    $pad = 4 unless defined $pad;
    $pad = ' ' x $pad if $pad =~ /^\d+$/;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        $text =~ s/^/$pad/mg;
        return $text;
    }
}


sub format_filter_factory {
    my ($context, $format) = @_;
    $format = '%s' unless defined $format;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        return join("\n", map{ sprintf($format, $_) } split(/\n/, $text));
    }
}



sub repeat_filter_factory {
    my ($context, $iter) = @_;
    $iter = 1 unless defined $iter and length $iter;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        return join('\n', $text) x $iter;
    }
}



sub replace_filter_factory {
    my ($context, $search, $replace) = @_;
    $search = '' unless defined $search;
    $replace = '' unless defined $replace;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        $text =~ s/$search/$replace/g;
        return $text;
    }
}



sub remove_filter_factory {
    my ($context, $search) = @_;

    return sub {
        my $text = shift;
        $text = '' unless defined $text;
        $text =~ s/$search//g;
        return $text;
    }
}



sub truncate_filter_factory {
    my ($context, $len, $char) = @_;
    $len  = $TRUNCATE_LENGTH unless defined $len;
    $char = $TRUNCATE_ADDON  unless defined $char;

    # Length of char is the minimum length
    my $lchar = length $char;
    if ($len < $lchar) {
        $char  = substr($char, 0, $len);
        $lchar = $len;
    }

    return sub {
        my $text = shift;
        return $text if length $text <= $len;
        return substr($text, 0, $len - $lchar) . $char;


    }
}



sub eval_filter_factory {
    my $context = shift;

    return sub {
        my $text = shift;
        $context->process(\$text);
    }
}



sub perl_filter_factory {
    my $context = shift;
    my $stash = $context->stash;

    return (undef, Template::Exception->new('perl', 'EVAL_PERL is not set'))
        unless $context->eval_perl();

    return sub {
        my $text = shift;
        local($Template::Perl::context) = $context;
        local($Template::Perl::stash)   = $stash;
        my $out = eval <<EOF;
package Template::Perl; 
\$stash = \$context->stash(); 
$text
EOF
        $context->throw($@) if $@;
        return $out;
    }
}



sub redirect_filter_factory {
    my ($context, $file, $options) = @_;
    my $outpath = $context->config->{ OUTPUT_PATH };

    return (undef, Template::Exception->new('redirect', 
                                            'OUTPUT_PATH is not set'))
        unless $outpath;

    $context->throw('redirect', "relative filenames are not supported: $file")
        if $file =~ m{(^|/)\.\./};

    $options = { binmode => $options } unless ref $options;

    sub {
        my $text = shift;
        my $outpath = $context->config->{ OUTPUT_PATH }
            || return '';
        $outpath .= "/$file";
        my $error = Template::_output($outpath, \$text, $options);
        die Template::Exception->new('redirect', $error)
            if $error;
        return '';
    }
}



sub stdout_filter_factory {
    my ($context, $options) = @_;

    $options = { binmode => $options } unless ref $options;

    sub {
        my $text = shift;
        binmode(STDOUT) if $options->{ binmode };
        print STDOUT $text;
        return '';
    }
}


1;

__END__


