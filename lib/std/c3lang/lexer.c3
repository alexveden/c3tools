module std::c3lang::lexer;
import std::io;
import std::c3lang::utils_port;
import std::c3lang::common;

// Copyright (c) 2019 Christoffer Lerno. All rights reserved.
// Use of this source code is governed by the GNU LGPLv3.0 license
// a copy of which can be found in the LICENSE file.

// #include "compiler_internal.h"

struct Lexer
{
	char *file_begin;
	char *lexing_start;
	char *current;
	uint current_row;
	uint start_row;
	char *line_start;
	char *start_row_start;
	// File *file;
	TokenData data;
	SourceSpan tok_span;
	TokenType token_type;
	LexMode mode; // only normal is supported
}

struct TokenData
{
	char *lex_start;
	usz lex_len;
	union
	{
		struct
		{
			String string;
		}
		struct
		{
			float value;
		}
		bitstruct : ulong
		{
			bool is_base64 : 0..0;
			ulong bytes_len : 1..63;
		}
		struct
		{
			int128 char_value;
			char width;
		}
	}
}

fn ushort check_col(usz col) @inline @local
{
	if (col > 255) return 0;
	return (ushort)col;
}
fn uint check_row(usz line) @inline @local
{
	return line > std::c3lang::common::MAX_SOURCE_LOCATION_LEN ? 0 : (uint)line;
}

// --- Lexing general methods.

fn void begin_new_token(Lexer *lexer) @inline @local
{
	lexer.lexing_start = lexer.current;
	lexer.start_row = lexer.current_row;
	lexer.start_row_start = lexer.line_start;
}

// // Peek at the current character in the buffer.
macro char peek(lexer_) @local {
  return (*(lexer_).current);
} 
//
// // Look at the prev character in the buffer.
macro char prev(lexer_) @local {
    return ((lexer_).current[-1]);
}
//
// // Peek one character ahead.
macro char peek_next(lexer_) @local {
    return ((lexer_).current[1]);
}
//
// // Is the current character '\0' if so we assume we reached the end.
macro bool reached_end(lexer_) {
    return (lexer_.current[0] == '\0');
}

// Step one character forward and return that character
fn char next(Lexer *lexer) @inline
{
	if (*lexer.current == '\n')
	{
	    // FIX: maybe different logic from orig
		//lexer->line_start = lexer->current + 1, lexer->current_row++;

		lexer.line_start = lexer.current + 1;
		lexer.current_row++;
	}
	return (++lexer.current)[0];
}

// Backtrack the buffer read one step.
fn void backtrack(Lexer *lexer) @inline @local
{
	lexer.current--;
	if (lexer.current[0] == '\n')
	{
		lexer.current_row--;
	}
}

// Skip the x next characters.
fn void skip(Lexer *lexer, int steps) @inline @local
{
	assert(steps > 0);
	for (int i = 0; i < steps; i++)
	{
		next(lexer);
	}
}

// Match a single character – if successful, more one step forward.
fn bool match(Lexer *lexer, char expected) @inline @local
{
	if (lexer.current[0] != expected) return false;
	next(lexer);
	return true;
}

// --- Token creation

/**
 * Allocate data for a token, including source location.
 * This call is doing the basic allocation, with other functions
 * filling out additional information.
 **/
fn void set_generic_token(Lexer *lexer, TokenType type) @inline @local
{

	lexer.token_type = type;
	// Set the location.
	lexer.data.lex_len = lexer.current - lexer.lexing_start;
	lexer.data.lex_start = lexer.lexing_start;
	uint line = lexer.start_row;
	uint col;
	uint length;
	if (line == lexer.current_row)
	{
		// Col is simple difference.
		col = check_col(lexer.lexing_start - lexer.line_start + 1);
		// Length is diff between current and start.
		length = check_row(lexer.current - lexer.lexing_start);
	}
	else
	{
		// For multiline, we grab the diff from the starting line.
		col = check_col(lexer.lexing_start - lexer.start_row_start + 1);
		// But always set a single token length.
		length = 1;
	}
	lexer.tok_span.length = (char)length; // TODO: wtf cast int to char
	lexer.tok_span.col = (char)col;
	lexer.tok_span.row = line;
}

// Error? We simply generate an invalid token and print out the error.
macro bool add_error_token(Lexer *lexer, char *message, ...) @local
{
    
	set_generic_token(lexer, TOKEN_INVALID_TOKEN);
	io::printfn("add_error_token");
	// va_list list;
	// va_start(list, message);
	// sema_verror_range(lexer.tok_span, message, list);
	// va_end(list);
	return false;
}

// Error at the start of the lexing, with a single length.
macro bool add_error_token_at_start(Lexer *lexer, char *message, ...) @local
{
	io::printfn("add_error_token_at_start");
	// va_list list;
	// va_start(list, message);
	// SourceSpan location = {
	// 		.file_id = lexer.file.file_id,
	// 		.row = lexer.start_row,
	// 		.length = 1,
	// 		.col = check_col((lexer.lexing_start - lexer.start_row_start) + 1),
	// };
	// sema_verror_range(location, message, list);
	// va_end(list);
	set_generic_token(lexer, TOKEN_INVALID_TOKEN);
	return false;
}

// Create an error token at a particular place in the file.
// used for pointing out errors in strings etc.
macro bool add_error_token_at(Lexer *lexer, char *loc, isz len, char *message, ...) @local
{
	// va_list list;
	// va_start(list, message);
	// uint current_line = lexer.current_row;
	// if (len > MAX_SOURCE_LOCATION_LEN) len = 0;
	// SourceSpan location = {
	// 		.file_id = lexer.file.file_id,
	// 		.row = current_line,
	// 		.length = len,
	// 		.col = check_col((loc - lexer.line_start) + 1),
	// };
	// sema_verror_range(location, message, list);
	// va_end(list);
	io::printfn("add_error_token_at");
	set_generic_token(lexer, TOKEN_INVALID_TOKEN);
	return false;
}

// Print an error at the current location.
macro bool add_error_token_at_current(Lexer *lexer, char *message, ...) @local
{
	// va_list list;
	// va_start(list, message);
	// uint current_line = lexer.current_row;
	// SourceSpan location = {
	// 		.file_id = lexer.file.file_id,
	// 		.row = current_line,
	// 		.length = 1,
	// 		.col = check_col((lexer.current - lexer.line_start) + 1),
	// };
	// sema_verror_range(location, message, list);
	// va_end(list);

	io::printfn("add_error_token_at_current");
	set_generic_token(lexer, TOKEN_INVALID_TOKEN);
	return false;
}

// Add a new regular token.
fn bool new_token(Lexer *lexer, TokenType type, String string) @inline @local
{
	set_generic_token(lexer, type);
	lexer.data.string = string;
	return true;
}



// --- Comment parsing

/**
 * Parsing of the "//" line comment - skipping past the end.
 */
fn void parse_line_comment(Lexer *lexer) @inline @local
{
	while (!reached_end(lexer) && peek(lexer) != '\n')
	{
		next(lexer);
	}
	// If we found EOL, then walk past '\n'
	if (peek(lexer) == '\n') next(lexer);
}

/**
 * Parse the common / *  * / style multiline comments, allowing nesting.
 **/
fn void parse_multiline_comment(Lexer *lexer) @inline @local
{
	int nesting = 1;
	while (1)
	{
		switch (peek(lexer))
		{
			case '*':
				if (peek_next(lexer) == '/')
				{
					skip(lexer, 2);
					nesting--;
					if (nesting == 0) return;
					continue;
				}
				break;
			case '/':
				if (peek_next(lexer) == '*')
				{
					skip(lexer, 2);
					nesting++;
					continue;
				}
				break;
			case '\0':
				// Reached eof - end.
				return;
			default:
				break;
		}
		next(lexer);
	}
}


/**
 * Skip regular whitespace.
 */
fn void skip_whitespace(Lexer *lexer) @local
{
	while (1)
	{
		switch (peek(lexer))
		{
			case '/':
				if (lexer.mode == LEX_CONTRACTS) return;
				// The '//' case
				if (peek_next(lexer) == '/')
				{
					skip(lexer, 2);
					parse_line_comment(lexer);
					continue;
				}
				// '/*'
				if (peek_next(lexer) == '*')
				{
					skip(lexer, 2);
					parse_multiline_comment(lexer);
					continue;
				}
				return;
			case '\n':
				// Contract lexing sees '\n' as a token.
				if (lexer.mode == LEX_CONTRACTS) return;
				//FALLTHROUGH;
				nextcase;
			case ' ':
			case '\t':
			case '\f':
				next(lexer);
				break;
			case '\r':
				// Already filtered out.
				unreachable();
			default:
				return;
		}
	}
}

// --- Identifier scanning

// Parses identifiers. Note that this is a bit complicated here since
// we split identifiers into 2 types + find keywords.
fn bool scan_ident(Lexer *lexer, TokenType normal, TokenType const_token, TokenType type_token, char prefix) @inline @local
{
	TokenType type = TOKEN_INVALID_TOKEN;
	uint hash = utils_port::FNV1_SEED;
	if (prefix)
	{
		hash = utils_port::fnv1a(prefix, hash);
	}
	char c;
	while ((c = peek(lexer)) == '_')
	{
		hash = utils_port::fnv1a(c, hash);
		next(lexer);
	}
	while LOOP: (1)
	{
		c = peek(lexer);
		switch (c)
		{
            // LOWER_CHAR_CASE
            case 'a':
            case 'b':
            case 'c':
            case 'd':
            case 'e':
            case 'f':
            case 'g':
            case 'h':
            case 'i':
            case 'j':
            case 'k':
            case 'l':
            case 'm':
            case 'n':
            case 'o':
            case 'p':
            case 'q':
            case 'r':
            case 's':
            case 't':
            case 'u':
            case 'v':
            case 'w':
            case 'x':
            case 'y':
            case 'z':
				if (type == TOKEN_INVALID_TOKEN)
				{
					type = normal;
				}
				else if (type == const_token)
				{
					type = type_token;
				}
				break;
            // UPPER_CHAR_CASE
            case 'A':
            case 'B':
            case 'C':
            case 'D':
            case 'E':
            case 'F':
            case 'G':
            case 'H':
            case 'I':
            case 'J':
            case 'K':
            case 'L':
            case 'M':
            case 'N':
            case 'O':
            case 'P':
            case 'Q':
            case 'R':
            case 'S':
            case 'T':
            case 'U':
            case 'V':
            case 'W':
            case 'X':
            case 'Y':
            case 'Z':
				if (type == TOKEN_INVALID_TOKEN) type = const_token;
				break;
            // NUMBER_CHAR_CASE CASE
            case '0': 
            case '1':
            case '2':
            case '3':
            case '4':
            case '5':
            case '6':
            case '7':
            case '8':
            case '9':
				if (type == TOKEN_INVALID_TOKEN) return add_error_token(lexer, "A letter must precede any digit");
			case '_':
				break;
			default:
				// goto EXIT;
				break LOOP;
		}
		hash = utils_port::fnv1a(c, hash);
		next(lexer);
	}

	// TODO: skip this at case default break
	// Allow bang!
	if (peek(lexer) == '!' && type == normal)
	{
		hash = utils_port::fnv1a('!', hash);
		next(lexer);
	}

	// EXIT:;
	uint len = (uint)(lexer.current - lexer.lexing_start);
	if (type == TOKEN_INVALID_TOKEN)
	{
		if (!prefix && len == 1) return new_token(lexer, TOKEN_UNDERSCORE, "_");
		if (prefix && len == 1)
		{
			return add_error_token(lexer, "An identifier was expected after the '%c'.", prefix);
		}
		return add_error_token(lexer, "An identifier may not consist of only '_' characters.");
	}
	switch (type)
	{
		case TOKEN_RETURN:
			if (lexer.mode == LEX_CONTRACTS) type = TOKEN_IDENT;
			break;
		default:
			break;
	}
	String identifier = (String)lexer.lexing_start[..len-1];
	TokenType ttype = common::token_from_identifier(identifier); 
	if (ttype != TOKEN_INVALID_TOKEN){
	    type = ttype;
	}
	return new_token(lexer, type, identifier);
}

// --- Number scanning

/**
 * For C3 we use the practice of f<bit-width> u<bit-width> and i<bit-width>
 * @param lexer
 * @param is_float
 * @return
 */
fn bool scan_number_suffix(Lexer *lexer, bool *is_float) @local
{
	if (prev(lexer) == '_')
	{
		backtrack(lexer);
		return add_error_token_at_current(lexer, "The number ended with '_', which isn't allowed, please remove it.");
	}
	char c = peek(lexer);
	if (!utils_port::char_is_alphanum_(c)) return true;
	switch (c | 32)
	{
		case 'l':
			c = next(lexer);
			if (*is_float)
			{
				return add_error_token_at_current(lexer, "Integer suffix '%c' is not valid for a floating point literal.", c);
			}
			break;
		case 'u':
			if (*is_float)
			{
				return add_error_token_at_current(lexer, "Integer suffix '%c' is not valid for a floating point literal.", c);
			}
			c = next(lexer);
			if ((c | 32) == 'l')
			{
				c = next(lexer);
				break;
			}
			while (utils_port::char_is_digit(c = peek(lexer))) next(lexer);
			break;
		case 'i':
			if (*is_float)
			{
				return add_error_token_at_current(lexer, "Integer suffix '%c' is not valid for a floating point literal.", c);
			}
			next(lexer);
			while (utils_port::char_is_digit(c = peek(lexer))) next(lexer);
			break;
		case 'f':
			next(lexer);
			*is_float = true;
			while (utils_port::char_is_digit(c = peek(lexer))) next(lexer);
			break;
		default:
			break;
	}
	if (utils_port::char_is_alphanum_(c))
	{
		next(lexer);
		return add_error_token(lexer, "This doesn't seem to be a valid literal.");
	}
	return true;
}


macro bool next_and_check_no_multiple_(Lexer* lexer) @local {
    if (next(lexer) == '_' && prev(lexer) == '_') { 
		return add_error_token_at_current(lexer, "Multiple consecutive '_' are not allowed."); 
	} 
	return true;
}

/**
 * Parsing octals. Here we depart from the (error prone) C style octals with initial zero e.g. 0231
 * Instead we only support 0o prefix like 0o231. Note that lexing here doesn't actually parse the
 * number itself.
 */
fn bool scan_oct(Lexer *lexer) @local
{
	if (!utils_port::char_is_oct(peek(lexer)))
	{
		return add_error_token_at_current(lexer, "An expression starting with '0o' should be followed by octal numbers (0-7).");
	}
	next(lexer);
	while (utils_port::char_is_oct_or_(peek(lexer)))  next_and_check_no_multiple_(lexer);

	if (utils_port::char_is_digit(peek(lexer)))
	{
		return add_error_token_at_current(lexer, "An expression starting with '0o' should be followed by octal numbers (0-7).");
	}
	bool is_float = false;
	if (!scan_number_suffix(lexer, &is_float)) return false;
	if (is_float)
	{
		return add_error_token(lexer, "Octal literals cannot have a floating point suffix.");
	}
	return new_token(lexer, TOKEN_INTEGER, ((ZString)lexer.lexing_start).str_view());
}

/**
 * Binary style literals e.g. 0b10101011
 **/
fn bool scan_binary(Lexer *lexer) @local
{
	if (!utils_port::char_is_binary(peek(lexer)))
	{
		return add_error_token_at_current(lexer, "An expression starting with '0b' should be followed by binary digits (0-1).");
	}
	next(lexer);
	while (utils_port::char_is_binary_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
	if (utils_port::char_is_digit(peek((lexer))))
	{
		return add_error_token_at_current(lexer, "An expression starting with '0b' should be followed by binary digits (0-1).");
	}
	bool is_float = false;
	if (!scan_number_suffix(lexer, &is_float)) return false;
	if (is_float)
	{
		return add_error_token(lexer, "Binary literals cannot have a floating point suffix.");
	}
	return new_token(lexer, TOKEN_INTEGER, ((ZString)lexer.lexing_start).str_view());
}

/**
 * Scan the digit after the exponent, e.g +12 or -12 or 12
 * @param lexer
 * @return false if lexing failed.
 */
fn bool scan_exponent(Lexer *lexer) @inline @local
{
	// Step past e/E or p/P
	next(lexer);
	char c = peek(lexer);
	next(lexer);
	// Step past +/-
	if (c == '+' || c == '-')
	{
		c = peek(lexer);
		next(lexer);
	}
	// Now we need at least one digit
	if (!utils_port::char_is_digit(c))
	{
		if (c == 0)
		{
			backtrack(lexer);
			return add_error_token_at_current(lexer, "End of file was reached while parsing the exponent.");
		}
		if (c == '\n') return add_error_token(lexer, "End of line was reached while parsing the exponent.");
		if (c < 31 || c > 127) add_error_token(lexer, "An unexpected character was found while parsing the exponent.");
		return add_error_token(lexer, "Parsing the floating point exponent failed, because '%c' is not a number.", c);
	}
	// Step through all the digits.
	while (utils_port::char_is_digit(peek(lexer))) next(lexer);
	return true;
}

/**
 * Scan a hex number, including floating point hex numbers of the format 0x31a31ff.21p12. Note that the
 * exponent is written in decimal.
 **/
fn bool scan_hex(Lexer *lexer) @inline @local
{
	if (!utils_port::char_is_hex(peek(lexer)))
	{
		return add_error_token_at_current(lexer, "'0x' starts a hexadecimal number, so the next character should be 0-9, a-f or A-F.");
	}
	next(lexer);
	while (utils_port::char_is_hex_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
	bool is_float = false;
	if (peek(lexer) == '.' && peek_next(lexer) != '.')
	{
		is_float = true;
		next(lexer);
		char c = peek(lexer);
		if (c == '_') return add_error_token_at_current(lexer, "'_' is not allowed directly after decimal point, try removing it.");
		if (utils_port::char_is_hex(c)) next(lexer);
		while (utils_port::char_is_hex_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
	}
	char c = peek(lexer);
	if (c == 'p' || c == 'P')
	{
		is_float = true;
		if (!scan_exponent(lexer)) return false;
	}
	if (!scan_number_suffix(lexer, &is_float)) return false;
	return new_token(lexer, is_float ? TOKEN_REAL : TOKEN_INTEGER, ((ZString)lexer.lexing_start).str_view());
}

/**
 * Scans integer and float decimal values.
 */
fn bool scan_dec(Lexer *lexer) @inline @local
{
	assert(utils_port::char_is_digit(peek(lexer)));

	// Walk through the digits, we don't need to worry about
	// initial _ because we only call this if we have a digit initially.
	while (utils_port::char_is_digit_or_(peek(lexer))) next_and_check_no_multiple_(lexer);

	// Assume no float.
	bool is_float = false;

	// If we have a single dot, we assume that we have a float.
	// Note that this current parsing means we can't have functions on
	// literals, like "123.sizeof", but we're fine with that.
	if (peek(lexer) == '.' && peek_next(lexer) != '.')
	{
		is_float = true;
		// Step past '.'
		next(lexer);
		// Check our rule to disallow 123._32
		char c = peek(lexer);
		if (c == '_') return add_error_token_at_current(lexer, "'_' is not allowed directly after decimal point, try removing it.");
		// Now walk until we see no more digits.
		// This allows 123. as a floating point number.
		while (utils_port::char_is_digit_or_(peek(lexer))) next_and_check_no_multiple_(lexer);
	}
	char c = peek(lexer);
	// We might have an exponential. We allow 123e1 and 123.e1 as floating point, so
	// just set it to floating point and check the exponential.
	if (c == 'e' || c == 'E')
	{
		is_float = true;
		if (!scan_exponent(lexer)) return false;
	}
	if (!scan_number_suffix(lexer, &is_float)) return false;
	return new_token(lexer, is_float ? TOKEN_REAL : TOKEN_INTEGER, ((ZString)lexer.lexing_start).str_view());
}

/**
 * Scan a digit, switching on initial zero on possible parsing schemes:
 * 0x... . Hex
 * 0o... . Octal
 * 0b... . Binary
 *
 * Default is decimal.
 *
 * It's actually pretty simple to add encoding schemes here, so for example Base64 could
 * be added.
 */
fn bool scan_digit(Lexer *lexer) @inline @local
{
	if (peek(lexer) == '0')
	{
		switch (peek_next(lexer))
		{
			case 'x':
			case 'X':
				skip(lexer, 2);
				return scan_hex(lexer);
			case 'o':
			case 'O':
				skip(lexer, 2);
				return scan_oct(lexer);
			case 'b':
			case 'B':
				skip(lexer, 2);
				return scan_binary(lexer);
			default:
				break;
		}
	}
	return scan_dec(lexer);
}

// --- Character & string scan

fn long scan_hex_literal(Lexer *lexer, int positions) @inline @local
{
	long hex = 0;
	for (int j = 0; j < positions; j++)
	{
		hex <<= 4U;
		int i = utils_port::char_hex_to_nibble(peek(lexer));
		if (i < 0)
		{
			return -1;
		}
		next(lexer);
		hex += i;
	}
	return hex;
}

fn long scan_utf8(Lexer *lexer, char c) @inline @local
{
	int utf8_bytes;
	ulong result;
	if (c < 0xc0) {
        // goto ERROR;
        return -1;
	} 
	if (c <= 0xdf)
	{
		result = 0x1f & (ulong)c;
		utf8_bytes = 2;
	}
	else if (c <= 0xef)
	{
		result = 0xf & (ulong)c;
		utf8_bytes = 3;
	}
	else if (c <= 0xf7)
	{
		utf8_bytes = 4;
		result = 0x7 & (ulong)c;
	}
	else if (c <= 0xfb)
	{
		utf8_bytes = 5;
		result = 0x3 & (ulong)c;
	}
	else if (c <= 0xfd)
	{
		utf8_bytes = 6;
		result = 0x1 & (ulong)c;
	}
	else
	{
		//goto ERROR;
		return -1;
	}
	for (int i = 1; i < utf8_bytes; i++)
	{
		result <<= 6U;
		c = (char)peek(lexer);
		if (c == '\0') return 0xFFFD;
		next(lexer);
		if ((c & 0xc0) != 0x80)
		{
			// goto ERROR;
			return -1;
		}
		result += (ulong)c & 0x3f;
	}
	return (long)result;
// ERROR:
	// add_error_token(lexer, "Invalid UTF-8 sequence.");
	// return -1;
}

/**
 * Rules:
 * 1. If ASCII or \xAB, accept up to 8 characters (16 with Int128 support), size is char, ushort, uint, ulong, UInt128
 * 2. If UTF8, accept 1 UTF character, size is ushort normally, ulong on wide UTF characters, no additional characters accepted.
 * 3. If \uABCD, convert to 16 bits, size is ushort, no additional characters accepted.
 * 4. If \U01234567, convert to 32 bits, size is uint, no additional characters accepted.
 *
 * @param lexer
 * @return
 */
fn bool scan_char(Lexer *lexer) @inline @local
{

	// Handle the problem with zero size character literal first.
	if (match(lexer, '\''))
	{
		return add_error_token(lexer, "The character literal was empty.");
	}

	int width = 0;
	char c;
	//Int128 b = { 0, 0 };
	int128 b = 0;

	while LOOP: (!match(lexer, '\''))
	{
		c = peek(lexer);
		next(lexer);
		// End of file may occur:
		if (c == '\0')
		{
			return add_error_token_at_start(lexer, "The character literal did not terminate.");
		}
		// We might exceed the width that we allow.
		if (width > 15) return add_error_token_at_start(lexer, "The character literal exceeds 16 characters.");
		// Handle (expected) utf-8 characters.
		if ((uint)c >= (uint)0x80)
		{
			if (width != 0) {
			        
                 //goto UNICODE_IN_MULTI;
	             return add_error_token(lexer, "A multi-character literal may not contain unicode characters.");
			}
			long utf8 = scan_utf8(lexer, (char)c);
			if (utf8 < 0) return false;
			if (!match(lexer, '\''))
			{
				if (peek(lexer) == '\0') continue;
				backtrack(lexer);
				return add_error_token_at_current(lexer, "Unicode character literals may only contain one character, "
														 "please remove the additional ones or use all ASCII.");
			}
			assert(1 != 0, "wtf?");
		    //b.low = (ulong) utf8;
			width = utf8 > 0xffff ? 4 : 2;
			// goto DONE;
			break LOOP;
		}
		// Parse the escape code
		ichar escape = ' ';
		if (c == '\\')
		{
			assert(c == '\\');
			c = peek(lexer);
			escape = utils_port::char_is_valid_escape(c);
			if (escape == -1)
			{
				lexer.lexing_start += 1;
				if (c > ' ' && c <= 127)
				{
					next(lexer);
					return add_error_token(lexer, "Invalid escape sequence '\\%c'.", c);
				}
				return add_error_token_at_current(lexer, "An escape sequence was expected after '\\'.");
			}
			next(lexer);
		}
		char *escape_begin = lexer.current - 2;
		switch (escape)
		{
			case 'x':
			{
				long hex = scan_hex_literal(lexer, 2);
				if (hex < 0)
				{
					return add_error_token_at(lexer, escape_begin, lexer.current - escape_begin, "Expected a two character hex value after \\x.");
				}
				// We can now reassign c and use the default code.
				c = (char)hex;
				break;
			}
			case 'u':
			case 'U':
			{
				// First check that we don't have any characters previous to this one.
				if (width != 0) {
					return add_error_token_at(lexer, escape_begin, lexer.current - escape_begin, "Expected a two character hex value after \\x.");
				};
				int bytes = escape == 'U' ? 4 : 2;
				long hex = scan_hex_literal(lexer, bytes * 2);
				// The hex parsing may have failed, lacking more hex chars.
				if (hex < 0)
				{
					begin_new_token(lexer);
					return add_error_token_at(lexer, escape_begin, lexer.current - escape_begin,
											  "Expected %s character hex value after \\%c.",
											  escape == 'u' ? "a four" : "an eight", escape);
				}
				// If we don't see the end here, then something is wrong.
				if (!match(lexer, '\''))
				{
					// It may be the end of the line, if so use the default handling by invoking "continue"
					if (peek(lexer) == '\0') continue;
					return add_error_token_at_current(lexer,
													  "Character literals with '\\%c' can only contain one character, please remove this one.",
													  escape);
				}
				// Assign the value and go to "DONE".
			    assert(1 != 0, "wtf?");
				//b.low = (ulong) hex;
				width = bytes;
				// goto DONE;
				break LOOP;
			}
			case ' ':
				// No escape, a regular character.
				break;
			default:
				c = (ichar)escape;
				break;
		}
		// Default handling here:
		width++;
		// b = i128_shl64(b, 8);
		// b = i128_add64(b, (char)c);
		b <<= 8;
		b += (char)c;
	}
	assert(width > 0 && width <= 16);
// DONE:
	set_generic_token(lexer, TOKEN_CHAR_LITERAL);
	lexer.data.char_value = b;
	lexer.data.width = (char)width;
	return true;

// UNICODE_IN_MULTI:
// return add_error_token(lexer, "A multi-character literal may not contain unicode characters.");
}

fn int append_esc_string_token(char* dest, char* src, usz *pos) @local
{
	int scanned;
	ulong unicode_char;
	ichar scanned_char = utils_port::char_is_valid_escape(src[0]);
	if (scanned_char < 0) return -1;
	switch (scanned_char)
	{
		case 'x':
		{
			int h = utils_port::char_hex_to_nibble(src[1]);
			if (h < 0) return -1;
			int l = utils_port::char_hex_to_nibble(src[2]);
			if (l < 0) return -1;
			unicode_char = (((ulong) h << (ulong)4) + (ulong)l);
			scanned = 3;
			break;
		}
		case 'u':
		{
			int x1 = utils_port::char_hex_to_nibble(src[1]);
			if (x1 < 0) return -1;
			int x2 = utils_port::char_hex_to_nibble(src[2]);
			if (x2 < 0) return -1;
			int x3 = utils_port::char_hex_to_nibble(src[3]);
			if (x3 < 0) return -1;
			int x4 = utils_port::char_hex_to_nibble(src[4]);
			if (x4 < 0) return -1;
			unicode_char = ((ulong) x1 << (ulong)12) + ((ulong) x2 << (ulong)8) + ((ulong) x3 << (ulong)4) + (uint)x4;
			scanned = 5;
			break;
		}
		case 'U':
		{
			int x1 = utils_port::char_hex_to_nibble(src[1]);
			if (x1 < 0) return -1;
			int x2 = utils_port::char_hex_to_nibble(src[2]);
			if (x2 < 0) return -1;
			int x3 = utils_port::char_hex_to_nibble(src[3]);
			if (x3 < 0) return -1;
			int x4 = utils_port::char_hex_to_nibble(src[4]);
			if (x4 < 0) return -1;
			int x5 = utils_port::char_hex_to_nibble(src[5]);
			if (x5 < 0) return -1;
			int x6 = utils_port::char_hex_to_nibble(src[6]);
			if (x6 < 0) return -1;
			int x7 = utils_port::char_hex_to_nibble(src[7]);
			if (x7 < 0) return -1;
			int x8 = utils_port::char_hex_to_nibble(src[8]);
			if (x8 < 0) return -1;
			unicode_char = ((ulong) x1 << 28U) + ((ulong) x2 << 24U) + ((ulong) x3 << 20U) + ((ulong) x4 << 16U) +
					((ulong) x5 << 12U) + ((ulong) x6 << 8U) + ((ulong) x7 << 4U) + (ulong)x8;
			scanned = 9;
			break;
		}
		default:
			dest[(*pos)++] = scanned_char;
			return 1;
	}
	if (unicode_char < 0x80U)
	{
		dest[(*pos)++] = (char)unicode_char;
	}
	else if (unicode_char < 0x800U)
	{
		dest[(*pos)++] = (char)(0xC0U | (unicode_char >> 6U));
		dest[(*pos)++] = (char)(0x80U | (unicode_char & 0x3FU));
	}
	else if (unicode_char < 0x10000U)
	{
		dest[(*pos)++] = (char)(0xE0U | (unicode_char >> 12U));
		dest[(*pos)++] = (char)(0x80U | ((unicode_char >> 6U) & 0x3FU));
		dest[(*pos)++] = (char)(0x80U | (unicode_char & 0x3FU));
	}
	else
	{
		dest[(*pos)++] = (char)(0xF0U | (unicode_char >> 18U));
		dest[(*pos)++] = (char)(0x80U | ((unicode_char >> 12U) & 0x3FU));
		dest[(*pos)++] = (char)(0x80U | ((unicode_char >> 6U) & 0x3FU));
		dest[(*pos)++] = (char)(0x80U | (unicode_char & 0x3FU));
	}
	return scanned;
}


fn void consume_to_end_quote(Lexer *lexer) @inline @local
{
	char c;
	while ((c = peek(lexer)) != '\0' && c != '"')
	{
		next(lexer);
	}
}

fn bool scan_string(Lexer *lexer) @inline @local
{
	char c = 0;
	char *current = lexer.current;
	while ((c = *(current++)) != '"')
	{
		if (c == '\n' || c == '\0')
		{
			current++;
			break;
		}
		if (c == '\\')
		{
			c = *current;
			if (c != '\n' && c != '\0') current++;
			continue;
		}
	}
	char *end = current - 1;
	// FIX: leaks????
	// char *destination = malloc_string((usz)(end - lexer.current + 1));
	char *destination = mem::malloc((usz)(end - lexer.current + 1));
	usz len = 0;
	while (lexer.current < end)
	{
		c = peek(lexer);
		next(lexer);
		if (c == '\0' || (c == '\\' && peek(lexer) == '\0'))
		{
			if (c == '\0') backtrack(lexer);
			add_error_token_at_start(lexer, "The end of the file was reached "
											"while parsing the string. "
											"Did you forget (or accidentally add) a '\"' somewhere?");
			consume_to_end_quote(lexer);
			return false;
		}
		if (c == '\n' || (c == '\\' && peek(lexer) == '\n'))
		{

			backtrack(lexer);
			add_error_token_at_start(lexer, "The end of the line was reached "
											"while parsing the string. "
											"Did you forget (or accidentally add) a '\"' somewhere?");
			consume_to_end_quote(lexer);
			return false;
		}
		if (c == '\\')
		{
			int scanned = append_esc_string_token(destination, lexer.current, &len);
			if (scanned < 0)
			{
				add_error_token_at_current(lexer, "Invalid escape in string.");
				consume_to_end_quote(lexer);
				return false;
			}
			skip(lexer, scanned);
			continue;
		}
		destination[len++] = c;
	}
	// Skip the `"`
	next(lexer);
	destination[len] = 0;
	new_token(lexer, TOKEN_STRING, ((ZString)destination).str_view());
	// lexer.data.strlen = len;
	return true;
}

fn bool scan_raw_string(Lexer *lexer) @inline @local
{
	char c;
	while (1)
	{
		c = peek(lexer);
		next(lexer);
		if (c == '`' && peek(lexer) != '`') break;
		if (c == '\0')
		{
			return add_error_token_at_start(lexer, "Reached the end of the file looking for "
												   "the end of the raw string that starts "
												   "here. Did you forget a '`' somewhere?");
		}
		if (c == '`') next(lexer);
	}
	char *current = lexer.lexing_start + 1;
	char *end = lexer.current - 1;
	usz len = (usz)(end - current);
	// FIX: leaks????
	// char *destination = malloc_string(len + 1);
	char *destination = mem::malloc(len + 1);
	len = 0;
	while (current < end)
	{
		c = *(current++);
		if (c == '`' && current[0] == '`')
		{
			current++;
		}
		destination[len++] = c;
	}
	destination[len] = 0;
	new_token(lexer, TOKEN_STRING, ((ZString)destination).str_view());
	// new_token(lexer, TOKEN_STRING, destination);
	// lexer.data.strlen = len;
	return true;
}

fn bool scan_hex_array(Lexer *lexer) @inline @local
{
	char start_char = peek(lexer);
	next(lexer); // Step past ' or " `
	char c;
	ulong len = 0;
	while (1)
	{
		c = peek(lexer);
		if (c == 0)
		{
			return add_error_token_at_current(lexer, "The hex string seems to be missing a terminating '%c'", start_char);
		}
		if (c == start_char) break;
		if (utils_port::char_is_hex(c))
		{
			next(lexer);
			len++;
			continue;
		}
		if (utils_port::char_is_whitespace(c))
		{
			next(lexer);
			continue;
		}
		if (c > ' ' && c < 127)
		{
			return add_error_token_at_current(lexer,
											  "'%c' isn't a valid hexadecimal digit, all digits should be a-z, A-Z and 0-9.",
											  c);
		}
		return add_error_token_at_current(lexer,
										  "This isn't a valid hexadecimal digit, all digits should be a-z, A-Z and 0-9.");
	}
	next(lexer);
	if (len % 2)
	{
		return add_error_token(lexer, "The hexadecimal string is not an even length, did you miss a digit somewhere?");
	}
	if (!new_token(lexer, TOKEN_BYTES, ((ZString)lexer.lexing_start).str_view())) return false;
	lexer.data.is_base64 = false;
	lexer.data.bytes_len = (ulong)len / 2;
	return true;
}

// Scan b64"abc=" and b64'abc='
fn bool scan_base64(Lexer *lexer) @inline @local
{
	next(lexer); // Step past 6
	next(lexer); // Step past 4
	char start_char = peek(lexer);
	next(lexer); // Step past ' or " or `
	char c;
	uint end_len = 0;
	ulong len = 0;
	while (1)
	{
		c = peek(lexer);
		if (c == 0)
		{
			return add_error_token_at_start(lexer, "The base64 string seems to be missing a terminating '%c'", start_char);
		}
		next(lexer);
		if (c == start_char) break;
		if (utils_port::char_is_base64(c))
		{
			if (end_len)
			{
				return add_error_token_at_current(lexer, "'%c' can't be placed after an ending '='", c);
			}
			len++;
			continue;
		}
		if (c == '=')
		{
			if (end_len > 1)
			{
				return add_error_token_at_current(lexer, "There cannot be more than 2 '=' at the end of a base64 string.", c);
			}
			end_len++;
			continue;
		}
		if (!utils_port::char_is_whitespace(c))
		{
			if (c < ' ' || c > 127)
			{
				return add_error_token_at_current(lexer, "A valid base64 character was expected here.");
			}
			return add_error_token_at_current(lexer, "'%c' is not a valid base64 character.", c);
		}
	}
	if (!end_len && len % 4 != 0)
	{
		switch (len % 4)
		{
			case 0:
			case 1:
				// Invalid
				break;
			case 2:
				end_len = 2;
				break;
			case 3:
				end_len = 1;
				break;
			default:
				unreachable();
		}
		if (len % 4 == 3)
		{
			end_len = 1;
		}
	}
	if ((len + end_len) % 4 != 0)
	{
		return add_error_token_at_start(lexer, "Base64 strings must either be padded to multiple of 4, or if unpadded "
											   "- only need 1 or 2 bytes of extra padding.");
	}
	ulong decoded_len = (3 * len - end_len) / 4;
	if (!new_token(lexer, TOKEN_BYTES, ((ZString)lexer.lexing_start).str_view())) return false;
	lexer.data.is_base64 = true;
	lexer.data.bytes_len = decoded_len;
	return true;
}



// --- Lexer doc lexing

/**
 * Parse the <* *> directives comments
 **/
fn bool parse_doc_start(Lexer *lexer) @local
{
	bool may_have_contract = true;
	// Let's loop until we find the end or the contract.
	while LOOP: (!reached_end(lexer))
	{
		char c = peek(lexer);
		switch (c)
		{
			case '\n':
				may_have_contract = true;
				next(lexer);
				continue;
			case ' ':
			case '\t':
				next(lexer);
				continue;
			case '*':
				// We might have <* Hello *>
				// if (peek_next(lexer) == '>') goto EXIT;
				if (peek_next(lexer) == '>') break LOOP;
				may_have_contract = false;
				next(lexer);
				continue;
			case '@':
				if (may_have_contract && utils_port::char_is_lower(peek_next(lexer)))
				{
					// Found a contract
					// goto EXIT;
					break;
				}
				nextcase;
			default:
				may_have_contract = false;
				next(lexer);
				continue;
		}
	}
// EXIT:;
	// Now we either found:
	// 1. "<* foo \n @param"
	// 2. "<* foo *>"
	// 3. "<* foo <eof>"
	//
	// In any case we can consider this having reached "the contracts"
	lexer.mode = LEX_CONTRACTS;
	return new_token(lexer, TOKEN_DOCS_START, ((ZString)lexer.lexing_start).str_view());
}

fn bool lexer_scan_token_inner(Lexer *lexer) @local
{
	// Now skip the whitespace.
	skip_whitespace(lexer);

	// Point start to the first non-whitespace character.
	begin_new_token(lexer);

	if (reached_end(lexer)) return new_token(lexer, TOKEN_EOF, "\n") && false;

	ichar c = peek(lexer);
	next(lexer);
	switch (c)
	{
		case '\n':
			assert(lexer.mode == LEX_CONTRACTS);
			return new_token(lexer, TOKEN_DOCS_EOL, "<eol>");
		case '@':
			if (utils_port::char_is_letter_(peek(lexer)))
			{
				return scan_ident(lexer, TOKEN_AT_IDENT, TOKEN_AT_CONST_IDENT, TOKEN_AT_TYPE_IDENT, '@');
			}
			return new_token(lexer, TOKEN_AT, "@");
		case '\'':
			return scan_char(lexer);
		case '`':
			return scan_raw_string(lexer);
		case '"':
			return scan_string(lexer);
		case '#':
			return scan_ident(lexer, TOKEN_HASH_IDENT, TOKEN_HASH_CONST_IDENT, TOKEN_HASH_TYPE_IDENT, '#');
		case '$':
			if (match(lexer, '$'))
			{
				if (utils_port::char_is_letter(peek(lexer)))
				{
					return new_token(lexer, TOKEN_BUILTIN, "$$");
				}
				return add_error_token_at_current(lexer, "Expected a letter after $$.");
			}
			return scan_ident(lexer, TOKEN_CT_IDENT, TOKEN_CT_CONST_IDENT, TOKEN_CT_TYPE_IDENT, '$');
		case ',':
			return new_token(lexer, TOKEN_COMMA, ",");
		case ';':
			return new_token(lexer, TOKEN_EOS, ";");
		case '{':
			return match(lexer, '|') ? new_token(lexer, TOKEN_LBRAPIPE, "{|") : new_token(lexer, TOKEN_LBRACE, "{");
		case '}':
			return new_token(lexer, TOKEN_RBRACE, "}");
		case '(':
			return match(lexer, '<') ? new_token(lexer, TOKEN_LGENPAR, "(<") : new_token(lexer, TOKEN_LPAREN, "(");
		case ')':
			return new_token(lexer, TOKEN_RPAREN, ")");
		case '[':
			if (match(lexer, '<')) return new_token(lexer, TOKEN_LVEC, "[<");
			return new_token(lexer, TOKEN_LBRACKET, "[");
		case ']':
			return new_token(lexer, TOKEN_RBRACKET, "]");
		case '.':
			if (match(lexer, '.'))
			{
				if (match(lexer, '.')) return new_token(lexer, TOKEN_ELLIPSIS, "...");
				return new_token(lexer, TOKEN_DOTDOT, "..");
			}
			return new_token(lexer, TOKEN_DOT, ".");
		case '~':
			return new_token(lexer, TOKEN_BIT_NOT, "~");
		case ':':
			return match(lexer, ':') ? new_token(lexer, TOKEN_SCOPE, "::") : new_token(lexer, TOKEN_COLON, ":");
		case '!':
			if (match(lexer, '!')) return new_token(lexer, TOKEN_BANGBANG, "!!");
			return match(lexer, '=') ? new_token(lexer, TOKEN_NOT_EQUAL, "!=") : new_token(lexer, TOKEN_BANG, "!");
		case '/':
			return match(lexer, '=') ? new_token(lexer, TOKEN_DIV_ASSIGN, "/=") : new_token(lexer, TOKEN_DIV, "/");
		case '*':
			if (lexer.mode == LEX_CONTRACTS && match(lexer, '>'))
			{
				lexer.mode = LEX_NORMAL;
				return new_token(lexer, TOKEN_DOCS_END, "*>");
			}
			return match(lexer, '=') ? new_token(lexer, TOKEN_MULT_ASSIGN, "*=") : new_token(lexer, TOKEN_STAR, "*");
		case '=':
			if (match(lexer, '>')) return new_token(lexer, TOKEN_IMPLIES, "=>");
			return match(lexer, '=') ? new_token(lexer, TOKEN_EQEQ, "==") : new_token(lexer, TOKEN_EQ, "=");
		case '^':
			return match(lexer, '=') ? new_token(lexer, TOKEN_BIT_XOR_ASSIGN, "^=") : new_token(lexer, TOKEN_BIT_XOR, "^");
		case '?':
			if (match(lexer, '?')) return new_token(lexer, TOKEN_QUESTQUEST, "??");
			return match(lexer, ':') ? new_token(lexer, TOKEN_ELVIS, "?:") : new_token(lexer, TOKEN_QUESTION, "?");
		case '<':
			if (match(lexer, '<'))
			{
				if (match(lexer, '=')) return new_token(lexer, TOKEN_SHL_ASSIGN, "<<=");
				return new_token(lexer, TOKEN_SHL, "<<");
			}
			if (lexer.mode == LEX_NORMAL && match(lexer, '*'))
			{
				return parse_doc_start(lexer);
			}
			return match(lexer, '=') ? new_token(lexer, TOKEN_LESS_EQ, "<=") : new_token(lexer, TOKEN_LESS, "<");
		case '>':
			if (match(lexer, '>'))
			{
				if (match(lexer, '=')) return new_token(lexer, TOKEN_SHR_ASSIGN, ">>=");
				return new_token(lexer, TOKEN_SHR, ">>");
			}
			if (match(lexer, ')')) return new_token(lexer, TOKEN_RGENPAR, ">)");
			if (match(lexer, ']')) return new_token(lexer, TOKEN_RVEC, ">]");
			return match(lexer, '=') ? new_token(lexer, TOKEN_GREATER_EQ, ">=") : new_token(lexer, TOKEN_GREATER, ">");
		case '%':
			return match(lexer, '=') ? new_token(lexer, TOKEN_MOD_ASSIGN, "%=") : new_token(lexer, TOKEN_MOD, "%");
		case '&':
			if (match(lexer, '&'))
			{
				return match(lexer, '&') ? new_token(lexer, TOKEN_CT_AND, "&&&") : new_token(lexer, TOKEN_AND, "&&");
			}
			return match(lexer, '=') ? new_token(lexer, TOKEN_BIT_AND_ASSIGN, "&=") : new_token(lexer, TOKEN_AMP, "&");
		case '|':
			if (match(lexer, '}')) return new_token(lexer, TOKEN_RBRAPIPE, "|}");
			if (match(lexer, '|'))
			{
				return match(lexer, '|') ? new_token(lexer, TOKEN_CT_OR, "|||") : new_token(lexer, TOKEN_OR, "||");
			}
			return match(lexer, '=') ? new_token(lexer, TOKEN_BIT_OR_ASSIGN, "|=") : new_token(lexer, TOKEN_BIT_OR,
			                                                                                   "|");
		case '+':
			if (match(lexer, '+'))
			{
				if (match(lexer, '+')) return new_token(lexer, TOKEN_CT_CONCAT, "+++");
				return new_token(lexer, TOKEN_PLUSPLUS, "++");
			}
			if (match(lexer, '=')) return new_token(lexer, TOKEN_PLUS_ASSIGN, "+=");
			return new_token(lexer, TOKEN_PLUS, "+");
		case '-':
			if (match(lexer, '>')) return new_token(lexer, TOKEN_ARROW, ".");
			if (match(lexer, '-')) return new_token(lexer, TOKEN_MINUSMINUS, "--");
			if (match(lexer, '=')) return new_token(lexer, TOKEN_MINUS_ASSIGN, "-=");
			return new_token(lexer, TOKEN_MINUS, "-");
		case 'x':
			if ((peek(lexer) == '"' || peek(lexer) == '\'' || peek(lexer) == '`'))
			{
				return scan_hex_array(lexer);
			}
			// goto IDENT;
			nextcase '_';
		case 'b':
			if (peek(lexer) == '6' && peek_next(lexer) == '4' && (lexer.current[2] == '\'' || lexer.current[2] == '"' || lexer.current[2] == '`'))
			{
				return scan_base64(lexer);
			}
			// goto IDENT;
			nextcase '_';
		case '_':
		// IDENT:
			backtrack(lexer);
			return scan_ident(lexer, TOKEN_IDENT, TOKEN_CONST_IDENT, TOKEN_TYPE_IDENT, 0);
		default:
			if (c >= '0' && c <= '9')
			{
				backtrack(lexer);
				return scan_digit(lexer);
			}
			if (c >= 'a' && c <= 'z') nextcase '_'; // goto IDENT;
			if (c >= 'A' && c <= 'Z') nextcase '_'; // goto IDENT;
			if (c < 0)
			{
				return add_error_token(lexer, "The 0x%x character may not be placed outside of a string or comment, did you forget a \" somewhere?", (char)c);
			}
			return add_error_token(lexer, "'%c' may not be placed outside of a string or comment, did you perhaps forget a \" somewhere?", c);

	}
}

fn void check_bidirectional_markers(Lexer *lexer) @inline
{
	// First we check for bidirectional markers.
	char *check = (char *)lexer.current;
	uint c;
	int balance = 0;
	// Loop until end.
	while LOOP: ((c = *(check++)) != '\0')
	{
		if (c != 0xE2) continue;
		// Possible marker.
		char next = check[0];
		if (next == 0) break;
		char type = check[1];
		switch (check[0])
		{
			case 0x80:
				if (type == 0xAC)
				{
					balance--;
					// if (balance < 0) goto DONE;
					if (balance < 0) break LOOP;
				}
				if (type >= 0xAA && type <= 0xAE)
				{
					balance++;
				}
				break;
			case 0x81:
				if (type >= 0xA6 && type <= 0xA8)
				{
					balance++;
				}
				else if (type == 0xA9)
				{
					balance--;
					// if (balance < 0) goto DONE;
					if (balance < 0) break LOOP;
				}
				break;
			default:
				break;
		}
	}
	// DONE:
	// Check for unbalanced result
	if (balance != 0)
	{
		add_error_token_at_start(lexer, "Invalid encoding - Unbalanced bidirectional markers.");
		return;
	}
}

// Initialize a file
fn void lexer_init(Lexer *lexer, String contents)
{
	// Set the current file.
	// lexer.file_begin = lexer.file.contents;
	lexer.file_begin = contents;
	// Set current to beginning.
	lexer.current = lexer.file_begin;
	// Line start is current.
	lexer.line_start = lexer.current;
	// Row number starts at 1
	lexer.current_row = 1;
	// File id is the current file.
	// lexer.tok_span.file_id = lexer.file.file_id;
	// Mode is NORMAL
	lexer.mode = LEX_NORMAL;
	// Set up lexing for a new token.
	begin_new_token(lexer);
	// Check for bidirectional markers.
	check_bidirectional_markers(lexer);
}

fn bool lexer_next_token(Lexer *lexer)
{
	// Scan for a token.
	if (lexer_scan_token_inner(lexer)) return true;
	// Failed, so check if we're at end:
	if (reached_end(lexer)) return true;
	// Scan through the rest of the text for other invalid tokens:
	bool token_is_ok = false;
	do
	{
		if (!token_is_ok)
		{
			// Scan to the end of the line if we have an error.
			while (!reached_end(lexer) && peek(lexer) != '\n') next(lexer);
		}
		token_is_ok = lexer_scan_token_inner(lexer);
	}
	while (!reached_end(lexer));
	// Done.
	return false;
}

