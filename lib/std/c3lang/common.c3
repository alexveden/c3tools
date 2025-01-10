module std::c3lang::common;
// Copyright (c) 2019 Christoffer Lerno. All rights reserved.
// Copyright (c) 2025 Alex Veden <i@alexveden.com>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.

const int MAX_SOURCE_LOCATION_LEN = 255;

enum TokenType : uint
{
	TOKEN_INVALID_TOKEN,

	// Single-character tokens.
	TOKEN_AMP,              // &
	TOKEN_AT,               // @
	TOKEN_BANG,             // !
	TOKEN_BIT_NOT,          // ~
	TOKEN_BIT_OR,           // =
	TOKEN_BIT_XOR,          // ^
	TOKEN_COLON,            // :
	TOKEN_COMMA,            // ,
	TOKEN_EOS,              // ;
	TOKEN_EMPTY_LINE,       // a line with only white spaces (useful for code formatting)
	TOKEN_EQ,               // =
	TOKEN_GREATER,          // >
	TOKEN_DIV,              // /
	TOKEN_DOLLAR,           // $
	TOKEN_DOT,              // .
	TOKEN_HASH,             // #
	TOKEN_LESS,             // <
	TOKEN_LBRACE,           // {
	TOKEN_LBRACKET,         // [
	TOKEN_LPAREN,           // (
	TOKEN_MINUS,            // -
	TOKEN_MOD,              // %
	TOKEN_PLUS,             // +
	TOKEN_QUESTION,         // ?
	TOKEN_RBRACE,           // }
	TOKEN_RBRACKET,         // ]
	TOKEN_RPAREN,           // )
	TOKEN_STAR,             // *
	TOKEN_UNDERSCORE,       // _

	// two character tokens.
	TOKEN_AND,              // &&
	TOKEN_ARROW,            // -> // Not used but reserved
	TOKEN_BANGBANG,         // !!
	TOKEN_BIT_AND_ASSIGN,   // &=
	TOKEN_BIT_OR_ASSIGN,    // |=
	TOKEN_BIT_XOR_ASSIGN,   // ^=
	TOKEN_DIV_ASSIGN,       // /=
	TOKEN_DOTDOT,           // ..
	TOKEN_BUILTIN,          // $$
	TOKEN_ELVIS,            // ?:
	TOKEN_EQEQ,             // ==
	TOKEN_GREATER_EQ,       // >=
	TOKEN_IMPLIES,          // =>
	TOKEN_LESS_EQ,          // <=
	TOKEN_LBRAPIPE,         // {|
	TOKEN_LGENPAR,          // (<
	TOKEN_LVEC,             // [<
	TOKEN_MINUS_ASSIGN,     // -=
	TOKEN_MINUSMINUS,       // --
	TOKEN_MOD_ASSIGN,       // %=
	TOKEN_MULT_ASSIGN,      // *=
	TOKEN_NOT_EQUAL,        // !=
	TOKEN_OR,               // ||
	TOKEN_PLUS_ASSIGN,      // +=
	TOKEN_PLUSPLUS,         // ++
	TOKEN_RBRAPIPE,         // |}
	TOKEN_RGENPAR,          // >)
	TOKEN_RVEC,             // >]
	TOKEN_QUESTQUEST,       // ??
	TOKEN_SCOPE,            // ::
	TOKEN_SHL,              // <<
	TOKEN_SHR,              // >>

	// Three or more
	TOKEN_ELLIPSIS,         // ...
	TOKEN_SHL_ASSIGN,       // <<=
	TOKEN_SHR_ASSIGN,       // >>=
	TOKEN_CT_AND,           // &&&
	TOKEN_CT_CONCAT,        // +++
	TOKEN_CT_OR,            // |||
	// Literals.
	TOKEN_IDENT,            // Any normal ident.
	TOKEN_CONST_IDENT,      // Any purely uppercase ident,
	TOKEN_TYPE_IDENT,       // Any ident on the format FooBar or __FooBar

	// We want to parse $foo separately,
	// otherwise we allow things like "$ foo" which would be pretty bad.
	TOKEN_CT_IDENT,         // $foobar
	TOKEN_CT_CONST_IDENT,   // $FOOBAR
	TOKEN_CT_TYPE_IDENT,    // $Foobar

	// We want to parse #foo separately.
	TOKEN_HASH_IDENT,       // #foobar
	TOKEN_HASH_CONST_IDENT, // #FOOBAR
	TOKEN_HASH_TYPE_IDENT,  // #Foobar

	TOKEN_AT_IDENT,         // @macro
	TOKEN_AT_CONST_IDENT,   // @MACRO
	TOKEN_AT_TYPE_IDENT,    // @Macro

	TOKEN_COMMENT_SINGLE_INLINE,           // //single INLINE comment
	TOKEN_COMMENT_SINGLE,     // //single line comment
	TOKEN_COMMENT_MULTI,          //  /* multiline on new line */
	TOKEN_COMMENT_MULTI_INLINE,   //  some /* multiline on the same line */


	TOKEN_STRING,           // "Teststring"
	TOKEN_RAW_STRING,           // `Teststring`
	TOKEN_INTEGER,          // 123 0x23 0b10010 0o327
	TOKEN_CHAR_LITERAL,        // 'a' 'FO' 'BARS' '\u1232'
	TOKEN_REAL,             // 0x23.2p-2a 43.23e23
	TOKEN_BYTES,            // Base64 or Hex

	TOKEN_DOC_COMMENT,      // Doc Comment start

	// Basic types names
	TOKEN_VOID,
	// TOKEN_FIRST_KEYWORD = TOKEN_VOID,
	TOKEN_BOOL,
	TOKEN_CHAR,
	TOKEN_DOUBLE,
	TOKEN_FLOAT,
	TOKEN_FLOAT16,
	TOKEN_BFLOAT,
	TOKEN_INT128,
	TOKEN_ICHAR,
	TOKEN_INT,
	TOKEN_IPTR,
	TOKEN_ISZ,
	TOKEN_LONG,
	TOKEN_SHORT,
	TOKEN_UINT128,
	TOKEN_UINT,
	TOKEN_ULONG,
	TOKEN_UPTR,
	TOKEN_USHORT,
	TOKEN_USZ,
	TOKEN_FLOAT128,
	TOKEN_ANY,
	TOKEN_ANYFAULT,
	TOKEN_TYPEID,

	// Keywords
	TOKEN_ASSERT,
	TOKEN_ASM,
	TOKEN_BITSTRUCT,
	TOKEN_BREAK,
	TOKEN_CASE,
	TOKEN_CATCH,
	TOKEN_CONST,
	TOKEN_CONTINUE,
	TOKEN_DEF,
	TOKEN_DEFAULT,
	TOKEN_DEFER,
	TOKEN_DISTINCT,
	TOKEN_DO,
	TOKEN_ELSE,
	TOKEN_ENUM,
	TOKEN_EXTERN,
	TOKEN_FALSE,
	TOKEN_FAULT,
	TOKEN_FOR,
	TOKEN_FOREACH,
	TOKEN_FOREACH_R,
	TOKEN_FN,
	TOKEN_TLOCAL,
	TOKEN_IF,
	TOKEN_INLINE,
	TOKEN_IMPORT,
	TOKEN_MACRO,
	TOKEN_MODULE,
	TOKEN_NEXTCASE,
	TOKEN_NULL,
	TOKEN_INTERFACE,
	TOKEN_RETURN,
	TOKEN_STATIC,
	TOKEN_STRUCT,
	TOKEN_SWITCH,
	TOKEN_TRUE,
	TOKEN_TRY,
	TOKEN_UNION,
	TOKEN_VAR,
	TOKEN_WHILE,
	// TOKEN_LAST_NON_CT_KEYWORD = TOKEN_WHILE,

	TOKEN_CT_ALIGNOF,           // $alignof
	TOKEN_CT_ANDFN,             // $and
	TOKEN_CT_APPEND,            // $append
	TOKEN_CT_ASSERT,            // $assert
	TOKEN_CT_ASSIGNABLE,        // $assignable
	TOKEN_CT_CASE,              // $case
	TOKEN_CT_CONCATFN,          // $concat
	TOKEN_CT_DEFAULT,           // $default
	TOKEN_CT_DEFINED,           // $defined
	TOKEN_CT_ECHO,              // $echo
	TOKEN_CT_ELSE,              // $else
	TOKEN_CT_EMBED,             // $embed
	TOKEN_CT_ENDFOR,            // $endfor
	TOKEN_CT_ENDFOREACH,        // $endforeach
	TOKEN_CT_ENDIF,             // $endif
	TOKEN_CT_ENDSWITCH,         // $endswitch
	TOKEN_CT_EVAL,              // $eval
	TOKEN_CT_EVALTYPE,          // $evaltype
	TOKEN_CT_ERROR,             // $error
	TOKEN_CT_EXEC,              // $exec
	TOKEN_CT_EXTNAMEOF,         // $extnameof
	TOKEN_CT_FEATURE,           // $feature
	TOKEN_CT_FOR,               // $for
	TOKEN_CT_FOREACH,           // $foreach
	TOKEN_CT_IF,                // $if
	TOKEN_CT_INCLUDE,           // $include
	TOKEN_CT_IS_CONST,          // $is_const
	TOKEN_CT_NAMEOF,            // $nameof
	TOKEN_CT_OFFSETOF,          // $offsetof
	TOKEN_CT_ORFN,              // $or
	TOKEN_CT_QNAMEOF,           // $qnameof
	TOKEN_CT_SIZEOF,            // $sizeof
	TOKEN_CT_STRINGIFY,         // $stringify
	TOKEN_CT_SWITCH,            // $switch
	TOKEN_CT_TYPEFROM,          // $typefrom
	TOKEN_CT_TYPEOF,            // $typeof
	TOKEN_CT_VACOUNT,           // $vacount
	TOKEN_CT_VATYPE,            // $vatype
	TOKEN_CT_VACONST,           // $vaconst,
	TOKEN_CT_VAREF,             // $varef,
	TOKEN_CT_VAARG,             // $vaarg,
	TOKEN_CT_VAEXPR,            // $vaexpr,
	TOKEN_CT_VASPLAT,           // $vasplat,
	// TOKEN_LAST_KEYWORD = TOKEN_CT_VASPLAT,
	TOKEN_DOCS_START,       // <*
	TOKEN_DOCS_END,         // *>
	TOKEN_DOCS_EOL,

	TOKEN_EOF,              // \n - SHOULD ALWAYS BE THE LAST TOKEN.

	// TOKEN_LAST = TOKEN_EOF,
}


union SourceSpan
{
	struct
	{
		char length;
		uint col;
		uint row;
	}
	ulong a;
}

enum LexMode
{
	LEX_NORMAL,
	LEX_CONTRACTS,
}

fn String token_type_to_string(TokenType type)
{
	switch (type)
	{
		case TOKEN_INVALID_TOKEN:
			return "INVALID_TOKEN";

		// One character tokens
		case TOKEN_AMP:
			return "&";
		case TOKEN_AT:
			return "@";
		case TOKEN_BIT_NOT:
			return "~";
		case TOKEN_BIT_OR:
			return "|";
		case TOKEN_BIT_XOR:
			return "^";
		case TOKEN_COLON:
			return ":";
		case TOKEN_COMMA:
			return ",";
		case TOKEN_DIV:
			return "/";
		case TOKEN_DOLLAR:
			return "$";
		case TOKEN_DOT:
			return ".";
		case TOKEN_EOS:
			return ";";
		case TOKEN_EMPTY_LINE:
			return "<EMPTY_LINE>";
		case TOKEN_EQ:
			return "=";
		case TOKEN_GREATER:
			return ">";
		case TOKEN_HASH:
			return "#";
		case TOKEN_LBRACE:
			return "{";
		case TOKEN_LBRACKET:
			return "[";
		case TOKEN_LESS:
			return "<";
		case TOKEN_LPAREN:
			return "(";
		case TOKEN_MINUS:
			return "-";
		case TOKEN_MOD:
			return "%";
		case TOKEN_BANG:
			return "!";
		case TOKEN_PLUS:
			return "+";
		case TOKEN_QUESTION:
			return "?";
		case TOKEN_RBRACE:
			return "}";
		case TOKEN_RBRACKET:
			return "]";
		case TOKEN_RPAREN:
			return ")";
		case TOKEN_STAR:
			return "*";
		case TOKEN_UNDERSCORE:
			return "_";

		// Two character tokens
		case TOKEN_AND:
			return "&&";
		case TOKEN_ARROW:
			return "->";
		case TOKEN_BIT_AND_ASSIGN:
			return "&=";
		case TOKEN_BIT_OR_ASSIGN:
			return "|=";
		case TOKEN_BIT_XOR_ASSIGN:
			return "^=";
		case TOKEN_BUILTIN:
			return "$$";
		case TOKEN_CT_AND:
			return "&&&";
		case TOKEN_CT_OR:
			return "|||";
		case TOKEN_CT_CONCAT:
			return "+++";
		case TOKEN_DIV_ASSIGN:
			return "/=";
		case TOKEN_DOTDOT:
			return "..";
		case TOKEN_ELVIS:
			return "?:";
		case TOKEN_EQEQ:
			return "==";
		case TOKEN_GREATER_EQ:
			return ">=";
		case TOKEN_IMPLIES:
			return "=>";
		case TOKEN_LESS_EQ:
			return "<=";
		case TOKEN_LBRAPIPE:
			return "{|";
		case TOKEN_LGENPAR:
			return "(<";
		case TOKEN_LVEC:
			return "[<";
		case TOKEN_MINUS_ASSIGN:
			return "-=";
		case TOKEN_MINUSMINUS:
			return "--";
		case TOKEN_MULT_ASSIGN:
			return "*=";
		case TOKEN_MOD_ASSIGN:
			return "%=";
		case TOKEN_NOT_EQUAL:
			return "!=";
		case TOKEN_OR:
			return "||";
		case TOKEN_PLUS_ASSIGN:
			return "+=";
		case TOKEN_PLUSPLUS:
			return "++";
		case TOKEN_QUESTQUEST:
			return "??";
		case TOKEN_RBRAPIPE:
			return "|}";
		case TOKEN_RGENPAR:
			return ">)";
		case TOKEN_RVEC:
			return ">]";
		case TOKEN_SCOPE:
			return "::";
		case TOKEN_SHL:
			return "<<";
		case TOKEN_SHR:
			return ">>";
		case TOKEN_BANGBANG:
			return "!!";

		// Three character tokens
		case TOKEN_ELLIPSIS:
			return "...";
		case TOKEN_SHL_ASSIGN:
			return "<<=";
		case TOKEN_SHR_ASSIGN:
			return ">>=";

		// Identifiers
		case TOKEN_IDENT:
			return "IDENT";
		case TOKEN_CT_IDENT:
			return "CT_IDENT";
		case TOKEN_CT_CONST_IDENT:
			return "CT_CONST_IDENT";
		case TOKEN_CT_TYPE_IDENT:
			return "CT_TYPE_IDENT";
		case TOKEN_HASH_IDENT:
			return "HASH_IDENT";
		case TOKEN_HASH_CONST_IDENT:
			return "HASH_CONST_IDENT";
		case TOKEN_HASH_TYPE_IDENT:
			return "HASH_TYPE_IDENT";
		case TOKEN_CONST_IDENT:
			return "CONST_IDENT";
		case TOKEN_TYPE_IDENT:
			return "TYPE_IDENT";

		case TOKEN_AT_IDENT:
			return "MACRO_IDENT";
		case TOKEN_AT_TYPE_IDENT:
			return "MACRO_TYPE_IDENT";
		case TOKEN_AT_CONST_IDENT:
			return "MACRO_CONST_IDENT";

		// Values
		case TOKEN_STRING:
			return "STRING";
		case TOKEN_RAW_STRING:
			return "RAW_STRING";
		case TOKEN_COMMENT_SINGLE:
			return "COMMENT_SINGLE";
		case TOKEN_COMMENT_SINGLE_INLINE:
			return "COMMENT_SINGLE_INLINE";
		case TOKEN_COMMENT_MULTI:
			return "COMMENT_MULTI";
		case TOKEN_COMMENT_MULTI_INLINE:
			return "COMMENT_MULTI_INLINE";
		case TOKEN_INTEGER:
			return "INTEGER";
		case TOKEN_REAL:
			return "FLOAT";
		case TOKEN_CHAR_LITERAL:
			return "CHAR_LITERAL";
		case TOKEN_BYTES:
			return "BYTES";

		// Comments
		case TOKEN_DOC_COMMENT:
			return "DOC_COMMENT";

		// Keywords
		case TOKEN_ANYFAULT:
			return "anyfault";
		case TOKEN_ASM:
			return "asm";
		case TOKEN_ASSERT:
			return "assert";
		case TOKEN_BITSTRUCT:
			return "bitstruct";
		case TOKEN_BREAK:
			return "break";
		case TOKEN_CASE:
			return "case";
		case TOKEN_CATCH:
			return "catch";
		case TOKEN_CONST:
			return "const";
		case TOKEN_CONTINUE:
			return "continue";
		case TOKEN_DEF:
			return "def";
		case TOKEN_DEFAULT:
			return "default";
		case TOKEN_DEFER:
			return "defer";
		case TOKEN_DISTINCT:
			return "distinct";
		case TOKEN_DO:
			return "do";
		case TOKEN_ELSE:
			return "else";
		case TOKEN_ENUM:
			return "enum";
		case TOKEN_EXTERN:
			return "extern";
		case TOKEN_FALSE:
			return "false";
		case TOKEN_FAULT:
			return "fault";
		case TOKEN_FOR:
			return "for";
		case TOKEN_FOREACH:
			return "foreach";
		case TOKEN_FOREACH_R:
			return "foreach_r";
		case TOKEN_FN:
			return "fn";
		case TOKEN_IF:
			return "if";
		case TOKEN_INLINE:
			return "inline";
		case TOKEN_INTERFACE:
			return "interface";
		case TOKEN_IMPORT:
			return "import";
		case TOKEN_MACRO:
			return "macro";
		case TOKEN_MODULE:
			return "module";
		case TOKEN_NEXTCASE:
			return "nextcase";
		case TOKEN_NULL:
			return "null";
		case TOKEN_RETURN:
			return "return";
		case TOKEN_STATIC:
			return "static";
		case TOKEN_STRUCT:
			return "struct";
		case TOKEN_SWITCH:
			return "switch";
		case TOKEN_TLOCAL:
			return "tlocal";
		case TOKEN_TRUE:
			return "true";
		case TOKEN_TRY:
			return "try";
		case TOKEN_TYPEID:
			return "typeid";
		case TOKEN_UNION:
			return "union";
		case TOKEN_VAR:
			return "var";
		case TOKEN_WHILE:
			return "while";

		// Named types
		case TOKEN_VOID:
			return "void";
		case TOKEN_ANY:
			return "any";
		case TOKEN_BOOL:
			return "bool";
		case TOKEN_FLOAT128:
			return "float128";
		case TOKEN_DOUBLE:
			return "double";
		case TOKEN_FLOAT:
			return "float";
		case TOKEN_BFLOAT:
			return "bfloat";
		case TOKEN_FLOAT16:
			return "float16";
		case TOKEN_LONG:
			return "long";
		case TOKEN_ULONG:
			return "ulong";
		case TOKEN_INT128:
			return "int128";
		case TOKEN_UINT128:
			return "uint128";
		case TOKEN_INT:
			return "int";
		case TOKEN_UINT:
			return "uint";
		case TOKEN_SHORT:
			return "short";
		case TOKEN_USHORT:
			return "ushort";
		case TOKEN_ICHAR:
			return "ichar";
		case TOKEN_CHAR:
			return "char";
		case TOKEN_ISZ:
			return "isz";
		case TOKEN_USZ:
			return "usz";
		case TOKEN_IPTR:
			return "iptr";
		case TOKEN_UPTR:
			return "uptr";
		case TOKEN_DOCS_START:
			return "<*";
		case TOKEN_DOCS_END:
			return "*>";
		case TOKEN_CT_ALIGNOF:
			return "$alignof";
		case TOKEN_CT_ANDFN:
			return "$and";
		case TOKEN_CT_APPEND:
			return "$append";
		case TOKEN_CT_ASSERT:
			return "$assert";
		case TOKEN_CT_ASSIGNABLE:
			return "$assignable";
		case TOKEN_CT_CASE:
			return "$case";
		case TOKEN_CT_CONCATFN:
			return "$concat";
		case TOKEN_CT_DEFAULT:
			return "$default";
		case TOKEN_CT_DEFINED:
			return "$defined";
		case TOKEN_CT_ELSE:
			return "$else";
		case TOKEN_CT_EMBED:
			return "$embed";
		case TOKEN_CT_ENDIF:
			return "$endif";
		case TOKEN_CT_ENDSWITCH:
			return "$endswitch";
		case TOKEN_CT_ENDFOR:
			return "$endfor";
		case TOKEN_CT_ENDFOREACH:
			return "$endforeach";
		case TOKEN_CT_EVAL:
			return "$eval";
		case TOKEN_CT_EVALTYPE:
			return "$evaltype";
		case TOKEN_CT_ERROR:
			return "$error";
		case TOKEN_CT_EXEC:
			return "$exec";
		case TOKEN_CT_EXTNAMEOF:
			return "$extnameof";
		case TOKEN_CT_FEATURE:
			return "$feature";
		case TOKEN_CT_FOR:
			return "$for";
		case TOKEN_CT_FOREACH:
			return "$foreach";
		case TOKEN_CT_IF:
			return "$if";
		case TOKEN_CT_IS_CONST:
			return "$is_const";
		case TOKEN_CT_INCLUDE:
			return "$include";
		case TOKEN_CT_VACOUNT:
			return "$vacount";
		case TOKEN_CT_VATYPE:
			return "$vatype";
		case TOKEN_CT_VACONST:
			return "$vaconst";
		case TOKEN_CT_VAARG:
			return "$vaarg";
		case TOKEN_CT_VAREF:
			return "$varef";
		case TOKEN_CT_VAEXPR:
			return "$vaexpr";
		case TOKEN_CT_VASPLAT:
			return "$vasplat";
		case TOKEN_CT_NAMEOF:
			return "$nameof";
		case TOKEN_CT_OFFSETOF:
			return "$offsetof";
		case TOKEN_CT_ORFN:
			return "$or";
		case TOKEN_CT_QNAMEOF:
			return "$qnameof";
		case TOKEN_CT_SIZEOF:
			return "$sizeof";
		case TOKEN_CT_SWITCH:
			return "$switch";
		case TOKEN_CT_TYPEFROM:
			return "$typefrom";
		case TOKEN_CT_TYPEOF:
			return "$typeof";
		case TOKEN_CT_STRINGIFY:
			return "$stringify";
		case TOKEN_CT_ECHO:
			return "$echo";
		case TOKEN_DOCS_EOL:
			return "<EOL>";
		case TOKEN_EOF:
			return "EOF";
		default:
			unreachable();


	}
}

fn TokenType token_from_identifier(String indentifier)
{
	switch (indentifier)
	{
		case "anyfault":
			return  TOKEN_ANYFAULT;
		case "asm":
			return  TOKEN_ASM;
		case "assert":
			return  TOKEN_ASSERT;
		case "bitstruct":
			return  TOKEN_BITSTRUCT;
		case "break":
			return  TOKEN_BREAK;
		case "case":
			return  TOKEN_CASE;
		case "catch":
			return  TOKEN_CATCH;
		case "const":
			return  TOKEN_CONST;
		case "continue":
			return  TOKEN_CONTINUE;
		case "def":
			return  TOKEN_DEF;
		case "default":
			return  TOKEN_DEFAULT;
		case "defer":
			return  TOKEN_DEFER;
		case "distinct":
			return  TOKEN_DISTINCT;
		case "do":
			return  TOKEN_DO;
		case "else":
			return  TOKEN_ELSE;
		case "enum":
			return  TOKEN_ENUM;
		case "extern":
			return  TOKEN_EXTERN;
		case "false":
			return  TOKEN_FALSE;
		case "fault":
			return  TOKEN_FAULT;
		case "for":
			return  TOKEN_FOR;
		case "foreach":
			return  TOKEN_FOREACH;
		case "foreach_r":
			return  TOKEN_FOREACH_R;
		case "fn":
			return  TOKEN_FN;
		case "if":
			return  TOKEN_IF;
		case "inline":
			return  TOKEN_INLINE;
		case "interface":
			return  TOKEN_INTERFACE;
		case "import":
			return  TOKEN_IMPORT;
		case "macro":
			return  TOKEN_MACRO;
		case "module":
			return  TOKEN_MODULE;
		case "nextcase":
			return  TOKEN_NEXTCASE;
		case "null":
			return  TOKEN_NULL;
		case "return":
			return  TOKEN_RETURN;
		case "static":
			return  TOKEN_STATIC;
		case "struct":
			return  TOKEN_STRUCT;
		case "switch":
			return  TOKEN_SWITCH;
		case "tlocal":
			return  TOKEN_TLOCAL;
		case "true":
			return  TOKEN_TRUE;
		case "try":
			return  TOKEN_TRY;
		case "typeid":
			return  TOKEN_TYPEID;
		case "union":
			return  TOKEN_UNION;
		case "var":
			return  TOKEN_VAR;
		case "while":
			return  TOKEN_WHILE;
		case "void":
		case "any":
		case "bool":
		case "float128":
		case "double":
		case "float":
		case "bfloat":
		case "float16":
		case "long":
		case "ulong":
		case "int128":
		case "uint128":
		case "int":
		case "uint":
		case "short":
		case "ushort":
		case "ichar":
		case "char":
		case "isz":
		case "usz":
		case "iptr":
		case "uptr":
			return  TOKEN_TYPE_IDENT;
		case "$alignof":
			return  TOKEN_CT_ALIGNOF;
		case "$and":
			return  TOKEN_CT_ANDFN;
		case "$append":
			return  TOKEN_CT_APPEND;
		case "$assert":
			return  TOKEN_CT_ASSERT;
		case "$assignable":
			return  TOKEN_CT_ASSIGNABLE;
		case "$case":
			return  TOKEN_CT_CASE;
		case "$concat":
			return  TOKEN_CT_CONCATFN;
		case "$default":
			return  TOKEN_CT_DEFAULT;
		case "$defined":
			return  TOKEN_CT_DEFINED;
		case "$else":
			return  TOKEN_CT_ELSE;
		case "$embed":
			return  TOKEN_CT_EMBED;
		case "$endif":
			return  TOKEN_CT_ENDIF;
		case "$endswitch":
			return  TOKEN_CT_ENDSWITCH;
		case "$endfor":
			return  TOKEN_CT_ENDFOR;
		case "$endforeach":
			return  TOKEN_CT_ENDFOREACH;
		case "$eval":
			return  TOKEN_CT_EVAL;
		case "$evaltype":
			return  TOKEN_CT_EVALTYPE;
		case "$error":
			return  TOKEN_CT_ERROR;
		case "$exec":
			return  TOKEN_CT_EXEC;
		case "$extnameof":
			return  TOKEN_CT_EXTNAMEOF;
		case "$feature":
			return  TOKEN_CT_FEATURE;
		case "$for":
			return  TOKEN_CT_FOR;
		case "$foreach":
			return  TOKEN_CT_FOREACH;
		case "$if":
			return  TOKEN_CT_IF;
		case "$is_const":
			return  TOKEN_CT_IS_CONST;
		case "$include":
			return  TOKEN_CT_INCLUDE;
		case "$vacount":
			return  TOKEN_CT_VACOUNT;
		case "$vatype":
			return  TOKEN_CT_VATYPE;
		case "$vaconst":
			return  TOKEN_CT_VACONST;
		case "$vaarg":
			return  TOKEN_CT_VAARG;
		case "$varef":
			return  TOKEN_CT_VAREF;
		case "$vaexpr":
			return  TOKEN_CT_VAEXPR;
		case "$vasplat":
			return  TOKEN_CT_VASPLAT;
		case "$nameof":
			return  TOKEN_CT_NAMEOF;
		case "$offsetof":
			return  TOKEN_CT_OFFSETOF;
		case "$or":
			return  TOKEN_CT_ORFN;
		case "$qnameof":
			return  TOKEN_CT_QNAMEOF;
		case "$sizeof":
			return  TOKEN_CT_SIZEOF;
		case "$switch":
			return  TOKEN_CT_SWITCH;
		case "$typefrom":
			return  TOKEN_CT_TYPEFROM;
		case "$typeof":
			return  TOKEN_CT_TYPEOF;
		case "$stringify":
			return  TOKEN_CT_STRINGIFY;
		case "$echo":
			return  TOKEN_CT_ECHO;
		default:
			return TOKEN_INVALID_TOKEN;
	}
}
