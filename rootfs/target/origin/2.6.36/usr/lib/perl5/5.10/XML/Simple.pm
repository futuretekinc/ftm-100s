
package XML::Simple;





use strict;
use Carp;
require Exporter;



use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $PREFERRED_PARSER);

@ISA               = qw(Exporter);
@EXPORT            = qw(XMLin XMLout);
@EXPORT_OK         = qw(xml_in xml_out);
$VERSION           = '2.18';
$PREFERRED_PARSER  = undef;

my $StrictMode     = 0;

my @KnownOptIn     = qw(keyattr keeproot forcecontent contentkey noattr
                        searchpath forcearray cache suppressempty parseropts
                        grouptags nsexpand datahandler varattr variables
                        normalisespace normalizespace valueattr);

my @KnownOptOut    = qw(keyattr keeproot contentkey noattr
                        rootname xmldecl outputfile noescape suppressempty
                        grouptags nsexpand handler noindent attrindent nosort
                        valueattr numericescape);

my @DefKeyAttr     = qw(name key id);
my $DefRootName    = qq(opt);
my $DefContentKey  = qq(content);
my $DefXmlDecl     = qq(<?xml version='1.0' standalone='yes'?>);

my $xmlns_ns       = 'http://www.w3.org/2000/xmlns/';
my $bad_def_ns_jcn = '{' . $xmlns_ns . '}';     # LibXML::SAX workaround



my %MemShareCache  = ();
my %MemCopyCache   = ();



sub import {
  # Handle the :strict tag
  
  $StrictMode = 1 if grep(/^:strict$/, @_);

  # Pass everything else to Exporter.pm

  @_ = grep(!/^:strict$/, @_);
  goto &Exporter::import;
}



sub new {
  my $class = shift;

  if(@_ % 2) {
    croak "Default options must be name=>value pairs (odd number supplied)";
  }

  my %known_opt;
  @known_opt{@KnownOptIn, @KnownOptOut} = (undef) x 100;

  my %raw_opt = @_;
  my %def_opt;
  while(my($key, $val) = each %raw_opt) {
    my $lkey = lc($key);
    $lkey =~ s/_//g;
    croak "Unrecognised option: $key" unless(exists($known_opt{$lkey}));
    $def_opt{$lkey} = $val;
  }
  my $self = { def_opt => \%def_opt };

  return(bless($self, $class));
}



sub _get_object {
  my $self;
  if($_[0]  and  UNIVERSAL::isa($_[0], 'XML::Simple')) {
    $self = shift;
  }
  else {
    $self = XML::Simple->new();
  }
  
  return $self;
}



sub XMLin {
  my $self = &_get_object;      # note, @_ is passed implicitly

  my $target = shift;


  # Work out whether to parse a string, a file or a filehandle

  if(not defined $target) {
    return $self->parse_file(undef, @_);
  }

  elsif($target eq '-') {
    local($/) = undef;
    $target = <STDIN>;
    return $self->parse_string(\$target, @_);
  }

  elsif(my $type = ref($target)) {
    if($type eq 'SCALAR') {
      return $self->parse_string($target, @_);
    }
    else {
      return $self->parse_fh($target, @_);
    }
  }

  elsif($target =~ m{<.*?>}s) {
    return $self->parse_string(\$target, @_);
  }

  else {
    return $self->parse_file($target, @_);
  }
}



sub parse_file {
  my $self = &_get_object;      # note, @_ is passed implicitly

  my $filename = shift;

  $self->handle_options('in', @_);

  $filename = $self->default_config_file if not defined $filename;

  $filename = $self->find_xml_file($filename, @{$self->{opt}->{searchpath}});

  # Check cache for previous parse

  if($self->{opt}->{cache}) {
    foreach my $scheme (@{$self->{opt}->{cache}}) {
      my $method = 'cache_read_' . $scheme;
      my $opt = $self->$method($filename);
      return($opt) if($opt);
    }
  }

  my $ref = $self->build_simple_tree($filename, undef);

  if($self->{opt}->{cache}) {
    my $method = 'cache_write_' . $self->{opt}->{cache}->[0];
    $self->$method($ref, $filename);
  }

  return $ref;
}



sub parse_fh {
  my $self = &_get_object;      # note, @_ is passed implicitly

  my $fh = shift;
  croak "Can't use " . (defined $fh ? qq{string ("$fh")} : 'undef') .
        " as a filehandle" unless ref $fh;

  $self->handle_options('in', @_);

  return $self->build_simple_tree(undef, $fh);
}



sub parse_string {
  my $self = &_get_object;      # note, @_ is passed implicitly

  my $string = shift;

  $self->handle_options('in', @_);

  return $self->build_simple_tree(undef, ref $string ? $string : \$string);
}



sub default_config_file {
  my $self = shift;

  require File::Basename;

  my($basename, $script_dir, $ext) = File::Basename::fileparse($0, '\.[^\.]+');

  # Add script directory to searchpath
  
  if($script_dir) {
    unshift(@{$self->{opt}->{searchpath}}, $script_dir);
  }

  return $basename . '.xml';
}



sub build_simple_tree {
  my $self = shift;

  my $tree = $self->build_tree(@_);

  return $self->{opt}->{keeproot}
         ? $self->collapse({}, @$tree)
         : $self->collapse(@{$tree->[1]});
}



sub build_tree {
  my $self     = shift;
  my $filename = shift;
  my $string   = shift;


  my $preferred_parser = $PREFERRED_PARSER;
  unless(defined($preferred_parser)) {
    $preferred_parser = $ENV{XML_SIMPLE_PREFERRED_PARSER} || '';
  }
  if($preferred_parser eq 'XML::Parser') {
    return($self->build_tree_xml_parser($filename, $string));
  }

  eval { require XML::SAX; };      # We didn't need it until now
  if($@) {                         # No XML::SAX - fall back to XML::Parser
    if($preferred_parser) {        # unless a SAX parser was expressly requested
      croak "XMLin() could not load XML::SAX";
    }
    return($self->build_tree_xml_parser($filename, $string));
  }

  $XML::SAX::ParserPackage = $preferred_parser if($preferred_parser);

  my $sp = XML::SAX::ParserFactory->parser(Handler => $self);
  
  $self->{nocollapse} = 1;
  my($tree);
  if($filename) {
    $tree = $sp->parse_uri($filename);
  }
  else {
    if(ref($string) && ref($string) ne 'SCALAR') {
      $tree = $sp->parse_file($string);
    }
    else {
      $tree = $sp->parse_string($$string);
    }
  }

  return($tree);
}



sub build_tree_xml_parser {
  my $self     = shift;
  my $filename = shift;
  my $string   = shift;


  eval {
    local($^W) = 0;      # Suppress warning from Expat.pm re File::Spec::load()
    require XML::Parser; # We didn't need it until now
  };
  if($@) {
    croak "XMLin() requires either XML::SAX or XML::Parser";
  }

  if($self->{opt}->{nsexpand}) {
    carp "'nsexpand' option requires XML::SAX";
  }

  my $xp = XML::Parser->new(Style => 'Tree', @{$self->{opt}->{parseropts}});
  my($tree);
  if($filename) {
    # $tree = $xp->parsefile($filename);  # Changed due to prob w/mod_perl
    local(*XML_FILE);
    open(XML_FILE, '<', $filename) || croak qq($filename - $!);
    $tree = $xp->parse(*XML_FILE);
    close(XML_FILE);
  }
  else {
    $tree = $xp->parse($$string);
  }

  return($tree);
}



sub cache_write_storable {
  my($self, $data, $filename) = @_;

  my $cachefile = $self->storable_filename($filename);

  require Storable;           # We didn't need it until now

  if ('VMS' eq $^O) {
    Storable::nstore($data, $cachefile);
  }
  else {
    # If the following line fails for you, your Storable.pm is old - upgrade
    Storable::lock_nstore($data, $cachefile);
  }
  
}



sub cache_read_storable {
  my($self, $filename) = @_;
  
  my $cachefile = $self->storable_filename($filename);

  return unless(-r $cachefile);
  return unless((stat($cachefile))[9] > (stat($filename))[9]);

  require Storable;           # We didn't need it until now
  
  if ('VMS' eq $^O) {
    return(Storable::retrieve($cachefile));
  }
  else {
    return(Storable::lock_retrieve($cachefile));
  }
  
}



sub storable_filename {
  my($self, $cachefile) = @_;

  $cachefile =~ s{(\.xml)?$}{.stor};
  return $cachefile;
}



sub cache_write_memshare {
  my($self, $data, $filename) = @_;

  $MemShareCache{$filename} = [time(), $data];
}



sub cache_read_memshare {
  my($self, $filename) = @_;
  
  return unless($MemShareCache{$filename});
  return unless($MemShareCache{$filename}->[0] > (stat($filename))[9]);

  return($MemShareCache{$filename}->[1]);
  
}



sub cache_write_memcopy {
  my($self, $data, $filename) = @_;

  require Storable;           # We didn't need it until now
  
  $MemCopyCache{$filename} = [time(), Storable::dclone($data)];
}



sub cache_read_memcopy {
  my($self, $filename) = @_;
  
  return unless($MemCopyCache{$filename});
  return unless($MemCopyCache{$filename}->[0] > (stat($filename))[9]);

  return(Storable::dclone($MemCopyCache{$filename}->[1]));
  
}



sub XMLout {
  my $self = &_get_object;      # note, @_ is passed implicitly

  croak "XMLout() requires at least one argument" unless(@_);
  my $ref = shift;

  $self->handle_options('out', @_);


  # If namespace expansion is set, XML::NamespaceSupport is required

  if($self->{opt}->{nsexpand}) {
    require XML::NamespaceSupport;
    $self->{nsup} = XML::NamespaceSupport->new();
    $self->{ns_prefix} = 'aaa';
  }


  # Wrap top level arrayref in a hash

  if(UNIVERSAL::isa($ref, 'ARRAY')) {
    $ref = { anon => $ref };
  }


  # Extract rootname from top level hash if keeproot enabled

  if($self->{opt}->{keeproot}) {
    my(@keys) = keys(%$ref);
    if(@keys == 1) {
      $ref = $ref->{$keys[0]};
      $self->{opt}->{rootname} = $keys[0];
    }
  }
  
  # Ensure there are no top level attributes if we're not adding root elements

  elsif($self->{opt}->{rootname} eq '') {
    if(UNIVERSAL::isa($ref, 'HASH')) {
      my $refsave = $ref;
      $ref = {};
      foreach (keys(%$refsave)) {
        if(ref($refsave->{$_})) {
          $ref->{$_} = $refsave->{$_};
        }
        else {
          $ref->{$_} = [ $refsave->{$_} ];
        }
      }
    }
  }


  # Encode the hashref and write to file if necessary

  $self->{_ancestors} = [];
  my $xml = $self->value_to_xml($ref, $self->{opt}->{rootname}, '');
  delete $self->{_ancestors};

  if($self->{opt}->{xmldecl}) {
    $xml = $self->{opt}->{xmldecl} . "\n" . $xml;
  }

  if($self->{opt}->{outputfile}) {
    if(ref($self->{opt}->{outputfile})) {
      my $fh = $self->{opt}->{outputfile};
      if(UNIVERSAL::isa($fh, 'GLOB') and !UNIVERSAL::can($fh, 'print')) {
        eval { require IO::Handle; };
        croak $@ if $@;
      }
      return($fh->print($xml));
    }
    else {
      local(*OUT);
      open(OUT, '>', "$self->{opt}->{outputfile}") ||
        croak "open($self->{opt}->{outputfile}): $!";
      binmode(OUT, ':utf8') if($] >= 5.008);
      print OUT $xml || croak "print: $!";
      close(OUT);
    }
  }
  elsif($self->{opt}->{handler}) {
    require XML::SAX;
    my $sp = XML::SAX::ParserFactory->parser(
               Handler => $self->{opt}->{handler}
             );
    return($sp->parse_string($xml));
  }
  else {
    return($xml);
  }
}



sub handle_options  {
  my $self = shift;
  my $dirn = shift;


  # Determine valid options based on context

  my %known_opt; 
  if($dirn eq 'in') {
    @known_opt{@KnownOptIn} = @KnownOptIn;
  }
  else {
    @known_opt{@KnownOptOut} = @KnownOptOut;
  }


  # Store supplied options in hashref and weed out invalid ones

  if(@_ % 2) {
    croak "Options must be name=>value pairs (odd number supplied)";
  }
  my %raw_opt  = @_;
  my $opt      = {};
  $self->{opt} = $opt;

  while(my($key, $val) = each %raw_opt) {
    my $lkey = lc($key);
    $lkey =~ s/_//g;
    croak "Unrecognised option: $key" unless($known_opt{$lkey});
    $opt->{$lkey} = $val;
  }


  # Merge in options passed to constructor

  foreach (keys(%known_opt)) {
    unless(exists($opt->{$_})) {
      if(exists($self->{def_opt}->{$_})) {
        $opt->{$_} = $self->{def_opt}->{$_};
      }
    }
  }


  # Set sensible defaults if not supplied
  
  if(exists($opt->{rootname})) {
    unless(defined($opt->{rootname})) {
      $opt->{rootname} = '';
    }
  }
  else {
    $opt->{rootname} = $DefRootName;
  }
  
  if($opt->{xmldecl}  and  $opt->{xmldecl} eq '1') {
    $opt->{xmldecl} = $DefXmlDecl;
  }

  if(exists($opt->{contentkey})) {
    if($opt->{contentkey} =~ m{^-(.*)$}) {
      $opt->{contentkey} = $1;
      $opt->{collapseagain} = 1;
    }
  }
  else {
    $opt->{contentkey} = $DefContentKey;
  }

  unless(exists($opt->{normalisespace})) {
    $opt->{normalisespace} = $opt->{normalizespace};
  }
  $opt->{normalisespace} = 0 unless(defined($opt->{normalisespace}));

  # Cleanups for values assumed to be arrays later

  if($opt->{searchpath}) {
    unless(ref($opt->{searchpath})) {
      $opt->{searchpath} = [ $opt->{searchpath} ];
    }
  }
  else  {
    $opt->{searchpath} = [ ];
  }

  if($opt->{cache}  and !ref($opt->{cache})) {
    $opt->{cache} = [ $opt->{cache} ];
  }
  if($opt->{cache}) {
    $_ = lc($_) foreach (@{$opt->{cache}});
    foreach my $scheme (@{$opt->{cache}}) {
      my $method = 'cache_read_' . $scheme;
      croak "Unsupported caching scheme: $scheme"
        unless($self->can($method));
    }
  }
  
  if(exists($opt->{parseropts})) {
    if($^W) {
      carp "Warning: " .
           "'ParserOpts' is deprecated, contact the author if you need it";
    }
  }
  else {
    $opt->{parseropts} = [ ];
  }

  
  # Special cleanup for {forcearray} which could be regex, arrayref or boolean
  # or left to default to 0

  if(exists($opt->{forcearray})) {
    if(ref($opt->{forcearray}) eq 'Regexp') {
      $opt->{forcearray} = [ $opt->{forcearray} ];
    }

    if(ref($opt->{forcearray}) eq 'ARRAY') {
      my @force_list = @{$opt->{forcearray}};
      if(@force_list) {
        $opt->{forcearray} = {};
        foreach my $tag (@force_list) {
          if(ref($tag) eq 'Regexp') {
            push @{$opt->{forcearray}->{_regex}}, $tag;
          }
          else {
            $opt->{forcearray}->{$tag} = 1;
          }
        }
      }
      else {
        $opt->{forcearray} = 0;
      }
    }
    else {
      $opt->{forcearray} = ( $opt->{forcearray} ? 1 : 0 );
    }
  }
  else {
    if($StrictMode  and  $dirn eq 'in') {
      croak "No value specified for 'ForceArray' option in call to XML$dirn()";
    }
    $opt->{forcearray} = 0;
  }


  # Special cleanup for {keyattr} which could be arrayref or hashref or left
  # to default to arrayref

  if(exists($opt->{keyattr}))  {
    if(ref($opt->{keyattr})) {
      if(ref($opt->{keyattr}) eq 'HASH') {

        # Make a copy so we can mess with it

        $opt->{keyattr} = { %{$opt->{keyattr}} };

        
        # Convert keyattr => { elem => '+attr' }
        # to keyattr => { elem => [ 'attr', '+' ] } 

        foreach my $el (keys(%{$opt->{keyattr}})) {
          if($opt->{keyattr}->{$el} =~ /^(\+|-)?(.*)$/) {
            $opt->{keyattr}->{$el} = [ $2, ($1 ? $1 : '') ];
            if($StrictMode  and  $dirn eq 'in') {
              next if($opt->{forcearray} == 1);
              next if(ref($opt->{forcearray}) eq 'HASH'
                      and $opt->{forcearray}->{$el});
              croak "<$el> set in KeyAttr but not in ForceArray";
            }
          }
          else {
            delete($opt->{keyattr}->{$el}); # Never reached (famous last words?)
          }
        }
      }
      else {
        if(@{$opt->{keyattr}} == 0) {
          delete($opt->{keyattr});
        }
      }
    }
    else {
      $opt->{keyattr} = [ $opt->{keyattr} ];
    }
  }
  else  {
    if($StrictMode) {
      croak "No value specified for 'KeyAttr' option in call to XML$dirn()";
    }
    $opt->{keyattr} = [ @DefKeyAttr ];
  }


  # Special cleanup for {valueattr} which could be arrayref or hashref

  if(exists($opt->{valueattr})) {
    if(ref($opt->{valueattr}) eq 'ARRAY') {
      $opt->{valueattrlist} = {};
      $opt->{valueattrlist}->{$_} = 1 foreach(@{ delete $opt->{valueattr} });
    }
  }

  # make sure there's nothing weird in {grouptags}

  if($opt->{grouptags}) {
    croak "Illegal value for 'GroupTags' option - expected a hashref"
      unless UNIVERSAL::isa($opt->{grouptags}, 'HASH');

    while(my($key, $val) = each %{$opt->{grouptags}}) {
      next if $key ne $val;
      croak "Bad value in GroupTags: '$key' => '$val'";
    }
  }


  # Check the {variables} option is valid and initialise variables hash

  if($opt->{variables} and !UNIVERSAL::isa($opt->{variables}, 'HASH')) {
    croak "Illegal value for 'Variables' option - expected a hashref";
  }

  if($opt->{variables}) { 
    $self->{_var_values} = { %{$opt->{variables}} };
  }
  elsif($opt->{varattr}) { 
    $self->{_var_values} = {};
  }

}



sub find_xml_file  {
  my $self = shift;
  my $file = shift;
  my @search_path = @_;


  require File::Basename;
  require File::Spec;

  my($filename, $filedir) = File::Basename::fileparse($file);

  if($filename ne $file) {        # Ignore searchpath if dir component
    return($file) if(-e $file);
  }
  else {
    my($path);
    foreach $path (@search_path)  {
      my $fullpath = File::Spec->catfile($path, $file);
      return($fullpath) if(-e $fullpath);
    }
  }

  # If user did not supply a search path, default to current directory

  if(!@search_path) {
    return($file) if(-e $file);
    croak "File does not exist: $file";
  }

  croak "Could not find $file in ", join(':', @search_path);
}



sub collapse {
  my $self = shift;


  # Start with the hash of attributes
  
  my $attr  = shift;
  if($self->{opt}->{noattr}) {                    # Discard if 'noattr' set
    $attr = {};
  }
  elsif($self->{opt}->{normalisespace} == 2) {
    while(my($key, $value) = each %$attr) {
      $attr->{$key} = $self->normalise_space($value)
    }
  }


  # Do variable substitutions

  if(my $var = $self->{_var_values}) {
    while(my($key, $val) = each(%$attr)) {
      $val =~ s{\$\{([\w.]+)\}}{ $self->get_var($1) }ge;
      $attr->{$key} = $val;
    }
  }


  # Roll up 'value' attributes (but only if no nested elements)

  if(!@_  and  keys %$attr == 1) {
    my($k) = keys %$attr;
    if($self->{opt}->{valueattrlist}  and $self->{opt}->{valueattrlist}->{$k}) {
      return $attr->{$k};
    }
  }


  # Add any nested elements

  my($key, $val);
  while(@_) {
    $key = shift;
    $val = shift;

    if(ref($val)) {
      $val = $self->collapse(@$val);
      next if(!defined($val)  and  $self->{opt}->{suppressempty});
    }
    elsif($key eq '0') {
      next if($val =~ m{^\s*$}s);  # Skip all whitespace content

      $val = $self->normalise_space($val)
        if($self->{opt}->{normalisespace} == 2);

      # do variable substitutions

      if(my $var = $self->{_var_values}) { 
        $val =~ s{\$\{(\w+)\}}{ $self->get_var($1) }ge;
      }

      
      # look for variable definitions

      if(my $var = $self->{opt}->{varattr}) { 
        if(exists $attr->{$var}) {
          $self->set_var($attr->{$var}, $val);
        }
      }


      # Collapse text content in element with no attributes to a string

      if(!%$attr  and  !@_) {
        return($self->{opt}->{forcecontent} ? 
          { $self->{opt}->{contentkey} => $val } : $val
        );
      }
      $key = $self->{opt}->{contentkey};
    }


    # Combine duplicate attributes into arrayref if required

    if(exists($attr->{$key})) {
      if(UNIVERSAL::isa($attr->{$key}, 'ARRAY')) {
        push(@{$attr->{$key}}, $val);
      }
      else {
        $attr->{$key} = [ $attr->{$key}, $val ];
      }
    }
    elsif(defined($val)  and  UNIVERSAL::isa($val, 'ARRAY')) {
      $attr->{$key} = [ $val ];
    }
    else {
      if( $key ne $self->{opt}->{contentkey} 
          and (
            ($self->{opt}->{forcearray} == 1)
            or ( 
              (ref($self->{opt}->{forcearray}) eq 'HASH')
              and (
                $self->{opt}->{forcearray}->{$key}
                or (grep $key =~ $_, @{$self->{opt}->{forcearray}->{_regex}})
              )
            )
          )
        ) {
        $attr->{$key} = [ $val ];
      }
      else {
        $attr->{$key} = $val;
      }
    }

  }


  # Turn arrayrefs into hashrefs if key fields present

  if($self->{opt}->{keyattr}) {
    while(($key,$val) = each %$attr) {
      if(defined($val)  and  UNIVERSAL::isa($val, 'ARRAY')) {
        $attr->{$key} = $self->array_to_hash($key, $val);
      }
    }
  }


  # disintermediate grouped tags

  if($self->{opt}->{grouptags}) {
    while(my($key, $val) = each(%$attr)) {
      next unless(UNIVERSAL::isa($val, 'HASH') and (keys %$val == 1));
      next unless(exists($self->{opt}->{grouptags}->{$key}));

      my($child_key, $child_val) =  %$val;

      if($self->{opt}->{grouptags}->{$key} eq $child_key) {
        $attr->{$key}= $child_val;
      }
    }
  }


  # Fold hashes containing a single anonymous array up into just the array

  my $count = scalar keys %$attr;
  if($count == 1 
     and  exists $attr->{anon}  
     and  UNIVERSAL::isa($attr->{anon}, 'ARRAY')
  ) {
    return($attr->{anon});
  }


  # Do the right thing if hash is empty, otherwise just return it

  if(!%$attr  and  exists($self->{opt}->{suppressempty})) {
    if(defined($self->{opt}->{suppressempty})  and
       $self->{opt}->{suppressempty} eq '') {
      return('');
    }
    return(undef);
  }


  # Roll up named elements with named nested 'value' attributes

  if($self->{opt}->{valueattr}) {
    while(my($key, $val) = each(%$attr)) {
      next unless($self->{opt}->{valueattr}->{$key});
      next unless(UNIVERSAL::isa($val, 'HASH') and (keys %$val == 1));
      my($k) = keys %$val;
      next unless($k eq $self->{opt}->{valueattr}->{$key});
      $attr->{$key} = $val->{$k};
    }
  }

  return($attr)

}



sub set_var {
  my($self, $name, $value) = @_;

  $self->{_var_values}->{$name} = $value;
}



sub get_var {
  my($self, $name) = @_;

  my $value = $self->{_var_values}->{$name};
  return $value if(defined($value));

  return '${' . $name . '}';
}



sub normalise_space {
  my($self, $text) = @_;

  $text =~ s/^\s+//s;
  $text =~ s/\s+$//s;
  $text =~ s/\s\s+/ /sg;

  return $text;
}



sub array_to_hash {
  my $self     = shift;
  my $name     = shift;
  my $arrayref = shift;

  my $hashref  = $self->new_hashref;

  my($i, $key, $val, $flag);


  # Handle keyattr => { .... }

  if(ref($self->{opt}->{keyattr}) eq 'HASH') {
    return($arrayref) unless(exists($self->{opt}->{keyattr}->{$name}));
    ($key, $flag) = @{$self->{opt}->{keyattr}->{$name}};
    for($i = 0; $i < @$arrayref; $i++)  {
      if(UNIVERSAL::isa($arrayref->[$i], 'HASH') and
         exists($arrayref->[$i]->{$key})
      ) {
        $val = $arrayref->[$i]->{$key};
        if(ref($val)) {
          $self->die_or_warn("<$name> element has non-scalar '$key' key attribute");
          return($arrayref);
        }
        $val = $self->normalise_space($val)
          if($self->{opt}->{normalisespace} == 1);
        $self->die_or_warn("<$name> element has non-unique value in '$key' key attribute: $val")
          if(exists($hashref->{$val}));
        $hashref->{$val} = { %{$arrayref->[$i]} };
        $hashref->{$val}->{"-$key"} = $hashref->{$val}->{$key} if($flag eq '-');
        delete $hashref->{$val}->{$key} unless($flag eq '+');
      }
      else {
        $self->die_or_warn("<$name> element has no '$key' key attribute");
        return($arrayref);
      }
    }
  }


  # Or assume keyattr => [ .... ]

  else {
    my $default_keys =
      join(',', @DefKeyAttr) eq join(',', @{$self->{opt}->{keyattr}});

    ELEMENT: for($i = 0; $i < @$arrayref; $i++)  {
      return($arrayref) unless(UNIVERSAL::isa($arrayref->[$i], 'HASH'));

      foreach $key (@{$self->{opt}->{keyattr}}) {
        if(defined($arrayref->[$i]->{$key}))  {
          $val = $arrayref->[$i]->{$key};
          if(ref($val)) {
            $self->die_or_warn("<$name> element has non-scalar '$key' key attribute")
              if not $default_keys;
            return($arrayref);
          }
          $val = $self->normalise_space($val)
            if($self->{opt}->{normalisespace} == 1);
          $self->die_or_warn("<$name> element has non-unique value in '$key' key attribute: $val")
            if(exists($hashref->{$val}));
          $hashref->{$val} = { %{$arrayref->[$i]} };
          delete $hashref->{$val}->{$key};
          next ELEMENT;
        }
      }

      return($arrayref);    # No keyfield matched
    }
  }
  
  # collapse any hashes which now only have a 'content' key

  if($self->{opt}->{collapseagain}) {
    $hashref = $self->collapse_content($hashref);
  }
 
  return($hashref);
}



sub die_or_warn {
  my $self = shift;
  my $msg  = shift;

  croak $msg if($StrictMode);
  carp "Warning: $msg" if($^W);
}



sub new_hashref {
  my $self = shift;

  return { @_ };
}



sub collapse_content {
  my $self       = shift;
  my $hashref    = shift; 

  my $contentkey = $self->{opt}->{contentkey};

  # first go through the values,checking that they are fit to collapse
  foreach my $val (values %$hashref) {
    return $hashref unless (     (ref($val) eq 'HASH')
                             and (keys %$val == 1)
                             and (exists $val->{$contentkey})
                           );
  }

  # now collapse them
  foreach my $key (keys %$hashref) {
    $hashref->{$key}=  $hashref->{$key}->{$contentkey};
  }

  return $hashref;
}
  


sub value_to_xml {
  my $self = shift;;


  # Grab the other arguments

  my($ref, $name, $indent) = @_;

  my $named = (defined($name) and $name ne '' ? 1 : 0);

  my $nl = "\n";

  my $is_root = $indent eq '' ? 1 : 0;   # Warning, dirty hack!
  if($self->{opt}->{noindent}) {
    $indent = '';
    $nl     = '';
  }


  # Convert to XML
  
  if(ref($ref)) {
    croak "circular data structures not supported"
      if(grep($_ == $ref, @{$self->{_ancestors}}));
    push @{$self->{_ancestors}}, $ref;
  }
  else {
    if($named) {
      return(join('',
              $indent, '<', $name, '>',
              ($self->{opt}->{noescape} ? $ref : $self->escape_value($ref)),
              '</', $name, ">", $nl
            ));
    }
    else {
      return("$ref$nl");
    }
  }


  # Unfold hash to array if possible

  if(UNIVERSAL::isa($ref, 'HASH')      # It is a hash
     and keys %$ref                    # and it's not empty
     and $self->{opt}->{keyattr}       # and folding is enabled
     and !$is_root                     # and its not the root element
  ) {
    $ref = $self->hash_to_array($name, $ref);
  }


  my @result = ();
  my($key, $value);


  # Handle hashrefs

  if(UNIVERSAL::isa($ref, 'HASH')) {

    # Reintermediate grouped values if applicable

    if($self->{opt}->{grouptags}) {
      $ref = $self->copy_hash($ref);
      while(my($key, $val) = each %$ref) {
        if($self->{opt}->{grouptags}->{$key}) {
          $ref->{$key} = { $self->{opt}->{grouptags}->{$key} => $val };
        }
      }
    }


    # Scan for namespace declaration attributes

    my $nsdecls = '';
    my $default_ns_uri;
    if($self->{nsup}) {
      $ref = $self->copy_hash($ref);
      $self->{nsup}->push_context();

      # Look for default namespace declaration first

      if(exists($ref->{xmlns})) {
        $self->{nsup}->declare_prefix('', $ref->{xmlns});
        $nsdecls .= qq( xmlns="$ref->{xmlns}"); 
        delete($ref->{xmlns});
      }
      $default_ns_uri = $self->{nsup}->get_uri('');


      # Then check all the other keys

      foreach my $qname (keys(%$ref)) {
        my($uri, $lname) = $self->{nsup}->parse_jclark_notation($qname);
        if($uri) {
          if($uri eq $xmlns_ns) {
            $self->{nsup}->declare_prefix($lname, $ref->{$qname});
            $nsdecls .= qq( xmlns:$lname="$ref->{$qname}"); 
            delete($ref->{$qname});
          }
        }
      }

      # Translate any remaining Clarkian names

      foreach my $qname (keys(%$ref)) {
        my($uri, $lname) = $self->{nsup}->parse_jclark_notation($qname);
        if($uri) {
          if($default_ns_uri  and  $uri eq $default_ns_uri) {
            $ref->{$lname} = $ref->{$qname};
            delete($ref->{$qname});
          }
          else {
            my $prefix = $self->{nsup}->get_prefix($uri);
            unless($prefix) {
              # $self->{nsup}->declare_prefix(undef, $uri);
              # $prefix = $self->{nsup}->get_prefix($uri);
              $prefix = $self->{ns_prefix}++;
              $self->{nsup}->declare_prefix($prefix, $uri);
              $nsdecls .= qq( xmlns:$prefix="$uri"); 
            }
            $ref->{"$prefix:$lname"} = $ref->{$qname};
            delete($ref->{$qname});
          }
        }
      }
    }


    my @nested = ();
    my $text_content = undef;
    if($named) {
      push @result, $indent, '<', $name, $nsdecls;
    }

    if(keys %$ref) {
      my $first_arg = 1;
      foreach my $key ($self->sorted_keys($name, $ref)) {
        my $value = $ref->{$key};
        next if(substr($key, 0, 1) eq '-');
        if(!defined($value)) {
          next if $self->{opt}->{suppressempty};
          unless(exists($self->{opt}->{suppressempty})
             and !defined($self->{opt}->{suppressempty})
          ) {
            carp 'Use of uninitialized value' if($^W);
          }
          if($key eq $self->{opt}->{contentkey}) {
            $text_content = '';
          }
          else {
            $value = exists($self->{opt}->{suppressempty}) ? {} : '';
          }
        }

        if(!ref($value)  
           and $self->{opt}->{valueattr}
           and $self->{opt}->{valueattr}->{$key}
        ) {
          $value = { $self->{opt}->{valueattr}->{$key} => $value };
        }

        if(ref($value)  or  $self->{opt}->{noattr}) {
          push @nested,
            $self->value_to_xml($value, $key, "$indent  ");
        }
        else {
          $value = $self->escape_value($value) unless($self->{opt}->{noescape});
          if($key eq $self->{opt}->{contentkey}) {
            $text_content = $value;
          }
          else {
            push @result, "\n$indent " . ' ' x length($name)
              if($self->{opt}->{attrindent}  and  !$first_arg);
            push @result, ' ', $key, '="', $value , '"';
            $first_arg = 0;
          }
        }
      }
    }
    else {
      $text_content = '';
    }

    if(@nested  or  defined($text_content)) {
      if($named) {
        push @result, ">";
        if(defined($text_content)) {
          push @result, $text_content;
          $nested[0] =~ s/^\s+// if(@nested);
        }
        else {
          push @result, $nl;
        }
        if(@nested) {
          push @result, @nested, $indent;
        }
        push @result, '</', $name, ">", $nl;
      }
      else {
        push @result, @nested;             # Special case if no root elements
      }
    }
    else {
      push @result, " />", $nl;
    }
    $self->{nsup}->pop_context() if($self->{nsup});
  }


  # Handle arrayrefs

  elsif(UNIVERSAL::isa($ref, 'ARRAY')) {
    foreach $value (@$ref) {
      next if !defined($value) and $self->{opt}->{suppressempty};
      if(!ref($value)) {
        push @result,
             $indent, '<', $name, '>',
             ($self->{opt}->{noescape} ? $value : $self->escape_value($value)),
             '</', $name, ">$nl";
      }
      elsif(UNIVERSAL::isa($value, 'HASH')) {
        push @result, $self->value_to_xml($value, $name, $indent);
      }
      else {
        push @result,
               $indent, '<', $name, ">$nl",
               $self->value_to_xml($value, 'anon', "$indent  "),
               $indent, '</', $name, ">$nl";
      }
    }
  }

  else {
    croak "Can't encode a value of type: " . ref($ref);
  }


  pop @{$self->{_ancestors}} if(ref($ref));

  return(join('', @result));
}



sub sorted_keys {
  my($self, $name, $ref) = @_;

  return keys %$ref if $self->{opt}->{nosort};

  my %hash = %$ref;
  my $keyattr = $self->{opt}->{keyattr};

  my @key;

  if(ref $keyattr eq 'HASH') {
    if(exists $keyattr->{$name} and exists $hash{$keyattr->{$name}->[0]}) {
      push @key, $keyattr->{$name}->[0];
      delete $hash{$keyattr->{$name}->[0]};
    }
  }
  elsif(ref $keyattr eq 'ARRAY') {
    foreach (@{$keyattr}) {
      if(exists $hash{$_}) {
        push @key, $_;
        delete $hash{$_};
        last;
      }
    }
  }

  return(@key, sort keys %hash);
}


sub escape_value {
  my($self, $data) = @_;

  return '' unless(defined($data));

  $data =~ s/&/&amp;/sg;
  $data =~ s/</&lt;/sg;
  $data =~ s/>/&gt;/sg;
  $data =~ s/"/&quot;/sg;

  my $level = $self->{opt}->{numericescape} or return $data;

  return $self->numeric_escape($data, $level);
}

sub numeric_escape {
  my($self, $data, $level) = @_;

  use utf8; # required for 5.6

  if($self->{opt}->{numericescape} eq '2') {
    $data =~ s/([^\x00-\x7F])/'&#' . ord($1) . ';'/gse;
  }
  else {
    $data =~ s/([^\x00-\xFF])/'&#' . ord($1) . ';'/gse;
  }

  return $data;
}



sub hash_to_array {
  my $self    = shift;
  my $parent  = shift;
  my $hashref = shift;

  my $arrayref = [];

  my($key, $value);

  my @keys = $self->{opt}->{nosort} ? keys %$hashref : sort keys %$hashref;
  foreach $key (@keys) {
    $value = $hashref->{$key};
    return($hashref) unless(UNIVERSAL::isa($value, 'HASH'));

    if(ref($self->{opt}->{keyattr}) eq 'HASH') {
      return($hashref) unless(defined($self->{opt}->{keyattr}->{$parent}));
      push @$arrayref, $self->copy_hash(
        $value, $self->{opt}->{keyattr}->{$parent}->[0] => $key
      );
    }
    else {
      push(@$arrayref, { $self->{opt}->{keyattr}->[0] => $key, %$value });
    }
  }

  return($arrayref);
}



sub copy_hash {
  my($self, $orig, @extra) = @_;

  return { @extra, %$orig };
}


sub start_document {
  my $self = shift;

  $self->handle_options('in') unless($self->{opt});

  $self->{lists} = [];
  $self->{curlist} = $self->{tree} = [];
}


sub start_element {
  my $self    = shift;
  my $element = shift;

  my $name = $element->{Name};
  if($self->{opt}->{nsexpand}) {
    $name = $element->{LocalName} || '';
    if($element->{NamespaceURI}) {
      $name = '{' . $element->{NamespaceURI} . '}' . $name;
    }
  }
  my $attributes = {};
  if($element->{Attributes}) {  # Might be undef
    foreach my $attr (values %{$element->{Attributes}}) {
      if($self->{opt}->{nsexpand}) {
        my $name = $attr->{LocalName} || '';
        if($attr->{NamespaceURI}) {
          $name = '{' . $attr->{NamespaceURI} . '}' . $name
        }
        $name = 'xmlns' if($name eq $bad_def_ns_jcn);
        $attributes->{$name} = $attr->{Value};
      }
      else {
        $attributes->{$attr->{Name}} = $attr->{Value};
      }
    }
  }
  my $newlist = [ $attributes ];
  push @{ $self->{lists} }, $self->{curlist};
  push @{ $self->{curlist} }, $name => $newlist;
  $self->{curlist} = $newlist;
}


sub characters {
  my $self  = shift;
  my $chars = shift;

  my $text  = $chars->{Data};
  my $clist = $self->{curlist};
  my $pos = $#$clist;
  
  if ($pos > 0 and $clist->[$pos - 1] eq '0') {
    $clist->[$pos] .= $text;
  }
  else {
    push @$clist, 0 => $text;
  }
}


sub end_element {
  my $self    = shift;

  $self->{curlist} = pop @{ $self->{lists} };
}


sub end_document {
  my $self = shift;

  delete($self->{curlist});
  delete($self->{lists});

  my $tree = $self->{tree};
  delete($self->{tree});


  # Return tree as-is to XMLin()

  return($tree) if($self->{nocollapse});


  # Or collapse it before returning it to SAX parser class
  
  if($self->{opt}->{keeproot}) {
    $tree = $self->collapse({}, @$tree);
  }
  else {
    $tree = $self->collapse(@{$tree->[1]});
  }

  if($self->{opt}->{datahandler}) {
    return($self->{opt}->{datahandler}->($self, $tree));
  }

  return($tree);
}

*xml_in  = \&XMLin;
*xml_out = \&XMLout;

1;

__END__



