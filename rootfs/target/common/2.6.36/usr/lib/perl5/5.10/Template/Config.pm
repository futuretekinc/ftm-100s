 
package Template::Config;

use strict;
use warnings;
use base 'Template::Base';
use vars qw( $VERSION $DEBUG $ERROR $INSTDIR
             $PARSER $PROVIDER $PLUGINS $FILTERS $ITERATOR 
             $LATEX_PATH $PDFLATEX_PATH $DVIPS_PATH
             $STASH $SERVICE $CONTEXT $CONSTANTS @PRELOAD );

$VERSION   = 2.75;
$DEBUG     = 0 unless defined $DEBUG;
$ERROR     = '';
$CONTEXT   = 'Template::Context';
$FILTERS   = 'Template::Filters';
$ITERATOR  = 'Template::Iterator';
$PARSER    = 'Template::Parser';
$PLUGINS   = 'Template::Plugins';
$PROVIDER  = 'Template::Provider';
$SERVICE   = 'Template::Service';
$STASH     = 'Template::Stash';
$CONSTANTS = 'Template::Namespace::Constants';

@PRELOAD   = ( $CONTEXT, $FILTERS, $ITERATOR, $PARSER,
               $PLUGINS, $PROVIDER, $SERVICE, $STASH );

$INSTDIR  = '';




sub preload {
    my $class = shift;

    foreach my $module (@PRELOAD, @_) {
        $class->load($module) || return;
    };
    return 1;
}



sub load {
    my ($class, $module) = @_;
    $module =~ s[::][/]g;
    $module .= '.pm';
    eval { require $module; };
    return $@ ? $class->error("failed to load $module: $@") : 1;
}



sub parser {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH'
               ? shift : { @_ };

    return undef unless $class->load($PARSER);
    return $PARSER->new($params) 
        || $class->error("failed to create parser: ", $PARSER->error);
}



sub provider {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' 
               ? shift : { @_ };

    return undef unless $class->load($PROVIDER);
    return $PROVIDER->new($params) 
        || $class->error("failed to create template provider: ",
                         $PROVIDER->error);
}



sub plugins {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' 
               ? shift : { @_ };

    return undef unless $class->load($PLUGINS);
    return $PLUGINS->new($params)
        || $class->error("failed to create plugin provider: ",
                         $PLUGINS->error);
}



sub filters {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' 
               ? shift : { @_ };

    return undef unless $class->load($FILTERS);
    return $FILTERS->new($params)
        || $class->error("failed to create filter provider: ",
                         $FILTERS->error);
}



sub iterator {
    my $class = shift;
    my $list  = shift;

    return undef unless $class->load($ITERATOR);
    return $ITERATOR->new($list, @_)
        || $class->error("failed to create iterator: ", $ITERATOR->error);
}



sub stash {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' 
               ? shift : { @_ };

    return undef unless $class->load($STASH);
    return $STASH->new($params) 
        || $class->error("failed to create stash: ", $STASH->error);
}



sub context {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' 
               ? shift : { @_ };

    return undef unless $class->load($CONTEXT);
    return $CONTEXT->new($params) 
        || $class->error("failed to create context: ", $CONTEXT->error);
}



sub service {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' 
               ? shift : { @_ };

    return undef unless $class->load($SERVICE);
    return $SERVICE->new($params) 
        || $class->error("failed to create context: ", $SERVICE->error);
}



sub constants {
    my $class  = shift;
    my $params = defined($_[0]) && ref($_[0]) eq 'HASH' 
               ? shift : { @_ };

    return undef unless $class->load($CONSTANTS);
    return $CONSTANTS->new($params) 
        || $class->error("failed to create constants namespace: ", 
                         $CONSTANTS->error);
}



sub instdir {
    my ($class, $dir) = @_;
    my $inst = $INSTDIR 
        || return $class->error("no installation directory");
    $inst =~ s[/$][]g;
    $inst .= "/$dir" if $dir;
    return $inst;
}




package Template::TieString;

sub TIEHANDLE {
    my ($class, $textref) = @_;
    bless $textref, $class;
}
sub PRINT {
    my $self = shift;
    $$self .= join('', @_);
}



1;

__END__


