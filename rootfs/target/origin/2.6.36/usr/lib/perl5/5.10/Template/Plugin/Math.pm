
package Template::Plugin::Math;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 1.16;
our $AUTOLOAD;



sub new {
    my ($class, $context, $config) = @_;
    $config ||= { };

    bless {
        %$config,
    }, $class;
}

sub abs   { shift; CORE::abs($_[0]);          }
sub atan2 { shift; CORE::atan2($_[0], $_[1]); } # prototyped (ugg)
sub cos   { shift; CORE::cos($_[0]);          }
sub exp   { shift; CORE::exp($_[0]);          }
sub hex   { shift; CORE::hex($_[0]);          }
sub int   { shift; CORE::int($_[0]);          }
sub log   { shift; CORE::log($_[0]);          }
sub oct   { shift; CORE::oct($_[0]);          }
sub rand  { shift; CORE::rand($_[0]);         }
sub sin   { shift; CORE::sin($_[0]);          }
sub sqrt  { shift; CORE::sqrt($_[0]);         }
sub srand { shift; CORE::srand($_[0]);        }

sub truly_random {
    eval { require Math::TrulyRandom; }
         or die(Template::Exception->new("plugin",
            "Can't load Math::TrulyRandom"));
    return Math::TrulyRandom::truly_random_value();
}

eval {
    require Math::Trig;
    no strict qw(refs);
    for my $trig_func (@Math::Trig::EXPORT) {
        my $sub = Math::Trig->can($trig_func);
        *{$trig_func} = sub { shift; &$sub(@_) };
    }
};

sub AUTOLOAD { return; }

1;

__END__


