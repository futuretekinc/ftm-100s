
package Image::ExifTool::XMP;

use strict;
use vars qw(%specialStruct $xlatNamespace);

use Image::ExifTool qw(:Utils);
use Image::ExifTool::XMP;

sub SerializeStruct($;$);
sub InflateStruct($;$);
sub DumpStruct($;$);
sub CheckStruct($$$);
sub AddNewStruct($$$$$$);
sub ConvertStruct($$$$;$);

sub SerializeStruct($;$)
{
    my ($obj, $ket) = @_;
    my ($key, $val, @vals, $rtnVal);

    if (ref $obj eq 'HASH') {
        foreach $key (sort keys %$obj) {
            push @vals, $key . '=' . SerializeStruct($$obj{$key}, '}');
        }
        $rtnVal = '{' . join(',', @vals) . '}';
    } elsif (ref $obj eq 'ARRAY') {
        foreach $val (@$obj) {
            push @vals, SerializeStruct($val, ']');
        }
        $rtnVal = '[' . join(',', @vals) . ']';
    } elsif (defined $obj) {
        $obj = $$obj if ref $obj eq 'SCALAR';
        # escape necessary characters in string (closing bracket plus "," and "|")
        my $pat = $ket ? "\\$ket|,|\\|" : ',|\\|';
        ($rtnVal = $obj) =~  s/($pat)/|$1/g;
        # also must escape opening bracket or whitespace at start of string
        $rtnVal =~ s/^([\s\[\{])/|$1/;
    } else {
        $rtnVal = '';   # allow undefined list items
    }
    return $rtnVal;
}

sub InflateStruct($;$)
{
    my ($obj, $delim) = @_;
    my ($val, $warn, $part);

    if ($$obj =~ s/^\s*\{//) {
        my %struct;
        while ($$obj =~ s/^\s*([-\w:]+#?)\s*=//s) {
            my $tag = $1;
            my ($v, $w) = InflateStruct($obj, '}');
            $warn = $w if $w and not $warn;
            return(undef, $warn) unless defined $v;
            $struct{$tag} = $v;
            # eat comma separator, or all done if there wasn't one
            last unless $$obj =~ s/^\s*,//s;
        }
        # eat closing brace and warn if we didn't find one
        unless ($$obj =~ s/^\s*\}//s or $warn) {
            if (length $$obj) {
                ($part = $$obj) =~ s/^\s*//s;
                $part =~ s/[\x0d\x0a].*//s;
                $part = substr($part,0,27) . '...' if length($part) > 30;
                $warn = "Invalid structure field at '$part'";
            } else {
                $warn = 'Missing closing brace for structure';
            }
        }
        $val = \%struct;
    } elsif ($$obj =~ s/^\s*\[//) {
        my @list;
        for (;;) {
            my ($v, $w) = InflateStruct($obj, ']');
            $warn = $w if $w and not $warn;
            return(undef, $warn) unless defined $v;
            push @list, $v;
            last unless $$obj =~ s/^\s*,//s;
        }
        # eat closing bracket and warn if we didn't find one
        $$obj =~ s/^\s*\]//s or $warn or $warn = 'Missing closing bracket for list';
        $val = \@list;
    } else {
        $$obj =~ s/^\s+//s; # remove leading whitespace
        # read scalar up to specified delimiter (or "," if not defined)
        $val = '';
        $delim = $delim ? "\\$delim|,|\\||\$" : ',|\\||$';
        for (;;) {
            $$obj =~ s/^(.*?)($delim)//s and $val .= $1;
            last unless $2;
            $2 eq '|' or $$obj = $2 . $$obj, last;
            $$obj =~ s/^(.)//s and $val .= $1;  # add escaped character
        }
    }
    return($val, $warn);
}

sub GetLangCode($)
{
    my $tag = shift;
    if ($tag =~ /^(\w+)[-_]([a-z]{2,3}|[xi])([-_][a-z\d]{2,8}([-_][a-z\d]{1,8})*)?$/i) {
        # normalize case of language codes
        my ($tg, $langCode) = ($1, lc($2));
        $langCode .= (length($3) == 3 ? uc($3) : lc($3)) if $3;
        $langCode =~ tr/_/-/;   # RFC 3066 specifies '-' as a separator
        $langCode = '' if lc($langCode) eq 'x-default';
        return($tg, $langCode);
    } else {
        return($tag, undef);
    }
}

sub DumpStruct($;$)
{
    local $_;
    my ($obj, $indent) = @_;

    $indent or $indent = '';
    if (ref $obj eq 'HASH') {
        print "{\n";
        foreach (sort keys %$obj) {
            print "$indent  $_ = ";
            DumpStruct($$obj{$_}, "$indent  ");
        }
        print $indent, "},\n";
    } elsif (ref $obj eq 'ARRAY') {
        print "[\n";
        foreach (@$obj) {
            print "$indent  ";
            DumpStruct($_, "$indent  ");
        }
        print $indent, "],\n",
    } else {
        print "\"$obj\",\n";
    }
}

sub CheckStruct($$$)
{
    my ($exifTool, $struct, $strTable) = @_;

    my $strName = $$strTable{STRUCT_NAME} || RegisterNamespace($strTable);
    ref $struct eq 'HASH' or return wantarray ? (undef, "Expecting $strName structure") : undef;

    my ($key, $err, $warn, %copy, $rtnVal, $val);
Key:
    foreach $key (keys %$struct) {
        my $tag = $key;
        # allow trailing '#' to disable print conversion on a per-field basis
        my ($type, $fieldInfo);
        $type = 'ValueConv' if $tag =~ s/#$//;
        $fieldInfo = $$strTable{$tag} unless $specialStruct{$tag};
        # fix case of field name if necessary
        unless ($fieldInfo) {
            # (sort in reverse to get lower case (not special) tags first)
            my ($fix) = reverse sort grep /^$tag$/i, keys %$strTable;
            $fieldInfo = $$strTable{$tag = $fix} if $fix and not $specialStruct{$fix};
        }
        until (ref $fieldInfo eq 'HASH') {
            # generate wildcard fields on the fly (ie. mwg-rs:Extensions)
            unless ($$strTable{NAMESPACE}) {
                my ($grp, $tg, $langCode);
                ($grp, $tg) = $tag =~ /^(.+):(.+)/ ? (lc $1, $2) : ('', $tag);
                undef $grp if $grp eq 'XMP'; # (a group of 'XMP' is implied)
                require Image::ExifTool::TagLookup;
                my @matches = Image::ExifTool::TagLookup::FindTagInfo($tg);
                # also look for lang-alt tags
                unless (@matches) {
                    ($tg, $langCode) = GetLangCode($tg);
                    @matches = Image::ExifTool::TagLookup::FindTagInfo($tg) if defined $langCode;
                }
                my ($tagInfo, $priority, $ti, $g1);
                # find best matching tag
                foreach $ti (@matches) {
                    my @grps = $exifTool->GetGroup($ti);
                    next unless $grps[0] eq 'XMP';
                    next if $grp and $grp ne lc $grps[1];
                    # must be lang-alt tag if we are writing an alternate language
                    next if defined $langCode and not ($$ti{Writable} and $$ti{Writable} eq 'lang-alt');
                    my $pri = $$ti{Priority} || 1;
                    $pri -= 10 if $$ti{Avoid};
                    next if defined $priority and $priority >= $pri;
                    $priority = $pri;
                    $tagInfo = $ti;
                    $g1 = $grps[1];
                }
                $tagInfo or $warn =  "'$tag' is not a writable XMP tag", next Key;
                GetPropertyPath($tagInfo);  # make sure property path is generated for this tag
                $tag = $$tagInfo{Name};
                $tag = "$g1:$tag" if $grp;
                $tag .= "-$langCode" if $langCode;
                $fieldInfo = $$strTable{$tag};
                # create new structure field if necessary
                $fieldInfo or $fieldInfo = $$strTable{$tag} = {
                    %$tagInfo, # (also copies the necessary TagID and PropertyPath)
                    Namespace => $$tagInfo{Table}{NAMESPACE},
                    LangCode  => $langCode,
                };
                # delete stuff we don't need (shouldn't cause harm, but better safe than sorry)
                # - need to keep StructType and Table in case we need to call AddStructType later
                delete $$fieldInfo{Description};
                delete $$fieldInfo{Groups};
                last; # write this dynamically-generated field
            }
            # generate lang-alt fields on the fly (ie. Iptc4xmpExt:AOTitle)
            my ($tg, $langCode) = GetLangCode($tag);
            if (defined $langCode) {
                $fieldInfo = $$strTable{$tg} unless $specialStruct{$tg};
                unless ($fieldInfo) {
                    my ($fix) = reverse sort grep /^$tg$/i, keys %$strTable;
                    $fieldInfo = $$strTable{$tg = $fix} if $fix and not $specialStruct{$fix};
                }
                if (ref $fieldInfo eq 'HASH' and $$fieldInfo{Writable} and
                    $$fieldInfo{Writable} eq 'lang-alt')
                {
                    my $srcInfo = $fieldInfo;
                    $tag = $tg . '-' . $langCode if $langCode;
                    $fieldInfo = $$strTable{$tag};
                    # create new structure field if necessary
                    $fieldInfo or $fieldInfo = $$strTable{$tag} = {
                        %$srcInfo,
                        TagID    => $tg,
                        LangCode => $langCode,
                    };
                    last; # write this lang-alt field
                }
            }
            $warn = "'$tag' is not a field of $strName";
            next Key;
        }
        if (ref $$struct{$key} eq 'HASH') {
            $$fieldInfo{Struct} or $warn = "$tag is not a structure in $strName", next Key;
            # recursively check this structure
            ($val, $err) = CheckStruct($exifTool, $$struct{$key}, $$fieldInfo{Struct});
            $err and $warn = $err, next Key;
            $copy{$tag} = $val;
        } elsif (ref $$struct{$key} eq 'ARRAY') {
            $$fieldInfo{List} or $warn = "$tag is not a list in $strName", next Key;
            # check all items in the list
            my ($item, @copy);
            my $i = 0;
            foreach $item (@{$$struct{$key}}) {
                if (not ref $item) {
                    $item = '' unless defined $item; # use empty string for missing items
                    $$fieldInfo{Struct} and $warn = "$tag items are not valid structures", next Key;
                    $exifTool->Sanitize(\$item);
                    ($copy[$i],$err) = $exifTool->ConvInv($item,$fieldInfo,$tag,$strName,$type);
                    $err and $warn = $err, next Key;
                    $err = CheckXMP($exifTool, $fieldInfo, \$copy[$i]);
                    $err and $warn = "$err in $strName $tag", next Key;
                } elsif (ref $item eq 'HASH') {
                    $$fieldInfo{Struct} or $warn = "$tag is not a structure in $strName", next Key;
                    ($copy[$i], $err) = CheckStruct($exifTool, $item, $$fieldInfo{Struct});
                    $err and $warn = $err, next Key;
                } else {
                    $warn = "Invalid value for $tag in $strName";
                    next Key;
                }
                ++$i;
            }
            $copy{$tag} = \@copy;
        } elsif ($$fieldInfo{Struct}) {
            $warn = "Improperly formed structure in $strName $tag";
        } else {
            $exifTool->Sanitize(\$$struct{$key});
            ($val,$err) = $exifTool->ConvInv($$struct{$key},$fieldInfo,$tag,$strName,$type);
            $err and $warn = $err, next Key;
            $err = CheckXMP($exifTool, $fieldInfo, \$val);
            $err and $warn = "$err in $strName $tag", next Key;
            # turn this into a list if necessary
            $copy{$tag} = $$fieldInfo{List} ? [ $val ] : $val;
        }
    }
    if (%copy) {
        $rtnVal = \%copy;
        undef $err;
        $$exifTool{CHECK_WARN} = $warn if $warn;
    } else {
        $err = $warn || 'Structure has no fields';
    }
    return wantarray ? ($rtnVal, $err) : $rtnVal;
}

sub DeleteStruct($$$$$)
{
    my ($exifTool, $capture, $pathPt, $nvHash, $changed) = @_;
    my ($deleted, $added, $p, $pp, $val, $delPath);
    my (@structPaths, @matchingPaths, @delPaths);

    # find all existing elements belonging to this structure
    ($pp = $$pathPt) =~ s/ \d+/ \\d\+/g;
    @structPaths = sort grep(/^$pp\//, keys %$capture);

    # delete only structures with matching fields if necessary
    if ($$nvHash{DelValue}) {
        if (@{$$nvHash{DelValue}}) {
            my $strTable = $$nvHash{TagInfo}{Struct};
            # all fields must match corresponding elements in the same
            # root structure for it to be deleted
            foreach $val (@{$$nvHash{DelValue}}) {
                next unless ref $val eq 'HASH';
                my (%cap, $p2, %match);
                next unless AddNewStruct(undef, undef, \%cap, $$pathPt, $val, $strTable);
                foreach $p (keys %cap) {
                    if ($p =~ / /) {
                        ($p2 = $p) =~ s/ \d+/ \\d\+/g;
                        @matchingPaths = sort grep(/^$p2$/, @structPaths);
                    } else {
                        push @matchingPaths, $p;
                    }
                    foreach $p2 (@matchingPaths) {
                        $p2 =~ /^($pp)/ or next;
                        # language attribute must also match if it exists
                        my $attr = $cap{$p}[1];
                        if ($$attr{'xml:lang'}) {
                            my $a2 = $$capture{$p2}[1];
                            next unless $$a2{'xml:lang'} and $$a2{'xml:lang'} eq $$attr{'xml:lang'};
                        }
                        if ($$capture{$p2}[0] eq $cap{$p}[0]) {
                            # ($1 contains root path for this structure)
                            $match{$1} = ($match{$1} || 0) + 1;
                        }
                    }
                }
                my $num = scalar(keys %cap);
                foreach $p (keys %match) {
                    # do nothing unless all fields matched the same structure
                    next unless $match{$p} == $num;
                    # delete all elements of this structure
                    foreach $p2 (@structPaths) {
                        push @delPaths, $p2 if $p2 =~ /^$p/;
                    }
                    # remember path of first deleted structure
                    $delPath = $p if not $delPath or $delPath gt $p;
                }
            }
        } # (else don't delete anything)
    } elsif (@structPaths) {
        @delPaths = @structPaths;   # delete all
        $structPaths[0] =~ /^($pp)/;
        $delPath = $1;
    }
    if (@delPaths) {
        my $verbose = $exifTool->Options('Verbose');
        @delPaths = sort @delPaths if $verbose > 1;
        foreach $p (@delPaths) {
            $exifTool->VerboseValue("- XMP-$p", $$capture{$p}[0]) if $verbose > 1;
            delete $$capture{$p};
            $deleted = 1;
            ++$$changed;
        }
        $delPath or warn("Internal error 1 in DeleteStruct\n"), return(undef,undef);
        $$pathPt = $delPath;    # return path of first element deleted
    } else {
        my $tagInfo = $$nvHash{TagInfo};
        if ($$tagInfo{List}) {
            # NOTE: we don't yet properly handle lang-alt elements!!!!
            if (@structPaths) {
                $structPaths[-1] =~ /^($pp)/ or warn("Internal error 2 in DeleteStruct\n"), return(undef,undef);
                my $path = $1;
                # (match last index to put in same lang-alt list for Bag of lang-alt items)
                $path =~ m/.* (\d+)/g or warn("Internal error 3 in DeleteStruct\n"), return(undef,undef);
                $added = $1;
                # add after last item in list
                my $len = length $added;
                my $pos = pos($path) - $len;
                my $nxt = substr($added, 1) + 1;
                substr($path, $pos, $len) = length($nxt) . $nxt;
                $$pathPt = $path;
            } else {
                $added = '10';
            }
        }
    }
    return($deleted, $added);
}

sub AddNewTag($$$$$$)
{
    my ($exifTool, $tagInfo, $capture, $path, $valPtr, $langIdx) = @_;
    my $val = EscapeXML($$valPtr);
    my %attrs;
    # support writing RDF "resource" values
    if ($$tagInfo{Resource}) {
        $attrs{'rdf:resource'} = $val;
        $val = '';
    }
    if ($$tagInfo{Writable} and $$tagInfo{Writable} eq 'lang-alt') {
        # write the lang-alt tag
        my $langCode = $$tagInfo{LangCode};
        # add indexed lang-alt list properties
        my $i = $$langIdx{$path} || 0;
        $$langIdx{$path} = $i + 1; # save next list index
        if ($i) {
            my $idx = length($i) . $i;
            $path =~ s/(.*) \d+/$1 $idx/;   # set list index
        }
        $attrs{'xml:lang'} = $langCode || 'x-default';
    }
    $$capture{$path} = [ $val, \%attrs ];
    # print verbose message
    if ($exifTool and $exifTool->Options('Verbose') > 1) {
        $exifTool->VerboseValue("+ XMP-$path", $val);
    }
}

sub AddNewStruct($$$$$$)
{
    my ($exifTool, $tagInfo, $capture, $basePath, $struct, $strTable) = @_;
    my $verbose = $exifTool ? $exifTool->Options('Verbose') : 0;
    my ($tag, %langIdx);

    my $ns = $$strTable{NAMESPACE} || '';
    my $changed = 0;

    foreach $tag (sort keys %$struct) {
        my $fieldInfo = $$strTable{$tag} or next;
        my $val = $$struct{$tag};
        my $propPath = $$fieldInfo{PropertyPath};
        unless ($propPath) {
            $propPath = ($$fieldInfo{Namespace} || $ns) . ':' . ($$fieldInfo{TagID} || $tag);
            if ($$fieldInfo{List}) {
                $propPath .= "/rdf:$$fieldInfo{List}/rdf:li 10";
            }
            if ($$fieldInfo{Writable} and $$fieldInfo{Writable} eq 'lang-alt') {
                $propPath .= "/rdf:Alt/rdf:li 10";
            }
            $$fieldInfo{PropertyPath} = $propPath;  # save for next time
        }
        my $path = $basePath . '/' . ConformPathToNamespace($exifTool, $propPath);
        my $addedTag;
        if (ref $val eq 'HASH') {
            my $subStruct = $$fieldInfo{Struct} or next;
            $changed += AddNewStruct($exifTool, $tagInfo, $capture, $path, $val, $subStruct);
        } elsif (ref $val eq 'ARRAY') {
            next unless $$fieldInfo{List};
            my $i = 0;
            my ($item, $p);
            # loop through all list items (note: can't yet write multi-dimensional lists)
            foreach $item (@{$val}) {
                if ($i) {
                    # update first index in field property (may be list of lang-alt lists)
                    $p = ConformPathToNamespace($exifTool, $propPath);
                    my $idx = length($i) . $i;
                    $p =~ s/ \d+/ $idx/;
                    $p = "$basePath/$p";
                } else {
                    $p = $path;
                }
                if (ref $item eq 'HASH') {
                    my $subStruct = $$fieldInfo{Struct} or next;
                    AddNewStruct($exifTool, $tagInfo, $capture, $p, $item, $subStruct) or next;
                } elsif (length $item) { # don't write empty items in list
                    AddNewTag($exifTool, $fieldInfo, $capture, $p, \$item, \%langIdx);
                    $addedTag = 1;
                }
                ++$changed;
                ++$i;
            }
        } else {
            AddNewTag($exifTool, $fieldInfo, $capture, $path, \$val, \%langIdx);
            $addedTag = 1;
            ++$changed;
        }
        # this is tricky, but we must add the rdf:type for contained structures
        # in the case that a whole hierarchy was added at once by writing a
        # flattened tag inside a variable-namespace structure
        if ($addedTag and $$fieldInfo{StructType} and $$fieldInfo{Table}) {
            AddStructType($exifTool, $$fieldInfo{Table}, $capture, $propPath, $basePath);
        }
    }
    # add 'rdf:type' property if necessary
    if ($$strTable{TYPE} and $changed) {
        my $path = $basePath . '/' . ConformPathToNamespace($exifTool, "rdf:type");
        unless ($$capture{$path}) {
            $$capture{$path} = [ '', { 'rdf:resource' => $$strTable{TYPE} } ];
            $exifTool->VerboseValue("+ XMP-$path", $$strTable{TYPE}) if $verbose > 1;
        }
    }
    return $changed;
}

sub ConvertStruct($$$$;$)
{
    my ($exifTool, $tagInfo, $value, $type, $parentID) = @_;
    if (ref $value eq 'HASH') {
        my (%struct, $key);
        my $table = $$tagInfo{Table};
        $parentID = $$tagInfo{TagID} unless $parentID;
        foreach $key (keys %$value) {
            my $tagID = $parentID . ucfirst($key);
            my $flatInfo = $$table{$tagID};
            unless ($flatInfo) {
                # handle variable-namespace structures
                if ($key =~ /^XMP-(.*?:)(.*)/) {
                    $tagID = $1 . $parentID . ucfirst($2);
                    $flatInfo = $$table{$tagID};
                }
                $flatInfo or $flatInfo = $tagInfo;
            }
            my $v = $$value{$key};
            if (ref $v) {
                $v = ConvertStruct($exifTool, $flatInfo, $v, $type, $tagID);
            } else {
                $v = $exifTool->GetValue($flatInfo, $type, $v);
            }
            $struct{$key} = $v if defined $v;  # save the converted value
        }
        return \%struct;
    } elsif (ref $value eq 'ARRAY') {
        my (@list, $val);
        foreach $val (@$value) {    
            my $v = ConvertStruct($exifTool, $tagInfo, $val, $type, $parentID);
            push @list, $v if defined $v;
        }
        return \@list;
    } else {
        return $exifTool->GetValue($tagInfo, $type, $value);
    }
}

sub RestoreStruct($)
{
    local $_;
    my $exifTool = shift;
    my ($key, %structs, %var, %lists, $si, %listKeys);
    my $ex = $$exifTool{TAG_EXTRA};
    foreach $key (keys %{$$exifTool{TAG_INFO}}) {
        $$ex{$key} or next;
        my ($err, $i);
        my $structProps = $$ex{$key}{Struct} or next;
        my $tagInfo = $$exifTool{TAG_INFO}{$key};   # tagInfo for flattened tag
        my $table = $$tagInfo{Table};
        my $prop = shift @$structProps;
        my $tag = $$prop[0];
        # get reference to structure tag (or normal list tag if not a structure)
        my $strInfo = @$structProps ? $$table{$tag} : $tagInfo;
        if ($strInfo) {
            ref $strInfo eq 'HASH' or next; # (just to be safe)
            if (@$structProps and not $$strInfo{Struct}) {
                # this could happen for invalid XMP containing mixed lists
                # (or for something like this -- what should we do here?:
                # <meta:user-defined meta:name="License">test</meta:user-defined>)
                $exifTool->Warn("$$strInfo{Name} is not a structure!");
                next;
            }
        } else {
            # create new entry in tag table for this structure
            my $g1 = $$table{GROUPS}{0} || 'XMP';
            my $name = $tag;
            if ($tag =~ /(.+):(.+)/) {
                my $ns;
                ($ns, $name) = ($1, $2);
                $ns = $$xlatNamespace{$ns} if $$xlatNamespace{$ns};
                $g1 .= "-$ns";
            }
            $strInfo = {
                Name => ucfirst $name,
                Groups => { 1 => $g1 },
                Struct => 'Unknown',
            };
            # add Struct entry if this is a structure
            if (@$structProps) {
                # this is a structure
                $$strInfo{Struct} = { STRUCT_NAME => 'Unknown' } if @$structProps;
            } elsif ($$tagInfo{LangCode}) {
                # this is lang-alt list
                $tag = $tag . '-' . $$tagInfo{LangCode};
                $$strInfo{LangCode} = $$tagInfo{LangCode};
            }
            Image::ExifTool::AddTagToTable($table, $tag, $strInfo);
        }
        # use strInfo ref for base key to avoid collisions
        $tag = $strInfo;
        my $struct = \%structs;
        my $oldStruct = $structs{$strInfo};
        # (fyi: 'lang-alt' Writable type will be valid even if tag is not pre-defined)
        my $writable = $$tagInfo{Writable} || '';
        # walk through the stored structure property information
        # to rebuild this structure
        for (;;) {
            my $index = $$prop[1];
            if ($index and not @$structProps) {
                # ignore this list if it is a simple lang-alt tag
                if ($writable eq 'lang-alt') {
                    pop @$prop; # remove lang-alt index
                    undef $index if @$prop < 2;
                }
                # add language code if necessary
                if ($$tagInfo{LangCode} and not ref $tag) {
                    $tag = $tag . '-' . $$tagInfo{LangCode};
                }
            }
            my $nextStruct = $$struct{$tag};
            if (defined $index) {
                # the field is a list
                $index = substr $index, 1;  # remove digit count
                if ($nextStruct) {
                    ref $nextStruct eq 'ARRAY' or $err = 2, last;
                    $struct = $nextStruct;
                } else {
                    $struct = $$struct{$tag} = [ ];
                }
                $nextStruct = $$struct[$index];
                # descend into multi-dimensional lists
                for ($i=2; $$prop[$i]; ++$i) {
                    if ($nextStruct) {
                        ref $nextStruct eq 'ARRAY' or last;
                        $struct = $nextStruct;
                    } else {
                        $lists{$struct} = $struct;
                        $struct = $$struct[$index] = [ ];
                    }
                    $nextStruct = $$struct[$index];
                    $index = substr $$prop[$i], 1;
                }
                if (ref $nextStruct eq 'HASH') {
                    $struct = $nextStruct;  # continue building sub-structure
                } elsif (@$structProps) {
                    $lists{$struct} = $struct;
                    $struct = $$struct[$index] = { };
                } else {
                    $lists{$struct} = $struct;
                    $$struct[$index] = $$exifTool{VALUE}{$key};
                    last;
                }
            } else {
                if ($nextStruct) {
                    ref $nextStruct eq 'HASH' or $err = 3, last;
                    $struct = $nextStruct;
                } elsif (@$structProps) {
                    $struct = $$struct{$tag} = { };
                } else {
                    $$struct{$tag} = $$exifTool{VALUE}{$key};
                    last;
                }
            }
            $prop = shift @$structProps or last;
            $tag = $$prop[0];
            if ($tag =~ /(.+):(.+)/) {
                # tag in variable-namespace tables will have a leading
                # XMP namespace on the tag name.  In this case, add
                # the corresponding group1 name to the tag ID.
                my ($ns, $name) = ($1, $2);
                $ns = $$xlatNamespace{$ns} if $$xlatNamespace{$ns};
                $tag = "XMP-$ns:" . ucfirst $name;
            } else {
                $tag = ucfirst $tag;
            }
        }
        if ($err) {
            # this may happen if we have a structural error in the XMP
            # (like an improperly contained list for example)
            $exifTool->Warn("Error $err placing $$tagInfo{Name} in structure", 1);
            delete $structs{$strInfo} unless $oldStruct;
        } elsif ($tagInfo eq $strInfo) {
            # just a regular list tag
            if ($oldStruct) {
                # keep tag with lowest numbered key (well, not exactly, since
                # "Tag (10)" is lt "Tag (2)", but at least "Tag" is lt
                # everything else, and this is really what we care about)
                my $k = $listKeys{$oldStruct};
                $k lt $key and $exifTool->DeleteTag($key), next;
                $exifTool->DeleteTag($k);   # remove tag with greater copy number
            }
            # replace existing value with new list
            $$exifTool{VALUE}{$key} = $structs{$strInfo};
            $listKeys{$structs{$strInfo}} = $key;   # save key for this list tag
        } else {
            # save strInfo ref and file order
            $var{$strInfo} = [ $strInfo, $$exifTool{FILE_ORDER}{$key} ];
            $exifTool->DeleteTag($key);
        }
    }
    # fill in undefined items in lists.  In theory, undefined list items should
    # be fine, but in practice the calling code may not check for this (and
    # historically this wasn't necessary, so do this for backward compatibility)
    foreach $si (keys %lists) {
        defined $_ or $_ = '' foreach @{$lists{$si}};
    }
    # save new structure tags
    foreach $si (keys %structs) {
        next unless $var{$si};  # already handled regular lists
        $key = $exifTool->FoundTag($var{$si}[0], '');
        $$exifTool{VALUE}{$key} = $structs{$si};
        $$exifTool{FILE_ORDER}{$key} = $var{$si}[1];
    }
}


1;  #end

__END__

