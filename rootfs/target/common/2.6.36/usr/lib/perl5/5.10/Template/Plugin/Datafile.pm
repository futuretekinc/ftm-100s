
package Template::Plugin::Datafile;

use strict;
use warnings;
use base 'Template::Plugin';

our $VERSION = 2.72;

sub new {
    my ($class, $context, $filename, $params) = @_;
    my ($delim, $line, @fields, @data, @results);
    my $self = [ ];
    local *FD;
    local $/ = "\n";

    $params ||= { };
    $delim = $params->{'delim'} || ':';
    $delim = quotemeta($delim);

    return $class->fail("No filename specified")
        unless $filename;

    open(FD, $filename)
        || return $class->fail("$filename: $!");

    # first line of file should contain field definitions
    while (! $line || $line =~ /^#/) {
        $line = <FD>;
        chomp $line;
        $line =~ s/\r$//;
    }

    (@fields = split(/\s*$delim\s*/, $line)) 
        || return $class->fail("first line of file must contain field names");

    # read each line of the file
    while (<FD>) {
        chomp;
        s/\r$//;

        # ignore comments and blank lines
        next if /^#/ || /^\s*$/;

        # split line into fields
        @data = split(/\s*$delim\s*/);

        # create hash record to represent data
        my %record;
        @record{ @fields } = @data;

        push(@$self, \%record);
    }

    bless $self, $class;
}       


sub as_list {
    return $_[0];
}


1;

__END__


