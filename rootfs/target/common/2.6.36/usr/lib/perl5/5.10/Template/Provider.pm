
package Template::Provider;

use strict;
use warnings;
use base 'Template::Base';
use Template::Config;
use Template::Constants;
use Template::Document;
use File::Basename;
use File::Spec;

use constant PREV   => 0;
use constant NAME   => 1;   # template name -- indexed by this name in LOOKUP
use constant DATA   => 2;   # Compiled template
use constant LOAD   => 3;   # mtime of template
use constant NEXT   => 4;   # link to next item in cache linked list
use constant STAT   => 5;   # Time last stat()ed

our $VERSION = 2.94;
our $DEBUG   = 0 unless defined $DEBUG;
our $ERROR   = '';

our $DOCUMENT = 'Template::Document' unless defined $DOCUMENT;

our $STAT_TTL = 1 unless defined $STAT_TTL;

our $MAX_DIRS = 64 unless defined $MAX_DIRS;

our $UNICODE = $] > 5.007 ? 1 : 0;

my $boms = [
    'UTF-8'    => "\x{ef}\x{bb}\x{bf}",
    'UTF-32BE' => "\x{0}\x{0}\x{fe}\x{ff}",
    'UTF-32LE' => "\x{ff}\x{fe}\x{0}\x{0}",
    'UTF-16BE' => "\x{fe}\x{ff}",
    'UTF-16LE' => "\x{ff}\x{fe}",
];

our $RELATIVE_PATH = qr[(?:^|/)\.+/];


BEGIN {
    if ($] < 5.006) {
        package bytes;
        $INC{'bytes.pm'} = 1;
    }
}




sub fetch {
    my ($self, $name) = @_;
    my ($data, $error);


    if (ref $name) {
        # $name can be a reference to a scalar, GLOB or file handle
        ($data, $error) = $self->_load($name);
        ($data, $error) = $self->_compile($data)
            unless $error;
        $data = $data->{ data }
            unless $error;
    }
    elsif (File::Spec->file_name_is_absolute($name)) {
        # absolute paths (starting '/') allowed if ABSOLUTE set
        ($data, $error) = $self->{ ABSOLUTE }
            ? $self->_fetch($name)
            : $self->{ TOLERANT }
                ? (undef, Template::Constants::STATUS_DECLINED)
            : ("$name: absolute paths are not allowed (set ABSOLUTE option)",
               Template::Constants::STATUS_ERROR);
    }
    elsif ($name =~ m/$RELATIVE_PATH/o) {
        # anything starting "./" is relative to cwd, allowed if RELATIVE set
        ($data, $error) = $self->{ RELATIVE }
            ? $self->_fetch($name)
            : $self->{ TOLERANT }
                ? (undef, Template::Constants::STATUS_DECLINED)
            : ("$name: relative paths are not allowed (set RELATIVE option)",
               Template::Constants::STATUS_ERROR);
    }
    else {
        # otherwise, it's a file name relative to INCLUDE_PATH
        ($data, $error) = $self->{ INCLUDE_PATH }
            ? $self->_fetch_path($name)
            : (undef, Template::Constants::STATUS_DECLINED);
    }


    return ($data, $error);
}



sub store {
    my ($self, $name, $data) = @_;
    $self->_store($name, {
        data => $data,
        load => 0,
    });
}



sub load {
    my ($self, $name) = @_;
    my ($data, $error);
    my $path = $name;

    if (File::Spec->file_name_is_absolute($name)) {
        # absolute paths (starting '/') allowed if ABSOLUTE set
        $error = "$name: absolute paths are not allowed (set ABSOLUTE option)"
            unless $self->{ ABSOLUTE };
    }
    elsif ($name =~ m[$RELATIVE_PATH]o) {
        # anything starting "./" is relative to cwd, allowed if RELATIVE set
        $error = "$name: relative paths are not allowed (set RELATIVE option)"
            unless $self->{ RELATIVE };
    }
    else {
      INCPATH: {
          # otherwise, it's a file name relative to INCLUDE_PATH
          my $paths = $self->paths()
              || return ($self->error(), Template::Constants::STATUS_ERROR);

          foreach my $dir (@$paths) {
              $path = File::Spec->catfile($dir, $name);
              last INCPATH
                  if $self->_template_modified($path);
          }
          undef $path;      # not found
      }
    }

    # Now fetch the content
    ($data, $error) = $self->_template_content($path)
        if defined $path && !$error;

    if ($error) {
        return $self->{ TOLERANT }
            ? (undef, Template::Constants::STATUS_DECLINED)
            : ($error, Template::Constants::STATUS_ERROR);
    }
    elsif (! defined $path) {
        return (undef, Template::Constants::STATUS_DECLINED);
    }
    else {
        return ($data, Template::Constants::STATUS_OK);
    }
}




sub include_path {
     my ($self, $path) = @_;
     $self->{ INCLUDE_PATH } = $path if $path;
     return $self->{ INCLUDE_PATH };
}



sub paths {
    my $self   = shift;
    my @ipaths = @{ $self->{ INCLUDE_PATH } };
    my (@opaths, $dpaths, $dir);
    my $count = $MAX_DIRS;

    while (@ipaths && --$count) {
        $dir = shift @ipaths || next;

        # $dir can be a sub or object ref which returns a reference
        # to a dynamically generated list of search paths.

        if (ref $dir eq 'CODE') {
            eval { $dpaths = &$dir() };
            if ($@) {
                chomp $@;
                return $self->error($@);
            }
            unshift(@ipaths, @$dpaths);
            next;
        }
        elsif (ref($dir) && UNIVERSAL::can($dir, 'paths')) {
            $dpaths = $dir->paths()
                || return $self->error($dir->error());
            unshift(@ipaths, @$dpaths);
            next;
        }
        else {
            push(@opaths, $dir);
        }
    }
    return $self->error("INCLUDE_PATH exceeds $MAX_DIRS directories")
        if @ipaths;

    return \@opaths;
}



sub DESTROY {
    my $self = shift;
    my ($slot, $next);

    $slot = $self->{ HEAD };
    while ($slot) {
        $next = $slot->[ NEXT ];
        undef $slot->[ PREV ];
        undef $slot->[ NEXT ];
        $slot = $next;
    }
    undef $self->{ HEAD };
    undef $self->{ TAIL };
}






sub _init {
    my ($self, $params) = @_;
    my $size = $params->{ CACHE_SIZE   };
    my $path = $params->{ INCLUDE_PATH } || '.';
    my $cdir = $params->{ COMPILE_DIR  } || '';
    my $dlim = $params->{ DELIMITER    };
    my $debug;

    # tweak delim to ignore C:/
    unless (defined $dlim) {
        $dlim = ($^O eq 'MSWin32') ? ':(?!\\/)' : ':';
    }

    # coerce INCLUDE_PATH to an array ref, if not already so
    $path = [ split(/$dlim/, $path) ]
        unless ref $path eq 'ARRAY';

    # don't allow a CACHE_SIZE 1 because it breaks things and the
    # additional checking isn't worth it
    $size = 2
        if defined $size && ($size == 1 || $size < 0);

    if (defined ($debug = $params->{ DEBUG })) {
        $self->{ DEBUG } = $debug & ( Template::Constants::DEBUG_PROVIDER
                                    | Template::Constants::DEBUG_FLAGS );
    }
    else {
        $self->{ DEBUG } = $DEBUG;
    }

    if ($self->{ DEBUG }) {
        local $" = ', ';
        $self->debug("creating cache of ",
                     defined $size ? $size : 'unlimited',
                     " slots for [ @$path ]");
    }

    # create COMPILE_DIR and sub-directories representing each INCLUDE_PATH
    # element in which to store compiled files
    if ($cdir) {
        require File::Path;
        foreach my $dir (@$path) {
            next if ref $dir;
            my $wdir = $dir;
            $wdir =~ s[:][]g if $^O eq 'MSWin32';
            $wdir =~ /(.*)/;  # untaint
            $wdir = "$1";     # quotes work around bug in Strawberry Perl
            $wdir = File::Spec->catfile($cdir, $wdir);
            File::Path::mkpath($wdir) unless -d $wdir;
        }
    }

    $self->{ LOOKUP       } = { };
    $self->{ NOTFOUND     } = { };  # Tracks templates *not* found.
    $self->{ SLOTS        } = 0;
    $self->{ SIZE         } = $size;
    $self->{ INCLUDE_PATH } = $path;
    $self->{ DELIMITER    } = $dlim;
    $self->{ COMPILE_DIR  } = $cdir;
    $self->{ COMPILE_EXT  } = $params->{ COMPILE_EXT } || '';
    $self->{ ABSOLUTE     } = $params->{ ABSOLUTE } || 0;
    $self->{ RELATIVE     } = $params->{ RELATIVE } || 0;
    $self->{ TOLERANT     } = $params->{ TOLERANT } || 0;
    $self->{ DOCUMENT     } = $params->{ DOCUMENT } || $DOCUMENT;
    $self->{ PARSER       } = $params->{ PARSER   };
    $self->{ DEFAULT      } = $params->{ DEFAULT  };
    $self->{ ENCODING     } = $params->{ ENCODING };
    $self->{ STAT_TTL     } = $params->{ STAT_TTL } || $STAT_TTL;
    $self->{ PARAMS       } = $params;

    # look for user-provided UNICODE parameter or use default from package var
    $self->{ UNICODE      } = defined $params->{ UNICODE }
                                    ? $params->{ UNICODE } : $UNICODE;

    return $self;
}



sub _fetch {
    my ($self, $name, $t_name) = @_;
    my $stat_ttl = $self->{ STAT_TTL };

    $self->debug("_fetch($name)") if $self->{ DEBUG };

    # First see if the named template is in the memory cache
    if ((my $slot = $self->{ LOOKUP }->{ $name })) {
        # Test if cache is fresh, and reload/compile if not.
        my ($data, $error) = $self->_refresh($slot);

        return $error
            ? ( $data, $error )     # $data may contain error text
            : $slot->[ DATA ];      # returned document object
    }

    # Otherwise, see if we already know the template is not found
    if (my $last_stat_time = $self->{ NOTFOUND }->{ $name }) {
        my $expires_in = $last_stat_time + $stat_ttl - time;
        if ($expires_in > 0) {
            $self->debug(" file [$name] in negative cache.  Expires in $expires_in seconds")
                if $self->{ DEBUG };
            return (undef, Template::Constants::STATUS_DECLINED);
        }
        else {
            delete $self->{ NOTFOUND }->{ $name };
        }
    }

    # Is there an up-to-date compiled version on disk?
    if ($self->_compiled_is_current($name)) {
        # require() the compiled template.
        my $compiled_template = $self->_load_compiled( $self->_compiled_filename($name) );

        # Store and return the compiled template
        return $self->store( $name, $compiled_template ) if $compiled_template;

        # Problem loading compiled template:
        # warn and continue to fetch source template
        warn($self->error(), "\n");
    }

    # load template from source
    my ($template, $error) = $self->_load($name, $t_name);

    if ($error) {
        # Template could not be fetched.  Add to the negative/notfound cache.
        $self->{ NOTFOUND }->{ $name } = time;
        return ( $template, $error );
    }

    # compile template source
    ($template, $error) = $self->_compile($template, $self->_compiled_filename($name) );

    if ($error) {
        # return any compile time error
        return ($template, $error);
    }
    else {
        # Store compiled template and return it
        return $self->store($name, $template->{data}) ;
    }
}



sub _fetch_path {
    my ($self, $name) = @_;

    $self->debug("_fetch_path($name)") if $self->{ DEBUG };

    # the template may have been stored using a non-filename name
    # so look for the plain name in the cache first
    if ((my $slot = $self->{ LOOKUP }->{ $name })) {
        # cached entry exists, so refresh slot and extract data
        my ($data, $error) = $self->_refresh($slot);

        return $error
            ? ($data, $error)
            : ($slot->[ DATA ], $error );
    }

    my $paths = $self->paths
        || return ( $self->error, Template::Constants::STATUS_ERROR );

    # search the INCLUDE_PATH for the file, in cache or on disk
    foreach my $dir (@$paths) {
        my $path = File::Spec->catfile($dir, $name);

        $self->debug("searching path: $path\n") if $self->{ DEBUG };

        my ($data, $error) = $self->_fetch( $path, $name );

        # Return if no error or if a serious error.
        return ( $data, $error )
            if !$error || $error == Template::Constants::STATUS_ERROR;

    }

    # not found in INCLUDE_PATH, now try DEFAULT
    return $self->_fetch_path( $self->{DEFAULT} )
        if defined $self->{DEFAULT} && $name ne $self->{DEFAULT};

    # We could not handle this template name
    return (undef, Template::Constants::STATUS_DECLINED);
}

sub _compiled_filename {
    my ($self, $file) = @_;
    my ($compext, $compdir) = @$self{ qw( COMPILE_EXT COMPILE_DIR ) };
    my ($path, $compiled);

    return undef
        unless $compext || $compdir;

    $path = $file;
    $path =~ /^(.+)$/s or die "invalid filename: $path";
    $path =~ s[:][]g if $^O eq 'MSWin32';

    $compiled = "$path$compext";
    $compiled = File::Spec->catfile($compdir, $compiled) if length $compdir;

    return $compiled;
}

sub _load_compiled {
    my ($self, $file) = @_;
    my $compiled;

    # load compiled template via require();  we zap any
    # %INC entry to ensure it is reloaded (we don't
    # want 1 returned by require() to say it's in memory)
    delete $INC{ $file };
    eval { $compiled = require $file; };
    return $@
        ? $self->error("compiled template $compiled: $@")
        : $compiled;
}


sub _load {
    my ($self, $name, $alias) = @_;
    my ($data, $error);
    my $tolerant = $self->{ TOLERANT };
    my $now = time;

    $alias = $name unless defined $alias or ref $name;

    $self->debug("_load($name, ", defined $alias ? $alias : '<no alias>',
                 ')') if $self->{ DEBUG };

    # SCALAR ref is the template text
    if (ref $name eq 'SCALAR') {
        # $name can be a SCALAR reference to the input text...
        return {
            name => defined $alias ? $alias : 'input text',
            path => defined $alias ? $alias : 'input text',
            text => $$name,
            time => $now,
            load => 0,
        };
    }

    # Otherwise, assume GLOB as a file handle
    if (ref $name) {
        local $/;
        my $text = <$name>;
        $text = $self->_decode_unicode($text) if $self->{ UNICODE };
        return {
            name => defined $alias ? $alias : 'input file handle',
            path => defined $alias ? $alias : 'input file handle',
            text => $text,
            time => $now,
            load => 0,
        };
    }

    # Otherwise, it's the name of the template
    if ( $self->_template_modified( $name ) ) {  # does template exist?
        my ($text, $error, $mtime ) = $self->_template_content( $name );
        unless ( $error )  {
            $text = $self->_decode_unicode($text) if $self->{ UNICODE };
            return {
                name => $alias,
                path => $name,
                text => $text,
                time => $mtime,
                load => $now,
            };
        }

        return ( "$alias: $!", Template::Constants::STATUS_ERROR )
            unless $tolerant;
    }

    # Unable to process template, pass onto the next Provider.
    return (undef, Template::Constants::STATUS_DECLINED);
}



sub _refresh {
    my ($self, $slot) = @_;
    my $stat_ttl = $self->{ STAT_TTL };
    my ($head, $file, $data, $error);

    $self->debug("_refresh([ ",
                 join(', ', map { defined $_ ? $_ : '<undef>' } @$slot),
                 '])') if $self->{ DEBUG };

    # if it's more than $STAT_TTL seconds since we last performed a
    # stat() on the file then we need to do it again and see if the file
    # time has changed
    my $now = time;
    my $expires_in_sec = $slot->[ STAT ] + $stat_ttl - $now;

    if ( $expires_in_sec <= 0 ) {  # Time to check!
        $slot->[ STAT ] = $now;

        # Grab mtime of template.
        # Seems like this should be abstracted to compare to
        # just ask for a newer compiled template (if it's newer)
        # and let that check for a newer template source.
        my $template_mtime = $self->_template_modified( $slot->[ NAME ] );
        if ( ! defined $template_mtime || ( $template_mtime != $slot->[ LOAD ] )) {
            $self->debug("refreshing cache file ", $slot->[ NAME ])
                if $self->{ DEBUG };

            ($data, $error) = $self->_load($slot->[ NAME ], $slot->[ DATA ]->{ name });
            ($data, $error) = $self->_compile($data)
                unless $error;

            if ($error) {
                # if the template failed to load/compile then we wipe out the
                # STAT entry.  This forces the provider to try and reload it
                # each time instead of using the previously cached version
                # until $STAT_TTL is next up
                $slot->[ STAT ] = 0;
            }
            else {
                $slot->[ DATA ] = $data->{ data };
                $slot->[ LOAD ] = $data->{ time };
            }
        }

    } elsif ( $self->{ DEBUG } ) {
        $self->debug( sprintf('STAT_TTL not met for file [%s].  Expires in %d seconds',
                        $slot->[ NAME ], $expires_in_sec ) );
    }

    # Move this slot to the head of the list
    unless( $self->{ HEAD } == $slot ) {
        # remove existing slot from usage chain...
        if ($slot->[ PREV ]) {
            $slot->[ PREV ]->[ NEXT ] = $slot->[ NEXT ];
        }
        else {
            $self->{ HEAD } = $slot->[ NEXT ];
        }
        if ($slot->[ NEXT ]) {
            $slot->[ NEXT ]->[ PREV ] = $slot->[ PREV ];
        }
        else {
            $self->{ TAIL } = $slot->[ PREV ];
        }

        # ..and add to start of list
        $head = $self->{ HEAD };
        $head->[ PREV ] = $slot if $head;
        $slot->[ PREV ] = undef;
        $slot->[ NEXT ] = $head;
        $self->{ HEAD } = $slot;
    }

    return ($data, $error);
}




sub _store {
    my ($self, $name, $data, $compfile) = @_;
    my $size = $self->{ SIZE };
    my ($slot, $head);

    # Return if memory cache disabled.  (overridding code should also check)
    # $$$ What's the expected behaviour of store()?  Can't tell from the
    # docs if you can call store() when SIZE = 0.
    return $data->{data} if defined $size and !$size;

    # extract the compiled template from the data hash
    $data = $data->{ data };
    $self->debug("_store($name, $data)") if $self->{ DEBUG };

    # check the modification time -- extra stat here
    my $load = $self->_modified($name);

    if (defined $size && $self->{ SLOTS } >= $size) {
        # cache has reached size limit, so reuse oldest entry
        $self->debug("reusing oldest cache entry (size limit reached: $size)\nslots: $self->{ SLOTS }") if $self->{ DEBUG };

        # remove entry from tail of list
        $slot = $self->{ TAIL };
        $slot->[ PREV ]->[ NEXT ] = undef;
        $self->{ TAIL } = $slot->[ PREV ];

        # remove name lookup for old node
        delete $self->{ LOOKUP }->{ $slot->[ NAME ] };

        # add modified node to head of list
        $head = $self->{ HEAD };
        $head->[ PREV ] = $slot if $head;
        @$slot = ( undef, $name, $data, $load, $head, time );
        $self->{ HEAD } = $slot;

        # add name lookup for new node
        $self->{ LOOKUP }->{ $name } = $slot;
    }
    else {
        # cache is under size limit, or none is defined

        $self->debug("adding new cache entry") if $self->{ DEBUG };

        # add new node to head of list
        $head = $self->{ HEAD };
        $slot = [ undef, $name, $data, $load, $head, time ];
        $head->[ PREV ] = $slot if $head;
        $self->{ HEAD } = $slot;
        $self->{ TAIL } = $slot unless $self->{ TAIL };

        # add lookup from name to slot and increment nslots
        $self->{ LOOKUP }->{ $name } = $slot;
        $self->{ SLOTS }++;
    }

    return $data;
}



sub _compile {
    my ($self, $data, $compfile) = @_;
    my $text = $data->{ text };
    my ($parsedoc, $error);

    $self->debug("_compile($data, ",
                 defined $compfile ? $compfile : '<no compfile>', ')')
        if $self->{ DEBUG };

    my $parser = $self->{ PARSER }
        ||= Template::Config->parser($self->{ PARAMS })
        ||  return (Template::Config->error(), Template::Constants::STATUS_ERROR);

    # discard the template text - we don't need it any more
    delete $data->{ text };

    # call parser to compile template into Perl code
    if ($parsedoc = $parser->parse($text, $data)) {

        $parsedoc->{ METADATA } = {
            'name'    => $data->{ name },
            'modtime' => $data->{ time },
            %{ $parsedoc->{ METADATA } },
        };

        # write the Perl code to the file $compfile, if defined
        if ($compfile) {
            my $basedir = &File::Basename::dirname($compfile);
            $basedir =~ /(.*)/;
            $basedir = $1;

            unless (-d $basedir) {
                eval { File::Path::mkpath($basedir) };
                $error = "failed to create compiled templates directory: $basedir ($@)"
                    if ($@);
            }

            unless ($error) {
                my $docclass = $self->{ DOCUMENT };
                $error = 'cache failed to write '
                    . &File::Basename::basename($compfile)
                    . ': ' . $docclass->error()
                    unless $docclass->write_perl_file($compfile, $parsedoc);
            }

            # set atime and mtime of newly compiled file, don't bother
            # if time is undef
            if (!defined($error) && defined $data->{ time }) {
                my ($cfile) = $compfile =~ /^(.+)$/s or do {
                    return("invalid filename: $compfile",
                           Template::Constants::STATUS_ERROR);
                };

                my ($ctime) = $data->{ time } =~ /^(\d+)$/;
                unless ($ctime || $ctime eq 0) {
                    return("invalid time: $ctime",
                           Template::Constants::STATUS_ERROR);
                }
                utime($ctime, $ctime, $cfile);

                $self->debug(" cached compiled template to file [$compfile]")
                    if $self->{ DEBUG };
            }
        }

        unless ($error) {
            return $data                                        ## RETURN ##
                if $data->{ data } = $DOCUMENT->new($parsedoc);
            $error = $Template::Document::ERROR;
        }
    }
    else {
        $error = Template::Exception->new( 'parse', "$data->{ name } " .
                                           $parser->error() );
    }

    # return STATUS_ERROR, or STATUS_DECLINED if we're being tolerant
    return $self->{ TOLERANT }
        ? (undef, Template::Constants::STATUS_DECLINED)
        : ($error,  Template::Constants::STATUS_ERROR)
}


sub _compiled_is_current {
    my ( $self, $template_name ) = @_;
    my $compiled_name   = $self->_compiled_filename($template_name) || return;
    my $compiled_mtime  = (stat($compiled_name))[9] || return;
    my $template_mtime  = $self->_template_modified( $template_name ) || return;

    # This was >= in the 2.15, but meant that downgrading
    # a source template would not get picked up.
    return $compiled_mtime == $template_mtime;
}



sub _template_modified {
    my $self = shift;
    my $template = shift || return;
    return (stat( $template ))[9];
}


sub _template_content {
    my ($self, $path) = @_;

    return (undef, "No path specified to fetch content from ")
        unless $path;

    my $data;
    my $mod_date;
    my $error;

    local *FH;
    if (open(FH, "< $path")) {
        local $/;
        binmode(FH);
        $data = <FH>;
        $mod_date = (stat($path))[9];
        close(FH);
    }
    else {
        $error = "$path: $!";
    }

    return wantarray
        ? ( $data, $error, $mod_date )
        : $data;
}



sub _modified {
    my ($self, $name, $time) = @_;
    my $load = $self->_template_modified($name)
        || return $time ? 1 : 0;

    return $time
         ? $load > $time
         : $load;
}


sub _dump {
    my $self = shift;
    my $size = $self->{ SIZE };
    my $parser = $self->{ PARSER };
    $parser = $parser ? $parser->_dump() : '<no parser>';
    $parser =~ s/\n/\n    /gm;
    $size = 'unlimited' unless defined $size;

    my $output = "[Template::Provider] {\n";
    my $format = "    %-16s => %s\n";
    my $key;

    $output .= sprintf($format, 'INCLUDE_PATH',
                       '[ ' . join(', ', @{ $self->{ INCLUDE_PATH } }) . ' ]');
    $output .= sprintf($format, 'CACHE_SIZE', $size);

    foreach $key (qw( ABSOLUTE RELATIVE TOLERANT DELIMITER
                      COMPILE_EXT COMPILE_DIR )) {
        $output .= sprintf($format, $key, $self->{ $key });
    }
    $output .= sprintf($format, 'PARSER', $parser);


    local $" = ', ';
    my $lookup = $self->{ LOOKUP };
    $lookup = join('', map {
        sprintf("    $format", $_, defined $lookup->{ $_ }
                ? ('[ ' . join(', ', map { defined $_ ? $_ : '<undef>' }
                               @{ $lookup->{ $_ } }) . ' ]') : '<undef>');
    } sort keys %$lookup);
    $lookup = "{\n$lookup    }";

    $output .= sprintf($format, LOOKUP => $lookup);

    $output .= '}';
    return $output;
}



sub _dump_cache {
    my $self = shift;
    my ($node, $lut, $count);

    $count = 0;
    if ($node = $self->{ HEAD }) {
        while ($node) {
            $lut->{ $node } = $count++;
            $node = $node->[ NEXT ];
        }
        $node = $self->{ HEAD };
        print STDERR "CACHE STATE:\n";
        print STDERR "  HEAD: ", $self->{ HEAD }->[ NAME ], "\n";
        print STDERR "  TAIL: ", $self->{ TAIL }->[ NAME ], "\n";
        while ($node) {
            my ($prev, $name, $data, $load, $next) = @$node;
            $prev = $prev ? "#$lut->{ $prev }<-": '<undef>';
            $next = $next ? "->#$lut->{ $next }": '<undef>';
            print STDERR "   #$lut->{ $node } : [ $prev, $name, $data, $load, $next ]\n";
            $node = $node->[ NEXT ];
        }
    }
}


sub _decode_unicode {
    my $self   = shift;
    my $string = shift;
    return undef unless defined $string;

    use bytes;
    require Encode;

    return $string if Encode::is_utf8( $string );

    # try all the BOMs in order looking for one (order is important
    # 32bit BOMs look like 16bit BOMs)

    my $count  = 0;

    while ($count < @{ $boms }) {
        my $enc = $boms->[$count++];
        my $bom = $boms->[$count++];

        # does the string start with the bom?
        if ($bom eq substr($string, 0, length($bom))) {
            # decode it and hand it back
            return Encode::decode($enc, substr($string, length($bom)), 1);
        }
    }

    return $self->{ ENCODING }
        ? Encode::decode( $self->{ ENCODING }, $string )
        : $string;
}


1;

__END__


