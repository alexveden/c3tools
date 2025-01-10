module std::c3lang::lexer;
import std::io;
import std::c3lang::utils_port;
import std::c3lang::common;
import std::collections::list;

// Copyright (c) 2019 Christoffer Lerno. All rights reserved.
// Copyright (c) 2025 Alex Veden <i@alexveden.com>. All rights reserved.
// Use of this source code is governed by the MIT license
// a copy of which can be found in the LICENSE_STDLIB file.


def Lexer = LexerImp;

struct LexerImp
{
	char *file_begin;
	uint file_len;
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

struct Token(Printable) {
	TokenType type;
	String value;
	uint row;
	uint col;
	usz offset;
}

fn String Token.to_string(&self, Allocator allocator) @dynamic {
	@pool(allocator)
	{
		DString builder = dstring::temp_new();
		builder.appendf("{\n");
		builder.appendf("    type: %s\n", self.type);
		builder.appendf("    value: `%s`\n", self.value);
		builder.appendf("    row: %s\n", self.row);
		builder.appendf("    col: %s\n", self.col);
		builder.appendf("    offset: %s\n", self.offset);
		builder.appendf("}\n");
		return builder.copy_str(allocator);
	};
}

fn void Token.print(&self, bool new_line = false) {
	switch(self.type)
	{
		case TOKEN_IDENT:
		case TOKEN_CT_IDENT:
		case TOKEN_CT_CONST_IDENT:
		case TOKEN_CT_TYPE_IDENT:
		case TOKEN_HASH_IDENT:
		case TOKEN_HASH_CONST_IDENT:
		case TOKEN_HASH_TYPE_IDENT:
		case TOKEN_CONST_IDENT:
		case TOKEN_TYPE_IDENT:
		case TOKEN_AT_IDENT:
		case TOKEN_AT_TYPE_IDENT:
		case TOKEN_AT_CONST_IDENT:
			io::printf("%s[%s]%s", 
					   common::token_type_to_string(self.type), self.value, new_line ? "\n" : " ");
			break;
		case TOKEN_STRING:
		case TOKEN_RAW_STRING:
		case TOKEN_INTEGER:
		case TOKEN_REAL:
		case TOKEN_CHAR_LITERAL:
		case TOKEN_BYTES:
		case TOKEN_COMMENT_SINGLE:
			io::printf("%s[%s]%s", 
					   common::token_type_to_string(self.type), self.value, new_line ? "\n" : " ");
			break;
		case TOKEN_EOS:
			io::printf("%s\n", common::token_type_to_string(self.type));
			break;
		default:
			io::printf("%s%s", common::token_type_to_string(self.type), new_line ? "\n" : " ");
	}

}

<*
Initializes new lexer instance
@param contents `c3 source contents`
@require contents.len > 0
*>
fn Lexer new_init(String contents)
{
	Lexer lexer = {};
	// Set the current file.
	// lexer.file_begin = lexer.file.contents;
	lexer.file_begin = contents;
	lexer.file_len = contents.len;
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
	begin_new_token(&lexer);
	// Check for bidirectional markers.
	check_bidirectional_markers(&lexer);
	return lexer;
}

<*
Parses next token in a code
@return `true if token found, false - EOF reached or error`
*>
fn bool Lexer.next_token(&self)
{
	if(self.token_type == TOKEN_EOF) {
		return false;
	}
	// Scan for a token.
	if (lexer_scan_token_inner(self)) return true;
	// Failed, so check if we're at end:
	if (reached_end(self)) return true;
	// Scan through the rest of the text for other invalid tokens:
	bool token_is_ok = false;
	do
	{
		if (!token_is_ok)
		{
			// Scan to the end of the line if we have an error.
			while (!reached_end(self) && peek(self) != '\n') next(self);
		}
		token_is_ok = lexer_scan_token_inner(self);
	}
	while (!reached_end(self));
	// Done.
	return false;
}

fn List(<lexer::Token>) Lexer.new_parse_tokens(&self, Allocator allocator = allocator::heap())
{
	assert(self.file_begin, "not initialied");
	assert(self.file_begin == self.current, "already processed");

	List(<Token>) result;
	result.new_init(allocator: allocator);
	
	while (self.next_token())
	{
		result.push(
			Token {
				.type = self.token_type, 
				.value = self.data.string, 
				.row = self.tok_span.row,
				.col = self.tok_span.col,
				.offset = (usz)(self.lexing_start - self.file_begin), 
			}
		);
	}
	return result;
}


struct TokenData @private
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
    return (lexer_.current[0] == '\0' || lexer_.current >= (lexer_.file_begin+lexer_.file_len));
}

// Step one character forward and return that character
fn char next(Lexer *lexer) @inline
{
	if (*lexer.current == '\n')
	{
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
fn bool parse_line_comment(Lexer *lexer) @inline @local
{
	backtrack(lexer);
	backtrack(lexer);
	begin_new_token(lexer);

	while (!reached_end(lexer) && peek(lexer) != '\n')
	{
		next(lexer);
	}
	// If we found EOL, then walk past '\n'
	if (peek(lexer) == '\n')
	{
		next(lexer);
	}

	bool has_new_line = false;
	char* cur = lexer.lexing_start - 1;
	while LOOP: (cur >= lexer.file_begin) {
		switch(*cur) {
			case ' ':
			case '\t':
				break;
			case '\n':
				has_new_line = true;
			default:
				break LOOP;
		}
		cur--;
	}
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer, has_new_line ? TOKEN_COMMENT_SINGLE : TOKEN_COMMENT_SINGLE_INLINE, (String)lexer.lexing_start[..len-1]);
}

/**
 * Parse the common / *  * / style multiline comments, allowing nesting.
 **/
fn bool parse_multiline_comment(Lexer *lexer) @inline @local
{
	backtrack(lexer);
	backtrack(lexer);
	begin_new_token(lexer);

	int nesting = 1;
	while LOOP: (!reached_end(lexer)) {
		switch (peek(lexer))
		{
			case '*':
				if (peek_next(lexer) == '/')
				{
					skip(lexer, 2);
					nesting--;
					if (nesting == 0) break LOOP;
					continue;
				}
			case '/':
				if (peek_next(lexer) == '*')
				{
					skip(lexer, 2);
					nesting++;
					continue;
				}
			case '\0':
				// Reached eof - end.
				return false;
			default:
				break;
		}
		next(lexer);
	}

	bool has_new_line = false;
	char* cur = lexer.lexing_start - 1;
	while LOOP: (cur >= lexer.file_begin) {
		switch(*cur) {
			case ' ':
			case '\t':
				break;
			case '\n':
				has_new_line = true;
			default:
				break LOOP;
		}
		cur--;
	}
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer, has_new_line ? TOKEN_COMMENT_MULTI : TOKEN_COMMENT_MULTI_INLINE, (String)lexer.lexing_start[..len-1]);
}


/**
 * Skip regular whitespace.
 */
fn bool skip_whitespace(Lexer *lexer) @local
{
	while (1)
	{
		switch (peek(lexer))
		{
			case '/':
				if (lexer.mode == LEX_CONTRACTS) return false;
				// The '//' case
				if (peek_next(lexer) == '/')
				{
					skip(lexer, 2);
					if(parse_line_comment(lexer)) {
						return true;
					}
					continue;
				}
				// '/*'
				if (peek_next(lexer) == '*')
				{
					skip(lexer, 2);
					if(parse_multiline_comment(lexer)){
						return true;
					}
					continue;
				}
				return false;
			case '\n':
				// Contract lexing sees '\n' as a token.
				if (lexer.mode == LEX_CONTRACTS) return false;
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
				return false;
		}
	}
	// unreachable();
}

// --- Identifier scanning

// Parses identifiers. Note that this is a bit complicated here since
// we split identifiers into 2 types + find keywords.
fn bool scan_ident(Lexer *lexer, TokenType normal, TokenType const_token, TokenType type_token, char prefix) @inline @local
{
	TokenType type = TOKEN_INVALID_TOKEN;
	char c;
	while ((c = peek(lexer)) == '_')
	{
		next(lexer);
	}
	while LOOP: (1)
	{
		c = peek(lexer);
		switch (c)
		{
            case 'a'..'z':
				if (type == TOKEN_INVALID_TOKEN)
				{
					type = normal;
				}
				else if (type == const_token)
				{
					type = type_token;
				}
				break;
            case 'A'..'Z':
				if (type == TOKEN_INVALID_TOKEN) type = const_token;
				break;
            case '0'..'9': 
				if (type == TOKEN_INVALID_TOKEN) return add_error_token(lexer, "A letter must precede any digit");
			case '_':
				break;
			default:
				break LOOP;
		}
		next(lexer);
	}

	// FIX: skip this at case default break
	// Allow bang!
	if (peek(lexer) == '!' && type == normal)
	{
		next(lexer);
	}

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
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer, TOKEN_INTEGER, (String)lexer.lexing_start[..len-1]);
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
	// return new_token(lexer, TOKEN_INTEGER, ((ZString)lexer.lexing_start).str_view());
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer, TOKEN_INTEGER, (String)lexer.lexing_start[..len-1]);
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
	// return new_token(lexer, is_float ? TOKEN_REAL : TOKEN_INTEGER, ((ZString)lexer.lexing_start).str_view());
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer,is_float ? TOKEN_REAL : TOKEN_INTEGER, (String)lexer.lexing_start[..len-1]);

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
	// return new_token(lexer, is_float ? TOKEN_REAL : TOKEN_INTEGER, ((ZString)lexer.lexing_start).str_view());
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer,is_float ? TOKEN_REAL : TOKEN_INTEGER, (String)lexer.lexing_start[..len-1]);
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

fn bool scan_char(Lexer *lexer) @inline @local
{
	// Handle the problem with zero size character literal first.
	if (match(lexer, '\''))
	{
		return add_error_token(lexer, "The character literal was empty.");
	}

	int width = 1;
	char c;

	while LOOP: (!match(lexer, '\''))
	{
		c = peek(lexer);
		next(lexer);
		// End of file may occur:
		if (c == '\0')
		{
			return add_error_token_at_start(lexer, "The character literal did not terminate.");
		}
		width++;
	}
	// next(lexer);
	assert(width > 0 && width <= 8);
	return new_token(lexer, TOKEN_CHAR_LITERAL, (String)lexer.lexing_start[..width]);
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
	usz len = 0;

	// NOTE: inlcuding previous "
	backtrack(lexer);
	begin_new_token(lexer);
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
		len++;
	}
	// Skip the `"`
	next(lexer);
	return new_token(lexer, TOKEN_STRING, len > 0 ? (String)lexer.lexing_start[..len]: "");

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
	char *current = lexer.lexing_start;
	char *end = lexer.current;
	usz len = (usz)(end - current);
	new_token(lexer, TOKEN_RAW_STRING, (String)current[0..len-1]);
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
	// FIX: this may oveflow
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
	// FIX: this may oveflow
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
					break LOOP;
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
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer, TOKEN_DOCS_START, (String)lexer.lexing_start[..len-1]);
}

fn bool lexer_scan_token_inner(Lexer *lexer) @local
{
	if(skip_whitespace(lexer)){
		// Now skip the whitespace (but check for comments).
		return true;
	}

	// Point start to the first non-whitespace character.
	begin_new_token(lexer);

	if (reached_end(lexer)) {
		new_token(lexer, TOKEN_EOF, "\n");
		return false;
	}

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

