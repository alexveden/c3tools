module c3tools::lexer;
import c3tools::utils_port;
import std::io;
import std::math;
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
	LexMode mode; 
	Token token;
	bool is_whitespace_mode;
}

struct Token(Printable) {
	TokenType type;
	String value;
	uint row;
	uint col;
	uint offset;
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

fn void Token.print(&self, bool new_line = false, int padding = 0) {
	assert(padding >= 0);

	usz plen = 0;
	switch(self.type)
	{
		case IDENT:
		case CT_IDENT:
		case CT_CONST_IDENT:
		case CT_TYPE_IDENT:
		case HASH_IDENT:
		case HASH_CONST_IDENT:
		case HASH_TYPE_IDENT:
		case CONST_IDENT:
		case TYPE_IDENT:
		case AT_IDENT:
		case AT_TYPE_IDENT:
		case AT_CONST_IDENT:
			plen = io::printf("%s[%s]", 
					   lexer::token_type_to_string(self.type), self.value)!!;
			break;
		case STRING:
		case RAW_STRING:
		case INTEGER:
		case REAL:
		case CHAR_LITERAL:
		case BYTES:
			plen = io::printf("%s[%s]", 
					   lexer::token_type_to_string(self.type), self.value)!!;
			break;
		case DOCS_START:
		case COMMENT_SINGLE:
		case COMMENT_SINGLE_INLINE:
		case COMMENT_MULTI:
		case COMMENT_MULTI_INLINE:
			plen = io::printf("%s`#%d`", 
					   lexer::token_type_to_string(self.type), self.value.len)!!;
			break;
		case EOS:
		case EOF:
		case EMPTY_LINE:
			plen = io::printf("%s", lexer::token_type_to_string(self.type))!!;
			break;
		default:
			plen = io::printf("%s", lexer::token_type_to_string(self.type))!!;
	}

	if (padding > 0) {
		assert(plen > 0);
		for(int i = 0; i < padding - plen; i++){
			io::print(" ");
		}
	}

	if (new_line){
		io::print("\n");
	} else {
		io::print(" ");
	}
	
}

<*
Initializes new lexer instance
@param contents `c3 source contents`
*>
fn void init(Lexer* lexer, String contents)
{
	*lexer = Lexer{};
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
	begin_new_token(lexer);
}

fn void Lexer.set_whitespace_mode(&self, bool is_enabled)
{
	self.is_whitespace_mode = is_enabled;
}

<*
Parses next token in a code
@return `true if token found, false - EOF reached or error`
*>
fn bool Lexer.next_token(&self)
{
	if(self.token.type == EOF) {
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

<*
Parses lexer contents and returns new list of all available tokens

@param allocator "optional allocator for resulting list"
@return "list of all tokens in lexer string"
*>
fn List(<lexer::Token>) Lexer.new_parse_tokens(&self, Allocator allocator = allocator::heap())
{
	assert(self.file_begin, "not initialied");
	assert(self.file_begin == self.current, "already processed");

	List(<Token>) result;
	result.new_init(allocator: allocator);
	
	while (self.next_token())
	{
		result.push(self.token);
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
	return line > lexer::MAX_SOURCE_LOCATION_LEN ? 0 : (uint)line;
}

// --- Lexing general methods.

// Peek at the current character in the buffer.
macro char peek(lexer_) @local {
  return (*(lexer_).current);
} 

// Look at the prev character in the buffer.
macro char prev(lexer_) @local {
    return ((lexer_).current[-1]);
}

// // Peek one character ahead.
macro char peek_next(lexer_) @local {
    return ((lexer_).current[1]);
}
//
// // Is the current character '\0' if so we assume we reached the end.
macro bool reached_end(lexer_) {
    return (lexer_.current >= (lexer_.file_begin+lexer_.file_len) || lexer_.current[0] == '\0');
}

// Step one character forward and return that character
fn char next(Lexer *lexer) @inline
{
	if (@unlikely(*lexer.current == '\n'))
	{
		lexer.line_start = lexer.current + 1;
		lexer.current_row++;
	}
	lexer.current++;
	if (@unlikely(lexer.current >= (lexer.file_begin+lexer.file_len))) {
		return '\0';
	}
	return (lexer.current)[0];
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

fn void begin_new_token(Lexer *lexer) @inline @local
{
	lexer.lexing_start = lexer.current;
	lexer.start_row = lexer.current_row;
	lexer.start_row_start = lexer.line_start;
}

// Add a new regular token.
fn bool new_token(Lexer *lexer, TokenType type, String string) @inline @local
{
	set_generic_token(lexer, type, string);
	return true;
}
/**
 * Allocate data for a token, including source location.
 * This call is doing the basic allocation, with other functions
 * filling out additional information.
 **/
fn void set_generic_token(Lexer *lexer, TokenType type, String value) @inline @local
{
	assert(lexer.lexing_start >= lexer.file_begin);

	lexer.token.type = type;
	// Set the location.
	lexer.token.value = value;
	lexer.token.offset = (uint)(lexer.lexing_start - lexer.file_begin);
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
	// lexer.tok_span.length = (char)length; 
	lexer.token.col = (char)col;
	lexer.token.row = line;
}

// Error? We simply generate an invalid token and print out the error.
macro bool add_error_token(Lexer *lexer, String message) @local
{
    
	set_generic_token(lexer, INVALID_TOKEN, message);
	return false;
}

// Error at the start of the lexing, with a single length.
macro bool add_error_token_at_start(Lexer *lexer, String message) @local
{
	set_generic_token(lexer, INVALID_TOKEN, message);
	return false;
}

// Create an error token at a particular place in the file.
// used for pointing out errors in strings etc.
macro bool add_error_token_at(Lexer *lexer, char *loc, isz len, String message) @local
{
	set_generic_token(lexer, INVALID_TOKEN, message);
	return false;
}

// Print an error at the current location.
macro bool add_error_token_at_current(Lexer *lexer, String message) @local
{
	set_generic_token(lexer, INVALID_TOKEN, message);
	return false;
}


// --- Comment parsing

/**
 * Parsing of the "//" line comment - skipping past the end.
 */
fn bool parse_line_comment(Lexer *lexer) @inline @local
{
	backtrack(lexer);
	backtrack(lexer);
	bool has_new_line = (lexer.current == lexer.file_begin);
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

	char* cur = lexer.lexing_start - 1;
	while LOOP: (cur >= lexer.file_begin) {
		switch(*cur) {
			case ' ':
			case '\t':
				break;
			case '\n':
				has_new_line = true;
				break LOOP;
			default:
				break LOOP;
		}
		cur--;
	}
	uint len = (uint)(lexer.current - lexer.lexing_start);
	if (lexer.lexing_start[len-1] == '\n') len--;

	return new_token(lexer, has_new_line ? COMMENT_SINGLE : COMMENT_SINGLE_INLINE, (String)lexer.lexing_start[..len-1]);
}

/**
 * Parse the common / *  * / style multiline comments, allowing nesting.
 **/
fn bool parse_multiline_comment(Lexer *lexer) @inline @local
{
	backtrack(lexer);
	backtrack(lexer);
	bool has_new_line = (lexer.current == lexer.file_begin);
	begin_new_token(lexer);

	int nesting = 0;
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
	if (lexer.lexing_start[len-1] == '\n') len--;

	return new_token(lexer, has_new_line ? COMMENT_MULTI : COMMENT_MULTI_INLINE, (String)lexer.lexing_start[..len-1]);
}


/**
 * Skip regular whitespace.
 */
fn bool skip_whitespace(Lexer *lexer) @local
{
	bool has_empty_line = false;
	while LOOP: (!reached_end(lexer))
	{
		char c = peek(lexer);
		switch (c)
		{
			case '/':
				has_empty_line = false;
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
				if (has_empty_line) {
					begin_new_token(lexer);
					return new_token(lexer, TokenType.EMPTY_LINE, "\n");
				}
				has_empty_line = true;

				nextcase;
			case ' ':
			case '\t':
			case '\f':
				if (lexer.is_whitespace_mode) {
					begin_new_token(lexer);
					next(lexer);
					uint len = (uint)(lexer.current - lexer.lexing_start);
					return new_token(lexer, SPACE, (String)lexer.lexing_start[..len-1]);
				}
				nextcase;
			case '\r': // This is forbidden by c3 grammar, and should be skipped silently
				next(lexer);
				break;
			default:
				has_empty_line = false;
				return false;
		}
	}
	return false;
}

// tries to extent current AT_IDENT
// for handling @if(env::SOO || SOME) @export("something")
fn void Lexer.extend_current_attribute(Lexer *lexer)
{
	Token* result = &lexer.token;
	assert(lexer.token.type == AT_IDENT);
	assert(math::abs(lexer.current - lexer.token.value.ptr) < 64, "this must be called AT_IDENT parsed");
	assert(lexer.token.value);
	assert(lexer.token.value.ptr >= lexer.file_begin);
	assert(lexer.token.value.ptr < lexer.file_begin + lexer.file_len);

	int nesting = 0;
	int extra_len = 0;
	bool had_nesting = false;
	while LOOP: (!reached_end(lexer)) {
		char c = peek(lexer);
    	// io::printf("current char: `%c`\n", c);
		switch (c)
		{
			case '(':
				nesting++;
				had_nesting = true;
			case ')':
				nesting--;
				if (nesting == 0) next(lexer);
				nextcase default;
			case ' ':
				break;
			default:
				if (nesting <= 0){
					if(had_nesting){
						result.value = (String)((char*) result.value.ptr)[..result.value.len + extra_len]; 
					}
					break LOOP;
				}
		}
		extra_len++;
		next(lexer);
	}
	// unreachable();
}

// Parses identifiers. Note that this is a bit complicated here since
// we split identifiers into 2 types + find keywords.
fn bool scan_ident(Lexer *lexer, TokenType normal, TokenType const_token, TokenType type_token, char prefix) @inline @local
{
	TokenType type = INVALID_TOKEN;
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
				if (type == INVALID_TOKEN)
				{
					type = normal;
				}
				else if (type == const_token)
				{
					type = type_token;
				}
				break;
            case 'A'..'Z':
				if (type == INVALID_TOKEN) type = const_token;
				break;
            case '0'..'9': 
				if (type == INVALID_TOKEN) return add_error_token(lexer, "A letter must precede any digit");
			case '_':
				break;
			default:
				break LOOP;
		}
		next(lexer);
	}

	uint len = (uint)(lexer.current - lexer.lexing_start);
	if (type == INVALID_TOKEN)
	{
		if (!prefix && len == 1) return new_token(lexer, UNDERSCORE, "_");
		if (prefix && len == 1)
		{
			return add_error_token(lexer, "An identifier was expected ... ");
		}
		return add_error_token(lexer, "An identifier may not consist of only '_' characters.");
	}
	switch (type)
	{
		case RETURN:
			if (lexer.mode == LEX_CONTRACTS) type = IDENT;
			break;
		default:
			break;
	}
	String identifier = (String)lexer.lexing_start[..len-1];
	TokenType ttype = lexer::token_from_identifier(identifier); 
	if (ttype != INVALID_TOKEN){
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
				return add_error_token_at_current(lexer, "Integer suffix is not valid for a floating point literal.");
			}
			break;
		case 'u':
			if (*is_float)
			{
				return add_error_token_at_current(lexer, "Integer suffix is not valid for a floating point literal.");
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
				return add_error_token_at_current(lexer, "Integer suffix '%c' is not valid for a floating point literal.");
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
	return new_token(lexer, INTEGER, (String)lexer.lexing_start[..len-1]);
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
	// return new_token(lexer, INTEGER, ((ZString)lexer.lexing_start).str_view());
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer, INTEGER, (String)lexer.lexing_start[..len-1]);
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
		return add_error_token(lexer, "Parsing the floating point exponent failed, because some char is not a number.");
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
	// return new_token(lexer, is_float ? REAL : INTEGER, ((ZString)lexer.lexing_start).str_view());
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer,is_float ? REAL : INTEGER, (String)lexer.lexing_start[..len-1]);

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
	// return new_token(lexer, is_float ? REAL : INTEGER, ((ZString)lexer.lexing_start).str_view());
	uint len = (uint)(lexer.current - lexer.lexing_start);
	return new_token(lexer,is_float ? REAL : INTEGER, (String)lexer.lexing_start[..len-1]);
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
		switch(c){
			case '\0':
				return add_error_token_at_start(lexer, "The character literal did not terminate.");
			case '\\': // escape sequence
				c = peek(lexer);
				if (c == '\'' || c == '\\') {
 	 	 	 	 	 next(lexer);
 	 	 	 	 	 width++;
				}
		}
		width++;
	}
	// next(lexer);
	assert(width > 0 && width <= 8);
	return new_token(lexer, CHAR_LITERAL, (String)lexer.lexing_start[..width]);
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
	return new_token(lexer, STRING, len > 0 ? (String)lexer.lexing_start[..len]: "");

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
	new_token(lexer, RAW_STRING, (String)current[0..len-1]);
	return true;
}

fn bool scan_hex_array(Lexer *lexer) @inline @local
{
	char start_char = peek(lexer);
	next(lexer); // Step past ' or " `
	char c;
	ulong len = 2;
	while (1)
	{
		c = peek(lexer);
		if (c == 0)
		{
			return add_error_token_at_current(lexer, "The hex string seems to be missing a terminating ");
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
											  " isn't a valid hexadecimal digit, all digits should be a-z, A-Z and 0-9.",
											  );
		}
		return add_error_token_at_current(lexer,
										  "This isn't a valid hexadecimal digit, all digits should be a-z, A-Z and 0-9.");
	}
	next(lexer);
	if (len % 2)
	{
		return add_error_token(lexer, "The hexadecimal string is not an even length, did you miss a digit somewhere?");
	}

	new_token(lexer, BYTES, (String)lexer.lexing_start[..len+1]);
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
	ulong len = 4;
	while (1)
	{
		c = peek(lexer);
		if (c == 0)
		{
			return add_error_token_at_start(lexer, "The base64 string seems to be missing a terminating");
		}
		next(lexer);
		if (c == start_char) break;
		if (utils_port::char_is_base64(c))
		{
			if (end_len)
			{
				return add_error_token_at_current(lexer, "can't be placed after an ending '='");
			}
			len++;
			continue;
		}
		if (c == '=')
		{
			if (end_len > 1)
			{
				return add_error_token_at_current(lexer, "There cannot be more than 2 '=' at the end of a base64 string.");
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
			return add_error_token_at_current(lexer, "not a valid base64 character.");
		}
	}
	new_token(lexer, BYTES, (String)lexer.lexing_start[..len]);
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
	return new_token(lexer, DOCS_START, (String)lexer.lexing_start[..len-1]);
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
		new_token(lexer, EOF, "\n");
		return false;
	}

	ichar c = peek(lexer);
	next(lexer);
	switch (c)
	{
		case '\n':
			assert(lexer.mode == LEX_CONTRACTS);
			return new_token(lexer, DOCS_EOL, "\n");
		case '@':
			if (utils_port::char_is_letter_(peek(lexer)))
			{
				return scan_ident(lexer, AT_IDENT, AT_CONST_IDENT, AT_TYPE_IDENT, '@');
			}
			return new_token(lexer, AT, "@");
		case '\'':
			return scan_char(lexer);
		case '`':
			return scan_raw_string(lexer);
		case '"':
			return scan_string(lexer);
		case '#':
			return scan_ident(lexer, HASH_IDENT, HASH_CONST_IDENT, HASH_TYPE_IDENT, '#');
		case '$':
			if (match(lexer, '$'))
			{
				if (utils_port::char_is_letter(peek(lexer)))
				{
					return scan_ident(lexer, BUILTIN, BUILTIN, BUILTIN, '#');
				}
				return add_error_token_at_current(lexer, "Expected a letter after $$.");
			} else {
				return scan_ident(lexer, CT_IDENT, CT_CONST_IDENT, CT_TYPE_IDENT, '$');
			}
		case ',':
			return new_token(lexer, COMMA, ",");
		case ';':
			return new_token(lexer, EOS, ";");
		case '{':
			return match(lexer, '|') ? new_token(lexer, LBRAPIPE, "{|") : new_token(lexer, LBRACE, "{");
		case '}':
			return new_token(lexer, RBRACE, "}");
		case '(':
			return match(lexer, '<') ? new_token(lexer, LGENPAR, "(<") : new_token(lexer, LPAREN, "(");
		case ')':
			return new_token(lexer, RPAREN, ")");
		case '[':
			if (match(lexer, '<')) return new_token(lexer, LVEC, "[<");
			return new_token(lexer, LBRACKET, "[");
		case ']':
			return new_token(lexer, RBRACKET, "]");
		case '.':
			if (match(lexer, '.'))
			{
				if (match(lexer, '.')) return new_token(lexer, ELLIPSIS, "...");
				return new_token(lexer, DOTDOT, "..");
			}
			return new_token(lexer, DOT, ".");
		case '~':
			return new_token(lexer, BIT_NOT, "~");
		case ':':
			return match(lexer, ':') ? new_token(lexer, SCOPE, "::") : new_token(lexer, COLON, ":");
		case '!':
			if (match(lexer, '!')) return new_token(lexer, BANGBANG, "!!");
			return match(lexer, '=') ? new_token(lexer, NOT_EQUAL, "!=") : new_token(lexer, BANG, "!");
		case '/':
			return match(lexer, '=') ? new_token(lexer, DIV_ASSIGN, "/=") : new_token(lexer, DIV, "/");
		case '*':
			if (lexer.mode == LEX_CONTRACTS && match(lexer, '>'))
			{
				lexer.mode = LEX_NORMAL;
				return new_token(lexer, DOCS_END, "*>");
			}
			return match(lexer, '=') ? new_token(lexer, MULT_ASSIGN, "*=") : new_token(lexer, STAR, "*");
		case '=':
			if (match(lexer, '>')) return new_token(lexer, IMPLIES, "=>");
			return match(lexer, '=') ? new_token(lexer, EQEQ, "==") : new_token(lexer, EQ, "=");
		case '^':
			return match(lexer, '=') ? new_token(lexer, BIT_XOR_ASSIGN, "^=") : new_token(lexer, BIT_XOR, "^");
		case '?':
			if (match(lexer, '?')) return new_token(lexer, QUESTQUEST, "??");
			return match(lexer, ':') ? new_token(lexer, ELVIS, "?:") : new_token(lexer, QUESTION, "?");
		case '<':
			if (match(lexer, '<'))
			{
				if (match(lexer, '=')) return new_token(lexer, SHL_ASSIGN, "<<=");
				return new_token(lexer, SHL, "<<");
			}
			if (lexer.mode == LEX_NORMAL && match(lexer, '*'))
			{
				return parse_doc_start(lexer);
			}
			return match(lexer, '=') ? new_token(lexer, LESS_EQ, "<=") : new_token(lexer, LESS, "<");
		case '>':
			if (match(lexer, '>'))
			{
				if (match(lexer, '=')) return new_token(lexer, SHR_ASSIGN, ">>=");
				return new_token(lexer, SHR, ">>");
			}
			if (match(lexer, ')')) return new_token(lexer, RGENPAR, ">)");
			if (match(lexer, ']')) return new_token(lexer, RVEC, ">]");
			return match(lexer, '=') ? new_token(lexer, GREATER_EQ, ">=") : new_token(lexer, GREATER, ">");
		case '%':
			return match(lexer, '=') ? new_token(lexer, MOD_ASSIGN, "%=") : new_token(lexer, MOD, "%");
		case '&':
			if (match(lexer, '&'))
			{
				return match(lexer, '&') ? new_token(lexer, CT_AND, "&&&") : new_token(lexer, AND, "&&");
			}
			return match(lexer, '=') ? new_token(lexer, BIT_AND_ASSIGN, "&=") : new_token(lexer, AMP, "&");
		case '|':
			if (match(lexer, '}')) return new_token(lexer, RBRAPIPE, "|}");
			if (match(lexer, '|'))
			{
				return match(lexer, '|') ? new_token(lexer, CT_OR, "|||") : new_token(lexer, OR, "||");
			}
			return match(lexer, '=') ? new_token(lexer, BIT_OR_ASSIGN, "|=") : new_token(lexer, BIT_OR,
			                                                                                   "|");
		case '+':
			if (match(lexer, '+'))
			{
				if (match(lexer, '+')) return new_token(lexer, CT_CONCAT, "+++");
				return new_token(lexer, PLUSPLUS, "++");
			}
			if (match(lexer, '=')) return new_token(lexer, PLUS_ASSIGN, "+=");
			return new_token(lexer, PLUS, "+");
		case '-':
			if (match(lexer, '>')) return new_token(lexer, ARROW, ".");
			if (match(lexer, '-')) return new_token(lexer, MINUSMINUS, "--");
			if (match(lexer, '=')) return new_token(lexer, MINUS_ASSIGN, "-=");
			return new_token(lexer, MINUS, "-");
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
			return scan_ident(lexer, IDENT, CONST_IDENT, TYPE_IDENT, 0);
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
				return add_error_token(lexer, "The 0x ?? character may not be placed outside of a string or comment, did you forget a \" somewhere?");
			}
			return add_error_token(lexer, "char may not be placed outside of a string or comment, did you perhaps forget a \" somewhere?");

	}
}

const int MAX_SOURCE_LOCATION_LEN = 255;

enum TokenType : uint
{
	INVALID_TOKEN,

	// Single-character tokens.
	AMP,              // &
	AT,               // @
	BANG,             // !
	BIT_NOT,          // ~
	BIT_OR,           // =
	BIT_XOR,          // ^
	COLON,            // :
	COMMA,            // ,
	EOS,              // ;
	EMPTY_LINE,       // a line with only white spaces (useful for code formatting)
	EQ,               // =
	GREATER,          // >
	DIV,              // /
	DOLLAR,           // $
	DOT,              // .
	HASH,             // #
	LESS,             // <
	LBRACE,           // {
	LBRACKET,         // [
	LPAREN,           // (
	MINUS,            // -
	MOD,              // %
	PLUS,             // +
	QUESTION,         // ?
	RBRACE,           // }
	RBRACKET,         // ]
	RPAREN,           // )
	STAR,             // *
	UNDERSCORE,       // _
	SPACE,            // ' '

	// two character tokens.
	AND,              // &&
	ARROW,            // -> // Not used but reserved
	BANGBANG,         // !!
	BIT_AND_ASSIGN,   // &=
	BIT_OR_ASSIGN,    // |=
	BIT_XOR_ASSIGN,   // ^=
	DIV_ASSIGN,       // /=
	DOTDOT,           // ..
	BUILTIN,          // $$
	ELVIS,            // ?:
	EQEQ,             // ==
	GREATER_EQ,       // >=
	IMPLIES,          // =>
	LESS_EQ,          // <=
	LBRAPIPE,         // {|
	LGENPAR,          // (<
	LVEC,             // [<
	MINUS_ASSIGN,     // -=
	MINUSMINUS,       // --
	MOD_ASSIGN,       // %=
	MULT_ASSIGN,      // *=
	NOT_EQUAL,        // !=
	OR,               // ||
	PLUS_ASSIGN,      // +=
	PLUSPLUS,         // ++
	RBRAPIPE,         // |}
	RGENPAR,          // >)
	RVEC,             // >]
	QUESTQUEST,       // ??
	SCOPE,            // ::
	SHL,              // <<
	SHR,              // >>

	// Three or more
	ELLIPSIS,         // ...
	SHL_ASSIGN,       // <<=
	SHR_ASSIGN,       // >>=
	CT_AND,           // &&&
	CT_CONCAT,        // +++
	CT_OR,            // |||
	// Literals.
	IDENT,            // Any normal ident.
	CONST_IDENT,      // Any purely uppercase ident,
	TYPE_IDENT,       // Any ident on the format FooBar or __FooBar

	// We want to parse $foo separately,
	// otherwise we allow things like "$ foo" which would be pretty bad.
	CT_IDENT,         // $foobar
	CT_CONST_IDENT,   // $FOOBAR
	CT_TYPE_IDENT,    // $Foobar

	// We want to parse #foo separately.
	HASH_IDENT,       // #foobar
	HASH_CONST_IDENT, // #FOOBAR
	HASH_TYPE_IDENT,  // #Foobar

	AT_IDENT,         // @macro
	AT_CONST_IDENT,   // @MACRO
	AT_TYPE_IDENT,    // @Macro

	COMMENT_SINGLE_INLINE,           // //single INLINE comment
	COMMENT_SINGLE,     // //single line comment
	COMMENT_MULTI,          //  /* multiline on new line */
	COMMENT_MULTI_INLINE,   //  some /* multiline on the same line */


	STRING,           // "Teststring"
	RAW_STRING,           // `Teststring`
	INTEGER,          // 123 0x23 0b10010 0o327
	CHAR_LITERAL,        // 'a' 'FO' 'BARS' '\u1232'
	REAL,             // 0x23.2p-2a 43.23e23
	BYTES,            // Base64 or Hex

	DOC_COMMENT,      // Doc Comment start

	// Basic types names
	VOID,
	// FIRST_KEYWORD = TOKEN_VOID,
	BOOL,
	CHAR,
	DOUBLE,
	FLOAT,
	FLOAT16,
	BFLOAT,
	INT128,
	ICHAR,
	INT,
	IPTR,
	ISZ,
	LONG,
	SHORT,
	UINT128,
	UINT,
	ULONG,
	UPTR,
	USHORT,
	USZ,
	FLOAT128,
	ANY,
	ANYFAULT,
	TYPEID,

	// Keywords
	ASSERT,
	ASM,
	STRUCT,
	DEF,
	DISTINCT,
	BITSTRUCT,
	FAULT,
	UNION,
	BREAK,
	CASE,
	CATCH,
	CONTINUE,
	DEFAULT,
	DEFER,
	DO,
	ELSE,
	ENUM,
	EXTERN,
	FALSE,
	FOR,
	FOREACH,
	FOREACH_R,
	FN,
	TLOCAL,
	IF,
	INLINE,
	IMPORT,
	MACRO,
	MODULE,
	NEXTCASE,
	NULL,
	INTERFACE,
	RETURN,
	STATIC,
	SWITCH,
	TRUE,
	TRY,
	VAR,
	WHILE,
	CONST,
	// LAST_NON_CT_KEYWORD = TOKEN_WHILE,

	CT_ALIGNOF,           // $alignof
	CT_ANDFN,             // $and
	CT_APPEND,            // $append
	CT_ASSERT,            // $assert
	CT_ASSIGNABLE,        // $assignable
	CT_CASE,              // $case
	CT_CONCATFN,          // $concat
	CT_DEFAULT,           // $default
	CT_DEFINED,           // $defined
	CT_ECHO,              // $echo
	CT_ELSE,              // $else
	CT_EMBED,             // $embed
	CT_ENDFOR,            // $endfor
	CT_ENDFOREACH,        // $endforeach
	CT_ENDIF,             // $endif
	CT_ENDSWITCH,         // $endswitch
	CT_EVAL,              // $eval
	CT_EVALTYPE,          // $evaltype
	CT_ERROR,             // $error
	CT_EXEC,              // $exec
	CT_EXTNAMEOF,         // $extnameof
	CT_FEATURE,           // $feature
	CT_FOR,               // $for
	CT_FOREACH,           // $foreach
	CT_IF,                // $if
	CT_INCLUDE,           // $include
	CT_IS_CONST,          // $is_const
	CT_NAMEOF,            // $nameof
	CT_OFFSETOF,          // $offsetof
	CT_ORFN,              // $or
	CT_QNAMEOF,           // $qnameof
	CT_SIZEOF,            // $sizeof
	CT_STRINGIFY,         // $stringify
	CT_SWITCH,            // $switch
	CT_TYPEFROM,          // $typefrom
	CT_TYPEOF,            // $typeof
	CT_VACOUNT,           // $vacount
	CT_VATYPE,            // $vatype
	CT_VACONST,           // $vaconst,
	CT_VAREF,             // $varef,
	CT_VAARG,             // $vaarg,
	CT_VAEXPR,            // $vaexpr,
	CT_VASPLAT,           // $vasplat,
	// LAST_KEYWORD = TOKEN_CT_VASPLAT,
	DOCS_START,       // <*
	DOCS_END,         // *>
	DOCS_EOL,

	EOF,              // \n - SHOULD ALWAYS BE THE LAST TOKEN.

	// LAST = TOKEN_EOF,
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
		case INVALID_TOKEN:
			return "INVALID_TOKEN";

		// One character tokens
		case AMP:
			return "&";
		case AT:
			return "@";
		case BIT_NOT:
			return "~";
		case BIT_OR:
			return "|";
		case BIT_XOR:
			return "^";
		case COLON:
			return ":";
		case COMMA:
			return ",";
		case DIV:
			return "/";
		case DOLLAR:
			return "$";
		case DOT:
			return ".";
		case EOS:
			return ";";
		case EMPTY_LINE:
			return "<EMPTY_LINE>";
		case EQ:
			return "=";
		case GREATER:
			return ">";
		case HASH:
			return "#";
		case LBRACE:
			return "{";
		case LBRACKET:
			return "[";
		case LESS:
			return "<";
		case LPAREN:
			return "(";
		case MINUS:
			return "-";
		case MOD:
			return "%";
		case BANG:
			return "!";
		case PLUS:
			return "+";
		case QUESTION:
			return "?";
		case RBRACE:
			return "}";
		case RBRACKET:
			return "]";
		case RPAREN:
			return ")";
		case STAR:
			return "*";
		case UNDERSCORE:
			return "_";
		case SPACE:
			return " ";

		// Two character tokens
		case AND:
			return "&&";
		case ARROW:
			return "->";
		case BIT_AND_ASSIGN:
			return "&=";
		case BIT_OR_ASSIGN:
			return "|=";
		case BIT_XOR_ASSIGN:
			return "^=";
		case BUILTIN:
			return "$$";
		case CT_AND:
			return "&&&";
		case CT_OR:
			return "|||";
		case CT_CONCAT:
			return "+++";
		case DIV_ASSIGN:
			return "/=";
		case DOTDOT:
			return "..";
		case ELVIS:
			return "?:";
		case EQEQ:
			return "==";
		case GREATER_EQ:
			return ">=";
		case IMPLIES:
			return "=>";
		case LESS_EQ:
			return "<=";
		case LBRAPIPE:
			return "{|";
		case LGENPAR:
			return "(<";
		case LVEC:
			return "[<";
		case MINUS_ASSIGN:
			return "-=";
		case MINUSMINUS:
			return "--";
		case MULT_ASSIGN:
			return "*=";
		case MOD_ASSIGN:
			return "%=";
		case NOT_EQUAL:
			return "!=";
		case OR:
			return "||";
		case PLUS_ASSIGN:
			return "+=";
		case PLUSPLUS:
			return "++";
		case QUESTQUEST:
			return "??";
		case RBRAPIPE:
			return "|}";
		case RGENPAR:
			return ">)";
		case RVEC:
			return ">]";
		case SCOPE:
			return "::";
		case SHL:
			return "<<";
		case SHR:
			return ">>";
		case BANGBANG:
			return "!!";

		// Three character tokens
		case ELLIPSIS:
			return "...";
		case SHL_ASSIGN:
			return "<<=";
		case SHR_ASSIGN:
			return ">>=";

		// Identifiers
		case IDENT:
			return "IDENT";
		case CT_IDENT:
			return "CT_IDENT";
		case CT_CONST_IDENT:
			return "CT_CONST_IDENT";
		case CT_TYPE_IDENT:
			return "CT_TYPE_IDENT";
		case HASH_IDENT:
			return "HASH_IDENT";
		case HASH_CONST_IDENT:
			return "HASH_CONST_IDENT";
		case HASH_TYPE_IDENT:
			return "HASH_TYPE_IDENT";
		case CONST_IDENT:
			return "CONST_IDENT";
		case TYPE_IDENT:
			return "TYPE_IDENT";

		case AT_IDENT:
			return "MACRO_IDENT";
		case AT_TYPE_IDENT:
			return "MACRO_TYPE_IDENT";
		case AT_CONST_IDENT:
			return "MACRO_CONST_IDENT";

		// Values
		case STRING:
			return "STRING";
		case RAW_STRING:
			return "RAW_STRING";
		case COMMENT_SINGLE:
			return "COMMENT_SINGLE";
		case COMMENT_SINGLE_INLINE:
			return "COMMENT_SINGLE_INLINE";
		case COMMENT_MULTI:
			return "COMMENT_MULTI";
		case COMMENT_MULTI_INLINE:
			return "COMMENT_MULTI_INLINE";
		case INTEGER:
			return "INTEGER";
		case REAL:
			return "FLOAT";
		case CHAR_LITERAL:
			return "CHAR_LITERAL";
		case BYTES:
			return "BYTES";

		// Comments
		case DOC_COMMENT:
			return "DOC_COMMENT";

		// Keywords
		case ANYFAULT:
			return "anyfault";
		case ASM:
			return "asm";
		case ASSERT:
			return "assert";
		case BITSTRUCT:
			return "bitstruct";
		case BREAK:
			return "break";
		case CASE:
			return "case";
		case CATCH:
			return "catch";
		case CONST:
			return "const";
		case CONTINUE:
			return "continue";
		case DEF:
			return "def";
		case DEFAULT:
			return "default";
		case DEFER:
			return "defer";
		case DISTINCT:
			return "distinct";
		case DO:
			return "do";
		case ELSE:
			return "else";
		case ENUM:
			return "enum";
		case EXTERN:
			return "extern";
		case FALSE:
			return "false";
		case FAULT:
			return "fault";
		case FOR:
			return "for";
		case FOREACH:
			return "foreach";
		case FOREACH_R:
			return "foreach_r";
		case FN:
			return "fn";
		case IF:
			return "if";
		case INLINE:
			return "inline";
		case INTERFACE:
			return "interface";
		case IMPORT:
			return "import";
		case MACRO:
			return "macro";
		case MODULE:
			return "module";
		case NEXTCASE:
			return "nextcase";
		case NULL:
			return "null";
		case RETURN:
			return "return";
		case STATIC:
			return "static";
		case STRUCT:
			return "struct";
		case SWITCH:
			return "switch";
		case TLOCAL:
			return "tlocal";
		case TRUE:
			return "true";
		case TRY:
			return "try";
		case TYPEID:
			return "typeid";
		case UNION:
			return "union";
		case VAR:
			return "var";
		case WHILE:
			return "while";

		// Named types
		case VOID:
			return "void";
		case ANY:
			return "any";
		case BOOL:
			return "bool";
		case FLOAT128:
			return "float128";
		case DOUBLE:
			return "double";
		case FLOAT:
			return "float";
		case BFLOAT:
			return "bfloat";
		case FLOAT16:
			return "float16";
		case LONG:
			return "long";
		case ULONG:
			return "ulong";
		case INT128:
			return "int128";
		case UINT128:
			return "uint128";
		case INT:
			return "int";
		case UINT:
			return "uint";
		case SHORT:
			return "short";
		case USHORT:
			return "ushort";
		case ICHAR:
			return "ichar";
		case CHAR:
			return "char";
		case ISZ:
			return "isz";
		case USZ:
			return "usz";
		case IPTR:
			return "iptr";
		case UPTR:
			return "uptr";
		case DOCS_START:
			return "<*";
		case DOCS_END:
			return "*>";
		case CT_ALIGNOF:
			return "$alignof";
		case CT_ANDFN:
			return "$and";
		case CT_APPEND:
			return "$append";
		case CT_ASSERT:
			return "$assert";
		case CT_ASSIGNABLE:
			return "$assignable";
		case CT_CASE:
			return "$case";
		case CT_CONCATFN:
			return "$concat";
		case CT_DEFAULT:
			return "$default";
		case CT_DEFINED:
			return "$defined";
		case CT_ELSE:
			return "$else";
		case CT_EMBED:
			return "$embed";
		case CT_ENDIF:
			return "$endif";
		case CT_ENDSWITCH:
			return "$endswitch";
		case CT_ENDFOR:
			return "$endfor";
		case CT_ENDFOREACH:
			return "$endforeach";
		case CT_EVAL:
			return "$eval";
		case CT_EVALTYPE:
			return "$evaltype";
		case CT_ERROR:
			return "$error";
		case CT_EXEC:
			return "$exec";
		case CT_EXTNAMEOF:
			return "$extnameof";
		case CT_FEATURE:
			return "$feature";
		case CT_FOR:
			return "$for";
		case CT_FOREACH:
			return "$foreach";
		case CT_IF:
			return "$if";
		case CT_IS_CONST:
			return "$is_const";
		case CT_INCLUDE:
			return "$include";
		case CT_VACOUNT:
			return "$vacount";
		case CT_VATYPE:
			return "$vatype";
		case CT_VACONST:
			return "$vaconst";
		case CT_VAARG:
			return "$vaarg";
		case CT_VAREF:
			return "$varef";
		case CT_VAEXPR:
			return "$vaexpr";
		case CT_VASPLAT:
			return "$vasplat";
		case CT_NAMEOF:
			return "$nameof";
		case CT_OFFSETOF:
			return "$offsetof";
		case CT_ORFN:
			return "$or";
		case CT_QNAMEOF:
			return "$qnameof";
		case CT_SIZEOF:
			return "$sizeof";
		case CT_SWITCH:
			return "$switch";
		case CT_TYPEFROM:
			return "$typefrom";
		case CT_TYPEOF:
			return "$typeof";
		case CT_STRINGIFY:
			return "$stringify";
		case CT_ECHO:
			return "$echo";
		case DOCS_EOL:
			return "<EOL>";
		case EOF:
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
			return  ANYFAULT;
		case "asm":
			return  ASM;
		case "assert":
			return  ASSERT;
		case "bitstruct":
			return  BITSTRUCT;
		case "break":
			return  BREAK;
		case "case":
			return  CASE;
		case "catch":
			return  CATCH;
		case "const":
			return  CONST;
		case "continue":
			return  CONTINUE;
		case "def":
			return  DEF;
		case "default":
			return  DEFAULT;
		case "defer":
			return  DEFER;
		case "distinct":
			return  DISTINCT;
		case "do":
			return  DO;
		case "else":
			return  ELSE;
		case "enum":
			return  ENUM;
		case "extern":
			return  EXTERN;
		case "false":
			return  FALSE;
		case "fault":
			return  FAULT;
		case "for":
			return  FOR;
		case "foreach":
			return  FOREACH;
		case "foreach_r":
			return  FOREACH_R;
		case "fn":
			return  FN;
		case "if":
			return  IF;
		case "inline":
			return  INLINE;
		case "interface":
			return  INTERFACE;
		case "import":
			return  IMPORT;
		case "macro":
			return  MACRO;
		case "module":
			return  MODULE;
		case "nextcase":
			return  NEXTCASE;
		case "null":
			return  NULL;
		case "return":
			return  RETURN;
		case "static":
			return  STATIC;
		case "struct":
			return  STRUCT;
		case "switch":
			return  SWITCH;
		case "tlocal":
			return  TLOCAL;
		case "true":
			return  TRUE;
		case "try":
			return  TRY;
		case "typeid":
			return  TYPEID;
		case "union":
			return  UNION;
		case "var":
			return  VAR;
		case "while":
			return  WHILE;
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
			return  TYPE_IDENT;
		case "$alignof":
			return  CT_ALIGNOF;
		case "$and":
			return  CT_ANDFN;
		case "$append":
			return  CT_APPEND;
		case "$assert":
			return  CT_ASSERT;
		case "$assignable":
			return  CT_ASSIGNABLE;
		case "$case":
			return  CT_CASE;
		case "$concat":
			return  CT_CONCATFN;
		case "$default":
			return  CT_DEFAULT;
		case "$defined":
			return  CT_DEFINED;
		case "$else":
			return  CT_ELSE;
		case "$embed":
			return  CT_EMBED;
		case "$endif":
			return  CT_ENDIF;
		case "$endswitch":
			return  CT_ENDSWITCH;
		case "$endfor":
			return  CT_ENDFOR;
		case "$endforeach":
			return  CT_ENDFOREACH;
		case "$eval":
			return  CT_EVAL;
		case "$evaltype":
			return  CT_EVALTYPE;
		case "$error":
			return  CT_ERROR;
		case "$exec":
			return  CT_EXEC;
		case "$extnameof":
			return  CT_EXTNAMEOF;
		case "$feature":
			return  CT_FEATURE;
		case "$for":
			return  CT_FOR;
		case "$foreach":
			return  CT_FOREACH;
		case "$if":
			return  CT_IF;
		case "$is_const":
			return  CT_IS_CONST;
		case "$include":
			return  CT_INCLUDE;
		case "$vacount":
			return  CT_VACOUNT;
		case "$vatype":
			return  CT_VATYPE;
		case "$vaconst":
			return  CT_VACONST;
		case "$vaarg":
			return  CT_VAARG;
		case "$varef":
			return  CT_VAREF;
		case "$vaexpr":
			return  CT_VAEXPR;
		case "$vasplat":
			return  CT_VASPLAT;
		case "$nameof":
			return  CT_NAMEOF;
		case "$offsetof":
			return  CT_OFFSETOF;
		case "$or":
			return  CT_ORFN;
		case "$qnameof":
			return  CT_QNAMEOF;
		case "$sizeof":
			return  CT_SIZEOF;
		case "$switch":
			return  CT_SWITCH;
		case "$typefrom":
			return  CT_TYPEFROM;
		case "$typeof":
			return  CT_TYPEOF;
		case "$stringify":
			return  CT_STRINGIFY;
		case "$echo":
			return  CT_ECHO;
		default:
			return INVALID_TOKEN;
	}
}
