
package Template::Plugin::Wrap;

use strict;
use warnings;
use base 'Template::Plugin';
use Text::Wrap;

our $VERSION = 2.68;

sub new {
    my ($class, $context, $format) = @_;;
    $context->define_filter('wrap', [ \&wrap_filter_factory => 1 ]);
    return \&tt_wrap;
}

sub tt_wrap {
    my $text  = shift;
    my $width = shift || 72;
    my $itab  = shift;
    my $ntab  = shift;
    $itab = '' unless defined $itab;
    $ntab = '' unless defined $ntab;
    $Text::Wrap::columns = $width;
    Text::Wrap::wrap($itab, $ntab, $text);
}

sub wrap_filter_factory {
    my ($context, @args) = @_;
    return sub {
        my $text = shift;
        tt_wrap($text, @args);
    }
}


1;

__END__

