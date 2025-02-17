
package Template::Grammar;

use strict;
use warnings;

our $VERSION  = 2.25;

my (@RESERVED, %CMPOP, $LEXTABLE, $RULES, $STATES);
my ($factory, $rawstart);




@RESERVED = qw( 
	GET CALL SET DEFAULT INSERT INCLUDE PROCESS WRAPPER BLOCK END
	USE PLUGIN FILTER MACRO PERL RAWPERL TO STEP AND OR NOT DIV MOD
	IF UNLESS ELSE ELSIF FOR NEXT WHILE SWITCH CASE META IN
	TRY THROW CATCH FINAL LAST RETURN STOP CLEAR VIEW DEBUG
    );



%CMPOP = qw( 
    != ne
    == eq
    <  <
    >  >
    >= >=
    <= <=
);



$LEXTABLE = {
    'FOREACH' => 'FOR',
    'BREAK'   => 'LAST',
    '&&'      => 'AND',
    '||'      => 'OR',
    '!'       => 'NOT',
    '|'	      => 'FILTER',
    '.'       => 'DOT',
    '_'       => 'CAT',
    '..'      => 'TO',
    '='       => 'ASSIGN',
    '=>'      => 'ASSIGN',
    ','       => 'COMMA',
    '\\'      => 'REF',
    'and'     => 'AND',		# explicitly specified so that qw( and or
    'or'      => 'OR',		# not ) can always be used in lower case, 
    'not'     => 'NOT',		# regardless of ANYCASE flag
    'mod'     => 'MOD',
    'div'     => 'DIV',
};

{ 
    my @tokens = qw< ( ) [ ] { } ${ $ + / ; : ? >;
    my @cmpop  = keys %CMPOP;
    my @binop  = qw( - * % );              # '+' and '/' above, in @tokens

    # fill lexer table, slice by slice, with reserved words and operators
    @$LEXTABLE{ @RESERVED, @cmpop, @binop, @tokens } 
	= ( @RESERVED, ('CMPOP') x @cmpop, ('BINOP') x @binop, @tokens );
}



sub new {
    my $class = shift;
    bless {
	LEXTABLE => $LEXTABLE,
	STATES   => $STATES,
	RULES    => $RULES,
    }, $class;
}

sub install_factory {
    my ($self, $new_factory) = @_;
    $factory = $new_factory;
}



$STATES = [
	{#State 0
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'loop' => 4,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'atomdir' => 12,
			'anonblock' => 50,
			'template' => 52,
			'defblockname' => 14,
			'ident' => 16,
			'assign' => 19,
			'macro' => 20,
			'lterm' => 56,
			'node' => 23,
			'term' => 58,
			'rawperl' => 59,
			'expr' => 62,
			'use' => 63,
			'defblock' => 66,
			'filter' => 29,
			'sterm' => 68,
			'perl' => 31,
			'chunks' => 33,
			'setlist' => 70,
			'try' => 35,
			'switch' => 34,
			'directive' => 71,
			'block' => 72,
			'condition' => 73
		}
	},
	{#State 1
		ACTIONS => {
			"\$" => 43,
			'LITERAL' => 75,
			'IDENT' => 2,
			"\${" => 37
		},
		GOTOS => {
			'setlist' => 76,
			'item' => 39,
			'assign' => 19,
			'node' => 23,
			'ident' => 74
		}
	},
	{#State 2
		DEFAULT => -130
	},
	{#State 3
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 79,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 4
		DEFAULT => -23
	},
	{#State 5
		ACTIONS => {
			";" => 80
		}
	},
	{#State 6
		DEFAULT => -37
	},
	{#State 7
		DEFAULT => -14
	},
	{#State 8
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 90,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 9
		ACTIONS => {
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"]" => 94,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 96,
			'item' => 39,
			'range' => 93,
			'node' => 23,
			'ident' => 77,
			'term' => 95,
			'lterm' => 56,
			'list' => 92
		}
	},
	{#State 10
		ACTIONS => {
			";" => 97
		}
	},
	{#State 11
		DEFAULT => -5
	},
	{#State 12
		ACTIONS => {
			";" => -20
		},
		DEFAULT => -27
	},
	{#State 13
		DEFAULT => -78,
		GOTOS => {
			'@5-1' => 98
		}
	},
	{#State 14
		ACTIONS => {
			'IDENT' => 99
		},
		DEFAULT => -87,
		GOTOS => {
			'blockargs' => 102,
			'metadata' => 101,
			'meta' => 100
		}
	},
	{#State 15
		ACTIONS => {
			'IDENT' => 99
		},
		GOTOS => {
			'metadata' => 103,
			'meta' => 100
		}
	},
	{#State 16
		ACTIONS => {
			'DOT' => 104,
			'ASSIGN' => 105
		},
		DEFAULT => -109
	},
	{#State 17
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 106,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 18
		ACTIONS => {
			'IDENT' => 107
		}
	},
	{#State 19
		DEFAULT => -149
	},
	{#State 20
		DEFAULT => -12
	},
	{#State 21
		ACTIONS => {
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 108,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 68,
			'item' => 39,
			'loopvar' => 110,
			'node' => 23,
			'ident' => 77,
			'term' => 109,
			'lterm' => 56
		}
	},
	{#State 22
		DEFAULT => -40
	},
	{#State 23
		DEFAULT => -127
	},
	{#State 24
		DEFAULT => -6
	},
	{#State 25
		ACTIONS => {
			"\"" => 117,
			"\$" => 114,
			'LITERAL' => 116,
			'FILENAME' => 83,
			'IDENT' => 111,
			'NUMBER' => 84,
			"\${" => 37
		},
		GOTOS => {
			'names' => 91,
			'lvalue' => 112,
			'item' => 113,
			'name' => 82,
			'filepart' => 87,
			'filename' => 85,
			'nameargs' => 118,
			'lnameargs' => 115
		}
	},
	{#State 26
		DEFAULT => -113
	},
	{#State 27
		ACTIONS => {
			"\$" => 43,
			'IDENT' => 2,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'ident' => 119
		}
	},
	{#State 28
		ACTIONS => {
			'LITERAL' => 124,
			'FILENAME' => 83,
			'IDENT' => 120,
			'NUMBER' => 84
		},
		DEFAULT => -87,
		GOTOS => {
			'blockargs' => 123,
			'filepart' => 87,
			'filename' => 122,
			'blockname' => 121,
			'metadata' => 101,
			'meta' => 100
		}
	},
	{#State 29
		DEFAULT => -43
	},
	{#State 30
		ACTIONS => {
			"\$" => 43,
			'LITERAL' => 129,
			'IDENT' => 2,
			"\${" => 37
		},
		DEFAULT => -119,
		GOTOS => {
			'params' => 128,
			'hash' => 125,
			'item' => 126,
			'param' => 127
		}
	},
	{#State 31
		DEFAULT => -25
	},
	{#State 32
		ACTIONS => {
			"\"" => 117,
			"\$" => 114,
			'LITERAL' => 116,
			'FILENAME' => 83,
			'IDENT' => 111,
			'NUMBER' => 84,
			"\${" => 37
		},
		GOTOS => {
			'names' => 91,
			'lvalue' => 112,
			'item' => 113,
			'name' => 82,
			'filepart' => 87,
			'filename' => 85,
			'nameargs' => 118,
			'lnameargs' => 130
		}
	},
	{#State 33
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -2,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 131,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 34
		DEFAULT => -22
	},
	{#State 35
		DEFAULT => -24
	},
	{#State 36
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 132,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 37
		ACTIONS => {
			"\"" => 60,
			"\$" => 43,
			'LITERAL' => 78,
			'IDENT' => 2,
			'REF' => 27,
			'NUMBER' => 26,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 133,
			'item' => 39,
			'node' => 23,
			'ident' => 77
		}
	},
	{#State 38
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 134,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 39
		ACTIONS => {
			"(" => 135
		},
		DEFAULT => -128
	},
	{#State 40
		ACTIONS => {
			";" => 136
		}
	},
	{#State 41
		DEFAULT => -38
	},
	{#State 42
		DEFAULT => -11
	},
	{#State 43
		ACTIONS => {
			'IDENT' => 137
		}
	},
	{#State 44
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 138,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 45
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 139,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 46
		DEFAULT => -42
	},
	{#State 47
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 140,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 48
		ACTIONS => {
			'IF' => 144,
			'FILTER' => 143,
			'FOR' => 142,
			'WHILE' => 146,
			'WRAPPER' => 145,
			'UNLESS' => 141
		}
	},
	{#State 49
		DEFAULT => -39
	},
	{#State 50
		DEFAULT => -10
	},
	{#State 51
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 147,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 52
		ACTIONS => {
			'' => 148
		}
	},
	{#State 53
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 57,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 151,
			'sterm' => 68,
			'item' => 39,
			'assign' => 150,
			'node' => 23,
			'ident' => 149,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 54
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 152,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 55
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 153,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 56
		DEFAULT => -103
	},
	{#State 57
		ACTIONS => {
			'ASSIGN' => 154
		},
		DEFAULT => -112
	},
	{#State 58
		DEFAULT => -146
	},
	{#State 59
		DEFAULT => -15
	},
	{#State 60
		DEFAULT => -176,
		GOTOS => {
			'quoted' => 155
		}
	},
	{#State 61
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 156,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 62
		ACTIONS => {
			";" => -16,
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -26
	},
	{#State 63
		DEFAULT => -13
	},
	{#State 64
		DEFAULT => -36
	},
	{#State 65
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 167,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 66
		DEFAULT => -9
	},
	{#State 67
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 168,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 68
		DEFAULT => -104
	},
	{#State 69
		ACTIONS => {
			"\$" => 43,
			'LITERAL' => 75,
			'IDENT' => 2,
			"\${" => 37
		},
		GOTOS => {
			'setlist' => 169,
			'item' => 39,
			'assign' => 19,
			'node' => 23,
			'ident' => 74
		}
	},
	{#State 70
		ACTIONS => {
			"\$" => 43,
			'COMMA' => 171,
			'LITERAL' => 75,
			'IDENT' => 2,
			"\${" => 37
		},
		DEFAULT => -19,
		GOTOS => {
			'item' => 39,
			'assign' => 170,
			'node' => 23,
			'ident' => 74
		}
	},
	{#State 71
		DEFAULT => -8
	},
	{#State 72
		DEFAULT => -1
	},
	{#State 73
		DEFAULT => -21
	},
	{#State 74
		ACTIONS => {
			'ASSIGN' => 172,
			'DOT' => 104
		}
	},
	{#State 75
		ACTIONS => {
			'ASSIGN' => 154
		}
	},
	{#State 76
		ACTIONS => {
			'COMMA' => 171,
			'LITERAL' => 75,
			'IDENT' => 2,
			"\$" => 43,
			"\${" => 37
		},
		DEFAULT => -30,
		GOTOS => {
			'item' => 39,
			'assign' => 170,
			'node' => 23,
			'ident' => 74
		}
	},
	{#State 77
		ACTIONS => {
			'DOT' => 104
		},
		DEFAULT => -109
	},
	{#State 78
		DEFAULT => -112
	},
	{#State 79
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			";" => 173,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		}
	},
	{#State 80
		DEFAULT => -7
	},
	{#State 81
		DEFAULT => -173
	},
	{#State 82
		DEFAULT => -166
	},
	{#State 83
		DEFAULT => -172
	},
	{#State 84
		DEFAULT => -174
	},
	{#State 85
		ACTIONS => {
			'DOT' => 174
		},
		DEFAULT => -168
	},
	{#State 86
		ACTIONS => {
			"\$" => 43,
			'IDENT' => 2,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'ident' => 175
		}
	},
	{#State 87
		DEFAULT => -171
	},
	{#State 88
		DEFAULT => -169
	},
	{#State 89
		DEFAULT => -176,
		GOTOS => {
			'quoted' => 176
		}
	},
	{#State 90
		DEFAULT => -35
	},
	{#State 91
		ACTIONS => {
			"+" => 177,
			"(" => 178
		},
		DEFAULT => -156,
		GOTOS => {
			'args' => 179
		}
	},
	{#State 92
		ACTIONS => {
			"{" => 30,
			'COMMA' => 182,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"]" => 180,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 181,
			'lterm' => 56
		}
	},
	{#State 93
		ACTIONS => {
			"]" => 183
		}
	},
	{#State 94
		DEFAULT => -107
	},
	{#State 95
		DEFAULT => -116
	},
	{#State 96
		ACTIONS => {
			'TO' => 184
		},
		DEFAULT => -104
	},
	{#State 97
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 185,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 98
		ACTIONS => {
			";" => 186
		}
	},
	{#State 99
		ACTIONS => {
			'ASSIGN' => 187
		}
	},
	{#State 100
		DEFAULT => -99
	},
	{#State 101
		ACTIONS => {
			'COMMA' => 189,
			'IDENT' => 99
		},
		DEFAULT => -86,
		GOTOS => {
			'meta' => 188
		}
	},
	{#State 102
		ACTIONS => {
			";" => 190
		}
	},
	{#State 103
		ACTIONS => {
			'COMMA' => 189,
			'IDENT' => 99
		},
		DEFAULT => -17,
		GOTOS => {
			'meta' => 188
		}
	},
	{#State 104
		ACTIONS => {
			"\$" => 43,
			'IDENT' => 2,
			'NUMBER' => 192,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 191
		}
	},
	{#State 105
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'WRAPPER' => 55,
			'FOR' => 21,
			'NEXT' => 22,
			'LITERAL' => 57,
			"\"" => 60,
			'PROCESS' => 61,
			'FILTER' => 25,
			'RETURN' => 64,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 193,
			'DEFAULT' => 69,
			"{" => 30,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'term' => 58,
			'loop' => 4,
			'expr' => 195,
			'wrapper' => 46,
			'atomexpr' => 48,
			'atomdir' => 12,
			'mdir' => 194,
			'filter' => 29,
			'sterm' => 68,
			'ident' => 149,
			'perl' => 31,
			'setlist' => 70,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'directive' => 196,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 106
		DEFAULT => -33
	},
	{#State 107
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'INCLUDE' => 17,
			"(" => 198,
			'SWITCH' => 54,
			'WRAPPER' => 55,
			'FOR' => 21,
			'NEXT' => 22,
			'LITERAL' => 57,
			"\"" => 60,
			'PROCESS' => 61,
			'FILTER' => 25,
			'RETURN' => 64,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 193,
			'DEFAULT' => 69,
			"{" => 30,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'term' => 58,
			'loop' => 4,
			'expr' => 199,
			'wrapper' => 46,
			'atomexpr' => 48,
			'atomdir' => 12,
			'mdir' => 197,
			'filter' => 29,
			'sterm' => 68,
			'ident' => 149,
			'perl' => 31,
			'setlist' => 70,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'directive' => 196,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 108
		ACTIONS => {
			'IN' => 201,
			'ASSIGN' => 200
		},
		DEFAULT => -130
	},
	{#State 109
		DEFAULT => -156,
		GOTOS => {
			'args' => 202
		}
	},
	{#State 110
		ACTIONS => {
			";" => 203
		}
	},
	{#State 111
		ACTIONS => {
			'ASSIGN' => -130
		},
		DEFAULT => -173
	},
	{#State 112
		ACTIONS => {
			'ASSIGN' => 204
		}
	},
	{#State 113
		DEFAULT => -159
	},
	{#State 114
		ACTIONS => {
			"\$" => 43,
			'IDENT' => 205,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'ident' => 175
		}
	},
	{#State 115
		ACTIONS => {
			";" => 206
		}
	},
	{#State 116
		ACTIONS => {
			'ASSIGN' => -161
		},
		DEFAULT => -169
	},
	{#State 117
		DEFAULT => -176,
		GOTOS => {
			'quoted' => 207
		}
	},
	{#State 118
		DEFAULT => -158
	},
	{#State 119
		ACTIONS => {
			'DOT' => 104
		},
		DEFAULT => -110
	},
	{#State 120
		ACTIONS => {
			'ASSIGN' => 187
		},
		DEFAULT => -173
	},
	{#State 121
		DEFAULT => -83
	},
	{#State 122
		ACTIONS => {
			'DOT' => 174
		},
		DEFAULT => -84
	},
	{#State 123
		ACTIONS => {
			";" => 208
		}
	},
	{#State 124
		DEFAULT => -85
	},
	{#State 125
		ACTIONS => {
			"}" => 209
		}
	},
	{#State 126
		ACTIONS => {
			'ASSIGN' => 210
		}
	},
	{#State 127
		DEFAULT => -122
	},
	{#State 128
		ACTIONS => {
			"\$" => 43,
			'COMMA' => 212,
			'LITERAL' => 129,
			'IDENT' => 2,
			"\${" => 37
		},
		DEFAULT => -118,
		GOTOS => {
			'item' => 126,
			'param' => 211
		}
	},
	{#State 129
		ACTIONS => {
			'ASSIGN' => 213
		}
	},
	{#State 130
		DEFAULT => -73
	},
	{#State 131
		DEFAULT => -4
	},
	{#State 132
		ACTIONS => {
			";" => 214
		}
	},
	{#State 133
		ACTIONS => {
			"}" => 215
		}
	},
	{#State 134
		ACTIONS => {
			'DIV' => 159,
			'BINOP' => 161,
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -142
	},
	{#State 135
		DEFAULT => -156,
		GOTOS => {
			'args' => 216
		}
	},
	{#State 136
		DEFAULT => -76,
		GOTOS => {
			'@4-2' => 217
		}
	},
	{#State 137
		DEFAULT => -132
	},
	{#State 138
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			";" => 218,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		}
	},
	{#State 139
		ACTIONS => {
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -29
	},
	{#State 140
		ACTIONS => {
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -28
	},
	{#State 141
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 219,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 142
		ACTIONS => {
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 108,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 68,
			'item' => 39,
			'loopvar' => 220,
			'node' => 23,
			'ident' => 77,
			'term' => 109,
			'lterm' => 56
		}
	},
	{#State 143
		ACTIONS => {
			"\"" => 117,
			"\$" => 114,
			'LITERAL' => 116,
			'FILENAME' => 83,
			'IDENT' => 111,
			'NUMBER' => 84,
			"\${" => 37
		},
		GOTOS => {
			'names' => 91,
			'lvalue' => 112,
			'item' => 113,
			'name' => 82,
			'filepart' => 87,
			'filename' => 85,
			'nameargs' => 118,
			'lnameargs' => 221
		}
	},
	{#State 144
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 222,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 145
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 223,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 146
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 224,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 147
		DEFAULT => -41
	},
	{#State 148
		DEFAULT => 0
	},
	{#State 149
		ACTIONS => {
			'DOT' => 104,
			'ASSIGN' => 172
		},
		DEFAULT => -109
	},
	{#State 150
		ACTIONS => {
			")" => 225
		}
	},
	{#State 151
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			")" => 226,
			'OR' => 162
		}
	},
	{#State 152
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			";" => 227,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		}
	},
	{#State 153
		ACTIONS => {
			";" => 228
		}
	},
	{#State 154
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 229,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 155
		ACTIONS => {
			"\"" => 234,
			'TEXT' => 231,
			";" => 233,
			"\$" => 43,
			'IDENT' => 2,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'ident' => 230,
			'quotable' => 232
		}
	},
	{#State 156
		DEFAULT => -34
	},
	{#State 157
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 235,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 158
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 236,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 159
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 237,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 160
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 238,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 161
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 239,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 162
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 240,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 163
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 241,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 164
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 242,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 165
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 243,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 166
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 244,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 167
		DEFAULT => -32
	},
	{#State 168
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			";" => 245,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		}
	},
	{#State 169
		ACTIONS => {
			'COMMA' => 171,
			'LITERAL' => 75,
			'IDENT' => 2,
			"\$" => 43,
			"\${" => 37
		},
		DEFAULT => -31,
		GOTOS => {
			'item' => 39,
			'assign' => 170,
			'node' => 23,
			'ident' => 74
		}
	},
	{#State 170
		DEFAULT => -147
	},
	{#State 171
		DEFAULT => -148
	},
	{#State 172
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 246,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 173
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 247,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 174
		ACTIONS => {
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 248
		}
	},
	{#State 175
		ACTIONS => {
			'DOT' => 104
		},
		DEFAULT => -156,
		GOTOS => {
			'args' => 249
		}
	},
	{#State 176
		ACTIONS => {
			"\"" => 250,
			'TEXT' => 231,
			";" => 233,
			"\$" => 43,
			'IDENT' => 2,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'ident' => 230,
			'quotable' => 232
		}
	},
	{#State 177
		ACTIONS => {
			"\"" => 89,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'filename' => 85,
			'name' => 251
		}
	},
	{#State 178
		DEFAULT => -156,
		GOTOS => {
			'args' => 252
		}
	},
	{#State 179
		ACTIONS => {
			'NOT' => 38,
			'LITERAL' => 256,
			'IDENT' => 2,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"{" => 30,
			'COMMA' => 258,
			"(" => 53,
			"\${" => 37
		},
		DEFAULT => -163,
		GOTOS => {
			'expr' => 257,
			'sterm' => 68,
			'item' => 254,
			'param' => 255,
			'node' => 23,
			'ident' => 253,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 180
		DEFAULT => -105
	},
	{#State 181
		DEFAULT => -114
	},
	{#State 182
		DEFAULT => -115
	},
	{#State 183
		DEFAULT => -106
	},
	{#State 184
		ACTIONS => {
			"\"" => 60,
			"\$" => 43,
			'LITERAL' => 78,
			'IDENT' => 2,
			'REF' => 27,
			'NUMBER' => 26,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 259,
			'item' => 39,
			'node' => 23,
			'ident' => 77
		}
	},
	{#State 185
		ACTIONS => {
			'FINAL' => 260,
			'CATCH' => 262
		},
		DEFAULT => -72,
		GOTOS => {
			'final' => 261
		}
	},
	{#State 186
		ACTIONS => {
			'TEXT' => 263
		}
	},
	{#State 187
		ACTIONS => {
			"\"" => 266,
			'LITERAL' => 265,
			'NUMBER' => 264
		}
	},
	{#State 188
		DEFAULT => -97
	},
	{#State 189
		DEFAULT => -98
	},
	{#State 190
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'loop' => 4,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'atomdir' => 12,
			'anonblock' => 50,
			'template' => 267,
			'defblockname' => 14,
			'ident' => 16,
			'assign' => 19,
			'macro' => 20,
			'lterm' => 56,
			'node' => 23,
			'term' => 58,
			'rawperl' => 59,
			'expr' => 62,
			'use' => 63,
			'defblock' => 66,
			'filter' => 29,
			'sterm' => 68,
			'perl' => 31,
			'chunks' => 33,
			'setlist' => 70,
			'switch' => 34,
			'try' => 35,
			'directive' => 71,
			'block' => 72,
			'condition' => 73
		}
	},
	{#State 191
		DEFAULT => -125
	},
	{#State 192
		DEFAULT => -126
	},
	{#State 193
		ACTIONS => {
			";" => 268
		}
	},
	{#State 194
		DEFAULT => -89
	},
	{#State 195
		ACTIONS => {
			";" => -150,
			"+" => 157,
			'LITERAL' => -150,
			'IDENT' => -150,
			'CAT' => 163,
			"\$" => -150,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			'COMMA' => -150,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162,
			"\${" => -150
		},
		DEFAULT => -26
	},
	{#State 196
		DEFAULT => -92
	},
	{#State 197
		DEFAULT => -91
	},
	{#State 198
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 57,
			'IDENT' => 269,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 151,
			'sterm' => 68,
			'item' => 39,
			'assign' => 150,
			'margs' => 270,
			'node' => 23,
			'ident' => 149,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 199
		ACTIONS => {
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -26
	},
	{#State 200
		ACTIONS => {
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 271,
			'lterm' => 56
		}
	},
	{#State 201
		ACTIONS => {
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 272,
			'lterm' => 56
		}
	},
	{#State 202
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'COMMA' => 258,
			'LITERAL' => 256,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		DEFAULT => -64,
		GOTOS => {
			'expr' => 257,
			'sterm' => 68,
			'item' => 254,
			'param' => 255,
			'node' => 23,
			'ident' => 253,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 203
		DEFAULT => -56,
		GOTOS => {
			'@1-3' => 273
		}
	},
	{#State 204
		ACTIONS => {
			"\"" => 89,
			"\$" => 86,
			'LITERAL' => 88,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'names' => 91,
			'nameargs' => 274,
			'filename' => 85,
			'name' => 82
		}
	},
	{#State 205
		ACTIONS => {
			'ASSIGN' => -132
		},
		DEFAULT => -130
	},
	{#State 206
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 275,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 207
		ACTIONS => {
			"\"" => 276,
			'TEXT' => 231,
			";" => 233,
			"\$" => 43,
			'IDENT' => 2,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'ident' => 230,
			'quotable' => 232
		}
	},
	{#State 208
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 277,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 209
		DEFAULT => -108
	},
	{#State 210
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 278,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 211
		DEFAULT => -120
	},
	{#State 212
		DEFAULT => -121
	},
	{#State 213
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 279,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 214
		DEFAULT => -74,
		GOTOS => {
			'@3-3' => 280
		}
	},
	{#State 215
		DEFAULT => -131
	},
	{#State 216
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'COMMA' => 258,
			'LITERAL' => 256,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			")" => 281,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 257,
			'sterm' => 68,
			'item' => 254,
			'param' => 255,
			'node' => 23,
			'ident' => 253,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 217
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 282,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 218
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 283,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 219
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -47
	},
	{#State 220
		DEFAULT => -58
	},
	{#State 221
		DEFAULT => -81
	},
	{#State 222
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -45
	},
	{#State 223
		DEFAULT => -66
	},
	{#State 224
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -61
	},
	{#State 225
		DEFAULT => -144
	},
	{#State 226
		DEFAULT => -145
	},
	{#State 227
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 284,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 228
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 285,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 229
		ACTIONS => {
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -151
	},
	{#State 230
		ACTIONS => {
			'DOT' => 104
		},
		DEFAULT => -177
	},
	{#State 231
		DEFAULT => -178
	},
	{#State 232
		DEFAULT => -175
	},
	{#State 233
		DEFAULT => -179
	},
	{#State 234
		DEFAULT => -111
	},
	{#State 235
		ACTIONS => {
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -135
	},
	{#State 236
		ACTIONS => {
			":" => 286,
			'CMPOP' => 164,
			"?" => 158,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		}
	},
	{#State 237
		ACTIONS => {
			'MOD' => 165
		},
		DEFAULT => -136
	},
	{#State 238
		ACTIONS => {
			'DIV' => 159,
			'BINOP' => 161,
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -140
	},
	{#State 239
		ACTIONS => {
			'DIV' => 159,
			"+" => 157,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -133
	},
	{#State 240
		ACTIONS => {
			'DIV' => 159,
			'BINOP' => 161,
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -141
	},
	{#State 241
		ACTIONS => {
			'DIV' => 159,
			'BINOP' => 161,
			"+" => 157,
			'CMPOP' => 164,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -139
	},
	{#State 242
		ACTIONS => {
			'DIV' => 159,
			'BINOP' => 161,
			"+" => 157,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -138
	},
	{#State 243
		DEFAULT => -137
	},
	{#State 244
		ACTIONS => {
			'DIV' => 159,
			'MOD' => 165
		},
		DEFAULT => -134
	},
	{#State 245
		DEFAULT => -59,
		GOTOS => {
			'@2-3' => 287
		}
	},
	{#State 246
		ACTIONS => {
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -150
	},
	{#State 247
		ACTIONS => {
			'ELSIF' => 290,
			'ELSE' => 288
		},
		DEFAULT => -50,
		GOTOS => {
			'else' => 289
		}
	},
	{#State 248
		DEFAULT => -170
	},
	{#State 249
		ACTIONS => {
			'NOT' => 38,
			'LITERAL' => 256,
			'IDENT' => 2,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"{" => 30,
			'COMMA' => 258,
			"(" => 53,
			"\${" => 37
		},
		DEFAULT => -162,
		GOTOS => {
			'expr' => 257,
			'sterm' => 68,
			'item' => 254,
			'param' => 255,
			'node' => 23,
			'ident' => 253,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 250
		DEFAULT => -167
	},
	{#State 251
		DEFAULT => -165
	},
	{#State 252
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'COMMA' => 258,
			'LITERAL' => 256,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			")" => 291,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 257,
			'sterm' => 68,
			'item' => 254,
			'param' => 255,
			'node' => 23,
			'ident' => 253,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 253
		ACTIONS => {
			'DOT' => 104,
			'ASSIGN' => 292
		},
		DEFAULT => -109
	},
	{#State 254
		ACTIONS => {
			"(" => 135,
			'ASSIGN' => 210
		},
		DEFAULT => -128
	},
	{#State 255
		DEFAULT => -153
	},
	{#State 256
		ACTIONS => {
			'ASSIGN' => 213
		},
		DEFAULT => -112
	},
	{#State 257
		ACTIONS => {
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -152
	},
	{#State 258
		DEFAULT => -155
	},
	{#State 259
		DEFAULT => -117
	},
	{#State 260
		ACTIONS => {
			";" => 293
		}
	},
	{#State 261
		ACTIONS => {
			'END' => 294
		}
	},
	{#State 262
		ACTIONS => {
			";" => 296,
			'DEFAULT' => 297,
			'FILENAME' => 83,
			'IDENT' => 81,
			'NUMBER' => 84
		},
		GOTOS => {
			'filepart' => 87,
			'filename' => 295
		}
	},
	{#State 263
		ACTIONS => {
			'END' => 298
		}
	},
	{#State 264
		DEFAULT => -102
	},
	{#State 265
		DEFAULT => -100
	},
	{#State 266
		ACTIONS => {
			'TEXT' => 299
		}
	},
	{#State 267
		ACTIONS => {
			'END' => 300
		}
	},
	{#State 268
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 301,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 269
		ACTIONS => {
			'IDENT' => -96,
			")" => -96,
			'COMMA' => -96
		},
		DEFAULT => -130
	},
	{#State 270
		ACTIONS => {
			'COMMA' => 304,
			'IDENT' => 302,
			")" => 303
		}
	},
	{#State 271
		DEFAULT => -156,
		GOTOS => {
			'args' => 305
		}
	},
	{#State 272
		DEFAULT => -156,
		GOTOS => {
			'args' => 306
		}
	},
	{#State 273
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 307,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 274
		DEFAULT => -157
	},
	{#State 275
		ACTIONS => {
			'END' => 308
		}
	},
	{#State 276
		ACTIONS => {
			'ASSIGN' => -160
		},
		DEFAULT => -167
	},
	{#State 277
		ACTIONS => {
			'END' => 309
		}
	},
	{#State 278
		ACTIONS => {
			'DIV' => 159,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162,
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -124
	},
	{#State 279
		ACTIONS => {
			'DIV' => 159,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162,
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -123
	},
	{#State 280
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 310,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 281
		DEFAULT => -129
	},
	{#State 282
		ACTIONS => {
			'END' => 311
		}
	},
	{#State 283
		ACTIONS => {
			'ELSIF' => 290,
			'ELSE' => 288
		},
		DEFAULT => -50,
		GOTOS => {
			'else' => 312
		}
	},
	{#State 284
		ACTIONS => {
			'CASE' => 313
		},
		DEFAULT => -55,
		GOTOS => {
			'case' => 314
		}
	},
	{#State 285
		ACTIONS => {
			'END' => 315
		}
	},
	{#State 286
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 316,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 287
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 317,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 288
		ACTIONS => {
			";" => 318
		}
	},
	{#State 289
		ACTIONS => {
			'END' => 319
		}
	},
	{#State 290
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 320,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 291
		DEFAULT => -164
	},
	{#State 292
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'expr' => 321,
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 293
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 322,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 294
		DEFAULT => -67
	},
	{#State 295
		ACTIONS => {
			'DOT' => 174,
			";" => 323
		}
	},
	{#State 296
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 324,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 297
		ACTIONS => {
			";" => 325
		}
	},
	{#State 298
		DEFAULT => -79
	},
	{#State 299
		ACTIONS => {
			"\"" => 326
		}
	},
	{#State 300
		DEFAULT => -82
	},
	{#State 301
		ACTIONS => {
			'END' => 327
		}
	},
	{#State 302
		DEFAULT => -94
	},
	{#State 303
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'WRAPPER' => 55,
			'FOR' => 21,
			'NEXT' => 22,
			'LITERAL' => 57,
			"\"" => 60,
			'PROCESS' => 61,
			'FILTER' => 25,
			'RETURN' => 64,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 193,
			'DEFAULT' => 69,
			"{" => 30,
			"\${" => 37
		},
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'term' => 58,
			'loop' => 4,
			'expr' => 199,
			'wrapper' => 46,
			'atomexpr' => 48,
			'atomdir' => 12,
			'mdir' => 328,
			'filter' => 29,
			'sterm' => 68,
			'ident' => 149,
			'perl' => 31,
			'setlist' => 70,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'directive' => 196,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 304
		DEFAULT => -95
	},
	{#State 305
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'COMMA' => 258,
			'LITERAL' => 256,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		DEFAULT => -62,
		GOTOS => {
			'expr' => 257,
			'sterm' => 68,
			'item' => 254,
			'param' => 255,
			'node' => 23,
			'ident' => 253,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 306
		ACTIONS => {
			'NOT' => 38,
			"{" => 30,
			'COMMA' => 258,
			'LITERAL' => 256,
			'IDENT' => 2,
			"\"" => 60,
			"(" => 53,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		DEFAULT => -63,
		GOTOS => {
			'expr' => 257,
			'sterm' => 68,
			'item' => 254,
			'param' => 255,
			'node' => 23,
			'ident' => 253,
			'term' => 58,
			'lterm' => 56
		}
	},
	{#State 307
		ACTIONS => {
			'END' => 329
		}
	},
	{#State 308
		DEFAULT => -80
	},
	{#State 309
		DEFAULT => -88
	},
	{#State 310
		ACTIONS => {
			'END' => 330
		}
	},
	{#State 311
		DEFAULT => -77
	},
	{#State 312
		ACTIONS => {
			'END' => 331
		}
	},
	{#State 313
		ACTIONS => {
			";" => 332,
			'DEFAULT' => 334,
			"{" => 30,
			'LITERAL' => 78,
			'IDENT' => 2,
			"\"" => 60,
			"\$" => 43,
			"[" => 9,
			'NUMBER' => 26,
			'REF' => 27,
			"\${" => 37
		},
		GOTOS => {
			'sterm' => 68,
			'item' => 39,
			'node' => 23,
			'ident' => 77,
			'term' => 333,
			'lterm' => 56
		}
	},
	{#State 314
		ACTIONS => {
			'END' => 335
		}
	},
	{#State 315
		DEFAULT => -65
	},
	{#State 316
		ACTIONS => {
			'DIV' => 159,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162,
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'MOD' => 165,
			"/" => 166
		},
		DEFAULT => -143
	},
	{#State 317
		ACTIONS => {
			'END' => 336
		}
	},
	{#State 318
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 337,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 319
		DEFAULT => -46
	},
	{#State 320
		ACTIONS => {
			'CMPOP' => 164,
			"?" => 158,
			";" => 338,
			"+" => 157,
			'MOD' => 165,
			'DIV' => 159,
			"/" => 166,
			'AND' => 160,
			'CAT' => 163,
			'BINOP' => 161,
			'OR' => 162
		}
	},
	{#State 321
		ACTIONS => {
			"+" => 157,
			'CAT' => 163,
			'CMPOP' => 164,
			"?" => 158,
			'DIV' => 159,
			'MOD' => 165,
			"/" => 166,
			'AND' => 160,
			'BINOP' => 161,
			'OR' => 162
		},
		DEFAULT => -154
	},
	{#State 322
		DEFAULT => -71
	},
	{#State 323
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 339,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 324
		ACTIONS => {
			'FINAL' => 260,
			'CATCH' => 262
		},
		DEFAULT => -72,
		GOTOS => {
			'final' => 340
		}
	},
	{#State 325
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 341,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 326
		DEFAULT => -101
	},
	{#State 327
		DEFAULT => -93
	},
	{#State 328
		DEFAULT => -90
	},
	{#State 329
		DEFAULT => -57
	},
	{#State 330
		DEFAULT => -75
	},
	{#State 331
		DEFAULT => -44
	},
	{#State 332
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 342,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 333
		ACTIONS => {
			";" => 343
		}
	},
	{#State 334
		ACTIONS => {
			";" => 344
		}
	},
	{#State 335
		DEFAULT => -51
	},
	{#State 336
		DEFAULT => -60
	},
	{#State 337
		DEFAULT => -49
	},
	{#State 338
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 345,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 339
		ACTIONS => {
			'FINAL' => 260,
			'CATCH' => 262
		},
		DEFAULT => -72,
		GOTOS => {
			'final' => 346
		}
	},
	{#State 340
		DEFAULT => -70
	},
	{#State 341
		ACTIONS => {
			'FINAL' => 260,
			'CATCH' => 262
		},
		DEFAULT => -72,
		GOTOS => {
			'final' => 347
		}
	},
	{#State 342
		DEFAULT => -54
	},
	{#State 343
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 348,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 344
		ACTIONS => {
			'SET' => 1,
			'PERL' => 40,
			'NOT' => 38,
			'IDENT' => 2,
			'CLEAR' => 41,
			'UNLESS' => 3,
			'IF' => 44,
			"\$" => 43,
			'STOP' => 6,
			'CALL' => 45,
			'THROW' => 8,
			'GET' => 47,
			"[" => 9,
			'TRY' => 10,
			'LAST' => 49,
			'DEBUG' => 51,
			'RAWPERL' => 13,
			'META' => 15,
			'INCLUDE' => 17,
			"(" => 53,
			'SWITCH' => 54,
			'MACRO' => 18,
			'WRAPPER' => 55,
			";" => -18,
			'FOR' => 21,
			'LITERAL' => 57,
			'NEXT' => 22,
			"\"" => 60,
			'TEXT' => 24,
			'PROCESS' => 61,
			'RETURN' => 64,
			'FILTER' => 25,
			'INSERT' => 65,
			'NUMBER' => 26,
			'REF' => 27,
			'WHILE' => 67,
			'BLOCK' => 28,
			'DEFAULT' => 69,
			"{" => 30,
			'USE' => 32,
			'VIEW' => 36,
			"\${" => 37
		},
		DEFAULT => -3,
		GOTOS => {
			'item' => 39,
			'node' => 23,
			'rawperl' => 59,
			'term' => 58,
			'loop' => 4,
			'use' => 63,
			'expr' => 62,
			'capture' => 42,
			'statement' => 5,
			'view' => 7,
			'wrapper' => 46,
			'atomexpr' => 48,
			'chunk' => 11,
			'defblock' => 66,
			'atomdir' => 12,
			'anonblock' => 50,
			'sterm' => 68,
			'defblockname' => 14,
			'filter' => 29,
			'ident' => 16,
			'perl' => 31,
			'setlist' => 70,
			'chunks' => 33,
			'try' => 35,
			'switch' => 34,
			'assign' => 19,
			'block' => 349,
			'directive' => 71,
			'macro' => 20,
			'condition' => 73,
			'lterm' => 56
		}
	},
	{#State 345
		ACTIONS => {
			'ELSIF' => 290,
			'ELSE' => 288
		},
		DEFAULT => -50,
		GOTOS => {
			'else' => 350
		}
	},
	{#State 346
		DEFAULT => -68
	},
	{#State 347
		DEFAULT => -69
	},
	{#State 348
		ACTIONS => {
			'CASE' => 313
		},
		DEFAULT => -55,
		GOTOS => {
			'case' => 351
		}
	},
	{#State 349
		DEFAULT => -53
	},
	{#State 350
		DEFAULT => -48
	},
	{#State 351
		DEFAULT => -52
	}
]; 



$RULES = [
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'template', 1,
sub
{ $factory->template($_[1])           }
	],
	[#Rule 2
		 'block', 1,
sub
{ $factory->block($_[1])              }
	],
	[#Rule 3
		 'block', 0,
sub
{ $factory->block()                   }
	],
	[#Rule 4
		 'chunks', 2,
sub
{ push(@{$_[1]}, $_[2]) 
                                        if defined $_[2]; $_[1]           }
	],
	[#Rule 5
		 'chunks', 1,
sub
{ defined $_[1] ? [ $_[1] ] : [ ]     }
	],
	[#Rule 6
		 'chunk', 1,
sub
{ $factory->textblock($_[1])          }
	],
	[#Rule 7
		 'chunk', 2,
sub
{ return '' unless $_[1];
                                      $_[0]->location() . $_[1];
                                    }
	],
	[#Rule 8
		 'statement', 1, undef
	],
	[#Rule 9
		 'statement', 1, undef
	],
	[#Rule 10
		 'statement', 1, undef
	],
	[#Rule 11
		 'statement', 1, undef
	],
	[#Rule 12
		 'statement', 1, undef
	],
	[#Rule 13
		 'statement', 1, undef
	],
	[#Rule 14
		 'statement', 1, undef
	],
	[#Rule 15
		 'statement', 1, undef
	],
	[#Rule 16
		 'statement', 1,
sub
{ $factory->get($_[1])                }
	],
	[#Rule 17
		 'statement', 2,
sub
{ $_[0]->add_metadata($_[2]);         }
	],
	[#Rule 18
		 'statement', 0, undef
	],
	[#Rule 19
		 'directive', 1,
sub
{ $factory->set($_[1])                }
	],
	[#Rule 20
		 'directive', 1, undef
	],
	[#Rule 21
		 'directive', 1, undef
	],
	[#Rule 22
		 'directive', 1, undef
	],
	[#Rule 23
		 'directive', 1, undef
	],
	[#Rule 24
		 'directive', 1, undef
	],
	[#Rule 25
		 'directive', 1, undef
	],
	[#Rule 26
		 'atomexpr', 1,
sub
{ $factory->get($_[1])                }
	],
	[#Rule 27
		 'atomexpr', 1, undef
	],
	[#Rule 28
		 'atomdir', 2,
sub
{ $factory->get($_[2])                }
	],
	[#Rule 29
		 'atomdir', 2,
sub
{ $factory->call($_[2])               }
	],
	[#Rule 30
		 'atomdir', 2,
sub
{ $factory->set($_[2])                }
	],
	[#Rule 31
		 'atomdir', 2,
sub
{ $factory->default($_[2])            }
	],
	[#Rule 32
		 'atomdir', 2,
sub
{ $factory->insert($_[2])             }
	],
	[#Rule 33
		 'atomdir', 2,
sub
{ $factory->include($_[2])            }
	],
	[#Rule 34
		 'atomdir', 2,
sub
{ $factory->process($_[2])            }
	],
	[#Rule 35
		 'atomdir', 2,
sub
{ $factory->throw($_[2])              }
	],
	[#Rule 36
		 'atomdir', 1,
sub
{ $factory->return()                  }
	],
	[#Rule 37
		 'atomdir', 1,
sub
{ $factory->stop()                    }
	],
	[#Rule 38
		 'atomdir', 1,
sub
{ "\$output = '';";                   }
	],
	[#Rule 39
		 'atomdir', 1,
sub
{ $_[0]->block_label('last ', ';')    }
	],
	[#Rule 40
		 'atomdir', 1,
sub
{ $_[0]->in_block('FOR')
                                        ? $factory->next($_[0]->block_label)
                                        : $_[0]->block_label('next ', ';') }
	],
	[#Rule 41
		 'atomdir', 2,
sub
{ if ($_[2]->[0]->[0] =~ /^'(on|off)'$/) {
                                          $_[0]->{ DEBUG_DIRS } = ($1 eq 'on');
                                          $factory->debug($_[2]);
                                      }
                                      else {
                                          $_[0]->{ DEBUG_DIRS } ? $factory->debug($_[2]) : '';
                                      }
                                    }
	],
	[#Rule 42
		 'atomdir', 1, undef
	],
	[#Rule 43
		 'atomdir', 1, undef
	],
	[#Rule 44
		 'condition', 6,
sub
{ $factory->if(@_[2, 4, 5])           }
	],
	[#Rule 45
		 'condition', 3,
sub
{ $factory->if(@_[3, 1])              }
	],
	[#Rule 46
		 'condition', 6,
sub
{ $factory->if("!($_[2])", @_[4, 5])  }
	],
	[#Rule 47
		 'condition', 3,
sub
{ $factory->if("!($_[3])", $_[1])     }
	],
	[#Rule 48
		 'else', 5,
sub
{ unshift(@{$_[5]}, [ @_[2, 4] ]);
                                      $_[5];                              }
	],
	[#Rule 49
		 'else', 3,
sub
{ [ $_[3] ]                           }
	],
	[#Rule 50
		 'else', 0,
sub
{ [ undef ]                           }
	],
	[#Rule 51
		 'switch', 6,
sub
{ $factory->switch(@_[2, 5])          }
	],
	[#Rule 52
		 'case', 5,
sub
{ unshift(@{$_[5]}, [ @_[2, 4] ]); 
                                      $_[5];                              }
	],
	[#Rule 53
		 'case', 4,
sub
{ [ $_[4] ]                           }
	],
	[#Rule 54
		 'case', 3,
sub
{ [ $_[3] ]                           }
	],
	[#Rule 55
		 'case', 0,
sub
{ [ undef ]                           }
	],
	[#Rule 56
		 '@1-3', 0,
sub
{ $_[0]->enter_block('FOR')           }
	],
	[#Rule 57
		 'loop', 6,
sub
{ $factory->foreach(@{$_[2]}, $_[5], $_[0]->leave_block)  }
	],
	[#Rule 58
		 'loop', 3,
sub
{ $factory->foreach(@{$_[3]}, $_[1])  }
	],
	[#Rule 59
		 '@2-3', 0,
sub
{ $_[0]->enter_block('WHILE')         }
	],
	[#Rule 60
		 'loop', 6,
sub
{ $factory->while(@_[2, 5], $_[0]->leave_block) }
	],
	[#Rule 61
		 'loop', 3,
sub
{ $factory->while(@_[3, 1]) }
	],
	[#Rule 62
		 'loopvar', 4,
sub
{ [ @_[1, 3, 4] ]                     }
	],
	[#Rule 63
		 'loopvar', 4,
sub
{ [ @_[1, 3, 4] ]                     }
	],
	[#Rule 64
		 'loopvar', 2,
sub
{ [ 0, @_[1, 2] ]                     }
	],
	[#Rule 65
		 'wrapper', 5,
sub
{ $factory->wrapper(@_[2, 4])         }
	],
	[#Rule 66
		 'wrapper', 3,
sub
{ $factory->wrapper(@_[3, 1])         }
	],
	[#Rule 67
		 'try', 5,
sub
{ $factory->try(@_[3, 4])             }
	],
	[#Rule 68
		 'final', 5,
sub
{ unshift(@{$_[5]}, [ @_[2,4] ]);
                                      $_[5];                              }
	],
	[#Rule 69
		 'final', 5,
sub
{ unshift(@{$_[5]}, [ undef, $_[4] ]);
                                      $_[5];                              }
	],
	[#Rule 70
		 'final', 4,
sub
{ unshift(@{$_[4]}, [ undef, $_[3] ]);
                                      $_[4];                              }
	],
	[#Rule 71
		 'final', 3,
sub
{ [ $_[3] ]                           }
	],
	[#Rule 72
		 'final', 0,
sub
{ [ 0 ] }
	],
	[#Rule 73
		 'use', 2,
sub
{ $factory->use($_[2])                }
	],
	[#Rule 74
		 '@3-3', 0,
sub
{ $_[0]->push_defblock();             }
	],
	[#Rule 75
		 'view', 6,
sub
{ $factory->view(@_[2,5], 
                                                     $_[0]->pop_defblock) }
	],
	[#Rule 76
		 '@4-2', 0,
sub
{ ${$_[0]->{ INPERL }}++;             }
	],
	[#Rule 77
		 'perl', 5,
sub
{ ${$_[0]->{ INPERL }}--;
                                      $_[0]->{ EVAL_PERL } 
                                      ? $factory->perl($_[4])             
                                      : $factory->no_perl();              }
	],
	[#Rule 78
		 '@5-1', 0,
sub
{ ${$_[0]->{ INPERL }}++; 
                                      $rawstart = ${$_[0]->{'LINE'}};     }
	],
	[#Rule 79
		 'rawperl', 5,
sub
{ ${$_[0]->{ INPERL }}--;
                                      $_[0]->{ EVAL_PERL } 
                                      ? $factory->rawperl($_[4], $rawstart)
                                      : $factory->no_perl();              }
	],
	[#Rule 80
		 'filter', 5,
sub
{ $factory->filter(@_[2,4])           }
	],
	[#Rule 81
		 'filter', 3,
sub
{ $factory->filter(@_[3,1])           }
	],
	[#Rule 82
		 'defblock', 5,
sub
{ my $name = join('/', @{ $_[0]->{ DEFBLOCKS } });
                                      pop(@{ $_[0]->{ DEFBLOCKS } });
                                      $_[0]->define_block($name, $_[4]); 
                                      undef
                                    }
	],
	[#Rule 83
		 'defblockname', 2,
sub
{ push(@{ $_[0]->{ DEFBLOCKS } }, $_[2]);
                                      $_[2];
                                    }
	],
	[#Rule 84
		 'blockname', 1, undef
	],
	[#Rule 85
		 'blockname', 1,
sub
{ $_[1] =~ s/^'(.*)'$/$1/; $_[1]      }
	],
	[#Rule 86
		 'blockargs', 1, undef
	],
	[#Rule 87
		 'blockargs', 0, undef
	],
	[#Rule 88
		 'anonblock', 5,
sub
{ local $" = ', ';
                                      print STDERR "experimental block args: [@{ $_[2] }]\n"
                                          if $_[2];
                                      $factory->anon_block($_[4])         }
	],
	[#Rule 89
		 'capture', 3,
sub
{ $factory->capture(@_[1, 3])         }
	],
	[#Rule 90
		 'macro', 6,
sub
{ $factory->macro(@_[2, 6, 4])        }
	],
	[#Rule 91
		 'macro', 3,
sub
{ $factory->macro(@_[2, 3])           }
	],
	[#Rule 92
		 'mdir', 1, undef
	],
	[#Rule 93
		 'mdir', 4,
sub
{ $_[3]                               }
	],
	[#Rule 94
		 'margs', 2,
sub
{ push(@{$_[1]}, $_[2]); $_[1]        }
	],
	[#Rule 95
		 'margs', 2,
sub
{ $_[1]                               }
	],
	[#Rule 96
		 'margs', 1,
sub
{ [ $_[1] ]                           }
	],
	[#Rule 97
		 'metadata', 2,
sub
{ push(@{$_[1]}, @{$_[2]}); $_[1]     }
	],
	[#Rule 98
		 'metadata', 2, undef
	],
	[#Rule 99
		 'metadata', 1, undef
	],
	[#Rule 100
		 'meta', 3,
sub
{ for ($_[3]) { s/^'//; s/'$//; 
                                                       s/\\'/'/g  }; 
                                         [ @_[1,3] ] }
	],
	[#Rule 101
		 'meta', 5,
sub
{ [ @_[1,4] ] }
	],
	[#Rule 102
		 'meta', 3,
sub
{ [ @_[1,3] ] }
	],
	[#Rule 103
		 'term', 1, undef
	],
	[#Rule 104
		 'term', 1, undef
	],
	[#Rule 105
		 'lterm', 3,
sub
{ "[ $_[2] ]"                         }
	],
	[#Rule 106
		 'lterm', 3,
sub
{ "[ $_[2] ]"                         }
	],
	[#Rule 107
		 'lterm', 2,
sub
{ "[ ]"                               }
	],
	[#Rule 108
		 'lterm', 3,
sub
{ "{ $_[2]  }"                        }
	],
	[#Rule 109
		 'sterm', 1,
sub
{ $factory->ident($_[1])              }
	],
	[#Rule 110
		 'sterm', 2,
sub
{ $factory->identref($_[2])           }
	],
	[#Rule 111
		 'sterm', 3,
sub
{ $factory->quoted($_[2])             }
	],
	[#Rule 112
		 'sterm', 1, undef
	],
	[#Rule 113
		 'sterm', 1, undef
	],
	[#Rule 114
		 'list', 2,
sub
{ "$_[1], $_[2]"                      }
	],
	[#Rule 115
		 'list', 2, undef
	],
	[#Rule 116
		 'list', 1, undef
	],
	[#Rule 117
		 'range', 3,
sub
{ $_[1] . '..' . $_[3]                }
	],
	[#Rule 118
		 'hash', 1, undef
	],
	[#Rule 119
		 'hash', 0,
sub
{ "" }
	],
	[#Rule 120
		 'params', 2,
sub
{ "$_[1], $_[2]"                      }
	],
	[#Rule 121
		 'params', 2, undef
	],
	[#Rule 122
		 'params', 1, undef
	],
	[#Rule 123
		 'param', 3,
sub
{ "$_[1] => $_[3]"                    }
	],
	[#Rule 124
		 'param', 3,
sub
{ "$_[1] => $_[3]"                    }
	],
	[#Rule 125
		 'ident', 3,
sub
{ push(@{$_[1]}, @{$_[3]}); $_[1]     }
	],
	[#Rule 126
		 'ident', 3,
sub
{ push(@{$_[1]}, 
                                           map {($_, 0)} split(/\./, $_[3]));
                                      $_[1];                              }
	],
	[#Rule 127
		 'ident', 1, undef
	],
	[#Rule 128
		 'node', 1,
sub
{ [ $_[1], 0 ]                        }
	],
	[#Rule 129
		 'node', 4,
sub
{ [ $_[1], $factory->args($_[3]) ]    }
	],
	[#Rule 130
		 'item', 1,
sub
{ "'$_[1]'"                           }
	],
	[#Rule 131
		 'item', 3,
sub
{ $_[2]                               }
	],
	[#Rule 132
		 'item', 2,
sub
{ $_[0]->{ V1DOLLAR }
                                       ? "'$_[2]'" 
                                       : $factory->ident(["'$_[2]'", 0])  }
	],
	[#Rule 133
		 'expr', 3,
sub
{ "$_[1] $_[2] $_[3]"                 }
	],
	[#Rule 134
		 'expr', 3,
sub
{ "$_[1] $_[2] $_[3]"                 }
	],
	[#Rule 135
		 'expr', 3,
sub
{ "$_[1] $_[2] $_[3]"                 }
	],
	[#Rule 136
		 'expr', 3,
sub
{ "int($_[1] / $_[3])"                }
	],
	[#Rule 137
		 'expr', 3,
sub
{ "$_[1] % $_[3]"                     }
	],
	[#Rule 138
		 'expr', 3,
sub
{ "$_[1] $CMPOP{ $_[2] } $_[3]"       }
	],
	[#Rule 139
		 'expr', 3,
sub
{ "$_[1]  . $_[3]"                    }
	],
	[#Rule 140
		 'expr', 3,
sub
{ "$_[1] && $_[3]"                    }
	],
	[#Rule 141
		 'expr', 3,
sub
{ "$_[1] || $_[3]"                    }
	],
	[#Rule 142
		 'expr', 2,
sub
{ "! $_[2]"                           }
	],
	[#Rule 143
		 'expr', 5,
sub
{ "$_[1] ? $_[3] : $_[5]"             }
	],
	[#Rule 144
		 'expr', 3,
sub
{ $factory->assign(@{$_[2]})          }
	],
	[#Rule 145
		 'expr', 3,
sub
{ "($_[2])"                           }
	],
	[#Rule 146
		 'expr', 1, undef
	],
	[#Rule 147
		 'setlist', 2,
sub
{ push(@{$_[1]}, @{$_[2]}); $_[1]     }
	],
	[#Rule 148
		 'setlist', 2, undef
	],
	[#Rule 149
		 'setlist', 1, undef
	],
	[#Rule 150
		 'assign', 3,
sub
{ [ $_[1], $_[3] ]                    }
	],
	[#Rule 151
		 'assign', 3,
sub
{ [ @_[1,3] ]                         }
	],
	[#Rule 152
		 'args', 2,
sub
{ push(@{$_[1]}, $_[2]); $_[1]        }
	],
	[#Rule 153
		 'args', 2,
sub
{ push(@{$_[1]->[0]}, $_[2]); $_[1]   }
	],
	[#Rule 154
		 'args', 4,
sub
{ push(@{$_[1]->[0]}, "'', " . 
                                      $factory->assign(@_[2,4])); $_[1]  }
	],
	[#Rule 155
		 'args', 2,
sub
{ $_[1]                               }
	],
	[#Rule 156
		 'args', 0,
sub
{ [ [ ] ]                             }
	],
	[#Rule 157
		 'lnameargs', 3,
sub
{ push(@{$_[3]}, $_[1]); $_[3]        }
	],
	[#Rule 158
		 'lnameargs', 1, undef
	],
	[#Rule 159
		 'lvalue', 1, undef
	],
	[#Rule 160
		 'lvalue', 3,
sub
{ $factory->quoted($_[2])             }
	],
	[#Rule 161
		 'lvalue', 1, undef
	],
	[#Rule 162
		 'nameargs', 3,
sub
{ [ [$factory->ident($_[2])], $_[3] ]   }
	],
	[#Rule 163
		 'nameargs', 2,
sub
{ [ @_[1,2] ] }
	],
	[#Rule 164
		 'nameargs', 4,
sub
{ [ @_[1,3] ] }
	],
	[#Rule 165
		 'names', 3,
sub
{ push(@{$_[1]}, $_[3]); $_[1] }
	],
	[#Rule 166
		 'names', 1,
sub
{ [ $_[1] ]                    }
	],
	[#Rule 167
		 'name', 3,
sub
{ $factory->quoted($_[2])  }
	],
	[#Rule 168
		 'name', 1,
sub
{ "'$_[1]'" }
	],
	[#Rule 169
		 'name', 1, undef
	],
	[#Rule 170
		 'filename', 3,
sub
{ "$_[1].$_[3]" }
	],
	[#Rule 171
		 'filename', 1, undef
	],
	[#Rule 172
		 'filepart', 1, undef
	],
	[#Rule 173
		 'filepart', 1, undef
	],
	[#Rule 174
		 'filepart', 1, undef
	],
	[#Rule 175
		 'quoted', 2,
sub
{ push(@{$_[1]}, $_[2]) 
                                          if defined $_[2]; $_[1]         }
	],
	[#Rule 176
		 'quoted', 0,
sub
{ [ ]                                 }
	],
	[#Rule 177
		 'quotable', 1,
sub
{ $factory->ident($_[1])              }
	],
	[#Rule 178
		 'quotable', 1,
sub
{ $factory->text($_[1])               }
	],
	[#Rule 179
		 'quotable', 1,
sub
{ undef                               }
	]
];



1;

__END__












