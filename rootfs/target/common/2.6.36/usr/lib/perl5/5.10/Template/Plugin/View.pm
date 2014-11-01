
package Template::Plugin::View;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 2.68;

use Template::View;


sub new {
    my $class = shift;
    my $context = shift;
    my $view = Template::View->new($context, @_)
        || return $class->error($Template::View::ERROR);
    $view->seal();
    return $view;
}

1;

__END__



