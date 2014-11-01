package CGI::Fast;




$CGI::Fast::VERSION='1.07';

use CGI;
use FCGI;
@ISA = ('CGI');

while (($ignore) = each %ENV) { }

sub save_request {
    # no-op
}

use vars qw($Ext_Request);
BEGIN {
   # If ENV{FCGI_SOCKET_PATH} is given, explicitly open the socket,
   # and keep the request handle around from which to call Accept().
   if ($ENV{FCGI_SOCKET_PATH}) {
	my $path    = $ENV{FCGI_SOCKET_PATH};
	my $backlog = $ENV{FCGI_LISTEN_QUEUE} || 100;
	my $socket  = FCGI::OpenSocket( $path, $backlog );
	$Ext_Request = FCGI::Request( \*STDIN, \*STDOUT, \*STDERR, 
					\%ENV, $socket, 1 );
   }
}

sub new {
     my ($self, $initializer, @param) = @_;
     unless (defined $initializer) {
	if ($Ext_Request) {
          return undef unless $Ext_Request->Accept() >= 0;
	} else {
         return undef unless FCGI::accept() >= 0;
     }
     }
     CGI->_reset_globals;
     return $CGI::Q = $self->SUPER::new($initializer, @param);
}

1;

